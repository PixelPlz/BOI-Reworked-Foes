local mod = ReworkedFoes



--[[ Load the champion IDs ]]--
mod.Champions = {}

local champions = {
	{ Variable = "Gish", 	 Champion = "Hera" },
	{ Variable = "Sloth", 	 Champion = "Dank Sloth" },
	{ Variable = "Lust", 	 Champion = "Fortune Teller Lust" },
	{ Variable = "Wrath", 	 Champion = "Burning Wrath" },
	{ Variable = "Gluttony", Champion = "Infested Gluttony" },
	{ Variable = "Greed", 	 Champion = "Golden Greed" },
	{ Variable = "Envy", 	 Champion = "Lonely Envy" },
	{ Variable = "Pride", 	 Champion = "Holy Pride" },
	{ Variable = "Pin", 	 Champion = "Pins Lament" },
	{ Variable = "Conquest", Champion = "Bloody Conquest" },
	{ Variable = "DarkOne",  Champion = "Darkest One" },
}
for i, entry in pairs(champions) do
	mod.Champions[entry.Variable] = Isaac.GetBossColorIdxByName(entry.Champion) + 1
end