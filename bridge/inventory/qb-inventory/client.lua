if GetResourceState('qb-inventory') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

Inventory = {
    OpenStash = function(id)
        TriggerEvent("inventory:client:SetCurrentStash", id)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", id, {
            maxweight = 50000,
            slots = 50,
        })
    end,

    GetItemInfo = function(item)
        return QBCore.Shared.Items[item]
    end,
}
