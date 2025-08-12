defmodule DemoRestApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    :ok = setup_cluster()

    children = [
      {Cluster.Supervisor, [topologies, [name: DemoRestApp.ClusterSupervisor]]},
      DemoRestApp.Cache,
      {Plug.Cowboy, scheme: :http, plug: DemoRestApp.Router, options: [port: 4000]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoRestApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp setup_cluster do
    Node.list()
    |> Enum.each(&:net_adm.ping/1)
  end

end
