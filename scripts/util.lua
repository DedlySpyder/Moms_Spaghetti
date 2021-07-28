local Logger = require("__DedLib__/modules/logger").create("Util")

local Util = {}

-- Accepts an allowed or denied tile name and returns the opposite of the pair
--  An allowed name returns denied or denied name returns allowed
--  This assumes that the allowed and denied prefix is the same length (a check in config hard fails when this is not the case)
function Util.invert_name_prefix(name)
    local prefixLength = #Config.Prototypes.ALLOWED_TILE_PREFIX
    local oldPrefix = string.sub(name, 1, prefixLength)
    local baseName = string.sub(name, prefixLength + 1)

    local newPrefix = Config.Prototypes.ALLOWED_TILE_PREFIX
    if oldPrefix == Config.Prototypes.ALLOWED_TILE_PREFIX then
        newPrefix = Config.Prototypes.DENIED_TILE_PREFIX
    end

    local inverted = newPrefix .. baseName
    Logger:trace("Inverting %s to %s", name, inverted)
    return inverted
end

return Util
