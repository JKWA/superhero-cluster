defmodule Location.Application do
  use Application

  @impl true
  def start(_type, _args) do
    city_name = System.get_env("CITY_NAME")

    children = [
      {Location.City, city_name}
    ]

    opts = [
      strategy: :one_for_one,
      max_restarts: 3,
      max_seconds: 5,
      name: Location.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
