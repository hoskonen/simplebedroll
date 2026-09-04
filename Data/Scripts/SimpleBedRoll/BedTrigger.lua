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

function SimpleBedRoll.PackCamp(user, source)
    source = source or "unknown"

    if SBR.RemoveFunctionalTestBed then
        local shouldReturnItem = SBR.ShouldReturnItemOnPack
            and SBR.ShouldReturnItemOnPack()
        local shouldConsumeBedding, beddingClassId = false, nil

        if SBR.GetBeddingRequiredOnPack then
            shouldConsumeBedding, beddingClassId =
                SBR.GetBeddingRequiredOnPack()
        end

        local removed = SBR.RemoveFunctionalTestBed()

        if removed
            and shouldReturnItem
            and SBR.ReturnPackedBedrollItem then

            SBR.ReturnPackedBedrollItem(user)
        end

        if removed and shouldConsumeBedding then
            if SBR.Bedding and SBR.Bedding.ConsumeRequiredBedding then
                local consumed, consumeResult =
                    SBR.Bedding.ConsumeRequiredBedding(user)

                if not consumed then
                    log(
                        "bedding consume skipped after pack source="
                        .. tostring(source)
                        .. " classId="
                        .. tostring(beddingClassId)
                        .. " reason="
                        .. tostring(consumeResult)
                    )
                end
            else
                log("bedding consume skipped: Bedding module unavailable")
            end
        end

        log(
            "Pack completed source="
            .. tostring(source)
            .. " removed="
            .. tostring(removed)
        )

        return removed
    end

    log("Pack failed: deployment module unavailable source=" .. tostring(source))
    return false
end

function BedTriggerBehavior.ReportUse(self, user, items, action)
    if action == self.Properties.Hold then
        log(
            "Pack requested user="
            .. tostring(user and user:GetName() or nil)
        )

        SimpleBedRoll.PackCamp(user, "BedTrigger")

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
