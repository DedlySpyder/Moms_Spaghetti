local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Restrict Entities-2"}
local Data_Util = require("data_util")

local LAYER_ONE = Data_Util.CHOSEN_MASKS[1]

for _, rType in ipairs(Config.Prototypes.RESTRICTED_TYPES) do
    Logger.debug("Restricting entities of type %s to only allowed tiles", rType)
    for name, entity in pairs(data.raw[rType]) do
        Logger.trace("Restricting %s", name)
        if not entity.collision_mask then
            entity.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
        end
        table.insert(entity.collision_mask, LAYER_ONE)
    end
end
