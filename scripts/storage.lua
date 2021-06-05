local LoggerLib = require("__DedLib__/modules/logger")

local Storage = {}


-- NOTE - global.layer is used by config
function Storage.init()
    global.allowed_tiles = global.allowed_tiles or {used = 0, total = 0, remainder = Config.Settings.STARTING_ALLOWED_TILES}
end

Storage.AllowedTiles = {}
Storage.AllowedTiles._LOGGER =  LoggerLib.create("Storage/AllowedTiles")
function Storage.AllowedTiles.get()
    local data = global.allowed_tiles
    Storage.AllowedTiles._LOGGER.debug("Getting allowed tiles data: %s", data)
    return data
end

function Storage.AllowedTiles.get_remainder()
    return Storage.AllowedTiles.get()["remainder"]
end

function Storage.AllowedTiles._calculate_remainder(used, total)
    return math.floor(Config.Settings.STARTING_ALLOWED_TILES - total + (used * (1 + Config.Settings.POPULATED_TILE_BONUS)))
end

function Storage.AllowedTiles.increase(args)
    local used = args["used"] or 0
    local total = args["total"] or 0
    if used == 0 and total == 0 then
        Storage.AllowedTiles._LOGGER.error("Attempting to increase allowed tiles data, but no value args: %s", args) -- TODO - testing - fatal & error after tests
        return
    end
    Storage.AllowedTiles._LOGGER.debug("Adding values to allowed tiles data: %s", args)

    local data = Storage.AllowedTiles.get()
    local newUsed = data["used"] + used
    local newTotal = data["total"] + total
    data["used"] = newUsed
    data["total"] = newTotal
    data["remainder"] = Storage.AllowedTiles._calculate_remainder(newUsed, newTotal)
    Storage.AllowedTiles._LOGGER.debug("New allowed tiles data: %s", data)
    return data
end

function Storage.AllowedTiles.decrease(args)
    local used = args["used"] or 0
    local total = args["total"] or 0
    if used == 0 and total == 0 then
        Storage.AllowedTiles._LOGGER.error("Attempting to decrease allowed tiles data, but no value args: %s", args) -- TODO - testing - fatal & error after tests
        return
    end
    Storage.AllowedTiles._LOGGER.debug("Subtracting values from allowed tiles data: %s", args)

    local data = Storage.AllowedTiles.get()
    local newUsed = data["used"] - used
    local newTotal = data["total"] - total
    data["used"] = newUsed
    data["total"] = newTotal
    data["remainder"] = Storage.AllowedTiles._calculate_remainder(newUsed, newTotal)
    Storage.AllowedTiles._LOGGER.debug("New allowed tiles data: %s", data)
    return data
end

function Storage.AllowedTiles.recalculate()
    local data = Storage.AllowedTiles.get()
    local newRemainder = Storage.AllowedTiles._calculate_remainder(data["used"], data["total"])
    data["remainder"] = newRemainder
    Storage.AllowedTiles._LOGGER.debug("Recalculated remainder to: %s", newRemainder)
    return data
end

return Storage
