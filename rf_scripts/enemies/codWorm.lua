local mod = ReworkedFoes

local Settings = {
	HideTime = 120,
	ShotSpeed = 11,
	VulnerableTime = 45
}



function mod:CodWormInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.State = NpcState.STATE_IDLE
	entity.TargetPosition = entity.Position
	entity.ProjectileCooldown = Settings.HideTime
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CodWormInit, EntityType.ENTITY_COD_WORM)

function mod:CodWormUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	entity.Velocity = Vector.Zero
	if sprite:IsEventTriggered("Dig") then
		mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)
	end

	-- Idle
	if entity.State == NpcState.STATE_IDLE then
		mod:LoopingAnim(sprite, "Pulse")

		if entity.ProjectileCooldown <= 0 then
			entity.State = NpcState.STATE_JUMP
			sprite:Play("DigOut", true)
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Pop out
	elseif entity.State == NpcState.STATE_JUMP then
		if sprite:IsEventTriggered("Dig") then
			entity.I1 = 1
			entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
		end
		if sprite:IsFinished() then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack", true)
		end

	-- Attack
	elseif entity.State == NpcState.STATE_ATTACK then
		if sprite:IsEventTriggered("Shoot") then
			mod:PlaySound(entity, SoundEffect.SOUND_WORM_SPIT, 1.2)
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(Settings.ShotSpeed - (entity.I2 * 3)), 3 + (entity.I2 * 2), ProjectileParams())
			mod:ShootEffect(entity, 5, Vector(1, -22), Color(1,1,1, 0.6))
		end

		if sprite:IsFinished("Attack") then
			if entity.I2 == 1 then
				entity.State = NpcState.STATE_STOMP
				sprite:Play("DigIn", true)
			else
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.VulnerableTime
			end
		end


	-- Popped out
	elseif entity.State == NpcState.STATE_MOVE then
		mod:LoopingAnim(sprite, "PulseOut")

		if entity.ProjectileCooldown <= 0 then
			entity.State = NpcState.STATE_STOMP
			sprite:Play("DigIn", true)
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end

	-- Hide
	elseif entity.State == NpcState.STATE_STOMP then
		if sprite:IsEventTriggered("Dig") then
			entity.I1 = 0
			entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
		end
		if sprite:IsFinished("DigIn") then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = Settings.HideTime
			entity.I2 = 0
		end
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.CodWormUpdate, EntityType.ENTITY_COD_WORM)

function mod:CodWormDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	local entity = entity:ToNPC()

	if entity.State == NpcState.STATE_IDLE and entity.FrameCount > 20 then
		entity.State = NpcState.STATE_JUMP
		entity:GetSprite():Play("DigOut", true)
		entity.I2 = 1
	end
	if entity.I1 == 0 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CodWormDMG, EntityType.ENTITY_COD_WORM)