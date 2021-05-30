local mod_gui = require("mod-gui")

local LoggerLib = require("__DedLib__/modules/logger")
local Area = require("__DedLib__/modules/area")
local Entity = require("__DedLib__/modules/entity")
local Storage = require("storage")


local Gui = {}

Gui.ClaimableChunkCounter = {}
Gui.ClaimableChunkCounter._LOGGER = LoggerLib.create("Gui/ClaimableChunkCounter")
Gui.ClaimableChunkCounter._LABEL_NAME = Config.MOD_PREFIX .. "_claimable_chunk_label"
function Gui.ClaimableChunkCounter.drawAll()
    Gui.ClaimableChunkCounter._LOGGER.debug("Drawing chunk counter for all players")
    for _, player in pairs(game.players) do
        Gui.ClaimableChunkCounter.draw(player)
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done drawing chunk counter for all players")
end

function Gui.ClaimableChunkCounter.draw(player)
    local playerName = player.name
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to draw chunk counter for %s", playerName)
    if not Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter does not exist for %s, drawing now...", playerName)
        local buttonFrom = mod_gui.get_button_flow(player)
        buttonFrom.add{
            type="label",
            name=Gui.ClaimableChunkCounter._LABEL_NAME,
            caption={"MomsSpaghetti_gui_claimable_chunks_label", Storage.ClaimableChunks.get()},
            tags = {mod = Config.MOD_PREFIX}
        }
    else
        Gui.ClaimableChunkCounter._LOGGER.warn("Chunk counter already exists for %s updating instead", playerName)
        Gui.ClaimableChunkCounter.update(player)
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done drawing chunk counter for %s", playerName)
end

function Gui.ClaimableChunkCounter.updateAll()
    Gui.ClaimableChunkCounter._LOGGER.debug("Updating chunk counter for all players")
    for _, player in pairs(game.players) do
        Gui.ClaimableChunkCounter.update(player)
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done updating chunk counter for all players")
end

function Gui.ClaimableChunkCounter.update(player)
    local playerName = player.name
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to update chunk counter for %s", playerName)
    if Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter exists for %s, updating now...", playerName)
        mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME].caption = {"MomsSpaghetti_gui_claimable_chunks_label", Storage.ClaimableChunks.get()}
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done updating chunk counter for %s", playerName)
end

function Gui.ClaimableChunkCounter.destroy(player) -- Unused
    local playerName = player.name
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to destroy chunk counter for %s", playerName)
    if Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter exists for %s, destroying now...", playerName)
        mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME].destroy()
    else
        Gui.ClaimableChunkCounter._LOGGER.warn("Chunk counter does not exist for %s, no-op", playerName)
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done destroying chunk counter for %s", playerName)
end

function Gui.ClaimableChunkCounter.exists(player)
    local frame = mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME]
    return frame and frame.valid
end


Gui.ClaimedChunkDetails = {}
Gui.ClaimedChunkDetails._PREFIX = Config.MOD_PREFIX .. "_claimed_chunk_details_"
Gui.ClaimedChunkDetails._FRAME_NAME = Gui.ClaimedChunkDetails._PREFIX .. "main_frame"
Gui.ClaimedChunkDetails._CLOSE_BUTTON_NAME = Gui.ClaimedChunkDetails._PREFIX .. "close"
function Gui.ClaimedChunkDetails.draw(player)
    if not Gui.ClaimedChunkDetails.exists(player) then
        local detailsFrame = player.gui.center.add{
            type = "frame",
            name = Gui.ClaimedChunkDetails._FRAME_NAME,
            caption = "Claimed Chunk Details",
            direction = "horizontal"
        }
        local listFlow = detailsFrame.add{type = "flow", direction = "vertical"}
        local table = listFlow.add{
            type = "table",
            name = Gui.ClaimedChunkDetails._PREFIX .. "table",
            column_count = 5,
            draw_vertical_lines = true,
            draw_horizontal_line_after_headers = true
        }

        -- Header
        table.add{type = "label", caption = "Chunk"}
        table.add{type = "label", caption = "Total"}
        table.add{type = "label", caption = "Fill"}
        table.add{type = "label", caption = "Percentage"}
        table.add{type = "label", caption = "Describe"}

        for surfaceName, chunks in pairs(Storage.Chunks.get_all_chunks()) do
            for chunkPositionString, chunkData in pairs(chunks) do
                table.add{type = "label", caption = chunkPositionString}
                table.add{type = "label", caption = chunkData["max"]}
                table.add{type = "label", caption = chunkData["fill"]}
                table.add{type = "label", caption = string.format("%.2f%%", (chunkData["fill"] / chunkData["max"]) * 100)}
                table.add{
                    type = "button",
                    name = Gui.ClaimedChunkDetails._PREFIX .. "describe_" .. chunkPositionString,
                    caption = "Describe",
                    tags = {
                        mod = Config.MOD_PREFIX,
                        action = "describe_chunk",
                        surfaceName = surfaceName,
                        chunkPositionString = chunkPositionString
                    }
                }
            end
        end

        listFlow.add{
            type = "button",
            name = Gui.ClaimedChunkDetails._CLOSE_BUTTON_NAME ,
            caption = "Close",
            tags = {mod = Config.MOD_PREFIX}
        }

        detailsFrame.add{
            type = "line",
            name = Gui.ClaimedChunkDetails._PREFIX .. "separator",
            direction = "vertical",
            visible = false
        }

        detailsFrame.add{
            type = "flow",
            name = Gui.ClaimedChunkDetails._PREFIX .. "describe_flow",
            direction = "vertical"
        }
    end
