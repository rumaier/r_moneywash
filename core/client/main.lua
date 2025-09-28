local blip = nil
local point = nil
local targets = {}
local entities = {}

local function taskGiveMoneyAnimation()
    local prop = 'prop_anim_cash_pile_02'
    entities.cashProp = Core.Natives.createObject(prop, vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(entities.cashProp, cache.ped, 90, 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
    Core.Natives.playAnimation(cache.ped, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    Core.Natives.playAnimation(entities.moneywashPed, 'mp_common', 'givetake1_a', -1, 1, 0.0)
    Wait(750)
    AttachEntityToEntity(entities.cashProp, entities.moneywashPed, GetPedBoneIndex(entities.moneywashPed, 28422), -0.015, -0.009, -0.013, 109.850, 0, 0, true, true, false, true, 2, true)
    Core.Natives.playAnimation(entities.moneywashPed, 'amb@code_human_wander_texting_fat@male@base', 'static', -1, 1, 0.0)
end

local function taskNpcGiveEnvelopeAnimation()
    local prop = 'prop_cash_envelope_01'
    entities.envelopeProp = Core.Natives.createObject(prop, vec3(0, 0, 0), 0, false)
    AttachEntityToEntity(entities.envelopeProp, entities.moneywashPed, GetPedBoneIndex(entities.moneywashPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    Core.Natives.playAnimation(cache.ped, 'mp_common', 'givetake1_a', -1, 1, 0.0)
    Core.Natives.playAnimation(entities.moneywashPed, 'mp_common', 'givetake1_a', -1, 0, 0.0)
    Wait(750)
    AttachEntityToEntity(entities.envelopeProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    Core.Natives.playAnimation(cache.ped, 'melee@holster', 'holster', -1, 0, 0.0)
    DeleteEntity(entities.envelopeProp)
end

local function triggerMoneywash(amount)
    taskGiveMoneyAnimation()
    local removed = lib.callback.await('r_moneywash:removeMoney', false, amount)
    if not removed then _debug('[^6DEBUG^0] - Failed to remove currency item from player.') return end
    amount = type(amount) == 'table' and amount.worth or amount
    local duration = Cfg.Options.MoneyWash.timer * 1000
    if lib.progressCircle({
        duration = duration,
        label = _L('counting_money'),
        position = 'bottom',
        canCancel = false,
        disable = { move = true, combat = true }
    }) then
        StopAnimTask(cache.ped, 'amb@code_human_wander_texting_fat@male@base', 'static', 1.0)
        Core.Natives.playAnimation(entities.moneywashPed, 'melee@holster', 'holster', -1, 0, 0.0)
        DeleteEntity(entities.cashProp)
        Wait(500)
        taskNpcGiveEnvelopeAnimation()
        local added = lib.callback.await('r_moneywash:addMoney', false)
        if not added then _debug('[^6DEBUG^0] - Failed to give player funds, check server console for details.') return end
        Core.Interface.notify(_L('notify_title'), _L('wash_successful', added), 'success')
        _debug('[^6DEBUG^0] - Successfully washed funds worth:', amount, 'after tax:', added)
    end
end

local function giveExchangeOffer(amount)
    local taxRate = lib.callback.await('r_moneywash:getCurrentTaxRate', false)
    local given = type(amount) == 'table' and amount.worth or amount
    local offer = math.ceil(given - (given * (taxRate / 100)))
    local alert = lib.alertDialog({
        header = _L('wash_money'),
        content = _L('taxed_offer', offer, taxRate),
        centered = true,
        cancel = true
    })
    if alert == 'cancel' then
        PlayPedAmbientSpeechNative(entities.moneywashPed, 'Generic_Insult_Med', 'Speech_Params_Force')
        return
    end
    triggerMoneywash(amount)
end

local function openMarkedBillsMenu()
    local options = {}
    local items = lib.callback.await('r_moneywash:getMarkedBillItems', false)
    if not items then _debug('[^1ERROR^0] - Failed to retrieve marked bills from player inventory.') return end
    for _, item in pairs(items) do
        table.insert(options, {
            title = item.label,
            description = _L('marked_worth', item.metadata.worth),
            icon = 'fas fa-money-bill-wave',
            iconColor = '#fa5252',
            onSelect = function()
                giveExchangeOffer(item.metadata)
            end
        })
    end
    Core.Interface.registerContext({ id = 'markedbill_menu', title = _L('wash_money'), options = options })
    _debug('[^6DEBUG^0] - Built marked bills menu with', #options, 'options, opening...')
    Core.Interface.showContext('markedbill_menu')
end

local function openMoneywashInput()
    local canWash, reason = lib.callback.await('r_moneywash:canPlayerWash', false) -- reason will return item count if canWash is true
    if not canWash then Core.Interface.notify(_L('notify_title'), reason, 'error') return end
    ClearPedTasks(entities.moneywashPed)
    PlayPedAmbientSpeechNative(entities.moneywashPed, 'Generic_Hows_It_Going', 'Speech_Params_Force')
    local wash = Cfg.Options.MoneyWash
    local isMarkedBills = wash.currency == 'markedbills'
    if isMarkedBills then openMarkedBillsMenu() return end
    local input = lib.inputDialog(_L('wash_money'), {
        { type = 'number', label = _L('wash_amount'), icon = 'dollar-sign', required = true, min = wash.min, max = math.min(reason, wash.max) }
    })
    if not input then return end
    _debug('[^6DEBUG^0] - Player input received:', input[1])
    giveExchangeOffer(tonumber(input[1]))
end

local function spawnMoneywashPed()
    if entities.moneywashPed and DoesEntityExist(entities.moneywashPed) then return end
    local pedCfg = Cfg.Options.WashPed
    entities.moneywashPed = Core.Natives.createPed(pedCfg.model, pedCfg.location.xyz, pedCfg.location.w, false)
    Core.Natives.setEntityProperties(entities.moneywashPed, true, true, true)
    TaskStartScenarioInPlace(entities.moneywashPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Core.Target.addLocalEntity(entities.moneywashPed, {
        {
            label = _L('wash_money'),
            icon = 'fas fa-money-bill-wave',
            distance = 1.5,
            onSelect = openMoneywashInput
        }
    })
    _debug('[^6DEBUG^0] - Moneywash ped spawned at:', pedCfg.location)
end

local function despawnMoneywashPed()
    if entities.moneywashPed and DoesEntityExist(entities.moneywashPed) then
        Core.Target.removeLocalEntity(entities.moneywashPed)
        DeleteEntity(entities.moneywashPed)
        entities.moneywashPed = nil
        _debug('[^6DEBUG^0] - Moneywash ped despawned.')
    end
end

local function teleportToEntrance()
    local teleporter = Cfg.Options.Teleporter
    TaskAchieveHeading(cache.ped, teleporter.exit.w, -1)
    if lib.progressCircle({
            duration = 1500,
            label = _L('exiting'),
            position = 'bottom',
            canCancel = false,
            anim = { dict = 'mp_common', clip = 'givetake1_a' },
            disable = { move = true, combat = true, }
        }) then
        Core.Target.removeZone(targets.exit)
        targets.exit = nil
        DoScreenFadeOut(750)
        Wait(800)
        StartPlayerTeleport(cache.playerId, teleporter.enter.xyz, teleporter.enter.w - 180.0, false, true, true)
        Wait(300)
        DoScreenFadeIn(375)
    end
end

local function teleportToMoneywash()
    local teleporter = Cfg.Options.Teleporter
    TaskAchieveHeading(cache.ped, teleporter.enter.w, -1)
    if lib.progressCircle({
        duration = 1500,
        label = _L('entering'),
        position = 'bottom',
        canCancel = false,
        anim = { dict = 'timetable@jimmy@doorknock@', clip = 'knockdoor_idle' },
        disable = { move = true, combat = true, }
        }) then
        DoScreenFadeOut(750)
        Wait(800)
        StartPlayerTeleport(cache.playerId, teleporter.exit.xyz, teleporter.exit.w - 180.0, false, true, true)
        Wait(300)
        DoScreenFadeIn(375)
    end
end

local function initializeTeleporters()
    local teleporter = Cfg.Options.Teleporter
    if not teleporter.enabled then return end
    targets.entrance = Core.Target.addBoxZone(teleporter.enter.xyz, vec3(1.5, 1.0, 3.0), teleporter.enter.w, {
        {
            label = _L('teleporter_enter'),
            icon = 'fas fa-money-bill-wave',
            distance = 1.5,
            onSelect = teleportToMoneywash
        }
    }, Cfg.Debug)
    _debug('[^6DEBUG^0] - Teleporter entrance set at:', teleporter.enter)
    targets.exit = Core.Target.addBoxZone(teleporter.exit.xyz, vec3(1.5, 1.0, 3.0), teleporter.exit.w, {
        {
            label = _L('teleporter_exit'),
            icon = 'fas fa-money-bill-wave',
            distance = 1.5,
            onSelect = teleportToEntrance
        }
    }, Cfg.Debug)
    _debug('[^6DEBUG^0] - Teleporter exit set at:', teleporter.exit)
end

function InitializeMoneywash()
    initializeTeleporters()
    local blipCfg = Cfg.Options.Blip
    local pedCfg = Cfg.Options.WashPed
    point = lib.points.new({ 
        coords = pedCfg.location.xyz, 
        distance = 100.0,
        onEnter = spawnMoneywashPed,
        onExit = despawnMoneywashPed
    })
    if blipCfg.enabled then
        blip = Core.Natives.createBlip(pedCfg.location, blipCfg.sprite, blipCfg.color, blipCfg.scales, blipCfg.label)
        _debug('[^6DEBUG^0] - Moneywash blip created at:', pedCfg.location)
    end
    _debug('[^6DEBUG^0] - Moneywash point initialized at:', pedCfg.location)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, target in pairs(targets) do Core.Target.removeZone(target) end
        for _, entity in pairs(entities) do DeleteEntity(entity) end
        if blip then Core.Natives.removeBlip(blip) end
        if point then point:remove() end
    end
end)