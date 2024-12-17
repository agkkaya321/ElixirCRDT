defmodule SupervisorNode do
  def start do
    {:ok, ifs} = :inet.getif()

    ip_address =
      ifs
      |> Enum.map(fn {ip, _broadaddr, _mask} -> ip end)
      |> Enum.find(fn ip -> ip not in [{127, 0, 0, 1}, {0, 0, 0, 0}] end)
      |> case do
        nil ->
          IO.puts("Impossible de déterminer l'adresse IP de la machine.")
          exit(:no_ip_found)

        ip ->
          ip
      end

    ip_string = :inet.ntoa(ip_address) |> to_string()
    node_name = String.to_atom("supervisor@#{ip_string}")
    {:ok, _} = Node.start(node_name)
    Node.set_cookie(:my_cookie)

    Process.register(self(), :supervisor)
    IO.puts("Supervisor started. Node address: #{Node.self()}")

    state = %{connected_nodes: [], webServer: [], monitors: %{}}

    # On planifie le premier check_counter ici, et plus jamais dans loop(state)
    Process.send_after(self(), :check_counter, 3000)

    loop(state)
  end

  defp loop(state) do
    receive do
      {:counter_value, counters, _node} ->
        # Peut afficher la velur des counters
        # Enum.each(counters, fn {product, counter} ->
        #   IO.puts("#{product}: #{PNCounter.value(counter)}")
        # end)

        loop(state)

      {:connect, from_pid, from_node} ->
        IO.puts("Connexion reçue de #{from_node}")
        ref = Node.monitor(from_node, true)

        case to_string(from_node) do
          <<"worker_", _rest::binary>> ->
            connected_nodes =
              [{from_node, from_pid} | state.connected_nodes]
              |> Enum.uniq_by(fn {node, _pid} -> node end)

            monitors = Map.put(state.monitors, ref, from_node)

            node_info = Enum.map(connected_nodes, fn {node, pid} -> {node, pid} end)
            send(from_pid, {:node_list, node_info})

            Enum.each(connected_nodes, fn {_node, pid} ->
              if pid != from_pid do
                send(pid, {:node_list, node_info})
              end
            end)

            loop(%{state | connected_nodes: connected_nodes, monitors: monitors})

          <<"webServer_", _rest::binary>> ->
            webServer =
              [{from_node, from_pid} | state.webServer]
              |> Enum.uniq_by(fn {node, _pid} -> node end)

            monitors = Map.put(state.monitors, ref, from_node)
            loop(%{state | webServer: webServer, monitors: monitors})

          _ ->
            IO.puts("Nœud inconnu non traité: #{from_node}")
            loop(state)
        end

      {:nodedown, node} ->
        IO.puts("Nœud #{node} déconnecté.")
        connected_nodes = Enum.reject(state.connected_nodes, fn {n, _pid} -> n == node end)
        webServer = Enum.reject(state.webServer, fn {n, _pid} -> n == node end)

        monitors =
          state.monitors
          |> Enum.reject(fn {_ref, n} -> n == node end)
          |> Enum.into(%{})

        node_info = Enum.map(connected_nodes, fn {n, pid} -> {n, pid} end)

        Enum.each(connected_nodes, fn {_node, pid} ->
          send(pid, {:node_list, node_info})
        end)

        loop(%{state | connected_nodes: connected_nodes, webServer: webServer, monitors: monitors})

      {:message, {signe, quantity, product}} ->
        mapped_product =
          case product do
            "A" -> :"Product A"
            "B" -> :"Product B"
            "C" -> :"Product C"
            _ -> :unknown_product
          end

        IO.puts("Action reçue: #{signe}")

        case signe do
          "+" -> plus(state, mapped_product, quantity)
          "-" -> moins(state, mapped_product, quantity)
          _ -> :ok
        end

        loop(state)

      :check_counter ->
        if state.connected_nodes != [] do
          {random_node, random_pid} = Enum.random(state.connected_nodes)
          IO.puts("Demande des compteurs à #{random_node}")
          send(random_pid, {:counter})
        end

        # Replanifier le prochain check_counter dans 3 secondes
        Process.send_after(self(), :check_counter, 3000)
        loop(state)
    after
      4000 ->
        loop(state)
    end
  end

  def plus(state, product, quantity) do
    if state.connected_nodes != [] do
      {random_node, random_pid} = Enum.random(state.connected_nodes)
      IO.puts("Envoi d'un message + à #{random_node} pour #{product}")
      send(random_pid, {:plus, product, String.to_integer(quantity)})
    else
      IO.puts("Aucun nœud connecté pour traiter #{product}.")
    end
  end

  def moins(state, product, quantity) do
    if state.connected_nodes != [] do
      {random_node, random_pid} = Enum.random(state.connected_nodes)
      IO.puts("Envoi d'un message - à #{random_node} pour #{product}")
      send(random_pid, {:minus, product, String.to_integer(quantity)})
    else
      IO.puts("Aucun nœud connecté pour traiter #{product}.")
    end
  end
end

SupervisorNode.start()
