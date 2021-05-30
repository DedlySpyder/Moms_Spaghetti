local LoggerLib = require("__DedLib__/modules/logger")
local Area = require("__DedLib__/modules/area")
local Entity = require("__DedLib__/modules/entity")
local Position = require("__DedLib__/modules/position")

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
    Storage.ClaimableChunks._LOGGER.debug("Getting current claimable chunks: %d", num)
    return num
end

function Storage.ClaimableChunks.set(num)
    Storage.ClaimableChunks._LOGGER.debug("Setting current claimable chunks: %d", num)
    global.claimable_chunks = num
    return num
end

function Storage.ClaimableChunks.increase(num)
    if not num then num = 1 end
    local newNum = Storage.ClaimableChunks.get() + num

    Storage.ClaimableChunks._LOGGER.debug("Increasing current claimable chunks by %d to %d", num,  newNum)
    global.claimable_chunks = newNum
    return newNum
end

function Storage.ClaimableChunks.decrease(num)
    if not num then num = 1 end
    local newNum = Storage.ClaimableChunks.get() - num

    Storage.ClaimableChunks._LOGGER.debug("Decrementing current claimable chunks by %d to %d", num, newNum)
    global.claimable_chunks = newNum
    return newNum
end


-- Storage of all of the chunks that have already been claimed
Storage.Chunks = {}
Storage.Chunks._LOGGER = LoggerLib.create("Storage/Chunks")
function Storage.Chunks._position_to_string(position)
    return serpent.line(position) -- TODO - performance - jarg said to someone else that serpent is slower than doing this stuff yourself
end

