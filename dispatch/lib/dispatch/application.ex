defmodule Dispatch.Application do
  require Logger
  use Application
  @nodes ["gotham@127.0.0.1", "metropolis@127.0.0.1", "capitol@127.0.0.1"]

  @impl true
  def start(_type, _args) do
    connect_to_nodes(@nodes)

    children = [
      DispatchWeb.Telemetry,
      {Phoenix.PubSub, name: Dispatch.PubSub},
      Dispatch.GossipServer,
      Dispatch.PollServer,
      DispatchWeb.Endpoint
    ]

    opts = [
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 1,
      name: Dispatch.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    DispatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp connect_to_nodes(nodes) do
    Enum.each(nodes, fn node ->
      case Node.connect(String.to_atom(node)) do
        true -> Logger.info("Connected to #{node} successfully.")
        false -> Logger.error("Failed to connect to #{node}.")
        :ignored -> Logger.info("Already connected to #{node}.")
      end
    end)
  end
end
