local mod = ReworkedFoes

local Settings = {
	Cooldown = 90,
	MaxSpawns = 3,
	SpawnHPMulti = 2,
	ShotSpeed = 11,
}

-- Example on how to add custom spawns: (variant and subtype can be left out to default it to 0)
-- table.insert( ReworkedFoes.PortalSpawns[10], {200, 21, 69} )
mod.PortalSpawns = { -- Corresponds to the IDs in stages.xml
	{ -- Basement
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_HORF},
		{EntityType.ENTITY_POOTER},
		{EntityType.ENTITY_CLOTTY},
		{EntityType.ENTITY_MULLIGAN},
		{EntityType.ENTITY_HOPPER},
		{EntityType.ENTITY_FATTY},
		{EntityType.ENTITY_SKINNY},
	},
	{ -- Cellar
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_HORF},
		{EntityType.ENTITY_POOTER, 1},
		{EntityType.ENTITY_CLOTTY, 1},
		{EntityType.ENTITY_HOPPER, 1},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_NEST},
		{EntityType.ENTITY_SKINNY},
	},
	{ -- Burning Basement
		{EntityType.ENTITY_GAPER, 2},
		{EntityType.ENTITY_HORF},
		{EntityType.ENTITY_POOTER},
		{EntityType.ENTITY_CLOTTY, 3},
		{EntityType.ENTITY_MULLIGAN, 1},
		{EntityType.ENTITY_FLAMINGHOPPER},
		{EntityType.ENTITY_FATTY, 2},
		{EntityType.ENTITY_SKINNY, 2},
	},

	{ -- Caves
		{EntityType.ENTITY_HIVE},
		{EntityType.ENTITY_CHARGER},
		{EntityType.ENTITY_GLOBIN},
		{EntityType.ENTITY_BOOMFLY},
		{EntityType.ENTITY_MAW},
		{EntityType.ENTITY_HOST},
		{EntityType.ENTITY_BONY},
		{EntityType.ENTITY_ONE_TOOTH},
	},
	{ -- Catacombs
		{EntityType.ENTITY_VIS, 2},
		{EntityType.ENTITY_KEEPER},
		{EntityType.ENTITY_GURGLE},
		{EntityType.ENTITY_WALKINGBOIL},
		{EntityType.ENTITY_WALKINGBOIL, 1},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_BUTTLICKER},
		{EntityType.ENTITY_BONY},
	},
	{ -- Flooded Caves
		{EntityType.ENTITY_HIVE, 1},
		{EntityType.ENTITY_CHARGER, 1},
		{EntityType.ENTITY_GLOBIN},
		{EntityType.ENTITY_BOOMFLY, 2},
		{EntityType.ENTITY_MAW, 1},
		{EntityType.ENTITY_BONY},
		{EntityType.ENTITY_ONE_TOOTH},
		{EntityType.ENTITY_ROUND_WORM, 1},
	},

	{ -- Depths
		{EntityType.ENTITY_BOIL},
		{EntityType.ENTITY_BRAIN},
		{EntityType.ENTITY_LEAPER},
		{EntityType.ENTITY_MRMAW},
		{EntityType.ENTITY_BABY},
		{EntityType.ENTITY_VIS},
		{EntityType.ENTITY_GUTS},
		{EntityType.ENTITY_KNIGHT},
	},
	{ -- Necropolis
		{EntityType.ENTITY_VIS, 1},
		{EntityType.ENTITY_KEEPER},
		{EntityType.ENTITY_GURGLE},
		{EntityType.ENTITY_WALKINGBOIL, 2},
		{EntityType.ENTITY_BUTTLICKER},
		{EntityType.ENTITY_HANGER},
		{EntityType.ENTITY_SWARMER},
		{EntityType.ENTITY_MASK},
	},
	{ -- Dank Depths
		{EntityType.ENTITY_CHARGER, 2},
		{EntityType.ENTITY_GLOBIN, 2},
		{EntityType.ENTITY_LEAPER, 1},
		{EntityType.ENTITY_GUTS, 2},
		{EntityType.ENTITY_DEATHS_HEAD, 1},
		{EntityType.ENTITY_SQUIRT, 1},
		{EntityType.ENTITY_TARBOY},
		{EntityType.ENTITY_BUTT_SLICKER},
	},

	{ -- Womb
		{EntityType.ENTITY_BABY},
		{EntityType.ENTITY_LEECH},
		{EntityType.ENTITY_LUMP},
		{EntityType.ENTITY_PARA_BITE},
		{EntityType.ENTITY_FRED},
		{EntityType.ENTITY_EYE},
		{EntityType.ENTITY_SWINGER},
		{EntityType.ENTITY_TUMOR},
	},
	{ -- Utero
		{EntityType.ENTITY_BABY, 3},
		{EntityType.ENTITY_VIS, 1},
		{EntityType.ENTITY_EYE, 1},
		{EntityType.ENTITY_MASK},
		{EntityType.ENTITY_MEATBALL, 1},
		{EntityType.ENTITY_TUMOR, 1},
		{EntityType.ENTITY_PEEPER_FATTY},
		{EntityType.ENTITY_FLOATING_HOST},
	},
	{ -- Scarred Womb
		{EntityType.ENTITY_VIS, 3},
		{EntityType.ENTITY_GUTS, 1},
		{EntityType.ENTITY_PARA_BITE, 1},
		{EntityType.ENTITY_MASK, 1},
		{EntityType.ENTITY_FLESH_DEATHS_HEAD},
		{EntityType.ENTITY_FISTULOID},
		{EntityType.ENTITY_LEPER},
		{EntityType.ENTITY_FACELESS},
	},

	{ -- Blue Womb
		{EntityType.ENTITY_CONJOINED_FATTY, 1},
		{EntityType.ENTITY_HUSH_FLY},
		{EntityType.ENTITY_HUSH_GAPER},
		{EntityType.ENTITY_HUSH_BOIL},
	},

	{ -- Sheol
		{EntityType.ENTITY_BABY, 3},
		{EntityType.ENTITY_KNIGHT, 1},
		{EntityType.ENTITY_LEECH, 1},
		{EntityType.ENTITY_CAMILLO_JR},
		{EntityType.ENTITY_NULLS},
		{EntityType.ENTITY_IMP},
		{EntityType.ENTITY_THE_HAUNT, 10},
		{EntityType.ENTITY_BLACK_GLOBIN},
	},
	{ -- Cathedral
		{EntityType.ENTITY_CLOTTY, 2},
		{EntityType.ENTITY_HIVE, 2},
		{EntityType.ENTITY_MAW, 2},
		{EntityType.ENTITY_BABY, 1},
		{EntityType.ENTITY_LEECH, 2},
		{EntityType.ENTITY_EYE, 2},
		{EntityType.ENTITY_BONY, 1},
		{EntityType.ENTITY_CANDLER},
	},

	{ -- Dark Room
		{EntityType.ENTITY_SLOTH},
		{EntityType.ENTITY_LUST},
		{EntityType.ENTITY_WRATH},
		{EntityType.ENTITY_GLUTTONY},
		{EntityType.ENTITY_GREED},
		{EntityType.ENTITY_ENVY},
		{EntityType.ENTITY_PRIDE},
		{EntityType.ENTITY_SHADY},
	},
	{ -- Chest
		{EntityType.ENTITY_SLOTH},
		{EntityType.ENTITY_LUST},
		{EntityType.ENTITY_WRATH},
		{EntityType.ENTITY_GLUTTONY},
		{EntityType.ENTITY_GREED},
		{EntityType.ENTITY_ENVY},
		{EntityType.ENTITY_PRIDE},
		{EntityType.ENTITY_CONJOINED_FATTY, 1},
	},

	-- Unused IDs
	{}, {}, {}, {}, {}, {}, {}, {}, {},

	{ -- Downpour
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_BUBBLES},
		{EntityType.ENTITY_WRAITH},
		{EntityType.ENTITY_SUB_HORF},
		{EntityType.ENTITY_BLURB},
		{EntityType.ENTITY_PREY},
		{EntityType.ENTITY_WILLO_L2},
		{EntityType.ENTITY_BLOATY},
	},
	{ -- Dross
		{EntityType.ENTITY_GAPER, 1},
		{EntityType.ENTITY_BUBBLES},
		{EntityType.ENTITY_SUB_HORF},
		{EntityType.ENTITY_BLURB},
		{EntityType.ENTITY_PREY},
		{EntityType.ENTITY_CLOGGY},
		{EntityType.ENTITY_FLY_TRAP},
		{EntityType.ENTITY_DUMP},
	},

	{ -- Mines
		{EntityType.ENTITY_BOOMFLY, 3},
		{EntityType.ENTITY_HOST, 3},
		{EntityType.ENTITY_DANNY},
		{EntityType.ENTITY_BLASTER},
		{EntityType.ENTITY_BOUNCER},
		{EntityType.ENTITY_QUAKEY},
		{EntityType.ENTITY_GYRO},
		{EntityType.ENTITY_MOLE},
	},
	{ -- Ashpit
		{EntityType.ENTITY_CHARGER, 3},
		{EntityType.ENTITY_BOOMFLY, 3},
		{EntityType.ENTITY_BOOMFLY, 4},
		{EntityType.ENTITY_GURGLE, 1},
		{EntityType.ENTITY_DANNY, 1},
		{EntityType.ENTITY_NECRO},
		{EntityType.ENTITY_BIG_BONY},
		{EntityType.ENTITY_FLESH_MAIDEN},
	},

	{ -- Mausoleum
		{EntityType.ENTITY_GLOBIN, 3},
		{EntityType.ENTITY_KNIGHT, 2},
		{EntityType.ENTITY_CANDLER},
		{EntityType.ENTITY_WHIPPER},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_VIS_VERSA},
		{EntityType.ENTITY_REVENANT},
		{EntityType.ENTITY_BABY_BEGOTTEN},
	},
	{ -- Gehenna
		{EntityType.ENTITY_GLOBIN, 3},
		{EntityType.ENTITY_KNIGHT, 4},
		{EntityType.ENTITY_WHIPPER},
		{EntityType.ENTITY_WHIPPER, 1},
		{EntityType.ENTITY_REVENANT},
		{EntityType.ENTITY_MORNINGSTAR},
		{EntityType.ENTITY_CULTIST, 1},
		{EntityType.ENTITY_GOAT},
	},

	{ -- Corpse
		{EntityType.ENTITY_GAPER, 3},
		{EntityType.ENTITY_BOOMFLY, 5},
		{EntityType.ENTITY_SUCKER, 4},
		{EntityType.ENTITY_TWITCHY},
		{EntityType.ENTITY_CHARGER_L2},
		{EntityType.ENTITY_UNBORN},
		{EntityType.ENTITY_CYST},
		{EntityType.ENTITY_EVIS},
	},
}



