Core = exports['r_bridge']:returnCoreObject()

local onPlayerLoaded = Core.Info.Framework == 'ESX' and 'esx:playerLoaded' or 'QBCore:Client:OnPlayerLoaded'
RegisterNetEvent(onPlayerLoaded, function()
    TriggerEvent('r_moneywash:onConnect')
end)

function debug(...)
    if Cfg.Debug then
        print(...)
    end
end