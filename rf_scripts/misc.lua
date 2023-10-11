local mod = ReworkedFoes



--[[ Clotty variants ]]--
function mod:ClottyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end

	-- Better I.Blob (+ Retribution Curdle) effect colors
	if entity.Variant == 2 or (Retribution and entity.Variant == 1873) then
		if entity:HasMortalDamage() then
			entity.SplatColor = Color.Default

		elseif entity.FrameCount == 25 then
			local c = mod.Colors.TearEffect
			entity.SplatColor = Color(c.R,c.G,c.B, 0.35, c.RO,c.GO,c.BO)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ClottyUpdate, EntityType.ENTITY_CLOTTY)

function mod:CloggyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CloggyUpdate, EntityType.ENTITY_CLOGGY)



--[[ Drowned Hive ]]--
function mod:DrownedHiveUpdate(entity, target, bool)
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.DrownedHiveUpdate, EntityType.ENTITY_HIVE)



--[[ Launched Boom Flies ]]--
function mod:LaunchedBoomFlyUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL and not entity:IsDead() and not entity:HasMortalDamage() then
		local sprite = entity:GetSprite()

		entity.Velocity = entity.V2
		mod:LoopingAnim(sprite, "Fly")

		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)


		-- Sprite trail
		local data = entity:GetData()
		if data.spriteTrail then
			data.spriteTrail.Velocity = entity.Position + Vector(0, -28) - data.spriteTrail.Position
		end


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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.LaunchedBoomFlyUpdate, EntityType.ENTITY_BOOMFLY)



--[[ Chubber ]]--
function mod:ChubberWormInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ChubberWormInit, EntityType.ENTITY_VIS)

function mod:ChubberUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ChubberUpdate, EntityType.ENTITY_VIS)



--[[ Scarred Guts ]]--
function mod:ScarredGutsDeath(entity)
	if entity.Variant == 1 then
		local flesh = Isaac.Spawn(EntityType.ENTITY_LEPER, 1, 0, entity.Position, entity.Velocity * 0.6, entity):ToNPC()
		flesh.State = NpcState.STATE_INIT

		if entity:IsChampion() then
			flesh:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ScarredGutsDeath, EntityType.ENTITY_GUTS)



--[[ Reduce Monstro 2 and Gish HP ]]--
function mod:Monstro2Init(entity)
	local newHealth = 540
	if entity.SubType == 1 then
		newHealth = 460
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.Monstro2Init, EntityType.ENTITY_MONSTRO2)



--[[ Death ]]--
-- Better Scythes
function mod:ScytheInit(entity)
	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.Mass = 1
		mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 0.9)

		-- Get the parent's subtype
		if entity.SubType == 0 and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
			entity.SubType = entity.SpawnerEntity.SubType
		end

		-- Black champion's scythes are bigger
		if entity.SubType == 1 then
			entity.Scale = 1.1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ScytheInit, EntityType.ENTITY_DEATH)

-- Hourglass sound
function mod:DeathUpdate(entity)
	if entity.Variant == 0 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() == 21 then
		mod:PlaySound(nil, SoundEffect.SOUND_MENU_FLIP_DARK, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DeathUpdate, EntityType.ENTITY_DEATH)



--[[ Make Peep and the Bloat's eyes bounce off of them and each other ]]--
function mod:PeepEyeCollision(entity, target, bool)
	if (entity.Variant == 10 or entity.Variant == 11) and target.Type == entity.Type then
		entity.Velocity = (entity.Position - target.Position):Normalized()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.PeepEyeCollision, EntityType.ENTITY_PEEP)



--[[ Increase Loki and Lokii's HP ]]--
function mod:LokiInit(entity)
	entity.MaxHitPoints = 420
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.LokiInit, EntityType.ENTITY_LOKI)



--[[ Fistula Scarred Womb skin ]]--
function mod:FistulaScarredSkin(entity)
	if entity.Variant == 0 then
		if entity.SubType == 0 and Game():GetRoom():GetBackdropType() == BackdropType.SCARRED_WOMB then
			entity.SubType = 1000 -- The subtype that Matriarch Fistula pieces use
		end

		if entity.SubType == 1000 then
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_025_fistula_scarred.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_BIG)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_MEDIUM)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_SMALL)



--[[ Big Spiders HP nerf ]]--
function mod:BigSpiderInit(entity)
	entity.MaxHitPoints = 13
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BigSpiderInit, EntityType.ENTITY_BIGSPIDER)



