-- Disposable bedding material policy for Simple Bedroll.

SimpleBedRoll = SimpleBedRoll or {}
SimpleBedRoll.Bedding = SimpleBedRoll.Bedding or {}

local Bedding = SimpleBedRoll.Bedding
local Placement = SimpleBedRoll.Placement

Bedding.RequiredClassId = "3e2f9a64-8c2b-4f7a-a9d3-5c1b2e7d4f90"
Bedding.RequiredName = "curaequi_hay_bundle_sm"
Bedding.MissingMessageKey = "@simplebedroll_ui_need_bedding"
Bedding.MissingMessageText = "I need something dry to put beneath the bedroll."

local function log(message)
    System.LogAlways("[SimpleBedRoll/Bedding] " .. tostring(message))
end

local function getInventory(entity)
    if not entity then
        return nil
    end

    if entity.inventory then
        return entity.inventory
    end

    if entity.GetInventory then
        local ok, inventory = pcall(entity.GetInventory, entity)
        if ok then
            return inventory
        end
    end

    return nil
end

function Bedding.GetPlayerInventory(user)
    local inventory = getInventory(user)
    if inventory then
        return inventory
    end

    if Placement and Placement.GetPlayer then
        inventory = getInventory(Placement.GetPlayer())
        if inventory then
            return inventory
        end
    end

    if player then
        return getInventory(player)
    end

    return nil
end

function Bedding.GetRequiredClassId()
    return Bedding.RequiredClassId
end

function Bedding.GetCount(user)
    local inventory = Bedding.GetPlayerInventory(user)

    if not inventory then
        return nil, "inventory unavailable"
    end

    if not inventory.GetCountOfClass then
        return nil, "inventory.GetCountOfClass unavailable"
    end

    local ok, count = pcall(
        inventory.GetCountOfClass,
        inventory,
        Bedding.RequiredClassId
    )

    if not ok or type(count) ~= "number" then
        return nil, "inventory.GetCountOfClass failed"
    end

    return math.floor(count + 0.00001), nil
end

function Bedding.HasRequiredBedding(user)
    local count, err = Bedding.GetCount(user)
    if count == nil then
        return false, err
    end

    return count >= 1, count
end

function Bedding.NotifyMissingBedding()
    local shown = false

    if Game and Game.SendInfoText then
        local ok = pcall(
            Game.SendInfoText,
            Bedding.MissingMessageKey,
            false,
            nil,
            5
        )
        shown = ok == true
    end

    log("missing bedding: " .. Bedding.MissingMessageText)
    return shown
end

function Bedding.ConsumeRequiredBedding(user)
    local inventory = Bedding.GetPlayerInventory(user)

    if not inventory then
        log("consume failed: player inventory unavailable")
        return false, "inventory unavailable"
    end

    local before = nil
    if inventory.GetCountOfClass then
        before = Bedding.GetCount(user)
    end

    if before ~= nil and before < 1 then
        log("consume skipped: required bedding missing at pack time")
        return false, "missing"
    end

    if not inventory.DeleteItemOfClass then
        log("consume failed: inventory.DeleteItemOfClass unavailable")
        return false, "DeleteItemOfClass unavailable"
    end

    local ok, result = pcall(
        inventory.DeleteItemOfClass,
        inventory,
        Bedding.RequiredClassId,
        1
    )

    if not ok then
        log("consume failed: DeleteItemOfClass raised " .. tostring(result))
        return false, "DeleteItemOfClass raised"
    end

    local consumed = 0
    if type(result) == "number" then
        consumed = result
    elseif result ~= false then
        consumed = 1
    end

    if consumed < 1 then
        log("consume failed: DeleteItemOfClass removed no items result=" .. tostring(result))
        return false, "no item removed"
    end

    if Game and Game.ShowItemsTransfer then
        pcall(Game.ShowItemsTransfer, Bedding.RequiredClassId, -1)
    end

    local after = nil
    if inventory.GetCountOfClass then
        after = Bedding.GetCount(user)
    end

    log(
        "consumed required bedding classId="
        .. Bedding.RequiredClassId
        .. " before="
        .. tostring(before)
        .. " after="
        .. tostring(after)
        .. " result="
        .. tostring(result)
    )

    return true, consumed
end

function Bedding.GiveTestHay(user)
    local inventory = Bedding.GetPlayerInventory(user)

    if not inventory then
        log("give test hay failed: player inventory unavailable")
        return false
    end

    if not inventory.CreateItem then
        log("give test hay failed: inventory.CreateItem unavailable")
        return false
    end

    local before = Bedding.GetCount(user)
    local ok, result = pcall(
        inventory.CreateItem,
        inventory,
        Bedding.RequiredClassId,
        1.0,
        1
    )

    if not ok then
        log("give test hay failed: CreateItem raised " .. tostring(result))
        return false
    end

    local after = Bedding.GetCount(user)
    local verified = before ~= nil and after ~= nil and after >= before + 1

    if Game and Game.ShowItemsTransfer then
        pcall(Game.ShowItemsTransfer, Bedding.RequiredClassId, 1)
    end

    log(
        "gave test hay classId="
        .. Bedding.RequiredClassId
        .. " result="
        .. tostring(result)
        .. " before="
        .. tostring(before)
        .. " after="
        .. tostring(after)
        .. " verified="
        .. tostring(verified)
    )

    return verified or (before == nil and after == nil and result ~= false)
end
