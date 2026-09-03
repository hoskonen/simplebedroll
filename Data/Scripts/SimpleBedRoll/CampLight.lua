-- Runtime light helpers for temporary camp props.

SimpleBedRoll = SimpleBedRoll or {}

local CampLight = SimpleBedRoll.CampLight or {}
SimpleBedRoll.CampLight = CampLight

local SBR = SimpleBedRoll
local Placement = SBR.Placement

local campPropsConfig = SimpleBedRoll_Config.CampProps or {}
local candleConfig = campPropsConfig.Candle or {}
local lightConfig = candleConfig.Light or {}
local lightOffset = lightConfig.Offset or {}
local flameConfig = candleConfig.Flame or {}
local flameOffset = flameConfig.Offset or {}
local flameRotation = flameConfig.Rotation or {}

local LIGHT_CLASS = "Light"
local LIGHT_NAME = tostring(
    lightConfig.Name or "SimpleBedRoll_TestCampCandleLight"
)
local FLAME_CLASS = "ParticleEffect"
local FLAME_NAME = tostring(
    flameConfig.Name or "SimpleBedRoll_TestCampCandleFlame"
)
local FLAME_EFFECT = tostring(
    flameConfig.Effect or "WH_Particels.fires.candle"
)

local function log(message)
    System.LogAlways("[SimpleBedRoll/CampLight] " .. tostring(message))
end

local function copyPosition(position)
    if Placement and Placement.CopyPosition then
        return Placement.CopyPosition(position)
    end

    return {
        x = position.x,
        y = position.y,
        z = position.z,
    }
end

local function formatVector(position)
    if not position then
        return "nil"
    end

    return string.format(
        "%.2f, %.2f, %.2f",
        tonumber(position.x) or 0,
        tonumber(position.y) or 0,
        tonumber(position.z) or 0
    )
end

local function buildLightProperties()
    local color = lightConfig.Color or {}
    local style = lightConfig.Style or {}
    local projector = lightConfig.Projector or {}
    local shadows = lightConfig.Shadows or {}
    local options = lightConfig.Options or {}

    return {
        Radius = tonumber(lightConfig.Radius) or 2.5,
        fAttenuationBulbSize =
            tonumber(lightConfig.AttenuationBulbSize) or 0.1,

        Color = {
            clrDiffuse = {
                x = tonumber(color.x) or 0.462077,
                y = tonumber(color.y) or 0.158961,
                z = tonumber(color.z) or 0.0561285,
            },
            fDiffuseMultiplier = tonumber(color.DiffuseMultiplier) or 0.01,
            fSpecularMultiplier = tonumber(color.SpecularMultiplier) or 1.5,
            fVolumetricMultiplier = tonumber(color.VolumetricMultiplier) or 4,
            fGIMultiplier = tonumber(color.GIMultiplier) or 1,
        },

        Style = {
            esLightAnimType = tostring(
                style.LightAnimType or "LoopRandomSeed"
            ),
            fAnimationSpeed = tonumber(style.AnimationSpeed) or 0.5,
            nAnimationPhase = tonumber(style.AnimationPhase) or 9,
            nLightStyle = tonumber(style.LightStyle) or 20,
            flare_Flare = tostring(style.Flare or ""),
            lightanimation_LightAnimation = tostring(
                style.LightAnimation or ""
            ),
        },

        Projector = {
            texture_Texture = tostring(projector.Texture or ""),
            bSpotShadow = projector.SpotShadow ~= false,
            bSpotShadowBack = projector.SpotShadowBack ~= false,
            bSpotShadowBottom = projector.SpotShadowBottom ~= false,
            bSpotShadowLeft = projector.SpotShadowLeft ~= false,
            bSpotShadowRight = projector.SpotShadowRight ~= false,
            bSpotShadowTop = projector.SpotShadowTop == true,
            fProjectorFov = tonumber(projector.Fov) or 90,
            fProjectorNearPlane = tonumber(projector.NearPlane) or 0,
        },

        Shadows = {
            nCastShadows = tonumber(shadows.CastShadows) or 3,
        },

        Options = {
            fVerticalClipDistanceDownward =
                tonumber(options.VerticalClipDistanceDownward) or 1.5,
            fVerticalClipDistanceUpward =
                tonumber(options.VerticalClipDistanceUpward) or 3,
            bAffectsThisAreaOnly = options.AffectsThisAreaOnly ~= false,
            esGIMode = tostring(options.GIMode or "None"),
        },
    }
end

local function getWorldPosition(entity)
    if entity and entity.GetWorldPos then
        local ok, position = pcall(entity.GetWorldPos, entity)
        if ok then
            return position
        end
    end

    return nil
end

function CampLight.GetName()
    return LIGHT_NAME
end

function CampLight.GetFlameName()
    return FLAME_NAME
end

