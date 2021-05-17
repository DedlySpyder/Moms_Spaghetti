local Logger = require("__DedLib__/modules/logger").create("Area Management")
local Area = require("__DedLib__/modules/area")

local Storage = require("storage")
local Config = require("config")
local Util = require("util")
local Gui = require("gui")

local Area_Management = {}

function Area_Management.convert_chunk(surface, position, player)
    Logger.debug("Attempting to convert chunk")
    local claimableChunks = Storage.ClaimableChunks.get()
    if claimableChunks < 1 then
        Logger.warn("Not enough chunks left to claim this one")
        player.print({"MomsSpaghetti_warn_convert_chunk_failed_not_enough_claimable_chunks"})
        return false
    end
    position = Area.standardize_position(position)
    local oldChunkData = Storage.Chunks.get_chunk_from_position(surface, position)
    if oldChunkData then
        Logger.warn("Chunk " .. surface.name .. " " .. serpent.line(position) .. " has already been claimed")
        player.print({"MomsSpaghetti_warn_convert_chunk_failed_already_claimed"})
        return false
    end

    Logger.debug("Converting chunk at position: " .. serpent.line(position))
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

    -- TODO - this doesn't take into account entities that are already there (trees, ship, etc)
    local currentTiles = surface.find_tiles_filtered{area = area}
    local tiles = {}
    for _, tile in ipairs(currentTiles) do
        if string.sub(tile.name, 1, #Config.Prototypes.DENIED_TILE_PREFIX) == Config.Prototypes.DENIED_TILE_PREFIX then
            table.insert(tiles, {name = Util.invert_name_prefix(tile.name), position = tile.position})
        elseif not tile.collides_with("water-tile") then
            table.insert(tiles, {name = Config.Prototypes.ALLOWED_TILE, position = tile.position})
        end
    end

    local tileCount = #tiles
    Logger.debug("Converting " .. tileCount .. " tiles to allowed placement tiles")
    Logger.trace(tiles)

    surface.set_tiles(tiles)
    local claimed = Storage.Chunks.claim_chunk_from_position(surface, position, tileCount)

    if claimed then
        Storage.ClaimableChunks.decrement()
        Gui.ClaimableChunkCounter.updateAll()
        return true
    end
end

function Area_Management.replace_tile(surface, tiles, tileName)
    Logger.debug("Replacing " .. #tiles .. " tiles")
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


function Area_Management.add_entity(entity)
    Logger.debug("Adding entity " .. entity.name)
    local thresholdCrossed, added = Storage.Chunks.add_entity(entity)
    if added and thresholdCrossed then
        Logger.info("Entity added crossed threshold upwards, so incrementing chunk count")
        Storage.ClaimableChunks.increment()
        Gui.ClaimableChunkCounter.updateAll()
    end
end

function Area_Management.remove_entity(entity)
    Logger.debug("Removing entity " .. entity.name)
    local thresholdCrossed, added = Storage.Chunks.remove_entity(entity)
    if added and thresholdCrossed then
        Logger.info("Entity removed crossed threshold downwards, so decrementing chunk count")
        Storage.ClaimableChunks.decrement()
        Gui.ClaimableChunkCounter.updateAll()
    end
end

return Area_Management