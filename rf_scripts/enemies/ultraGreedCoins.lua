local mod = ReworkedFoes



-- Make the collision size smaller
function mod:UltraGreedCoinInit(entity)
	if entity.Variant == 0 then
		entity:SetSize(20, Vector.One, 12)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.UltraGreedCoinInit, EntityType.ENTITY_ULTRA_COIN)

-- Better falling state
function mod:UltraGreedCoinUpdate(entity)
	local sprite = entity:GetSprite()

	-- Replace the default one
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		entity.State = NpcState.STATE_STOMP
		entity.CollisionDamage = 0

		-- Set the height
		entity.PositionOffset = Vector(0, -350)
		entity.V2 = Vector(0, -20)
		entity:SetColor(Color(1,1,1, 0), 3, 255, true)

		-- Get the animation to play
		local suffix = "Neutral"

		if entity.Variant == 1 then
			suffix = "Key"
		elseif entity.Variant == 2 then
			suffix = "Bomb"
		elseif entity.Variant == 3 then
			suffix = "Heart"
		end
		sprite:Play("Spinning" .. suffix, true)



	-- Cutom falling state
	elseif entity.State == NpcState.STATE_STOMP then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		-- Update height
		entity.V2 = Vector(0, entity.V2.Y - 2)
		entity.PositionOffset = Vector(0, entity.PositionOffset.Y - entity.V2.Y)

		-- Update collison
		if entity.PositionOffset.Y >= -30 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		else
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end


		-- Bounce / land
		if entity.PositionOffset.Y >= 0 then
			entity.PositionOffset = Vector.Zero
			mod:PlaySound(nil, SoundEffect.SOUND_PENNYDROP, 1, 0.98, 10)

			-- Bounce strength
			local multi = mod:Random(30, 45)
			entity.V2 = -entity.V2 * (multi / 100)

			-- Land if the bounce strength isn't strong enough
			if entity.V2:Length() <= 10 then
				entity.State = NpcState.STATE_IDLE
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

				-- Re-enable damage for the spinners
				if entity.Variant == 0 then
					entity.CollisionDamage = 1
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.UltraGreedCoinUpdate, EntityType.ENTITY_ULTRA_COIN)