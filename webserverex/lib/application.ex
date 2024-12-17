defmodule Webserverex.Application do
  use Application

  def start(_type, _args) do
    IO.puts("Entrez l'adresse du superviseur (par ex., supervisor@ip_address) :")
    supervisor_address = IO.gets("") |> String.trim()

    connect_to_supervisor(supervisor_address)

    # Liste des processus enfants à superviser
    enfants = [
      {Plug.Cowboy, scheme: :http, plug: Webserverex.Router, options: [port: 4000]}
    ]

    # Options de supervision
    opts = [strategy: :one_for_one, name: Webserverex.Superviseur]
    Supervisor.start_link(enfants, opts)
  end

  defp connect_to_supervisor(supervisor_address) do
    {:ok, ifs} = :inet.getif()

    ip_address =
      ifs
      |> Enum.map(fn {ip, _broadaddr, _mask} -> ip end)
      |> Enum.find(fn ip -> ip not in [{127, 0, 0, 1}, {0, 0, 0, 0}] end)

    unless ip_address do
      IO.puts("Impossible de déterminer l'adresse IP de la machine.")
      exit(:no_ip_found)
    end

    ip_string = :inet.ntoa(ip_address) |> to_string()
    unique_id = "#{:os.system_time(:millisecond)}_#{:erlang.unique_integer([:positive])}"
    node_name = String.to_atom("webServer_#{unique_id}@#{ip_string}")

    {:ok, _} = Node.start(node_name)
    Node.set_cookie(:my_cookie)

    IO.puts("Processus démarré. Adresse du nœud : #{Node.self()}")

    if Node.connect(String.to_atom(supervisor_address)) do
      IO.puts("Connecté au superviseur à #{supervisor_address}")

      supervisor_pid =
        :rpc.call(String.to_atom(supervisor_address), Process, :whereis, [:supervisor])

      if is_pid(supervisor_pid) do
        # On stocke le PID du superviseur dans la configuration de l'application
        Application.put_env(:webserverex, :supervisor_pid, supervisor_pid)
        send(supervisor_pid, {:connect, self(), Node.self()})
      else
        IO.puts("Impossible d'atteindre le superviseur.")
        exit(:supervisor_unreachable)
      end
    else
      IO.puts("Impossible de se connecter au superviseur.")
      exit(:supervisor_unreachable)
    end
  end

  def send_message(signe, number, product) do
    supervisor_pid = Application.get_env(:webserverex, :supervisor_pid)

    if is_pid(supervisor_pid) do
      send(supervisor_pid, {:message, {signe, number, product}})
    else
      IO.puts("Impossible d'atteindre le superviseur.")
    end
  end
end
