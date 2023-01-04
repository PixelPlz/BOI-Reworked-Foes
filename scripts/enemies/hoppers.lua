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
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.flamingHopperInit, EntityType.ENTITY_FLAMINGHOPPER)

function mod:flamingHopperUpdate(entity)
	local sprite = entity:GetSprite()

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
		if sprite:GetFrame() < 12 then
			entity.Velocity = Vector.Zero
		end

		if sprite:IsEventTriggered("Land") then
			entity.Velocity = Vector.Zero
			entity.TargetPosition = entity.Position
			entity.ProjectileCooldown = 3
			mod:FireRing(entity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingHopperUpdate, EntityType.ENTITY_FLAMINGHOPPER)