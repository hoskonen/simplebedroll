-- Complete visual prop, functional bed, and trigger lifecycle.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll

SBR.FunctionalTest = SBR.FunctionalTest or {
    bed = nil,
    trigger = nil,
    visualAnchor = nil,
    candleAnchor = nil,
    modelPath = nil,
    returnItemOnPack = false,
    beddingRequiredOnPack = false,
    beddingClassId = nil,
}

local FUNCTIONAL_BED_CLASS = "SimpleBedRoll_BedEntity"
local FUNCTIONAL_BED_NAME = "SimpleBedRoll_TestBed"
local FUNCTIONAL_TRIGGER_CLASS = "BedTrigger"
local FUNCTIONAL_TRIGGER_NAME = "SimpleBedRoll_TestBedTrigger"
local FUNCTIONAL_VISUAL_CLASS = "SimpleBedRoll_VisualAnchor"
local FUNCTIONAL_VISUAL_NAME = "SimpleBedRoll_TestBedVisual"
local BEDROLL_ITEM_CLASS_ID = "7f3f6a24-3b4d-4ec7-9a91-6d8e9f5a2c11"

local campPropsConfig = SimpleBedRoll_Config.CampProps or {}
local candleConfig = campPropsConfig.Candle or {}
local candleOffset = candleConfig.Offset or {}
local CANDLE_PROP_NAME = tostring(
    candleConfig.Name or "SimpleBedRoll_TestCampCandle"
)
local CANDLE_MODEL_PATH = tostring(
    candleConfig.ModelPath or "manmade/common_illumination/candle_a.cgf"
)
local CANDLE_GROUND_OFFSET = tonumber(candleConfig.GroundOffset) or 0.02

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

local function getInventory(entity)
    if not entity then
        return nil
    end

    if entity.inventory then
        return entity.inventory
    end

    if entity.GetInventory then
        local ok, inventory = pcall(entity.GetInventory, entity)
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

local function distanceBetween(first, second)
    if not first or not second then
        return nil
    end

    local x = (tonumber(first.x) or 0) - (tonumber(second.x) or 0)
    local y = (tonumber(first.y) or 0) - (tonumber(second.y) or 0)
    local z = (tonumber(first.z) or 0) - (tonumber(second.z) or 0)

    return math.sqrt(x * x + y * y + z * z)
end

local function formatDistance(distance)
    if distance == nil then
        return "nil"
    end

    return string.format("%.3f", distance)
end

local function getEntityWorldPosition(entity)
    if entity and entity.GetWorldPos then
        local ok, position = pcall(entity.GetWorldPos, entity)
        if ok then
            return position
        end
    end

    return nil
end

