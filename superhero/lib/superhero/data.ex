defmodule Superhero.Data do
  defstruct superheroes: %{},
            tombstones: %{}

  @type superhero :: %{
          id: String.t(),
          name: String.t(),
          location: atom(),
          is_patrolling: boolean(),
          last_updated: integer(),
          health: integer()
        }

  @type t :: %__MODULE__{
          superheroes: %{String.t() => superhero()},
          tombstones: %{String.t() => boolean()}
        }

  @spec create_superhero() :: superhero()
  def create_superhero do
    %{
      id: UUID.uuid4(),
      name: Faker.Superhero.name(),
      location: :home,
      is_patrolling: false,
      last_updated: System.system_time(:second),
      health: 100
    }
  end

  @spec converge_superhero(t(), t()) :: t()
  def converge_superhero(data_a, data_b) do
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
