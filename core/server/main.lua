math = lib.math

local resource = GetCurrentResourceName()
local RATE_LIMIT_MS = 1000

local rateLimits = {}
local cooldowns = {}
local washing = {}
local tax = Cfg.WashTax

local function getRateLimitKey(src, action)
    return ('%s:%s'):format(src, action)
end

local function isRateLimited(src, action, duration)
    local last = rateLimits[getRateLimitKey(src, action)]
    return last and GetGameTimer() - last < duration
end

local function setRateLimit(src, action)
    rateLimits[getRateLimitKey(src, action)] = GetGameTimer()
end

local function getBalance(src, currency)
    return bridge.framework.getBalance(src, currency)
end

local function getItemCount(src, item)
    return bridge.inventory.getItemCount(src, item)
end

local function removeBalanceVerified(src, account, amount)
    local before = getBalance(src, account)
    if before < amount then return false end
    bridge.framework.removeBalance(src, account, amount)
    return getBalance(src, account) <= before - amount
end

local function setCooldown(src)
    cooldowns[src] = os.time() + (Cfg.WashCooldown * 60)
end

local function getCooldownMinutes(src)
    local expires = cooldowns[src]
    if not expires then return 0 end
    local remaining = expires - os.time()
    if remaining <= 0 then return 0 end
    return math.ceil(remaining / 60)
end

local function isPlayerInRange(src)
    local player = GetPlayerPed(src)
    local coords = GetEntityCoords(player)
    local distance = #(coords - Cfg.Ped.coords.xyz)
    return distance <= 5.0
end

local function isValidAmount(amount)
    return type(amount) == 'number'
        and amount > 0
        and amount == math.floor(amount)
        and amount >= Cfg.MinAmount
        and amount <= Cfg.MaxAmount
end

local function getDirtyCount(src)
    local currency = Cfg.Currency
    if currency == 'markedbills' or Cfg.CurrencyType == 'item' then
        return getItemCount(src, currency)
    end
    return getBalance(src, currency)
end

local function findMarkedBill(src, slot)
    if type(slot) ~= 'number' then return nil end
    local inventory = bridge.inventory.getInventory(src) or {}
    for _, item in pairs(inventory) do
        if item.name == Cfg.Currency and item.slot == slot then
            local worth = item.metadata and item.metadata.worth
            if type(worth) == 'number' and worth > 0 and worth == math.floor(worth) then
                return item, worth
            end
            return nil
        end
    end
end

local function setNewTaxRate()
    local change = math.random(Cfg.PercentChange.min, Cfg.PercentChange.max)
    local direction = math.random() < 0.5 and -1 or 1
    tax = math.clamp(tax + (tax * (change / 100) * direction), Cfg.TaxLimits.min, Cfg.TaxLimits.max)
    log('debug', 'New tax rate set to ' .. tax .. '%')
    SetTimeout(Cfg.ChangeTimer * 60000, setNewTaxRate)
end

local function logWash(src, given, received)
    Log(src, locale('moneywash'), {
        { name = locale('money_given'),    value = '`$' .. given .. '`', inline = true },
        { name = locale('tax_rate'),       value = '`' .. tax .. '%`', inline = true },
        { name = locale('money_received'), value = '`$' .. received .. '`', inline = true },
    })
end

local function failWash(src, reason)
    log('warn', ('Player %s wash failed: %s'):format(src, reason))
    return { success = false }
end

lib.callback.register('r_moneywash:getTax', function()
    return tax
end)

lib.callback.register('r_moneywash:getMarkedBills', function(src)
    if isRateLimited(src, 'getMarkedBills', RATE_LIMIT_MS) then return {} end
    setRateLimit(src, 'getMarkedBills')

    local info = bridge.inventory.getItemInfo(Cfg.Currency)
    local label = (info and (info.label or info.name)) or Cfg.Currency
    local items = {}
    local inventory = bridge.inventory.getInventory(src) or {}
    for _, item in pairs(inventory) do
        local worth = item.metadata and item.metadata.worth
        if item.name == Cfg.Currency and type(worth) == 'number' and worth > 0 then
            items[#items + 1] = {
                label = label,
                worth = worth,
                slot = item.slot,
            }
        end
    end
    return items
end)

