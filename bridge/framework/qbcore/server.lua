if GetResourceState('qb-core') ~= 'started' then return end

Core.Framework = 'QBCore'
local QBCore = exports['qb-core']:GetCoreObject()

Framework = {
    Notify = function(src, msg, type)
        local src = src or source
        local resource = Cfg.Server.Notification or 'default'
        if resource == 'default' then
            TriggerClientEvent('QBCore:Notify', src, msg, type)
        elseif resource == 'ox' then
            TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type, position = 'top' })
        elseif resource == 'custom' then
            -- insert your notification export here
        end
    end,

    GetPlayerIdentifier = function(src)
        local src = src or source
        local playerData = QBCore.Functions.GetPlayer(src).PlayerData
        if not playerData then return end
        return playerData.citizenid
    end,

    GetPlayerJob = function(src)
        local src = src or source
        local playerData = QBCore.Functions.GetPlayer(src).PlayerData
        if not playerData then return end
        return playerData.job.name, playerData.job.label
    end,

    GetPlayerJobGrade = function(src)
        local src = src or source
        local playerData = QBCore.Functions.GetPlayer(src).PlayerData
        if not playerData then return end
        return playerData.job.grade.level, playerData.job.grade.name
    end,

    GetAccountBalance = function(src, acct)
        local src = src or source
        local playerData = QBCore.Functions.GetPlayer(src).PlayerData
        if not playerData then return end
        if acct == 'money' then acct = 'cash' end
        return playerData.accounts[acct].money
    end,

    AddAccountBalance = function(src, acct, amt)
        local src = src or source
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return end
        if acct == 'money' then acct = 'cash' end
        player.Functions.AddMoney(acct, amt)
    end,

    RemoveAccountBalance = function(src, acct, amt)
        local src = src or source
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return end
        if acct == 'money' then acct = 'cash' end
        player.Functions.RemoveMoney(acct, amt)
    end,

    RegisterUsableItem = function(item, cb)
        QBCore.Functions.CreateUseableItem(item, cb)
    end,
}