function Storage.Chunks._string_to_position(positionString) -- TODO - fix - this should just be stored as [x][y] instead of as a string
    local position = loadstring(string.format("do local _ = %s; return _; end", positionString))()
    return position
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
    chunkPosition = Position.standardize(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    -- Make sure it's not currently owned
    local oldChunkData = Storage.Chunks.get_chunk(surface, chunkPosition)
    if oldChunkData then
        Storage.Chunks._LOGGER.warn("Chunk %s - %s is already added", surfaceName, chunkPositionString)
        return false
    end

    if not global.chunk_data[surfaceName] then
        Storage.Chunks._LOGGER.debug("Adding surface to global chunk table: %s", surfaceName)
        global.chunk_data[surfaceName] = {}
    end

    Storage.Chunks._LOGGER.debug("Adding claim of chunk %s - %s -- %d tiles - %d fill",
            surfaceName,
            chunkPositionString,
            tileCount,
            currentFill
    )
    global.chunk_data[surfaceName][chunkPositionString] = {fill = currentFill, max = tileCount}
    return true
end

function Storage.Chunks.claim_chunk_from_position(surface, position, tileCount, currentFill)
    Storage.Chunks._LOGGER.debug("Adding chunk by position")
    local chunkPosition = Area.get_chunk_position_from_position(position)
    return Storage.Chunks.claim_chunk(surface, chunkPosition, tileCount, currentFill), chunkPosition
end

-- chunkCountsToAdd is a table of {[x] = {[y] = count}}
function Storage.Chunks.add_to_chunks(surface, chunkCountsToAdd)
    Storage.Chunks._LOGGER.debug("Adding to chunks")
    Storage.Chunks._LOGGER.trace(chunkCountsToAdd)
    for x, yAndCounts in pairs(chunkCountsToAdd) do
        for y, count in pairs(yAndCounts) do
            Storage.Chunks._LOGGER.debug("Attempting to add %d to chunk {x = %d, y = %d}", count, x, y)
            local chunkData = Storage.Chunks.get_chunk(surface, {x = x, y = y})
            if chunkData then
                local newMax = chunkData["max"] + count
                chunkData["max"] = newMax
                Storage.Chunks._LOGGER.debug("New max for chunk: %d", newMax)
            end
        end
    end
end

function Storage.Chunks.get_chunk(surface, chunkPosition)
    Storage.Chunks._LOGGER.debug("Getting chunk")
    if not surface.valid then
        Storage.Chunks._LOGGER.error("Surface is invalid")
        return
    end

    local surfaceName = surface.name
    chunkPosition = Position.standardize(chunkPosition)
    local chunkPositionString = Storage.Chunks._position_to_string(chunkPosition)

    if global.chunk_data[surfaceName] then
        local oldChunkData = global.chunk_data[surfaceName][chunkPositionString]
        if oldChunkData then
            Storage.Chunks._LOGGER.debug("Chunk %s - %s has been claimed", surfaceName, chunkPositionString)
            return oldChunkData
        else
            Storage.Chunks._LOGGER.debug("Chunk %s - %s is not claimed", surfaceName, chunkPositionString)
            return nil
        end
    end
    Storage.Chunks._LOGGER.debug("No owner found for chunk %s - %s", surfaceName, chunkPositionString)
end

function Storage.Chunks.get_all_chunks()
    return global.chunk_data
end

function Storage.Chunks.get_chunk_from_position(surface, position) --TODO - performance(?) - cache lookups for just this tick?
    Storage.Chunks._LOGGER.debug("Getting chunk from position")
    local chunkPosition = Area.get_chunk_position_from_position(position)
    return Storage.Chunks.get_chunk(surface, chunkPosition), chunkPosition
end


function Storage.Chunks._crossed_fill_threshold(oldPercentage, newPercentage)
    local threshold = Config.Settings.CHUNK_PERCENTAGE_FULL_FOR_NEW_CHUNK
    if oldPercentage < threshold and threshold <= newPercentage then
        Storage.Chunks._LOGGER.debug("Crossed fill threshold upwards (old, new, threshold): (%d, %d, %d)",
                oldPercentage,
                newPercentage,
                threshold
        )
        return 1
    elseif oldPercentage >= threshold and threshold > newPercentage then
        Storage.Chunks._LOGGER.debug("Crossed fill threshold downwards (old, new, threshold): (%d, %d, %d)",
                oldPercentage,
                newPercentage,
                threshold
        )
        return -1
    else
        Storage.Chunks._LOGGER.debug("Did not cross fill threshold (old, new, threshold): (%d, %d, %d)",
                oldPercentage,
                newPercentage,
                threshold
        )
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
        local surface = entity.surface
        local thresholdsCrossed = 0

        Storage.Chunks._LOGGER.debug("Attempting to %s entity %s to chunk(s)", directionName, entityName)
        local areas_by_chunks = Entity.area_of_by_chunks(entity)
        for _, area_by_chunk in ipairs(areas_by_chunks) do
            local chunkPosition = area_by_chunk["chunk"]
            local chunkData = Storage.Chunks.get_chunk(surface, chunkPosition)
            if chunkData then
                Storage.Chunks._LOGGER.debug("Found chunk data for %s at %s", entityName, chunkPosition)
                local maxArea = chunkData["max"]
                local currentFill = chunkData["fill"]
                local oldPercentage = currentFill / maxArea

                local newFill = newFillFunc(currentFill, area_by_chunk["area"], maxArea) --math.min(currentFill + area, maxArea)
                chunkData["fill"] = newFill
                local percentage =  newFill / maxArea

                local crossedThreshold = Storage.Chunks._crossed_fill_threshold(oldPercentage, percentage)

                Storage.Chunks._LOGGER.info("Successfully modified %s to chunk %s. New percent filled: %.2f%%",
                        entityName,
                        chunkPosition,
                        percentage * 100
                )
                if crossedThreshold == thresholdDirection then
                    thresholdsCrossed = thresholdsCrossed + 1
                end
            else
                Storage.Chunks._LOGGER.error("Failed to %s %s to chunk %s, not claimed", directionName, entityName, chunkPosition)
            end
        end
        Storage.Chunks._LOGGER.info("Completed modifying %s to chunks, %d thresholds crossed", entityName, thresholdsCrossed)
        return thresholdsCrossed
    else
        Storage.Chunks._LOGGER.error("Cannot %s entity to chunks, it is nil or invalid", directionName)
        return 0
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
