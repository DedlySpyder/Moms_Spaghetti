local Config = require("scripts/config")

data:extend({
	-- Runtime
	{
		name = Config.MOD_PREFIX .. "_starting_allowed_chunks",
		type = "int-setting",
		setting_type = "runtime-global",
		default_value = 4,
		minimum_value = 1,
		order = "000"
	},
	{
		name = Config.MOD_PREFIX .. "_chunk_percentage_full_for_new_chunk",
		type = "double-setting",
		setting_type = "runtime-global",
		default_value = 75,
		minimum_value  = 0,
		maximum_value  = 100,
		order = "100"
	}
})
