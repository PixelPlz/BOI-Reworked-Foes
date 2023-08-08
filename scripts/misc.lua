local mod = BetterMonsters



--[[ Clotty variants ]]--
function mod:clottyUpdate(entity)
	if entity.Variant ~= 3 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottyUpdate, EntityType.ENTITY_CLOTTY)

function mod:cloggyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cloggyUpdate, EntityType.ENTITY_CLOGGY)



--[[ Drowned Hive ]]--
function mod:drownedHiveUpdate(entity, target, bool)
	if entity.Variant == 1 then
		-- Only have up to 2 chargers
		if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetOverlayFrame() <= 1 and Isaac.CountEntities(entity, EntityType.ENTITY_CHARGER, 1, -1) >= 2 then
			entity.State = NpcState.STATE_MOVE
		end

		-- Shoot projectiles and spawn a Charger on death
		if entity:HasMortalDamage() and entity:IsDead() then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_TEAR
			entity:FireProjectiles(entity.Position, Vector(9, 4), 7, params)
			Isaac.Spawn(EntityType.ENTITY_CHARGER, 1, 0, entity.Position, Vector.Zero, entity)

			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.drownedHiveUpdate, EntityType.ENTITY_HIVE)



--[[ Launched Boom Flies ]]--
function mod:launchedBoomFlyUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL and not entity:IsDead() and not entity:HasMortalDamage() then
		local sprite = entity:GetSprite()

		entity.Velocity = entity.V2
		mod:LoopingAnim(sprite, "Fly")

		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)


		-- Die / Return to regular state when hitting a wall
		if entity:CollidesWithGrid() then
			if entity.StateFrame > 0 and Isaac.CountEntities(nil, EntityType.ENTITY_BOOMFLY, entity.Variant, -1) <= entity.StateFrame then
				entity.State = NpcState.STATE_MOVE
				entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.Mass = 7
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0)

			else
				entity:TakeDamage(entity.MaxHitPoints * 2, 0, EntityRef(entity), 0)
				entity.Velocity = Vector.Zero
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.launchedBoomFlyUpdate, EntityType.ENTITY_BOOMFLY)



--[[ Chubber ]]--
function mod:chubberInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chubberInit, EntityType.ENTITY_VIS)

function mod:chubberUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()

		if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 62 then
			mod:PlaySound(entity, SoundEffect.SOUND_MEAT_JUMPS, 0.9)

			-- Blood effect
			if sprite:IsEventTriggered("Shoot") then
				mod:ShootEffect(entity, 2, Vector(0, -14), Color.Default, 0.8, true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.chubberUpdate, EntityType.ENTITY_VIS)



--[[ Scarred Guts ]]--
function mod:scarredGutsDeath(entity)
	if entity.Variant == 1 then
		local flesh = Isaac.Spawn(EntityType.ENTITY_LEPER, 1, 0, entity.Position, entity.Velocity * 0.6, entity):ToNPC()
		flesh.State = NpcState.STATE_INIT

		if entity:IsChampion() then
			flesh:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.scarredGutsDeath, EntityType.ENTITY_GUTS)



--[[ Reduce Monstro 2 and Gish HP ]]--
function mod:monstro2Init(entity)
	local newHealth = 540
	if entity.SubType == 1 then
		newHealth = 460
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.monstro2Init, EntityType.ENTITY_MONSTRO2)



--[[ Death ]]--
-- Better Scythes
function mod:scytheInit(entity)
	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.Mass = 0.1
		mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 0.9)

		-- Get the parent's subtype
		if entity.SubType == 0 and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
			entity.SubType = entity.SpawnerEntity.SubType
		end

		if entity.SubType == 1 then
			entity.Scale = 1.1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.scytheInit, EntityType.ENTITY_DEATH)

-- Extra sounds
function mod:deathUpdate(entity)
	local sprite = entity:GetSprite()

	-- Hourglass sound
	if entity.Variant == 0 and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 21 then
		mod:PlaySound(nil, SoundEffect.SOUND_MENU_FLIP_DARK, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.deathUpdate, EntityType.ENTITY_DEATH)



