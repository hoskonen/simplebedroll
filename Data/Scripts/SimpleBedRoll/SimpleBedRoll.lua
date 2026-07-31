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