local mod_gui = require("mod-gui")

local LoggerLib = require("__DedLib__/modules/logger")
local Area = require("__DedLib__/modules/area")
local Entity = require("__DedLib__/modules/entity")
local Storage = require("storage")


local Gui = {}


Gui.ClaimableTileCounter = {}
Gui.ClaimableTileCounter._LOGGER = LoggerLib.create("Gui/ClaimableTileCounter")
Gui.ClaimableTileCounter._LABEL_NAME = Config.MOD_PREFIX .. "_claimable_tile_label"
function Gui.ClaimableTileCounter.drawAll()
    Gui.ClaimableTileCounter._LOGGER:debug("Drawing tile counter for all players")
    for _, player in pairs(game.players) do
        Gui.ClaimableTileCounter.draw(player)
    end
    Gui.ClaimableTileCounter._LOGGER:debug("Done drawing tile counter for all players")
end

function Gui.ClaimableTileCounter.draw(player)
    local playerName = player.name
    Gui.ClaimableTileCounter._LOGGER:debug("Attempting to draw tile counter for %s", playerName)
    if not Gui.ClaimableTileCounter.exists(player) then
        Gui.ClaimableTileCounter._LOGGER:info("Tile counter does not exist for %s, drawing now...", playerName)
        local buttonFrom = mod_gui.get_button_flow(player)
        buttonFrom.add{
            type="label",
            name=Gui.ClaimableTileCounter._LABEL_NAME,
            caption="Claimable Tiles: " .. Storage.AllowedTiles.get_remainder(),
            tags = {
                mod = Config.MOD_PREFIX,
                action = "open_details"
            }
        }
    else
        Gui.ClaimableTileCounter._LOGGER:warn("Tile counter already exists for %s updating instead", playerName)
        Gui.ClaimableTileCounter.update(player)
    end
    Gui.ClaimableTileCounter._LOGGER:debug("Done drawing tile counter for %s", playerName)
end

function Gui.ClaimableTileCounter.updateAll()
    Gui.ClaimableTileCounter._LOGGER:debug("Updating tile counter for all players")
    for _, player in pairs(game.players) do
        Gui.ClaimableTileCounter.update(player)
    end
    Gui.ClaimableTileCounter._LOGGER:debug("Done updating tile counter for all players")
end

function Gui.ClaimableTileCounter.update(player)
    local playerName = player.name
    Gui.ClaimableTileCounter._LOGGER:debug("Attempting to update tile counter for %s", playerName)
    if Gui.ClaimableTileCounter.exists(player) then
        Gui.ClaimableTileCounter._LOGGER:info("Tile counter exists for %s, updating now...", playerName)
        mod_gui.get_button_flow(player)[Gui.ClaimableTileCounter._LABEL_NAME].caption = "Claimable Tiles: " .. Storage.AllowedTiles.get_remainder()
    end
    Gui.ClaimableTileCounter._LOGGER:debug("Done updating tile counter for %s", playerName)
end

function Gui.ClaimableTileCounter.destroy(player) -- Unused
    local playerName = player.name
    Gui.ClaimableTileCounter._LOGGER:debug("Attempting to destroy tile counter for %s", playerName)
    if Gui.ClaimableTileCounter.exists(player) then
        Gui.ClaimableTileCounter._LOGGER:info("Tile counter exists for %s, destroying now...", playerName)
        mod_gui.get_button_flow(player)[Gui.ClaimableTileCounter._LABEL_NAME].destroy()
    else
        Gui.ClaimableTileCounter._LOGGER:warn("Tile counter does not exist for %s, no-op", playerName)
    end
    Gui.ClaimableTileCounter._LOGGER:debug("Done destroying tile counter for %s", playerName)
end

function Gui.ClaimableTileCounter.exists(player)
    local frame = mod_gui.get_button_flow(player)[Gui.ClaimableTileCounter._LABEL_NAME]
    return frame and frame.valid
end


Gui.ClaimedAreaDetails = {}
Gui.ClaimedAreaDetails._PREFIX = Config.MOD_PREFIX .. "_claimed_area_details_"
Gui.ClaimedAreaDetails._FRAME_NAME = Gui.ClaimedAreaDetails._PREFIX .. "main_frame"
Gui.ClaimedAreaDetails._CLOSE_BUTTON_NAME = Gui.ClaimedAreaDetails._PREFIX .. "close"
function Gui.ClaimedAreaDetails.draw(player) --TODO - implement - need to search for the tiles then the stuff on top of it? Ooof
    -- On GUI click is commented out for this as well
    if not Gui.ClaimedAreaDetails.exists(player) then
        local detailsFrame = player.gui.center.add{
            type = "frame",
            name = Gui.ClaimedAreaDetails._FRAME_NAME,
            caption = "Claimed Area Details",
            direction = "horizontal"
        }
        local listFlow = detailsFrame.add{type = "flow", direction = "vertical"}
        local table = listFlow.add{
            type = "table",
            name = Gui.ClaimedAreaDetails._PREFIX .. "table",
            column_count = 5,
            draw_vertical_lines = true,
            draw_horizontal_line_after_headers = true
        }

        -- Header
        table.add{type = "label", caption = ""}

        local allowedTiles

        listFlow.add{
            type = "button",
            name = Gui.ClaimedAreaDetails._CLOSE_BUTTON_NAME ,
            caption = "Close",
            tags = {
                mod = Config.MOD_PREFIX,
                action = "close_details"
            }
        }
    end
end

function Gui.ClaimedAreaDetails.destroy(player)
    if Gui.ClaimedAreaDetails.exists(player) then
        player.gui.center[Gui.ClaimedAreaDetails._FRAME_NAME].destroy()
    end
end

function Gui.ClaimedAreaDetails.exists(player)
    local frame = player.gui.center[Gui.ClaimedAreaDetails._FRAME_NAME]
    return frame and frame.valid
end


return Gui
