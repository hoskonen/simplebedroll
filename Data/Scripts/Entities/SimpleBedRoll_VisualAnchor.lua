-- Invisible parent entity for the visible bedroll prefab.

Script.ReloadScript("Scripts/Entities/EntityCommon.lua")

SimpleBedRoll_VisualAnchor = {
    Properties = {
        Angles = {
            x = 0,
            y = 0,
            z = 0,
        },

        Position = {},

        object_Model = "",
        sPrefabID = "",

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
    },

    Client = {},
    Server = {},

    Editor = {
        Icon = "physicsobject.bmp",
        IconOnTop = 1,
    },
}

EntityCommon.Derive(SimpleBedRoll_VisualAnchor, BasicEntity)

local function normalizeModelPath(modelPath)
    local text = tostring(modelPath or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.gsub(text, "\\", "/")
    text = string.gsub(text, "^Data/", "")
    text = string.gsub(text, "^Objects/", "objects/")

    return text
end

function SimpleBedRoll_VisualAnchor:SetupModel()
    self.Properties.object_Model = normalizeModelPath(
        self.Properties.object_Model
    )

    BasicEntity.SetupModel(self)
end

function SimpleBedRoll_VisualAnchor:OnSpawn()
    BasicEntity.OnSpawn(self)

    self:SetFromProperties()
    self:SetViewDistUnlimited()
    self:RenderShadow(true)
end

function SimpleBedRoll_VisualAnchor:OnSave(saveTable)
    BasicEntity.OnSave(self, saveTable)

    saveTable.object_Model = self.Properties.object_Model
    saveTable.Position = self:GetWorldPos()
    saveTable.Angles = self:GetAngles()
    saveTable.sPrefabID = self.Properties.sPrefabID
end

function SimpleBedRoll_VisualAnchor:OnLoad(saveTable)
    BasicEntity.OnLoad(self, saveTable)

    if saveTable.object_Model then
        self.Properties.object_Model = saveTable.object_Model
    end

    if saveTable.Position then
        self.Properties.Position = saveTable.Position
        self:SetPos(saveTable.Position)
    end

    if saveTable.Angles then
        self.Properties.Angles = saveTable.Angles
        self:SetAngles(saveTable.Angles)
    end

    if saveTable.sPrefabID then
        self.Properties.sPrefabID = saveTable.sPrefabID
    end

    self:SetupModel()
    self:SetViewDistUnlimited()
    self:RenderShadow(true)
end