--[[ Classic eternal flies ]]--
function mod:EternalFlyInit(entity)
	if entity.Type == EntityType.ENTITY_ETERNALFLY or (FiendFolio and entity.Type == FiendFolio.FF.DeadFlyOrbital.ID and entity.Variant == FiendFolio.FF.DeadFlyOrbital.Var) then
		entity:GetData().isEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.EternalFlyInit)

function mod:EternalFlyUpdate(entity)
	-- Make them properly keep up with their parents
	if entity.Parent then
		entity.Velocity = entity.Parent.Velocity
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EternalFlyUpdate, EntityType.ENTITY_ETERNALFLY)

function mod:EternalFlyConvert(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EternalFlyConvert, EntityType.ENTITY_ATTACKFLY)



--[[ Gurdy Jr. ]]--
function mod:GurdyJrUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("Attack03Start") and sprite:GetFrame() < 8 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GurdyJrUpdate, EntityType.ENTITY_GURDY_JR)



--[[ Bone orbitals ]]--
function mod:BoneOrbitalInit(entity)
	if entity.Variant == mod.Entities.BoneOrbital then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		-- Play random animation
		entity:GetSprite():Play("Idle" .. math.random(0, 7), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BoneOrbitalInit, mod.Entities.Type)

function mod:BoneOrbitalUpdate(entity)
	if entity.Variant == mod.Entities.BoneOrbital then
		if mod:OrbitParent(entity, entity.Parent, 4, 30 - entity.SubType * 12) == false then
			entity:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BoneOrbitalUpdate, mod.Entities.Type)



--[[ Thrown Dips ]]--
function mod:ThrownDipUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ThrownDipUpdate, EntityType.ENTITY_SPIDER)



--[[ Gurglings ]]--
-- Different sprites for boss Gurglings
function mod:GurglingInit(entity)
	if entity.Variant == 1 and (entity.SubType == 0 or entity.SubType == 500) then
		local sprite = entity:GetSprite()
		sprite:ReplaceSpritesheet(1, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:ReplaceSpritesheet(2, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GurglingInit, EntityType.ENTITY_GURGLING)

-- Make them immune to knockback while charging
function mod:GurglingUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GurglingUpdate, EntityType.ENTITY_GURGLING)



--[[ Tube Worm effect color ]]--
function mod:TubeWormEffects(effect)
	for i, worm in pairs(Isaac.FindByType(EntityType.ENTITY_ROUND_WORM, 1, -1, false, false)) do
		if worm:ToNPC().State == NpcState.STATE_ATTACK and worm.Position:Distance(effect.Position) <= 2 and effect.FrameCount == 0 then -- Of course they don't have a spawner entity set...
			local bg = Game():GetRoom():GetBackdropType()

			-- Boiler water
			if FFGRACE and FFGRACE.STAGE.Boiler:IsStage() then
				local c = FFGRACE.ColorBoilerWaterEffect
				effect:GetSprite().Color = Color(0,0,0, 1, c.R,c.G,c.B)
			-- Regular water
			elseif bg == BackdropType.FLOODED_CAVES or bg == BackdropType.DOWNPOUR then
				effect:GetSprite().Color = mod.Colors.TearEffect
			-- Shit water
			elseif bg == BackdropType.DROSS then
				effect:GetSprite().Color = mod.Colors.PukeEffect
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.TubeWormEffects, EffectVariant.BLOOD_EXPLOSION)



--[[ Homunculus, Begotten chain break ]]--
function mod:HomunculusUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HomunculusUpdate, EntityType.ENTITY_HOMUNCULUS)

function mod:BegottenUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BegottenUpdate, EntityType.ENTITY_BEGOTTEN)



--[[ Imp extra sounds ]]--
function mod:ImpUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Attack") and sprite:GetFrame() == 4 then
		mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0.9, 5)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ImpUpdate, EntityType.ENTITY_IMP)



--[[ Mega Maw ]]--
function mod:MegaMawUpdate(entity)
	local sprite = entity:GetSprite()
	local hopperCount = Isaac.CountEntities(nil, EntityType.ENTITY_HOPPER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_FLAMINGHOPPER, -1, -1)

	-- Limit his Hopper count to 3
	if entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 and hopperCount >= 3 then
		entity.State = NpcState.STATE_ATTACK2
		SFXManager():Stop(SoundEffect.SOUND_MOUTH_FULL)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MegaMawUpdate, EntityType.ENTITY_MEGA_MAW)

-- Prevent him from taking damage from his Flaming Hoppers
function mod:MegaMawDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_FLAMINGHOPPER or damageSource.SpawnerType == EntityType.ENTITY_FLAMINGHOPPER then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MegaMawDMG, EntityType.ENTITY_MEGA_MAW)



