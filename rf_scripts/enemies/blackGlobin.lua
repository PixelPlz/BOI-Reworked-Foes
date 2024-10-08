local mod = ReworkedFoes

local Settings = {
	SlideTime = 40,
	SlideSpeed = 14,
	RegenTime = 80,
	NewHealth = 20,
}



--[[ Black Globin ]]--
function mod:BlackGlobinUpdate(entity)
	if entity:IsDead() or entity.State == NpcState.STATE_APPEAR_CUSTOM then
		-- Regened from a head
		if entity.State == NpcState.STATE_APPEAR_CUSTOM then
			local sprite = entity:GetSprite()
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(entity, SoundEffect.SOUND_DEATH_REVERSE, 1.2)

			elseif sprite:IsEventTriggered("Regen") then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlackGlobinUpdate, EntityType.ENTITY_BLACK_GLOBIN)

-- Keep track of the last hit direction
function mod:BlackGlobinDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	entity:ToNPC().V1 = (entity.Position - damageSource.Position):Normalized()
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BlackGlobinDMG, EntityType.ENTITY_BLACK_GLOBIN)

function mod:BlackGlobinDeath(entity)
	entity = entity:ToNPC()

	-- Create the sliding head
	local head = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN_HEAD, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
	head.State = NpcState.STATE_STOMP
	head.Velocity = entity.V1:Resized(Settings.SlideSpeed)
	head.I1 = Settings.SlideTime
	mod:FlipTowardsMovement(head, head:GetSprite(), true)

	-- Turn into a body
	entity:Morph(EntityType.ENTITY_BLACK_GLOBIN_BODY, 0, 0, entity:GetChampionColorIdx())
	entity.HitPoints = entity.MaxHitPoints
	entity.State = NpcState.STATE_MOVE
	entity:SetDead(false)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, mod.BlackGlobinDeath, EntityType.ENTITY_BLACK_GLOBIN)

function mod:BlackGlobinCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_SPIDER
	or target.Type == EntityType.ENTITY_BLACK_GLOBIN_HEAD or target.Type == EntityType.ENTITY_BLACK_GLOBIN_BODY then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.BlackGlobinCollision, EntityType.ENTITY_BLACK_GLOBIN)



--[[ Black Globin Head ]]--
function mod:BlackGlobinHeadUpdate(entity)
	local sprite = entity:GetSprite()

	-- Regen (only if spawned from a Black Globin)
	if entity.State == NpcState.STATE_MOVE and entity.SpawnerType == EntityType.ENTITY_BLACK_GLOBIN then
		if entity.I1 <= 0 then
			entity:Morph(EntityType.ENTITY_BLACK_GLOBIN, 0, 0, entity:GetChampionColorIdx())
			entity.HitPoints = Settings.NewHealth
			entity.State = NpcState.STATE_APPEAR_CUSTOM
			sprite:Play("Appear", true)
			sprite.FlipX = not sprite.FlipX

		else
			entity.I1 = entity.I1 - 1
		end


	-- Sliding / Recovering
	elseif entity.State == NpcState.STATE_STOMP or entity.State == NpcState.STATE_JUMP then
		-- Creep
		if entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 1, Settings.CreepTime)
		end

		-- Sliding
		if entity.State == NpcState.STATE_STOMP then
			mod:LoopingAnim(sprite, "Sliding")

			-- Recover
			if entity.I1 <= 0 then
				entity.State = NpcState.STATE_JUMP
				sprite:Play("Recover", true)
			else
				entity.I1 = entity.I1 - 1
			end

			-- Squishy meat sounds
			if entity:CollidesWithGrid() then
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)
			end


		-- Recovering
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity, 0.15)

			if sprite:IsEventTriggered("Recover") then
				entity.Velocity = Vector.Zero
				mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 0.75)

			elseif sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = Settings.RegenTime
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlackGlobinHeadUpdate, EntityType.ENTITY_BLACK_GLOBIN_HEAD)

function mod:BlackGlobinHeadCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_SPIDER or target.Type == EntityType.ENTITY_BLACK_GLOBIN_BODY then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.BlackGlobinHeadCollision, EntityType.ENTITY_BLACK_GLOBIN_HEAD)