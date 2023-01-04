local mod = BetterMonsters

local Settings = {
	HideTime = 120,
	ShotSpeed = 12,
	VulnerableTime = 45
}



function mod:codWormInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.State = NpcState.STATE_IDLE
	entity.TargetPosition = entity.Position
	entity.ProjectileCooldown = Settings.HideTime
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.codWormInit, EntityType.ENTITY_COD_WORM)

function mod:codWormUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	entity.Velocity = Vector.Zero
	if sprite:IsEventTriggered("Dig") then
		SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS, 0.9)
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
		end
		if sprite:IsFinished("DigOut") then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack", true)
		end

	-- Attack
	elseif entity.State == NpcState.STATE_ATTACK then
		if sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_WORM_SPIT, 1.2, 0, false, 1)
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * (Settings.ShotSpeed - (entity.I2 * 2)), 3 + (entity.I2 * 2), ProjectileParams())
			mod:shootEffect(entity, 5, Vector(1, -22), Color(1,1,1, 0.7), 0.8)
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.codWormUpdate, EntityType.ENTITY_COD_WORM)

function mod:codWormDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target:ToNPC().State == NpcState.STATE_IDLE and target.FrameCount > 20 then
		target:ToNPC().State = NpcState.STATE_JUMP
		target:ToNPC():GetSprite():Play("DigOut", true)
		target:ToNPC().I2 = 1
	end
	if target:ToNPC().I1 == 0 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.codWormDMG, EntityType.ENTITY_COD_WORM)