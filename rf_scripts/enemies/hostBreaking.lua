local mod = ReworkedFoes

mod.BreakableHosts = {
	{ Type = EntityType.ENTITY_HOST, Variant = 0, SubType = 0,   BrokenVariant = 1, }, -- Host
	{ Type = EntityType.ENTITY_HOST, Variant = 0, SubType = 250,   BrokenVariant = 1, BrokenSubType = 251, }, -- Fiend Folio Hostlet
	{ Type = EntityType.ENTITY_HOST, Variant = 3, SubType = 0,   BrokenSubType = 40, },  -- Hard Host
	{ Type = EntityType.ENTITY_MOBILE_HOST, BrokenType = EntityType.ENTITY_FLESH_MOBILE_HOST, }, -- Mobile Host
	{ Type = EntityType.ENTITY_FLOATING_HOST, Variant = 0,   BrokenVariant = 1, }, -- Floast
}



-- Leaving out the Variant or SubType will make it work on any of that type's variants or subtypes
-- Leaving out any of the broken values will make them not change it when they get broken
-- 'BreakCheckScript' should be a function that returns true if some custom condition is met for them breaking. (something that isn't their animation or overlay being "Bombed")
	-- The first argument should be the entity.
	-- Can be left out to use default conditions.
-- 'BrokenScript' gets triggered when they break. If your Host doesn't use StateFrame for the timer or use "Bombed" as their animation like vanilla Hosts then you should set up that stuff here.
	-- The first argument should be the entity.
	-- Can be left out.
function mod:AddBreakableHost(Type, Variant, SubType, BrokenType, BrokenVariant, BrokenSubType, BreakCheckScript, BrokenScript)
	local brokenData = {
		Type 	= Type,
		Variant = Variant,
		SubType = SubType,

		BrokenType    = BrokenType,
		BrokenVariant = BrokenVariant,
		BrokenSubType = BrokenSubType,

		BreakCheckScript = BreakCheckScript,
		BrokenScript 	 = BrokenScript,
	}
	table.insert(mod.BreakableHosts, brokenData)
end



-- Check if this entity is a Host that can be broken and return the needed data if it is
function mod:IsBreakableHost(entity)
	for i, entry in pairs(mod.BreakableHosts) do
		if entity.Type == entry.Type
		and (not entry.Variant or entity.Variant == entry.Variant)
		and (not entry.SubType or entity.SubType == entry.SubType) then
			return {
				Type = entry.BrokenType,
				Variant = entry.BrokenVariant,
				SubType = entry.BrokenSubType,
				Condition = entry.BreakCheckScript,
				Script = entry.BrokenScript
			}
		end
	end
	return false
end

-- Break the Host
function mod:BreakHost(entity, brokenData)
	local sprite = entity:GetSprite()

	-- Turn into the new entity
	local Type    = brokenData.Type    or entity.Type
	local Variant = brokenData.Variant or entity.Variant
	local SubType = brokenData.SubType or entity.SubType

	entity:Morph(Type, Variant, SubType, entity:GetChampionColorIdx())


	-- Fiend Folio grid Hosts
	if FiendFolio and entity:GetData().ffGridHost then
		sprite:Load("gfx/enemies/grid hosts/host.anm2", true)
		sprite:ReplaceSpritesheet(1, "gfx/enemies/grid hosts/redhost_" .. entity:GetData().ffGridHost)
		sprite:LoadGraphics()
	end


	-- Stunned state for the new entity
	if brokenData.Script ~= nil then
		brokenData.Script(_, entity)

	else
		if entity.Type == EntityType.ENTITY_FLESH_MOBILE_HOST then
			sprite:PlayOverlay("Bombed", true)
		else
			sprite:Play("Bombed", true)
		end
		entity.StateFrame = 10
	end

	-- Make sure the NO_TARGET flag is removed
	entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)


	-- Effects
	mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)

	-- Gibs
	for i = 1, 5 do
		local vector = mod:RandomVector(math.random(2, 4))
		local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, BackdropType.DEPTHS, entity.Position, vector, entity):ToEffect()
		rocks:Update()
		rocks:GetSprite():SetAnimation("rubble_alt", false)
	end

	-- Smoke
	for i = 1, 2 do
		local smoke = mod:SmokeParticles(entity, Vector(0, -12), 0, Vector(120, 140), Color(0,0,0, 1, 0.4,0.4,0.4), 100)
		smoke.Velocity = smoke.Velocity:Resized(math.random(2, 4))
	end
end

-- Check if this entity is a Host that should be broken
function mod:hostBreakCheck(entity)
	if mod.Config.BreakableHosts then
		local brokenData = mod:IsBreakableHost(entity)

		if brokenData ~= false -- Is a Host that can be broken
		and ((brokenData.Condition ~= nil and brokenData.Condition(_, entity) == true) -- Has custom condition
		or (entity:GetSprite():IsPlaying("Bombed") or entity:GetSprite():IsOverlayPlaying("Bombed"))) then -- Default condition
			mod:BreakHost(entity, brokenData)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hostBreakCheck)





--[[ New broken variants ]]--
-- Fake damage for Soft Hosts and Flesh Floasts
function mod:HostFakeDMG(entity, damageAmount)
	entity.HitPoints = entity.HitPoints - damageAmount
	entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, false)

	if entity.HitPoints <= 0 then
		entity:Kill()
	end
	return false
end



-- Soft Host
function mod:SoftHostUpdate(entity)
	if entity.Variant == 3 and entity.SubType == 40 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)

		if entity:GetSprite():IsEventTriggered("Close") then
			entity:FireProjectiles(entity.Position, Vector(12, 8), 8, ProjectileParams())
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.6, entity.Scale * 0.6)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SoftHostUpdate, EntityType.ENTITY_HOST)

function mod:SoftHostFakeDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 3 and entity.SubType == 40 then
		return mod:HostFakeDMG(entity, damageAmount)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SoftHostFakeDMG, EntityType.ENTITY_HOST)



-- Flesh Floast
function mod:FleshFloastUpdate(entity)
	if entity.Variant == 1 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FleshFloastUpdate, EntityType.ENTITY_FLOATING_HOST)

function mod:FleshFloastFakeDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 1 then
		return mod:HostFakeDMG(entity, damageAmount)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.FleshFloastFakeDMG, EntityType.ENTITY_FLOATING_HOST)