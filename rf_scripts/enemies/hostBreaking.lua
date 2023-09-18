local mod = BetterMonsters



IRFbreakableHosts = {
	{Type = EntityType.ENTITY_HOST, 		 Variant = 0,   SubType = 0,   '   -->   ', BrokenType = nil, 								  BrokenVariant = 1,   BrokenSubType = nil}, -- Host
	{Type = EntityType.ENTITY_HOST, 		 Variant = 0,   SubType = 250, '   -->   ', BrokenType = nil, 								  BrokenVariant = 1,   BrokenSubType = 251}, -- Fiend Folio Hostlet
	{Type = EntityType.ENTITY_HOST, 		 Variant = 3,   SubType = 0,   '   -->   ', BrokenType = nil, 								  BrokenVariant = nil, BrokenSubType = 40},  -- Hard Host
	{Type = EntityType.ENTITY_MOBILE_HOST,   Variant = nil, SubType = nil, '   -->   ', BrokenType = EntityType.ENTITY_FLESH_MOBILE_HOST, BrokenVariant = nil, BrokenSubType = nil}, -- Mobile Host
	{Type = EntityType.ENTITY_FLOATING_HOST, Variant = 0,   SubType = nil, '   -->   ', BrokenType = nil, 								  BrokenVariant = 1,   BrokenSubType = nil}, -- Floast
}

-- Putting nil as the Variant or SubType will make it work on any of that type's variants or subtypes
-- Putting nil as any of the broken values will make them not change it when they get broken
-- BreakCheckScript should be a function that returns true if some custom condition is met for them breaking. (something that isn't their animation or overlay being "Bombed")
	-- The first argument should be the entity.
	-- Can be set to nil to use default conditions.
-- BrokenScript gets triggered when they break. If your Host doesn't use StateFrame for the timer or use "Bombed" as their animation like vanilla Hosts then you should set up that stuff here.
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
		BrokenScript  = BrokenScript
	}
	table.insert(IRFbreakableHosts, brokenData)
end



-- Check if this entity is a Host that can be broken and return the needed data if it is
function mod:IsBreakableHost(entity)
	for i, entry in pairs(IRFbreakableHosts) do
		if entity.Type == entry.Type
		and (entry.Variant == nil or entity.Variant == entry.Variant)
		and (entry.SubType == nil or entity.SubType == entry.SubType) then
			return {Type = entry.BrokenType, Variant = entry.BrokenVariant, SubType = entry.BrokenSubType, Condition = entry.BreakCheckScript, Script = entry.BrokenScript}
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
		brokenData.Script(entity)

	else
		if entity.Type == EntityType.ENTITY_FLESH_MOBILE_HOST then
			sprite:PlayOverlay("Bombed", true)
		else
			sprite:Play("Bombed", true)
		end
		entity.StateFrame = 10
	end


	-- Effects
	for i = 0, 5 do
		local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, mod:RandomVector(3), entity):ToEffect()
		rocks:GetSprite():Play("rubble", true)
		rocks.State = 2
	end
	mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)
end

-- Check if this entity is a Host that should be broken
function mod:hostBreakCheck(entity)
	if IRFConfig.breakableHosts == true then
		local brokenData = mod:IsBreakableHost(entity)

		if brokenData ~= false -- Is a Host that can be broken
		and ((brokenData.Condition ~= nil and brokenData.Condition(entity) == true) -- Has custom condition
		or (entity:GetSprite():IsPlaying("Bombed") or entity:GetSprite():IsOverlayPlaying("Bombed"))) then -- Default condition
			mod:BreakHost(entity, brokenData)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hostBreakCheck)





--[[ New broken variants ]]--
-- Soft Host
function mod:softHostUpdate(entity)
	if entity.Variant == 3 and entity.SubType == 40 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)

		if entity:GetSprite():IsEventTriggered("Close") then
			entity:FireProjectiles(entity.Position, Vector(12, 8), 8, ProjectileParams())
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.6, entity.Scale * 0.6)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.softHostUpdate, EntityType.ENTITY_HOST)

-- Flesh Floast
function mod:fleshFloastUpdate(entity)
	if entity.Variant == 1 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fleshFloastUpdate, EntityType.ENTITY_FLOATING_HOST)



-- Fake damage for Soft Hosts and Flesh Floasts
local function hostFakeDMG(target, damageAmount)
	target.HitPoints = target.HitPoints - damageAmount
	target:SetColor(IRFcolors.DamageFlash, 2, 0, false, false)

	if target.HitPoints <= 0 then
		target:Kill()
	end
	return false
end

function mod:softHostFakeDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 3 and target.SubType == 40 then
		return hostFakeDMG(target, damageAmount)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.softHostFakeDMG, EntityType.ENTITY_HOST)

function mod:fleshFloastFakeDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 then
		return hostFakeDMG(target, damageAmount)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.fleshFloastFakeDMG, EntityType.ENTITY_FLOATING_HOST)