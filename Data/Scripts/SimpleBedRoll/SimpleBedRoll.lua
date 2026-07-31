SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll

SBR.Test = SBR.Test or {
    anchor = nil,
    prefabGuid = nil,
    prefabSpawnRequested = false,
}

local function log(message)
    System.LogAlways("[SimpleBedRoll] " .. tostring(message))
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

function SimpleBedRoll.OnGameplayStarted()
    log("Initialized")
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
        class = "SimpleBedRoll_TestAnchor",
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

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll

SBR.FunctionalTest = SBR.FunctionalTest or {
    bed = nil,
    trigger = nil,
}

local FUNCTIONAL_BED_CLASS = "SimpleBedRoll_BedEntity"
local FUNCTIONAL_BED_NAME = "SimpleBedRoll_TestBed"
local FUNCTIONAL_TRIGGER_NAME = "SimpleBedRoll_TestBedTrigger"

local BED_DISTANCE = 1.0

local BED_TRIGGER_OFFSET = {
    x = 0.15,
    y = -0.09,
    z = 0.35,
}

local BED_TRIGGER_SCALE = {
    0.29,
    0.29,
    0.29,
}

local function functionalLog(message)
    System.LogAlways(
        "[SimpleBedRoll/FunctionalTest] " .. tostring(message)
    )
end

local function functionalGetPlayer()
    if System and System.GetEntityByName then
        return System.GetEntityByName("Henry")
            or System.GetEntityByName("dude")
    end

    if player and player.this then
        return player.this
    end

    return nil
end

local function functionalCopyPosition(position)
    return {
        x = position.x,
        y = position.y,
        z = position.z,
    }
end

local function functionalGetPlacement(playerEntity)
    if not playerEntity
        or not playerEntity.GetWorldPos
        or not playerEntity.GetDirectionVector then
        return nil, nil
    end

    local playerPosition = playerEntity:GetWorldPos()
    local direction = playerEntity:GetDirectionVector(0)

    if not playerPosition or not direction then
        return nil, nil
    end

    local position = {
        x = playerPosition.x + direction.x * BED_DISTANCE,
        y = playerPosition.y + direction.y * BED_DISTANCE,
        z = playerPosition.z,
    }

    local angleZ = 0

    if playerEntity.GetAngles then
        local angles = playerEntity:GetAngles()

        if angles and angles.z then
            angleZ = angles.z
        end
    end

    return position, angleZ
end

local function functionalEntityExists(entity)
    if not entity or not entity.id then
        return false
    end

    if System and System.GetEntity then
        return System.GetEntity(entity.id) ~= nil
    end

    return true
end

local function functionalDeleteEntity(entity, label)
    if not entity then
        return true
    end

    local id = entity.id

    if entity.DeleteThis then
        local ok, err = pcall(entity.DeleteThis, entity)

        if not ok then
            functionalLog(
                "failed to delete "
                .. tostring(label)
                .. ": "
                .. tostring(err)
            )

            return false
        end
    elseif System and System.RemoveEntity and id then
        local ok, err = pcall(System.RemoveEntity, id)

        if not ok then
            functionalLog(
                "failed to remove "
                .. tostring(label)
                .. ": "
                .. tostring(err)
            )

            return false
        end
    else
        functionalLog(
            "cannot delete "
            .. tostring(label)
            .. ": no supported removal function"
        )

        return false
    end

    functionalLog(
        "deleted "
        .. tostring(label)
        .. " id="
        .. tostring(id)
    )

    return true
end

local function functionalFindEntitiesByClass(className)
    if not System or not System.GetEntitiesByClass then
        return {}
    end

    local entities = System.GetEntitiesByClass(className)

    if type(entities) ~= "table" then
        return {}
    end

    return entities
end

local function functionalRemoveExistingEntities()
    local success = true
    local deletedIds = {}

    local function deleteOnce(entity, label)
        if not entity or not entity.id then
            return true
        end

        local idText = tostring(entity.id)

        if deletedIds[idText] then
            return true
        end

        deletedIds[idText] = true

        return functionalDeleteEntity(entity, label)
    end

    -- Remove tracked trigger first so it cannot retain a link to a deleted bed.
    if SBR.FunctionalTest.trigger then
        if not deleteOnce(
            SBR.FunctionalTest.trigger,
            "tracked trigger"
        ) then
            success = false
        end
    end

    if SBR.FunctionalTest.bed then
        if not deleteOnce(
            SBR.FunctionalTest.bed,
            "tracked bed"
        ) then
            success = false
        end
    end

    SBR.FunctionalTest.trigger = nil
    SBR.FunctionalTest.bed = nil

    -- Development cleanup for entities whose Lua references were lost,
    -- for example after a script reload.
    local triggers = functionalFindEntitiesByClass("BedTrigger")

    for _, trigger in ipairs(triggers) do
        if trigger
            and trigger.GetName
            and trigger:GetName() == FUNCTIONAL_TRIGGER_NAME then

            if not deleteOnce(
                trigger,
                "orphaned test trigger"
            ) then
                success = false
            end
        end
    end

    local beds = functionalFindEntitiesByClass(FUNCTIONAL_BED_CLASS)

    for _, bed in ipairs(beds) do
        if not deleteOnce(
            bed,
            "orphaned test bed"
        ) then
            success = false
        end
    end

    return success
end

