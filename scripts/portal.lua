local mod = BetterMonsters
local game = Game()

local Settings = {
	Cooldown = 90,
	MaxSpawns = 3,
	ShotSpeed = 10
}

local portalSpawns = { -- Corresponds to the values from game:GetRoom():GetRoomConfigStage()
	{ -- Basement
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_HORF, 0},
		{EntityType.ENTITY_POOTER, 0},
		{EntityType.ENTITY_CLOTTY, 0},
		{EntityType.ENTITY_MULLIGAN, 0},
		{EntityType.ENTITY_HOPPER, 0},
		{EntityType.ENTITY_FATTY, 0},
		{EntityType.ENTITY_SKINNY, 0}
	},
	{ -- Cellar
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_HORF, 0},
		{EntityType.ENTITY_POOTER, 1},
		{EntityType.ENTITY_CLOTTY, 1},
		{EntityType.ENTITY_HOPPER, 1},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_NEST, 0},
		{EntityType.ENTITY_SKINNY, 0}
	},
	{ -- Burning Basement
		{EntityType.ENTITY_GAPER, 2},
		{EntityType.ENTITY_HORF, 0},
		{EntityType.ENTITY_POOTER, 0},
		{EntityType.ENTITY_CLOTTY, 3},
		{EntityType.ENTITY_MULLIGAN, 1},
		{EntityType.ENTITY_FLAMINGHOPPER, 0},
		{EntityType.ENTITY_FATTY, 2},
		{EntityType.ENTITY_SKINNY, 2}
	},

	{ -- Caves
		{EntityType.ENTITY_HIVE, 0},
		{EntityType.ENTITY_CHARGER, 0},
		{EntityType.ENTITY_GLOBIN, 0},
		{EntityType.ENTITY_BOOMFLY, 0},
		{EntityType.ENTITY_MAW, 0},
		{EntityType.ENTITY_HOST, 0},
		{EntityType.ENTITY_BONY, 0},
		{EntityType.ENTITY_ONE_TOOTH, 0}
	},
	{ -- Catacombs
		{EntityType.ENTITY_VIS, 2},
		{EntityType.ENTITY_KEEPER, 0},
		{EntityType.ENTITY_GURGLE, 0},
		{EntityType.ENTITY_WALKINGBOIL, 0},
		{EntityType.ENTITY_WALKINGBOIL, 1},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_BUTTLICKER, 0},
		{EntityType.ENTITY_BONY, 0}
	},
	{ -- Flooded Caves
		{EntityType.ENTITY_HIVE, 1},
		{EntityType.ENTITY_CHARGER, 1},
		{EntityType.ENTITY_GLOBIN, 0},
		{EntityType.ENTITY_BOOMFLY, 2},
		{EntityType.ENTITY_MAW, 1},
		{EntityType.ENTITY_BONY, 0},
		{EntityType.ENTITY_ONE_TOOTH, 0},
		{EntityType.ENTITY_ROUND_WORM, 1}
	},

	{ -- Depth
		{EntityType.ENTITY_BOIL, 0},
		{EntityType.ENTITY_BRAIN, 0},
		{EntityType.ENTITY_LEAPER, 0},
		{EntityType.ENTITY_MRMAW, 0},
		{EntityType.ENTITY_BABY, 0},
		{EntityType.ENTITY_VIS, 0},
		{EntityType.ENTITY_GUTS, 0},
		{EntityType.ENTITY_KNIGHT, 0}
	},
	{ -- Necropolis
		{EntityType.ENTITY_VIS, 1},
		{EntityType.ENTITY_KEEPER, 0},
		{EntityType.ENTITY_GURGLE, 0},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_BUTTLICKER, 0},
		{EntityType.ENTITY_HANGER, 0},
		{EntityType.ENTITY_SWARMER, 0},
		{EntityType.ENTITY_MASK, 0}
	},
	{ -- Dank Depth
		{EntityType.ENTITY_CHARGER, 2},
		{EntityType.ENTITY_GLOBIN, 2},
		{EntityType.ENTITY_LEAPER, 1},
		{EntityType.ENTITY_GUTS, 2},
		{EntityType.ENTITY_DEATHS_HEAD, 1},
		{EntityType.ENTITY_SQUIRT, 1},
		{EntityType.ENTITY_TARBOY, 0},
		{EntityType.ENTITY_BUTT_SLICKER, 0}
	},

	{ -- Womb
		{EntityType.ENTITY_BABY, 0},
		{EntityType.ENTITY_LEECH, 0},
		{EntityType.ENTITY_LUMP, 0},
		{EntityType.ENTITY_PARA_BITE, 0},
		{EntityType.ENTITY_FRED, 0},
		{EntityType.ENTITY_EYE, 0},
		{EntityType.ENTITY_SWINGER, 0},
		{EntityType.ENTITY_TUMOR, 0}
	},
	{ -- Utero
		{EntityType.ENTITY_BABY, 3},
		{EntityType.ENTITY_VIS, 1},
		{EntityType.ENTITY_EYE, 1},
		{EntityType.ENTITY_MASK, 0},
		{EntityType.ENTITY_MEATBALL, 1},
		{EntityType.ENTITY_TUMOR, 1},
		{EntityType.ENTITY_PEEPER_FATTY, 0},
		{EntityType.ENTITY_FLOATING_HOST, 0}
	},
	{ -- Scarred Womb
		{EntityType.ENTITY_VIS, 3},
		{EntityType.ENTITY_GUTS, 1},
		{EntityType.ENTITY_PARA_BITE, 1},
		{EntityType.ENTITY_MASK, 1},
		{EntityType.ENTITY_FLESH_DEATHS_HEAD, 0},
		{EntityType.ENTITY_FISTULOID, 0},
		{EntityType.ENTITY_LEPER, 0},
		{EntityType.ENTITY_FACELESS, 0}
	},

	{ -- Blue Womb
		{EntityType.ENTITY_CONJOINED_FATTY, 1},
		{EntityType.ENTITY_HUSH_FLY, 0},
		{EntityType.ENTITY_HUSH_GAPER, 0},
		{EntityType.ENTITY_HUSH_BOIL, 0}
	},

	{ -- Sheol
		{EntityType.ENTITY_BABY, 3},
		{EntityType.ENTITY_KNIGHT, 1},
		{EntityType.ENTITY_LEECH, 1},
		{EntityType.ENTITY_CAMILLO_JR, 0},
		{EntityType.ENTITY_NULLS, 0},
		{EntityType.ENTITY_IMP, 0},
		{EntityType.ENTITY_THE_HAUNT, 10},
		{EntityType.ENTITY_BLACK_GLOBIN, 0}
	},
	{ -- Cathedral
		{EntityType.ENTITY_CLOTTY, 2},
		{EntityType.ENTITY_HIVE, 2},
		{EntityType.ENTITY_MAW, 2},
		{EntityType.ENTITY_BABY, 1},
		{EntityType.ENTITY_LEECH, 2},
		{EntityType.ENTITY_EYE, 2},
		{EntityType.ENTITY_BONY, 1},
		{EntityType.ENTITY_CANDLER, 0}
	},

	{ -- Dark Room
		{EntityType.ENTITY_SLOTH, 0},
		{EntityType.ENTITY_LUST, 0},
		{EntityType.ENTITY_WRATH, 0},
		{EntityType.ENTITY_GLUTTONY, 0},
		{EntityType.ENTITY_GREED, 0},
		{EntityType.ENTITY_ENVY, 0},
		{EntityType.ENTITY_PRIDE, 0},
		{EntityType.ENTITY_SHADY, 0}
	},
	{ -- Chest
		{EntityType.ENTITY_SLOTH, 0},
		{EntityType.ENTITY_LUST, 0},
		{EntityType.ENTITY_WRATH, 0},
		{EntityType.ENTITY_GLUTTONY, 0},
		{EntityType.ENTITY_GREED, 0},
		{EntityType.ENTITY_ENVY, 0},
		{EntityType.ENTITY_PRIDE, 0},
		{EntityType.ENTITY_CONJOINED_FATTY, 1}
	},

	-- Unused IDs
	{}, {}, {}, {}, {}, {}, {}, {}, {},

	{ -- Downpour
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_BUBBLES, 0},
		{EntityType.ENTITY_WRAITH, 0},
		{EntityType.ENTITY_SUB_HORF, 0},
		{EntityType.ENTITY_BLURB, 0},
		{EntityType.ENTITY_PREY, 0},
		{EntityType.ENTITY_WILLO_L2, 0},
		{EntityType.ENTITY_BLOATY, 0}
	},
	{ -- Dross
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_BUBBLES, 0},
		{EntityType.ENTITY_SUB_HORF, 0},
		{EntityType.ENTITY_BLURB, 0},
		{EntityType.ENTITY_PREY, 0},
		{EntityType.ENTITY_CLOGGY, 0},
		{EntityType.ENTITY_FLY_TRAP, 0},
		{EntityType.ENTITY_DUMP, 0}
	},
	
	{ -- Mines
		{EntityType.ENTITY_BOOMFLY, 3},
		{EntityType.ENTITY_HOST, 3},
		{EntityType.ENTITY_DANNY, 0},
		{EntityType.ENTITY_BLASTER, 0},
		{EntityType.ENTITY_BOUNCER, 0},
		{EntityType.ENTITY_QUAKEY, 0},
		{EntityType.ENTITY_GYRO, 0},
		{EntityType.ENTITY_MOLE, 0}
	},
	{ -- Ashpit
		{EntityType.ENTITY_CHARGER, 3},
		{EntityType.ENTITY_BOOMFLY, 3},
		{EntityType.ENTITY_BOOMFLY, 4},
		{EntityType.ENTITY_GURGLE, 1},
		{EntityType.ENTITY_DANNY, 1},
		{EntityType.ENTITY_NECRO, 0},
		{EntityType.ENTITY_BIG_BONY, 0},
		{EntityType.ENTITY_FLESH_MAIDEN, 0}
	},
	
	{ -- Mausoleum
		{EntityType.ENTITY_GLOBIN, 3},
		{EntityType.ENTITY_KNIGHT, 2},
		{EntityType.ENTITY_CANDLER, 0},
		{EntityType.ENTITY_WHIPPER, 0},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_VIS_VERSA, 0},
		{EntityType.ENTITY_REVENANT, 0},
		{EntityType.ENTITY_BABY_BEGOTTEN, 0}
	},
	{ -- Gehenna
		{EntityType.ENTITY_GLOBIN, 3},
		{EntityType.ENTITY_KNIGHT, 4},
		{EntityType.ENTITY_WHIPPER, 0},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_REVENANT, 0},
		{EntityType.ENTITY_MORNINGSTAR, 0},
		{EntityType.ENTITY_CULTIST, 1},
		{EntityType.ENTITY_GOAT, 0}
	},
	
	{ -- Corpse
		{EntityType.ENTITY_GAPER, 3},
		{EntityType.ENTITY_BOOMFLY, 5},
		{EntityType.ENTITY_SUCKER, 4},
		{EntityType.ENTITY_TWITCHY, 0},
		{EntityType.ENTITY_CHARGER_L2, 0},
		{EntityType.ENTITY_UNBORN, 0},
		{EntityType.ENTITY_CYST, 0},
		{EntityType.ENTITY_EVIS, 0}
	},
}