--[[ Make Peep and the Bloat's eyes bounce off of them and each other ]]--
function mod:peepEyeCollision(entity, target, cock)
	if (entity.Variant == 10 or entity.Variant == 11) and target.Type == entity.Type then
		entity.Velocity = (entity.Position - target.Position):Normalized()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.peepEyeCollision, EntityType.ENTITY_PEEP)



--[[ Fistula Scarred Womb skin ]]--
function mod:fistulaScarredSkin(entity)
	if IRFConfig.matriarchFistula == true and entity.Variant == 0 then
		if entity.SubType == 0 and Game():GetRoom():GetBackdropType() == BackdropType.SCARRED_WOMB then
			entity.SubType = 1000 -- The subtype that Matriarch fistula pieces use
		end

		if entity.SubType == 1000 then
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_025_fistula_scarred.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaScarredSkin, EntityType.ENTITY_FISTULA_BIG)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaScarredSkin, EntityType.ENTITY_FISTULA_MEDIUM)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaScarredSkin, EntityType.ENTITY_FISTULA_SMALL)



--[[ Big Spiders ]]--
function mod:bigSpiderInit(entity)
	entity.MaxHitPoints = 13
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bigSpiderInit, EntityType.ENTITY_BIGSPIDER)



--[[ Classic eternal flies ]]--
function mod:eternalFlyInit(entity)
	if entity.Type == EntityType.ENTITY_ETERNALFLY or (FiendFolio and entity.Type == FiendFolio.FF.DeadFlyOrbital.ID and entity.Variant == FiendFolio.FF.DeadFlyOrbital.Var) then
		entity:GetData().isEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.eternalFlyInit)

function mod:eternalFlyUpdate(entity)
	if entity.Parent then
		entity.Velocity = entity.Parent.Velocity
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eternalFlyUpdate, EntityType.ENTITY_ETERNALFLY)

function mod:eternalFlyConvert(entity)
	if entity:GetData().isEternalFly then
		local sprite = entity:GetSprite()
		sprite:Load("gfx/attack eternal fly.anm2", true)
		sprite:Play("Fly", true)

		entity.MaxHitPoints = 10
		entity.HitPoints = entity.MaxHitPoints
		entity.I1 = 0
		entity.SubType = 96

		entity:GetData().isEternalFly = nil
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eternalFlyConvert, EntityType.ENTITY_ATTACKFLY)



--[[ Gurdy Jr. ]]--
function mod:gurdyJrUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("Attack03Start") and sprite:GetFrame() < 8 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurdyJrUpdate, EntityType.ENTITY_GURDY_JR)



--[[ Bone orbitals ]]--
function mod:boneOrbitalInit(entity)
	if entity.Variant == IRFentities.BoneOrbital then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		-- Play random animation
		entity:GetSprite():Play("Idle" .. math.random(0, 7), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.boneOrbitalInit, IRFentities.Type)

function mod:boneOrbitalUpdate(entity)
	if entity.Variant == IRFentities.BoneOrbital then
		if mod:OrbitParent(entity, entity.Parent, 4, 30 - entity.SubType * 12) == false then
			entity:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.boneOrbitalUpdate, IRFentities.Type)



--[[ Thrown Dip ]]--
function mod:thrownDipUpdate(entity)
	local data = entity:GetData()

	if data.thrownDip and (entity.State ~= NpcState.STATE_JUMP or entity:IsDead()) then
		entity:Morph(EntityType.ENTITY_DIP, data.thrownDip, 0, -1)
		mod:PlaySound(entity, SoundEffect.SOUND_BABY_HURT)
		data.thrownDip = nil

		entity.State = NpcState.STATE_INIT
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

		if entity.Variant == 3 then
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
		else
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.thrownDipUpdate, EntityType.ENTITY_SPIDER)



--[[ Gurglings ]]--
-- Different sprites for boss Gurglings
function mod:gurglingsInit(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		sprite:ReplaceSpritesheet(1, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:ReplaceSpritesheet(2, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gurglingsInit, EntityType.ENTITY_GURGLING)

-- Make them immuno to knockback while charging
function mod:gurglingsUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurglingsUpdate, EntityType.ENTITY_GURGLING)



--[[ Tube Worm effect color ]]--
function mod:tubeWormEffects(effect)
	for i, worm in pairs(Isaac.FindByType(EntityType.ENTITY_ROUND_WORM, 1, -1, false, false)) do
		if worm:ToNPC().State == NpcState.STATE_ATTACK and worm.Position:Distance(effect.Position) <= 2 and effect.FrameCount == 0 then -- Of course they don't have a spawner entity set...
			local bg = Game():GetRoom():GetBackdropType()

			if bg == BackdropType.FLOODED_CAVES or bg == BackdropType.DOWNPOUR then
				effect:GetSprite().Color = IRFcolors.TearEffect
			elseif bg == BackdropType.DROSS then
				effect:GetSprite().Color = IRFcolors.PukeEffect
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.tubeWormEffects, EffectVariant.BLOOD_EXPLOSION)



