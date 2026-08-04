local resource = GetCurrentResourceName()
local version = GetResourceMetadata(resource, 'version', 0)
local webhookUrl = ''

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
