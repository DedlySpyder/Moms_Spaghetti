local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Tiles-2"}
--TODO - how to handle buildable tiles?
-- use a 2nd collision mask just for them? they can't collide with non this mod tiles, but can collide with mod tiles

local masks = {}
for category, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        local mask = prototype.collision_mask
        --Logger.trace(category .. ' - ' .. name .. ' - ' .. serpent.line(mask)) -- TODO remove
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
    elseif #chosenMasks < 2 then
        table.insert(chosenMasks, layer)
    end
end
Logger.trace("All numbered masks:")
Logger.trace(numberMasks, true)
Logger.trace("Chosen allowed masks:")
Logger.trace(chosenMasks, true)

if #chosenMasks < 2 then
    Logger.error("ALl layered masks are in use, finding the least populated masks")
    for mask, count in pairs(numberMasks) do
        if #chosenMasks < 2 and count < 5 then
            table.insert(chosenMasks, mask)
        end
    end

    -- TODO - FUTURE - choosing busy masks - this is good for at least a while, I hope
    if #chosenMasks < 2 then
        error("Failed to find free layers for Mom'S Spaghetti mod. Please report this error to the mod portal with the factorio-current.log")
    end
end

local LAYER_ONE = chosenMasks[1]
local LAYER_TWO = chosenMasks[2]

for name, tile in pairs(data.raw["tile"]) do
    if name ~= "MomsSpaghetti_allowed_tile" then
        Logger.debug(tile.collision_mask)
        if not tile.collision_mask then
            tile.collision_mask = {}
        end
        Logger.debug("tile - " .. name)
        table.insert(tile.collision_mask, LAYER_ONE)
        Logger.debug(tile.collision_mask)
    end
end

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