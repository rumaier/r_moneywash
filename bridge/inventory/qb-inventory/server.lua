if GetResourceState('qb-inventory') ~= 'started' then return end

Core.Inventory = 'qb-inventory'
local QBCore = exports['qb-core']:GetCoreObject()

Inventory = {
    AddItem = function(src, item, qty, meta)
        local src = src or source
        local added = exports['qb-inventory']:AddItem(src, item, qty, nil, meta)
        if not added then return added end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', qty)
        return added
    end,

    RemoveItem = function(src, item, qty, meta)
        local src = src or source
        if meta then
            local playerInv = QBCore.Functions.GetPlayer(src).PlayerData.items
            if not playerInv then return end
            for _, item in pairs(playerInv) do
                if lib.table.matches(item.info, meta) then
                    local removed = exports['qb-inventory']:RemoveItem(src, item.name, qty, item.slot)
                    if not removed then return removed end
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'remove', qty)
                    return removed
                end
            end
        end
        local removed = exports['qb-inventory']:RemoveItem(src, item, qty, nil)
        if not removed then return removed end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', qty)
        return removed
    end,

    GetItem = function(src, item, meta)
        local src = src or source
        local playerItems = QBCore.Functions.GetPlayer(src).PlayerData.items
        if not playerItems then return end
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
        local totalItems = exports['qb-inventory']:GetItemsByName(src, item)
        return totalItems[1].amount or 0
    end,

    GetInventoryItems = function(src)
        local src = src or source
        local playerItems = QBCore.Functions.GetPlayer(src).PlayerData.items
        if not playerItems then return end
        for _, item in pairs(playerItems) do
            item.count = item.amount
            item.metadata = item.info
        end
        return playerItems
    end,

    CanCarryItem = function(src, item, amt)
        return true -- this framework and everything it does is stupid... so just return true
    end,

    RegisterStash = function(id, label, slots, weight, owner)
        -- this is a client side thing in qb-inventory, so we don't need to do anything here
    end,

    GetItemInfo = function(item)
        return QBCore.Shared.Items[item]
    end,
}
