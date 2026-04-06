Street Deals - A QBCore resource that lets players sell items to NPCs that approach them on the street.

Features:

NPCs randomly spawn and walk up to the player (15% chance every 5 seconds)
NPC types have different spawn chances, models, names, and dialogue
Price negotiation system - players can haggle for better prices
Reputation system - the more you deal, the better prices you get (5 tiers from "Unknown" to "Kingpin")
Blacklist zones where NPCs won't approach (e.g., police stations)
Cooldown between NPC approaches
Custom React UI for viewing offers and negotiating
Commands:

/spawndealer - Manually trigger an NPC approach (testing)
/sellrep - Check your current reputation and price modifier
Config (config.lua) defines:

Sellable items and their base prices
NPC types with spawn chances, models, dialogue
Reputation tiers and price modifiers
Blacklist zones
Approach cooldown