--[[ Homunculus, Begotten chain break ]]--
function mod:homunculusUpdate(entity)
	if entity.Variant == 0 then
		local data = entity:GetData()

		-- Get all cord segments
		if not data.cordSegments then
			data.cordSegments = {}

			for i, segment in pairs(Isaac.FindByType(entity.Type, 10, -1, false, false)) do
				if segment.Parent and segment.Parent.Index == entity.Index then
					table.insert(data.cordSegments, segment)
				end
			end


		-- Detached
		elseif (entity.State == NpcState.STATE_ATTACK or entity:HasMortalDamage()) and entity.I2 == 0 then
			entity.I2 = 1
			mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS)

			-- Blood effects
			for i, segment in pairs(data.cordSegments) do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 1, segment.Position, Vector.Zero, entity).SpriteOffset = Vector(0, -20)
			end
			data.cordSegments = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.homunculusUpdate, EntityType.ENTITY_HOMUNCULUS)

function mod:begottenUpdate(entity)
	if entity.Variant == 0 then
		local data = entity:GetData()

		-- Get all cord segments
		if not data.cordSegments then
			data.cordSegments = {}

			for i, segment in pairs(Isaac.FindByType(entity.Type, 10, -1, false, false)) do
				if segment.Parent and segment.Parent.Index == entity.Index then
					table.insert(data.cordSegments, segment)
				end
			end


		-- Detached
		elseif (entity.State == NpcState.STATE_ATTACK or entity:HasMortalDamage()) and entity.I2 == 0 then
			entity.I2 = 1
			mod:PlaySound(nil, SoundEffect.SOUND_CHAIN_BREAK)

			-- Chain gibs
			for i, segment in pairs(data.cordSegments) do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, segment.Position, mod:RandomVector(), entity):GetSprite().Color = Color(0.75,0.75,0.75, 1)
			end
			data.cordSegments = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.begottenUpdate, EntityType.ENTITY_BEGOTTEN)



--[[ Imp extra sounds ]]--
function mod:impUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Attack") and sprite:GetFrame() == 4 then
		mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0.9, 5)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.impUpdate, EntityType.ENTITY_IMP)



--[[ Mega Maw ]]--
function mod:megaMawUpdate(entity)
	local sprite = entity:GetSprite()
	local hopperCount = Isaac.CountEntities(nil, EntityType.ENTITY_HOPPER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_FLAMINGHOPPER, -1, -1)

	if entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 and hopperCount >= 3 then
		entity.State = NpcState.STATE_ATTACK2
		SFXManager():Stop(SoundEffect.SOUND_MOUTH_FULL)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaMawUpdate, EntityType.ENTITY_MEGA_MAW)

-- Prevent him from taking damage from his Flaming Hoppers
function mod:megaMawDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_FLAMINGHOPPER or damageSource.SpawnerType == EntityType.ENTITY_FLAMINGHOPPER then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.megaMawDMG, EntityType.ENTITY_MEGA_MAW)



--[[ Mega Fatty suction effects ]]--
function mod:megaFattyUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Sucking") then
		-- Sound
		if sprite:GetFrame() == 4 then
			mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE)

		elseif sprite:WasEventTriggered("StartSucking") then
			-- Attract rings
			if sprite:GetFrame() <= 25 and entity:IsFrame(8, 0) then
				local ring = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_ATTRACT, 0, entity.Position, Vector.Zero, entity):ToEffect()
				ring:FollowParent(entity)
				ring.ParentOffset = Vector(0, entity.Scale * -90)
				ring:Update()
			end

			-- Attract trails
			if sprite:GetFrame() <= 35 and entity:IsFrame(6, 0) then
				local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_ATTRACT, 1, entity.Position, Vector.Zero, entity):ToEffect()
				trail:FollowParent(entity)
				trail.ParentOffset = Vector(0, entity.Scale * -90)
				trail:Update()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaFattyUpdate, EntityType.ENTITY_MEGA_FATTY)



