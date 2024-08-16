if GetResourceState('qs-inventory') ~= 'started' then return end

Core.Inventory = 'qs-inventory'

Inventory = {
    AddItem = function(src, item, qty, meta)
        local src = src or source
        return exports['qs-inventory']:AddItem(src, item, qty, nil, meta)
    end,

    RemoveItem = function(src, item, qty, meta)
        local src = src or source
        return exports['qs-inventory']:RemoveItem(src, item, qty, nil, meta)
    end,

    GetItem = function(src, item, meta)
        local src = src or source
        local playerItems = exports['qs-inventory']:GetInventory(src)
        for _, itemInfo in pairs(playerItems) do
            if itemInfo.name == item then
                itemInfo.count = itemInfo.amount
                itemInfo.metadata = itemInfo.info
                return itemInfo
            end
        end
    end,

    GetItemCount = function(src, item, meta)
        local src = src or source
        return exports['qs-inventory']:GetItemTotalAmount(src, item)
    end,

    GetInventoryItems = function(src)
        local src = src or source
        local playerItems = exports['qs-inventory']:GetInventory(src)
        for _, item in pairs(playerItems) do
            item.count = item.amount
            item.metadata = item.info
        end
        return playerItems
    end,

    CanCarryItem = function(src, item, amt)
        local src = src or source
        return exports['qs-inventory']:CanCarryItem(source, item, amt)
    end,

    RegisterStash = function(id, label, slots, weight, owner)
        -- this is done client side on qs-inventory, so we don't need to do anything here
    end,

    GetItemInfo = function(item)
        local itemsLua = exports['qs-inventory']:GetItemList()
        if not itemsLua[item] then return end
        return itemsLua[item]
    end,
}
