-- Thin wrappers around KCD2's current game-world time APIs.

SimpleBedRoll = SimpleBedRoll or {}
SimpleBedRoll.Time = SimpleBedRoll.Time or {}

local Time = SimpleBedRoll.Time

local function log(message)
    if System and System.LogAlways then
        System.LogAlways("[SimpleBedRoll] " .. tostring(message))
    end
end

local function callFunction(fn)
    if type(fn) ~= "function" then
        return nil
    end

    local ok, value = pcall(fn)
    if ok and type(value) == "number" then
        return value
    end

    return nil
end

local function callMethod(target, methodName)
    if not target or type(target[methodName]) ~= "function" then
        return nil
    end

    local ok, value = pcall(target[methodName], target)
    if ok and type(value) == "number" then
        return value
    end

    return nil
end

local function getPlayer()
    if System and System.GetEntityByName then
        local playerEntity = System.GetEntityByName("Henry")
            or System.GetEntityByName("dude")
            or System.GetEntityByName("Player")

        if playerEntity then
            return playerEntity
        end
    end

    if System and System.GetLocalPlayer then
        local ok, playerEntity = pcall(System.GetLocalPlayer)
        if ok and playerEntity then
            return playerEntity
        end
    end

    if Game and Game.GetPlayer then
        local ok, playerEntity = pcall(Game.GetPlayer)
        if ok and playerEntity then
            return playerEntity
        end
    end

    if player then
        return player
    end

    return nil
end

local function normalizeHour(hour)
    hour = tonumber(hour)
    if not hour then
        return nil
    end

    hour = hour % 24
    if hour < 0 then
        hour = hour + 24
    end

    return hour
end

function Time.GetWorldTime()
    local value = nil

    if KCDUtils
        and KCDUtils.Calendar
        and type(KCDUtils.Calendar.GetWorldTime) == "function" then

        value = callFunction(KCDUtils.Calendar.GetWorldTime)
        if value then
            return value, "KCDUtils.Calendar.GetWorldTime"
        end
    end

    if Calendar and type(Calendar.GetWorldTime) == "function" then
        value = callFunction(Calendar.GetWorldTime)
        if value then
            return value, "Calendar.GetWorldTime"
        end
    end

    return nil, "unavailable"
end

function Time.GetHour()
    local hour = nil

    if KCDUtils
        and KCDUtils.Calendar
        and type(KCDUtils.Calendar.GetWorldHourOfDay) == "function" then

        hour = normalizeHour(callFunction(KCDUtils.Calendar.GetWorldHourOfDay))
        if hour then
            return hour, "KCDUtils.Calendar.GetWorldHourOfDay"
        end
    end

    if Calendar and type(Calendar.GetWorldHourOfDay) == "function" then
        hour = normalizeHour(callFunction(Calendar.GetWorldHourOfDay))
        if hour then
            return hour, "Calendar.GetWorldHourOfDay"
        end
    end

    if KCDUtils
        and KCDUtils.System
        and type(KCDUtils.System.GetTimeOfDayHour) == "function" then

        hour = normalizeHour(callFunction(KCDUtils.System.GetTimeOfDayHour))
        if hour then
            return hour, "KCDUtils.System.GetTimeOfDayHour"
        end
    end

    if Entity and type(Entity.GetTimeOfDayHour) == "function" then
        hour = normalizeHour(callFunction(Entity.GetTimeOfDayHour))
        if hour then
            return hour, "Entity.GetTimeOfDayHour"
        end
    end

    local playerEntity = getPlayer()
    hour = normalizeHour(callMethod(playerEntity, "GetTimeOfDayHour"))
    if hour then
        return hour, "player:GetTimeOfDayHour"
    end

    local worldTime, source = Time.GetWorldTime()
    if worldTime then
        return normalizeHour(worldTime / 3600), source .. " / 3600 % 24"
    end

    return nil, "unavailable"
end

function Time.FormatHour(hour)
    hour = normalizeHour(hour)
    if not hour then
        return "unavailable"
    end

    return string.format("%.2f", hour)
end

function Time.DebugLog()
    local hour, hourSource = Time.GetHour()
    local worldTime, worldTimeSource = Time.GetWorldTime()

    if not hour then
        log("Game time unavailable: source=" .. tostring(hourSource))
        return false
    end

    log(
        "Game time: "
            .. Time.FormatHour(hour)
            .. " source="
            .. tostring(hourSource)
            .. " worldTime="
            .. tostring(worldTime)
            .. " worldTimeSource="
            .. tostring(worldTimeSource)
    )

    return true
end
