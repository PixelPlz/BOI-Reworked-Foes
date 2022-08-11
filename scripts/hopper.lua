local mod = BetterMonsters
local game = Game()



--[[ Hoppers / Trites ]]--
function mod:hopperUpdate(entity)
	local sprite = entity:GetSprite()

	if (entity.Variant == 3 and sprite:IsEventTriggered("Land")) or (sprite:IsPlaying("Hop") and sprite:GetFrame() == 22) then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hopperUpdate, EntityType.ENTITY_HOPPER)

--[[ Leapers ]]--
function mod:leaperUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.leaperUpdate, EntityType.ENTITY_LEAPER)

--[[ Ministro ]]--
function mod:ministroUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ministroUpdate, EntityType.ENTITY_MINISTRO)

--[[ Pon ]]--
function mod:ponUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ponUpdate, EntityType.ENTITY_PON)



--[[ Flaming Hopper ]]--
function mod:flamingHopperUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Hop") and sprite:GetFrame() == 22 then
		entity.Velocity = Vector.Zero
		entity.TargetPosition = entity.Position
	end

	-- Spawn fire when jumping
	if sprite:IsEventTriggered("Jump") and math.random(1, 10) <= 4 then
		local fire = Isaac.Spawn(EntityType.ENTITY_FIREPLACE, 10, 0, entity.Position, Vector.Zero, entity)
		fire.HitPoints = 2
		fire.DepthOffset = entity.DepthOffset - 10
		SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.5)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingHopperUpdate, EntityType.ENTITY_FLAMINGHOPPER)

function mod:flamingHopperDeath(entity)
	Isaac.Spawn(EntityType.ENTITY_FIREPLACE, 10, 0, entity.Position, Vector.Zero, entity).HitPoints = 4
	SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.8)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.flamingHopperDeath, EntityType.ENTITY_FLAMINGHOPPER)