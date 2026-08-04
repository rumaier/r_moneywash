math = lib.math

local resource = GetCurrentResourceName()
local rateLimits = {}
local cooldowns = {}
local tax = Cfg.WashTax

local function getRateLimitKey(src, action)
    return ('%s:%s'):format(src, action)
end

function IsRateLimited(src, action, duration)
    local last = rateLimits[getRateLimitKey(src, action)]
    return last and GetGameTimer() - last < duration
end

function SetRateLimit(src, action)
    rateLimits[getRateLimitKey(src, action)] = GetGameTimer()
end

local function getBalance(src, currency)
    return bridge.framework.getBalance(src, currency)
end

local function getItemCount(src, item)
    return bridge.inventory.getItemCount(src, item)
end

local function setCooldown(src)
    cooldowns[src] = os.time() + (Cfg.WashCooldown * 60)
end

local function isPlayerInRange(src)
    local player = GetPlayerPed(src)
    local coords = GetEntityCoords(player)
    local distance = #(coords - Cfg.Ped.coords.xyz)
    return distance <= 5.0
end

local function setNewTaxRate()
    local change = math.random(Cfg.PercentChange.min, Cfg.PercentChange.max)
    local direction = math.random() < 0.5 and -1 or 1
    tax = math.clamp(tax + (tax * (change / 100) * direction), Cfg.TaxLimits.min, Cfg.TaxLimits.max)
    log('debug', 'New tax rate set to ' .. tax .. '%')
    SetTimeout(Cfg.ChangeTimer * 60000, setNewTaxRate)
end

lib.callback.register('r_moneywash:getTax', function()
    return tax
end)

local function logWash(src, given, received)
    Log(src, locale('moneywash'), {
        { name = locale('money_given'),    value = '`$' .. given .. '`', inline = true },
        { name = locale('tax_rate'),       value = '`' .. tax .. '%`', inline = true },
        { name = locale('money_received'), value = '`$' .. received .. '`', inline = true },
    })
end

lib.callback.register('r_moneywash:canWash', function(src)
    local type = Cfg.CurrencyType
    local currency = Cfg.Currency
    if cooldowns[src] and os.time() < cooldowns[src] then
        return { canWash = false, err = 'on_cooldown' }
    end
    local count = type == 'item' and getItemCount(src, currency) or getBalance(src, currency)
    if currency == 'markedbills' and count < 1 or count < Cfg.MinAmount then
        return { canWash = false, err = 'no_funds' }
    end
    return { canWash = true, count = count }
end)

lib.callback.register('r_moneywash:wash', function(src, amount)
    if not isPlayerInRange(src) then
        log('warn', 'Player ' .. src .. ' is not in range of the wash')
        return { success = false }
    end
    if cooldowns[src] and os.time() < cooldowns[src] then
        log('warn', 'Player ' .. src .. ' is on cooldown, they should not have gotten here...')
        return { success = false }
    end
    local type = Cfg.CurrencyType
    local currency = Cfg.Currency
    local taxedAmount = math.ceil(amount - (amount * (tax / 100)))
    if currency == 'markedbills' then
        bridge.inventory.removeItem(src, currency, 1, { worth = amount })
    else
        if type == 'item' then
            bridge.inventory.removeItem(src, currency, amount)
        else
            bridge.framework.removeBalance(src, currency, amount)
        end
    end
    bridge.framework.addBalance(src, 'cash', taxedAmount)
    logWash(src, amount, taxedAmount)
    setCooldown(src)
    return { success = true, received = taxedAmount }
end)

lib.callback.register(resource .. ':getClientConfig', function()
    return {
        Language = Cfg.Language,
        Debug = Cfg.Debug,
        NuiColor = Cfg.NuiColor,
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
    for key in pairs(rateLimits) do
        if key:match('^' .. src .. ':') then
            rateLimits[key] = nil
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() or not Cfg.DynamicTax then return end
    setNewTaxRate()
end)
