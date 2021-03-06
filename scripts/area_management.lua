local Logger = require("__DedLib__/modules/logger").create("Area_Management")
local Area = require("__DedLib__/modules/area")
local Entity = require("__DedLib__/modules/entity")
local Position = require("__DedLib__/modules/position")
local Table = require("__DedLib__/modules/table")

local Storage = require("storage")
local Util = require("util")
local Gui = require("gui")

--[[
Handle all the management of the claimed chunks

These chunks are the only spot where normal base entities (furnaces/assembling machines, etc) can be placed. When each
chunk is  above a certain percentage full, then a new chunk can be claimed.
]]--
local Area_Management = {}

Area_Management.IGNORED_ENTITY_TYPES_RAW = {"tree"}
Area_Management.IGNORED_ENTITY_TYPES = Table.indexify(Area_Management.IGNORED_ENTITY_TYPES_RAW)

function Area_Management._index_tiles(tiles)
    local t = {}
    for _, tile in ipairs(tiles) do
        local pos = tile.position
        t[pos.x .. "," .. pos.y] = true
    end
    return t
end

function Area_Management._is_ignored_entity_type(ttype)
    return Area_Management.IGNORED_ENTITY_TYPES[ttype]
end

function Area_Management.add_selected_area(surface, area, tiles, player)
    Logger:debug("add_selected_area original area: %s", area)
    area = Area.round_bounding_box_up(area)

    local allowed = Area_Management.is_adjacent_or_first_selection(surface, area)
    if not allowed then
        Logger:warn("Player %s attempting to add invalid selection on %s at %s", player.name, surface.name, area)
        player.print("New allowed area must be adjacent to current allowed area") -- TODO localize
        return
    end

    Logger:info("Adding area %s on surface %s, selected by %s, containing %d tile(s)", area, surface.name, player.name, #tiles)

    local leftTop = area.left_top
    local rightBottom = area.right_bottom

    Logger:debug("Checking entities in the area for border infringement")
    local tilesIndex -- Lazily evaluate
    local entities = surface.find_entities_filtered{area = area, collision_mask = "object-layer"}
    local usedSize = 0
    for _, e in ipairs(entities) do
        if not Area_Management._is_ignored_entity_type(e.type) then
            local bb = Area.round_bounding_box_up(e.bounding_box)
            local eName = e.name
            Logger:trace("Found entity %s with area: %s", eName, bb)
            local eLt = bb.left_top
            local eRb = bb.right_bottom
            if not (Position.is_greater_than_or_equal(eLt, leftTop) and Position.is_less_than_or_equal(eRb, rightBottom)) then
                if not tilesIndex then tilesIndex = Area_Management._index_tiles(tiles) end
                for x = eLt.x, eRb.x do
                    for y = eLt.y, eRb.y do
                        local newTileIndex = x .. "," .. y
                        if not tilesIndex[newTileIndex] then
                            Logger:trace("Adding new tile for %s at (%s,%s)", eName, x, y)
                            tilesIndex[newTileIndex] = true
                            table.insert(tiles, surface.get_tile(x, y))
                        end
                    end
                end
            end
            usedSize = usedSize + Entity.area_of(e)
            -- TODO - future - this is still wonky for some entities (mainly the crash ship, but could be for modded entities)
        end
    end
    Logger:debug("Finished adjusting for entities, tile count is now %d, total size of entities is %d", #tiles, usedSize)

    local newTiles = Area_Management.build_allowed_tiles(tiles)

    local tileCount = #newTiles
    if tileCount <= 0 then
        Logger:warn("No valid tiles selected by player, exiting add_selected_area...")
        return
    end

    local cost = tileCount - usedSize
    local currentAllowed = Storage.AllowedTiles.get()["remainder"]
    if cost > currentAllowed then
        Logger:error("Too much area requested by player, %d requsted, %d allowed", cost, currentAllowed)
        player.print("Too large of an area requested, you only have " .. currentAllowed .. " tiles available at the moment") -- TODO localize?
        return
    end

    Logger:debug("Converting %d tiles to allowed placement tiles", tileCount)
    Logger:trace(newTiles)

    surface.set_tiles(newTiles)
    Storage.AllowedTiles.increase{used = usedSize, total = tileCount}
    Gui.ClaimableTileCounter.updateAll()
end

-- TODO - abuse possibility - can select length across water and it would be allowed - I don't think I care enough for now
function Area_Management._area_contains_allowed_tiles(surface, area)
    Logger:debug("Checking if area %s on surface %s contains allowed tiles", area, surface.name)
    local tiles = surface.find_tiles_filtered{area = area}
    if tiles and #tiles > 0 then
        for _, tile in ipairs(tiles) do
            if not tile.collides_with(Config.Game.ModLayer) then
                Logger:debug("Found allowed tile %s in area at %s", tile.name, tile.position)
                return true
            end
        end
    end
    Logger:debug("Failed to find allowed tile")
    return false
    -- TODO - interface request - https://forums.factorio.com/viewtopic.php?f=28&t=98621
    --return entity.surface.count_tiles_filtered{
    --            area = area,
    --            collision_mask = Config.Game.ModLayer,
    --            invert = true
    --        } > 0
end

function Area_Management.is_adjacent_or_first_selection(surface, area)
    local data = Storage.AllowedTiles.get()
    if data["total"] == 0 then
        return true
    end

    local searchArea = Area.grow_bounding_box_by_n(area, 1)
    return Area_Management._area_contains_allowed_tiles(surface, searchArea)
end

function Area_Management.build_allowed_tiles(currentTiles)
    local tiles = {}
    for _, tile in ipairs(currentTiles) do
        if tile.collides_with(Config.Game.ModLayer) then
            if string.sub(tile.name, 1, #Config.Prototypes.DENIED_TILE_PREFIX) == Config.Prototypes.DENIED_TILE_PREFIX then
                table.insert(tiles, {name = Util.invert_name_prefix(tile.name), position = tile.position})
            elseif not tile.collides_with("water-tile") then
                table.insert(tiles, {name = Config.Prototypes.ALLOWED_TILE, position = tile.position})
            end
        end
    end
    return tiles
end

-- Replace tiles that are placeable by players
-- There are either allowed or denied versions of all of these, and each one is checked to see which version is needed
function Area_Management.replace_tile(surface, tiles, tileName)
    Logger:info("Replacing %d tiles", #tiles)
    local allowedTileName = Config.Prototypes.ALLOWED_TILE_PREFIX .. tileName
    local deniedTileName = Config.Prototypes.DENIED_TILE_PREFIX .. tileName

    local collisionCache = {}
    for _, tile in ipairs(tiles) do
        local hiddenTileName = surface.get_tile(tile.position).hidden_tile
        local collides
        if collisionCache[hiddenTileName] then
            collides = collisionCache[hiddenTileName]["value"]
        else
            collides = game.tile_prototypes[hiddenTileName].collision_mask[Config.Game.ModLayer]
            collisionCache[hiddenTileName] = {value = collides}
        end

        if collides then
            tile["name"] = deniedTileName
        else
            tile["name"] = allowedTileName
        end
    end

    Logger:trace(tiles)
    surface.set_tiles(tiles)
end


-- Add/remove an entity from allowed area. Storage will handle the remainder math, this just needs to kick it off and
-- Update the GUI
function Area_Management._count_entity(entity)
    -- This needs rounded up because a 1x1 entity is normally smaller than 1 tile, so will not find anything
    local area = Area.round_bounding_box_up(entity.bounding_box)
    return Area_Management._area_contains_allowed_tiles(entity.surface, area)
end

function Area_Management.add_entity(entity)
    if not Area_Management._is_ignored_entity_type(entity.type) and Area_Management._count_entity(entity) then
        Logger:info("Adding entity %s", entity.name)
        local size = Entity.area_of(entity)
        Storage.AllowedTiles.increase{used = size}
        Gui.ClaimableTileCounter.updateAll()
    end
end

function Area_Management.remove_entity(entity)
    if not Area_Management._is_ignored_entity_type(entity.type) and Area_Management._count_entity(entity) then
        Logger:info("Removing entity %s", entity.name)
        local size = Entity.area_of(entity)
        Storage.AllowedTiles.decrease{used = size}
        Gui.ClaimableTileCounter.updateAll()
    end
end


return Area_Management