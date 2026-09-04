-- Standalone hold trigger for SimpleBedRoll camp-level controls.

Script.ReloadScript("Scripts/Entities/EntityCommon.lua")

SimpleBedRoll_CampControlTrigger = {
    Properties = {
        object_Model = "objects/special/primitive_cylinder.cgf",
        InteractorPriorityOverride = -1,
        interactionTrigger = "",

        Hold = {
            bIsActive = true,
            UseMessage = "@ui_pickup_item",

            bIsActiveWhileCarryingCorpse = false,
            bIsActiveInCombat = false,
            bIsActiveInTenseCircumstance = false,

            fActiveDistance = -1,
            fActiveMinDistance = -1,
            fZToleration = -1,
        },

        Physics = {
            bPhysicalize = true,
            bRigidBody = false,
            Density = -1,
            Mass = -1,
        },

        bSaved_by_game = true,
        bSerialize = true,
    },

    Client = {},
    Server = {},

    Editor = {
        Icon = "Trigger.bmp",
        IconOnTop = 1,
    },

    InteractorPriority = 4,
    interactionTrigger = "",
}

EntityCommon.Derive(SimpleBedRoll_CampControlTrigger, BasicEntity)

local function log(message)
    System.LogAlways(
        "[SimpleBedRoll/CampControlTrigger] " .. tostring(message)
    )
end

local function getConfiguredPackHint()
    if SimpleBedRoll_Config
        and SimpleBedRoll_Config.Trigger
        and SimpleBedRoll_Config.Trigger.PackHint then

        return tostring(SimpleBedRoll_Config.Trigger.PackHint)
    end

    return "@ui_pickup_item"
end

function SimpleBedRoll_CampControlTrigger:UpdateMaterial(gameMode)
    local cvarValue = 0

    if System and System.GetCVar then
        cvarValue = tonumber(System.GetCVar("wh_ent_ShowHelperObjects")) or 0
    end

    local showInEditMode = cvarValue > 0
    local showInGameAndGameMode = cvarValue > 1

    if ((System.IsEditor and System.IsEditor() and showInEditMode and not gameMode)
        or showInGameAndGameMode) then

        self:SetMaterial("objects/intermediates/poses/poses_nomultimaterial")
    else
        self:SetMaterial("materials/special/nodraw")
    end
end

function SimpleBedRoll_CampControlTrigger:PhysicalizeThis()
    local physics = self.Properties.Physics or {
        bPhysicalize = true,
        bRigidBody = false,
        Density = -1,
        Mass = -1,
    }

    EntityCommon.PhysicalizeRigid(self, 0, physics, self.bRigidBodyActive)
end

function SimpleBedRoll_CampControlTrigger:OnReset()
    local properties = self.Properties

    self:LoadObject(0, properties.object_Model)
    self:UpdateMaterial(false)

    if self.interactionTrigger and self.interactionTrigger.SetPriority then
        if properties.InteractorPriorityOverride
            and properties.InteractorPriorityOverride >= 0 then

            self.interactionTrigger:SetPriority(
                properties.InteractorPriorityOverride
            )
        else
            self.interactionTrigger:SetPriority(self.InteractorPriority)
        end
    end

    self:PhysicalizeThis()

    if self.SetPhysicParams then
        local flags = { flags_mask = geom_collides }
        self:SetPhysicParams(PHYSICPARAM_FLAGS, flags)
        self:SetPhysicParams(PHYSICPARAM_PART_FLAGS, flags)
        self:SetPhysicParams(
            PHYSICPARAM_COLLISION_CLASS,
            { collisionClassIgnore = -1 }
        )
    end

    self.Runtime = {
        HoldAvailable = properties.Hold.bIsActive,
        HoldMessage = getConfiguredPackHint(),
    }

    properties.Hold.UseMessage = self.Runtime.HoldMessage

    log(
        "OnReset id="
        .. tostring(self.id)
        .. " holdAvailable="
        .. tostring(self.Runtime.HoldAvailable)
        .. " holdMessage="
        .. tostring(self.Runtime.HoldMessage)
    )
end

function SimpleBedRoll_CampControlTrigger:OnSpawn()
    BasicEntity.OnSpawn(self)
    self:SetFromProperties()
    self:OnReset()

    log("OnSpawn id=" .. tostring(self.id))
end

function SimpleBedRoll_CampControlTrigger:OnPropertyChange()
    self:OnReset()
end

function SimpleBedRoll_CampControlTrigger:OnEditorSetGameMode(gameMode)
    self:UpdateMaterial(gameMode)
end

function SimpleBedRoll_CampControlTrigger:OnLoad(saveTable)
    BasicEntity.OnLoad(self, saveTable)

    if saveTable and saveTable.Runtime then
        self.Runtime = saveTable.Runtime
    else
        self.Runtime = {
            HoldAvailable = self.Properties.Hold.bIsActive,
            HoldMessage = getConfiguredPackHint(),
        }
    end

    self.Properties.Hold.UseMessage = self.Runtime.HoldMessage
    self:UpdateMaterial(false)
end

function SimpleBedRoll_CampControlTrigger:OnSave(saveTable)
    BasicEntity.OnSave(self, saveTable)
    saveTable.Runtime = self.Runtime
end

function SimpleBedRoll_CampControlTrigger:NeedSerialize()
    if not self.Runtime then
        return false
    end

    return self.Runtime.HoldAvailable ~= self.Properties.Hold.bIsActive
        or self.Runtime.HoldMessage ~= getConfiguredPackHint()
end

