defmodule Superhero.GossipServer do
  use GenServer
  require Logger

  @gossip_interval 1_000
  @locations [:gotham, :metropolis, :capitol]

  # Public API
  def start_link(_) do
    IO.puts("Starting GossipServer")
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_gossip do
    GenServer.cast(__MODULE__, :start_gossip)
  end

  # GenServer Callbacks
  @impl true
  def init(state) do
    schedule_gossip()
    {:ok, state}
  end

  @impl true
  def handle_cast(:start_gossip, state) do
    gossip()
    schedule_gossip()
    {:noreply, state}
  end

  @impl true
  def handle_info(:gossip, state) do
    gossip()
    schedule_gossip()
    {:noreply, state}
  end

  # Private functions
  defp schedule_gossip do
    # Schedules the next gossip event after the interval
    Process.send_after(self(), :gossip, @gossip_interval)
  end

  defp gossip do
    source = Enum.random(@locations)

    source_data = GenServer.call({:global, source}, :get_superheroes)

    destination = Enum.random(@locations -- [source])

    GenServer.cast({:global, destination}, {:update_superheroes, source_data})

    # Logger.info("Gossiped data from #{source} to #{destination}")
  end
end
