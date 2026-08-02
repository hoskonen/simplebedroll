-- Composition root and stable public SimpleBedRoll table.

Script.ReloadScript("Scripts/SimpleBedRoll/Config.lua")

SimpleBedRoll = SimpleBedRoll or {}

Script.ReloadScript("Scripts/SimpleBedRoll/Placement.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/BedTrigger.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/Deployment.lua")
Script.ReloadScript("Scripts/SimpleBedRoll/DevTools.lua")

function SimpleBedRoll.OnGameplayStarted()
    System.LogAlways("[SimpleBedRoll] Initialized")
end