end

function Gui.ClaimedChunkDetails.update_describe_section(player, surface, chunkPositionString)
    if Gui.ClaimedChunkDetails.exists(player) then
        player.gui.center[Gui.ClaimedChunkDetails._FRAME_NAME][Gui.ClaimedChunkDetails._PREFIX .. "separator"].visible = true
        local describeFlow = player.gui.center[Gui.ClaimedChunkDetails._FRAME_NAME][Gui.ClaimedChunkDetails._PREFIX .. "describe_flow"]
        describeFlow.clear()
        local describeTable = describeFlow.add{
            type = "table",
            column_count = 4,
            draw_horizontal_line_after_headers = true
        }

        describeTable.add{type = "label", caption = "Name"}
        describeTable.add{type = "label", caption = "Area Each"}
        describeTable.add{type = "label", caption = "Count"}
        describeTable.add{type = "label", caption = "Total Area"}

        local chunkPosition = Storage.Chunks._string_to_position(chunkPositionString)
        local chunkArea = Area.get_chunk_area_from_chunk_position(chunkPosition)
        local entities = surface.find_entities_filtered{area = chunkArea, collision_mask = "object-layer"}
        local grouped = {}
        for _, entity in ipairs(entities) do
            local name = entity.name
            if not grouped[name] then
                local area = 0
                for _, area_by_chunk in ipairs(Entity.area_of_by_chunks(entity)) do
                    local chunk = area_by_chunk["chunk"]
                    if chunk.x == chunkPosition.x and chunk.y == chunkPosition.y then
                        area =  area_by_chunk["area"]
                        break
                    end
                end
                grouped[name] = {count = 0, area = area, positions = {}}
            end
            grouped[name].count = grouped[name].count + 1
            table.insert(grouped[name].positions, entity.position)
        end

        local totalCount = 0
        local totalSize = 0
        for name, group in pairs(grouped) do
            local size = group["area"] * group["count"]
            describeTable.add{type = "label", caption = name}
            describeTable.add{type = "label", caption = group["area"]}
            describeTable.add{type = "label", caption = group["count"]}
            describeTable.add{type = "label", caption = size}
            totalSize = totalSize + size
            totalCount = totalCount + group["count"]
        end
        describeTable.add{type = "label", caption = "Totals"}
        describeTable.add{type = "label", caption = ""}
        describeTable.add{type = "label", caption = totalCount}
        describeTable.add{type = "label", caption = totalSize}
    end
end

function Gui.ClaimedChunkDetails.destroy(player)
    if Gui.ClaimedChunkDetails.exists(player) then
        player.gui.center[Gui.ClaimedChunkDetails._FRAME_NAME].destroy()
    end
end

function Gui.ClaimedChunkDetails.exists(player)
    local frame = player.gui.center[Gui.ClaimedChunkDetails._FRAME_NAME]
    return frame and frame.valid
end


return Gui
