-- TODO - info description
local Logger = require("__DedLib__/modules/logger").create("Control")

local Area_Management = require("scripts/area_management")
local Config = require("scripts/config")

script.on_event(defines.events.on_built_entity, function(event)
    local entity = event.created_entity
    local entityName = entity.name

    Logger.debug("Player built event for entity: " .. entityName)
    if entityName == Config.Prototypes.CHUNK_SELECTOR then
        local player = game.get_player(event.player_index)
        if player and player.valid then
            Logger.info("Chunk chooser event for " .. player.name)
            Area_Management.convert_chunk(entity.position)
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
        -- TODO - other entity, do the math stuff
    end
end)

--[[
limit placement to allowed chunks
first entity in this list sets the force's area
--- can I use collision masks to handle allowed placement???
---- [SCRATCH THIS] duplicate all tiles, and the new ones DON'T have a new mask that all specific entities (since I need to swap to these new ones)
---- alien biomes says the game maxs at 255 tiles, so make 1 tile that only collides with my layer and place it everywhere on generation?
- https://wiki.factorio.com/Types/CollisionMask


every time something is placed/removed it adds/removes from the cost of the chunks/total area
-- unlocks more chunks unlocks (UI) when it is X% full
-- need to remove chunks if they are less than X% to avoid abuse (down to min?)
- this math need done by surface as well, each one starting at 1 chunk allowed


split train stations to a specific one that allows unloading only, only allowed to be placed in base
]]--


--[[
Needed features:
- chunk math of placement
- change out item for allowed tiles to a tool?
    -- artillery-targeting-remote
- support placeable tiles
    - Need to duplicate the tile and have 1 allowed and 1 not allowed, interrupt the placement to switch if in an allowed chunk
    - need to smarted up the convert chunks as well for it
- train station split

Future:
- support multiple forces?
]]--