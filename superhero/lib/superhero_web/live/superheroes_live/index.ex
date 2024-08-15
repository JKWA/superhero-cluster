defmodule SuperheroWeb.SuperheroesLive.Index do
  use SuperheroWeb, :live_view
  require Logger
  @locations [:gotham, :metropolis, :capitol]
  @poll_interval 2_000

  @impl true
  def mount(_params, _session, socket) do
    initial_state = %{superheroes: %{}, tombstones: %{}}
    schedule_poll()

    socket
    |> assign(:data, initial_state)
    |> assign(:location_options, [:home | @locations])
    |> get_superheroes(:gotham)
    |> then(&{:ok, &1})
  end

  @impl true
  def handle_event("select_changed", %{"value" => location, "id" => id}, socket) do
    IO.puts("location: #{location}, superhero_id: #{id}")

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
  def handle_event("create", _params, socket) do
    superhero = create_superhero()
    data = socket.assigns.data

    updated_data = %{
      superheroes: Map.put_new(data.superheroes, superhero.id, superhero),
      tombstones: data.tombstones
    }

    new_data = converge_superhero(data, updated_data)
    update_superhero_data(new_data)

    {:noreply, assign(socket, :data, new_data)}
  end

  @impl true
  def handle_event("bomb", _params, socket) do
    case bomb_city() do
      {:ok, location} ->
        {:noreply, put_flash(socket, :info, "#{location} has been destroyed")}

      {:error, location} ->
        {:noreply, put_flash(socket, :error, "#{location} has not been destroyed.")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    data = socket.assigns.data

    updated_data = %{
      superheroes: Map.delete(data.superheroes, id),
      tombstones: Map.put(data.tombstones, id, true)
    }

    new_data = converge_superhero(data, updated_data)
    update_superhero_data(new_data)

    {:noreply, assign(socket, :data, new_data)}
  end

  @impl true
  def handle_info(:poll, socket) do
    schedule_poll()
    Logger.info("Polling gotham")

    {:noreply, get_superheroes(socket, :gotham)}
  end

  defp update_location(socket, superhero_id, location) do
    data = socket.assigns.data
    assign_to_location(data, superhero_id, location)
    get_superheroes(socket, location)
  end

  defp update_home(socket, superhero_id) do
    data = socket.assigns.data
    new_data = assign_to_home(data, superhero_id)
    update_superhero_data(new_data)

    assign(socket, :data, new_data)
  end

  defp get_superheroes(socket, location) do
    local_data = socket.assigns.data

    location_data =
      try do
        GenServer.call({:global, location}, :get_superheroes)
      rescue
        _ -> %{superheroes: %{}, tombstones: %{}}
      end

    combined_data = converge_superhero(local_data, location_data)
    assign(socket, :data, combined_data)
  end

  defp bomb_city() do
    location = Enum.random(@locations)

    try do
      GenServer.call({:global, location}, :bomb_city)
      {:error, location}
    catch
      :exit, _reason ->
        {:ok, location}
    end
  end

  defp create_superhero do
    %{
      id: UUID.uuid4(),
      name: Faker.Superhero.name(),
      location: :home,
      is_patrolling: false,
      last_updated: System.system_time(:second),
      health: 100
    }
  end

  defp update_superhero_data(data) do
    location = Enum.random(@locations)
    GenServer.cast({:global, location}, {:update_superheroes, data})
  end

  defp assign_to_location(data, superhero_id, location) do
    GenServer.cast({:global, location}, {:assign_superhero, data, superhero_id})
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

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  defp converge_superhero(data_a, data_b) do
    combined_superheroes =
      Map.merge(data_a.superheroes, data_b.superheroes, fn _id, sh1, sh2 ->
        if sh1.last_updated > sh2.last_updated, do: sh1, else: sh2
      end)

    combined_tombstones =
      Map.merge(data_a.tombstones, data_b.tombstones, fn _id, d1, d2 ->
        d1 or d2
      end)

    filtered_superheroes =
      Map.filter(combined_superheroes, fn {id, _} ->
        not Map.has_key?(combined_tombstones, id)
      end)

    %{superheroes: filtered_superheroes, tombstones: combined_tombstones}
  end
end
