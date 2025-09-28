local washing = {}
local cooldowns = {}
local taxRate = Cfg.Options.MoneyWash.tax

local function setPlayerCooldown(src)
    local duration = Cfg.Options.MoneyWash.cooldown
    cooldowns[src] = true
    SetTimeout(duration * 60000, function() cooldowns[src] = nil end)
end

lib.callback.register('r_moneywash:canPlayerWash', function(src)
    local wash = Cfg.Options.MoneyWash
    local item = wash.currency
    local count = Core.Inventory.getItemCount(src, item)
    local cooldown = cooldowns[src] ~= nil
    if cooldown then return false, _L('on_cooldown', wash.cooldown) end
    if item == 'markedbills' then
        if count < 1 then return false, _L('insufficient_funds') end
        return true
    else
        local min = wash.min
        if count < min then return false, _L('insufficient_funds') end
        return true, count
    end
end)

lib.callback.register('r_moneywash:getCurrentTaxRate', function()
    return taxRate
end)

local function setNewTaxRate()
    local wash = Cfg.Options.MoneyWash
    local rate = wash.tax
    local range = wash.taxChangeRange
    local change = math.random(range[1], range[2])
    local increase = math.random(0, 1) == 1
    if increase then
        taxRate = math.min(rate + change, 100)
    else
        taxRate = math.max(rate - change, 0)
    end
    _debug('[^6DEBUG^0] - New tax rate set:', taxRate)
    SetTimeout(wash.taxChangeTimer * 60000, setNewTaxRate)
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if Cfg.Options.MoneyWash.dynamicTax then
            setNewTaxRate()
        end
    end
end)

lib.callback.register('r_moneywash:getMarkedBillItems', function(src)
    local inventory = Core.Inventory.getPlayerInventory(src) or {}
    local markedbills = {}
    for _, item in pairs(inventory) do
        if item.name == 'markedbills' and item.metadata and item.metadata.worth then
            table.insert(markedbills, item)
        end
    end
    return markedbills
end)

local function isPlayerNearMoneywash(src)
    local player = GetPlayerPed(src)
    local coords = GetEntityCoords(player)
    local washCoords = Cfg.Options.WashPed.location.xyz
    local distance = #(coords - washCoords)
    return distance <= 10.0
end

lib.callback.register('r_moneywash:removeMoney', function(src, amount)
    local wash = Cfg.Options.MoneyWash
    local item = wash.currency
    if item == 'markedbills' then
        local removed = Core.Inventory.removeItem(src, item, 1, amount)
        washing[src] = removed and math.ceil(amount - (amount * (taxRate / 100))) or nil
        return removed
    else
        local removed = Core.Inventory.removeItem(src, item, amount)
        washing[src] = removed and math.ceil(amount - (amount * (taxRate / 100))) or nil
        return removed
    end
end)

local function sendWashLog(src, amount)
    local rate = taxRate
    local originalAmount = math.floor(amount / (1 - (rate / 100)))
    SendWebhook(src, _L('money_washed'), {
        { name = _L('money_given'),    value = '`$' .. originalAmount .. '`', inline = true },
        { name = _L('tax_rate'),       value = '`' .. rate .. '%`', inline = true },
        { name = _L('money_received'), value = '`$' .. amount .. '`', inline = true },
    })
end

lib.callback.register('r_moneywash:addMoney', function(src)
    if not isPlayerNearMoneywash(src) then return false, _debug('[^1ERROR^0] - Player is not near money wash ped, possible exploit attempt.') end
    if not washing[src] then return false, _debug('[^1ERROR^0] - Playing not found in washing table, possible exploit attempt.') end
    if cooldowns[src] then return false, _debug('[^1ERROR^0] - Player is still on cooldown, possible exploit attempt.') end
    local balance = Core.Framework.getAccountBalance(src, 'cash') or 0
    Core.Framework.addAccountBalance(src, 'cash', washing[src])
    local newBalance = Core.Framework.getAccountBalance(src, 'cash') or 0
    local added = newBalance == (balance + washing[src])
    if not added then return false, _debug('[^1ERROR^0] - Failed to add funds to player ' .. src .. '') end
    setPlayerCooldown(src)
    added = washing[src]
    washing[src] = nil
    sendWashLog(src, added)
    return added
end)
