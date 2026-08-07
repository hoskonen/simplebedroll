-- Isolated prefab probes and development status commands.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll
local TEST_ANCHOR_CLASS = "SimpleBedRoll_VisualAnchor"

SBR.Test = SBR.Test or {
    anchor = nil,
    prefabGuid = nil,
    prefabSpawnRequested = false,
}

local function log(message)
    System.LogAlways("[SimpleBedRoll] " .. tostring(message))
end

local function helpLog(message)
    System.LogAlways(
        "[SimpleBedRoll/Help] " .. tostring(message)
    )
end

local function probeLog(message)
    System.LogAlways(
        "[SimpleBedRoll/EntityProbe] " .. tostring(message)
    )
end

local function safeCall(target, methodName, ...)
    if not target or not target[methodName] then
        return nil
    end

    local ok, first, second = pcall(
        target[methodName],
        target,
        ...
    )

    if not ok then
        return nil
    end

    return first, second
end

local function formatVector(vector)
    if not vector then
        return "nil"
    end

    return string.format(
        "%.2f, %.2f, %.2f",
        tonumber(vector.x) or 0,
        tonumber(vector.y) or 0,
        tonumber(vector.z) or 0
    )
end

local function getDistance(first, second)
    local x = (first.x or 0) - (second.x or 0)
    local y = (first.y or 0) - (second.y or 0)
    local z = (first.z or 0) - (second.z or 0)

    return math.sqrt(x * x + y * y + z * z)
end

local function getEntityModel(entity)
    local properties = entity and entity.Properties

    if not properties then
        return nil
    end

    local model = properties.object_Model
        or properties.objModel
        or properties.fileModel

    if model == "" then
        return nil
    end

    return model
end

local function getEntityLinks(entity)
    local count = tonumber(safeCall(entity, "CountLinks")) or 0

    if count <= 0 then
        return "none"
    end

    local links = {}
    local reportedCount = math.min(count, 8)

    for index = 0, reportedCount - 1 do
        local linkedEntity, linkName = safeCall(
            entity,
            "GetLink",
            index
        )

        if linkedEntity then
            local linkedName = safeCall(linkedEntity, "GetName")
                or linkedEntity.class
                or linkedEntity.id
                or "unknown"

            links[#links + 1] = string.format(
                "%s->%s",
                tostring(linkName or ""),
                tostring(linkedName)
            )
        end
    end

    if count > reportedCount then
        links[#links + 1] = string.format(
            "+%d more",
            count - reportedCount
        )
    end

    if #links == 0 then
        return "unreadable"
    end

    return table.concat(links, ", ")
end

local function getPlayer()
    if not System or not System.GetEntityByName then
        return nil
    end

    return System.GetEntityByName("Henry")
        or System.GetEntityByName("dude")
end

local function getSpawnPosition(playerEntity, distance)
    if not playerEntity
        or not playerEntity.GetWorldPos
        or not playerEntity.GetDirectionVector then

        return nil
    end

    local playerPosition = playerEntity:GetWorldPos()
    local playerDirection = playerEntity:GetDirectionVector()

    distance = tonumber(distance) or 2.0

    return {
        x = playerPosition.x + playerDirection.x * distance,
        y = playerPosition.y + playerDirection.y * distance,
        z = playerPosition.z,
    }
end

local function deleteAnchor()
    local anchor = SBR.Test.anchor

    if not anchor then
        return true
    end

    -- Delete prefab children attached to this anchor first.
    if Game and Game.DeletePrefab and anchor.id then
        local ok, result = pcall(Game.DeletePrefab, anchor.id)

        log(
            "DeletePrefab called: ok="
            .. tostring(ok)
            .. " result="
            .. tostring(result)
        )
    end

    if anchor.DeleteThis then
        local ok, err = pcall(anchor.DeleteThis, anchor)

        if not ok then
            log("anchor deletion failed: " .. tostring(err))
            return false
        end
    elseif System and System.RemoveEntity and anchor.id then
        local ok, err = pcall(System.RemoveEntity, anchor.id)

        if not ok then
            log("anchor removal failed: " .. tostring(err))
            return false
        end
    end

    SBR.Test.anchor = nil
    SBR.Test.prefabGuid = nil
    SBR.Test.prefabSpawnRequested = false

    return true
end


