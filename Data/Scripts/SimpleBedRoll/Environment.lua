-- Environment policy for where Simple Bedroll may be deployed.

SimpleBedRoll = SimpleBedRoll or {}
SimpleBedRoll.Environment = SimpleBedRoll.Environment or {}

local Environment = SimpleBedRoll.Environment
local Placement = SimpleBedRoll.Placement

Environment.AudioRadius = 5.0

local AUDIO_CLASSES = {
    AudioAreaAmbience = true,
    AudioAreaEntity = true,
}

local function log(message)
    System.LogAlways("[SimpleBedRoll/Environment] " .. tostring(message))
end

local function valueText(value)
    if value == nil then
        return "nil"
    end

    return tostring(value)
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function safeGet(object, key)
    if type(object) ~= "table" then
        return nil
    end

    local ok, value = pcall(function()
        return object[key]
    end)

    if ok then
        return value
    end

    return nil
end

local function safeCall(object, methodName)
    local method = safeGet(object, methodName)

    if type(method) ~= "function" then
        return nil
    end

    local ok, value = pcall(method, object)
    if ok then
        return value
    end

    return nil
end

local function readFromRoots(entity, names)
    local roots = {
        type(entity) == "table" and entity or nil,
        type(entity) == "table" and entity.Properties or nil,
        type(entity) == "table" and entity.PropertiesInstance or nil,
    }

    for _, root in ipairs(roots) do
        if type(root) == "table" then
            for _, name in ipairs(names) do
                local value = safeGet(root, name)
                if value ~= nil then
                    return value
                end
            end
        end
    end

    return nil
end

local function asNumber(value)
    if type(value) == "number" then
        return value
    end

    return tonumber(value)
end

local function audioActive(entity)
    local bIsPlaying = readFromRoots(
        entity,
        { "bIsPlaying", "isPlaying", "IsPlaying" }
    )
    local fFadeValue = readFromRoots(
        entity,
        { "fFadeValue", "fade", "Fade", "fadeValue" }
    )
    local nState = readFromRoots(
        entity,
        { "nState", "state", "State" }
    )

    if bIsPlaying == true then
        return true
    end

    local fade = asNumber(fFadeValue)
    if fade ~= nil and fade > 0 then
        return true
    end

    local state = asNumber(nState)
    if state ~= nil and state > 0 then
        return true
    end

    if bIsPlaying == false or fade == 0 or state == 0 then
        return false
    end

    return nil
end

local function entityClass(entity)
    if type(entity) ~= "table" then
        return nil
    end

    return entity.class
        or entity.Class
        or safeCall(entity, "GetClass")
end

local function entityName(entity)
    return safeCall(entity, "GetName")
        or safeGet(entity, "name")
        or safeGet(entity, "Name")
end

local function getPosition(entity)
    return safeCall(entity, "GetWorldPos")
        or safeCall(entity, "GetPos")
end

local function getPlayerPosition(actor)
    local position = getPosition(actor)
    if position then
        return position
    end

    if Placement and Placement.GetPlayer then
        return getPosition(Placement.GetPlayer())
    end

    return nil
end

function Environment.CanCampHere(actor)
    if not (System and System.GetEntitiesInSphere) then
        log("no allowed environment found result=DENY reason=GetEntitiesInSphere unavailable")
        return false, "entity query unavailable"
    end

    local center = getPlayerPosition(actor)
    if not center then
        log("no allowed environment found result=DENY reason=player position unavailable")
        return false, "player position unavailable"
    end

    local ok, entities = pcall(
        System.GetEntitiesInSphere,
        center,
        Environment.AudioRadius
    )

    if not ok or type(entities) ~= "table" then
        log(
            "no allowed environment found result=DENY reason=query failed result="
            .. tostring(entities)
        )
        return false, "entity query failed"
    end

    local seenCandidate = false

    for _, entity in pairs(entities) do
        local className = entityClass(entity)

        if AUDIO_CLASSES[tostring(className)] then
            local active = audioActive(entity)
            local name = entityName(entity)

            if active == true then
                seenCandidate = true
                log(
                    "candidate name="
                    .. valueText(name)
                    .. " class="
                    .. valueText(className)
                    .. " active="
                    .. valueText(active)
                )

                if string.find(lower(name), "forest", 1, true) then
                    log("matched token=forest result=ALLOW")
                    return true, "forest"
                end
            end
        end
    end

    if seenCandidate then
        log("no allowed environment found result=DENY")
    else
        log("no active audio area candidates found result=DENY")
    end

    return false, "no active forest audio area"
end