function CampLight.SpawnCandleLight(candlePosition, angleZ)
    if not candlePosition then
        log("spawn skipped reason=candle-position-unavailable")
        return nil
    end

    if not (System and System.SpawnEntity) then
        log("spawn skipped reason=System.SpawnEntity-unavailable")
        return nil
    end

    if not (Placement and Placement.OffsetFromHeading) then
        log("spawn skipped reason=Placement.OffsetFromHeading-unavailable")
        return nil
    end

    local wickPosition = Placement.OffsetFromHeading(
        candlePosition,
        angleZ,
        lightOffset.right,
        lightOffset.forward,
        lightOffset.z
    )

    if not wickPosition then
        log("spawn skipped reason=wick-position-failed")
        return nil
    end

    local properties = buildLightProperties()
    local params = {
        class = LIGHT_CLASS,
        name = LIGHT_NAME,
        position = copyPosition(wickPosition),
        bActive = true,
        properties = properties,
    }

    log(
        "spawn request candlePosition="
        .. formatVector(candlePosition)
        .. " wickOffset="
        .. string.format(
            "%.2f, %.2f, %.2f",
            tonumber(lightOffset.right) or 0,
            tonumber(lightOffset.forward) or 0,
            tonumber(lightOffset.z) or 0
        )
        .. " position="
        .. formatVector(wickPosition)
        .. " class="
        .. LIGHT_CLASS
    )

    local ok, entityOrError = pcall(System.SpawnEntity, params)
    if not ok then
        log("spawn failed error=" .. tostring(entityOrError))
        return nil
    end

    local light = entityOrError
    if not light or not light.id then
        log("spawn failed reason=no-entity-returned")
        return nil
    end

    local activeOk, activeError = pcall(function()
        light.bActive = true
    end)

    if not activeOk then
        log("active assignment failed error=" .. tostring(activeError))
    end

    if light.SetPos then
        pcall(light.SetPos, light, copyPosition(wickPosition))
    end

    local worldPosition = getWorldPosition(light)
    local radius = light.Properties and light.Properties.Radius or properties.Radius
    local diffuse = light.Properties
        and light.Properties.Color
        and light.Properties.Color.clrDiffuse
        or properties.Color.clrDiffuse

    log(
        "spawn result id="
        .. tostring(light.id)
        .. " worldPosition="
        .. formatVector(worldPosition)
        .. " radius="
        .. tostring(radius)
        .. " diffuse="
        .. formatVector(diffuse)
        .. " active="
        .. tostring(light.bActive)
    )

    return light
end

function CampLight.GetFlameOffset()
    return {
        right = tonumber(flameOffset.right) or 0.003486633,
        forward = tonumber(flameOffset.forward) or 0.001457214,
        z = tonumber(flameOffset.z) or 0.06493159,
    }
end

function CampLight.SpawnCandleFlame(candlePosition, angleZ, offsetOverride)
    if not candlePosition then
        log("flame spawn skipped reason=candle-position-unavailable")
        return nil
    end

    if not (System and System.SpawnEntity) then
        log("flame spawn skipped reason=System.SpawnEntity-unavailable")
        return nil
    end

    if not (Placement and Placement.OffsetFromHeading) then
        log("flame spawn skipped reason=Placement.OffsetFromHeading-unavailable")
        return nil
    end

    local offset = offsetOverride or CampLight.GetFlameOffset()

    local flamePosition = Placement.OffsetFromHeading(
        candlePosition,
        angleZ,
        offset.right,
        offset.forward,
        offset.z
    )

    if not flamePosition then
        log("flame spawn skipped reason=flame-position-failed")
        return nil
    end

    local rotation = {
        x = tonumber(flameRotation.x) or 0.7071068,
        y = tonumber(flameRotation.y) or 0.7071068,
        z = tonumber(flameRotation.z) or 0,
        w = tonumber(flameRotation.w) or 0,
    }

    local params = {
        class = FLAME_CLASS,
        name = FLAME_NAME,
        position = copyPosition(flamePosition),
        orientation = rotation,

        properties = {
            ParticleEffect = FLAME_EFFECT,
            bActive = true,
        },
    }

    log(
        "flame spawn effect="
        .. FLAME_EFFECT
        .. " candlePos="
        .. formatVector(candlePosition)
        .. " flamePos="
        .. formatVector(flamePosition)
        .. " offset="
        .. string.format(
            "%.6f, %.6f, %.6f",
            tonumber(offset.right) or 0,
            tonumber(offset.forward) or 0,
            tonumber(offset.z) or 0
        )
        .. " rotation="
        .. string.format(
            "%.7f, %.7f, %.7f, %.7f",
            rotation.x,
            rotation.y,
            rotation.z,
            rotation.w
        )
    )

    local ok, entityOrError = pcall(System.SpawnEntity, params)
    if not ok then
        log("flame spawn failed error=" .. tostring(entityOrError))
        return nil
    end

    local flame = entityOrError
    if not flame or not flame.id then
        log("flame spawn failed reason=no-entity-returned")
        return nil
    end

    local activeOk, activeError = pcall(function()
        flame.bActive = true
    end)

    if not activeOk then
        log("flame active assignment failed error=" .. tostring(activeError))
    end

    if flame.SetPos then
        pcall(flame.SetPos, flame, copyPosition(flamePosition))
    end

    local worldPosition = getWorldPosition(flame)

    log(
        "flame spawn result id="
        .. tostring(flame.id)
        .. " worldPosition="
        .. formatVector(worldPosition)
        .. " active="
        .. tostring(flame.bActive)
    )

    return flame
end

function CampLight.Remove(light)
    if not light then
        return true
    end

    local id = light.id
    if light.DeleteThis then
        local ok, err = pcall(light.DeleteThis, light)
        if not ok then
            log("remove failed id=" .. tostring(id) .. " error=" .. tostring(err))
            return false
        end
    elseif System and System.RemoveEntity and id then
        local ok, err = pcall(System.RemoveEntity, id)
        if not ok then
            log("remove failed id=" .. tostring(id) .. " error=" .. tostring(err))
            return false
        end
    else
        log("remove failed id=" .. tostring(id) .. " reason=no-remove-api")
        return false
    end

    log("removed id=" .. tostring(id))
    return true
end
