local mod = BetterMonsters



local function hostBreak(entity)
	local sprite = entity:GetSprite()

	local type = EntityType.ENTITY_HOST
	local variant = 1
	local subtype = 0

	-- Get the entity to turn into
	if entity.Type == EntityType.ENTITY_HOST then
		if FiendFolio and entity.Variant == 0 and entity.SubType == 250 then -- Stinky FF compatibility
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
	entity:Morph(type, variant, subtype, entity:GetChampionColorIdx())

	-- More stinky FF compatibility yayyy sooo fun
	if FiendFolio and entity:GetData().ffGridHost then
		sprite:Load("gfx/enemies/grid hosts/host.anm2", true)
		sprite:ReplaceSpritesheet(1, "gfx/enemies/grid hosts/host_" .. entity:GetData().ffGridHost)
		sprite:LoadGraphics()
	end

	-- Bombed state for the new entity
	if entity.Type == EntityType.ENTITY_FLESH_MOBILE_HOST then
		sprite:PlayOverlay("Bombed", true)
	else
		sprite:Play("Bombed", true)
	end
	entity.StateFrame = 10


	-- Effects
	for i = 0, 5 do
		local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(3), entity):ToEffect()
		rocks:GetSprite():Play("rubble", true)
		rocks.State = 2
	end
	mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)
end



function mod:hostUpdate(entity)
	local sprite = entity:GetSprite()

	-- Soft Host / Flesh Floast
	if (entity.Type == EntityType.ENTITY_HOST and entity.Variant == 3 and entity.SubType == 40) -- Soft Host
	or (entity.Type == EntityType.ENTITY_FLOATING_HOST and entity.Variant == 1) then -- Flesh Floast
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)

		if entity.Type == EntityType.ENTITY_HOST and entity.State == NpcState.STATE_ATTACK and sprite:IsEventTriggered("Close") then
			entity:FireProjectiles(entity.Position, Vector(12, 8), 8, ProjectileParams())
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.6, entity.Scale * 0.6)
		end


	-- Skull breaking
	elseif IRFconfig.breakableHosts == true
	and (entity.Type == EntityType.ENTITY_HOST or entity.Type == EntityType.ENTITY_MOBILE_HOST or entity.Type == EntityType.ENTITY_FLOATING_HOST)
	and (entity.Variant == 0 or (entity.Variant == 3 and entity.SubType ~= 40))
	and (sprite:IsPlaying("Bombed") or sprite:IsOverlayPlaying("Bombed")) then
		hostBreak(entity:ToNPC())
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hostUpdate)

function mod:hostDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Fake damage for Soft Hosts and Flesh Floasts
	if (target.Type == EntityType.ENTITY_HOST and target.Variant == 3 and target.SubType == 40) -- Soft Host
	or (target.Type == EntityType.ENTITY_FLOATING_HOST and target.Variant == 1) then -- Flesh Floast
		target.HitPoints = target.HitPoints - damageAmount
		target:SetColor(IRFcolors.DamageFlash, 2, 0, false, false)

		if target.HitPoints <= 0 then
			target:Kill()
		end

		return false


	-- Break the skull if it takes more or equal damage to its max health
	elseif IRFconfig.breakableHosts == true
	and (target.Type == EntityType.ENTITY_HOST or target.Type == EntityType.ENTITY_MOBILE_HOST or target.Type == EntityType.ENTITY_FLOATING_HOST)
	and damageAmount >= target.MaxHitPoints and target:ToNPC().State == NpcState.STATE_IDLE then
		if target.Type == EntityType.ENTITY_MOBILE_HOST then
			target:GetSprite():PlayOverlay("Bombed", true)
		else
			target:GetSprite():Play("Bombed", true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hostDMG)