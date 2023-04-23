local mod = BetterMonsters



local function hostBreak(entity)
	local type = EntityType.ENTITY_HOST
	local variant = 1
	local subtype = 0


	-- Get the entity to turn into
	if entity.Type == EntityType.ENTITY_HOST then
		if entity.Variant == 0 and entity.SubType == 250 then -- Stinky FF compat
			variant = 1
			subtype = 251
		elseif entity.Variant == 3 then
			variant = 3
			subtype = 40
		end

	elseif entity.Type == EntityType.ENTITY_MOBILE_HOST then
		type = EntityType.ENTITY_FLESH_MOBILE_HOST
		variant = 0
	
	elseif entity.Type == EntityType.ENTITY_FLOATING_HOST then
		type = entity.Type
	end


	-- Turn into the new entity
	entity:ToNPC():Morph(type, variant, subtype, entity:GetChampionColorIdx())
	if entity.Type == EntityType.ENTITY_FLESH_MOBILE_HOST then
		entity:GetSprite():PlayOverlay("Bombed", true)
	else
		entity:GetSprite():Play("Bombed", true)
	end
	entity:ToNPC().StateFrame = 10


	-- Effects
	for i = 0, 5 do
		local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, Vector.FromAngle(math.random(0, 359)) * 3, entity):ToEffect()
		rocks:GetSprite():Play("rubble", true)
		rocks.State = 2
	end
	SFXManager():Play(SoundEffect.SOUND_ROCK_CRUMBLE)
end



function mod:hostUpdate(entity)
	local sprite = entity:GetSprite()

	-- Soft Host / Flesh Floast
	if (entity.Type == EntityType.ENTITY_HOST and entity.Variant == 3 and entity.SubType == 40) or (entity.Type == EntityType.ENTITY_FLOATING_HOST and entity.Variant == 1) then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
		
		if entity.Type == EntityType.ENTITY_HOST and entity.State == NpcState.STATE_ATTACK and sprite:IsEventTriggered("Close") then
			entity:FireProjectiles(entity.Position, Vector(11, 0), 8, ProjectileParams())
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.6, entity.Scale * 0.6)
		end


	elseif IRFconfig.breakableHosts == true and (entity.Type == EntityType.ENTITY_HOST or entity.Type == EntityType.ENTITY_MOBILE_HOST or entity.Type == EntityType.ENTITY_FLOATING_HOST) then
		if entity.Variant == 0 or (entity.Variant == 3 and entity.SubType ~= 40) then
			if sprite:IsPlaying("Bombed") or sprite:IsOverlayPlaying("Bombed") then
				hostBreak(entity)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hostUpdate)

function mod:hostDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Fake damage for Soft Hosts and Flesh Floasts
	if (target.Type == EntityType.ENTITY_HOST and target.Variant == 3 and target.SubType == 40) or (target.Type == EntityType.ENTITY_FLOATING_HOST and target.Variant == 1) then
		target.HitPoints = target.HitPoints - damageAmount
		target:SetColor(fakeDamageColor, 3, 10, true, true)

		if target.HitPoints <= 0 then
			target:Kill()
		end

		return false


	-- Break the skull if it takes more or equal damage to its max health
	elseif IRFconfig.breakableHosts == true and (target.Type == EntityType.ENTITY_HOST or target.Type == EntityType.ENTITY_MOBILE_HOST or target.Type == EntityType.ENTITY_FLOATING_HOST)
	and damageAmount >= target.MaxHitPoints and target:ToNPC().State == NpcState.STATE_IDLE then
		if target.Type == EntityType.ENTITY_MOBILE_HOST then
			target:GetSprite():PlayOverlay("Bombed", true)
		else
			target:GetSprite():Play("Bombed", true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hostDMG)