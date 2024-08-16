if GetResourceState('ox_target') ~= 'started' then return end

local ox_target = exports.ox_target

Target = {
    AddLocalEntity = function(entities, options)
        ox_target:addLocalEntity(entities, options)
    end,

    AddModel = function(models, options)
        ox_target:addModel(models, options)
    end,

    AddBoxZone = function(name, coords, size, heading, options)
        ox_target:addBoxZone({
            coords = coords,
            size = size,
            rotation = heading,
            debug = Cfg.Debug.Targets,
            options = options
        })
    end,

    RemoveLocalEntity = function(entity)
        ox_target:removeLocalEntity(entity)
    end,

    RemoveModel = function(model)
        ox_target:removeModel(model)
    end,

    RemoveZone = function(name)
        ox_target:removeZone(name)
    end
}