local mod = ReworkedFoes

-- For backwards compatibility
BetterMonsters = mod



function mod:LoadCompatibility()
	--[[ Off-screen Indicator blacklists ]]--
	if OffscreenIndicators then
		-- Gish
		OffscreenIndicators:AddBlacklist(EntityType.ENTITY_MONSTRO2, 1, nil, {NpcState.STATE_ATTACK2}) -- On the ceiling

		-- Steven
		OffscreenIndicators:AddBlacklist(EntityType.ENTITY_GEMINI, 1, nil, {NpcState.STATE_SPECIAL}) -- 2nd phase
		OffscreenIndicators:AddBlacklist(EntityType.ENTITY_GEMINI, 11, nil, "segmented") -- Little Steven
		OffscreenIndicators:AddBlacklist(mod.Entities.Type, mod.Entities.Wallace) -- Wallace

		-- Forgotten body
		OffscreenIndicators:AddBlacklist(mod.Entities.Type, mod.Entities.BlueBabyExtras, mod.Entities.ForgottenBody)

		-- Sister Vis corpse
		local corpseCheck = function(entity)
			return entity:GetData().corpse == true
		end
		OffscreenIndicators:AddBlacklist(EntityType.ENTITY_SISTERS_VIS, nil, nil, corpseCheck)
	end



	--[[ Fiend Folio ]]--
	if FiendFolio then
		-- Non-males
		local nonMale = {
			{ID = {EntityType.ENTITY_HOST, 3, 40},    Affliction = "Woman"}, -- Soft Host
			{ID = {EntityType.ENTITY_MULLIGAN, 40},   Affliction = "Woman"}, -- Mullicocoon
		}
		for i, entry in pairs(nonMale) do
			table.insert(FiendFolio.Nonmale, entry)
		end


		-- LGBTQIA
		local based = {
			{ID = {mod.Entities.Type, mod.Entities.Wallace}, Affliction = "Pan"}, -- Wallace
			{ID = {EntityType.ENTITY_HIVE, 40}, 			 Affliction = "Trans"}, -- Nest (new)
		}
		for i, entry in pairs(based) do
			table.insert(FiendFolio.LGBTQIA, entry)
		end


		-- Outliers
		local outliers = {
			{ID = {EntityType.ENTITY_CLOTTY, mod.Entities.ClottySketch},   Affliction = "Drawing"}, -- Clotty Sketch
			{ID = {EntityType.ENTITY_CHARGER, mod.Entities.ChargerSketch}, Affliction = "Drawing"}, -- Charger Sketch
			{ID = {EntityType.ENTITY_GLOBIN, mod.Entities.GlobinSketch},   Affliction = "Drawing"}, -- Globin Sketch
			{ID = {EntityType.ENTITY_MAW, mod.Entities.MawSketch}, 		   Affliction = "Drawing"}, -- Maw Sketch

			{ID = {EntityType.ENTITY_WAR, 20}, 					   Affliction = "Horse"}, -- Conquest Horse
			{ID = {mod.Entities.Type, mod.Entities.Teratomar}, 	   Affliction = "War criminal"}, -- Teratomar
			{ID = {EntityType.ENTITY_KEEPER, mod.Entities.Coffer}, Affliction = "Inflation fetishist"}, -- Coffer
		}
		for i, entry in pairs(outliers) do
			table.insert(FiendFolio.Outlier, entry)
		end
	end



	--[[ Enhanced Boss Bars ]]--
	if HPBars then
		local path = "gfx/ui/bosshp_icons/"

		-- Conquest
		HPBars.BossDefinitions["65.20"] = { -- Horse
			sprite = path .. "horsemen/conquest_horse.png",
			offset = Vector(-4, 0),
		}

		-- Matriarch Fistula
		HPBars.BossDefinitions["71.0"].conditionalSprites = { -- Large
			{ function(entity) return entity.SubType == 1000 end, path .. "chapter2/fistula_large_scarred.png" }
		}
		HPBars.BossDefinitions["72.0"].conditionalSprites = { -- Medium
			{ function(entity) return entity.SubType == 1000 end, path .. "chapter2/fistula_medium_scarred.png" }
		}
		HPBars.BossDefinitions["73.0"].conditionalSprites = { -- Small
			{ function(entity) return entity.SubType == 1000 end, path .. "chapter2/fistula_small_scarred.png" }
		}

		-- Teratomar
		local teratomarTypeVar = tostring(mod.Entities.Type) .. "." .. tostring(mod.Entities.Teratomar)
		HPBars.BossDefinitions[teratomarTypeVar] = {
			sprite = path .. "chapter4/teratomar.png",
			offset = Vector(-4, 0),
			bossColors = {"_fuzzy"} -- For Fiend Folio
		}

		-- It Lives
		HPBars.BossDefinitions["78.1"].conditionalSprites = {
			{ function(entity) return entity:GetData().enraged == true end, path .. "final/it_lives_angy.png" }
		}

		-- Steven
		HPBars.BossDefinitions["79.1"].conditionalSprites = {
			{ function(entity) return entity:ToNPC().State == NpcState.STATE_SPECIAL end, path .. "chapter1/steven_wallace.png" }
		}

		-- Blighted Ovum
		HPBars.BossDefinitions["79.2"].conditionalSprites = {
			{ "isI1Equal", path .. "chapter1/blighted_ovum_phase2.png", {1} }
		}

		-- Forsaken clone (for Off-screen Indicators)
		HPBars.BossDefinitions["403.10"] = {
			sprite = path .. "chapter2/the_forsaken.png",
			offset = Vector(-6, 0),
			bossColors = {"_black"}
		}

		-- Sister Vis
		HPBars.BossDefinitions["410.0"].conditionalSprites = {
			{ function(entity) return entity:GetData().enraged == true end, path .. "chapter3/sisters_vis_nuts.png" }
		}

		-- Visage heart unique phase 3 icon
		HPBars.BossDefinitions["903.0"].conditionalSprites = {
			{"animationNameContains", path .. "altpath/the_visage_heart_phase2.png", {"2"}},
			{"animationNameContains", path .. "altpath/the_visage_heart_phase3.png", {"3"}},
			{"animationNameContains", path .. "altpath/the_visage_heart_phase3.png", {"Attack"}},
		}


		-- Blacklists
		-- Steven
		HPBars.BossIgnoreList["79.11"] = function(entity) -- Little Steven
			return entity:ToNPC().I1 ~= 1
		end
		HPBars.BossIgnoreList["79.1"] = function(entity) -- 2nd phase delay
			return entity:ToNPC().State == NpcState.STATE_SPECIAL and entity:ToNPC().StateFrame == 0 and not entity:GetData().wasDelirium
		end
		local wallaceTypeVar = tostring(mod.Entities.Type) .. "." .. tostring(mod.Entities.Wallace)
		HPBars.BossIgnoreList[wallaceTypeVar] = true -- Wallace

		-- Mask of Infamy
		HPBars.BossIgnoreList["97.0"] = true

		-- Triachnid feet
		HPBars.BossIgnoreList["101.10"] = true

		-- Forgotten body
		local forgottenBodyTypeVar = tostring(mod.Entities.Type) .. "." .. tostring(mod.Entities.BlueBabyExtras)
		HPBars.BossIgnoreList[forgottenBodyTypeVar] = true

		-- Stain tentacles
		HPBars.BossIgnoreList["401.10"] = true

		-- Forsaken clone
		HPBars.BossIgnoreList["403.10"] = true

		-- Sister Vis corpse
		HPBars.BossIgnoreList["410.0"] = function(entity)
			return entity:GetData().corpse == true
		end

		-- Siren revive
		HPBars.BossIgnoreList["904.0"] = function(entity)
			return entity:ToNPC().I2 == 100
		end
	end



	--[[ Enemy Bullet Trails ]]--
	if BulletTrails then
		local c = mod.Colors.Sketch
		local sketch = Color(c.RO,c.GO,c.BO, 1)

		-- Trail colors from the mod
		local red = Color(0.9,0.05,0.05, 1)
		local green = Color(0.05,0.9,0.05, 1)


		-- C.H.A.D. Sucker projectile
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_CHUB, 1, red)

		-- Ultra Pride
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_SLOTH, 2, green)

		-- Ultra Pride Sketches
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_CLOTTY, mod.Entities.ClottySketch, sketch) -- Clotty Sketch
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_MAW, mod.Entities.MawSketch, sketch) -- Maw Sketch

		-- Champion Husk Sucker projectile
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_DUKE, 1, red)

		-- Champion Bloat
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_PEEP, 1,
			function(entity)
				if entity and entity.SubType == 1 then
					return green
				end
			end
		)

		-- Triachnid egg sack projectile
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_DADDYLONGLEGS, 1, mod.Colors.WhiteShot)

		-- Hush baby fly attack
		BulletTrails:BlacklistEntity(true, EntityType.ENTITY_HUSH_FLY, 0)

		-- Non-champion Mega Maw fires
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_MEGA_MAW, 0,
			function(entity)
				if entity and entity.SubType == 0 then
					return mod.Colors.RagManPurple
				end
			end
		)

		-- Cage
		BulletTrails:AddEntityTrailColor(EntityType.ENTITY_CAGE, 0,
			function(entity)
				if entity then
					-- Green champion
					if entity.SubType == 1 then
						return mod.Colors.CageGreenShot

					-- Pink champion
					elseif entity.SubType == 2 then
						return mod.Colors.CagePinkShot

					-- Non-champion
					else
						return Color(0.3,0.7,0.6, 1)
					end
				end
			end
		)
	end



	--[[ Retribution ]]--
	if Retribution then
		local GED = BaptismalPreloader.GenerateEntityDataset

		local downgrades = {
			{GED("Soft Host"),    GED("#HARD_HOST")},
			{GED("Coffer"), 	  GED("#HOPPER")},
			{GED("Mullicocoon"),  GED("#MULLIGAN")},
			{GED("Flesh Floast"), GED("#FLOAST")},
		}
		for _, entry in pairs(downgrades) do
			BaptismalPreloader.AddBaptismalData(entry[1], {BaptismalPreloader.GenerateTransformationDataset(entry[2])})
		end


		local upgrades = {
			{GED("Clotty Sketch"), 	GED("#CLOTTY")},
			{GED("Charger Sketch"), GED("#CHARGER")},
			{GED("Globin Sketch"), 	GED("#GLOBIN")},
			{GED("Maw Sketch"), 	GED("#MAW")},

			{GED("Coffer"), 	 GED("#EGGY")},
			{GED("Mullicocoon"), GED("#NEST")},
		}
		for _, entry in pairs(upgrades) do
			BaptismalPreloader.AddAntibaptismalData(entry[1], {BaptismalPreloader.GenerateTransformationDataset(entry[2])})
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.LoadCompatibility)