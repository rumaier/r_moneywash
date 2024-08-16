if GetResourceState('ox_inventory') ~= 'started' then return end

local ox_inventory = exports.ox_inventory

Inventory = {
    OpenStash = function(id)
        ox_inventory:openInventory('stash', id)
    end,
    
    GetItemInfo = function(item)
        return ox_inventory:Items(item)
    end,
}