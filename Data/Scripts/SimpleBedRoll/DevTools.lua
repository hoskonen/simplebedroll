-- Isolated prefab probes and development status commands.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll
local TEST_ANCHOR_CLASS = "SimpleBedRoll_VisualAnchor"
local TEST_PREFAB_ANCHOR_MODEL = ""
local prefabConfig = SimpleBedRoll_Config.Prefabs or {}
local litCandlePrefabConfig = prefabConfig.CandleLit or {}
local LIT_CANDLE_PREFAB_ID = tostring(
    litCandlePrefabConfig.Guid or "da23c351-21cd-4430-8dc9-fc8c459086b7"
)
local LIT_CANDLE_PREFAB_PATH = tostring(
    litCandlePrefabConfig.Path
    or "Data/Prefabs/simplebedroll/SBRCandleFullLitv1.xml"
)
local BEDROLL_ITEM_CLASS_ID = "7f3f6a24-3b4d-4ec7-9a91-6d8e9f5a2c11"
local TEST_LIGHT_ITEM_CLASSES = {
    { id = "643000ee-d9ad-4501-8e07-b8fb2dd9aaed", name = "loot_candle" },
    { id = "34380658-48a8-4726-94f6-51ad4d69cce8", name = "loot_lamp" },
    { id = "6c2769a6-de64-42c0-aa25-323b49f7f3bd", name = "lantern_old" },
    { id = "f1962b90-4704-4d4e-a1f2-f8a354f9bde3", name = "lantern_fancy" },
}

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

function SimpleBedRoll.GiveTestHay()
    if SBR.Bedding and SBR.Bedding.GiveTestHay then
        return SBR.Bedding.GiveTestHay()
    end

    log("GiveTestHay failed: Bedding module unavailable")
    return false
end

