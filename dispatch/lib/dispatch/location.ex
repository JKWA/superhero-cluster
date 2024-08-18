defmodule Dispatch.Location do
  @locations [:gotham, :metropolis, :capitol]

  def get_locations do
    @locations
  end

  def get_data(location) when location in @locations do
    GenServer.call({:global, location}, :get_superheroes)
  end

  def get_data_from_random_location do
    location = Enum.random(@locations)
    get_data(location)
  end

  def update_data(data, location) when location in @locations do
    GenServer.cast({:global, location}, {:update_superheroes, data})
  end

  def update_data_to_random_location(data) do
    location = Enum.random(@locations)
    update_data(data, location)
  end

  def assign_to_location(data, superhero_id, location) when location in @locations do
    GenServer.call({:global, location}, {:assign_superhero, data, superhero_id})
  end

  def bomb_random_city do
    location = Enum.random(@locations)
    GenServer.cast({:global, location}, :bomb_city)
    {:ok, location}
  end
end
