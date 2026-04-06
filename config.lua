Config = {}

-- Debug mode (shows extra prints)
Config.Debug = false

-- How often NPCs can approach (in seconds)
Config.ApproachCooldown = 60

-- Maximum distance for NPC to approach player
Config.MaxApproachDistance = 30.0

-- NPC Configuration
Config.NPCs = {
    {
        model = "a_m_y_street_01",
        name = "Street Dealer",
        greeting = "Yo, I heard you got some good stuff. Wanna make a deal?",
        rejectDialogue = "Aight, your loss homie.",
        acceptDialogue = "Pleasure doing business.",
        walkAwayDialogue = "Maybe another time then.",
        -- Chance for this NPC type to spawn (1-100)
        spawnChance = 40
    },
    {
        model = "a_m_m_indian_01",
        name = "Street Vendor",
        greeting = "Excuse me friend, I am looking for certain items. Can you help?",
        rejectDialogue = "No problem, maybe next time.",
        acceptDialogue = "Thank you, here is your money.",
        walkAwayDialogue = "Alright, take care.",
        spawnChance = 30
    },
    {
        model = "a_m_y_hipster_01",
        name = "College Kid",
        greeting = "Hey man, you wouldn't happen to have... you know? I got cash.",
        rejectDialogue = "Cool, cool, no worries.",
        acceptDialogue = "Thanks dude, you're a lifesaver!",
        walkAwayDialogue = "Later then.",
        spawnChance = 20
    },
    {
        model = "a_f_y_business_01",
        name = "Business Woman",
        greeting = "I'm in need of some... discretionary items. Are you selling?",
        rejectDialogue = "I understand, have a good day.",
        acceptDialogue = "Excellent, pleasure doing business.",
        walkAwayDialogue = "Perhaps another time then.",
        spawnChance = 10
    }
}

-- Items that can be sold
Config.SellableItems = {
    -- Drugs
    ["weed_brick"] = {
        label = "Weed Brick",
        basePrice = 50,
        minPrice = 30,
        maxPrice = 80,
        category = "drugs"
    },
    ["cocaine"] = {
        label = "Cocaine",
        basePrice = 150,
        minPrice = 100,
        maxPrice = 250,
        category = "drugs"
    },
    ["meth"] = {
        label = "Meth",
        basePrice = 200,
        minPrice = 150,
        maxPrice = 350,
        category = "drugs"
    },
    ["ecstasy"] = {
        label = "Ecstasy",
        basePrice = 75,
        minPrice = 50,
        maxPrice = 120,
        category = "drugs"
    },
    
    -- Stolen Items
    ["jewelry"] = {
        label = "Jewelry",
        basePrice = 100,
        minPrice = 60,
        maxPrice = 180,
        category = "stolen"
    },
    ["electronics"] = {
        label = "Electronics",
        basePrice = 80,
        minPrice = 40,
        maxPrice = 150,
        category = "stolen"
    },
    ["watch"] = {
        label = "Watch",
        basePrice = 120,
        minPrice = 70,
        maxPrice = 200,
        category = "stolen"
    },
    
    -- Contraband
    ["cigarettes"] = {
        label = "Cigarettes",
        basePrice = 30,
        minPrice = 20,
        maxPrice = 50,
        category = "contraband"
    },
    ["alcohol"] = {
        label = "Alcohol",
        basePrice = 40,
        minPrice = 25,
        maxPrice = 70,
        category = "contraband"
    }
}

-- Reputation System
Config.Reputation = {
    -- Reputation tiers
    tiers = {
        { name = "Rookie", minRep = 0, priceModifier = 0.8 },      -- 80% of base price
        { name = "Hustler", minRep = 100, priceModifier = 0.9 }, -- 90% of base price
        { name = "Dealer", minRep = 300, priceModifier = 1.0 },   -- 100% of base price
        { name = "Kingpin", minRep = 600, priceModifier = 1.1 },  -- 110% of base price
        { name = "Legend", minRep = 1000, priceModifier = 1.25 }  -- 125% of base price
    },
    
    -- Rep gained/lost per transaction
    repGainOnSuccess = 5,
    repLossOnReject = 0,      -- No loss for rejecting initial offer
    repLossOnNegotiationFail = 15,  -- Loss if negotiation fails
    repGainOnNegotiationSuccess = 10,  -- Bonus for successful negotiation
    
    -- Negotiation settings
    negotiation = {
        -- Chance for negotiation to succeed based on rep (formula)
        -- baseChance + (reputation / 50)
        baseSuccessChance = 30,  -- 30% base chance
        maxSuccessChance = 80,   -- Cap at 80%
        
        -- How much price can increase on successful negotiation (percentage)
        priceIncreasePercent = 25,
        
        -- How much price decreases on failed negotiation (percentage)
        priceDecreasePercent = 15
    },
    
    -- Starting reputation for new players
    startingRep = 0
}

-- Notification settings
Config.Notifications = {
    showRepChanges = true,
    showPriceOffer = true
}

-- Blacklist certain areas (safe zones where NPCs won't approach)
Config.BlacklistZones = {
    { coords = vector3(434.0, -982.0, 30.0), radius = 100.0 },  -- Mission Row PD
    { coords = vector3(-1037.0, -2737.0, 20.0), radius = 150.0 } -- Airport
}
