local entities = {}

local function taskNpcGiveEnvelope()
    Core.Natives.PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    Core.Natives.PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    SetTimeout(1000, function()
        AttachEntityToEntity(entities.envelope, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
        Core.Natives.PlayAnim(cache.ped, 'melee@holster', 'holster', 1000, 0, 0.0)
        SetTimeout(750, function()
            DeleteEntity(entities.envelope)
            PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE')
            _debug('[DEBUG] - Envelope given, player paid??')
        end)
    end)
end

lib.callback.register('r_moneywash:startWashingProgressBar', function()
    SetTimeout(750, function()
        Core.Natives.PlayAnim(entities.npc, 'anim@amb@casino@peds@',
            'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
        CreateThread(function()
            Wait(100)
            while true do
                if not IsEntityPlayingAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', 3) then
                    Core.Natives.PlayAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
                    break
                end
                Wait(0)
            end
        end)
    end)
    if lib.progressCircle({
            duration = Cfg.Options.WashTime * 1000,
            label = _L('counting_money'),
            position = 'bottom',
            canCancel = false,
            disable = { move = true, combat = true }
        }) then
        Core.Natives.PlayAnim(entities.npc, 'melee@holster', 'holster', 750, 0, 0.0)
        SetTimeout(500, function()
            local envelopeProp = 'prop_cash_envelope_01'
            entities.envelope = Core.Natives.CreateProp(envelopeProp, Cfg.Options.Location, 0.0, false)
            AttachEntityToEntity(entities.envelope, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
            DeleteEntity(entities.cash)
            taskNpcGiveEnvelope()
        end)
        _debug('[DEBUG] - Money counted, giving envelope')
        return true
    else
        return false
    end
end)

local function taskGiveNpcMoney(amount, metadata)
    local cashProp = 'prop_anim_cash_pile_02'
    entities.cash = Core.Natives.CreateProp(cashProp, Cfg.Options.Location, 0.0, false)
    AttachEntityToEntity(entities.cash, cache.ped, 90, 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
    Core.Natives.PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    Core.Natives.PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    TriggerServerEvent('r_moneywash:startWashingMoney', cache.serverId, amount, metadata)
    _debug('[DEBUG] - Money given, starting exchange')
    SetTimeout(750, function()
        AttachEntityToEntity(entities.cash, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0, 0, 0, 168.93, -83.80, 76.29, true, true, false, true, 2, true)
    end)
end

local function giveExchangeOffer(amount, metadata)
    local taxRate = lib.callback.await('r_moneywash:getTaxRate', false)
    local given = amount if metadata then given = metadata.worth end
    local offer = math.ceil(given - (given * taxRate / 100))
    local confirm = lib.alertDialog({
        header = _L('money_wash'),
        content = _L('taxed_offer', offer, taxRate),
        centered = true,
        cancel = true
    })
    if confirm == 'cancel' then return PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_INSULT_MED', 'SPEECH_PARAMS_FORCE') end
    taskGiveNpcMoney(amount, metadata)
    _debug('[DEBUG] - Exchange Offer Accepted')
end

local function buildMarkedBillsMenu()
    local options = {}
    ClearPedTasks(entities.npc)
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    local playerInventory = lib.callback.await('r_moneywash:getPlayerInventory', false)
    for _, item in pairs(playerInventory) do
        if item.name == Cfg.Options.Currency then
            table.insert(options, {
                title = item.label,
                description = _L('marked_worth', item.metadata.worth),
                icon = 'fas fa-money-bill-wave',
                iconColor = '#fa5252',
                onSelect = function()
                    giveExchangeOffer(item.count, item.metadata)
                end,
            })
        end
    end
    lib.registerContext({
        id = 'moneywash_markedbills',
        title = _L('money_wash'),
        options = options
    })
    lib.showContext('moneywash_markedbills')
    _debug('[DEBUG] - Marked Bills Menu Created')
end

local function openMoneyWashInput()
    local playerCash = lib.callback.await('r_moneywash:getInventoryItem', false, Cfg.Options.Currency)
    if playerCash.count < Cfg.Options.MinWash then return Core.Framework.Notify(_L('not_enough_money', Cfg.Options.MinWash), 'error') end
    if playerCash.count > Cfg.Options.MaxWash then playerCash.count = Cfg.Options.MaxWash end
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    local input = lib.inputDialog(_L('wash_money'), {
        { type = 'number', label = _L('wash_amount'), icon = 'dollar-sign', required = true, min = Cfg.Options.MinWash, max = playerCash.count },
    })
    if not input then return end
    giveExchangeOffer(tonumber(input[1]))
end

local function enterMoneyWash(door, coords)
    TaskAchieveHeading(cache.ped, door.w, 500)
    SetTimeout(500, function()
        if lib.progressCircle({
                duration = 1500,
                label = _L('entering_moneywash'),
                position = 'bottom',
                canCancel = true,
                anim = { dict = 'timetable@jimmy@doorknock@', clip = 'knockdoor_idle' },
                disable = { move = true, combat = true, }
            }) then
            DoScreenFadeOut(750)
            Wait(800)
            StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, coords.w - 180, false, true, true)
            Wait(300)
            DoScreenFadeIn(375)
        end
    end)
end

local function exitMoneyWash(door, coords)
    TaskAchieveHeading(cache.ped, door.w, 500)
    SetTimeout(500, function()
        if lib.progressCircle({
                duration = 1500,
                label = _L('exiting_moneywash'),
                position = 'bottom',
                canCancel = true,
                anim = { dict = 'mp_common', clip = 'givetake1_a' },
                disable = { move = true, combat = true }
            }) then
            DoScreenFadeOut(750)
            Wait(800)
            StartPlayerTeleport(cache.playerId, coords.x, coords.y, coords.z, coords.w - 180, false, true, true)
            Wait(300)
            DoScreenFadeIn(375)
        end
    end)
end

RegisterNetEvent('r_moneywash:onConnect', function()
    if Cfg.Options.Blip.Enabled and not entities.blip then
        local location = Cfg.Options.Location
        if Cfg.Options.Teleporter.Enabled then location = Cfg.Options.Teleporter.Entrance.xyz end
        entities.blip = Core.Natives.CreateBlip(location, Cfg.Options.Blip.Sprite, Cfg.Options.Blip.Color, Cfg.Options.Blip.Scale, Cfg.Options.Blip.Label, true)
        _debug('[DEBUG] - Blip Created')
    end
    if Cfg.Options.Teleporter.Enabled then
        Core.Target.AddBoxZone('moneywash_entrance', Cfg.Options.Teleporter.Entrance.xyz, vec3(1.5, 1.0, 3.0), Cfg.Options.Teleporter.Entrance.w, { {
            label = _L('enter_moneywash'),
            name = 'moneywash_entrance',
            icon = 'fas fa-money-bill-wave',
            distance = 1,
            onSelect = function()
                enterMoneyWash(Cfg.Options.Teleporter.Entrance, Cfg.Options.Teleporter.Exit)
            end
        } }, Cfg.Debug)
        Core.Target.AddBoxZone('moneywash_exit', Cfg.Options.Teleporter.Exit.xyz, vec3(1.4, 0.7, 2.1), Cfg.Options.Teleporter.Exit.w, { {
            label = _L('exit_moneywash'),
            name = 'moneywash_exit',
            icon = 'fas fa-door-open',
            distance = 1,
            onSelect = function()
                exitMoneyWash(Cfg.Options.Teleporter.Exit, Cfg.Options.Teleporter.Entrance)
            end
        } }, Cfg.Debug)
        _debug('[DEBUG] - Teleporter Created')
    end
end)

local locPoint = lib.points.new({ coords = Cfg.Options.Location, distance = 30 })

function locPoint:onEnter()
    entities.npc = Core.Natives.CreateNpc(Cfg.Options.PedModel, Cfg.Options.Location, Cfg.Options.PedHeading, false)
    while not DoesEntityExist(entities.npc) do Wait(0) end
    Core.Natives.SetEntityProperties(entities.npc, true, true, true)
    TaskStartScenarioInPlace(entities.npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Core.Target.AddLocalEntity(entities.npc, { {
        label = _L('wash_money'),
        icon = 'fas fa-money-bill-wave',
        distance = 2,
        onSelect = function()
            local onCooldown = lib.callback.await('r_moneywash:getPlayerCooldown', false)
            print(onCooldown)
            if onCooldown then Core.Framework.Notify(_L('on_cooldown'), 'info') return end
            if Cfg.Options.Currency == 'markedbills' then return buildMarkedBillsMenu() end
            openMoneyWashInput()
        end
    } })
    _debug('[DEBUG] - NPC Created')
end

function locPoint:onExit()
    for _, entity in pairs(entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    Core.Target.RemoveLocalEntity(entities.npc)
    _debug('[DEBUG] - NPC Removed')
end

AddEventHandler('onResourceStart', function(resource)
    if (GetCurrentResourceName() == resource) then
        TriggerEvent('r_moneywash:onConnect')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if (GetCurrentResourceName() == resource) then
        if entities.blip and DoesBlipExist(entities.blip) then RemoveBlip(entities.blip) end
        for _, entity in pairs(entities) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end
    end
end)