function mod:portalInit(entity)
	if entity.Variant == 0 or entity.Variant == 40 then
		entity.Variant = 40 -- Unsurprisingly Fiend Folio fucks with this too, because they just can't stop being fucking annoying
		entity.ProjectileCooldown = Settings.Cooldown / 2
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.portalInit, EntityType.ENTITY_PORTAL)

function mod:portalUpdate(entity)
	if entity.Variant == 40 then
		local sprite = entity:GetSprite()

		entity.Velocity = Vector.Zero
		mod:LoopingAnim(sprite, "Idle")


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingOverlay(sprite, "FaceIdle")
			
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_SUMMON
				sprite:PlayOverlay("FaceSpawn", true)
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Spawn / Attack
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetOverlayFrame() == 10 then
				SFXManager():Play(SoundEffect.SOUND_PORTAL_SPAWN, 1.1)
				local stage = game:GetRoom():GetRoomConfigStage()

				if Isaac.CountEntities(entity, EntityType.ENTITY_NULL, -1, -1) < Settings.MaxSpawns and ((stage > 0 and stage < 18) or (stage > 26 and stage < 35)) then
					local spawn = portalSpawns[stage][math.random(1, #portalSpawns[stage])]

					local ent = Isaac.Spawn(spawn[1], spawn[2], 0, entity.Position + Vector(0, 10), Vector.Zero, entity)
					ent:SetColor(portalSpawnColor, 15, 1, true, false)
					ent.MaxHitPoints = ent.MaxHitPoints * 2
					ent.HitPoints = ent.MaxHitPoints
					ent:Update()
				
				else
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Color = portalBulletColor
					
					if entity.StateFrame == 0 then
						params.BulletFlags = ProjectileFlags.ORBIT_CW
						entity.StateFrame = entity.StateFrame + 1
					elseif entity.StateFrame == 1 then
						params.BulletFlags = ProjectileFlags.ORBIT_CCW
						entity.StateFrame = 0
					end
					params.TargetPosition = entity.Position

					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 7, params)
				end

			elseif sprite:IsOverlayFinished("FaceSpawn") then
				entity.State = NpcState.STATE_IDLE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.portalUpdate, EntityType.ENTITY_PORTAL)

function mod:portalDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 40 and (damageSource.SpawnerType == EntityType.ENTITY_PORTAL or (damageSource.SpawnerEntity and damageSource.SpawnerEntity.SpawnerType == EntityType.ENTITY_PORTAL)) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.portalDMG, EntityType.ENTITY_PORTAL)