--[[ Mega Fatty suction effects ]]--
function mod:MegaFattyUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MegaFattyUpdate, EntityType.ENTITY_MEGA_FATTY)



--[[ The Cage ]]--
-- Reduce his ridiculous health
function mod:CageInit(entity)
	local newHealth = 720
	if entity.SubType == 2 then
		newHealth = 360
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CageInit, EntityType.ENTITY_CAGE)

function mod:CageUpdate(entity)
	-- Fix him having a hitbox before he lands
	if entity.State == NpcState.STATE_STOMP then
		if entity:GetSprite():GetFrame() < 4 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		else
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end

	-- Extra effects when bouncing off of walls
	elseif entity.State == NpcState.STATE_ATTACK and entity:CollidesWithGrid() then
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
		Game():ShakeScreen(math.floor(entity.Scale * 4))
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CageUpdate, EntityType.ENTITY_CAGE)

-- Make them bounce off of each other
function mod:CageCollide(entity, target, bool)
	if entity.State == NpcState.STATE_ATTACK and (target.Type == entity.Type or target.Type == EntityType.ENTITY_SISTERS_VIS) then
		entity.Velocity = (entity.Position - target.Position):Normalized()
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.CageCollide, EntityType.ENTITY_CAGE)



--[[ Red Ghost ]]--
function mod:RedGhostUpdate(entity)
	local sprite = entity:GetSprite()

	if not entity:GetData().IndicatorBrim and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RedGhostUpdate, EntityType.ENTITY_RED_GHOST)



--[[ Delirium helper ]]--
function mod:DeliriumHelper(entity)
	if not entity:GetData().wasDelirium then
		entity:GetData().wasDelirium = true
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DeliriumHelper, EntityType.ENTITY_DELIRIUM)



--[[ Tainted Faceless ]]--
function mod:TaintedFacelessUpdate(entity)
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TaintedFacelessUpdate, EntityType.ENTITY_FACELESS)



--[[ Cyst effect ]]--
function mod:CystEffect(effect)
	for i, cyst in pairs(Isaac.FindByType(EntityType.ENTITY_CYST, -1, -1, false, false)) do
		if cyst.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
			effect:GetSprite().Color = mod.Colors.CorpseYellow
			effect:GetSprite().Offset = Vector(0, -6)
			effect:FollowParent(cyst)
			effect.DepthOffset = cyst.DepthOffset + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.CystEffect, EffectVariant.BULLET_POOF)



--[[ Evis Cord ]]--
function mod:EvisCordUpdate(entity)
	if entity.Variant == 10 and entity.Parent then
		entity.SplatColor = entity.Parent.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EvisCordUpdate, EntityType.ENTITY_EVIS)



--[[ Decrease Reap Creep's HP ]]--
function mod:ReapCreepInit(entity)
	entity.MaxHitPoints = 600
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ReapCreepInit, EntityType.ENTITY_REAP_CREEP)



--[[ Bumbino make sticky nickel go boom!! ]]--
function mod:BumbinoUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_MOVE then
		-- Find any sticky nickels nearby
		for _, pickup in pairs(Isaac.FindInRadius(entity.Position, 180, EntityPartition.PICKUP)) do
			if pickup.Variant == PickupVariant.PICKUP_COIN and pickup.SubType == CoinSubType.COIN_STICKYNICKEL and pickup:ToPickup():CanReroll() == true then
				entity.State = NpcState.STATE_ATTACK4
				sprite:Play("ButtBomb", true)
				entity.Target = pickup
				sprite.FlipX = entity.Position.X > pickup.Position.X
				break
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BumbinoUpdate, EntityType.ENTITY_BUMBINO)

-- Change his Butt Bomb's velocity to target the sticky nickel
function mod:BumbinoBombInit(bomb)
	if bomb.SpawnerType == EntityType.ENTITY_BUMBINO and bomb.SpawnerEntity and bomb.SpawnerEntity.Target and bomb.SpawnerEntity.Target.Type == EntityType.ENTITY_PICKUP then
		local speed = bomb.Position:Distance(bomb.SpawnerEntity.Target.Position) / 11
		bomb.Velocity = (bomb.SpawnerEntity.Target.Position - bomb.Position):Resized(speed)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, mod.BumbinoBombInit, BombVariant.BOMB_BUTT)



--[[ One time effect ]]--
function mod:OneTimeEffectUpdate(effect)
	if effect:GetSprite():IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.OneTimeEffectUpdate, mod.Entities.OneTimeEffect)