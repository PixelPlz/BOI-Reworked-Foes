local mod = BetterMonsters
local game = Game()



function mod:postGameStartedHPBars()
	if HPBars then
		local path = "gfx/ui/bosshp_icons"
		HPBars.BossIgnoreList["97.0"] = true

		HPBars.BossDefinitions["43.1"] = {
			sprite = path .. "/chapter3/gish.png",
			offset = Vector(-5, 0),
			bossColors = {"_white"}
		}

		HPBars.BossDefinitions["46.0"] = {
			sprite = path .. "/minibosses/sloth.png",
			offset = Vector(-6, 0),
			bossColors = {"_grey"}
		}
		HPBars.BossDefinitions["47.0"] = {
			sprite = path .. "/minibosses/lust.png",
			offset = Vector(-6, 0),
			bossColors = {"_purple"}
		}
		HPBars.BossDefinitions["48.0"] = {
			sprite = path .. "/minibosses/wrath.png",
			offset = Vector(-5, 0),
			bossColors = {"_grey"}
		}
		HPBars.BossDefinitions["49.0"] = {
			sprite = path .. "/minibosses/gluttony.png",
			offset = Vector(-6, 0),
			bossColors = {"_green"}
		}
		HPBars.BossDefinitions["50.0"] = {
			sprite = path .. "/minibosses/greed.png",
			offset = Vector(-6, 0),
			bossColors = {"_yellow"}
		}
		HPBars.BossDefinitions["51.0"] = {
			sprite = path .. "/minibosses/envy_large.png",
			offset = Vector(-5, 0),
			bossColors = {"_pink"}
		}
		HPBars.BossDefinitions["51.10"] = {
			sprite = path .. "/minibosses/envy_large.png",
			offset = Vector(-5, 0),
			bossColors = {"_pink"}
		}
		HPBars.BossDefinitions["51.20"] = {
			sprite = path .. "/minibosses/envy_medium.png",
			offset = Vector(-4, 0),
			bossColors = {"_pink"}
		}
		HPBars.BossDefinitions["51.30"] = {
			sprite = path .. "/minibosses/envy_small.png",
			offset = Vector(-2, 0),
			bossColors = {"_pink"}
		}
		HPBars.BossDefinitions["52.0"] = {
			sprite = path .. "/minibosses/pride.png",
			offset = Vector(-6, 0),
			bossColors = {"_yellow"}
		}

		HPBars.BossDefinitions["65.1"] = {
			sprite = path .. "/horsemen/conquest.png",
			offset = Vector(-7, 0),
			bossColors = {"_red"}
		}
		HPBars.BossDefinitions["65.11"] = {
			sprite = path .. "/horsemen/conquest.png",
			offset = Vector(-7, 0),
			conditionalSprites = {
				{function(entity) return entity.SubType == 1 end, path .. "/horsemen/conquest_red.png"}
			},
		}
		HPBars.BossDefinitions["65.20"] = {
			sprite = path .. "/horsemen/conquest_horse.png",
			offset = Vector(-4, 0),
			conditionalSprites = {
				{function(entity) return entity.SubType == 1 end, path .. "/horsemen/conquest_horse_red.png"}
			},
		}

		HPBars.BossDefinitions["81.0"] = {
			sprite = path .. "/chapter1/the_fallen.png",
			offset = Vector(-7, 2),
			bossColors = {"_red"}
		}
		HPBars.BossDefinitions["81.1"] = {
			sprite = path .. "/minibosses/krampus.png",
			offset = Vector(-6, 0),
			bossColors = {"_red"}
		}

		HPBars.BossDefinitions["82.0"] = {
			sprite = path .. "/horsemen/headless_horsemen_body.png",
			offset = Vector(-4, 0),
			bossColors = {"_purple"}
		}
		HPBars.BossDefinitions["83.0"] = {
			sprite = path .. "/horsemen/headless_horsemen_head.png",
			offset = Vector(-7, 0),
			bossColors = {"_purple"}
		}
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.postGameStartedHPBars)