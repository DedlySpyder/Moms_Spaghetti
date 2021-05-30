local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Chunk Selector"}

local waterTiles = {}
for _, tile in pairs(data.raw["tile"]) do
    for _, mask in ipairs(tile.collision_mask) do
        if mask == "water-tile" then
            table.insert(waterTiles, tile.name)
            break
        end
    end
end
Logger.debug("Found water tiles: %s", waterTiles)

data:extend({
    {
        type = "selection-tool",
        name = Config.Prototypes.CHUNK_SELECTOR,
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png",
        icon_size = 32,
        flags = {"hidden", "hide-from-bonus-gui", "only-in-cursor", "not-stackable", "spawnable"},
        stack_size = 1,
        alt_selection_color = {b = 0, g = 0, r = 1},
        alt_selection_cursor_box_type = "copy",
        alt_selection_mode = {"any-tile"},
        selection_color = {b = 255, g = 255, r = 255},
        selection_cursor_box_type = "copy",
        selection_mode = {"any-tile"},
        tile_filter_mode = "blacklist",
        tile_filters = waterTiles,
        alt_tile_filter_mode = "blacklist",
        alt_tile_filters = waterTiles
    },
    {
        type = "shortcut",
        name = Config.Prototypes.CHUNK_SELECTOR,
        order = "aa",
        action = "spawn-item",
        item_to_spawn = Config.Prototypes.CHUNK_SELECTOR,
        icon = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png",
            size = 32
        },
        small_icon = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png",
            size = 32
        }
    },
    {
        type = "custom-input",
        name = Config.Prototypes.CHUNK_SELECTOR,
        key_sequence = "CONTROL + S",
        action = "spawn-item",
        item_to_spawn = Config.Prototypes.CHUNK_SELECTOR
    }
})
