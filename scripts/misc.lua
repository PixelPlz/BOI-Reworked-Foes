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

		-- Spawn bubble projectiles instead of chargers on death
		if entity:HasMortalDamage() and entity:IsDead() then
			for i = 1, 8 do
				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 90

				params.Acceleration = 1.1
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.2
				params.Scale = 1 + (mod:Random(5) * 0.1)
				params.Variant = ProjectileVariant.PROJECTILE_TEAR

				mod:FireProjectiles(entity, entity.Position, mod:RandomVector(mod:Random(3, 5)), 0, params).CollisionDamage = 1
			end

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
				entity:TakeDamage(entity.MaxHitPoints * 2, 0, EntityRef(nil), 0)
				entity.Velocity = Vector.Zero
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.launchedBoomFlyUpdate, EntityType.ENTITY_BOOMFLY)



--[[ Ultra Pride baby ]]--
function mod:florianInit(entity)
	if entity.Variant == 2 then
		local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, nil)
		fly.Parent = entity
		entity.Child = fly
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.florianInit, EntityType.ENTITY_BABY)



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
local function fistulaScarredSkin(entity)
	if IRFconfig.matriarchFistula == true and entity.Variant == 0 then
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

function mod:fistulaBigInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaBigInit, EntityType.ENTITY_FISTULA_BIG)

function mod:fistulaMediumInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaMediumInit, EntityType.ENTITY_FISTULA_MEDIUM)

function mod:fistulaSmallInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaSmallInit, EntityType.ENTITY_FISTULA_SMALL)



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
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurglingsUpdate, EntityType.ENTITY_GURGLING)



--[[ Homunculus, Begotten chain break ]]--
function mod:homunculusChainBreak(entity)
	if entity.Variant == 10 then
		mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS, 0.65)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 1, entity.Position, Vector.Zero, entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.homunculusChainBreak, EntityType.ENTITY_HOMUNCULUS)

function mod:begottenChainBreak(entity)
	if entity.Variant == 10 then
		mod:PlaySound(nil, SoundEffect.SOUND_CHAIN_BREAK, 0.65)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, 0, entity.Position, mod:RandomVector(), entity):GetSprite().Color = Color(0.75,0.75,0.75, 1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, mod.begottenChainBreak, EntityType.ENTITY_BEGOTTEN)



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

	if IRFconfig.laserRedGhost == true and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() == 0 then
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



--[[ Evis Cord ]]--
function mod:evisCordUpdate(entity)
	if entity.Variant == 10 and entity.Parent then
		entity.SplatColor = entity.Parent.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.evisCordUpdate, EntityType.ENTITY_EVIS)