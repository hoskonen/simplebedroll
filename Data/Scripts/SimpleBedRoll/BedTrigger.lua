-- Bedroll-specific behavior attached to one native BedTrigger instance.

SimpleBedRoll = SimpleBedRoll or {}

local SBR = SimpleBedRoll

SBR.BedTrigger = SBR.BedTrigger or {}

local BedTriggerBehavior = SBR.BedTrigger

local function log(message)
    System.LogAlways(
        "[SimpleBedRoll/BedTrigger] " .. tostring(message)
    )
end

function BedTriggerBehavior.ReportUse(self, user, items, action)
    if action == self.Properties.Hold then
        log(
            "Pack requested user="
            .. tostring(user and user:GetName() or nil)
        )

        if SBR.RemoveFunctionalTestBed then
            SBR.RemoveFunctionalTestBed()
        else
            log("Pack failed: deployment module unavailable")
        end

        return
    end

    -- Preserve native sleep validation and stance behavior for Click.
    BedTrigger.ReportUse(self, user, items, action)
end

function BedTriggerBehavior.Attach(trigger)
    if not trigger then
        log("Attach failed: trigger missing")
        return false
    end

    local attached, attachError = pcall(
        function()
            trigger.ReportUse = BedTriggerBehavior.ReportUse
        end
    )

    if not attached then
        log("Attach failed: " .. tostring(attachError))
        return false
    end

    if trigger.ReportUse ~= BedTriggerBehavior.ReportUse then
        log("Attach failed: instance handler was not retained")
        return false
    end

    log("attached to native trigger id=" .. tostring(trigger.id))
    return true
end
