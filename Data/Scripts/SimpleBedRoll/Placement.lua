-- Player lookup and bed placement transforms.

SimpleBedRoll = SimpleBedRoll or {}

local Placement = SimpleBedRoll.Placement or {}
SimpleBedRoll.Placement = Placement

local placementConfig = SimpleBedRoll_Config.Placement or {}
local BED_DISTANCE = tonumber(placementConfig.BedDistance) or 1.0

local function log(message)
    System.LogAlways("[SimpleBedRoll/Placement] " .. tostring(message))
end

function Placement.GetPlayer()
    if System and System.GetEntityByName then
        return System.GetEntityByName("Henry")
            or System.GetEntityByName("dude")
    end

    if player and player.this then
        return player.this
    end

    return nil
end

function Placement.CopyPosition(position)
    return {
        x = position.x,
        y = position.y,
        z = position.z,
    }
end

function Placement.OffsetFromHeading(origin, angleZ, right, forward, z)
    if not origin then
        return nil
    end

    angleZ = tonumber(angleZ) or 0
    right = tonumber(right) or 0
    forward = tonumber(forward) or 0
    z = tonumber(z) or 0

    local sinZ = math.sin(angleZ)
    local cosZ = math.cos(angleZ)

    local position = {
        x = origin.x + right * -sinZ + forward * cosZ,
        y = origin.y + right * cosZ + forward * sinZ,
        z = origin.z + z,
    }

    log(
        string.format(
            "localOffset right=%.2f forward=%.2f z=%.2f heading=%.4f worldPos=%.2f, %.2f, %.2f",
            right,
            forward,
            z,
            angleZ,
            position.x,
            position.y,
            position.z
        )
    )

    return position
end

function Placement.GetGroundedPosition(position, verticalOffset)
    if not position then
        return nil, "position unavailable"
    end

    if not (Physics and Physics.RayWorldIntersection) then
        log("groundProbe failed reason=Physics.RayWorldIntersection unavailable")
        return nil, "raycast unavailable"
    end

    local entityTypes = (ent_terrain or 0) + (ent_static or 0)
    if entityTypes == 0 then
        log("groundProbe failed reason=terrain/static entity masks unavailable")
        return nil, "entity masks unavailable"
    end

    verticalOffset = tonumber(verticalOffset) or 0

    local rayStart = {
        x = position.x,
        y = position.y,
        z = position.z + 50,
    }
    local rayDirection = {
        x = 0,
        y = 0,
        z = -700,
    }
    local hitTable = g_HitTable or {}
    hitTable[1] = nil

    log(
        string.format(
            "groundProbe requested=%.2f, %.2f, %.2f start=%.2f, %.2f, %.2f end=%.2f, %.2f, %.2f verticalOffset=%.2f",
            position.x,
            position.y,
            position.z,
            rayStart.x,
            rayStart.y,
            rayStart.z,
            rayStart.x + rayDirection.x,
            rayStart.y + rayDirection.y,
            rayStart.z + rayDirection.z,
            verticalOffset
        )
    )

    local ok, hits = pcall(
        Physics.RayWorldIntersection,
        rayStart,
        rayDirection,
        1,
        entityTypes,
        nil,
        nil,
        hitTable
    )

    if not ok or tonumber(hits) == nil or tonumber(hits) <= 0 then
        log(
            "groundProbe failed hits="
            .. tostring(hits)
            .. " error="
            .. tostring(ok and nil or hits)
        )
        return nil, "no ground hit"
    end

    local hitPosition = hitTable[1] and hitTable[1].pos or nil
    if not hitPosition then
        log("groundProbe failed reason=hit position unavailable")
        return nil, "hit position unavailable"
    end

    local grounded = {
        x = position.x,
        y = position.y,
        z = hitPosition.z + verticalOffset,
    }

    log(
        string.format(
            "groundProbe hit=%.2f, %.2f, %.2f grounded=%.2f, %.2f, %.2f",
            hitPosition.x,
            hitPosition.y,
            hitPosition.z,
            grounded.x,
            grounded.y,
            grounded.z
        )
    )

    return grounded, hitPosition
end

function Placement.GetPlayerHeading(playerEntity)
    if not playerEntity or not playerEntity.GetAngles then
        return 0
    end

    local angles = playerEntity:GetAngles()

    if angles and angles.z then
        return angles.z
    end

    return 0
end

function Placement.GetBedPlacement(playerEntity)
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

    return position, Placement.GetPlayerHeading(playerEntity)
end
