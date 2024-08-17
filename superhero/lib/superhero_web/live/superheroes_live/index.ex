defmodule SuperheroWeb.SuperheroesLive.Index do
  use SuperheroWeb, :live_view
  alias Superhero.{Location, Data, PollServer}
  alias Phoenix.PubSub

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    PubSub.subscribe(Superhero.PubSub, PollServer.topic())

    new_socket =
      socket
      |> assign(:data, %Data{})
      |> assign(:location_options, [:home | Location.get_locations()])

    {:ok, new_socket}
  end

  @impl true
  def handle_event("create", _params, socket) do
    superhero = Data.create_superhero()
    data = socket.assigns.data

    updated_data = %{
      superheroes: Map.put_new(data.superheroes, superhero.id, superhero),
      tombstones: data.tombstones
    }

    new_data = Data.converge_superhero(data, updated_data)
    Location.update_data_to_random_location(new_data)

    new_socket =
      socket
      |> assign(:data, new_data)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    data = socket.assigns.data

    updated_data = %{
      superheroes: Map.delete(data.superheroes, id),
      tombstones: Map.put(data.tombstones, id, true)
    }

    new_data = Data.converge_superhero(data, updated_data)
    Location.update_data_to_random_location(new_data)

    {:noreply, assign(socket, :data, new_data)}
  end

  @impl true
  def handle_event("select_changed", %{"value" => location, "id" => id}, socket) do
    new_socket =
      case location do
        "gotham" -> update_location(socket, id, :gotham)
        "metropolis" -> update_location(socket, id, :metropolis)
        "capitol" -> update_location(socket, id, :capitol)
        _ -> update_home(socket, id)
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("bomb", _params, socket) do
    {:ok, bombed_location} = Location.bomb_random_city()

    new_socket =
      socket |> put_flash(:info, "#{bombed_location} has been destroyed")

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:update_data, data}, socket) do
    local_data = socket.assigns.data

    {:noreply, socket |> assign(:data, Data.converge_superhero(local_data, data))}
  end

  defp update_home(socket, superhero_id) do
    data = socket.assigns.data
    new_data = assign_to_home(data, superhero_id)
    Location.update_data_to_random_location(new_data)
    socket |> assign(:data, new_data)
  end

  defp update_location(socket, superhero_id, location) do
    new_data =
      socket.assigns.data
      |> Location.assign_to_location(superhero_id, location)

    socket
    |> assign(:data, new_data)
  end

  defp assign_to_home(data, superhero_id) do
    timestamp = System.system_time(:second)

    if Map.has_key?(data.tombstones, superhero_id) do
      Logger.warning("Attempt to assign dead superhero with ID #{superhero_id}")
      data
    else
      Logger.info("Assigning superhero with ID #{superhero_id} to home")

      updated_hero = Map.get(data.superheroes, superhero_id, %{})
      new_health = min(updated_hero.health + 20, 100)

      superheroes_updated =
        Map.put(
          data.superheroes,
          superhero_id,
          Map.merge(updated_hero, %{
            location: :home,
            is_patrolling: false,
            last_updated: timestamp,
            health: new_health
          })
        )

      %{data | superheroes: superheroes_updated}
    end
  end
end
