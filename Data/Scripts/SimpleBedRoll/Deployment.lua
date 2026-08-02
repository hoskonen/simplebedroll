-- Complete visual prop, functional bed, and trigger lifecycle.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll

SBR.FunctionalTest = SBR.FunctionalTest or {
    bed = nil,
    trigger = nil,
    visualAnchor = nil,
    modelPath = nil,
}

local FUNCTIONAL_BED_CLASS = "SimpleBedRoll_BedEntity"
local FUNCTIONAL_BED_NAME = "SimpleBedRoll_TestBed"
local FUNCTIONAL_TRIGGER_CLASS = "BedTrigger"
local FUNCTIONAL_TRIGGER_NAME = "SimpleBedRoll_TestBedTrigger"
local FUNCTIONAL_VISUAL_CLASS = "SimpleBedRoll_VisualAnchor"
local FUNCTIONAL_VISUAL_NAME = "SimpleBedRoll_TestBedVisual"

local visualConfig = SimpleBedRoll_Config.Visual or {}
local FUNCTIONAL_VISUAL_MODEL_PATH = tostring(
    visualConfig.ModelPath
    or "Objects/manmade/common_furniture/beds/low/bed_makeshift_a.cgf"
)

local triggerConfig = SimpleBedRoll_Config.Trigger or {}
local BED_TRIGGER_PACK_HINT = tostring(
    triggerConfig.PackHint or "@ui_pickup_item"
)
local BED_TRIGGER_OFFSET = triggerConfig.Offset or {
    x = 0.15,
    y = -0.09,
    z = 0.35,
}

local BED_TRIGGER_SCALE = triggerConfig.Scale or {
    0.29,
    0.29,
    0.29,
}

local function functionalLog(message)
    System.LogAlways(
        "[SimpleBedRoll/FunctionalTest] " .. tostring(message)
    )
end

local Placement = SBR.Placement
local BedTriggerBehavior = SBR.BedTrigger

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

    if SBR.FunctionalTest.visualAnchor then
        if not deleteOnce(
            SBR.FunctionalTest.visualAnchor,
            "tracked visual prop"
        ) then
            success = false
        end
    end

    SBR.FunctionalTest.trigger = nil
    SBR.FunctionalTest.bed = nil
    SBR.FunctionalTest.visualAnchor = nil
    SBR.FunctionalTest.modelPath = nil

    -- Development cleanup for entities whose Lua references were lost,
    -- for example after a script reload.
    local triggers = functionalFindEntitiesByClass(
        FUNCTIONAL_TRIGGER_CLASS
    )

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

    local visualAnchors = functionalFindEntitiesByClass(
        FUNCTIONAL_VISUAL_CLASS
    )

    for _, anchor in ipairs(visualAnchors) do
        if anchor
            and anchor.GetName
            and anchor:GetName() == FUNCTIONAL_VISUAL_NAME then

            if not deleteOnce(
                anchor,
                "orphaned visual prop"
            ) then
                success = false
            end
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

    if not functionalRemoveExistingEntities() then
        functionalLog(
            "spawn failed: previous deployment could not be removed"
        )

        return false
    end

    local playerEntity = Placement.GetPlayer()

    if not playerEntity then
        functionalLog("spawn failed: player not found")
        return false
    end

    local bedPosition, angleZ =
        Placement.GetBedPlacement(playerEntity)

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

    local visualParams = {
        class = FUNCTIONAL_VISUAL_CLASS,
        name = FUNCTIONAL_VISUAL_NAME,
        position = Placement.CopyPosition(bedPosition),

        properties = {
            Position = Placement.CopyPosition(bedPosition),

            Angles = {
                x = 0,
                y = 0,
                z = angleZ,
            },

            object_Model = FUNCTIONAL_VISUAL_MODEL_PATH,

            bSaved_by_game = 1,
            bSerialize = 1,
        },
    }

    local visualOk, visualOrError = pcall(
        System.SpawnEntity,
        visualParams
    )

    if not visualOk then
        functionalLog(
            "visual prop spawn raised an error: "
            .. tostring(visualOrError)
        )

        return false
    end

    local visualAnchor = visualOrError

    if not visualAnchor or not visualAnchor.id then
        functionalLog(
            "visual prop spawn failed: no entity returned"
        )

        return false
    end

    SBR.FunctionalTest.visualAnchor = visualAnchor
    SBR.FunctionalTest.modelPath = FUNCTIONAL_VISUAL_MODEL_PATH

    if visualAnchor.SetAngles then
        visualAnchor:SetAngles({
            x = 0,
            y = 0,
            z = angleZ,
        })
    end

    functionalLog(
        "visual prop spawned id="
        .. tostring(visualAnchor.id)
        .. " modelPath="
        .. FUNCTIONAL_VISUAL_MODEL_PATH
    )

    local bedParams = {
        class = FUNCTIONAL_BED_CLASS,
        name = FUNCTIONAL_BED_NAME,
        position = Placement.CopyPosition(bedPosition),

        properties = {
            Position = Placement.CopyPosition(bedPosition),

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

        functionalRemoveExistingEntities()
        return false
    end

    local bed = bedOrError

    if not bed or not bed.id then
        functionalLog(
            "bed spawn failed: no entity returned"
        )

        functionalRemoveExistingEntities()
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
        class = FUNCTIONAL_TRIGGER_CLASS,
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

            Hold = {
                bIsActive = true,
                UseMessage = BED_TRIGGER_PACK_HINT,

                bAllowNoOwner = 1,
                bCheckOwner = 0,

                esActionType = "None",
                sAction = "",
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

    if not BedTriggerBehavior
        or not BedTriggerBehavior.Attach
        or not BedTriggerBehavior.Attach(trigger) then

        functionalLog(
            "trigger setup failed: bedroll behavior not attached"
        )

        functionalRemoveExistingEntities()
        return false
    end

    functionalLog(
        "trigger spawned id="
        .. tostring(trigger.id)
        .. " class="
        .. FUNCTIONAL_TRIGGER_CLASS
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
        or SBR.FunctionalTest.visualAnchor ~= nil

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
    local visualAnchor = SBR.FunctionalTest.visualAnchor

    local bedExists = functionalEntityExists(bed)
    local triggerExists = functionalEntityExists(trigger)
    local visualExists = functionalEntityExists(visualAnchor)

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
        .. " visualTracked="
        .. tostring(visualAnchor ~= nil)
        .. " visualExists="
        .. tostring(visualExists)
        .. " visualId="
        .. tostring(visualAnchor and visualAnchor.id or nil)
        .. " modelPath="
        .. tostring(SBR.FunctionalTest.modelPath)
    )

    return bedExists and triggerExists and visualExists
end
