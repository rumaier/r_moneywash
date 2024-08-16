if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

Framework = {
    Notify = function(msg, type)
        local resource = Cfg.Server.Notification or 'default'
        if resource == 'default' then
            TriggerEvent('QBCore:Notify', msg, 'primary', 3000)
        elseif resource == 'ox' then
            lib.notify({ description = msg, type = type, position = 'top' })
        elseif resource == 'custom' then
            -- insert your notification export here
        end
    end,

    GetPlayerName = function()
        local playerData = QBCore.Functions.GetPlayerData()
        return playerData.charinfo.firstname, playerData.charinfo.lastname
    end,

    ToggleOutfit = function(outfit)
        if not Cfg.Uniform.Enabled then return end
        if outfit then
            local outfits = Cfg.Uniform.outfit
            local gender = QBCore.Functions.GetPlayerData().charinfo.gender
            local outfit = gender == 1 and outfits.female or outfits.male
            if not outfit then return end
            TriggerEvent('qb-clothing:client:loadOutfit', {outfitData = outfit})
        else
            TriggerServerEvent('qb-clothing:loadPlayerSkin')
        end
    end,
}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('r_moneywash:onConnect')
end)
