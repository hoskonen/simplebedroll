System.LogAlways("[SimpleBedRoll] loading")

Script.ReloadScript("Scripts/SimpleBedRoll/SimpleBedRoll.lua")

if UIAction and UIAction.RegisterEventSystemListener
    and not SimpleBedRoll._gameplayListenerBound then

    UIAction.RegisterEventSystemListener(
        SimpleBedRoll,
        "System",
        "OnGameplayStarted",
        "OnGameplayStarted"
    )

    SimpleBedRoll._gameplayListenerBound = true
end