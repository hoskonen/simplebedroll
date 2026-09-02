-- World-item interaction adapter for the custom Simple Bedroll item.

SimpleBedRoll = SimpleBedRoll or {}
SimpleBedRoll.WorldItem = SimpleBedRoll.WorldItem or {}

local WorldItem = SimpleBedRoll.WorldItem

WorldItem.ItemClassId = "7f3f6a24-3b4d-4ec7-9a91-6d8e9f5a2c11"
WorldItem.ActionName = "simplebedroll_make_camp"
WorldItem.ActionHint = "@simplebedroll_ui_make_camp"
WorldItem.EnvironmentDeniedMessageKey = "@simplebedroll_ui_no_camp_site"
WorldItem.EnvironmentDeniedMessageText =
    "This is no place to make camp. I should find somewhere more secluded."
WorldItem.HookRetryMs = 500

local function log(message)
    System.LogAlways("[SimpleBedRoll/WorldItem] " .. tostring(message))
end

local function callMethod(obj, methodName, ...)
    if not (obj and type(obj[methodName]) == "function") then
        return false, nil
    end

    return pcall(obj[methodName], obj, ...)
end

local function lower(value)
    if value == nil then
        return nil
    end

    return string.lower(tostring(value))
end

local function formatVector(vector)
    if not vector then
        return "nil"
    end

    return string.format(
        "%.2f, %.2f, %.2f",
        tonumber(vector.x) or 0,
        tonumber(vector.y) or 0,
        tonumber(vector.z) or 0
    )
end

local function notifyEnvironmentDenied()
    local shown = false

    if Game and Game.SendInfoText then
        local ok = pcall(
            Game.SendInfoText,
            WorldItem.EnvironmentDeniedMessageKey,
            false,
            nil,
            5
        )
        shown = ok == true
    end

    log(
        "camp denied message: "
        .. WorldItem.EnvironmentDeniedMessageText
    )

    return shown
end

local function valueFromAnyKey(item, keys)
    if type(item) ~= "table" then
        return nil
    end

    for i = 1, #keys do
        local value = item[keys[i]]
        if value ~= nil then
            return value
        end
    end

    return nil
end

function WorldItem.GetRuntimeItemDetails(itemId)
    if not (itemId and ItemManager and ItemManager.GetItemEx) then
        return nil
    end

    local ok, itemEx = pcall(ItemManager.GetItemEx, itemId)
    if ok then
        return itemEx
    end

    return nil
end

function WorldItem.ResolveItem(entity)
    if not (entity and entity.item) then
        return nil, nil, nil, nil
    end

    local itemId = nil
    local ok, result = callMethod(entity.item, "GetId")
    if ok then
        itemId = result
    end

    local item = nil
    local classId = nil
    if itemId and ItemManager and ItemManager.GetItem then
        local itemOk, foundItem = pcall(ItemManager.GetItem, itemId)
        if itemOk and foundItem then
            item = foundItem
            classId = foundItem.class
        end
    end

    local itemEx = WorldItem.GetRuntimeItemDetails(itemId)
    if not classId then
        classId = valueFromAnyKey(itemEx, { "class", "className", "Class" })
    end

    return classId, itemId, item, itemEx
end

function WorldItem.IsSimpleBedroll(entity)
    local classId = WorldItem.ResolveItem(entity)
    return lower(classId) == lower(WorldItem.ItemClassId)
end

