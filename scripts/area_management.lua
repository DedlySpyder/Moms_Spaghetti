local Logger = require("__DedLib__/modules/logger").create("Area Management")
local Area = require("__DedLib__/modules/area")

local Storage = require("storage")
local Config = require("config")
local Util = require("util")

local Area_Management = {}

function Area_Management.convert_chunk(surface, position)
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
    Storage.Chunks.claim_chunk_from_position(surface, position, tileCount)
    return true
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


function Area_Management.add_entity(entity) -- TODO add in storage then refresh UI? (it will take from storage for the number available)
    Logger.debug("Adding entity " .. entity.name)
    local percentFull, added = Storage.Chunks.add_entity(entity)
    if added then
        Logger.debug("Entity was successfully added") -- TODO - see if player/force should get more chunks
    end
end

function Area_Management.remove_entity(entity) --TODO - implement

end

return Area_Management