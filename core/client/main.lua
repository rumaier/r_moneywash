local teleporters = {}
local spawner = nil
local ped = nil
local prop = nil

local function enterExitAnim(direction)
    local label = direction == 'enter' and locale('knocking') or locale('leaving')
    local anim = direction == 'enter' and { dict = 'timetable@jimmy@doorknock@', clip = 'knockdoor_idle' } or { dict = 'mp_common', clip = 'givetake1_a' }
    local duration = direction == 'enter' and 1500 or 1000
    return bridge.interface.progress({
        duration = duration,
        label = label,
        position = 'bottom',
        canCancel = false,
        anim = anim,
        disable = { move = true, combat = true },
    })
end

local function takeMoneyAnims()
    assert(ped, 'Ped is not defined')
    local pedHand = GetPedBoneIndex(ped, 28422)
    prop = bridge.natives.createObject('prop_cash_envelope_01', vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(prop, ped, pedHand, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    bridge.natives.playAnimation(ped, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    bridge.natives.playAnimation(cache.ped, 'mp_common', 'givetake1_b', -1, 0, 0.0)
    Wait(750)
    AttachEntityToEntity(prop, cache.ped, 90, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    bridge.natives.playAnimation(cache.ped, 'melee@holster', 'holster', -1, 0, 0.0)
    DeleteEntity(prop)
    prop = nil
end

local function giveMoneyAnims()
    assert(ped, 'Ped is not defined')
    prop = bridge.natives.createObject('prop_anim_cash_pile_02', vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(prop, cache.ped, 90, 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
    bridge.natives.playAnimation(cache.ped, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    bridge.natives.playAnimation(ped, 'mp_common', 'givetake1_b', -1, 0, 0.0)
    Wait(750)
    local pedHand = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(prop, ped, pedHand, -0.015, -0.009, -0.013, 109.850, 0, 0, true, true, false, true, 2, true)
    Wait(250)
    bridge.natives.playAnimation(ped, 'amb@code_human_wander_texting_fat@male@base', 'static', -1, 1, 0.0)
end

local function washMoney(amount)
    giveMoneyAnims()
    local duration = Cfg.WashTimer * 1000
    if bridge.interface.progress({
        duration = duration,
        label = locale('counting'),
        position = 'bottom',
        canCancel = false,
        disable = { move = true, combat = true, vehicle = true },
    }) then
        assert(ped, 'Ped is not defined')
        assert(prop, 'Prop is not defined')
        local resp = lib.callback.await('r_moneywash:wash', false, amount)
        if not resp.success then log('error', 'Failed to wash money, check server console for more information') return end
        StopAnimTask(ped, 'amb@code_human_wander_texting_fat@male@base', 'static', 1.0)
        bridge.natives.playAnimation(ped, 'melee@holster', 'holster', -1, 0, 0.0)
        DeleteEntity(prop)
        Wait(500)
        takeMoneyAnims()
        bridge.interface.notify(locale('moneywash'), locale('washed', amount, resp.received), 'success')
        log('debug', 'Washed ' .. amount .. ' and received ' .. resp.received)
    end
end

local function givePlayerOffer(amount)
    log('debug', 'givePlayerOffer(' .. amount .. ')')
    local tax = lib.callback.await('r_moneywash:getTax', false)
    local offer = math.ceil(amount - (amount * (tax / 100)))
    local alert = lib.alertDialog({
        header = locale('moneywash'),
        content = locale('offer', offer, tax),
        centered = true,
        cancel = true
    })
    if alert == 'cancel' then
        assert(ped, 'Ped is not defined')
        PlayPedAmbientSpeechNative(ped, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE')
    else
        washMoney(amount)
    end
end

local function openMarkedBillSelection()
    local options = lib.callback.await('r_moneywash:getMarkedBills', false)
    if not options or #options == 0 then return end
    for k, v in pairs(options) do
        local worth = v.metadata.worth
        v.title = v.label
        v.description = locale('worth', worth)
        v.icon = 'fas fa-sack-dollar'
        v.iconColor = '#fa5252'
        v.onSelect = function()
            givePlayerOffer(worth)
        end
        v.metadata = nil
    end
    bridge.interface.registerContext({ id = 'moneywash', title = locale('moneywash'), options = options })
    log('debug', 'Marked bill selection menu built with ' .. #options .. ' options')
    bridge.interface.showContext('moneywash')
end

local function openInput()
    assert(ped, 'Ped is not defined')
    local resp = lib.callback.await('r_moneywash:canWash', false)
    if not resp.canWash then
        PlayPedAmbientSpeechNative(ped, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE')
        bridge.interface.notify(locale('moneywash'), locale(resp.err), 'error')
        return
    end
    PlayPedAmbientSpeechNative(ped, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    if Cfg.Currency == 'markedbills' then openMarkedBillSelection() return end
    local input = bridge.interface.input(locale('moneywash'), {
        { type = 'number', label = locale('amount'), icon = 'dollar-sign', required = true, default = Cfg.MinAmount, min = Cfg.MinAmount, max = math.min(Cfg.MaxAmount, resp.count or 0)}
    })
    if not input or #input == 0 then return end
    givePlayerOffer(tonumber(input[1]))
end

local function despawnPed()
    assert(ped, 'Ped is not defined')
    bridge.target.removeLocalEntity(ped)
    DeleteEntity(ped)
    ped = nil
    log('debug', 'Moneywash ped despawned')
end

local function spawnPed()
    if ped then despawnPed() end
    local cfg = Cfg.Ped
    ped = bridge.natives.createPed(cfg.model, cfg.coords.xyz, cfg.coords.w, false)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    bridge.natives.setPedInert(ped, true)
    bridge.target.addLocalEntity(ped, {
        {
            label = locale('moneywash'),
            icon = 'fas fa-money-bill',
            distance = 1.0,
            onSelect = openInput
        }
    })
    log('debug', 'Moneywash ped spawned at: ' .. cfg.coords)
end

local function enterMoneywash(target)
    target = NormalizeTarget(target)
    TaskTurnPedToFaceCoord(cache.ped, target.coords.x, target.coords.y, target.coords.z, -1)
    repeat Wait(0) until bridge.natives.isPedFacingCoord(cache.ped, target.coords)
    ClearPedTasks(cache.ped)    
    if enterExitAnim('enter') then
        local coords = Cfg.TeleportExit.coords
        bridge.natives.teleportPlayer(coords.xyz, coords.w)
    end
end

local function exitMoneywash(target)
    target = NormalizeTarget(target)
    TaskTurnPedToFaceCoord(cache.ped, target.coords.x, target.coords.y, target.coords.z, -1)
    repeat Wait(0) until bridge.natives.isPedFacingCoord(cache.ped, target.coords)
    ClearPedTasks(cache.ped)
    if enterExitAnim('exit') then
        local coords = Cfg.TeleportEnter.coords
        bridge.natives.teleportPlayer(coords.xyz, coords.w)
    end
end

local function initializeMoneywash()
    local blip = Cfg.Blip
    local ped = Cfg.Ped
    spawner = lib.points.new({
        coords = ped.coords.xyz,
        heading = ped.coords.w,
        distance = 150.0,
        onEnter = spawnPed,
        onExit = despawnPed
    })
    if blip.enabled then
        local blipCoords = Cfg.TeleportEnter.target
        bridge.natives.createBlip(blipCoords, blip.sprite, blip.color, blip.scale, locale('moneywash'))
        log('debug', 'Moneywash blip created at: ' .. tostring(blipCoords))
    end
    log('debug', 'Moneywash spawner initialized at: ' .. tostring(ped.coords.xyz))
end

local function initializeTeleporters()
    if not Cfg.EnableTeleport or teleporters.enter then return end
    local debug = Cfg.Debug
    local enter = Cfg.TeleportEnter
    teleporters.enter = bridge.target.addZone(enter.target, 0.5, {
        {
            label = locale('knock'),
            icon = 'fas fa-door-open',
            distance = 1.0,
            onSelect = enterMoneywash
        }
    }, debug)
    log('debug', 'Entrance teleporter initialized at: ' .. tostring(enter.target))
    local exit = Cfg.TeleportExit
    teleporters.exit = bridge.target.addZone(exit.target, 0.5, {
        {
            label = locale('exit'),
            icon = 'fas fa-person-walking-arrow-right',
            distance = 1.0,
            onSelect = exitMoneywash
        }
    }, debug)
    log('debug', 'Exit teleporter initialized at: ' .. tostring(exit.target))
end

local function onClientReady()
    initializeTeleporters()
    initializeMoneywash()
end

AddEventHandler('r_bridge:playerLoaded', onClientReady)
AddEventHandler(GetCurrentResourceName() .. ':clientConfigLoaded', onClientReady)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, t in pairs(teleporters) do
        bridge.target.removeZone(t)
    end
end)
