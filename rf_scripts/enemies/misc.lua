local mod = ReworkedFoes



--[[ Clotty variants ]]--
-- Better I.Blob (+ Retribution Curdle) effect colors
function mod:IBlobInit(entity)
	if entity.Variant == 2 or (Retribution and entity.Variant == 1873) then
		local c = mod.Colors.TearEffect
		entity.SplatColor = Color(c.R,c.G,c.B, 0.3, c.RO,c.GO,c.BO)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.IBlobInit, EntityType.ENTITY_CLOTTY)

function mod:ClottyUpdate(entity)
	-- Don't move around while shooting
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = mod:StopLerp(entity.Velocity, 0.5)

	-- Actually face towards the movement direction instead of only sometimes doing it
	else
		mod:FlipTowardsMovement(entity, entity:GetSprite())
	end

	-- I.Blob (+ Retribution Curdle) gib color
	if (entity.Variant == 2 or (Retribution and entity.Variant == 1873))
	and (entity:HasMortalDamage() or entity:IsDead()) then
		entity.SplatColor = Color.Default
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ClottyUpdate, EntityType.ENTITY_CLOTTY)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ClottyUpdate, EntityType.ENTITY_CLOGGY)



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



--[[ Angelic Baby ]]--
function mod:BabyUpdate(entity)
	local sprite = entity:GetSprite()

	-- Stop them from moving while teleporting
	if sprite:IsPlaying("Vanish2") then
		entity.Velocity = Vector.Zero
	end


	-- Angelic Babies create a lightbeam at their teleport destination
	if entity.Variant == 1 and entity.SubType == 0 then
		if sprite:IsPlaying("Vanish") and sprite:IsEventTriggered("Jump") then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity.TargetPosition, Vector.Zero, entity).DepthOffset = entity.DepthOffset - 10

		-- Projectiles
		elseif sprite:IsPlaying("Vanish2") and sprite:GetFrame() == 2 then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Color = Color(1,1,1, 1, 0.25,0.25,0.25)
			entity:FireProjectiles(entity.Position, Vector(10, 4), 6, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BabyUpdate, EntityType.ENTITY_BABY)



--[[ Chubber ]]--
function mod:ChubberWormInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 1
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
		local flesh = Isaac.Spawn(EntityType.ENTITY_LEPER, 1, 0, entity.Position, entity.Velocity / 2, entity):ToNPC()
		flesh.State = NpcState.STATE_INIT

		if entity:IsChampion() then
			flesh:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ScarredGutsDeath, EntityType.ENTITY_GUTS)



--[[ Holy Leech ]]--
-- Death effects
function mod:HolyLeechUpdate(entity)
	if entity.Variant == 2 and entity.State == NpcState.STATE_SPECIAL then
		local sprite = entity:GetSprite()
		entity.Velocity = Vector.Zero

		-- Shoot the light beam
		if sprite:IsEventTriggered("Spawn") then
			local target = entity:GetPlayerTarget()
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, target.Position, Vector.Zero, entity)
			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.8, 0.8)
		end

		if sprite:IsFinished() then
			entity:Kill()
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.HolyLeechUpdate, EntityType.ENTITY_LEECH)

-- Start the death animation
function mod:HolyLeechRender(entity, offset)
	if entity.Variant == 2 and mod:ShouldDoRenderEffects()
	and entity:HasMortalDamage() and entity.State ~= NpcState.STATE_SPECIAL then
		entity.State = NpcState.STATE_SPECIAL
		entity:GetSprite():Play("Death", true)

		entity.HitPoints = 1000
		entity.MaxHitPoints = 0
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.Visible = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.HolyLeechRender, EntityType.ENTITY_LEECH)



--[[ Big Spiders HP nerf ]]--
function mod:BigSpiderInit(entity)
	mod:ChangeMaxHealth(entity, 13)
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



--[[ Make Dinga hitboxes not stupidly small ]]--
function mod:DingaInit(entity)
	entity:SetSize(28, Vector(1, 0.75), 16)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DingaInit, EntityType.ENTITY_DINGA)



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

		mod:QuickTracer(entity, angle, Vector(0, entity.SpriteScale.Y * -25), 6, 3)
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



--[[ Cohort ]]--
function mod:StopSlidingAfterHopCohortEdition(entity)
	if entity.State == NpcState.STATE_JUMP and entity:GetSprite():WasEventTriggered("Land") then
		entity.Velocity = mod:StopLerp(entity.Velocity)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHopCohortEdition, EntityType.ENTITY_COHORT)



--[[ Cyst effect ]]--
function mod:CystEffect(effect)
	if not (LastJudgement and LastJudgement.STAGE.Mortis:IsStage()) then
		for i, cyst in pairs(Isaac.FindByType(EntityType.ENTITY_CYST, -1, -1, false, false)) do
			if effect.FrameCount <= 0 and effect.Position:Distance(cyst.Position) <= 0 then
				effect:GetSprite().Color = mod.Colors.CorpseYellow
				effect:GetSprite().Offset = Vector(0, -6)
				effect:FollowParent(cyst)
				effect.DepthOffset = cyst.DepthOffset + 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.CystEffect, EffectVariant.BULLET_POOF)



--[[ Evis ]]--
function mod:EvisCordUpdate(entity)
	if entity.Variant == 10 then
		-- Keep the desired depth offset
		if entity:GetData().DepthOffset then
			entity.DepthOffset = entity:GetData().DepthOffset
		end

		-- Make sure the correct splat color is used
		if entity:GetData().SplatColor then
			entity.SplatColor = entity:GetData().SplatColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EvisCordUpdate, EntityType.ENTITY_EVIS)



--[[ Needle / Pasty appear animation ]]--
function mod:NeedleAppearInit(entity)
	if mod.Config.AppearNeedles then
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
	if mod.Config.NoHiddenDust and entity.V1.X < 0.1 and entity:IsFrame(11, 0) then -- Only when fully invisible
		local dust = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, entity.Position + Vector(0, -24) + mod:RandomVector(10), Vector.Zero, entity)
		dust:GetSprite().Color = mod.Colors.DustTrail
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