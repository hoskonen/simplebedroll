-- SimpleBedRoll_BedEntity.lua
-- Functional bed entity used by Simple Bedroll.

Script.ReloadScript("Scripts/Entities/EntityCommon.lua")

SimpleBedRoll_BedEntity = {
    Properties = {
        Angles = {
            x = 0,
            y = 0,
            z = 0,
        },

        Position = {},

        soclasses_SmartObjectClass = "",

        bMissionCritical = false,
        bCanTriggerAreas = false,

        -- The functional entity is intentionally model-less for the first test.
        object_Model = "",

        bSaved_by_game = true,
        bSerialize = true,

        Physics = {
            bPhysicalize = true,
            bRigidBody = false,
            bPushableByPlayers = false,
            Density = -1,
            Mass = -1,
        },

        MultiplayerOptions = {
            bNetworked = false,
        },

        bExcludeCover = false,

        guidSmartObjectType = "425d4fdf-8dcd-4a2b-fdc5-cbb1b5d25b89",
        soclass_SmartObjectHelpers = "Bed_1Place_Low",

        bInteractiveCollisionClass = true,
        sWH_AI_EntityCategory = "Bed",
        sSittingTagGlobal = "sittingNoTable",

        fUsabilityDistance = 1.25,

        HiddenInGame = true,
        viewDistRatio = 0.0,

        Script = {
            Misc = "",
            esBedTypes = "GroundBed",
        },

        Bed = {
            esSleepQuality = "low",
            esReadingQuality = "bed_ground",
        },

        esFaction = "",
    },

    Client = {},
    Server = {},

    Editor = {
        Icon = "physicsobject.bmp",
        IconOnTop = 1,
    },
}

EntityCommon.Derive(SimpleBedRoll_BedEntity, BasicEntity)

local function log(message)
    System.LogAlways(
        "[SimpleBedRoll/BedEntity] " .. tostring(message)
    )
end

function SimpleBedRoll_BedEntity:OnSpawn()
    log("OnSpawn id=" .. tostring(self.id))

    BasicEntity.OnSpawn(self)

    self:SetFromProperties()
    self:SetAngles(self.Properties.Angles)
    self:SetPos(self.Properties.Position)
end

function SimpleBedRoll_BedEntity:OnSave(saveTable)
    log("OnSave id=" .. tostring(self.id))

    BasicEntity.OnSave(self, saveTable)

    saveTable.object_Model = self.Properties.object_Model
    saveTable.Position = self.Properties.Position
    saveTable.Angles = self:GetAngles()
end

function SimpleBedRoll_BedEntity:OnLoad(saveTable)
    BasicEntity.OnLoad(self, saveTable)

    if saveTable.object_Model then
        self.Properties.object_Model = saveTable.object_Model
    else
        log("OnLoad warning: no model")
    end

    if saveTable.Position then
        self.Properties.Position = saveTable.Position
    else
        log("OnLoad warning: no position")
    end

    if saveTable.Angles then
        self.Properties.Angles = saveTable.Angles
        self:SetAngles(self.Properties.Angles)
    else
        log("OnLoad warning: no angles")
    end

    self:SetupModel()
end

function SimpleBedRoll_BedEntity:GetSleepQuality()
    local quality = self.Properties.Bed.esSleepQuality

    if quality == "low" then
        return 2
    elseif quality == "medium" then
        return 3
    elseif quality == "high" then
        return 1
    elseif quality == "exceptional" then
        return 0
    end

    return 2
end

function SimpleBedRoll_BedEntity:GetReadingQuality()
    local quality = self.Properties.Bed.esReadingQuality

    if quality == "none" then
        return 0
    elseif quality == "bed_ground" then
        return 1
    elseif quality == "bed" then
        return 3
    elseif quality == "bed_exceptional" then
        return 4
    elseif quality == "bench_table" then
        return 5
    elseif quality == "bench_notable" then
        return 6
    end

    return 0
end

function SimpleBedRoll_BedEntity:IsUsableByPlayer(user)
    if not user then
        return false
    end

    local userPosition = g_Vectors.temp_v1
    local bedPosition = g_Vectors.temp_v2

    user:GetWorldPos(userPosition)
    self:GetWorldPos(bedPosition)

    local difference = VectorUtils.Subtract(
        bedPosition,
        userPosition
    )

    local distance = VectorUtils.Length(difference)

    return distance <= self.Properties.fUsabilityDistance
end

function SimpleBedRoll_BedEntity:OnUsed(user)
    log(
        "OnUsed user="
        .. tostring(user and user:GetName() or nil)
    )

    if not user then
        return
    end

    local bedType = self.Properties.Script.esBedTypes

    local canUse =
        bedType == "normal"
        or bedType == "bench"
        or (
            user.player
            and user.player.CanSleepAndReportProblem
            and user.player.CanSleepAndReportProblem()
        )

    if not canUse then
        log("OnUsed rejected by CanSleepAndReportProblem")
        return
    end

    XGenAIModule.SendMessageToEntity(
        player.this.id,
        "player:request",
        "target("
            .. Framework.WUIDToMsg(
                XGenAIModule.GetMyWUID(self)
            )
            .. "), mode ('use')"
    )
end

function SimpleBedRoll_BedEntity:Event_Remove()
    self:DrawSlot(0, 0)
    self:DestroyPhysics()
    self:ActivateOutput("Remove", true)
end

SimpleBedRoll_BedEntity.FlowEvents = {
    Inputs = {
        Hide = {
            SimpleBedRoll_BedEntity.Event_Hide,
            "bool",
        },
        UnHide = {
            SimpleBedRoll_BedEntity.Event_UnHide,
            "bool",
        },
        Remove = {
            SimpleBedRoll_BedEntity.Event_Remove,
            "bool",
        },
    },

    Outputs = {
        Hide = "bool",
        UnHide = "bool",
        Remove = "bool",
        Break = "int",
    },
}

-- Preserve DJB's complete baseline for the first functional test.
EntityCommon.MakeUsable(SimpleBedRoll_BedEntity)
EntityCommon.MakePickable(SimpleBedRoll_BedEntity)
EntityCommon.AddHeavyObjectProperty(SimpleBedRoll_BedEntity)
EntityCommon.AddInteractLargeObjectProperty(SimpleBedRoll_BedEntity)
EntityCommon.SetupCollisionFiltering(SimpleBedRoll_BedEntity)