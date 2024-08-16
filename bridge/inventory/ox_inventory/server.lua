if GetResourceState('ox_inventory') ~= 'started' then return end

Core.Inventory = 'ox_inventory'
local ox_inventory = exports.ox_inventory

Inventory = {
    AddItem = function(src, item, qty, meta)
        local src = src or source
        return ox_inventory:AddItem(src, item, qty, meta)
    end,

    RemoveItem = function(src, item, qty, meta)
        local src = src or source
        return ox_inventory:RemoveItem(src, item, qty, meta)
    end,

    GetItem = function(src, item, meta)
        local src = src or source
        return ox_inventory:GetItem(src, item, meta, false)
    end,

    GetItemCount = function(src, item, meta)
        local src = src or source
        return ox_inventory:GetItemCount(src, item, meta, false)
    end,

    GetInventoryItems = function(src)
        local src = src or source
        return ox_inventory:GetInventoryItems(src, false)
    end,

    CanCarryItem = function(src, item, amt)
        local src = src or source
        return ox_inventory:CanCarryItem(src, item, amt)
    end,

    RegisterStash = function(id, label, slots, weight, owner)
        ox_inventory:RegisterStash(id, label, slots, weight, owner)
    end,

    GetItemInfo = function(item)
        return ox_inventory:Items(item)
    end,
}