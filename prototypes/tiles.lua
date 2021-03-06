data:extend({
    {
        name = Config.Prototypes.ALLOWED_TILE,
        type = "tile",
        order = "zzz",
        collision_mask = {"ground-tile"},
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
    }
})
