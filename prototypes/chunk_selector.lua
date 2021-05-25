data:extend({
    {
        type = "item",
        name = Config.Prototypes.CHUNK_SELECTOR,
        order = "zzz",
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png",
        icon_size = 32,
        flags = {"hidden", "hide-from-bonus-gui", "only-in-cursor", "not-stackable", "spawnable"},
        stack_size = 1,
        place_result = Config.Prototypes.CHUNK_SELECTOR
    },
    {
        type = "simple-entity",
        name = Config.Prototypes.CHUNK_SELECTOR,
        icon = "__Moms_Spaghetti__/graphics/allowed_tile.png",
        icon_size = 32,
        flags = {"not-rotatable", "placeable-player", "player-creation", "not-upgradable"},
        collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
        collision_mask = {},
        picture = {
            filename = "__Moms_Spaghetti__/graphics/allowed_tile.png",
            size = 32,
        }
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
