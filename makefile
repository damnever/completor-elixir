prepare:
	cd ./sense_wrapper && mix deps.get
	cd ./sense_wrapper && MIX_ENV=prod mix compile
