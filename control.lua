local Logger = require("__DedLib__/modules/logger").create("Control")

require("scripts/config") -- Config is a singleton, so it only needs called here

local Area_Management = require("scripts/area_management")
local Storage = require("scripts/storage")
local Gui = require("scripts/gui")

script.on_init(function()
    Storage.init()
    Gui.ClaimableChunkCounter.drawAll()
end)

-- Ghosts are added in here, so we don't care when the ghost is constructed, since it was already counted
script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local entityName = entity.name

    Logger.debug("Player built event for entity: %s", entityName)
    if entityName == Config.Prototypes.CHUNK_SELECTOR then
        local player = game.get_player(event.player_index)
        if player and player.valid then
            Logger.info("Chunk chooser event for %s", player.name)
            Area_Management.convert_chunk(entity.surface, entity.position, player)
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
    elseif tileName == "landfill" then
        Logger.info("Landfill built, replacing and adding to total tile count...")
        Area_Management.replace_landfill_tile(surface, tiles, tileName)
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

    local validPrototypes = game.get_filtered_tile_prototypes({{filter = "minable"}})
    for groupName, tiles in pairs(groupedTiles) do
        local prototype = validPrototypes[groupName]
        if prototype then
            Logger.debug("Triggering normal built tiles event to tile %s", groupName)
            on_built_tile{surface_index = event.surface_index, tiles = tiles, tile = prototype}
        else
            Logger.debug("Skipping past non minable tile: %s", groupName)
        end
    end
end
script.on_event(defines.events.script_raised_set_tiles, on_script_raised_set_tiles)


script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    Gui.ClaimableChunkCounter.draw(player)
end)


script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    local setting = event.setting

    if setting == Config.Settings.CHUNK_PERCENTAGE_FULL_FOR_NEW_CHUNK_NAME or
            setting == Config.Settings.STARTING_ALLOWED_CHUNKS then
        Logger.info("%s setting changed, refreshing values and recalculating claimable chunks...", setting)
        Config.Settings.Refresh()
        Area_Management.recalculate_claimable_chunks()
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    local tags = element.tags

    Logger.info("Clicked %s", element.name)
    if tags["mod"] == Config.MOD_PREFIX then
        local player = game.get_player(event.player_index)
        local name = element.name
        Logger.info("Mod interactive element %s clicked by %s", name, player.name)

        if name == Gui.ClaimableChunkCounter._LABEL_NAME then
            Gui.ClaimedChunkDetails.draw(player)
        elseif name == Gui.ClaimedChunkDetails._CLOSE_BUTTON_NAME  then
            Gui.ClaimedChunkDetails.destroy(player)
        elseif tags["action"] == "describe_chunk" then
            local surface = game.get_surface(tags["surfaceName"])
            Gui.ClaimedChunkDetails.update_describe_section(player, surface, tags["chunkPositionString"])
        end
    end
end)
