setup:
	@echo "Running mix deps.get in /location"
	@cd location && mix deps.get
	@echo "Running mix deps.get in /superhero"
	@cd superhero && mix deps.get