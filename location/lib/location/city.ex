defmodule Location.City do
  use GenServer
  require Logger

  @patrol_interval 5_000
  @fight_interval 5_000

  def start_link(city_name) do
    GenServer.start_link(
      __MODULE__,
      %{city_name: city_name, data: %{superheroes: %{}, tombstones: %{}}},
      name: {:global, String.to_atom(city_name)}
    )
  end

  @impl true
  def init(state) do
    schedule_patrol()
    schedule_fight()
    {:ok, state}
  end

  @impl true
  def handle_call(:get_superheroes, _from, state) do
    {:reply, state.data, state}
  end

  @impl true
  def handle_call({:assign_superhero, incoming_data, superhero_id}, _from, state) do
    timestamp = System.system_time(:second)

    combined_data = converge_superhero(state.data, incoming_data)

    if Map.has_key?(combined_data.tombstones, superhero_id) do
      Logger.warning("Attempt to assign dead superhero with ID #{superhero_id}")
      {:noreply, state}
    else
      Logger.info("Assigning superhero with ID #{superhero_id} to #{state.city_name}")

      updated_hero = Map.get(combined_data.superheroes, superhero_id, %{})

      new_health = min(updated_hero.health + 20, 100)

      superheroes_updated =
        Map.put(
          combined_data.superheroes,
          superhero_id,
          Map.merge(updated_hero, %{
            location: state.city_name,
            last_updated: timestamp,
            is_patrolling: false,
            health: new_health
          })
        )

      new_state = update_state(state, superheroes_updated, combined_data.tombstones)

      {:reply, new_state.data, new_state}
    end
  end

  def handle_cast(:bomb_city, _from, state) do
    Logger.info("#{state.city_name} is being bombed!")
    exit(:boom)
  end

  @impl true
  def handle_cast({:update_superheroes, updated_data}, state) do
    Logger.info("Updating superheroes with new data for #{state.city_name}")

    combined_data = converge_superhero(state.data, updated_data)

    {:noreply, update_state(state, combined_data.superheroes, combined_data.tombstones)}
  end

  @impl true
  def handle_info(:set_patrol, state) do
    schedule_patrol()
    {:noreply, state |> set_superhero_patrolling()}
  end

  @impl true
  def handle_info(:fight_villain, state) do
    state = fight_villain(state)
    schedule_fight()
    {:noreply, state}
  end

  defp schedule_patrol do
    Process.send_after(self(), :set_patrol, @patrol_interval)
  end

  defp schedule_fight do
    Process.send_after(self(), :fight_villain, @fight_interval)
  end

  defp set_superhero_patrolling(state) do
    city_superheroes = get_superheroes_in_city(state)

    if Enum.empty?(city_superheroes) do
      Logger.info("No superheroes available to patrol in #{state.city_name}")
      state
    else
      random_id = Enum.random(city_superheroes)
      updated_heroes = set_hero_patrolling(state, random_id)

      superhero_name = updated_heroes[random_id].name

      Logger.info("Dispatch #{superhero_name} is now patrolling in #{state.city_name}")
      update_state(state, updated_heroes, state.data.tombstones)
    end
  end

  defp get_superheroes_in_city(state) do
    state.data.superheroes
    |> Enum.filter(fn {_id, hero} -> hero.location == state.city_name end)
    |> Enum.map(fn {id, _hero} -> id end)
  end

  defp set_hero_patrolling(state, superhero_id) do
    timestamp = System.system_time(:second)

    Map.update!(state.data.superheroes, superhero_id, fn hero ->
      %{hero | is_patrolling: true, last_updated: timestamp}
    end)
  end

  defp fight_villain(state) do
    patrolling_superheroes = get_patrolling_superheroes(state)

    if Enum.empty?(patrolling_superheroes) do
      Logger.info("No patrolling superheroes available to fight in #{state.city_name}")
      state
    else
      random_id = Enum.random(patrolling_superheroes)
      updated_heroes = update_superhero_health(state, random_id)

      if superhero_defeated?(updated_heroes[random_id]) do
        remove_defeated_superhero(state, updated_heroes, random_id)
      else
        update_state(state, updated_heroes, state.data.tombstones)
      end
    end
  end

  defp get_patrolling_superheroes(state) do
    state.data.superheroes
    |> Enum.filter(fn {_id, hero} ->
      hero.location == state.city_name and hero.is_patrolling
    end)
    |> Enum.map(fn {id, _hero} -> id end)
  end

  defp update_superhero_health(state, superhero_id) do
    health_reduction = :rand.uniform(11) + 4
    timestamp = System.system_time(:second)

    Map.update!(state.data.superheroes, superhero_id, fn hero ->
      new_health = hero.health - health_reduction
      log_fight_result(hero.name, health_reduction, new_health, state.city_name)
      %{hero | health: max(new_health, 0), last_updated: timestamp}
    end)
  end

  defp superhero_defeated?(hero) do
    hero.health <= 0
  end

  defp remove_defeated_superhero(state, updated_heroes, superhero_id) do
    updated_heroes = Map.delete(updated_heroes, superhero_id)
    updated_tombstones = Map.put(state.data.tombstones, superhero_id, true)

    update_state(state, updated_heroes, updated_tombstones)
  end

  defp converge_superhero(local_data, updated_data) do
    combined_superheroes =
      Map.merge(local_data.superheroes, updated_data.superheroes, fn _id, sh1, sh2 ->
        if sh1.last_updated > sh2.last_updated, do: sh1, else: sh2
      end)

    combined_tombstones =
      Map.merge(local_data.tombstones, updated_data.tombstones, fn _id, d1, d2 ->
        d1 or d2
      end)

    filtered_superheroes =
      Map.filter(combined_superheroes, fn {id, _} ->
        not Map.has_key?(combined_tombstones, id)
      end)

    %{superheroes: filtered_superheroes, tombstones: combined_tombstones}
  end

  defp update_state(state, superheroes, tombstones) do
    %{state | data: %{superheroes: superheroes, tombstones: tombstones}}
  end

  defp log_fight_result(superhero_name, health_reduction, new_health, city_name) do
    if new_health <= 0 do
      Logger.info("Dispatch #{superhero_name} lost the fight and was removed from #{city_name}")
    else
      Logger.info(
        "Dispatch #{superhero_name} fought a villain and lost #{health_reduction} health points. Remaining health: #{new_health}"
      )
    end
  end
end