function SimpleBedRoll_CampControlTrigger:IsEnabledByProperties(user)
    if not user then
        return false, nil
    end

    local hold = self.Properties.Hold

    if not hold.bIsActiveWhileCarryingCorpse
        and user.actor
        and user.actor.IsCarryingCorpse
        and user.actor:IsCarryingCorpse() then

        return false, "@ui_playerCantGeneral_corpseCarry"
    end

    if user.soul then
        local inCombat = user.soul.IsInCombatDanger
            and user.soul:IsInCombatDanger()
        local inCrime = user.soul.HasScriptContext
            and user.soul:HasScriptContext(
                "crime_escalationLevel_script_confrontingGeneral_player"
            )

        if not hold.bIsActiveInCombat and (inCombat or inCrime) then
            return false, "@ui_playerCantGeneral_combat"
        end

        if not hold.bIsActiveInTenseCircumstance
            and user.soul.IsInTenseCircumstance
            and user.soul:IsInTenseCircumstance() then

            return false, "@ui_playerCantGeneral_tense"
        end
    end

    return true, nil
end

function SimpleBedRoll_CampControlTrigger:IsActionAvailable(user)
    if not user then
        return false
    end

    local hold = self.Properties.Hold

    if hold.fActiveDistance ~= -1
        and VectorUtils
        and VectorUtils.Distance
        and player
        and player.GetWorldPos
        and self.GetWorldPos
        and VectorUtils.Distance(self:GetWorldPos(), player:GetWorldPos())
            > hold.fActiveDistance then

        return false
    end

    if hold.fActiveMinDistance ~= -1
        and VectorUtils
        and VectorUtils.Distance
        and player
        and player.GetWorldPos
        and self.GetWorldPos
        and VectorUtils.Distance(self:GetWorldPos(), player:GetWorldPos())
            < hold.fActiveMinDistance then

        return false
    end

    if hold.fZToleration ~= -1
        and VectorUtils
        and VectorUtils.Subtract
        and player
        and player.GetWorldPos
        and self.GetWorldPos
        and math.abs(
            VectorUtils.Subtract(self:GetWorldPos(), player:GetWorldPos()).z
        ) > hold.fZToleration then

        return false
    end

    return true
end

function SimpleBedRoll_CampControlTrigger:IsUsableHold(user)
    return self.Runtime
        and self.Runtime.HoldAvailable
        and self.Runtime.HoldMessage ~= ""
        and self:IsActionAvailable(user)
end

function SimpleBedRoll_CampControlTrigger:IsEnabledHold(user)
    return self:IsEnabledByProperties(user)
end

function SimpleBedRoll_CampControlTrigger:GetHintHold(user)
    if not self.Runtime then
        return getConfiguredPackHint()
    end

    return self.Runtime.HoldMessage
end

function SimpleBedRoll_CampControlTrigger:GetActions(user, firstFast)
    local output = {}

    if self:IsUsableHold(user) then
        local isEnabled, disabledReason = self:IsEnabledHold(user)

        if not self._holdAvailabilityLogged then
            log(
                "hold action available id="
                .. tostring(self.id)
                .. " user="
                .. tostring(user and user:GetName() or nil)
                .. " enabled="
                .. tostring(isEnabled)
            )

            self._holdAvailabilityLogged = true
        end

        local holdAction = Action()
            :hint(self:GetHintHold(user))
            :action("trigger_use_hold")
            :func(SimpleBedRoll_CampControlTrigger.OnUsedHold)
            :interaction(inr_scriptTrigger)
            :hintType(AHT_HOLD)
            :enabled(isEnabled)
            :reason(disabledReason)

        if AddInteractorAction(output, firstFast, holdAction) then

            return output
        end
    end

    return output
end

function SimpleBedRoll_CampControlTrigger:OnUsedHold(user)
    log(
        "Pack hold callback selected id="
        .. tostring(self.id)
        .. " user="
        .. tostring(user and user:GetName() or nil)
    )

    local packed = false

    if SimpleBedRoll and SimpleBedRoll.PackCamp then
        packed = SimpleBedRoll.PackCamp(user, "CampControlTrigger")
    else
        log("Pack failed: SimpleBedRoll.PackCamp unavailable")
    end

    if self.interactionTrigger then
        if packed and self.interactionTrigger.SetHeld then
            self.interactionTrigger:SetHeld()
        elseif not packed and self.interactionTrigger.SetPressed then
            self.interactionTrigger:SetPressed()
        end
    end

    log("Pack hold callback result=" .. tostring(packed))

    return packed
end

function SimpleBedRoll_CampControlTrigger:SetAvailableHold(available)
    self.Runtime = self.Runtime or {}
    self.Runtime.HoldAvailable = available == true
end

function SimpleBedRoll_CampControlTrigger:SetHoldMessage(message)
    self.Runtime = self.Runtime or {}
    self.Runtime.HoldMessage = tostring(message or "")
end

function SimpleBedRoll_CampControlTrigger:ResetHoldMessage()
    self:SetHoldMessage(getConfiguredPackHint())
end

SimpleBedRoll_CampControlTrigger.FlowEvents = {
    Inputs = {
        Hide = { SimpleBedRoll_CampControlTrigger.Event_Hide, "bool" },
        UnHide = { SimpleBedRoll_CampControlTrigger.Event_UnHide, "bool" },
        Remove = { SimpleBedRoll_CampControlTrigger.Event_Remove, "bool" },
    },
    Outputs = {
        Hide = "bool",
        UnHide = "bool",
        Remove = "bool",
        Break = "int",
    },
}
