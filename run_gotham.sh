#!/bin/bash
cd location
MIX_ENV=dev CITY_NAME="gotham" elixir --name gotham@127.0.0.1 --cookie superhero -S mix