local function spawnVisualAnchor(
    name,
    position,
    angleZ,
    modelPath,
    label,
    diagnostics
)
    local params = {
        class = FUNCTIONAL_VISUAL_CLASS,
        name = name,
        position = Placement.CopyPosition(position),

        properties = {
            Position = Placement.CopyPosition(position),

            Angles = {
                x = 0,
                y = 0,
                z = angleZ,
            },

            object_Model = modelPath,

            bSaved_by_game = 1,
            bSerialize = 1,
        },
    }

    if diagnostics then
        functionalLog(
            tostring(label)
            .. " spawn request bedPosition="
            .. formatVector(diagnostics.bedPosition)
            .. " offsetRight="
            .. string.format("%.2f", tonumber(diagnostics.right) or 0)
            .. " offsetForward="
            .. string.format("%.2f", tonumber(diagnostics.forward) or 0)
            .. " offsetZ="
            .. string.format("%.2f", tonumber(diagnostics.z) or 0)
            .. " angleZ="
            .. string.format("%.4f", tonumber(angleZ) or 0)
            .. " spawnPosition="
            .. formatVector(position)
            .. " bedToSpawnDistance="
            .. formatDistance(distanceBetween(diagnostics.bedPosition, position))
        )
    end

    local spawnOk, anchorOrError = pcall(System.SpawnEntity, params)

    if not spawnOk then
        functionalLog(
            tostring(label)
            .. " spawn raised an error: "
            .. tostring(anchorOrError)
        )

        return nil
    end

    local anchor = anchorOrError

    if diagnostics then
        local worldPosition = getEntityWorldPosition(anchor)
        local propertiesPosition = anchor
            and anchor.Properties
            and anchor.Properties.Position
            or nil

        functionalLog(
            tostring(label)
            .. " spawn result requestedSpawnPosition="
            .. formatVector(position)
            .. " anchorWorldPos="
            .. formatVector(worldPosition)
            .. " anchorPropertiesPosition="
            .. formatVector(propertiesPosition)
            .. " requestedToWorldDistance="
            .. formatDistance(distanceBetween(position, worldPosition))
        )
    end

    if not anchor or not anchor.id then
        functionalLog(tostring(label) .. " spawn failed: no entity returned")
        if anchor then
            functionalDeleteEntity(anchor, tostring(label) .. " partial")
        end

        return nil
    end

    if anchor.SetAngles then
        local angleOk, angleError = pcall(
            anchor.SetAngles,
            anchor,
            {
                x = 0,
                y = 0,
                z = angleZ,
            }
        )

        if not angleOk then
            functionalLog(
                tostring(label)
                .. " angle setup failed: "
                .. tostring(angleError)
            )
            functionalDeleteEntity(anchor, tostring(label) .. " partial")
            return nil
        end
    end

    return anchor
end

local function spawnCandleProbe(bedPosition, angleZ)
    if not (Placement and Placement.OffsetFromHeading) then
        functionalLog("candle prop skipped: Placement.OffsetFromHeading unavailable")
        return nil
    end

    local desiredPosition = Placement.OffsetFromHeading(
        bedPosition,
        angleZ,
        candleOffset.right,
        candleOffset.forward,
        candleOffset.z
    )

    if not desiredPosition then
        functionalLog("candle prop skipped: offset calculation failed")
        return nil
    end

    if not (Placement and Placement.GetGroundedPosition) then
        functionalLog("candle prop skipped: Placement.GetGroundedPosition unavailable")
        return nil
    end

    local candlePosition, groundHit = Placement.GetGroundedPosition(
        desiredPosition,
        CANDLE_GROUND_OFFSET
    )

    if not candlePosition then
        functionalLog(
            "candle prop skipped: grounding failed desiredPos="
            .. formatVector(desiredPosition)
        )
        return nil
    end

    functionalLog(
        "candle desiredPos="
        .. formatVector(desiredPosition)
        .. " groundedPos="
        .. formatVector(candlePosition)
        .. " groundHit="
        .. formatVector(groundHit)
    )

    local candleAnchor = spawnVisualAnchor(
        CANDLE_PROP_NAME,
        candlePosition,
        angleZ,
        CANDLE_MODEL_PATH,
        "candle prop",
        {
            bedPosition = bedPosition,
            right = candleOffset.right,
            forward = candleOffset.forward,
            z = candleOffset.z,
        }
    )

    if not candleAnchor then
        functionalLog("candle prop optional spawn failed; continuing deployment")
        return nil
    end

    functionalLog(
        "candle prop spawned id="
        .. tostring(candleAnchor.id)
        .. " pos="
        .. formatVector(candlePosition)
        .. " heading="
        .. string.format("%.4f", angleZ)
        .. " modelPath="
        .. CANDLE_MODEL_PATH
    )

    return candleAnchor
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

    if SBR.FunctionalTest.candleAnchor then
        if not deleteOnce(
            SBR.FunctionalTest.candleAnchor,
            "tracked candle prop"
        ) then
            success = false
        end
    end

    SBR.FunctionalTest.trigger = nil
    SBR.FunctionalTest.bed = nil
    SBR.FunctionalTest.visualAnchor = nil
    SBR.FunctionalTest.candleAnchor = nil
    SBR.FunctionalTest.modelPath = nil
    SBR.FunctionalTest.returnItemOnPack = false
    SBR.FunctionalTest.beddingRequiredOnPack = false
    SBR.FunctionalTest.beddingClassId = nil

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
            and (
                anchor:GetName() == FUNCTIONAL_VISUAL_NAME
                or anchor:GetName() == CANDLE_PROP_NAME
            ) then

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

