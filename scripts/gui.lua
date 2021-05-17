local mod_gui = require("mod-gui")

local LoggerLib = require("__DedLib__/modules/logger")
local Storage = require("storage")
local Config = require("config")

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

-- TODO - feature - color number based on status (1 = yellow, 0 = red)
function Gui.ClaimableChunkCounter.draw(player) -- TODO - make sure this is good? Looks kinda smushed
    local playerName = player.name
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to draw chunk counter for " .. playerName)
    if not Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter does not exist for " .. playerName .. ", drawing now...")
        local buttonFrom = mod_gui.get_button_flow(player)
        buttonFrom.add{type="label", name=Gui.ClaimableChunkCounter._LABEL_NAME, caption={"MomsSpaghetti_gui_claimable_chunks_label", Storage.ClaimableChunks.get()}}
    else
        Gui.ClaimableChunkCounter._LOGGER.warn("Chunk counter already exists for " .. playerName .. " updating instead")
        Gui.ClaimableChunkCounter.update(player)
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done drawing chunk counter for " .. playerName)
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
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to update chunk counter for " .. player.name)
    if Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter exists for " .. playerName .. ", updating now...")
        mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME].caption = {"MomsSpaghetti_gui_claimable_chunks_label", Storage.ClaimableChunks.get()}
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done updating chunk counter for " .. playerName)
end

function Gui.ClaimableChunkCounter.destroy(player) -- TODO - Unused, but that's fine?
    local playerName = player.name
    Gui.ClaimableChunkCounter._LOGGER.debug("Attempting to destroy chunk counter for " .. playerName)
    if Gui.ClaimableChunkCounter.exists(player) then
        Gui.ClaimableChunkCounter._LOGGER.info("Chunk counter exists for " .. playerName .. ", destroying now...")
        mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME].destroy()
    else
        Gui.ClaimableChunkCounter._LOGGER.warn("Chunk counter does not exist for " .. playerName .. ", no-op")
    end
    Gui.ClaimableChunkCounter._LOGGER.debug("Done destroying chunk counter for " .. playerName)
end

function Gui.ClaimableChunkCounter.exists(player)
    local frame = mod_gui.get_button_flow(player)[Gui.ClaimableChunkCounter._LABEL_NAME]
    return frame and frame.valid
end


return Gui
