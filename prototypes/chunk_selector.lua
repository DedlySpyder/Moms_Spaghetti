data:extend({
    {
        type = "item",
        name = "MomsSpaghetti_chunk_selector",
        order = "zzz",
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png", --TODO - plate icon
        icon_size = 32,
        flags = {"hidden", "hide-from-bonus-gui", "only-in-cursor", "not-stackable", "spawnable"},
        stack_size = 1,
        place_result = "MomsSpaghetti_chunk_selector"
    },
    {
        type = "simple-entity",
        name = "MomsSpaghetti_chunk_selector",
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png", --TODO - plate icon
        icon_size = 32,
        flags = {"not-rotatable", "placeable-player", "player-creation", "not-upgradable"},
        collision_box = {{-0.5, -0.5}, {0.5, 0.5}}, --TODO
        collision_mask = {},
        picture = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png", -- TODO plate icon (not seen)
            size = 32,
        }
    },
    {
        type = "shortcut", -- TODO swap something out when the player is spawned for this?
        name = "MomsSpaghetti_chunk_selector",
        order = "aa",
        action = "spawn-item",
        item_to_spawn = "MomsSpaghetti_chunk_selector",
        icon = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png", --TODO - plate icon
            size = 32
        },
        small_icon = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png", --TODO - plate icon
            size = 32
        }
    }
})
