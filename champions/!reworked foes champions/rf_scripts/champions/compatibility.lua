local mod = ReworkedFoes



function mod:LoadChampionCompatibility()
	--[[ Fiend Folio ]]--
	if FiendFolio then
		local entry = {ID = {EntityType.ENTITY_MONSTRO2, 1, mod.Champions.Gish}, Affliction = "Woman"}
		table.insert(FiendFolio.Nonmale, entry)
	end



	--[[ Enhanced Boss Bars ]]--
	if HPBars then
		-- Helper function
		local function createChampionEntry(typeVar, id, suffix)
			if not HPBars.BossDefinitions[typeVar].bossColors then
				HPBars.BossDefinitions[typeVar].bossColors = {}
			end
			HPBars.BossDefinitions[typeVar].bossColors[ mod.Champions[id] ] = "_" .. suffix
		end

		-- Gish
		createChampionEntry("43.1", "Gish", "hera")

		-- Sloth
		createChampionEntry("46.0", "Sloth", "dank")

		-- Lust
		createChampionEntry("47.0", "Lust", "fortune_teller")

		-- Wrath
		createChampionEntry("48.0", "Wrath", "burning")

		-- Gluttony
		createChampionEntry("49.0", "Gluttony", "infested")

		-- Greed
		createChampionEntry("50.0", "Greed", "golden")

		-- Envy
		createChampionEntry("51.0",  "Envy", "lonely") -- Full
		createChampionEntry("51.10", "Envy", "lonely") -- Large
		createChampionEntry("51.20", "Envy", "lonely") -- Medium
		createChampionEntry("51.30", "Envy", "lonely") -- Small

		-- Pride
		createChampionEntry("52.0", "Pride", "holy")

		-- Pin
		HPBars.BossDefinitions["62.0"].bossColors[ mod.Champions.Pin ] = "_pins_lament"

		-- Conquest
		createChampionEntry("65.1",  "Conquest", "bloody") -- Conquest
		createChampionEntry("65.20", "Conquest", "bloody") -- Horse

		-- Dark One
		createChampionEntry("267.0", "DarkOne", "darker")
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.LoadChampionCompatibility)