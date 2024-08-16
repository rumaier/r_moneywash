if GetResourceState('es_extended') ~= 'started' then return end

Core.Framework = 'ESX'
local ESX = exports["es_extended"]:getSharedObject()

Framework = {
    Notify = function(src, msg, type)
        local src = src or source
        local resource = Cfg.Server.Notification or 'default'
        if resource == 'default' then
            TriggerClientEvent('esx:showNotification', src, msg, type)
        elseif resource == 'ox' then
            TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type, position = 'top' })
        elseif resource == 'custom' then
            -- insert your notification export here
        end
    end,

    GetPlayerIdentifier = function(src)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        return xPlayer.getIdentifier()
    end,

    GetPlayerJob = function(src)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        return xPlayer.getJob().name, xPlayer.getJob().label
    end,

    GetPlayerJobGrade = function(src)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        return xPlayer.getJob().grade, xPlayer.getJob().grade_label
    end,

    GetAccountBalance = function(src, acct)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        return xPlayer.getAccount(acct).money
    end,

    AddAccountBalance = function(src, acct, amt)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        xPlayer.addAccountMoney(acct, amt)
    end,

    RemoveAccountBalance = function(src, acct, amt)
        local src = src or source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        xPlayer.removeAccountMoney(acct, amt)
    end,

    RegisterUsableItem = function(item, cb)
        ESX.RegisterUsableItem(item, cb)
    end,
}