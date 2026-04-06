local QBCore = exports['qb-core']:GetCoreObject()
local currentNPC = nil
local currentNPCData = nil
local isDealing = false
local lastApproachTime = 0
local currentOffer = nil

-- Check if player is in blacklist zone
local function IsInBlacklistZone(coords)
    for _, zone in ipairs(Config.BlacklistZones) do
        local dist = #(coords - zone.coords)
        if dist < zone.radius then
            return true
        end
    end
    return false
end

-- Check if player has sellable items
local function HasSellableItems()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.items then return false end
    
    for _, item in pairs(PlayerData.items) do
        if item and item.amount > 0 and Config.SellableItems[item.name] then
            return true
        end
    end
    return false
end

-- Spawn NPC and make them approach player
local function SpawnApproachingNPC()
    if currentNPC and DoesEntityExist(currentNPC) then
        DeleteEntity(currentNPC)
    end
    currentNPC = nil
    currentNPCData = nil
    
    -- Select random NPC based on spawn chances
    local totalChance = 0
    local roll = math.random(1, 100)
    local selectedNPC = Config.NPCs[1]
    
    local cumulative = 0
    for _, npc in ipairs(Config.NPCs) do
        cumulative = cumulative + npc.spawnChance
        if roll <= cumulative then
            selectedNPC = npc
            break
        end
    end
    
    local hash = GetHashKey(selectedNPC.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    -- Spawn NPC behind player
    local spawnOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -8.0, 0.0)
    local spawnZ = spawnOffset.z
    
    -- Get ground Z
    local found, groundZ = GetGroundZFor_3dCoord(spawnOffset.x, spawnOffset.y, spawnOffset.z + 1.0, false)
    if found then spawnZ = groundZ end
    
    currentNPC = CreatePed(4, hash, spawnOffset.x, spawnOffset.y, spawnZ, playerHeading, false, true)
    SetModelAsNoLongerNeeded(hash)
    
    -- Configure NPC
    SetEntityAsMissionEntity(currentNPC, true, true)
    SetBlockingOfNonTemporaryEvents(currentNPC, true)
    SetPedFleeAttributes(currentNPC, 0, false)
    SetPedKeepTask(currentNPC, true)
    
    -- Make NPC walk to player
    TaskGoToEntity(currentNPC, playerPed, -1, 2.0, 1.0, 1073741824, 0)
    
    -- Store NPC data
    currentNPCData = selectedNPC
    
    -- Wait for NPC to reach player
    CreateThread(function()
        local timeout = 0
        local maxTimeout = 15000 -- 15 seconds max
        
        while DoesEntityExist(currentNPC) and timeout < maxTimeout do
            local npcCoords = GetEntityCoords(currentNPC)
            local dist = #(npcCoords - playerCoords)
            
            -- NPC is close enough
            if dist < 3.0 then
                -- Stop and face player
                TaskTurnPedToFaceEntity(currentNPC, playerPed, -1)
                Wait(500)
                
                -- Trigger interaction
                if not isDealing and HasSellableItems() then
                    isDealing = true
                    TriggerServerEvent('streetdeals:server:getOfferData')
                    
                    -- Show NPC greeting
                    QBCore.Functions.Notify(currentNPCData.name .. ': "' .. currentNPCData.greeting .. '"', 'primary', 6000)
                end
                break
            end
            
            -- Player moved too far away
            if dist > 50.0 then
                if DoesEntityExist(currentNPC) then
                    DeleteEntity(currentNPC)
                end
                currentNPC = nil
                currentNPCData = nil
                break
            end
            
            Wait(500)
            timeout = timeout + 500
            playerPed = PlayerPedId()
            playerCoords = GetEntityCoords(playerPed)
        end
    end)
    
    return true
end

-- Clean up NPC
local function CleanupNPC()
    if currentNPC and DoesEntityExist(currentNPC) then
        -- Make NPC walk away
        if currentNPCData then
            QBCore.Functions.Notify(currentNPCData.name .. ': "' .. currentNPCData.walkAwayDialogue .. '"', 'primary', 4000)
        end
        
        ClearPedTasks(currentNPC)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local behindCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -20.0, 0.0)
        TaskGoToCoordAnyMeans(currentNPC, behindCoords.x, behindCoords.y, behindCoords.z, 2.0, 0, false, 786603, 0xbf800000)
        
        -- Delete after walking away
        CreateThread(function()
            Wait(8000)
            if DoesEntityExist(currentNPC) then
                DeleteEntity(currentNPC)
            end
            currentNPC = nil
            currentNPCData = nil
        end)
    else
        currentNPC = nil
        currentNPCData = nil
    end
end

