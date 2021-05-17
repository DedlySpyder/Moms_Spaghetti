local Area = require("__DedLib__/modules/area")
local LoggerLib = require("__DedLib__/modules/logger")

local Config = require("config")

local Storage = {}


function Storage.init()
    global.chunk_data = global.chunk_data or {} -- map of surfaceName -> map of chunk positions -> true
    global.claimable_chunks = global.claimable_chunks or Config.Settings.STARTING_ALLOWED_CHUNKS -- int of chunks that can be claimed
end


-- This is the number of chunks that can still be claimed, they only move in single increments/decrements at a time
Storage.ClaimableChunks = {}
Storage.ClaimableChunks._LOGGER = LoggerLib.create("Storage/ClaimableChunks")
function Storage.ClaimableChunks.get()
    local num = global.claimable_chunks
    Storage.ClaimableChunks._LOGGER.debug("Current claimable chunks: " .. num)
    return num
end

function Storage.ClaimableChunks.increment()
    local newNum = Storage.ClaimableChunks.get() + 1

    Storage.ClaimableChunks._LOGGER.debug("Incrementing current claimable chunks to " .. newNum)
    global.claimable_chunks = newNum
    return newNum
end

function Storage.ClaimableChunks.decrement()
    local newNum = Storage.ClaimableChunks.get() - 1

    Storage.ClaimableChunks._LOGGER.debug("Decrementing current claimable chunks to " .. newNum)
    global.claimable_chunks = newNum
    return newNum
end


-- Storage of all of the chunks that have already been claimed
Storage.Chunks = {}
Storage.Chunks._LOGGER = LoggerLib.create("Storage/Chunks")
function Storage.Chunks._position_to_string(position)
    return serpent.line(position)
end

function Storage.Chunks.claim_chunk(surface, chunkPosition, tileCount, currentFill)
    Storage.Chunks._LOGGER.debug("Adding chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return false
    end

    if not tileCount then tileCount = 1024 end
    if not currentFill then currentFill = 0 end

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

    Storage.Chunks._LOGGER.debug("Adding claim of chunk " .. surfaceName .. " - " .. chunkPositionString .. " - tiles " .. tileCount .. " - fill " .. currentFill)
    global.chunk_data[surfaceName][chunkPositionString] = {claimed = true, fill = currentFill, max = tileCount}
    return true
end

function Storage.Chunks.claim_chunk_from_position(surface, position, tileCount, currentFill)
    Storage.Chunks._LOGGER.debug("Adding chunk by position")
    return Storage.Chunks.claim_chunk(surface, Area.get_chunk_position_from_position(position), tileCount, currentFill)
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

function Storage.Chunks.get_chunk_from_position(surface, position) --TODO - performance(?) - cache lookups for just this tick?
    Storage.Chunks._LOGGER.debug("Getting chunk from position")
    return Storage.Chunks.get_chunk(surface, Area.get_chunk_position_from_position(position))
end


function Storage.Chunks._crossed_fill_threshold(oldPercentage, newPercentage)
    local threshold = Config.Settings.CHUNK_PERCENTAGE_FULL_FOR_NEW_CHUNK
    if oldPercentage < threshold and threshold <= newPercentage then
        Storage.Chunks._LOGGER.debug("Crossed fill threshold upwards (old, new, threshold): (" .. oldPercentage .. "," .. newPercentage .. "," .. threshold .. ")")
        return 1
    elseif oldPercentage >= threshold and threshold > newPercentage then
        Storage.Chunks._LOGGER.debug("Crossed fill threshold downwards (old, new, threshold): (" .. oldPercentage .. "," .. newPercentage .. "," .. threshold .. ")")
        return -1
    else
        Storage.Chunks._LOGGER.debug("Did not cross fill threshold (old, new, threshold): (" .. oldPercentage .. "," .. newPercentage .. "," .. threshold .. ")")
        return 0
    end
end

function Storage.Chunks._modify_entity(entity, thresholdDirection, newFillFunc)
    local directionName = "add"
    if thresholdDirection == -1 then
        directionName = "remove"
    end

    if entity and entity.valid then
        local entityName = entity.name
        Storage.Chunks._LOGGER.debug("Attempting to " .. directionName .. " entity" .. entityName .. " to chunk")
        local chunkData = Storage.Chunks.get_chunk_from_position(entity.surface, entity.position)
        if not chunkData then
            Storage.Chunks._LOGGER.error("Failed to " .. directionName .. " " .. entityName .. " to chunk, chunk is not claimed")
            return nil, false
        end

        local maxArea = chunkData["max"]
        local currentFill = chunkData["fill"]
        local oldPercentage = currentFill / maxArea
        local area = Area.area_of_entity(entity)

        local newFill = newFillFunc(currentFill, area, maxArea) --math.min(currentFill + area, maxArea)
        chunkData["fill"] = newFill
        local percentage =  newFill / maxArea

        local crossedThreshold = Storage.Chunks._crossed_fill_threshold(oldPercentage, percentage)

        Storage.Chunks._LOGGER.info("Successfully modified " .. entityName .. " to chunk. New percent filled: " .. percentage * 100 .. "%")
        return crossedThreshold == thresholdDirection, true
    end
end

function Storage.Chunks.add_entity(entity)
    return Storage.Chunks._modify_entity(entity, 1, function(currentFill, area, maxArea)
        return math.min(currentFill + area, maxArea)
    end)
end

function Storage.Chunks.remove_entity(entity)
    return Storage.Chunks._modify_entity(entity, -1, function(currentFill, area, maxArea)
        return math.max(currentFill - area, 0)
    end)
end

return Storage
