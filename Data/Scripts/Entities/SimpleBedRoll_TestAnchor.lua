Script.ReloadScript("Scripts/Entities/EntityCommon.lua")

SimpleBedRoll_TestAnchor = {
    Properties = {
        object_Model = "",

        Physics = {
            bPhysicalize = false,
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
}

EntityCommon.Derive(SimpleBedRoll_TestAnchor, BasicEntity)

function SimpleBedRoll_TestAnchor:OnSpawn()
    BasicEntity.OnSpawn(self)

    -- Do not hide the anchor. The anchor has no model, and hiding it may also
    -- hide or suppress prefab objects attached beneath it.
end