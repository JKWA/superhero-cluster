defmodule Superhero.Application do
  @moduledoc false
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    # Attempt to connect to the Gotham node
    connect_to_gotham()
    connect_to_metropolis()
    connect_to_capitol_city()

    children = [
      # Start the Telemetry supervisor
      SuperheroWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Superhero.PubSub},
      # Start the Gossip server
      Superhero.GossipServer,
      # Start the Endpoint (http/https)
      SuperheroWeb.Endpoint
      # Add other workers or supervisors here
    ]

    # Options for the supervisor
    opts = [strategy: :one_for_one, name: Superhero.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SuperheroWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp connect_to_gotham do
    case Node.connect(:"gotham@127.0.0.1") do
      true ->
        Logger.info("Connected to Gotham node successfully.")

      false ->
        Logger.error("Failed to connect to Gotham node.")

      :ignored ->
        Logger.info("Already connected to Gotham node.")
    end
  end

  defp connect_to_metropolis do
    case Node.connect(:"metropolis@127.0.0.1") do
      true ->
        Logger.info("Connected to Metropolis node successfully.")

      false ->
        Logger.error("Failed to connect to Metropolis node.")

      :ignored ->
        Logger.info("Already connected to Metropolis node.")
    end
  end

  defp connect_to_capitol_city do
    case Node.connect(:"capitol@127.0.0.1") do
      true ->
        Logger.info("Connected to Capital City node successfully.")

      false ->
        Logger.error("Failed to connect to Capital City node.")

      :ignored ->
        Logger.info("Already connected to Capital City node.")
    end
  end
end
