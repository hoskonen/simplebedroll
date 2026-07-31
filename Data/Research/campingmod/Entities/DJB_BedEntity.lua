-- DJB_BedEntity.lua
-- Persistent bed entity for DJB_Camping mod

DJB_BedEntity = {
    Properties = {
        Angles = { x = 0, y = 0, z = 0},
        Position = {},
        soclasses_SmartObjectClass = "",
        bMissionCritical = false,
        bCanTriggerAreas = false,
        object_Model = "", -- Will be set at runtime
        bSaved_by_game = true, -- Critical for persistence
        bSerialize = true,     -- Critical for persistence
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
        HiddenInGame= true,
        viewDistRatio = 0.0,
        Script = {
            Misc = '',
            esBedTypes = 'GroundBed',
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

-- =============================================================================
-- Derive from BasicEntity
EntityCommon.Derive(DJB_BedEntity, BasicEntity)

-- =============================================================================
-- Override OnSpawn to handle custom initialization
function DJB_BedEntity:OnSpawn()
    System.LogAlways("DJB_BedEntity: OnSpawn")
    
    -- First call the parent's OnSpawn for basic initialization
    BasicEntity.OnSpawn(self)
    
    -- Then do our custom setup
    self:SetFromProperties()

    self:SetAngles(self.Properties.Angles)
    self:SetPos(self.Properties.Position)
end

-- =============================================================================
-- Override OnSave to store our custom properties
function DJB_BedEntity:OnSave(table)
    System.LogAlways("DJB_BedEntity: OnSave")
    
    -- First call the parent's OnSave
    BasicEntity.OnSave(self, table)
    
    -- Save our custom properties
    table.object_Model = self.Properties.object_Model
    table.Position = self.Properties.Position

    local angles = self:GetAngles()
    table.Angles = angles
    --System.LogAlways("DJB_BedEntity: Saved angles x=" .. angles.x .. ", y=" .. angles.y .. ", z=" .. angles.z)
end

-- =============================================================================
-- Override OnLoad to restore our custom properties
function DJB_BedEntity:OnLoad(table)
    --System.LogAlways("DJB_BedEntity: OnLoad")

    -- First call the parent's OnLoad
    BasicEntity.OnLoad(self, table)

    -- Restore our custom properties
    if table.object_Model then
        self.Properties.object_Model = table.object_Model
        --System.LogAlways("DJB_BedEntity: Loaded with model " .. table.object_Model)
    else
        System.LogAlways("DJB_BedEntity: Warning - No model")
    end
    if table.Position then 
        self.Properties.Position = table.Position
        --System.LogAlways("DJB_BedEntity: Loaded with position: " .. self.Properties.Position)
    else 
        System.LogAlways("DJB_BedEntity: Warning - No Position")
    end
    if table.Angles then 
        self.Properties.Angles = table.Angles
        self:SetAngles(self.Properties.Angles)
        --System.LogAlways("DJB_BedEntity: Loaded with angles x=" .. self.Properties.Angles.x .. ", y=" .. self.Properties.Angles.y .. ", z=" .. self.Properties.Angles.z)
        --local angles = self:GetAngles()
        --System.LogAlways("DJB_BedEntity: Actual angles x=" .. angles.x .. ", y=" .. angles.y .. ", z=" .. angles.z)
    else 
        System.LogAlways("DJB_BedEntity: Warning - No Angles")
    end
    -- Re-setup the model
    self:SetupModel()
end

-- =============================================================================
function DJB_BedEntity:GetSleepQuality()
    local str = self.Properties.Bed.esSleepQuality

    if str == "low" then
        return 2
    elseif str == "medium" then
        return 3
    elseif str == "high" then
        return 1
    elseif str == "exceptional" then
        return 0
    else
        return 2
    end
end

-- =============================================================================
function DJB_BedEntity:GetReadingQuality()
    local str = self.Properties.Bed.esReadingQuality

    if str == "none" then
        return 0
    elseif str == "bed_ground" then
        return 1
    elseif str == "bed" then
        return 3
    elseif str == "bed_exceptional" then
        return 4
    elseif str == "bench_table" then
        return 5
    elseif str == "bench_notable" then
        return 6
    else
        return 0
    end
end


-- =============================================================================
function DJB_BedEntity:IsUsableByPlayer(user)
    local myDirection = g_Vectors.temp_v1
    local vecToPlayer = g_Vectors.temp_v2
    local myPos = g_Vectors.temp_v3

    myDirection = self:GetDirectionVector(0)

    user:GetWorldPos(vecToPlayer)
    self:GetWorldPos(myPos)

    vecToPlayer = VectorUtils.Subtract(myPos, vecToPlayer)
    local len = VectorUtils.Length(vecToPlayer)

    if(len <= self.Properties.fUsabilityDistance) then
        return true
    end
    return false
end

-- =============================================================================
function DJB_BedEntity:OnUsed(user)
    System.LogAlways("DJB_BedEntity:OnUsed called by " .. tostring(user:GetName()))
    
    if(self.Properties.Script.esBedTypes == 'normal' or self.Properties.Script.esBedTypes == 'bench' or (user.player and user.player.CanSleepAndReportProblem())) then
        XGenAIModule.SendMessageToEntity(player.this.id, "player:request", "target(" .. Framework.WUIDToMsg(XGenAIModule.GetMyWUID(self)) .. "), mode ('use')")
    end
end

-- =============================================================================
function DJB_BedEntity:Event_Remove()
    self:DrawSlot(0, 0)
    self:DestroyPhysics()
    self:ActivateOutput("Remove", true)
end

-- =============================================================================
DJB_BedEntity.FlowEvents = {
    Inputs = {
        Hide = {DJB_BedEntity.Event_Hide, "bool"},
        UnHide = {DJB_BedEntity.Event_UnHide, "bool"},
        Remove = {DJB_BedEntity.Event_Remove, "bool"},
    },
    Outputs = {
        Hide = "bool",
        UnHide = "bool",
        Remove = "bool",
        Break = "int",
    },
}

-- Make sure all helper functions are applied
EntityCommon.MakeUsable(DJB_BedEntity)
EntityCommon.MakePickable(DJB_BedEntity)
EntityCommon.AddHeavyObjectProperty(DJB_BedEntity)
EntityCommon.AddInteractLargeObjectProperty(DJB_BedEntity)
EntityCommon.SetupCollisionFiltering(DJB_BedEntity)