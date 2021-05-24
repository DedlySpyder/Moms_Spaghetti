local Logger = require("__DedLib__/modules/logger").create("Area Management")
local Area = require("__DedLib__/modules/area")
local Entity = require("__DedLib__/modules/entity")
local Position = require("__DedLib__/modules/position")

local Storage = require("storage")
local Config = require("config")
local Util = require("util")
local Gui = require("gui")

--[[
Handle all the management of the claimed chunks

These chunks are the only spot where normal base entities (furnaces/assembling machines, etc) can be placed. When each
chunk is  above a certain percentage full, then a new chunk can be claimed.
]]--
local Area_Management = {}

-- Claim a whole chunk and convert the current tiles to allowed tiles
function Area_Management.convert_chunk(surface, position, player)
    Logger.debug("Attempting to convert chunk")
    local claimableChunks = Storage.ClaimableChunks.get()
    if claimableChunks < 1 then
        Logger.warn("Not enough chunks left to claim this one")
        player.print({"MomsSpaghetti_warn_convert_chunk_failed_not_enough_claimable_chunks"})
        return false
    end
    position = Position.standardize(position)
    local oldChunkData, chunkPosition = Storage.Chunks.get_chunk_from_position(surface, position)
    if oldChunkData then
        Logger.warn("Chunk %s on surface %s has already been claimed", position, surface.name)
        player.print({"MomsSpaghetti_warn_convert_chunk_failed_already_claimed"})
        return false
    end

    Logger.debug("Converting chunk at position: %s", position)
    local area = Area.get_chunk_area_from_position(position)

    local xDelta
    if area.left_top.x < area.right_bottom.x then
        xDelta = 1
    else
        xDelta = -1
    end

    local yDelta
    if area.left_top.y < area.right_bottom.y then
        yDelta = 1
    else
        yDelta = -1
    end

    local currentTiles = surface.find_tiles_filtered{area = area}
    local tiles = {}
    for _, tile in ipairs(currentTiles) do
        if string.sub(tile.name, 1, #Config.Prototypes.DENIED_TILE_PREFIX) == Config.Prototypes.DENIED_TILE_PREFIX then
            table.insert(tiles, {name = Util.invert_name_prefix(tile.name), position = tile.position})
        elseif not tile.collides_with("water-tile") then
            table.insert(tiles, {name = Config.Prototypes.ALLOWED_TILE, position = tile.position})
        end
    end

    local entities = surface.find_entities_filtered{area = area, collision_mask = "object-layer"}
    local takenSpace = 0
    for _, entity in ipairs(entities) do
        local areas_by_chunks = Entity.area_of_by_chunks(entity)
        for _, area_by_chunk in ipairs(areas_by_chunks) do
            local chunk = area_by_chunk["chunk"]
            if chunk.x == chunkPosition.x and chunk.y == chunkPosition.y then
                takenSpace = takenSpace + area_by_chunk["area"]
                break
            end
        end
    end

    local tileCount = #tiles
    Logger.debug("Converting %d tiles to allowed placement tiles", tileCount)
    Logger.trace(tiles)

    surface.set_tiles(tiles)
    local claimed = Storage.Chunks.claim_chunk_from_position(surface, position, tileCount, takenSpace)

    if claimed then
        Storage.ClaimableChunks.decrease()
        Gui.ClaimableChunkCounter.updateAll()
        return true
    end
end

-- Replace tiles that are placeable by players
-- There are either allowed or denied versions of all of these, and each one is checked to see which version is needed
function Area_Management.replace_tile(surface, tiles, tileName)
    Logger.debug("Replacing %d tiles", #tiles)
    local allowedTileName = Config.Prototypes.ALLOWED_TILE_PREFIX .. tileName
    local deniedTileName = Config.Prototypes.DENIED_TILE_PREFIX .. tileName

    for _, tile in ipairs(tiles) do
        if Storage.Chunks.get_chunk_from_position(surface, tile.position) then
            tile["name"] = allowedTileName
        else
            tile["name"] = deniedTileName
        end
    end

    Logger.trace(tiles)
    surface.set_tiles(tiles)
end


-- Add/remove an entity from a chunk. Storage will handle the exact logic on if the chunk is being tracked and if we
-- should change the chunks remaining to claim count
function Area_Management.add_entity(entity)
    Logger.debug("Adding entity %s", entity.name)
    local thresholdsCrossed = Storage.Chunks.add_entity(entity)
    if thresholdsCrossed > 0 then
        Logger.info("Entity added crossed %d threshold(s) upwards, so incrementing chunk count", thresholdsCrossed)
        Storage.ClaimableChunks.increase(thresholdsCrossed)
        Gui.ClaimableChunkCounter.updateAll()
    end
end

function Area_Management.remove_entity(entity)
    Logger.debug("Removing entity %s", entity.name)
    local thresholdsCrossed = Storage.Chunks.remove_entity(entity)
    if thresholdsCrossed > 0 then
        Logger.info("Entity removed crossed %d threshold(s) downwards, so decrementing chunk count", thresholdsCrossed)
        Storage.ClaimableChunks.decrease(thresholdsCrossed)
        Gui.ClaimableChunkCounter.updateAll()
    end
end

return Area_Management