-- Main thread for NPC spawning
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Skip if in blacklist zone
        if IsInBlacklistZone(playerCoords) then
            Wait(10000)
            goto continue
        end
        
        -- Skip if already dealing or NPC exists
        if isDealing or (currentNPC and DoesEntityExist(currentNPC)) then
            goto continue
        end
        
        -- Check cooldown
        local currentTime = GetGameTimer()
        if (currentTime - lastApproachTime) < (Config.ApproachCooldown * 1000) then
            goto continue
        end
        
        -- Random chance for NPC to approach
        if math.random(1, 100) <= 15 then -- 15% chance every check
            -- Check if player has sellable items
            if HasSellableItems() then
                SpawnApproachingNPC()
                lastApproachTime = GetGameTimer()
            end
        end
        
        ::continue::
    end
end)

-- Command to manually trigger NPC approach (for testing)
RegisterCommand('spawndealer', function()
    if not isDealing and HasSellableItems() then
        SpawnApproachingNPC()
        lastApproachTime = GetGameTimer()
    elseif not HasSellableItems() then
        QBCore.Functions.Notify('You have nothing to sell', 'error')
    else
        QBCore.Functions.Notify('You\'re already in a deal', 'error')
    end
end, false)

-- Command to check reputation
RegisterCommand('sellrep', function()
    TriggerServerEvent('streetdeals:server:getReputation')
end, false)

-- Event: Receive offer data from server
RegisterNetEvent('streetdeals:client:receiveOffer', function(offerData)
    currentOffer = offerData
    offerData.npcName = currentNPCData.name
    offerData.npcDialogue = {
        accept = currentNPCData.acceptDialogue,
        reject = currentNPCData.rejectDialogue
    }
    
    NUI.Open(offerData)
end)

-- Event: No items to sell
RegisterNetEvent('streetdeals:client:noItems', function()
    isDealing = false
    CleanupNPC()
end)

-- Event: Deal complete
RegisterNetEvent('streetdeals:client:dealComplete', function(data)
    isDealing = false
    currentOffer = nil
    
    if currentNPC and DoesEntityExist(currentNPC) and currentNPCData then
        if data.success then
            QBCore.Functions.Notify(currentNPCData.name .. ': "' .. currentNPCData.acceptDialogue .. '"', 'success', 4000)
        end
    end
    
    Wait(2000)
    NUI.Close()
    CleanupNPC()
end)

-- Event: Negotiation result
RegisterNetEvent('streetdeals:client:negotiationResult', function(data)
    if currentOffer then
        currentOffer.offerPrice = data.newPrice
        currentOffer.reputation = data.newRep
        currentOffer.tierName = data.tier.name
    end
    
    -- Update UI with new price
    NUI.SendMessage('priceUpdate', {
        newPrice = data.newPrice,
        success = data.success,
        repChange = data.repChange,
        newRep = data.newRep,
        tierName = data.tier.name
    })
end)

-- Event: Reputation data
RegisterNetEvent('streetdeals:client:reputationData', function(data)
    QBCore.Functions.Notify(string.format('Reputation: %d (%s) - %.0f%% prices', 
        data.rep, data.tierName, data.priceModifier * 100), 'primary', 5000)
end)

-- NUI Callbacks
RegisterNuiCallback('acceptOffer', function(data, cb)
    if currentOffer then
        TriggerServerEvent('streetdeals:server:acceptOffer', {
            itemName = currentOffer.item.name,
            itemLabel = currentOffer.item.label,
            amount = currentOffer.item.amount,
            offerPrice = currentOffer.offerPrice
        })
    end
    cb({ success = true })
end)

RegisterNuiCallback('rejectOffer', function(data, cb)
    if currentNPC and DoesEntityExist(currentNPC) and currentNPCData then
        QBCore.Functions.Notify(currentNPCData.name .. ': "' .. currentNPCData.rejectDialogue .. '"', 'error', 4000)
    end
    TriggerServerEvent('streetdeals:server:rejectOffer')
    cb({ success = true })
end)

RegisterNuiCallback('negotiatePrice', function(data, cb)
    if currentOffer then
        TriggerServerEvent('streetdeals:server:negotiatePrice', {
            itemName = currentOffer.item.name,
            offerPrice = currentOffer.offerPrice
        })
    end
    cb({ success = true })
end)

RegisterNuiCallback('close', function(data, cb)
    if isDealing then
        TriggerServerEvent('streetdeals:server:rejectOffer')
    end
    cb({ success = true })
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentNPC and DoesEntityExist(currentNPC) then
            DeleteEntity(currentNPC)
        end
        currentNPC = nil
        currentNPCData = nil
        NUI.Close()
    end
end)
