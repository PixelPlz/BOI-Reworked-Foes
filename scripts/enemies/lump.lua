local mod = BetterMonsters



function mod:lumpInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lumpInit, EntityType.ENTITY_LUMP)

function mod:lumpUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local room = Game():GetRoom()

	entity.Velocity = Vector.Zero

	if sprite:IsEventTriggered("Sound") then
		mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.85)
	end


	if entity.State == NpcState.STATE_IDLE then
		mod:LoopingAnim(sprite, "Shake")

		-- Shoot if target is close enough
		if entity.Position:Distance(target.Position) <= 220 and room:CheckLine(entity.Position, target.Position, 3, 0, false, false) then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Spit", true)
		end

		-- Change position if player is not close enough
		if entity.StateFrame <= 0 then
			entity.State = NpcState.STATE_STOMP
			sprite:Play("Hide", true)

		else
			entity.StateFrame = entity.StateFrame - 1
		end


	-- Go underground
	elseif entity.State == NpcState.STATE_STOMP then
		if sprite:IsEventTriggered("Sound") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end

		if sprite:IsFinished("Hide") then
			entity.State = NpcState.STATE_MOVE
			entity.StateFrame = 30
			entity.Visible = false
		end

	-- Go to position
	elseif entity.State == NpcState.STATE_MOVE then
		entity.V1 = target.Position + mod:RandomVector(mod:Random(200, 300))
		entity.V1 = room:FindFreePickupSpawnPosition(entity.V1, 40, true, false)

		local minDistance = 160
		if room:GetRoomShape() == RoomShape.ROOMSHAPE_IV then
			minDistance = 120
		end

		if entity.StateFrame <= 0 and entity.V1:Distance(Game():GetNearestPlayer(entity.Position).Position) >= minDistance then
			entity.Position = entity.V1
			entity.State = NpcState.STATE_JUMP
			sprite:Play("Emerge", true)
			entity.Visible = true
			mod:FlipTowardsTarget(entity, sprite)

		else
			entity.StateFrame = entity.StateFrame - 1
		end

	-- Popup
	elseif entity.State == NpcState.STATE_JUMP then
		if sprite:IsEventTriggered("Sound") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end
		
		if sprite:IsFinished("Emerge") then
			entity.State = NpcState.STATE_IDLE
			entity.StateFrame = 90
		end


	-- Attack
	elseif entity.State == NpcState.STATE_ATTACK then
		if sprite:IsEventTriggered("Shoot") then
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7.5), 2, ProjectileParams())
			mod:PlaySound(entity, SoundEffect.SOUND_MEATHEADSHOOT)
			mod:FlipTowardsTarget(entity, sprite)
		end

		if sprite:IsFinished("Spit") then
			entity.State = NpcState.STATE_STOMP
			sprite:Play("Hide")
		end
	end


	-- FF waiting Lump (This is such a dumb variant why does it even exist...)
	if (entity.SubType == 95 and entity.State == NpcState.STATE_INIT) then
		entity.State = NpcState.STATE_IDLE
		entity.StateFrame = 90
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.lumpUpdate, EntityType.ENTITY_LUMP)