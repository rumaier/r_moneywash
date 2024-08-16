local taxRate = Cfg.Options.TaxRate
local cooldowns = {}

lib.callback.register('r_moneywash:getCurrentTaxRate', function(src)
    return taxRate
end)

lib.callback.register('r_moneywash:getPlayerInventory', function(src)
    return Inventory.GetInventoryItems(src)
end)

lib.callback.register('r_moneywash:getInventoryItem', function(src, item)
    return Inventory.GetItem(src, item)
end)

lib.callback.register('r_moneywash:getPlayerCooldown', function(src)
    local identifier = Framework.GetPlayerIdentifier(src)
    return cooldowns[identifier] ~= nil or false
end)

local function setPlayerCooldown(src)
    if not Cfg.Options.Cooldown then return end
    local identifier = Framework.GetPlayerIdentifier(src)
    cooldowns[identifier] = true
    debug('[DEBUG] - ' .. identifier .. ' is on cooldown')
    SetTimeout(Cfg.Options.Cooldown * 60000, function()
        cooldowns[identifier] = nil
        debug('[DEBUG] - ' .. identifier .. ' is no longer on cooldown')
    end)
end

local function givePlayerWashedMoney(src, amount)
    local taxedAmount = math.ceil(amount - (amount * taxRate / 100))
    Framework.AddAccountBalance(src, 'money', taxedAmount)
    Framework.Notify(src, _L('washed_money', amount, taxedAmount, taxRate), 'success')
    SendWebhook(src, 'Money Washed', amount, taxedAmount, taxRate)
    debug('[DEBUG] - Washed: ' .. amount .. ' Received: ' .. taxedAmount)
end

RegisterNetEvent('r_moneywash:startWashingMoney', function(src, amount, metadata)
    local src = src or source
    local player = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(player)
    local identifier = Framework.GetPlayerIdentifier(src)
    local distance = #(Cfg.Options.Location - playerCoords)
    local removed = Inventory.RemoveItem(src, Cfg.Options.Currency, amount, metadata)
    if not removed then return debug('[DEBUG] - Error removing Currency') end
    local counted = lib.callback.await('r_moneywash:startWashingProgressBar', src, Cfg.Options.WashTime)
    if not counted then 
        Inventory.AddItem(src, Cfg.Options.Currency, amount, metadata)
        debug('[DEBUG] - Error counting money') 
        return   
    end
    if distance > 5.0 then return DropPlayer(src, _L('cheater')) end
    if cooldowns[identifier] then return DropPlayer(src, _L('cheater')) end
    setPlayerCooldown(src)
    SetTimeout(750, function()
        if metadata then
            givePlayerWashedMoney(src, metadata.worth)
            debug('[DEBUG] - Washed markedbills')
        else
            givePlayerWashedMoney(src, amount)
            debug('[DEBUG] - Washed' .. Cfg.Options.Currency)
        end
    end)
end)

CreateThread(function()
    while Cfg.Options.DynacmicTax do
        local newRate = math.random(Cfg.Options.DynamicRange[1], Cfg.Options.DynamicRange[2])
        taxRate = newRate
        Wait(Cfg.Options.DynamicTimer * 60000)
    end
end)

function SendWebhook(src, event, ...)
    if not Cfg.Webhook.Enabled then return end
    local name = '' if src > 0 then name = GetPlayerName(src) end
    local identifier = Framework.GetPlayerIdentifier(src) or ''
    PerformHttpRequest(Cfg.Webhook.Url, function(err, text, headers)
    end, 'POST', json.encode({
        username = 'Resource Logs',
        avatar_url = 'https://i.ibb.co/z700S5H/square.png',
        embeds = {
            {
                color = 0x2C1B47,
                title = event,
                author = {
                    name = GetCurrentResourceName(),
                    icon_url = 'https://i.ibb.co/z700S5H/square.png',
                    url = 'https://discord.gg/r-scripts'
                },
                thumbnail = {
                    url = 'https://i.ibb.co/z700S5H/square.png'
                },
                fields = {
                    { name = _L('player_id'),  value = src,        inline = true },
                    { name = _L('username'),   value = name,       inline = true },
                    { name = _L('identifier'), value = identifier, inline = false },
                    { name = _L('description'), value = _L('description_text', name, ...), inline = false},
                },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
                footer = {
                    text = 'r_scripts',
                    icon_url = 'https://i.ibb.co/z700S5H/square.png',
                },
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

local function checkVersion()
    if not Cfg.Server.VersionCheck then return end
    local url = 'https://api.github.com/repos/rumaier/r_moneywash/releases/latest'
    local current = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    PerformHttpRequest(url, function(err, text, headers)
        if err == 200 then
            local data = json.decode(text)
            local latest = data.tag_name
            if latest ~= current then
                print('[^3WARNING^0] '.. _L('update', GetCurrentResourceName()))
                print('[^3WARNING^0] https://github.com/rumaier/r_moneywash/releases/latest ^0')
            end
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
    SetTimeout(3600000, checkVersion)
end

function debug(...)
    if Cfg.Debug.Prints then
        print(...)
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        print('------------------------------')
        print(_L('version', GetCurrentResourceName(), GetResourceMetadata(GetCurrentResourceName(), 'version', 0)))
        print(_L('framework', Core.Framework))
        print(_L('inventory', Core.Inventory))
        print(_L('target', Core.Target))
        print('------------------------------')
        checkVersion()
    end
end)