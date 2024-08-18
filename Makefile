setup:
	@echo "Running mix deps.get in /location"
	@cd location && mix deps.get
	@echo "Cleaning old builds in /location"
	@cd location && mix clean
	@echo "Compiling new build in /location"
	@cd location && mix compile
	@echo "Running mix deps.get in /dispatch"
	@cd dispatch && mix deps.get
	@echo "Cleaning old builds in /dispatch"
	@cd dispatch && mix clean
	@echo "Compiling new build in /dispatch"
	@cd dispatch && mix compile
