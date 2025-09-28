Core = exports.r_bridge:returnCoreObject()

local resource = GetCurrentResourceName()
local version = GetResourceMetadata(resource, 'version', 0)
local bridgeStarted = GetResourceState('r_bridge') == 'started'

local function checkResourceVersion()
    if not Cfg.Server.VersionCheck then return end
    Core.VersionCheck(resource)
    SetTimeout(3600000, checkResourceVersion)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= resource then return end
    print('------------------------------')
    print(_L('resource_version', resource, version))
    if bridgeStarted then
        print(_L('bridge_detected'))
    else
        print(_L('bridge_not_detected'))
    end
    if Cfg.Debug then print(_L('debug_enabled')) end
    print('------------------------------')
    checkResourceVersion()
end)

function SendWebhook(src, event, fields)
    if not Cfg.Options.WebhookEnabled then return end
    local srcName = src > 0 and GetPlayerName(src) or 'Server'
    PerformHttpRequest(Cfg.WebhookUrl, function()
    end, 'POST', json.encode({
        username = 'Resource Logs',
        avatar_url = 'https://i.ibb.co/N62P014g/logo-2.jpg',
        embeds = {
            {
                title = event,
                color = 0x2C1B47,
                image = { url = 'https://i.ibb.co/vVMnc6Y/wide.png' },
                fields = {
                    { name = _L('player_id'),   value = '`' .. src .. '`',     inline = true },
                    { name = _L('username'),    value = '`' .. srcName .. '`', inline = true },
                    { name = utf8.char(0x200B), value = utf8.char(0x200B),     inline = true },
                    table.unpack(fields or {})
                },
                footer = { text = GetCurrentResourceName() },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end
