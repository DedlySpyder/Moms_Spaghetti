local Logger = require("__DedLib__/modules/logger").create("Config")

local Config = {}

Config.MOD_PREFIX = "MomsSpaghetti"

Config.Prototypes = {}
Config.Prototypes.ALLOWED_TILE = Config.MOD_PREFIX .. "_allowed_tile"
Config.Prototypes.CHUNK_SELECTOR = Config.MOD_PREFIX .. "_chunk_selector"

-- These 2 MUST be the same length, for inversion logic in Util.invert_name_prefix
Config.Prototypes.ALLOWED_TILE_PREFIX = Config.MOD_PREFIX .. "_allowed_tile_"
Config.Prototypes.DENIED_TILE_PREFIX = Config.MOD_PREFIX .. "_denied0_tile_"
if #Config.Prototypes.ALLOWED_TILE_PREFIX ~= #Config.Prototypes.DENIED_TILE_PREFIX then
    Logger.fatal("Allowed and denied tile prefixes are not equal length")
    error("MOD BROKEN: I'm a doofus, please post this on the mod portal - Allowed and denied tile prefixes are not equal length")
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


Config.Settings = {}

if settings and settings.global then
    Config.Settings.STARTING_ALLOWED_CHUNKS = settings.global[Config.MOD_PREFIX .. "_starting_allowed_chunks"].value
    Config.Settings.CHUNK_PERCENTAGE_FULL_FOR_NEW_CHUNK = settings.global[Config.MOD_PREFIX .. "_chunk_percentage_full_for_new_chunk"].value / 100
end

Logger.trace("Config values:")
Logger.trace(Config, true)

return Config