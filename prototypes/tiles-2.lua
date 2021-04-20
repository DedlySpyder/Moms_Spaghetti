local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Tiles-2"}
--TODO - how to handle buildable tiles?
-- use a 2nd collision mask just for them? they can't collide with non this mod tiles, but can collide with mod tiles

local REQUIRED_COLLISION_MASKS = 1

local masks = {}
for category, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        local mask = prototype.collision_mask
        if mask and #mask > 0 then
            for _, m in ipairs(mask) do
                masks[m] = (masks[m] or 0) + 1
            end
        end
    end
end

Logger.trace("All masks:")
Logger.trace(masks, true)
local chosenMasks = {}
local numberMasks = {}
for i=55,13,-1 do
    local layer = "layer-" .. i
    if masks[layer] then
        numberMasks[layer] = masks[layer]
    elseif #chosenMasks < REQUIRED_COLLISION_MASKS then
        table.insert(chosenMasks, layer)
    end
end
Logger.trace("All numbered masks:")
Logger.trace(numberMasks, true)

if #chosenMasks < REQUIRED_COLLISION_MASKS then
    Logger.error("ALl layered masks are in use, finding the least populated masks")
    for mask, count in pairs(numberMasks) do
        if #chosenMasks < REQUIRED_COLLISION_MASKS and count < 5 then
            table.insert(chosenMasks, mask)
        end
    end

    -- TODO - FUTURE - choosing busy masks - this is good for at least a while
    if #chosenMasks < REQUIRED_COLLISION_MASKS then
        Logger.fatal("Failed to find free layers for Mom'S Spaghetti mod. Picking hardcoded layer instead")
        table.insert(chosenMasks, "layer-49")
    end
end

Logger.trace("Chosen mask(s):")
Logger.trace(chosenMasks, true)

local LAYER_ONE = chosenMasks[1]

local newPrototypes = {}
for name, tile in pairs(data.raw["tile"]) do
    if name ~= "MomsSpaghetti_allowed_tile" then
        Logger.debug("Modifying tile: " .. name)
        if not tile.collision_mask then
            tile.collision_mask = {}
        end

        if tile.minable then
            Logger.debug("Tile is minable, so creating a duplicates to swap to")
            local allowedTile = table.deepcopy(tile)
            allowedTile.name = "MomsSpaghetti_allowed_tile_" .. tile.name
            allowedTile.localised_name =  {"MomsSpaghetti_x_allowed", {"tile-name." .. tile.name}}
            allowedTile.localised_description =  {"tile-description." .. tile.name}
            allowedTile.collision_mask = {}
            allowedTile.map_color = {r=255, g=255, b=255}
            table.insert(newPrototypes, allowedTile)

            local deniedTile = table.deepcopy(tile)
            deniedTile.name = "MomsSpaghetti_denied_tile_" .. deniedTile.name
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

--TODO - need to figure out what is relevant for this
for name, entity in pairs(data.raw["assembling-machine"]) do
    Logger.debug(entity.collision_mask)
    if not entity.collision_mask then
        entity.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
    end
    Logger.debug("entity - " .. name)
    table.insert(entity.collision_mask, LAYER_ONE)
    Logger.debug(entity.collision_mask)
end