function SimpleBedRoll.SpawnFunctionalTestBed()
    if not System or not System.SpawnEntity then
        functionalLog(
            "spawn failed: System.SpawnEntity unavailable"
        )

        return false
    end

    functionalRemoveExistingEntities()

    local playerEntity = functionalGetPlayer()

    if not playerEntity then
        functionalLog("spawn failed: player not found")
        return false
    end

    local bedPosition, angleZ =
        functionalGetPlacement(playerEntity)

    if not bedPosition then
        functionalLog(
            "spawn failed: could not calculate placement"
        )

        return false
    end

    functionalLog(
        string.format(
            "placement pos=%.2f, %.2f, %.2f angleZ=%.4f",
            bedPosition.x,
            bedPosition.y,
            bedPosition.z,
            angleZ
        )
    )

    local bedParams = {
        class = FUNCTIONAL_BED_CLASS,
        name = FUNCTIONAL_BED_NAME,
        position = functionalCopyPosition(bedPosition),

        properties = {
            Position = functionalCopyPosition(bedPosition),

            Angles = {
                x = 0,
                y = 0,
                z = angleZ,
            },

            object_Model = "",

            bSaved_by_game = 1,
            bSerialize = 1,

            Bed = {
                esSleepQuality = "low",
            },
        },
    }

    local bedOk, bedOrError = pcall(
        System.SpawnEntity,
        bedParams
    )

    if not bedOk then
        functionalLog(
            "bed spawn raised an error: "
            .. tostring(bedOrError)
        )

        return false
    end

    local bed = bedOrError

    if not bed or not bed.id then
        functionalLog(
            "bed spawn failed: no entity returned"
        )

        return false
    end

    SBR.FunctionalTest.bed = bed

    functionalLog(
        "bed spawned id="
        .. tostring(bed.id)
        .. " class="
        .. FUNCTIONAL_BED_CLASS
    )

    local triggerPosition = {
        x = bedPosition.x + BED_TRIGGER_OFFSET.x,
        y = bedPosition.y + BED_TRIGGER_OFFSET.y,
        z = bedPosition.z + BED_TRIGGER_OFFSET.z,
    }

    local triggerParams = {
        class = "BedTrigger",
        name = FUNCTIONAL_TRIGGER_NAME,
        position = triggerPosition,
        scale = BED_TRIGGER_SCALE,

        properties = {
            Click = {
                bIsActive = true,

                -- Preserve the direct reference used by DJB.
                bedEntity = bed,

                UseMessage = "@ui_hud_sleep",

                bAllowNoOwner = 0,
                bCheckOwner = 0,

                esActionType = "Stance",
                sAction = "lying",
            },
        },
    }

    local triggerOk, triggerOrError = pcall(
        System.SpawnEntity,
        triggerParams
    )

    if not triggerOk then
        functionalLog(
            "trigger spawn raised an error: "
            .. tostring(triggerOrError)
        )

        functionalRemoveExistingEntities()
        return false
    end

    local trigger = triggerOrError

    if not trigger or not trigger.id then
        functionalLog(
            "trigger spawn failed: no entity returned"
        )

        functionalRemoveExistingEntities()
        return false
    end

    SBR.FunctionalTest.trigger = trigger

    functionalLog(
        "trigger spawned id="
        .. tostring(trigger.id)
        .. " pos="
        .. string.format(
            "%.2f, %.2f, %.2f",
            triggerPosition.x,
            triggerPosition.y,
            triggerPosition.z
        )
    )

    if not trigger.CreateLink or not bed.CreateLink then
        functionalLog(
            "linking failed: CreateLink unavailable"
        )

        functionalRemoveExistingEntities()
        return false
    end

    local triggerLinkOk, triggerLinkError = pcall(
        trigger.CreateLink,
        trigger,
        "",
        bed.id
    )

    if not triggerLinkOk then
        functionalLog(
            "trigger-to-bed link failed: "
            .. tostring(triggerLinkError)
        )

        functionalRemoveExistingEntities()
        return false
    end

    functionalLog(
        "linked trigger -> bed"
    )

    local bedLinkOk, bedLinkError = pcall(
        bed.CreateLink,
        bed,
        "mTrigger",
        trigger.id
    )

    if not bedLinkOk then
        functionalLog(
            "bed-to-trigger link failed: "
            .. tostring(bedLinkError)
        )

        functionalRemoveExistingEntities()
        return false
    end

    functionalLog(
        "linked bed mTrigger -> trigger"
    )

    functionalLog(
        "functional test bed ready"
    )

    return true
end

function SimpleBedRoll.RemoveFunctionalTestBed()
    local hadTrackedEntities =
        SBR.FunctionalTest.bed ~= nil
        or SBR.FunctionalTest.trigger ~= nil

    local removed = functionalRemoveExistingEntities()

    functionalLog(
        "remove completed hadTrackedEntities="
        .. tostring(hadTrackedEntities)
        .. " success="
        .. tostring(removed)
    )

    return removed
end

function SimpleBedRoll.FunctionalTestBedStatus()
    local bed = SBR.FunctionalTest.bed
    local trigger = SBR.FunctionalTest.trigger

    local bedExists = functionalEntityExists(bed)
    local triggerExists = functionalEntityExists(trigger)

    functionalLog(
        "status bedTracked="
        .. tostring(bed ~= nil)
        .. " bedExists="
        .. tostring(bedExists)
        .. " bedId="
        .. tostring(bed and bed.id or nil)
        .. " triggerTracked="
        .. tostring(trigger ~= nil)
        .. " triggerExists="
        .. tostring(triggerExists)
        .. " triggerId="
        .. tostring(trigger and trigger.id or nil)
    )

    return bedExists and triggerExists
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