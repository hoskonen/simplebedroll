-- Isolated prefab probes and development status commands.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll
local TEST_ANCHOR_CLASS = "SimpleBedRoll_VisualAnchor"
local BEDROLL_ITEM_CLASS_ID = "7f3f6a24-3b4d-4ec7-9a91-6d8e9f5a2c11"

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

local function getPlayerInventory()
    local playerEntity = getPlayer()

    if not playerEntity and System and System.GetEntity and g_localActorId then
        local ok, entity = pcall(System.GetEntity, g_localActorId)
        if ok then
            playerEntity = entity
        end
    end

    if not playerEntity and player then
        playerEntity = player
    end

    if not playerEntity then
        return nil
    end

    if playerEntity.inventory then
        return playerEntity.inventory
    end

    if playerEntity.GetInventory then
        local ok, inventory = pcall(
            playerEntity.GetInventory,
            playerEntity
        )

        if ok then
            return inventory
        end
    end

    return nil
end

local function getInventoryCount(inventory, classId)
    if not inventory or not inventory.GetCountOfClass then
        return nil
    end

    local ok, count = pcall(
        inventory.GetCountOfClass,
        inventory,
        classId
    )

    if not ok or type(count) ~= "number" then
        return nil
    end

    return math.floor(count + 0.00001)
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


function SimpleBedRoll.GiveBedrollItem(quantity, health)
    quantity = math.floor(tonumber(quantity) or 1)
    health = tonumber(health) or 1.0

    if quantity < 1 then
        quantity = 1
    end

    if quantity > 20 then
        log("GiveBedrollItem quantity limited from " .. quantity .. " to 20")
        quantity = 20
    end

    if health > 1 then
        health = health / 100.0
    end

    if health < 0 then
        health = 0
    elseif health > 1 then
        health = 1
    end

    local inventory = getPlayerInventory()

    if not inventory then
        log("GiveBedrollItem failed: player inventory unavailable")
        return false
    end

    if not inventory.CreateItem then
        log("GiveBedrollItem failed: inventory.CreateItem unavailable")
        return false
    end

    local before = getInventoryCount(inventory, BEDROLL_ITEM_CLASS_ID)
    local ok, result = pcall(
        inventory.CreateItem,
        inventory,
        BEDROLL_ITEM_CLASS_ID,
        health,
        quantity
    )

    if not ok then
        log("GiveBedrollItem failed: CreateItem raised " .. tostring(result))
        return false
    end

    local after = getInventoryCount(inventory, BEDROLL_ITEM_CLASS_ID)
    local verified = before ~= nil and after ~= nil and after >= before + quantity

    if Game and Game.ShowItemsTransfer then
        pcall(Game.ShowItemsTransfer, BEDROLL_ITEM_CLASS_ID, quantity)
    end

    log(
        "GiveBedrollItem classId="
        .. BEDROLL_ITEM_CLASS_ID
        .. " quantity="
        .. tostring(quantity)
        .. " health="
        .. tostring(health)
        .. " result="
        .. tostring(result)
        .. " before="
        .. tostring(before)
        .. " after="
        .. tostring(after)
        .. " verified="
        .. tostring(verified)
    )

    return verified or (before == nil and after == nil and result ~= false)
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
    helpLog("help or sbr_help - show this command list")
    helpLog("sbr_spawn - deploy the visible functional bedroll")
    helpLog("sbr_give_bedroll [quantity] [health] - add the bedroll item to Henry")
    helpLog("sbr_remove - remove the active bedroll")
    helpLog("sbr_status - report deployment entity state")
    helpLog(
        "sbr_probe_entities [radius] - scan nearby entities; default 2, max 20 metres"
    )
    helpLog("Lua hash forms also work: #sbr_help(), #sbr_spawn(), #sbr_remove()")
    helpLog(
        "#sbr_give_bedroll(quantity, health), #sbr_status(), #sbr_probe_entities(radius)"
    )
    helpLog("Experimental prefab commands:")
    helpLog("sbr_test_prefab <guid>")
    helpLog("sbr_test_status")
    helpLog("sbr_test_remove")
    helpLog(
        "#SimpleBedRoll.SpawnTestPrefab(\"guid\")"
    )
    helpLog("#SimpleBedRoll.TestStatus()")
    helpLog("#SimpleBedRoll.RemoveTestPrefab()")

    return true
end

local function registerDevCommand(name, callback, description)
    if not System or not System.AddCCommand then
        return false
    end

    local ok, err = pcall(
        System.AddCCommand,
        name,
        callback,
        description
    )

    if not ok then
        log(
            "failed to register command "
            .. tostring(name)
            .. ": "
            .. tostring(err)
        )

        return false
    end

    return true
end

function SimpleBedRoll.RegisterDevCommands()
    if SBR._devCommandsRegistered then
        return true
    end

    if not System or not System.AddCCommand then
        log("dev command registration skipped: System.AddCCommand unavailable")
        return false
    end

    registerDevCommand("help", "sbr_help()", "Simple Bedroll: list development commands")
    registerDevCommand("sbr_help", "sbr_help()", "Simple Bedroll: list development commands")
    registerDevCommand("sbr_spawn", "sbr_spawn()", "Simple Bedroll: deploy functional bedroll")
    registerDevCommand("sbr_remove", "sbr_remove()", "Simple Bedroll: remove active bedroll")
    registerDevCommand("sbr_status", "sbr_status()", "Simple Bedroll: deployment status")
    registerDevCommand("sbr_give_bedroll", "sbr_give_bedroll(%%)", "Simple Bedroll: give bedroll item")
    registerDevCommand("sbr_probe_entities", "sbr_probe_entities(%1)", "Simple Bedroll: scan nearby entities")
    registerDevCommand("sbr_test_prefab", "SimpleBedRoll.SpawnTestPrefab([[%1]])", "Simple Bedroll: spawn test prefab")
    registerDevCommand("sbr_test_status", "SimpleBedRoll.TestStatus()", "Simple Bedroll: test prefab status")
    registerDevCommand("sbr_test_remove", "SimpleBedRoll.RemoveTestPrefab()", "Simple Bedroll: remove test prefab")

    SBR._devCommandsRegistered = true
    log("registered development console commands")

    return true
end


function sbr_help()
    return SimpleBedRoll.Help()
end

function help()
    return SimpleBedRoll.Help()
end

function sbr_spawn()
    return SimpleBedRoll.SpawnFunctionalTestBed()
end

function sbr_give_bedroll(quantity, health)
    return SimpleBedRoll.GiveBedrollItem(quantity, health)
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
