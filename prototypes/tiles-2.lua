local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Tiles-2"}

local Config = require("__Moms_Spaghetti__/scripts/config")
local Data_Util = require("data_util")

local LAYER_ONE = Data_Util.CHOSEN_MASKS[1]

local newPrototypes = {}
for name, tile in pairs(data.raw["tile"]) do
    if name ~= Config.Prototypes.ALLOWED_TILE then
        Logger.debug("Modifying tile: " .. name)
        if not tile.collision_mask then
            tile.collision_mask = {}
        end

        if tile.minable then
            Logger.debug("Tile is minable, so creating allow/deny copies")
            local allowedTile = table.deepcopy(tile)
            allowedTile.name = Config.Prototypes.ALLOWED_TILE_PREFIX .. tile.name
            allowedTile.localised_name =  {"MomsSpaghetti_X_allowed", {"tile-name." .. tile.name}}
            allowedTile.localised_description =  {"tile-description." .. tile.name}
            allowedTile.collision_mask = {}
            allowedTile.map_color = {r=255, g=255, b=255}
            table.insert(newPrototypes, allowedTile)

            local deniedTile = table.deepcopy(tile)
            deniedTile.name = Config.Prototypes.DENIED_TILE_PREFIX .. deniedTile.name
            deniedTile.localised_name = {"MomsSpaghetti_X_denied", {"tile-name." .. tile.name}}
            deniedTile.localised_description =  {"tile-description." .. tile.name}
            table.insert(deniedTile.collision_mask, LAYER_ONE)
            table.insert(newPrototypes, deniedTile)
        else
            Logger.debug("Tile is not minable, adding chosen collision mask")
            table.insert(tile.collision_mask, LAYER_ONE)
        end
    end
end
data:extend(newPrototypes)
