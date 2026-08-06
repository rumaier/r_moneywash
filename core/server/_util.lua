local resource = GetCurrentResourceName()
local version = GetResourceMetadata(resource, 'version', 0)
local webhookUrl = ''
local rateLimits = {}
local cooldowns = {}

function IsRateLimited(src, action, duration)
    local last = rateLimits[('%s:%s'):format(src, action)]
    return last and GetGameTimer() - last < duration
end

function SetRateLimit(src, action)
    rateLimits[('%s:%s'):format(src, action)] = GetGameTimer()
end

function IsOnCooldown(src, action, duration)
    local last = cooldowns[('%s:%s'):format(src, action)]
    return last and GetGameTimer() - last < duration
end

function SetCooldown(src, action)
    cooldowns[('%s:%s'):format(src, action)] = GetGameTimer()
end

function ClearCooldown(src, action)
    cooldowns[('%s:%s'):format(src, action)] = nil
end

function GetCooldownRemaining(src, action, duration)
    local last = cooldowns[('%s:%s'):format(src, action)]
    if not last then return 0 end
    local remaining = duration - (GetGameTimer() - last)
    if remaining <= 0 then return 0 end
    return remaining
end

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

local function checkVersion()
    if not Cfg.VersionCheck then return end
    bridge.version.check(resource)
    SetTimeout(3600000, checkVersion)
end

function Log(src, event, fields)
    if not webhookUrl or webhookUrl == '' then return end
    local name = src > 0 and GetPlayerName(src) or 'Console'
    PerformHttpRequest(webhookUrl, function()
    end, 'POST', json.encode({
        username = 'Resource Logs',
        avatar_url = 'https://cdn.rscripts.store/brand-assets/logo.png',
        embeds = {
            {
                title = event,
                color = 0x2C1B47,
                image = { url = 'https://cdn.rscripts.store/brand-assets/banner.png' },
                fields = {
                    { name = locale('server_id'),   value = '`' .. src .. '`',     inline = true },
                    { name = locale('username'),    value = '`' .. name .. '`', inline = true },
                    { name = utf8.char(0x200B), value = utf8.char(0x200B),     inline = true },
                    table.unpack(fields or {})
                },
                footer = { text = GetCurrentResourceName() .. ' | ' .. version},
                timestamp = os.date('%Y-%m-%d %H:%M:%S')
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

AddEventHandler('onResourceStart', function(name)
    if name ~= resource then return end
    print('------------------------------')
    print(resource .. ' | ' .. version)
    if bridge then
        print('^2' .. locale('bridge_loaded') .. '^0')
    else
        print('^1' .. locale('update_bridge') .. '^0')
    end
    if Cfg and Cfg.Debug then print('^1' .. locale('debug_enabled') .. '^0') end
    print('------------------------------')
    checkVersion()
end)

AddEventHandler('playerDropped', function()
    local src = source
    local prefix = '^' .. src .. ':'
    for key in pairs(rateLimits) do
        if key:match(prefix) then rateLimits[key] = nil end
    end
    for key in pairs(cooldowns) do
        if key:match(prefix) then cooldowns[key] = nil end
    end
end)
