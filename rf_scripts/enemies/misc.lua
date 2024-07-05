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



--[[ Fat Attack Fly ]]--
function mod:FatFuckFlyInit(entity)
	if entity.Variant == 0 and entity.Scale == 1.25 -- Big fly
	and entity.SpawnerType == EntityType.ENTITY_DUKE and entity.SpawnerVariant == 0 then -- From Duke of Flies
		entity.Scale = 1
		entity:Morph(entity.Type, mod.Entities.FatAFly, 0, -1)
		entity:Update()
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FatFuckFlyInit, EntityType.ENTITY_ATTACKFLY)



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



--[[ Holy Leech ]]--
function mod:HolyLeechRender(entity, offset)
	if entity.Variant == 2 and mod:ShouldDoRenderEffects() then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Start the death animation
		if entity:IsDead() and entity.State ~= NpcState.STATE_UNIQUE_DEATH then
			sprite:Play("Death", true)
			entity:KillUnique()
			entity.Visible = true


		-- Light beam
		elseif sprite:IsEventTriggered("Spawn") and not data.DeathBeam then
			data.DeathBeam = true

			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity:GetPlayerTarget().Position, Vector.Zero, entity)
			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0.8)


		-- Death gibs
		elseif sprite:IsFinished("Death") and not data.DeathGibs then
			data.DeathGibs = true
			entity:BloodExplode()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.HolyLeechRender, EntityType.ENTITY_LEECH)



--[[ Big Spiders HP nerf ]]--
function mod:BigSpiderInit(entity)
	entity.MaxHitPoints = 13
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BigSpiderInit, EntityType.ENTITY_BIGSPIDER)



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



--[[ Flaming Fatty ]]--
function mod:FlamingFattyUpdate(entity)
	if entity.Variant == 2 then
		mod:EmberParticles(entity, Vector(0, -48))

		-- Fire ring
		if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():IsEventTriggered("Shoot") then
			mod:CreateFireRing(entity, 0, 2, 10, 40, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FlamingFattyUpdate, EntityType.ENTITY_FATTY)

-- Turn regular fatties into flaming ones when burnt
function mod:FattyIgnite(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if Game():GetRoom():HasWater() == false -- Not in a flooded room
	and entity.Variant == 0 and (damageFlags & DamageFlag.DAMAGE_FIRE > 0) then
		entity:ToNPC():Morph(EntityType.ENTITY_FATTY, 2, 0, entity:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.FattyIgnite, EntityType.ENTITY_FATTY)



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



-- Make Dinga hitboxes not stupidly small
function mod:DingaUpdate(entity)
	if entity.FrameCount <= 1 then
		entity:SetSize(30 * entity.Scale, Vector(1, 0.75), 12)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DingaUpdate, EntityType.ENTITY_DINGA)



--[[ Imp extra sounds ]]--
function mod:ImpUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Attack") and sprite:GetFrame() == 4 then
		mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0.9, 5)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ImpUpdate, EntityType.ENTITY_IMP)



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



--[[ Mushroom ]]--
function mod:MushroomDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity:ToNPC().State == NpcState.STATE_IDLE and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		entity:TakeDamage(damageAmount, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		entity:SetColor(mod.Colors.ArmorFlash, 2, 0, false, false)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MushroomDMG, EntityType.ENTITY_MUSHROOM)



--[[ Blaster ]]--
function mod:BlasterDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if not (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		entity:TakeDamage(damageAmount, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		entity:SetColor(mod.Colors.ArmorFlash, 2, 0, false, false)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BlasterDMG, EntityType.ENTITY_BLASTER)



--[[ Tainted Faceless ]]--
function mod:TaintedFacelessUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		if sprite:IsOverlayPlaying("Attack") and sprite:GetOverlayFrame() == 14 then
			local params = ProjectileParams()
			params.CircleAngle = mod:DegreesToRadians(30)
			params.Scale = 1.5
			params.FallingSpeedModifier = 1
			params.FallingAccelModifier = -0.065
			entity:FireProjectiles(entity.Position, Vector(6, 6), 9, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TaintedFacelessUpdate, EntityType.ENTITY_FACELESS)



--[[ Cohort ]]--
function mod:StopSlidingAfterHopCohortEdition(entity)
	if entity.State == NpcState.STATE_JUMP and entity:GetSprite():WasEventTriggered("Land") then
		entity.Velocity = mod:StopLerp(entity.Velocity)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHopCohortEdition, EntityType.ENTITY_COHORT)



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



--[[ Needle / Pasty appear animation ]]--
function mod:NeedleAppearInit(entity)
	if mod.Config.AppearNeedles == true then
		entity:GetSprite():Play("Appear", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NeedleAppearInit, EntityType.ENTITY_NEEDLE)

function mod:NeedleAppearUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("Appear") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.NeedleAppearUpdate, EntityType.ENTITY_NEEDLE)



--[[ Dust trail ]]--
function mod:DustParticles(entity)
	if mod.Config.NoHiddenDust == true
	and entity.V1.X < 0.1 and entity:IsFrame(12, 0) then -- Only when fully invisible
		for i = 1, math.random(1, 2) do
			local dust = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, entity.Position + Vector(0, -24) + mod:RandomVector(10), Vector.Zero, entity)
			dust:GetSprite().Color = mod.Colors.DustTrail
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DustParticles, EntityType.ENTITY_DUST)



--[[ Sky Beam size fix ]]--
function mod:SkyBeamInit(effect)
	if effect.SpawnerEntity and effect.SpawnerEntity:ToNPC() then
		effect.Size = 18
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.SkyBeamInit, EffectVariant.CRACK_THE_SKY)



--[[ One time effect ]]--
function mod:OneTimeEffectUpdate(effect)
	if effect:GetSprite():IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.OneTimeEffectUpdate, mod.Entities.OneTimeEffect)