local QBCore = exports['qb-core']:GetCoreObject()

-- Player reputation storage (citizenid -> rep)
local PlayerReputation = {}

-- In-memory storage, could be replaced with database
-- Load reputation on player join
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    -- In production, load from database here
    if not PlayerReputation[citizenid] then
        PlayerReputation[citizenid] = Config.Reputation.startingRep
    end
end)

-- Save reputation on player leave
AddEventHandler('playerDropped', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- In production, save to database here
    end
end)

-- Get player's reputation
local function GetPlayerRep(citizenid)
    return PlayerReputation[citizenid] or Config.Reputation.startingRep
end

-- Get reputation tier based on rep amount
local function GetRepTier(rep)
    local tier = Config.Reputation.tiers[1] -- Default to first tier
    for _, t in ipairs(Config.Reputation.tiers) do
        if rep >= t.minRep then
            tier = t
        end
    end
    return tier
end

-- Calculate price based on reputation
local function CalculatePrice(itemName, citizenid)
    local item = Config.SellableItems[itemName]
    if not item then return nil end
    
    local rep = GetPlayerRep(citizenid)
    local tier = GetRepTier(rep)
    local basePrice = item.basePrice * tier.priceModifier
    
    -- Add some randomness (±10%)
    local randomMod = math.random(-10, 10) / 100
    return math.floor(basePrice * (1 + randomMod))
end

-- Get sellable items from player inventory
local function GetPlayerSellableItems(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end
    
    local items = {}
    local playerItems = Player.PlayerData.items
    
    for _, item in pairs(playerItems) do
        if item and item.amount > 0 and Config.SellableItems[item.name] then
            table.insert(items, {
                name = item.name,
                label = item.label or Config.SellableItems[item.name].label,
                amount = item.amount
            })
        end
    end
    
    return items
end

-- Server event: Get initial offer data
RegisterNetEvent('streetdeals:server:getOfferData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local rep = GetPlayerRep(citizenid)
    local tier = GetRepTier(rep)
    local items = GetPlayerSellableItems(src)
    
    if #items == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'You have nothing to sell', 'error')
        TriggerClientEvent('streetdeals:client:noItems', src)
        return
    end
    
    -- Pick random item from player's inventory
    local randomItem = items[math.random(1, #items)]
    local offerPrice = CalculatePrice(randomItem.name, citizenid)
    
    if not offerPrice then
        TriggerClientEvent('QBCore:Notify', src, 'Error calculating price', 'error')
        return
    end
    
    local offerData = {
        item = randomItem,
        offerPrice = offerPrice,
        reputation = rep,
        tierName = tier.name,
        priceModifier = tier.priceModifier,
        minPrice = Config.SellableItems[randomItem.name].minPrice,
        maxPrice = Config.SellableItems[randomItem.name].maxPrice
    }
    
    TriggerClientEvent('streetdeals:client:receiveOffer', src, offerData)
end)

-- Server event: Accept offer
RegisterNetEvent('streetdeals:server:acceptOffer', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Verify player has item
    local item = Player.Functions.GetItemByName(data.itemName)
    if not item or item.amount < data.amount then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough of that item', 'error')
        return
    end
    
    -- Remove item
    local removed = Player.Functions.RemoveItem(data.itemName, data.amount)
    if not removed then
        TriggerClientEvent('QBCore:Notify', src, 'Failed to complete transaction', 'error')
        return
    end
    
    -- Add money
    local totalPrice = data.offerPrice * data.amount
    Player.Functions.AddMoney('cash', totalPrice, 'street-deal')
    
    -- Add reputation
    local newRep = GetPlayerRep(citizenid) + Config.Reputation.repGainOnSuccess
    PlayerReputation[citizenid] = newRep
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, 
        string.format('Sold %dx %s for $%d (+%d rep)', 
            data.amount, data.itemLabel, totalPrice, Config.Reputation.repGainOnSuccess), 
        'success')
    
    -- Send updated rep to client
    TriggerClientEvent('streetdeals:client:dealComplete', src, {
        success = true,
        totalPrice = totalPrice,
        newRep = newRep,
        tier = GetRepTier(newRep)
    })
end)

-- Server event: Reject offer
RegisterNetEvent('streetdeals:server:rejectOffer', function()
    local src = source
    -- No rep loss for rejecting initial offer
    TriggerClientEvent('QBCore:Notify', src, 'Deal rejected', 'primary')
    TriggerClientEvent('streetdeals:client:dealComplete', src, { success = false, reason = 'rejected' })
end)

-- Server event: Negotiate price
RegisterNetEvent('streetdeals:server:negotiatePrice', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local rep = GetPlayerRep(citizenid)
    
    -- Calculate success chance based on reputation
    local successChance = Config.Reputation.negotiation.baseSuccessChance + math.floor(rep / 50)
    successChance = math.min(successChance, Config.Reputation.negotiation.maxSuccessChance)
    
    -- Roll for success
    local roll = math.random(1, 100)
    local success = roll <= successChance
    
    local newPrice
    local repChange = 0
    
    if success then
        -- Price increases
        local increase = data.offerPrice * (Config.Reputation.negotiation.priceIncreasePercent / 100)
        newPrice = math.floor(data.offerPrice + increase)
        newPrice = math.min(newPrice, Config.SellableItems[data.itemName].maxPrice)
        repChange = Config.Reputation.repGainOnNegotiationSuccess
    else
        -- Price decreases, NPC is annoyed
        local decrease = data.offerPrice * (Config.Reputation.negotiation.priceDecreasePercent / 100)
        newPrice = math.floor(data.offerPrice - decrease)
        newPrice = math.max(newPrice, Config.SellableItems[data.itemName].minPrice)
        repChange = -Config.Reputation.repLossOnNegotiationFail
    end
    
    -- Update reputation
    local newRep = math.max(0, GetPlayerRep(citizenid) + repChange)
    PlayerReputation[citizenid] = newRep
    
    -- Notify based on result
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Negotiation successful! Price increased!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Negotiation failed. NPC lowered their offer!', 'error')
    end
    
    -- Send result to client
    TriggerClientEvent('streetdeals:client:negotiationResult', src, {
        success = success,
        newPrice = newPrice,
        repChange = repChange,
        newRep = newRep,
        tier = GetRepTier(newRep)
    })
end)

-- Server event: Get player reputation
RegisterNetEvent('streetdeals:server:getReputation', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local rep = GetPlayerRep(citizenid)
    local tier = GetRepTier(rep)
    
    TriggerClientEvent('streetdeals:client:reputationData', src, {
        rep = rep,
        tierName = tier.name,
        priceModifier = tier.priceModifier
    })
end)

-- Exports for external use
exports('GetPlayerRep', function(citizenid)
    return GetPlayerRep(citizenid)
end)

exports('GetRepTier', function(rep)
    return GetRepTier(rep)
end)
