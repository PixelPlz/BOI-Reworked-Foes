local mod = ReworkedFoes



--[[ Hoppers / Trite / Leapers / Ministro / Pon ]]--
function mod:StopSlidingAfterHop(entity)
	local sprite = entity:GetSprite()

	if (entity.Type == EntityType.ENTITY_HOPPER and entity.Variant == 3 and sprite:IsEventTriggered("Land"))
	or (sprite:IsPlaying("Hop") and sprite:GetFrame() == 22) then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHop, EntityType.ENTITY_HOPPER)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHop, EntityType.ENTITY_LEAPER)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHop, EntityType.ENTITY_MINISTRO)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StopSlidingAfterHop, EntityType.ENTITY_PON)



--[[ Flaming Hopper ]]--
function mod:FlamingHopperInit(entity)
	mod:ChangeMaxHealth(entity, 10)
	entity.ProjectileCooldown = 1

	-- Purple variant
	if entity.SubType == 1 then
		entity:GetSprite():Load("gfx/054.000_flaming hopper_purple.anm2")
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FlamingHopperInit, EntityType.ENTITY_FLAMINGHOPPER)

function mod:FlamingHopperUpdate(entity)
	local sprite = entity:GetSprite()

	mod:StopSlidingAfterHop(entity)


	-- Ember particles
	local emberColor = nil
	local splatColor = mod.Colors.EmberFade

	if entity.SubType == 1 then
		emberColor = Color(0.6,0.6,0.6, 1, 0.3,0,0.6)
		splatColor = mod.Colors.PurpleFade
	end

	mod:EmberParticles(entity, Vector(0, -28), nil, emberColor)


	-- Attack after 3 jumps
	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 0 then
		if entity.ProjectileCooldown <= 0 then
			sprite:Play("Attack", true)
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Ground pound
	elseif sprite:IsPlaying("Attack") then
		-- Wind-up
		if not sprite:WasEventTriggered("Jump") then
			entity.Velocity = Vector.Zero

		-- Launched by Gate
		elseif entity.PositionOffset.Y < 0 then
			-- Reset offset, enable collision
			if sprite:GetFrame() == 25 then
				entity.PositionOffset = Vector.Zero
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

			-- No collision before landing
			else
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end
		end


		-- Stop moving before stomping down
		if sprite:IsEventTriggered("Stop") then
			entity.TargetPosition = entity.Position

		-- Fire ring
		elseif sprite:IsEventTriggered("Land") then
			entity.Velocity = Vector.Zero
			entity.TargetPosition = entity.Position
			entity.ProjectileCooldown = 3

			for i = 1, 6 do
				-- Get position
				local angle = 360 / 6 * i
				local distance = 45
				local pos = entity.Position + Vector.FromAngle(angle):Resized(distance)

				if Game():GetRoom():IsPositionInRoom(pos, 0) then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, entity.SubType, pos, Vector.Zero, entity)
				end
			end

			-- Effects
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, entity.Position, Vector.Zero, entity).Color = splatColor
			mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 1.1)
		end
	end


	-- Cool gibs
	if entity:HasMortalDamage() then
		entity.SplatColor = splatColor
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FlamingHopperUpdate, EntityType.ENTITY_FLAMINGHOPPER)

-- Turn regular Hoppers into purple flaming ones when burnt by Mega Maw or purple fire jets
function mod:HopperIgnite(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 0
	and ((damageSource.Type == EntityType.ENTITY_EFFECT and damageSource.Variant == EffectVariant.FIRE_JET and damageSource.Entity.SubType == 1) -- Purple Fire Jet
	or (damageSource.Entity and damageSource.Entity.SpawnerType == EntityType.ENTITY_MEGA_MAW -- Mega Maw fire projectile
	and damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.Entity:ToProjectile():HasProjectileFlags(ProjectileFlags.FIRE))) then
		entity:ToNPC():Morph(EntityType.ENTITY_FLAMINGHOPPER, 0, 1, entity:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		entity:GetSprite():Load("gfx/054.000_flaming hopper_purple.anm2")
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.HopperIgnite, EntityType.ENTITY_HOPPER)