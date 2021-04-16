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

data:extend({
    {
        name = "MomsSpaghetti_allowed_tile",
        type = "tile",
        order = "zzz",
        collision_mask = {},
        layer = 255,
        decorative_removal_probability = 1,
        variants = {
            main = {
                {
                    picture = "__Moms_Spaghetti__/graphics/allowed_tile.png",
                    count = 1,
                    size = 1
                }
            },
            empty_transitions = true
        },
        map_color = {r=255, g=255, b=255},
        pollution_absorption_per_second = 0
    },
    {
        name = "MomsSpaghetti_chunk_chooser",
        type = "simple-entity-with-force",
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png",
        icon_size = 32,
        flags = {"not-rotatable"},
        collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
        pictures = {
            {
                filename = "__Moms_Spaghetti__/graphics/allowed_tile.png",
                width = 32,
                height = 32,
            }
        }
    },
    {
        name = "MomsSpaghetti_chunk_chooser",
        type = "item",
        order = "zzz",
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png",
        icon_size = 32,
        stack_size = 500,
        place_result = "MomsSpaghetti_chunk_chooser"
    }
})
