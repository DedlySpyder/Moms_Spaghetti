require("scripts/config")

data:extend({
	-- Runtime
	{
		name = Config.MOD_PREFIX .. "_starting_allowed_tiles",
		type = "int-setting",
		setting_type = "runtime-global",
		default_value = 4096,
		minimum_value = 1,
		order = "000"
	},
	{
		name = Config.MOD_PREFIX .. "_populated_tile_bonus",
		type = "double-setting",
		setting_type = "runtime-global",
		default_value = 0.75,
		minimum_value  = 0,
		maximum_value  = 1,
		order = "100"
	}
})
