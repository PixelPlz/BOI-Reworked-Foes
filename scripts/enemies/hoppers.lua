local mod = BetterMonsters

local function stopSlidingAfterHop(entity)
	local sprite = entity:GetSprite()

	if (entity.Type == EntityType.ENTITY_HOPPER and entity.Variant == 3 and sprite:IsEventTriggered("Land")) or (sprite:IsPlaying("Hop") and sprite:GetFrame() == 22) then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end



--[[ Hoppers / Trites ]]--
function mod:hopperUpdate(entity)
	stopSlidingAfterHop(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hopperUpdate, EntityType.ENTITY_HOPPER)

--[[ Leapers ]]--
function mod:leaperUpdate(entity)
	stopSlidingAfterHop(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.leaperUpdate, EntityType.ENTITY_LEAPER)

--[[ Ministro ]]--
function mod:ministroUpdate(entity)
	stopSlidingAfterHop(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ministroUpdate, EntityType.ENTITY_MINISTRO)

--[[ Pon ]]--
function mod:ponUpdate(entity)
	stopSlidingAfterHop(entity)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ponUpdate, EntityType.ENTITY_PON)



--[[ Flaming Hopper ]]--
function mod:flamingHopperInit(entity)
	entity.MaxHitPoints = 10
	entity.HitPoints = entity.MaxHitPoints
	entity.ProjectileCooldown = 1

	-- Purple variant
	if entity.SubType == 1 then
		entity:GetSprite():Load("gfx/054.000_flaming hopper_purple.anm2")
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.flamingHopperInit, EntityType.ENTITY_FLAMINGHOPPER)

function mod:flamingHopperUpdate(entity)
	local sprite = entity:GetSprite()

	local color = nil
	if entity.SubType >= 1 then
		color = Color(0.6,0.6,0.6, 1, 0.3,0,0.6)
	end
	mod:EmberParticles(entity, Vector(0, -28), nil, color)


	-- Attack after 3 jumps
	if sprite:IsPlaying("Hop") then
		if sprite:GetFrame() == 0 then
			if entity.ProjectileCooldown <= 0 then
				sprite:Play("Attack", true)
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

		elseif sprite:GetFrame() == 22 then
			entity.Velocity = Vector.Zero
			entity.TargetPosition = entity.Position
		end


	-- Ground pound
	elseif sprite:IsPlaying("Attack") then
		-- Wind-up
		if sprite:GetFrame() < 12 then
			entity.Velocity = Vector.Zero

		-- Reset position offset (for the Gate's spawn)
		elseif entity.PositionOffset.Y < 0 and sprite:GetFrame() == 25 then
			entity.PositionOffset = Vector.Zero
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end


		if sprite:IsEventTriggered("Land") then
			entity.Velocity = Vector.Zero
			entity.TargetPosition = entity.Position
			entity.ProjectileCooldown = 3

			local data = entity:GetData()
			data.startFireRing = true
			data.fireRingIndex = 0
			data.fireRingDelay = 0

			mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 1.1)
		end

		mod:FireRing(entity, 70, entity.SubType)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingHopperUpdate, EntityType.ENTITY_FLAMINGHOPPER)

-- Turn regular hoppers into purple flaming ones when burnt by Mega Maw or other purple flaming hoppers
function mod:hopperIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 0 and
	((damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.Entity:ToProjectile():HasProjectileFlags(ProjectileFlags.FIRE))
	or (damageSource.Type == EntityType.ENTITY_EFFECT and damageSource.Variant == EffectVariant.FIRE_JET and damageSource.Entity.SubType == 1)) then
		target:ToNPC():Morph(EntityType.ENTITY_FLAMINGHOPPER, 0, 1, target:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)

		target:GetSprite():Load("gfx/054.000_flaming hopper_purple.anm2")

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hopperIgnite, EntityType.ENTITY_HOPPER)