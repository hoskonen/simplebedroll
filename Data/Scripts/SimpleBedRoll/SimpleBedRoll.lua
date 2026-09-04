-- Composition root and stable public SimpleBedRoll table.

Script.ReloadScript("Scripts/SimpleBedRoll/Config.lua")

SimpleBedRoll = SimpleBedRoll or {}

Script.ReloadScript("Scripts/SimpleBedRoll/Time.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/Placement.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/Environment.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/Bedding.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/BedTrigger.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/CampLight.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/Deployment.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/WorldItem.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/DevTools.lua")

function SimpleBedRoll.OnGameplayStarted()
    System.LogAlways("[SimpleBedRoll] Initialized")

    if SimpleBedRoll.WorldItem
        and type(SimpleBedRoll.WorldItem.EnsureHooks) == "function" then

        SimpleBedRoll.WorldItem.EnsureHooks()
    end
end
