local Logger = require("__DedLib__/modules/logger").create("Config")

Config = {}

Config.MOD_PREFIX = "MomsSpaghetti"

Config.Prototypes = {}
Config.Prototypes.ALLOWED_TILE = Config.MOD_PREFIX .. "_allowed_tile"
Config.Prototypes.CHUNK_SELECTOR = Config.MOD_PREFIX .. "_chunk_selector" -- TODO - rename - this isn't a chunk selector anymore

-- These 2 MUST be the same length, for inversion logic in Util.invert_name_prefix
Config.Prototypes.ALLOWED_TILE_PREFIX = Config.MOD_PREFIX .. "_allowed_tile_"
Config.Prototypes.DENIED_TILE_PREFIX = Config.MOD_PREFIX .. "_denied0_tile_"
if #Config.Prototypes.ALLOWED_TILE_PREFIX ~= #Config.Prototypes.DENIED_TILE_PREFIX then
    Logger.fatal("Allowed and denied tile prefixes are not equal length")
    error("MOD BROKEN: Please post this on the mod portal - Allowed and denied tile prefixes are not equal length")
end

Config.Prototypes.RESTRICTED_TYPES = {
    "accumulator",
    "assembling-machine",
    "beacon",
    "boiler",
    "burner-generator",
    "furnace",
    "generator",
    "lab",
    "reactor",
    "rocket-silo",
    "solar-panel",
}


-- This file is used in the settings phase, so the settings global does not exist there
Config.Settings = {}
if settings and settings.global then
    Config.Settings.STARTING_ALLOWED_TILES_NAME = Config.MOD_PREFIX .. "_starting_allowed_tiles"
    Config.Settings.POPULATED_TILE_BONUS_NAME = Config.MOD_PREFIX .. "_populated_tile_bonus"

    function Config.Settings.Refresh()
        Logger.info("Refreshing config values")
        Config.Settings.STARTING_ALLOWED_TILES = settings.global[Config.Settings.STARTING_ALLOWED_TILES_NAME].value
        Config.Settings.POPULATED_TILE_BONUS = settings.global[Config.Settings.POPULATED_TILE_BONUS_NAME].value
    end

    Config.Settings.Refresh()
end

Logger.trace_block("Config values: %s", Config)
