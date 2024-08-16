if GetResourceState('qs-inventory') ~= 'started' then return end

RegisterCommand('test', function(src)
end, false)

Inventory = {
    OpenStash = function(id)
        exports['qs-inventory']:RegisterStash(id, 50, 50000)
    end,

    GetItemInfo = function(item)
        local itemsLua = exports['qs-inventory']:GetItemList()
        if not itemsLua[item] then return end
        return itemsLua[item]
    end,
}