--[[ The Cage ]]--
function mod:cageUpdate(entity)
	-- Fix him having a hitbox before he lands
	if entity.State == NpcState.STATE_STOMP then
		if entity:GetSprite():GetFrame() < 4 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		else
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end

	-- Extra effects when bouncing off of walls
	elseif entity.State == NpcState.STATE_ATTACK and entity:CollidesWithGrid() then
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.6)
		Game():ShakeScreen(math.floor(entity.Scale * 5))
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cageUpdate, EntityType.ENTITY_CAGE)

function mod:cageCollide(entity, target, bool)
	if entity.State == NpcState.STATE_ATTACK and target.Type == EntityType.ENTITY_CAGE then
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.6)
		entity.Velocity = (entity.Position - target.Position):Normalized()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.cageCollide, EntityType.ENTITY_CAGE)



--[[ Red Ghost ]]--
function mod:redGhostUpdate(entity)
	local sprite = entity:GetSprite()

	if not entity:GetData().IndicatorBrim and IRFConfig.laserRedGhost == true and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
		local angle = 0
		if sprite:GetAnimation() == "ShootDown" then
			angle = 90
		elseif sprite:GetAnimation() == "ShootLeft" then
			angle = 180
		elseif sprite:GetAnimation() == "ShootUp" then
			angle = 270
		end

		mod:QuickTracer(entity, angle, Vector(0, entity.SpriteScale.Y * -25), 15, 1, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redGhostUpdate, EntityType.ENTITY_RED_GHOST)



--[[ Hush fixes ]]--
function mod:hushInit(entity)
	entity:GetData().hushFix = {
		lastState = 0,
		animation = "Idle"
	}
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.hushInit, EntityType.ENTITY_HUSH)

function mod:hushUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()

	-- Chill state
	if entity.State == 80085 then
		if sprite:IsFinished(data.hushFix.animation) then
			if (string.match(data.hushFix.animation, "FaceVanish")) then
				data.hushFix.animation = "FaceAppearDown"
				sprite:Play(data.hushFix.animation, true)

			elseif data.hushFix.animation == "LaserLoop" then
				data.hushFix.animation = "LaserEnd"
				sprite:Play(data.hushFix.animation, true)

			else
				sprite:Play("Wiggle", true)
			end
		end

		if entity.StateFrame <= 0 then
			entity.State = NpcState.STATE_IDLE
		else
			entity.StateFrame = entity.StateFrame -1
		end


	-- Chill tf out
	elseif entity.State == NpcState.STATE_IDLE and data.hushFix.lastState ~= NpcState.STATE_IDLE
	and entity.HitPoints / math.max(entity.MaxHitPoints, 0.001) < .5
	and entity.HitPoints / math.max(entity.MaxHitPoints, 0.001) > .01 then
		entity.State = 80085
		entity.StateFrame = 45
		data.hushFix.animation = sprite:GetAnimation()
	end

	data.hushFix.lastState = entity.State
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hushUpdate, EntityType.ENTITY_HUSH)

function mod:hushLaserUpdate(effect)
	local room = Game():GetRoom()

	if room:HasSlowDown() or room:GetBrokenWatchState() == 1 then
		local baseLength = 8.4
		local drowsyMult = 0.513

		local targetLength = baseLength * (effect.Target:ToPlayer().MoveSpeed or 1) * drowsyMult
		effect.Velocity = effect.Velocity:Resized(targetLength)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.hushLaserUpdate, EffectVariant.HUSH_LASER)



--[[ Delirium helper ]]--
function mod:deliriumHelper(entity)
	if not entity:GetData().wasDelirium then
		entity:GetData().wasDelirium = true
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.deliriumHelper, EntityType.ENTITY_DELIRIUM)



--[[ Tainted Faceless ]]--
function mod:tFacelessUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		if sprite:IsOverlayPlaying("Attack") and sprite:GetOverlayFrame() == 14 then
			local params = ProjectileParams()
			params.CircleAngle = 0.5
			params.Scale = 1.5
			entity:FireProjectiles(entity.Position, Vector(5, 6), 9, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.tFacelessUpdate, EntityType.ENTITY_FACELESS)



--[[ Cyst effect ]]--
function mod:cystEffect(effect)
	for i, cyst in pairs(Isaac.FindByType(EntityType.ENTITY_CYST, -1, -1, false, false)) do
		if cyst.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
			effect:GetSprite().Color = IRFcolors.CorpseYellow
			effect:GetSprite().Offset = Vector(0, -6)
			effect:FollowParent(cyst)
			effect.DepthOffset = cyst.DepthOffset + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.cystEffect, EffectVariant.BULLET_POOF)



