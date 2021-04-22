local Logger = require("__DedLib__/modules/logger").create("Util")

local Config = require("config")

local Util = {}

function Util.invert_name_prefix(name)
    local prefixLength = #Config.Prototypes.ALLOWED_TILE_PREFIX
    local oldPrefix = string.sub(name, 1, prefixLength)
    local baseName = string.sub(name, prefixLength + 1)

    local newPrefix = Config.Prototypes.ALLOWED_TILE_PREFIX
    if oldPrefix == Config.Prototypes.ALLOWED_TILE_PREFIX then
        newPrefix = Config.Prototypes.DENIED_TILE_PREFIX
    end

    local inverted = newPrefix .. baseName
    Logger.trace("Inverting " .. name .. " to " .. inverted)
    return inverted
end

return Util
