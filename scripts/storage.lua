local Area = require("__DedLib__/modules/area")

local Storage = {}

function Storage.init()
    global.chunk_data = {} -- map of surfaceName -> map of chunk positions -> true
end

Storage.Chunks = {}
Storage.Chunks._LOGGER = require("__DedLib__/modules/logger").create("Storage/Chunks")
function Storage.Chunks._position_to_string(position)
    return serpent.line(position)
end

function Storage.Chunks.claim_chunk(surface, chunkPosition, tileCount)
    Storage.Chunks._LOGGER.debug("Adding chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return false
    end

    if not tileCount then tileCount = 1024 end

    local surfaceName = surface.name
    chunkPosition = Area.standardize_position(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    -- Make sure it's not currently owned
    local oldChunkData = Storage.Chunks.get_chunk(surface, chunkPosition)
    if oldChunkData then
        Storage.Chunks._LOGGER.warn("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " is already added")
        return false
    end

    if not global.chunk_data[surfaceName] then
        Storage.Chunks._LOGGER.debug("Adding surface to global chunk table: " .. surfaceName)
        global.chunk_data[surfaceName] = {}
    end

    Storage.Chunks._LOGGER.debug("Adding claim of chunk " .. surfaceName .. " - " .. chunkPositionString .. " - tiles " .. tileCount)
    global.chunk_data[surfaceName][chunkPositionString] = {claimed = true, fill = 0, max = tileCount} -- TODO - doc on init?
    return true
end

function Storage.Chunks.claim_chunk_from_position(surface, position, tileCount)
    Storage.Chunks._LOGGER.debug("Adding chunk by position")
    return Storage.Chunks.claim_chunk(surface, Area.get_chunk_position_from_position(position), tileCount)
end

function Storage.Chunks.get_chunk(surface, chunkPosition)
    Storage.Chunks._LOGGER.debug("Getting chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return
    end

    local surfaceName = surface.name
    chunkPosition = Area.standardize_position(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    if global.chunk_data[surfaceName] then
        local oldChunkData = global.chunk_data[surfaceName][chunkPositionString]
        if oldChunkData then
            Storage.Chunks._LOGGER.debug("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " has been claimed")
            return oldChunkData
        else
            Storage.Chunks._LOGGER.debug("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " is not claimed")
            return nil
        end
    end
    Storage.Chunks._LOGGER.debug("No owner found for chunk ".. surfaceName .. " - " .. chunkPositionString)
end

function Storage.Chunks.get_chunk_from_position(surface, position) --TODO cache lookups for just this tick?
    Storage.Chunks._LOGGER.debug("Getting chunk from position")
    return Storage.Chunks.get_chunk(surface, Area.get_chunk_position_from_position(position))
end

function Storage.Chunks.add_entity(entity)
    if entity and entity.valid then
        local entityName = entity.name
        Storage.Chunks._LOGGER.debug("Attempting to add entity" .. entityName .. " to chunk")
        local chunkData = Storage.Chunks.get_chunk_from_position(entity.surface, entity.position)
        if not chunkData then
            Storage.Chunks._LOGGER.error("Failed to add " .. entityName .. " to chunk, chunk is not claimed")
            return nil, false
        end

        local maxArea = chunkData["max"]
        local area = Area.area_of_entity(entity)
        chunkData["fill"] = math.min(chunkData["fill"] + area, maxArea)

        local percentage =  chunkData["fill"] / maxArea
        Storage.Chunks._LOGGER.info("Added " .. entityName .. " to chunk. Percent filled: " .. percentage * 100 .. "%")
        return percentage, true
    end
end

function Storage.Chunks.remove_entity(entity)
    if entity and entity.valid then
        local entityName = entity.name
        Storage.Chunks._LOGGER.debug("Attempting to remove entity" .. entityName .. " from chunk")
        local chunkData = Storage.Chunks.get_chunk_from_position(entity.surface, entity.position)
        if not chunkData then
            Storage.Chunks._LOGGER.error("Failed to remove " .. entityName .. " from chunk, chunk is not claimed")
            return nil, false
        end

        local area = Area.area_of_entity(entity)
        chunkData["fill"] = math.max(chunkData["fill"] - area, 0)

        local percentage =  chunkData["fill"] / chunkData["max"]
        Storage.Chunks._LOGGER.info("Removed " .. entityName .. " from chunk. Percent filled: " .. percentage * 100 .. "%")
        return percentage, true
    end
end

return Storage
