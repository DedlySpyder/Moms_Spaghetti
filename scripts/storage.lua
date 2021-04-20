local AREA = require("__DedLib__/modules/area")

local Storage = {}

function Storage.init()
    global.chunk_data = {} -- map of surfaceName -> map of chunk positions -> true
end

Storage.Chunks = {}
Storage.Chunks._LOGGER = require("__DedLib__/modules/logger").create("Storage/Chunks")
function Storage.Chunks._position_to_string(position)
    return serpent.line(position)
end

function Storage.Chunks.add_chunk(surface, chunkPosition)
    Storage.Chunks._LOGGER.debug("Adding chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return false
    end

    local surfaceName = surface.name
    chunkPosition = AREA.standardize_position(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    -- Make sure it's not currently owned
    local oldChunkData = Storage.Chunks.get_chunk(surface, chunkPosition)
    if oldChunkData then
        Storage.Chunks._LOGGER.warn("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " is already added")
        return false
    end

    if not global[surfaceName] then
        Storage.Chunks._LOGGER.debug("Adding surface to global chunk table: " .. surfaceName)
        global[surfaceName] = {}
    end

    Storage.Chunks._LOGGER.debug("Adding claim of chunk " .. surfaceName .. " - " .. chunkPositionString)
    global[surfaceName][chunkPositionString] = true
    return true
end

function Storage.Chunks.add_chunk_from_position(surface, position)
    Storage.Chunks._LOGGER.debug("Adding chunk by position")
    return Storage.Chunks.add_chunk(surface, AREA.get_chunk_position_from_position(position))
end

function Storage.Chunks.get_chunk(surface, chunkPosition)
    Storage.Chunks._LOGGER.debug("Getting chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return
    end

    local surfaceName = surface.name
    chunkPosition = AREA.standardize_position(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    if global[surfaceName] then
        local oldChunkData = global[surfaceName][chunkPositionString]
        if oldChunkData then
            Storage.Chunks._LOGGER.debug("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " has been claimed")
            return true
        else
            Storage.Chunks._LOGGER.debug("Chunk " .. surfaceName .. " - " .. chunkPositionString .. " is not claimed")
            return false
        end
    end
    Storage.Chunks._LOGGER.debug("No owner found for chunk ".. surfaceName .. " - " .. chunkPositionString)
end

function Storage.Chunks.get_chunk_from_position(surface, position)
    Storage.Chunks._LOGGER.debug("Getting chunk from position")
    return Storage.Chunks.get_chunk(surface, AREA.get_chunk_position_from_position(position))
end

return Storage
