-- TODO - info description
local Logger = require("__DedLib__/modules/logger").create("Control")

local Area_Management = require("scripts/area_management")
local Config = require("scripts/config")

-- Ghosts are added in here, so we don't care when the ghost is constructed, since it was already counted
script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local entityName = entity.name

    Logger.debug("Player built event for entity: " .. entityName)
    if entityName == Config.Prototypes.CHUNK_SELECTOR then
        local player = game.get_player(event.player_index)
        if player and player.valid then
            Logger.info("Chunk chooser event for " .. player.name)
            Area_Management.convert_chunk(entity.surface, entity.position)
            entity.destroy()

            -- Put the selector item back
            local cursorStack = player.cursor_stack
            if cursorStack and cursorStack.valid then
                if not cursorStack.valid_for_read or cursorStack.name == Config.Prototypes.CHUNK_SELECTOR then
                    player.cursor_stack.set_stack{name = Config.Prototypes.CHUNK_SELECTOR, count = 1}
                end
            end
        end
    else
        Area_Management.add_entity(entity)
    end
end)

function on_built_tile(event)
    local surface = game.get_surface(event.surface_index)
    local tiles = event.tiles
    local tile = event.tile
    local tileName = tile.name

    Logger.debug("Tile built event for " .. #tiles .. " tiles to " .. tileName)
    Logger.trace(tiles)
    if tile.mineable_properties.minable and string.sub(tileName, 1, #Config.MOD_PREFIX) ~= Config.MOD_PREFIX then
        -- Mod tiles should not be buildable outright, but just in case...
        Logger.info("Minable non-mod tiles built, replacing...")
        Area_Management.replace_tile(surface, tiles, tileName)
    else
        Logger.debug("Tile is either not minable or is a mod tile")
    end
end
script.on_event(defines.events.on_player_built_tile, on_built_tile)
script.on_event(defines.events.on_robot_built_tile, on_built_tile)

function on_script_raised_set_tiles(event)
    local setTiles = event.tiles
    Logger.debug("Script raised set tiles event for " .. #setTiles .. " tiles")
    Logger.trace(setTiles)

    local groupedTiles = {}
    for _, tile in ipairs(setTiles) do
        local name = tile.name
        if not groupedTiles[name] then
            groupedTiles[name] = {}
        end
        table.insert(groupedTiles[name], tile)
    end

    Logger.trace("Tiles have been grouped:")
    Logger.trace(groupedTiles)

    local validPrototypes = game.get_filtered_tile_prototypes({{filter = "minable"}})
    for groupName, tiles in pairs(groupedTiles) do
        local prototype = validPrototypes[groupName]
        if prototype then
            Logger.debug("Triggering normal built tiles event to tile " .. groupName)
            on_built_tile{surface_index = event.surface_index, tiles = tiles, tile = prototype}
        else
            Logger.debug("Skipping past non minable tile: " .. groupName)
        end
    end
end
script.on_event(defines.events.script_raised_set_tiles, on_script_raised_set_tiles)


--[[
every time something is placed/removed it adds/removes from the cost of the chunks/total area
-- unlocks more chunks unlocks (UI) when it is X% full
-- need to remove chunks if they are less than X% to avoid abuse (down to min?)
- this math need done by surface as well, each one starting at 1 chunk allowed


split train stations to a specific one that allows unloading only, only allowed to be placed in base
]]--


--[[
Needed features:
- chunk math of placement
- support placeable tiles
    - DONE - Need to duplicate the tile and have 1 allowed and 1 not allowed, interrupt the placement to switch if in an allowed chunk
    - DONE - need to smarted up the convert chunks as well for it
    - TODO - need to test the dynamic selection of layers with a dummy mod
- train station split

Future:
- make tile look less shit
    - same for icons for plates
- add border to mineable tiles? (can I layer something on the border?)
- support multiple forces?
]]--