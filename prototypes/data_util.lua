local Logger = require("__DedLib__/modules/logger").create{modName = "Moms_Spaghetti", prefix = "Data Util"}

local Data_Util = {}

Data_Util.REQUIRED_COLLISION_MASKS = 1

-- Calculate mod collision mask(s) by finding empty collision masks
local masks = {}
for category, prototypes in pairs(data.raw) do
    for name, prototype in pairs(prototypes) do
        local mask = prototype.collision_mask
        if mask and #mask > 0 then
            for _, m in ipairs(mask) do
                masks[m] = (masks[m] or 0) + 1
            end
        end
    end
end

Logger.trace("All masks:")
Logger.trace(masks, true)
local chosenMasks = {}
local numberMasks = {}
for i=55,13,-1 do
    local layer = "layer-" .. i
    if masks[layer] then
        numberMasks[layer] = masks[layer]
    elseif #chosenMasks < Data_Util.REQUIRED_COLLISION_MASKS then
        table.insert(chosenMasks, layer)
    end
end
Logger.trace("All numbered masks:")
Logger.trace(numberMasks, true)

-- Make sure we have enough masks
if #chosenMasks < Data_Util.REQUIRED_COLLISION_MASKS then
    Logger.error("ALl layered masks are in use, finding the least populated masks")
    for mask, count in pairs(numberMasks) do
        if #chosenMasks < Data_Util.REQUIRED_COLLISION_MASKS and count < 5 then
            table.insert(chosenMasks, mask)
        end
    end

    -- Last ditch effort, get something at least
    -- TODO - FUTURE - choosing busy masks - this is good for at least a while
    if #chosenMasks < Data_Util.REQUIRED_COLLISION_MASKS then
        Logger.fatal("Failed to find free layers for Mom'S Spaghetti mod. Picking hardcoded layer instead")
        table.insert(chosenMasks, "layer-49")
    end
end

Logger.debug("Chosen mask(s):")
Logger.debug(chosenMasks, true)
Data_Util.CHOSEN_MASKS = chosenMasks

return Data_Util