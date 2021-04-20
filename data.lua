local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti"}
--TODO - how to handle buildable tiles?
        -- use a 2nd collision mask just for them? they can't collide with non this mod tiles, but can collide with mod tiles

for name, tile in pairs(data.raw["tile"]) do
    Logger.debug(tile.collision_mask)
    if not tile.collision_mask then
        tile.collision_mask = {}
    end
    Logger.debug("tile - " .. name)
    table.insert(tile.collision_mask, "layer-49")
    Logger.debug(tile.collision_mask)
end

--TODO - need to figure out what is relevant for this
for name, entity in pairs(data.raw["assembling-machine"]) do
    Logger.debug(entity.collision_mask)
    if not entity.collision_mask then
        entity.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
    end
    Logger.debug("entity - " .. name)
    table.insert(entity.collision_mask, "layer-49")
    Logger.debug(entity.collision_mask)
end

require("prototypes/chunk_selector")
require("prototypes/tiles")
