local mod = ReworkedFoes



function mod:LumpInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.LumpInit, EntityType.ENTITY_LUMP)

function mod:LumpUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local room = Game():GetRoom()

	entity.Velocity = Vector.Zero

	if sprite:IsEventTriggered("Sound") then
		mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.85)
	end



	--[[ Idle ]]--
	if entity.State == NpcState.STATE_IDLE then
		mod:LoopingAnim(sprite, "Shake")

		-- Shoot if the target is close enough
		if entity.Position:Distance(target.Position) <= 220 and room:CheckLine(entity.Position, target.Position, 3, 0, false, false) then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Spit", true)
		end

		-- Change position if the target is not close enough
		if entity.StateFrame <= 0 then
			entity.State = NpcState.STATE_STOMP
			sprite:Play("Hide", true)
		else
			entity.StateFrame = entity.StateFrame - 1
		end



	--[[ Go underground ]]--
	elseif entity.State == NpcState.STATE_STOMP then
		if sprite:IsEventTriggered("Sound") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end

		if sprite:IsFinished("Hide") then
			entity.State = NpcState.STATE_MOVE
			entity.StateFrame = 30
			entity.Visible = false
		end



	--[[ Go to a random position ]]--
	elseif entity.State == NpcState.STATE_MOVE then
		if entity.StateFrame <= 0 then
			local distance = mod:Random(160, 280)
			entity.TargetPosition = target.Position + mod:RandomVector(distance)
			entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 40, true, false)

			-- Check if this spot is far enough away from any players
			local nearestPlayerPos = Game():GetNearestPlayer(entity.TargetPosition).Position
			local minDistance = 160

			if mod:GetRoomShapeFlags() & mod.RoomShapeFlags.Tiny > 0 then
				minDistance = 100
			end

			-- Emerge if it is far enough
			if entity.TargetPosition:Distance(nearestPlayerPos) >= minDistance then
				entity.Position = entity.TargetPosition
				entity.State = NpcState.STATE_JUMP
				sprite:Play("Emerge", true)
				entity.Visible = true
				mod:FlipTowardsTarget(entity, sprite)
			end

		else
			entity.StateFrame = entity.StateFrame - 1
		end



	--[[ Emerge ]]--
	elseif entity.State == NpcState.STATE_JUMP then
		if sprite:IsEventTriggered("Sound") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end

		if sprite:IsFinished("Emerge") then
			entity.State = NpcState.STATE_IDLE
			entity.StateFrame = 90
		end



	--[[ Attack ]]--
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



	-- FF waiting Lump bullshit
	if (entity.SubType == 95 and entity.State == NpcState.STATE_INIT) then
		entity.State = NpcState.STATE_IDLE
		entity.StateFrame = 90
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.LumpUpdate, EntityType.ENTITY_LUMP)