function mod:PortalInit(entity)
	if entity.Variant == 0 or entity.Variant == 40 then
		entity.Variant = 40
		entity.PositionOffset = Vector(0, -16)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.ProjectileCooldown = Settings.Cooldown / 2

		-- Bestiary fix
		entity:GetSprite():ReplaceSpritesheet(6, "")
		entity:GetSprite():LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PortalInit, EntityType.ENTITY_PORTAL)

function mod:PortalUpdate(entity)
	if entity.Variant == 40 then
		local sprite = entity:GetSprite()
		mod:LoopingAnim(sprite, "Idle")

		entity.Velocity = Vector.Zero
		mod:IgnoreKnockoutDrops(entity)


		-- Particles
		if entity:IsFrame(6, 0) then
			for i = 1, math.random(1, 2) do
				local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, entity.Position, Vector.Zero, nil):ToEffect()
				trail.DepthOffset = entity.DepthOffset - 10
				trail.PositionOffset = Vector(0, -16)

				-- Scale
				local scaler = math.random(40, 50) / 100
				trail.SpriteScale = Vector(scaler, scaler)

				-- Color
				local c = mod.Colors.PortalShotTrail
				local colorOffset = math.random(-1, 1) * 0.06
				trail:GetSprite().Color = Color(c.R,c.G,c.B, math.random(50, 100) / 100, c.RO + colorOffset, c.GO + colorOffset, c.BO + colorOffset)

				-- Movement
				local dir = mod:RandomVector()
				trail.Position = entity.Position + dir * 44
				trail.Velocity = -dir * 4

				trail:Update()
			end
		end


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingOverlay(sprite, "FaceIdle")

			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_SUMMON
				sprite:PlayOverlay("FaceSpawn", true)
				entity.ProjectileCooldown = Settings.Cooldown
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Spawn / Shoot
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetOverlayFrame() == 8 then
				mod:PlaySound(nil, SoundEffect.SOUND_PORTAL_SPAWN, 1.1)
				local stage = Game():GetRoom():GetRoomConfigStage()

				-- Spawn
				if Isaac.CountEntities(entity, EntityType.ENTITY_NULL, -1, -1) < Settings.MaxSpawns -- Not at max spawns
				and ((stage > 0 and stage < 18) or (stage > 26 and stage < 35)) then -- Valid stage type
					local selectedSpawn = mod:RandomIndex(mod.PortalSpawns[stage])

					local vector = Vector.FromAngle(mod:Random(60, 120)):Resized(3)
					local spawn = Isaac.Spawn(selectedSpawn[1], selectedSpawn[2] or 0, selectedSpawn[3] or 0, entity.Position + Vector(0, entity.Size), vector, entity)
					mod:ChangeMaxHealth(spawn, spawn.MaxHitPoints * Settings.SpawnHPMulti)
					spawn:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					spawn:SetColor(mod.Colors.PortalSpawn, 15, 1, true, false)

				-- Shoot
				else
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Color = mod.Colors.PortalShot

					-- Rotation direction
					if entity.StateFrame == 0 then
						params.BulletFlags = ProjectileFlags.ORBIT_CW
						entity.StateFrame = 1
					elseif entity.StateFrame == 1 then
						params.BulletFlags = ProjectileFlags.ORBIT_CCW
						entity.StateFrame = 0
					end
					params.TargetPosition = entity.Position

					mod:FireProjectiles(entity, entity.Position, Vector(Settings.ShotSpeed, 4), 9, params, mod.Colors.PortalShotTrail)
				end

			elseif sprite:IsOverlayFinished("FaceSpawn") then
				entity.State = NpcState.STATE_IDLE
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.PortalUpdate, EntityType.ENTITY_PORTAL)

function mod:PortalDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 40
	and (damageSource.SpawnerType == EntityType.ENTITY_PORTAL
	or (damageSource.SpawnerEntity and damageSource.SpawnerEntity.SpawnerType == EntityType.ENTITY_PORTAL)) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PortalDMG, EntityType.ENTITY_PORTAL)



--[[ Turn Crazy Long Legs from Lil Portals into Level 2 Spiders ]]--
function mod:CrazyLongLegsInit(entity)
	if entity.SpawnerType == EntityType.ENTITY_PORTAL and entity.SpawnerVariant == 1 then
		entity:Morph(EntityType.ENTITY_SPIDER_L2, 0, 0, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CrazyLongLegsInit, EntityType.ENTITY_BABY)