local teleporters = {}
local spawner = nil
local blipId = nil
local ped = nil
local prop = nil

local function cleanupProp()
    if not prop then return end
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    prop = nil
end

local function cleanupWashVisuals()
    if ped and DoesEntityExist(ped) then
        StopAnimTask(ped, 'amb@code_human_wander_texting_fat@male@base', 'static', 1.0)
        ClearPedTasks(ped)
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    end
    cleanupProp()
end

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
    if not ped then
        log('error', 'takeMoneyAnims called without ped')
        return
    end
    local pedHand = GetPedBoneIndex(ped, 28422)
    prop = bridge.natives.createObject('prop_cash_envelope_01', vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(prop, ped, pedHand, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    bridge.natives.playAnimation(ped, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    bridge.natives.playAnimation(cache.ped, 'mp_common', 'givetake1_b', -1, 0, 0.0)
    Wait(750)
    AttachEntityToEntity(prop, cache.ped, 90, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    bridge.natives.playAnimation(cache.ped, 'melee@holster', 'holster', -1, 0, 0.0)
    cleanupProp()
end

local function giveMoneyAnims()
    if not ped then
        log('error', 'giveMoneyAnims called without ped')
        return false
    end
    prop = bridge.natives.createObject('prop_anim_cash_pile_02', vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(prop, cache.ped, 90, 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
    bridge.natives.playAnimation(cache.ped, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    bridge.natives.playAnimation(ped, 'mp_common', 'givetake1_b', -1, 0, 0.0)
    Wait(750)
    local pedHand = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(prop, ped, pedHand, -0.015, -0.009, -0.013, 109.850, 0, 0, true, true, false, true, 2, true)
    Wait(250)
    bridge.natives.playAnimation(ped, 'amb@code_human_wander_texting_fat@male@base', 'static', -1, 1, 0.0)
    return true
end

local function washMoney(amount, slot)
    if not giveMoneyAnims() then return end
    local duration = Cfg.WashTimer * 1000
    if not bridge.interface.progress({
        duration = duration,
        label = locale('counting'),
        position = 'bottom',
        canCancel = false,
        disable = { move = true, combat = true, vehicle = true },
    }) then
        cleanupWashVisuals()
        return
    end

    if not ped or not prop then
        log('error', 'Wash visuals missing after progress')
        cleanupWashVisuals()
        return
    end

    local resp = lib.callback.await('r_moneywash:wash', false, amount, slot)
    if not resp or not resp.success then
        log('error', 'Failed to wash money, check server console for more information')
        cleanupWashVisuals()
        return
    end

    StopAnimTask(ped, 'amb@code_human_wander_texting_fat@male@base', 'static', 1.0)
    bridge.natives.playAnimation(ped, 'melee@holster', 'holster', -1, 0, 0.0)
    cleanupProp()
    Wait(500)
    takeMoneyAnims()
    bridge.interface.notify(locale('moneywash'), locale('washed', amount, resp.received), 'success')
    log('debug', 'Washed ' .. amount .. ' and received ' .. resp.received)
end

local function givePlayerOffer(amount, slot)
    log('debug', 'givePlayerOffer(' .. amount .. ', ' .. tostring(slot) .. ')')
    local tax = lib.callback.await('r_moneywash:getTax', false)
    local offer = math.ceil(amount - (amount * (tax / 100)))
    local alert = bridge.interface.alert({
        header = locale('moneywash'),
        content = locale('offer', offer, tax),
        centered = true,
        cancel = true
    })
    if alert == 'cancel' then
        if ped then
            PlayPedAmbientSpeechNative(ped, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE')
        end
        return
    end
    washMoney(amount, slot)
end

local function openMarkedBillSelection()
    local options = lib.callback.await('r_moneywash:getMarkedBills', false)
    if not options or #options == 0 then return end
    local menuOptions = {}
    for i = 1, #options do
        local entry = options[i]
        local worth = entry.worth
        local slot = entry.slot
        menuOptions[i] = {
            title = entry.label,
            description = locale('worth', worth),
            icon = 'fas fa-sack-dollar',
            iconColor = '#fa5252',
            onSelect = function()
                givePlayerOffer(worth, slot)
            end,
        }
    end
    bridge.interface.registerContext({ id = 'moneywash', title = locale('moneywash'), options = menuOptions })
    log('debug', 'Marked bill selection menu built with ' .. #menuOptions .. ' options')
    bridge.interface.showContext('moneywash')
end

local function openInput()
    if not ped then
        log('error', 'openInput called without ped')
        return
    end
    local resp = lib.callback.await('r_moneywash:canWash', false)
    if not resp or not resp.canWash then
        PlayPedAmbientSpeechNative(ped, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE')
        if resp and resp.err == 'on_cooldown' then
            bridge.interface.notify(locale('moneywash'), locale('on_cooldown', resp.cooldown or 0), 'error')
        elseif resp and resp.err then
            bridge.interface.notify(locale('moneywash'), locale(resp.err), 'error')
        end
        return
    end
    PlayPedAmbientSpeechNative(ped, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    if Cfg.Currency == 'markedbills' then
        openMarkedBillSelection()
        return
    end
    local input = bridge.interface.input(locale('moneywash'), {
        {
            type = 'number',
            label = locale('amount'),
            icon = 'dollar-sign',
            required = true,
            default = Cfg.MinAmount,
            min = Cfg.MinAmount,
            max = math.min(Cfg.MaxAmount, resp.count or 0),
        }
    })
    if not input or #input == 0 then return end
    givePlayerOffer(tonumber(input[1]))
end

local function despawnPed()
    if not ped then return end
    bridge.target.removeLocalEntity(ped)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    ped = nil
    log('debug', 'Moneywash ped despawned')
end

local function spawnPed()
    if ped then despawnPed() end
    local pedCfg = Cfg.Ped
    ped = bridge.natives.createPed(pedCfg.model, pedCfg.coords.xyz, pedCfg.coords.w, false)
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
    log('debug', 'Moneywash ped spawned at: ' .. tostring(pedCfg.coords))
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
    if spawner then return end
    local blip = Cfg.Blip
    local pedCfg = Cfg.Ped
    spawner = lib.points.new({
        coords = pedCfg.coords.xyz,
        heading = pedCfg.coords.w,
        distance = 150.0,
        onEnter = spawnPed,
        onExit = despawnPed
    })
    if blip.enabled then
        local blipCoords = Cfg.TeleportEnter.target
        blipId = bridge.natives.createBlip(blipCoords, blip.sprite, blip.color, blip.scale, locale('moneywash'))
        log('debug', 'Moneywash blip created at: ' .. tostring(blipCoords))
    end
    log('debug', 'Moneywash spawner initialized at: ' .. tostring(pedCfg.coords.xyz))
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

AddEventHandler(GetCurrentResourceName() .. ':clientConfigLoaded', function()
    if not bridge.framework.isPlayerLoaded() then return end
    onClientReady()
end)

AddEventHandler('onResourceStop', function(stopped)
    if stopped ~= GetCurrentResourceName() then return end
    for _, zoneId in pairs(teleporters) do
        bridge.target.removeZone(zoneId)
    end
    if spawner then
        spawner:remove()
        spawner = nil
    end
    if blipId then
        bridge.natives.removeBlip(blipId)
        blipId = nil
    end
    cleanupProp()
    despawnPed()
end)