function SimpleBedRoll.GiveLightTestItems(quantity, health)
    quantity = math.floor(tonumber(quantity) or 1)
    health = tonumber(health) or 1.0

    if quantity < 1 then
        quantity = 1
    end

    if quantity > 20 then
        log("GiveLightTestItems quantity limited from " .. quantity .. " to 20")
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
        log("GiveLightTestItems failed: player inventory unavailable")
        return false
    end

    if not inventory.CreateItem then
        log("GiveLightTestItems failed: inventory.CreateItem unavailable")
        return false
    end

    local allOk = true

    for _, itemClass in ipairs(TEST_LIGHT_ITEM_CLASSES) do
        local before = getInventoryCount(inventory, itemClass.id)
        local ok, result = pcall(
            inventory.CreateItem,
            inventory,
            itemClass.id,
            health,
            quantity
        )

        if not ok or result == false then
            allOk = false
        end

        local after = getInventoryCount(inventory, itemClass.id)
        local verified = before ~= nil
            and after ~= nil
            and after >= before + quantity

        if before ~= nil and after ~= nil and not verified then
            allOk = false
        end

        if Game and Game.ShowItemsTransfer then
            pcall(Game.ShowItemsTransfer, itemClass.id, quantity)
        end

        log(
            "GiveLightTestItems item="
            .. itemClass.name
            .. " classId="
            .. itemClass.id
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
    end

    return allOk
end

function SimpleBedRoll.SpawnTestPrefab(prefabGuid)
    prefabGuid = tostring(prefabGuid or "")
    prefabGuid = string.gsub(prefabGuid, "^%s+", "")
    prefabGuid = string.gsub(prefabGuid, "%s+$", "")
    prefabGuid = string.gsub(prefabGuid, "^[\"'](.+)[\"']$", "%1")

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

    local playerAngles = nil

    if playerEntity.GetAngles then
        playerAngles = playerEntity:GetAngles()
    end

    local spawnAngles = {
        x = 0,
        y = 0,
        z = playerAngles and playerAngles.z or 0,
    }

    local spawnParams = {
        class = TEST_ANCHOR_CLASS,
        name = "SimpleBedRoll_TestAnchor",
        position = spawnPosition,

        properties = {
            Position = spawnPosition,
            Angles = spawnAngles,
            object_Model = TEST_PREFAB_ANCHOR_MODEL,
            sPrefabID = prefabGuid,
            bSaved_by_game = 1,
            bSerialize = 1,
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

    if anchor.Hide then
        anchor:Hide(1)
    end

    if anchor.SetPos then
        anchor:SetPos(spawnPosition)
    end

    if anchor.SetAngles then
        anchor:SetAngles(spawnAngles)
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
        .. " angleZ="
        .. tostring(spawnAngles.z)
        .. " model="
        .. TEST_PREFAB_ANCHOR_MODEL
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
        .. " anchorId="
        .. tostring(anchor.id)
    )

    return true
end

function SimpleBedRoll.SpawnLitCandlePrefab()
    log(
        "SpawnLitCandlePrefab request prefabPath="
        .. LIT_CANDLE_PREFAB_PATH
        .. " prefabId="
        .. LIT_CANDLE_PREFAB_ID
    )

    local spawned = SimpleBedRoll.SpawnTestPrefab(LIT_CANDLE_PREFAB_ID)

    log(
        "SpawnLitCandlePrefab result="
        .. tostring(spawned)
        .. " anchorId="
        .. tostring(SBR.Test.anchor and SBR.Test.anchor.id or nil)
        .. " prefabId="
        .. tostring(SBR.Test.prefabGuid)
    )

    return spawned
end

function SimpleBedRoll.ProbePrefabApis(prefabGuid)
    prefabGuid = tostring(prefabGuid or "")
    prefabGuid = string.gsub(prefabGuid, "^%s+", "")
    prefabGuid = string.gsub(prefabGuid, "%s+$", "")
    prefabGuid = string.gsub(prefabGuid, "^[\"'](.+)[\"']$", "%1")

    if prefabGuid == "" then
        log("ProbePrefabApis rejected: prefab GUID is required")
        return false
    end

    local playerEntity = getPlayer()
    local spawnPosition = playerEntity and getSpawnPosition(playerEntity, 2.0)

    log(
        "ProbePrefabApis begin guid="
        .. prefabGuid
        .. " position="
        .. formatVector(spawnPosition)
    )

    local function probe(label, fn, ...)
        if not fn then
            log("ProbePrefabApis " .. label .. " unavailable")
            return nil
        end

        local ok, result = pcall(fn, ...)
        log(
            "ProbePrefabApis "
            .. label
            .. " ok="
            .. tostring(ok)
            .. " result="
            .. tostring(result)
        )

        return ok and result or nil
    end

    if Game then
        probe("CacheResource(guid)", Game.CacheResource, prefabGuid)
        probe("CreatePrefab(guid)", Game.CreatePrefab, prefabGuid)

        if spawnPosition then
            probe(
                "CreatePrefab(guid,pos)",
                Game.CreatePrefab,
                prefabGuid,
                spawnPosition
            )
            probe(
                "CreatePrefab(guid,pos,0)",
                Game.CreatePrefab,
                prefabGuid,
                spawnPosition,
                0
            )
        end
    end

    local spawned = SimpleBedRoll.SpawnTestPrefab(prefabGuid)
    local anchor = SBR.Test and SBR.Test.anchor or nil
    log(
        "ProbePrefabApis SpawnTestPrefab result="
        .. tostring(spawned)
        .. " anchorId="
        .. tostring(anchor and anchor.id or nil)
    )

    if Game and anchor and anchor.id then
        probe(
            "CreatePrefab(anchorId,guid,0)",
            Game.CreatePrefab,
            anchor.id,
            prefabGuid,
            0
        )
        probe(
            "CreatePrefab(guid,anchorId,0)",
            Game.CreatePrefab,
            prefabGuid,
            anchor.id,
            0
        )
        probe(
            "MovePrefab(anchorId,pos)",
            Game.MovePrefab,
            anchor.id,
            spawnPosition
        )
    end

    log("ProbePrefabApis end guid=" .. prefabGuid)
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
    helpLog("sbr_help - show this command list")
    helpLog("sbr_spawn - deploy the visible functional bedroll")
    helpLog("sbr_give_bedroll [quantity] [health] - add the bedroll item to Henry")
    helpLog("sbr_give_hay - add one CuraEqui small hay bundle to Henry")
    helpLog("sbr_give_light_items [quantity] [health] - add candle/lamp/lantern test items")
    helpLog("sbr_remove - remove the active bedroll")
    helpLog("sbr_status - report deployment entity state")
    helpLog("sbr_flame_z <z> - respawn only the candle flame with absolute local z")
    helpLog("sbr_flame_up [delta] - raise only the candle flame; default 0.01")
    helpLog("sbr_flame_down [delta] - lower only the candle flame; default 0.01")
    helpLog("sbr_flame_offset <right> <forward> <z> - respawn flame at local offset")
    helpLog(
        "sbr_probe_entities [radius] - scan nearby entities; default 2, max 20 metres"
    )
    helpLog("Lua hash forms also work: #sbr_help(), #sbr_spawn(), #sbr_remove()")
    helpLog(
        "#sbr_give_bedroll(quantity, health), #sbr_status(), #sbr_probe_entities(radius)"
    )
    helpLog("#sbr_flame_z(z), #sbr_flame_up(delta), #sbr_flame_down(delta)")
    helpLog("#sbr_give_light_items(quantity, health)")
    helpLog("Experimental prefab commands:")
    helpLog("sbr_test_prefab <guid>")
    helpLog("sbr_test_lit_candle_prefab - spawn " .. LIT_CANDLE_PREFAB_PATH)
    helpLog("sbr_probe_prefab <guid> - try prefab runtime APIs and log results")
    helpLog("sbr_test_status")
    helpLog("sbr_test_remove")
    helpLog(
        "#SimpleBedRoll.SpawnTestPrefab(\"guid\")"
    )
    helpLog("#sbr_test_lit_candle_prefab(), #SimpleBedRoll.SpawnLitCandlePrefab()")
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

    registerDevCommand("sbr_help", "sbr_help()", "Simple Bedroll: list development commands")
    registerDevCommand("sbr_spawn", "sbr_spawn()", "Simple Bedroll: deploy functional bedroll")
    registerDevCommand("sbr_remove", "sbr_remove()", "Simple Bedroll: remove active bedroll")
    registerDevCommand("sbr_status", "sbr_status()", "Simple Bedroll: deployment status")
    registerDevCommand("sbr_give_bedroll", "sbr_give_bedroll(%%)", "Simple Bedroll: give bedroll item")
    registerDevCommand("sbr_give_hay", "sbr_give_hay()", "Simple Bedroll: give one CuraEqui small hay bundle")
    registerDevCommand("sbr_give_light_items", "sbr_give_light_items(%%)", "Simple Bedroll: give lighting test items")
    registerDevCommand("sbr_flame_z", "sbr_flame_z(%1)", "Simple Bedroll: set live candle flame local z")
    registerDevCommand("sbr_flame_up", "sbr_flame_up(%1)", "Simple Bedroll: raise live candle flame")
    registerDevCommand("sbr_flame_down", "sbr_flame_down(%1)", "Simple Bedroll: lower live candle flame")
    registerDevCommand("sbr_flame_offset", "sbr_flame_offset(%1,%2,%3)", "Simple Bedroll: set live candle flame local offset")
    registerDevCommand("sbr_probe_entities", "sbr_probe_entities(%1)", "Simple Bedroll: scan nearby entities")
    registerDevCommand("sbr_test_prefab", "SimpleBedRoll.SpawnTestPrefab([[%1]])", "Simple Bedroll: spawn test prefab")
    registerDevCommand("sbr_test_lit_candle_prefab", "SimpleBedRoll.SpawnLitCandlePrefab()", "Simple Bedroll: spawn lit candle prefab")
    registerDevCommand("sbr_probe_prefab", "SimpleBedRoll.ProbePrefabApis([[%1]])", "Simple Bedroll: probe prefab runtime APIs")
    registerDevCommand("sbr_test_status", "SimpleBedRoll.TestStatus()", "Simple Bedroll: test prefab status")
    registerDevCommand("sbr_test_remove", "SimpleBedRoll.RemoveTestPrefab()", "Simple Bedroll: remove test prefab")

    SBR._devCommandsRegistered = true
    log("registered development console commands")

    return true
end


function sbr_help()
    return SimpleBedRoll.Help()
end

function sbr_spawn()
    return SimpleBedRoll.SpawnFunctionalTestBed()
end

function sbr_give_bedroll(quantity, health)
    return SimpleBedRoll.GiveBedrollItem(quantity, health)
end

function sbr_give_hay()
    return SimpleBedRoll.GiveTestHay()
end

function sbr_give_light_items(quantity, health)
    return SimpleBedRoll.GiveLightTestItems(quantity, health)
end

local function currentFlameOffset()
    local stateOffset = SBR.FunctionalTest
        and SBR.FunctionalTest.candleFlameOffset
        or nil

    if stateOffset then
        return {
            right = tonumber(stateOffset.right) or 0,
            forward = tonumber(stateOffset.forward) or 0,
            z = tonumber(stateOffset.z) or 0,
        }
    end

    if SBR.CampLight and SBR.CampLight.GetFlameOffset then
        return SBR.CampLight.GetFlameOffset()
    end

    local flameConfig = SimpleBedRoll_Config
        and SimpleBedRoll_Config.CampProps
        and SimpleBedRoll_Config.CampProps.Candle
        and SimpleBedRoll_Config.CampProps.Candle.Flame
        or {}
    local offset = flameConfig.Offset or {}

    return {
        right = tonumber(offset.right) or 0.003486633,
        forward = tonumber(offset.forward) or 0.001457214,
        z = tonumber(offset.z) or 0.06493159,
    }
end

function SimpleBedRoll.SetCandleFlameOffset(right, forward, z)
    local state = SBR.FunctionalTest

    if not state or not state.candlePosition then
        log("flame tune failed: no deployed candle position tracked")
        return false
    end

    if not (SBR.CampLight and SBR.CampLight.SpawnCandleFlame) then
        log("flame tune failed: CampLight.SpawnCandleFlame unavailable")
        return false
    end

    local offset = {
        right = tonumber(right),
        forward = tonumber(forward),
        z = tonumber(z),
    }

    if offset.right == nil or offset.forward == nil or offset.z == nil then
        log("flame tune failed: usage sbr_flame_offset <right> <forward> <z>")
        return false
    end

    if state.candleFlame then
        if SBR.CampLight.Remove then
            SBR.CampLight.Remove(state.candleFlame)
        elseif state.candleFlame.DeleteThis then
            pcall(state.candleFlame.DeleteThis, state.candleFlame)
        end
    end

    state.candleFlame = nil
    state.candleFlameOffset = offset
    state.candleFlame = SBR.CampLight.SpawnCandleFlame(
        state.candlePosition,
        state.candleAngleZ or 0,
        offset
    )

    log(
        "flame tune offset right="
        .. tostring(offset.right)
        .. " forward="
        .. tostring(offset.forward)
        .. " z="
        .. tostring(offset.z)
        .. " candlePos="
        .. formatVector(state.candlePosition)
        .. " resultId="
        .. tostring(state.candleFlame and state.candleFlame.id or nil)
    )

    return state.candleFlame ~= nil
end

function SimpleBedRoll.SetCandleFlameZ(z)
    local offset = currentFlameOffset()
    return SimpleBedRoll.SetCandleFlameOffset(
        offset.right,
        offset.forward,
        z
    )
end

function SimpleBedRoll.NudgeCandleFlameZ(delta)
    delta = tonumber(delta) or 0.01

    local offset = currentFlameOffset()
    return SimpleBedRoll.SetCandleFlameOffset(
        offset.right,
        offset.forward,
        offset.z + delta
    )
end

function sbr_flame_z(z)
    return SimpleBedRoll.SetCandleFlameZ(z)
end

function sbr_flame_up(delta)
    return SimpleBedRoll.NudgeCandleFlameZ(delta)
end

function sbr_flame_down(delta)
    return SimpleBedRoll.NudgeCandleFlameZ(-1 * (tonumber(delta) or 0.01))
end

function sbr_flame_offset(right, forward, z)
    return SimpleBedRoll.SetCandleFlameOffset(right, forward, z)
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

function sbr_test_lit_candle_prefab()
    return SimpleBedRoll.SpawnLitCandlePrefab()
end
