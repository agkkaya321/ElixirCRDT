defmodule WorkerProcess do
  alias PNCounter

  def start(supervisor_address) do
    node_name = setup_node()
    connect_to_supervisor(node_name, supervisor_address)
  end

  defp setup_node do
    {:ok, ifs} = :inet.getif()

    ip_address =
      ifs
      |> Enum.map(fn {ip, _, _} -> ip end)
      |> Enum.find(fn ip -> ip not in [{127, 0, 0, 1}, {0, 0, 0, 0}] end)

    unless ip_address, do: exit(:no_ip_found)

    ip_string = :inet.ntoa(ip_address) |> to_string()
    unique_id = "#{:os.system_time(:millisecond)}_#{:erlang.unique_integer([:positive])}"
    node_name = String.to_atom("worker_#{unique_id}@#{ip_string}")

    {:ok, _} = Node.start(node_name)
    Node.set_cookie(:my_cookie)
    IO.puts("Processus démarré : #{Node.self()}")
    node_name
  end

  defp connect_to_supervisor(_node_name, supervisor_address) do
    if Node.connect(String.to_atom(supervisor_address)) do
      supervisor_pid =
        :rpc.call(String.to_atom(supervisor_address), Process, :whereis, [:supervisor])

      send(supervisor_pid, {:connect, self(), Node.self()})

      receive do
        {:node_list, node_info} ->
          node_info =
            case node_info do
              [{_, _} | _] -> Enum.map(node_info, fn {node, _} -> node end)
              _ -> node_info
            end

          connect_to_nodes(node_info)
          initialize_state(node_info, supervisor_pid)
      after
        5000 -> exit(:no_supervisor_response)
      end
    else
      exit(:supervisor_unreachable)
    end
  end

  defp initialize_state(node_info, supervisor_pid) do
    pn_counters = %{
      :"Product A" => PNCounter.new(),
      :"Product B" => PNCounter.new(),
      :"Product C" => PNCounter.new()
    }

    :global.register_name({:worker, Node.self()}, self())

    state = %{
      connected_nodes: Enum.reject(node_info, fn node -> node == Node.self() end),
      pn_counters: pn_counters,
      is_leader: leader?(node_info),
      supervisor_pid: supervisor_pid
    }

    loop(state)
  end

  defp leader?(node_info) do
    # Est leader s'il n'y a pas d'autres nœuds connectés
    Enum.empty?(node_info)
  end

  defp handle_update(state, product, delta) do
    updated_counter = PNCounter.update(state.pn_counters[product], Node.self(), delta)
    new_counters = Map.put(state.pn_counters, product, updated_counter)
    send_to_workers(state.connected_nodes, {:update, product, updated_counter})
    %{state | pn_counters: new_counters}
  end

  defp send_to_workers(connected_nodes, message) do
    Enum.each(connected_nodes, fn node ->
      pid = :rpc.call(node, :global, :whereis_name, [{:worker, node}])
      if is_pid(pid), do: send(pid, message)
    end)
  end

  defp loop(state) do
    IO.puts(IO.ANSI.clear())

    Enum.each(state.pn_counters, fn {product, counter} ->
      IO.puts("#{product}: #{PNCounter.value(counter)}")
    end)

    receive do
      {:counter} ->
        # Le worker envoie les compteurs actuels au superviseur
        send(state.supervisor_pid, {:counter_value, state.pn_counters, Node.self()})
        loop(state)

      {:plus, product, quantity} ->
        loop(handle_update(state, product, quantity))

      {:minus, product, quantity} ->
        loop(handle_update(state, product, -quantity))

      {:update, product, received_counter} ->
        # Fusionne les compteurs reçus avec les siens
        updated_counter = PNCounter.merge(state.pn_counters[product], received_counter)
        new_counters = Map.put(state.pn_counters, product, updated_counter)
        loop(%{state | pn_counters: new_counters})

      {:node_list, node_info} ->
        node_info =
          case node_info do
            [{_, _} | _] -> Enum.map(node_info, fn {node, _} -> node end)
            _ -> node_info
          end

        connect_to_nodes(node_info)

        new_state = %{
          state
          | connected_nodes: Enum.reject(node_info, fn node -> node == Node.self() end)
        }

        # Si ce nœud est leader, il envoie immédiatement son état aux autres
        if new_state.is_leader do
          Enum.each(new_state.pn_counters, fn {product, counter} ->
            send_to_workers(new_state.connected_nodes, {:update, product, counter})
          end)

          # Reprogrammer l'auto_update
          Process.send_after(self(), :auto_update, 5000)
        end

        loop(new_state)
    after
      2000 ->
        # Aucun message reçu après 2s, on relance la boucle
        loop(state)
    end
  end

  defp connect_to_nodes(node_info) do
    Enum.each(node_info, fn node ->
      if node != Node.self(), do: Node.connect(node)
    end)
  end
end

IO.puts("Entrez l'adresse du superviseur :")
supervisor_address = IO.gets("") |> String.trim()
WorkerProcess.start(supervisor_address)