--[[ Evis Cord ]]--
function mod:evisCordUpdate(entity)
	if entity.Variant == 10 and entity.Parent then
		entity.SplatColor = entity.Parent.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.evisCordUpdate, EntityType.ENTITY_EVIS)



--[[ Siren revive ]]--
function mod:sirenUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()


	-- Can't instantly change state when spawning a new one otherwise it crashes the game
	if data.revive then
		entity.State = NpcState.STATE_SPECIAL
		data.revive = nil

		-- Remove skull
		for i, skull in pairs(Isaac.FindByType(entity.Type, 1, -1, false, true)) do
			if skull.Position:Distance(entity.Position) <= 1 then
				skull:Remove()
			end
		end
	end


	-- Reviving
	if entity.State == NpcState.STATE_SPECIAL then
		-- Sike!
		if sprite:GetFrame() == 30 then
			entity.Visible = true

			-- Re-charm the reviver
			local minion = Isaac.Spawn(EntityType.ENTITY_SIREN_HELPER, 0, 0, entity.Position, Vector.Zero, nil):ToNPC()
			minion.Parent = entity
			minion.Target = entity.Target
			minion:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

			entity.Target.Parent = entity
			entity.Target = nil


		-- Restart boss music
		elseif sprite:GetFrame() == 40 then
			Game():GetRoom():PlayMusic()


		-- Item visual + health
		elseif sprite:IsEventTriggered("Sound") then
			-- Item effect
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, entity.Position, Vector.Zero, entity):ToEffect()
			data.itemEffect = effect
			effect:FollowParent(entity)
			effect.DepthOffset = entity.DepthOffset + 1

			local effectSprite = effect:GetSprite()
			effectSprite.Offset = Vector(0, -60)
			effectSprite:Load("gfx/005.100_collectible.anm2", true)
			effectSprite:Play("PlayerPickupSparkle", true)

			-- Heal + proper item sprite
			if entity.I1 == FamiliarVariant.DEAD_CAT then
				entity.HitPoints = entity.MaxHitPoints / 10
				effectSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/collectibles_081_deadcat.png")
			else
				entity.HitPoints = entity.MaxHitPoints / 2
				effectSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/collectibles_011_1up.png")
			end
			effectSprite:LoadGraphics()

			-- Reset back to normal
			entity.I1 = 0
			entity.I2 = 0
			entity:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)


		-- Get rid of the item visual
		elseif sprite:GetFrame() == 75 then
			data.itemEffect:Remove()
		end
	end


	-- Do fake death if she charmed 1up or Dead Cat
	if entity:HasMortalDamage() then
		for i, minion in pairs(Isaac.FindByType(EntityType.ENTITY_SIREN_HELPER, -1, -1, false, true)) do
			if minion.Parent.Index == entity.Index and minion.Target and (minion.Target.Variant == FamiliarVariant.DEAD_CAT or minion.Target.Variant == FamiliarVariant.ONE_UP) then
				entity.I2 = 100
				entity.Target = minion.Target
				minion:Kill()
				break
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.sirenUpdate, EntityType.ENTITY_SIREN)

function mod:sirenDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target:ToNPC().State == NpcState.STATE_SPECIAL and not target:GetSprite():WasEventTriggered("Sound") then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.sirenDMG, EntityType.ENTITY_SIREN)

-- Create new Siren from revive
function mod:sirenDeath(entity)
	if entity.I2 == 100 then
		local newSiren = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, entity.Position, entity.Velocity, entity):ToNPC()
		newSiren:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		newSiren:GetData().revive = true
		newSiren.Target = entity.Target
		newSiren.I1 = newSiren.Target.Variant
		newSiren.I2 = 100

		newSiren.Visible = false
		newSiren.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		newSiren:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)

		-- Remove heart drops
		for i, heart in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, -1, false, false)) do
			if heart.SpawnerEntity and heart.SpawnerEntity.Index == entity.Index then
				heart:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.sirenDeath, EntityType.ENTITY_SIREN)

-- Fix for revive familiars not going back to the player
function mod:sirenHelperDeath(entity)
	if entity.Target then
		entity.Target.Parent = nil
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.sirenHelperDeath, EntityType.ENTITY_SIREN_HELPER)