function SimpleBedRoll.SpawnFunctionalTestBed(position, angleZ)
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

    local bedPosition = nil

    if position then
        bedPosition = Placement.CopyPosition(position)
        angleZ = tonumber(angleZ) or Placement.GetPlayerHeading(playerEntity)
    else
        bedPosition, angleZ = Placement.GetBedPlacement(playerEntity)
    end

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
    SBR.FunctionalTest.returnItemOnPack = false
    SBR.FunctionalTest.beddingRequiredOnPack = false
    SBR.FunctionalTest.beddingClassId = nil

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

    SBR.FunctionalTest.candleAnchor = spawnCandleProbe(bedPosition, angleZ)

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

function SimpleBedRoll.MarkReturnItemOnPack(value)
    SBR.FunctionalTest.returnItemOnPack = value == true
    return SBR.FunctionalTest.returnItemOnPack
end

function SimpleBedRoll.ShouldReturnItemOnPack()
    return SBR.FunctionalTest.returnItemOnPack == true
end

function SimpleBedRoll.MarkBeddingRequiredOnPack(classId)
    SBR.FunctionalTest.beddingRequiredOnPack = true
    SBR.FunctionalTest.beddingClassId = classId
    return true
end

function SimpleBedRoll.GetBeddingRequiredOnPack()
    return SBR.FunctionalTest.beddingRequiredOnPack == true,
        SBR.FunctionalTest.beddingClassId
end

function SimpleBedRoll.ReturnPackedBedrollItem(user)
    local inventory = getInventory(user) or getInventory(Placement.GetPlayer())

    if not inventory then
        functionalLog("return item failed: player inventory unavailable")
        return false
    end

    if not inventory.CreateItem then
        functionalLog("return item failed: inventory.CreateItem unavailable")
        return false
    end

    local before = getInventoryCount(inventory, BEDROLL_ITEM_CLASS_ID)
    local ok, result = pcall(
        inventory.CreateItem,
        inventory,
        BEDROLL_ITEM_CLASS_ID,
        1.0,
        1
    )

    if not ok then
        functionalLog("return item failed: CreateItem raised " .. tostring(result))
        return false
    end

    local after = getInventoryCount(inventory, BEDROLL_ITEM_CLASS_ID)
    local verified = before ~= nil and after ~= nil and after >= before + 1

    if Game and Game.ShowItemsTransfer then
        pcall(Game.ShowItemsTransfer, BEDROLL_ITEM_CLASS_ID, 1)
    end

    functionalLog(
        "returned packed bedroll item classId="
        .. BEDROLL_ITEM_CLASS_ID
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

function SimpleBedRoll.RemoveFunctionalTestBed()
    local hadTrackedEntities =
        SBR.FunctionalTest.bed ~= nil
        or SBR.FunctionalTest.trigger ~= nil
        or SBR.FunctionalTest.visualAnchor ~= nil
        or SBR.FunctionalTest.candleAnchor ~= nil

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
    local candleAnchor = SBR.FunctionalTest.candleAnchor

    local bedExists = functionalEntityExists(bed)
    local triggerExists = functionalEntityExists(trigger)
    local visualExists = functionalEntityExists(visualAnchor)
    local candleExists = functionalEntityExists(candleAnchor)

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
        .. " candleTracked="
        .. tostring(candleAnchor ~= nil)
        .. " candleExists="
        .. tostring(candleExists)
        .. " candleId="
        .. tostring(candleAnchor and candleAnchor.id or nil)
        .. " modelPath="
        .. tostring(SBR.FunctionalTest.modelPath)
    )

    return bedExists and triggerExists and visualExists
end
