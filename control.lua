local Logger = require("__DedLib__/modules/logger").create("Control")

require("scripts/config") -- Config is a singleton, so it only needs called here

local Area_Management = require("scripts/area_management")
local Storage = require("scripts/storage")
local Gui = require("scripts/gui")

script.on_init(function()
    Storage.init()
    Gui.ClaimableTileCounter.drawAll()
    Config.Game.refresh()
end)

script.on_configuration_changed(function()
    Config.Game.refresh()
end)

script.on_load(function()
    Config.Game.refresh()
end)

-- Select the tiles (not water)
-- manually do a find for entities that are entities with health and collide with a normal collision mask
    -- then manually check for ignorable types
script.on_event(defines.events.on_player_selected_area, function(event)
    local item = event.item
    if item == Config.Prototypes.CHUNK_SELECTOR then
        Logger.info("Area selected using %s", item)
        Area_Management.add_selected_area(event.surface, event.area, event.tiles, game.get_player(event.player_index))
    end
end)

-- Ghosts are added in here, so we don't care when the ghost is constructed, since it was already counted
script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local entityName = entity.name

    Logger.debug("Player built event for entity: %s", entityName)
    Area_Management.add_entity(entity)
end)

function on_entity_removed(event)
    local entity = event.entity or event.ghost
    Area_Management.remove_entity(entity)
end

function on_entity_died(event)
    local entity = event.entity

    -- If the force isn't making a ghost then this entity can be removed from the count
    if entity.force.ghost_time_to_live == 0 then --TODO - performance -- this needs caching
        on_entity_removed(event)
    end
end

script.on_event(defines.events.on_player_mined_entity, on_entity_removed) -- TODO - performance(?) - this triggers on mining ore as well?
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_pre_ghost_deconstructed, on_entity_removed) -- TODO - performance - this can be heavy


function on_built_tile(event)
    local surface = game.get_surface(event.surface_index)
    local tiles = event.tiles
    local tile = event.tile
    local tileName = tile.name

    Logger.debug("Tile built event for %d tiles to %s", #tiles, tileName)
    Logger.trace(tiles)
    if tile.mineable_properties.minable and string.sub(tileName, 1, #Config.MOD_PREFIX) ~= Config.MOD_PREFIX then
        -- MomsSpaghetti mod tiles should not be buildable outright, but just in case...
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
    Logger.debug("Script raised set tiles event for %d tiles", #setTiles)
    Logger.trace(setTiles)

    local groupedTiles = {}
    for _, tile in ipairs(setTiles) do
        local name = tile.name
        if not groupedTiles[name] then
            groupedTiles[name] = {}
        end
        table.insert(groupedTiles[name], tile)
    end

    Logger.trace("Tiles have been grouped: %s", groupedTiles)

    for groupName, tiles in pairs(groupedTiles) do
        Logger.debug("Triggering normal built tiles event to tile %s", groupName)
        on_built_tile{surface_index = event.surface_index, tiles = tiles, tile = prototype}
    end
end
script.on_event(defines.events.script_raised_set_tiles, on_script_raised_set_tiles)


script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    Gui.ClaimableTileCounter.draw(player)
end)


script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local setting = event.setting

    if setting == Config.Settings.STARTING_ALLOWED_TILES_NAME or setting == Config.Settings.POPULATED_TILE_BONUS_NAME then
        Logger.info("%s setting changed, refreshing values and recalculating allowed tiles...", setting)
        Config.Settings.Refresh()
        Storage.AllowedTiles.recalculate()
        Gui.ClaimableTileCounter.updateAll()
    end
end)


--script.on_event(defines.events.on_gui_click, function(event) -- TODO - ignored for now
--    local element = event.element
--    local tags = element.tags
--
--    Logger.info("Clicked %s", element.name)
--    if tags["mod"] == Config.MOD_PREFIX then
--        local player = game.get_player(event.player_index)
--        local name = element.name
--        Logger.info("Mod interactive element %s clicked by %s", name, player.name)
--
--        if tags["action"] == "open_details" then
--            Gui.ClaimedAreaDetails.draw(player)
--        elseif tags["action"] == "close_details"  then
--            Gui.ClaimedAreaDetails.destroy(player)
--        end
--    end
--end)
