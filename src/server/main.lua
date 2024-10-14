local taxRate = Cfg.Options.TaxRate
local cooldowns = {}

lib.callback.register('r_moneywash:getTaxRate', function()
    return taxRate
end)

lib.callback.register('r_moneywash:getPlayerInventory', function(src)
    return Core.Inventory.GetInventoryItems(src)
end)

lib.callback.register('r_moneywash:getPlayerCooldown', function(src)
    local identifier = Core.Framework.GetPlayerIdentifier(src)
    return (cooldowns[identifier] ~= nil) or false
end)

local function setPlayerCooldown(src)
    if not Cfg.Options.Cooldown then return end
    local identifier = Core.Framework.GetPlayerIdentifier(src)
    cooldowns[identifier] = true
    SetTimeout(Cfg.Options.Cooldown * 60000, function()
        cooldowns[identifier] = nil
    end)
    debug('[DEBUG] - '.. GetPlayerName(src) ..' has been set on cooldown for '.. Cfg.Options.Cooldown ..' minutes.')
end

local function givePlayerWashedMoney(src, amount)
    local taxedAmount = math.ceil(amount - (amount * (taxRate / 100)))
    Core.Framework.AddAccountBalance(src, 'money', taxedAmount)
    Core.Framework.Notify(src, _L('washed_money', amount, taxedAmount, taxRate), 'success')
    SendWebhook(src, 'Money Washed', amount, taxedAmount, taxRate)
    debug('[DEBUG] - '.. GetPlayerName(src) ..' has washed '.. amount ..' and received '.. taxedAmount ..' after tax.')
end

RegisterNetEvent('r_moneywash:startWashingMoney', function(src, amount, metadata)
    local src = src or source
    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    local identifier = Core.Framework.GetPlayerIdentifier(src)
    local distance = #(Cfg.Options.Location - playerCoords)
    local removed = Core.Inventory.RemoveItem(src, Cfg.Options.Currency, amount, metadata)
    if not removed then debug('[DEBUG] - Error removing currency from player', GetPlayerName(src)) return end
    local counted = lib.callback.await('r_moneywash:startWashingProgressBar', src, Cfg.Options.WashTime)
    if not counted then
        Core.Inventory.AddItem(src, Cfg.Options.Currency, amount, metadata)
        debug('[DEBUG] - Error counting money for player', GetPlayerName(src))
        return
    end
    if distance > 5.0 then DropPlayer(src, _L('cheater')) return end
    if cooldowns[identifier] then DropPlayer(src, _L('cheater')) return end
    setPlayerCooldown(src)
    SetTimeout(750, function()
        if metadata then
            givePlayerWashedMoney(src, metadata.worth)
        else
            givePlayerWashedMoney(src, amount)
        end
    end)
end)

CreateThread(function()
    while Cfg.Options.DynamicTax do
        local newRate = math.random(Cfg.Options.DynamicRange[1], Cfg.Options.DynamicRange[2])
        taxRate = newRate
        Wait(Cfg.Options.DynamicTimer * 60000)
    end
end)