function SimpleBedRoll.SpawnTestPrefab(prefabGuid)
    prefabGuid = tostring(prefabGuid or "")

    if prefabGuid == "" then
        log("SpawnTestPrefab rejected: prefab GUID is required")
        return false
    end

    if not System or not System.SpawnEntity then
        log("SpawnTestPrefab failed: System.SpawnEntity unavailable")
        return false
    end

    if not Game or not Game.SpawnPrefab then
        log("SpawnTestPrefab failed: Game.SpawnPrefab unavailable")
        return false
    end

    local playerEntity = getPlayer()

    if not playerEntity then
        log("SpawnTestPrefab failed: player not found")
        return false
    end

    -- Keep only one research prefab active.
    if SBR.Test.anchor then
        log("removing previous test prefab")
        deleteAnchor()
    end

    local spawnPosition = getSpawnPosition(playerEntity, 2.0)

    if not spawnPosition then
        log("SpawnTestPrefab failed: could not calculate spawn position")
        return false
    end

    local spawnParams = {
        class = TEST_ANCHOR_CLASS,
        name = "SimpleBedRoll_TestAnchor",
        position = spawnPosition,
        properties = {
            object_Model = "",
        },
    }

    local ok, anchor = pcall(System.SpawnEntity, spawnParams)

    if not ok then
        log("SpawnTestPrefab failed while creating anchor: " .. tostring(anchor))
        return false
    end

    if not anchor or not anchor.id then
        log("SpawnTestPrefab failed: anchor was not created")
        return false
    end

    SBR.Test.anchor = anchor
    SBR.Test.prefabGuid = prefabGuid

    local playerAngles = nil

    if playerEntity.GetAngles then
        playerAngles = playerEntity:GetAngles()
    end

    if playerAngles and anchor.SetAngles then
        anchor:SetAngles({
            x = 0,
            y = 0,
            z = playerAngles.z,
        })
    end

    log(
        "anchor created: id="
        .. tostring(anchor.id)
        .. " pos="
        .. string.format(
            "%.2f, %.2f, %.2f",
            spawnPosition.x,
            spawnPosition.y,
            spawnPosition.z
        )
    )

    local spawnOk, spawnResult = pcall(
        Game.SpawnPrefab,
        anchor.id,
        prefabGuid,
        0
    )

    SBR.Test.prefabSpawnRequested = spawnOk

    if not spawnOk then
        log("Game.SpawnPrefab crashed: " .. tostring(spawnResult))
        deleteAnchor()
        return false
    end

    log(
        "prefab spawn requested: guid="
        .. prefabGuid
        .. " result="
        .. tostring(spawnResult)
    )

    return true
end

function SimpleBedRoll.RemoveTestPrefab()
    if not SBR.Test.anchor then
        log("RemoveTestPrefab: no active test prefab")
        return false
    end

    local removed = deleteAnchor()

    if removed then
        log("test prefab removed")
    end

    return removed
end

function SimpleBedRoll.TestStatus()
    local anchor = SBR.Test.anchor

    log(
        "test status: active="
        .. tostring(anchor ~= nil)
        .. " anchorId="
        .. tostring(anchor and anchor.id or nil)
        .. " prefabGuid="
        .. tostring(SBR.Test.prefabGuid)
        .. " spawnRequested="
        .. tostring(SBR.Test.prefabSpawnRequested)
    )

    return anchor ~= nil
end

function SimpleBedRoll.ProbeEntities(radius)
    if not System or not System.GetEntitiesInSphere then
        probeLog("failed: System.GetEntitiesInSphere unavailable")
        return 0
    end

    local playerEntity = getPlayer()

    if not playerEntity then
        probeLog("failed: player not found")
        return 0
    end

    local playerPosition = safeCall(
        playerEntity,
        "GetWorldPos"
    )

    if not playerPosition then
        probeLog("failed: player position unavailable")
        return 0
    end

    radius = tonumber(radius) or 2.0

    if radius <= 0 then
        probeLog("failed: radius must be greater than zero")
        return 0
    end

    if radius > 20.0 then
        probeLog("radius limited from " .. radius .. " to 20")
        radius = 20.0
    end

    local queryOk, entities = pcall(
        System.GetEntitiesInSphere,
        playerPosition,
        radius
    )

    if not queryOk or type(entities) ~= "table" then
        probeLog(
            "failed: entity query returned "
            .. tostring(entities)
        )

        return 0
    end

    local results = {}

    for _, entity in pairs(entities) do
        local position = safeCall(entity, "GetWorldPos")

        if position then
            results[#results + 1] = {
                entity = entity,
                position = position,
                distance = getDistance(
                    position,
                    playerPosition
                ),
            }
        end
    end

    table.sort(
        results,
        function(first, second)
            return first.distance < second.distance
        end
    )

    probeLog(
        string.format(
            "scan center=%.2f, %.2f, %.2f radius=%.2f count=%d",
            playerPosition.x,
            playerPosition.y,
            playerPosition.z,
            radius,
            #results
        )
    )

    for index, result in ipairs(results) do
        local entity = result.entity
        local name = safeCall(entity, "GetName") or ""
        local angles = safeCall(entity, "GetAngles")
        local model = getEntityModel(entity)

        probeLog(
            string.format(
                "[%d] distance=%.2f class=%s name=%s id=%s pos=%s angles=%s model=%s links=%s",
                index,
                result.distance,
                tostring(entity.class or "unknown"),
                tostring(name),
                tostring(entity.id),
                formatVector(result.position),
                formatVector(angles),
                tostring(model),
                getEntityLinks(entity)
            )
        )
    end

    return #results
end


function SimpleBedRoll.Help()
    helpLog("Simple Bedroll development commands:")
    helpLog("#sbr_help() - show this command list")
    helpLog("#sbr_spawn() - deploy the visible functional bedroll")
    helpLog("#sbr_remove() - remove the active bedroll")
    helpLog("#sbr_status() - report deployment entity state")
    helpLog(
        "#sbr_probe_entities(radius) - scan nearby entities; default 2, max 20 metres"
    )
    helpLog("Experimental prefab commands:")
    helpLog(
        "#SimpleBedRoll.SpawnTestPrefab(\"guid\")"
    )
    helpLog("#SimpleBedRoll.TestStatus()")
    helpLog("#SimpleBedRoll.RemoveTestPrefab()")

    return true
end


function sbr_help()
    return SimpleBedRoll.Help()
end

function sbr_spawn()
    return SimpleBedRoll.SpawnFunctionalTestBed()
end

function sbr_remove()
    return SimpleBedRoll.RemoveFunctionalTestBed()
end

function sbr_status()
    return SimpleBedRoll.FunctionalTestBedStatus()
end

function sbr_probe_entities(radius)
    return SimpleBedRoll.ProbeEntities(radius)
end
