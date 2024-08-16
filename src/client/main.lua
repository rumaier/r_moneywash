local entities = {}
local cfg = Cfg.Options

local function taskNpcGiveEnvelope()
    local envelopeProp = 'prop_cash_envelope_01'
    entities.envelope = CreateProp(envelopeProp, cfg.Location, 0.0, false)
    AttachEntityToEntity(entities.envelope, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    SetTimeout(1000, function()
        AttachEntityToEntity(entities.envelope, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
        PlayAnim(cache.ped, 'melee@holster', 'holster', 1000, 0, 0.0)
        SetTimeout(750, function()
            DeleteEntity(entities.envelope)
            PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_THANKS', 'SPEECH_PARAMS_FORCE')
            debug('[DEBUG] - Envelope given, player paid??')
        end)
    end)
end

lib.callback.register('r_moneywash:startWashingProgressBar', function()
    PlayAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
    CreateThread(function()
        Wait(100) -- Wait for the animation to start
        while true do 
            if not IsEntityPlayingAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', 3) then
                PlayAnim(entities.npc, 'anim@amb@casino@peds@', 'amb_world_human_leaning_male_wall_back_texting_idle_a', -1, 0, 0.0)
                break
            end
            Wait(0)
        end
    end)
    if lib.progressCircle({
            duration = cfg.WashTime * 1000,
            label = _L('counting_money'),
            position = 'bottom',
            canCancel = false,
            disable = { move = true, combat = true }
        }) then
        PlayAnim(entities.npc, 'melee@holster', 'holster', 750, 0, 0.0)
        SetTimeout(500, function()
            DeleteEntity(entities.cash)
            taskNpcGiveEnvelope()
        end)
        debug('[DEBUG] - Money counted, giving envelope')
        return true
    else
        return false
    end
end)

local function taskGiveNpcMoney(amount, metadata)
    local cashProp = 'prop_anim_cash_pile_02'
    entities.cash = CreateProp(cashProp, cfg.Location, false)
    AttachEntityToEntity(entities.cash, cache.ped, 90, 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
    PlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    PlayAnim(entities.npc, 'mp_common', 'givetake1_a', 1000, 0, 0.0)
    SetTimeout(750, function()
        AttachEntityToEntity(entities.cash, entities.npc, GetPedBoneIndex(entities.npc, 28422), 0.003, 0.008, 0.015, 44.108, 29.315, 20.733, true, true, false, true, 2, true)
        TriggerServerEvent('r_moneywash:startWashingMoney', cache.serverId, amount, metadata)
        debug('[DEBUG] - Money given, starting exchange')
    end)
end

local function giveExchangeOffer(amount, metadata)
    local taxRate = lib.callback.await('r_moneywash:getCurrentTaxRate', false)
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
    debug('[DEBUG] - Exchange Offer Accepted')
end

local function buildMarkedBillsMenu()
    local options = {}
    ClearPedTasks(entities.npc)
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    local playerInventory = lib.callback.await('r_moneywash:getPlayerInventory', false)
    for _, item in pairs(playerInventory) do
        if item.name == cfg.Currency then
            table.insert(options, {
                title = item.label,
                description = _L('marked_worth', item.metadata.worth),
                icon = 'fas fa-money-bill-wave',
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
    debug('[DEBUG] - Marked Bills Menu Created')
end

local function openMoneyWashInput()
    ClearPedTasks(entities.npc)
    PlayPedAmbientSpeechNative(entities.npc, 'GENERIC_HOWS_IT_GOING', 'SPEECH_PARAMS_FORCE')
    local playerCash = lib.callback.await('r_moneywash:getInventoryItem', false, cfg.Currency)
    if playerCash.count > cfg.MaxWash then playerCash.count = cfg.MaxWash end
    local input = lib.inputDialog(_L('wash_money'), {
        { type = 'number', label = _L('wash_amount'), icon = 'dollar-sign', required = true, min = 1, max = playerCash.count },
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
    if cfg.Blip.Enabled and not entities.blip then
        local location = cfg.Location
        if cfg.Teleporter.Enabled then location = cfg.Teleporter.Entrance.xyz end
        entities.blip = CreateBlip(location, cfg.Blip.Sprite, cfg.Blip.Scale, cfg.Blip.Color, 4, cfg.Blip.Label)
        debug('[DEBUG] - Blip Created')
    end
    if cfg.Teleporter.Enabled then
        Target.AddBoxZone('moneywash_entrance', cfg.Teleporter.Entrance.xyz, vec3(1.5, 1.0, 3.0), cfg.Teleporter.Entrance.w, { {
            label = _L('enter_moneywash'),
            name = 'moneywash_entrance',
            icon = 'fas fa-money-bill-wave',
            distance = 1,
            onSelect = function()
                enterMoneyWash(cfg.Teleporter.Entrance, cfg.Teleporter.Exit)
            end
        } })
        Target.AddBoxZone('moneywash_exit', cfg.Teleporter.Exit.xyz, vec3(1.4, 0.7, 2.1), cfg.Teleporter.Exit.w, { {
            label = _L('exit_moneywash'),
            name = 'moneywash_exit',
            icon = 'fas fa-door-open',
            distance = 1,
            onSelect = function()
                exitMoneyWash(cfg.Teleporter.Exit, cfg.Teleporter.Entrance)
            end
        } })
        debug('[DEBUG] - Teleporter Created')
    end
end)

local locPoint = lib.points.new({ coords = cfg.Location, distance = 30 })

function locPoint:onEnter()
    entities.npc = CreateNPC(cfg.PedModel, cfg.Location, cfg.PedHeading, false)
    while not DoesEntityExist(entities.npc) do Wait(0) end
    SetNPCProperties(entities.npc, true, true, true)
    TaskStartScenarioInPlace(entities.npc, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Target.AddLocalEntity(entities.npc, { {
        label = _L('wash_money'),
        icon = 'fas fa-money-bill-wave',
        distance = 1,
        onSelect = function()
            local onCooldown = lib.callback.await('r_moneywash:getPlayerCooldown', false)
            if onCooldown then Framework.Notify(_L('on_cooldown'), 'info') return end
            if cfg.Currency == 'markedbills' then return buildMarkedBillsMenu() end
            openMoneyWashInput()
        end
    } })
    debug('[DEBUG] - NPC Created')
end

function locPoint:onExit()
    for _, entity in pairs(entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    Target.RemoveLocalEntity(entities.npc)
    debug('[DEBUG] - NPC Removed')
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        TriggerEvent('r_moneywash:onConnect')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        if entities.blip and DoesBlipExist(entities.blip) then RemoveBlip(entities.blip) end
        for _, entity in pairs(entities) do
            if DoesEntityExist(entity) then DeleteEntity(entity) end
        end
    end
end)

---@param display integer -- [2: Map and minimap] [4: Only map]
function CreateBlip(coords, sprite, scale, color, display, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

function CreateProp(model, coords, heading, isNetwork)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local entity = CreateObject(model, coords.x, coords.y, coords.z, isNetwork, false, false)
    SetEntityHeading(entity, heading)
    SetModelAsNoLongerNeeded(model)
    return entity
end

function CreateNPC(model, coords, heading, isNetwork)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, heading, isNetwork, false)
    SetModelAsNoLongerNeeded(model)
    return ped
end

function SetNPCProperties(entity, freeze, invincible, oblivious)
    FreezeEntityPosition(entity, freeze)
    SetEntityInvincible(entity, invincible)
    SetBlockingOfNonTemporaryEvents(entity, oblivious)
end

function PlayAnim(ped, dict, anim, duration, flag, playbackRate)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, duration, flag, playbackRate, false, false, false)
end

function debug(...)
    if Cfg.Debug.Prints then
        print(...)
    end
end