lib.callback.register('r_moneywash:canWash', function(src)
    if isRateLimited(src, 'canWash', RATE_LIMIT_MS) then
        return { canWash = false }
    end
    setRateLimit(src, 'canWash')

    local minutes = getCooldownMinutes(src)
    if minutes > 0 then
        return { canWash = false, err = 'on_cooldown', cooldown = minutes }
    end

    local currency = Cfg.Currency
    local count = getDirtyCount(src)
    if currency == 'markedbills' then
        if count < 1 then
            return { canWash = false, err = 'no_funds' }
        end
        return { canWash = true, count = count }
    end

    if count < Cfg.MinAmount then
        return { canWash = false, err = 'no_funds' }
    end
    return { canWash = true, count = count }
end)

lib.callback.register('r_moneywash:wash', function(src, amount, slot)
    if isRateLimited(src, 'wash', RATE_LIMIT_MS) then
        return failWash(src, 'rate limited')
    end
    setRateLimit(src, 'wash')

    if washing[src] then
        return failWash(src, 'already washing')
    end
    washing[src] = true

    local function finish(result)
        washing[src] = nil
        return result
    end

    if not isPlayerInRange(src) then
        return finish(failWash(src, 'out of range'))
    end
    if getCooldownMinutes(src) > 0 then
        return finish(failWash(src, 'on cooldown'))
    end

    local currency = Cfg.Currency
    local currencyType = Cfg.CurrencyType
    local washAmount

    if currency == 'markedbills' then
        local item, worth = findMarkedBill(src, slot)
        if not item then
            return finish(failWash(src, 'invalid markedbills slot'))
        end
        washAmount = worth
    else
        if not isValidAmount(amount) then
            return finish(failWash(src, 'invalid amount'))
        end
        local count = getDirtyCount(src)
        if count < amount then
            return finish(failWash(src, 'insufficient funds'))
        end
        washAmount = amount
    end

    local taxedAmount = math.ceil(washAmount - (washAmount * (tax / 100)))
    if taxedAmount < 1 then
        return finish(failWash(src, 'taxed amount too low'))
    end

    -- Lock the wash window before mutating to prevent double-payout races.
    setCooldown(src)

    local removed = false
    if currency == 'markedbills' then
        -- Slot already verified server-side; omit metadata so providers honor the slot.
        removed = bridge.inventory.removeItem(src, currency, 1, nil, slot)
    elseif currencyType == 'item' then
        removed = bridge.inventory.removeItem(src, currency, washAmount)
    else
        removed = removeBalanceVerified(src, currency, washAmount)
    end

    if not removed then
        cooldowns[src] = nil
        return finish(failWash(src, 'failed to remove dirty money'))
    end

    local cashBefore = getBalance(src, 'cash')
    bridge.framework.addBalance(src, 'cash', taxedAmount)
    if getBalance(src, 'cash') < cashBefore + taxedAmount then
        if currency == 'markedbills' then
            bridge.inventory.addItem(src, currency, 1, { worth = washAmount })
        elseif currencyType == 'item' then
            bridge.inventory.addItem(src, currency, washAmount)
        else
            bridge.framework.addBalance(src, currency, washAmount)
        end
        cooldowns[src] = nil
        return finish(failWash(src, 'failed to add clean cash'))
    end

    logWash(src, washAmount, taxedAmount)
    log('debug', ('Player %s washed %s and received %s'):format(src, washAmount, taxedAmount))
    return finish({ success = true, received = taxedAmount })
end)

lib.callback.register(resource .. ':getClientConfig', function()
    return {
        Language = Cfg.Language,
        Debug = Cfg.Debug,
        EnableTeleport = Cfg.EnableTeleport,
        TeleportEnter = Cfg.TeleportEnter,
        TeleportExit = Cfg.TeleportExit,
        Blip = Cfg.Blip,
        Ped = Cfg.Ped,
        Currency = Cfg.Currency,
        MinAmount = Cfg.MinAmount,
        MaxAmount = Cfg.MaxAmount,
        WashTimer = Cfg.WashTimer,
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    cooldowns[src] = nil
    washing[src] = nil
    for key in pairs(rateLimits) do
        if key:match('^' .. src .. ':') then
            rateLimits[key] = nil
        end
    end
end)

AddEventHandler('onResourceStart', function(started)
    if started ~= resource or not Cfg.DynamicTax then return end
    setNewTaxRate()
end)
