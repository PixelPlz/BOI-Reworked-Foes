local mod = BetterMonsters
local game = Game()



--[[
function mod:lumpUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_MOVE then
		if sprite:IsPlaying("Hide") and sprite:GetFrame() > 13 then
			entity.Visible = false
		end

		entity.I2 = 1
		entity.StateFrame = 0

	elseif entity.State == NpcState.STATE_IDLE then
		entity.I2 = 0


	elseif entity.State == NpcState.STATE_JUMP then
		entity.Visible = true
		entity.StateFrame = sprite:GetFrame()


	elseif entity.State == NpcState.STATE_ATTACK then
		if entity.I2 == 1 then
			entity.State = NpcState.STATE_JUMP
			sprite:Play("Appear", true)
			sprite:SetFrame(entity.StateFrame)
			entity.I2 = 0
			entity.ProjectileCooldown = entity.ProjectileCooldown - 30
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.lumpUpdate, EntityType.ENTITY_LUMP)
]]--



function mod:lumpInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.CollisionDamage = 0
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lumpInit, EntityType.ENTITY_LUMP)

function mod:lumpUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local room = game:GetRoom()

	
	entity.Velocity = Vector.Zero

	if sprite:IsEventTriggered("Sound") then
		SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS, 0.85)
	end

	local function spriteFlipX()
		if target.Position.X > entity.Position.X then
			sprite.FlipX = true
		else
			sprite.FlipX = false
		end
	end


	if entity.State == NpcState.STATE_IDLE then
		if not sprite:IsPlaying("Shake") then
			sprite:Play("Shake", true)
		end
		
		-- Shoot if target is close enough
		if entity.Position:Distance(target.Position) <= 220 and room:CheckLine(entity.Position, target.Position, 3, 0, false, false) then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Spit", true)
		end

		-- Change position if player 
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
		entity.V1 = target.Position + Vector.FromAngle(math.random(0, 359)) * math.random(200, 320)
		entity.V1 = room:FindFreePickupSpawnPosition(entity.V1, 40, true, false)

		local minDistance = 160
		if room:GetRoomShape() == RoomShape.ROOMSHAPE_IV then
			minDistance = 120
		end

		if entity.StateFrame <= 0 and entity.V1:Distance(target.Position) >= minDistance then
			entity.Position = entity.V1
			entity.State = NpcState.STATE_JUMP
			sprite:Play("Emerge", true)
			entity.Visible = true
			spriteFlipX()

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
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 7.5, 2, ProjectileParams())
			entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 1, 0, false, 1)
			spriteFlipX()
		end

		if sprite:IsFinished("Spit") then
			entity.State = NpcState.STATE_STOMP
			sprite:Play("Hide")
		end
	end
	
	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.lumpUpdate, EntityType.ENTITY_LUMP)