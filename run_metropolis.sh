#!/bin/bash
cd location
MIX_ENV=dev CITY_NAME="metropolis" elixir --name metropolis@127.0.0.1 --cookie superhero -S mix
exec bash
