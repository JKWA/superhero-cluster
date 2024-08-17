defmodule Superhero.GossipServer do
  use GenServer
  alias Superhero.Location

  @gossip_interval 1_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def start_gossip do
    GenServer.cast(__MODULE__, :start_gossip)
  end

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

  defp schedule_gossip do
    Process.send_after(self(), :gossip, @gossip_interval)
  end

  defp gossip do
    locations = Location.get_locations()

    source = Enum.random(locations)
    destination = Enum.random(locations -- [source])

    source_data = Location.get_data(source)
    Location.update_data(source_data, destination)
  end
end
