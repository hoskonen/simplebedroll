-- Player lookup and bed placement transforms.

SimpleBedRoll = SimpleBedRoll or {}

local Placement = SimpleBedRoll.Placement or {}
SimpleBedRoll.Placement = Placement

local placementConfig = SimpleBedRoll_Config.Placement or {}
local BED_DISTANCE = tonumber(placementConfig.BedDistance) or 1.0

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

    local angleZ = 0

    if playerEntity.GetAngles then
        local angles = playerEntity:GetAngles()

        if angles and angles.z then
            angleZ = angles.z
        end
    end

    return position, angleZ
end