function WorldItem.OnMakeCamp(entity, user)
    local classId, itemId, item, itemEx = WorldItem.ResolveItem(entity)
    local position = nil

    if entity and entity.GetWorldPos then
        local ok, result = pcall(entity.GetWorldPos, entity)
        if ok then
            position = result
        end
    end

    local className = valueFromAnyKey(itemEx, { "className", "name", "Name" })
        or valueFromAnyKey(item, { "name", "Name" })

    if not className and classId and ItemManager and ItemManager.GetItemName then
        local ok, name = pcall(ItemManager.GetItemName, classId)
        if ok then
            className = name
        end
    end

    log(
        "Make camp selected: entityId="
        .. tostring(entity and entity.id or nil)
        .. " itemId="
        .. tostring(itemId)
        .. " classId="
        .. tostring(classId)
        .. " className="
        .. tostring(className)
        .. " position="
        .. formatVector(position)
    )

    if lower(classId) ~= lower(WorldItem.ItemClassId) then
        log("Make camp aborted: world item class did not match Simple Bedroll")
        return true
    end

    if not position then
        log("Make camp aborted: world position unavailable")
        return true
    end

    if not (SimpleBedRoll.Environment
        and SimpleBedRoll.Environment.CanCampHere) then

        log("Make camp aborted: environment module unavailable")
        return true
    end

    local canCamp, environmentReason =
        SimpleBedRoll.Environment.CanCampHere(user)

    if not canCamp then
        notifyEnvironmentDenied()
        log(
            "Make camp aborted: environment denied reason="
            .. tostring(environmentReason)
        )

        return true
    end

    if not (SimpleBedRoll.Bedding
        and SimpleBedRoll.Bedding.HasRequiredBedding) then

        log("Make camp aborted: bedding module unavailable")
        return true
    end

    local hasBedding, beddingCountOrReason =
        SimpleBedRoll.Bedding.HasRequiredBedding(user)

    if not hasBedding then
        if SimpleBedRoll.Bedding.NotifyMissingBedding then
            SimpleBedRoll.Bedding.NotifyMissingBedding()
        end

        log(
            "Make camp aborted: required bedding missing countOrReason="
            .. tostring(beddingCountOrReason)
        )

        return true
    end

    if not SimpleBedRoll.SpawnFunctionalTestBed then
        log("Make camp aborted: deployment API unavailable")
        return true
    end

    local deployOk, deployed = pcall(
        SimpleBedRoll.SpawnFunctionalTestBed,
        position
    )

    if not deployOk or deployed ~= true then
        log(
            "Make camp deployment failed: "
            .. tostring(deployOk and deployed or deployed)
        )

        return true
    end

    if SimpleBedRoll.MarkBeddingRequiredOnPack
        and SimpleBedRoll.Bedding.GetRequiredClassId then

        SimpleBedRoll.MarkBeddingRequiredOnPack(
            SimpleBedRoll.Bedding.GetRequiredClassId()
        )
    end

    if itemId and ItemManager and ItemManager.RemoveItem then
        local removeOk, removed = pcall(ItemManager.RemoveItem, itemId)
        local removedDroppedItem = removeOk and removed ~= false
        log(
            "Make camp removed dropped item: ok="
            .. tostring(removeOk)
            .. " result="
            .. tostring(removed)
            .. " itemId="
            .. tostring(itemId)
        )

        if removedDroppedItem
            and SimpleBedRoll.MarkReturnItemOnPack then

            SimpleBedRoll.MarkReturnItemOnPack(true)
        end
    else
        log(
            "Make camp could not remove dropped item: ItemManager.RemoveItem unavailable itemId="
            .. tostring(itemId)
        )
    end

    return true
end

function WorldItem.InstallHooks()
    local pickableItem = _G.PickableItem
    if not (pickableItem and type(pickableItem.GetActions) == "function") then
        return false
    end

    if pickableItem.__simplebedroll_getactions_wrapped then
        return true
    end

    local originalGetActions = pickableItem.GetActions

    function pickableItem.GetActions(self, user, firstFast)
        local actions = originalGetActions(self, user, firstFast) or {}

        if firstFast then
            return actions
        end

        if not WorldItem.IsSimpleBedroll(self)
            or not (Action and AddInteractorAction) then
            return actions
        end

        for i = 1, #actions do
            local action = actions[i]
            if action and action.func == WorldItem.OnMakeCamp then
                return actions
            end
        end

        local interaction = rawget(_G, "inr_pickablePickup")
            or rawget(_G, "inr_pickableSteal")
            or rawget(_G, "inr_pickableLoot")
        if not interaction then
            return actions
        end

        local maxOrder = 0
        for i = 1, #actions do
            local uiOrder = actions[i] and actions[i].uiOrder or 0
            if uiOrder and uiOrder > maxOrder then
                maxOrder = uiOrder
            end
        end

        local makeCampAction = Action()
            :hint(WorldItem.ActionHint)
            :action(WorldItem.ActionName)
            :hintType(AHT_HOLD)
            :func(WorldItem.OnMakeCamp)
            :interaction(interaction)
            :uiOrder(maxOrder + 1)
            :enabled(true)

        AddInteractorAction(actions, firstFast, makeCampAction)
        return actions
    end

    pickableItem.__simplebedroll_getactions_wrapped = true
    log("Wrapped PickableItem.GetActions")
    return true
end

function WorldItem.EnsureHooks()
    if not WorldItem.InstallHooks() and Script and Script.SetTimerForFunction then
        Script.SetTimerForFunction(
            WorldItem.HookRetryMs,
            "SimpleBedRoll_WorldItem_EnsureHooks"
        )
    end
end

function SimpleBedRoll_WorldItem_EnsureHooks()
    if SimpleBedRoll
        and SimpleBedRoll.WorldItem
        and SimpleBedRoll.WorldItem.EnsureHooks then

        SimpleBedRoll.WorldItem.EnsureHooks()
    end
end
