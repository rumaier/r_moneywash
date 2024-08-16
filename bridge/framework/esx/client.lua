if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports["es_extended"]:getSharedObject()

Framework = {
    Notify = function(msg, type)
        local resource = Cfg.Server.Notification or 'default'
        if resource == 'default' then
            ESX.ShowNotification(msg, type)
        elseif resource == 'ox' then
            lib.notify({ description = msg, type = type, position = 'top' })
        elseif resource == 'custom' then
            -- insert your notification export here
        end
    end,

    GetPlayerName = function()
        return ESX.PlayerData.firstName, ESX.PlayerData.lastName
    end,

    ToggleOutfit = function(outfit)
        if not Cfg.Uniform.Enabled then return end
        if outfit then
            local outfits = Cfg.Uniform.Outfits
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                local gender = skin.sex
                local outfit = gender == 1 and outfits.female or outfits.male
                if not outfit then return end
                TriggerEvent('skinchanger:loadClothes', skin, outfit)
            end)
        else
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
        end
    end,
}

RegisterNetEvent('esx:playerLoaded', function()
    while not ESX.IsPlayerLoaded() do Wait(0) end
    TriggerEvent('r_moneywash:onConnect')
end)
