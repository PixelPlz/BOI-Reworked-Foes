local mod = ReworkedFoes

local Settings = {
	Cooldown = 60,
	MaxSpawns = 3,
	SummonSpeed = 3,
	ShotSpeed = 11,
}



-- Spawn table
-- Corresponds to the STB type
mod.PortalSpawns = {
	HPMulti = 2,

	-- Chapter 1
	-- Basement
	[1] = {
		{ Type = EntityType.ENTITY_GAPER, },
		{ Type = EntityType.ENTITY_HORF, },
		{ Type = EntityType.ENTITY_POOTER, },
		{ Type = EntityType.ENTITY_CLOTTY, },
		{ Type = EntityType.ENTITY_MULLIGAN, },
		{ Type = EntityType.ENTITY_HOPPER, },
	},
	-- Cellar
	[2] = {
		{ Type = EntityType.ENTITY_GAPER, Variant = 1, },
		{ Type = EntityType.ENTITY_HORF, },
		{ Type = EntityType.ENTITY_POOTER, Variant = 1, },
		{ Type = EntityType.ENTITY_CLOTTY, Variant = 1, },
		{ Type = EntityType.ENTITY_MULLIGAN, Variant = 2, },
		{ Type = EntityType.ENTITY_HOPPER, Variant = 1, },
	},
	-- Burning Basement
	[3] = {
		{ Type = EntityType.ENTITY_GAPER, Variant = 2, },
		{ Type = EntityType.ENTITY_HORF, },
		{ Type = EntityType.ENTITY_POOTER, },
		{ Type = EntityType.ENTITY_CLOTTY, Variant = 3, },
		{ Type = EntityType.ENTITY_MULLIGAN, Variant = 1, },
		{ Type = EntityType.ENTITY_FLAMINGHOPPER, },
	},
	-- Downpour
	[27] = {
		{ Type = EntityType.ENTITY_BUBBLES, },
		{ Type = EntityType.ENTITY_WRAITH, },
		{ Type = EntityType.ENTITY_SUB_HORF, },
		{ Type = EntityType.ENTITY_BLURB, },
		{ Type = EntityType.ENTITY_PREY, },
		{ Type = EntityType.ENTITY_WILLO_L2, },
	},
	-- Dross
	[28] = {
		{ Type = EntityType.ENTITY_BUBBLES, },
		{ Type = EntityType.ENTITY_SUB_HORF, },
		{ Type = EntityType.ENTITY_BLURB, },
		{ Type = EntityType.ENTITY_PREY, },
		{ Type = EntityType.ENTITY_CLOGGY, },
		{ Type = EntityType.ENTITY_DUMP, },
	},

	-- Chapter 2
	-- Caves
	[4] = {
		{ Type = EntityType.ENTITY_HIVE, },
		{ Type = EntityType.ENTITY_CHARGER, },
		{ Type = EntityType.ENTITY_GLOBIN, },
		{ Type = EntityType.ENTITY_BOOMFLY, },
		{ Type = EntityType.ENTITY_MAW, },
		{ Type = EntityType.ENTITY_HOST, },
	},
	-- Catacombs
	[5] = {
		{ Type = EntityType.ENTITY_VIS, Variant = 2, },
		{ Type = EntityType.ENTITY_KEEPER, },
		{ Type = EntityType.ENTITY_GURGLE, },
		{ Type = EntityType.ENTITY_WALKINGBOIL, },
		{ Type = EntityType.ENTITY_WALKINGBOIL, Variant = 1, },
		{ Type = EntityType.ENTITY_WALKINGBOIL, Variant = 2, },
	},
	-- Flooded Caves
	[6] = {
		{ Type = EntityType.ENTITY_HIVE, Variant = 1, },
		{ Type = EntityType.ENTITY_CHARGER, Variant = 1, },
		{ Type = EntityType.ENTITY_GLOBIN, },
		{ Type = EntityType.ENTITY_BOOMFLY, Variant = 2, },
		{ Type = EntityType.ENTITY_MAW, Variant = 1, },
		{ Type = EntityType.ENTITY_HOST, Variant = 1, },
	},
	-- Mines
	[29] = {
		{ Type = EntityType.ENTITY_BOOMFLY, Variant = 3, },
		{ Type = EntityType.ENTITY_HOST, Variant = 3, },
		{ Type = EntityType.ENTITY_BOUNCER, },
		{ Type = EntityType.ENTITY_QUAKEY, },
		{ Type = EntityType.ENTITY_GYRO, },
		{ Type = EntityType.ENTITY_FACELESS, },
	},
	-- Ashpit
	[30] = {
		{ Type = EntityType.ENTITY_BOOMFLY, Variant = 4, },
		{ Type = EntityType.ENTITY_GURGLE, Variant = 1, },
		{ Type = EntityType.ENTITY_NECRO, },
		{ Type = EntityType.ENTITY_BIG_BONY, },
		{ Type = EntityType.ENTITY_FLESH_MAIDEN, },
		{ Type = EntityType.ENTITY_DUST, },
	},

	-- Chapter 3
	-- Depths
	[7] = {
		{ Type = EntityType.ENTITY_BOIL, },
		{ Type = EntityType.ENTITY_BRAIN, },
		{ Type = EntityType.ENTITY_LEAPER, },
		{ Type = EntityType.ENTITY_BABY, },
		{ Type = EntityType.ENTITY_VIS, },
		{ Type = EntityType.ENTITY_KNIGHT, },
	},
	-- Necropolis
	[8] = {
		{ Type = EntityType.ENTITY_VIS, Variant = 1, },
		{ Type = EntityType.ENTITY_VIS, Variant = 2, },
		{ Type = EntityType.ENTITY_KEEPER, },
		{ Type = EntityType.ENTITY_GURGLE, },
		{ Type = EntityType.ENTITY_HANGER, },
		{ Type = EntityType.ENTITY_MASK, },
	},
	-- Dank Depths
	[9] = {
		{ Type = EntityType.ENTITY_CHARGER, Variant = 2, },
		{ Type = EntityType.ENTITY_GLOBIN, Variant = 2, },
		{ Type = EntityType.ENTITY_LEAPER, Variant = 1, },
		{ Type = EntityType.ENTITY_GUTS, Variant = 2, },
		{ Type = EntityType.ENTITY_DEATHS_HEAD, Variant = 1, },
		{ Type = EntityType.ENTITY_TARBOY, },
	},
	-- Mausoleum
	[31] = {
		{ Type = EntityType.ENTITY_KNIGHT, Variant = 2, },
		{ Type = EntityType.ENTITY_CANDLER, },
		{ Type = EntityType.ENTITY_WHIPPER, },
		{ Type = EntityType.ENTITY_WHIPPER, Variant = 1, },
		{ Type = EntityType.ENTITY_REVENANT, },
		{ Type = EntityType.ENTITY_CULTIST, },
	},
	-- Gehenna
	[32] = {
		{ Type = EntityType.ENTITY_KNIGHT, Variant = 4, },
		{ Type = EntityType.ENTITY_WHIPPER, },
		{ Type = EntityType.ENTITY_WHIPPER, Variant = 1, },
		{ Type = EntityType.ENTITY_REVENANT, },
		{ Type = EntityType.ENTITY_CULTIST, Variant = 1, },
		{ Type = EntityType.ENTITY_GOAT, },
	},

	-- Chapter 4
	-- Womb
	[10] = {
		{ Type = EntityType.ENTITY_BABY, },
		{ Type = EntityType.ENTITY_LEECH, },
		{ Type = EntityType.ENTITY_LUMP, },
		{ Type = EntityType.ENTITY_PARA_BITE, },
		{ Type = EntityType.ENTITY_FRED, },
		{ Type = EntityType.ENTITY_EYE, },
	},
	-- Utero
	[11] = {
		{ Type = EntityType.ENTITY_BABY, Variant = 3, },
		{ Type = EntityType.ENTITY_VIS, Variant = 1, },
		{ Type = EntityType.ENTITY_LEECH, },
		{ Type = EntityType.ENTITY_EYE, Variant = 1, },
		{ Type = EntityType.ENTITY_MASK, },
		{ Type = EntityType.ENTITY_MEMBRAIN, Variant = 1, },
	},
	-- Scarred Womb
	[12] = {
		{ Type = EntityType.ENTITY_VIS, Variant = 3, },
		{ Type = EntityType.ENTITY_PARA_BITE, Variant = 1, },
		{ Type = EntityType.ENTITY_MASK, Variant = 1, },
		{ Type = EntityType.ENTITY_FISTULOID, },
		{ Type = EntityType.ENTITY_LEPER, },
		{ Type = EntityType.ENTITY_FACELESS, },
	},
	-- Corpse
	[33] = {
		{ Type = EntityType.ENTITY_SUCKER, Variant = 4, },
		{ Type = EntityType.ENTITY_GAPER_L2, },
		{ Type = EntityType.ENTITY_TWITCHY, },
		{ Type = EntityType.ENTITY_CHARGER_L2, },
		{ Type = EntityType.ENTITY_UNBORN, },
		{ Type = EntityType.ENTITY_CYST, },
	},

	-- Chapter 5
	-- Sheol
	[14] = {
		{ Type = EntityType.ENTITY_KNIGHT, Variant = 1, },
		{ Type = EntityType.ENTITY_LEECH, Variant = 1, },
		{ Type = EntityType.ENTITY_EYE, Variant = 1, },
		{ Type = EntityType.ENTITY_NULLS, },
		{ Type = EntityType.ENTITY_IMP, },
		{ Type = EntityType.ENTITY_BLACK_GLOBIN, },
	},
	-- Cathedral
	[15] = {
		{ Type = EntityType.ENTITY_CLOTTY, Variant = 2, },
		{ Type = EntityType.ENTITY_HIVE, Variant = 2, },
		{ Type = EntityType.ENTITY_BABY, Variant = 1, },
		{ Type = EntityType.ENTITY_LEECH, Variant = 2, },
		{ Type = EntityType.ENTITY_EYE, Variant = 2, },
		{ Type = EntityType.ENTITY_BONY, Variant = 1, },
	},
	-- Blue Womb
	[13] = {
		{ Type = EntityType.ENTITY_CONJOINED_FATTY, Variant = 1, },
		{ Type = EntityType.ENTITY_HUSH_FLY, },
		{ Type = EntityType.ENTITY_HUSH_GAPER, },
		{ Type = EntityType.ENTITY_HUSH_BOIL, },
	},

	-- Chapter 6
	-- Dark Room
	[16] = {
		{ Type = EntityType.ENTITY_SLOTH, },
		{ Type = EntityType.ENTITY_LUST, },
		{ Type = EntityType.ENTITY_WRATH, },
		{ Type = EntityType.ENTITY_GLUTTONY, },
		{ Type = EntityType.ENTITY_GREED, },
		{ Type = EntityType.ENTITY_PRIDE, },
	},
	-- Chest
	[17] = {
		{ Type = EntityType.ENTITY_SLOTH, },
		{ Type = EntityType.ENTITY_LUST, },
		{ Type = EntityType.ENTITY_WRATH, },
		{ Type = EntityType.ENTITY_GLUTTONY, },
		{ Type = EntityType.ENTITY_GREED, },
		{ Type = EntityType.ENTITY_PRIDE, },
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



		--[[ Idle ]]--
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingOverlay(sprite, "FaceIdle")

			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_SUMMON
				sprite:PlayOverlay("FaceSpawn", true)
				entity.ProjectileCooldown = Settings.Cooldown
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Spawn / Shoot ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetOverlayFrame() == 8 then
				-- Get the spawn table for the room
				local stbType = Game():GetRoom():GetRoomConfigStage()
				local spawnTable = mod.PortalSpawns[stbType]

				-- Custom stages
				if StageAPI and StageAPI.CurrentStage and mod.PortalSpawns[StageAPI.CurrentStage.Alias] then
					spawnTable = mod.PortalSpawns[StageAPI.CurrentStage.Alias]
				end


				-- Spawn if there are valid spawns for this STB type and there aren't too many spawns alive
				if spawnTable and Isaac.CountEntities(entity) < Settings.MaxSpawns then
					local spawnData = mod:RandomIndex(spawnTable)
					local variant = spawnData.Variant or 0
					local subtype = spawnData.SubType or 0
					local pos = entity.Position + Vector(0, entity.Size)
					local vector = Vector.FromAngle(mod:Random(60, 120)):Resized(Settings.SummonSpeed)

					local spawn = Isaac.Spawn(spawnData.Type, variant, subtype, pos, vector, entity):ToNPC()
					mod:ChangeMaxHealth(spawn, spawn.MaxHitPoints * mod.PortalSpawns.HPMulti)
					spawn:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					spawn:SetColor(mod.Colors.PortalSpawn, 15, 255, true, true)


				-- Shoot
				else
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Color = mod.Colors.PortalShot
					params.TargetPosition = entity.Position

					-- Get the orbit direction
					if entity.StateFrame == 0 then
						params.BulletFlags = ProjectileFlags.ORBIT_CW
						entity.StateFrame = 1

					elseif entity.StateFrame == 1 then
						params.BulletFlags = ProjectileFlags.ORBIT_CCW
						entity.StateFrame = 0
					end

					mod:FireProjectiles(entity, entity.Position, Vector(Settings.ShotSpeed, 4), 9, params, mod.Colors.PortalShotTrail)
				end


				-- Effects
				Game():MakeShockwave(entity.Position, 0.015, 0.015, 5)
				mod:PlaySound(nil, SoundEffect.SOUND_PORTAL_SPAWN, 1, math.random(97, 103) / 100)

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