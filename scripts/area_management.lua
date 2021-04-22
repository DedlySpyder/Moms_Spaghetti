local Logger = require("__DedLib__/modules/logger").create("Area Management")
local Area = require("__DedLib__/modules/area")

local Storage = require("storage")
local Config = require("config")

local Area_Management = {}

function Area_Management.convert_chunk(position) -- TODO needs surface?
    local surface = game.surfaces["nauvis"]

    Logger.debug("Attempting to convert chunk")
    position = Area.standardize_position(position)
    local oldChunkData = Storage.Chunks.get_chunk_from_position(surface, position)
    if oldChunkData then
        Logger.warn("Chunk " .. surface.name .. " " .. serpent.line(position) .. " has already been claimed")
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

    local invalidTiles = surface.find_tiles_filtered{area = area, collision_mask = "water-tile"}
    Logger.debug("Found " .. #invalidTiles .. " invalid tiles for conversion")
    local tileFilter = {}
    for _, tile in ipairs(invalidTiles) do
        local pos = tile.position
        tileFilter[pos.x .. "-" .. pos.y] = true
    end

    local tiles = {}
    for x = area.left_top.x, area.right_bottom.x - 1, xDelta do
        for y = area.left_top.y, area.right_bottom.y - 1, yDelta do
            if not tileFilter[x .. "-" .. y] then
                table.insert(tiles, {name = Config.Prototypes.ALLOWED_TILE, position = {x, y}})
            end
        end
    end

    Logger.debug("Converting " .. #tiles .. " tiles to allowed placement tiles")
    --Logger.trace(tiles)

    surface.set_tiles(tiles)
    Storage.Chunks.add_chunk_from_position(surface, position)
    return true
end

return Area_Management