local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Restrict Entities-2"}

local Config = require("__Moms_Spaghetti__/scripts/config")
local Data_Util = require("data_util")

local LAYER_ONE = Data_Util.CHOSEN_MASKS[1]

for _, type in ipairs(Config.Prototypes.RESTRICTED_TYPES) do
    Logger.debug("Restricting entities of type " .. type .. " to only allowed tiles")
    for name, entity in pairs(data.raw[type]) do
        Logger.trace("Restricting " .. name)
        if not entity.collision_mask then
            entity.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
        end
        table.insert(entity.collision_mask, LAYER_ONE)
    end
end
