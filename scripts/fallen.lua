local mod = BetterMonsters
local game = Game()



function mod:redKrampusUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	-- Fallen
	if entity.Variant == 0 and entity.SubType == 1 then
		-- 2nd phase
		if entity.SpawnerType == EntityType.ENTITY_FALLEN then
			entity.Velocity = entity.Velocity * 0.975

			-- Goat double attack
			if entity.State == NpcState.STATE_ATTACK then
				entity.State = NpcState.STATE_ATTACK5
				sprite:Play("Attack1", true)

			elseif entity.State == NpcState.STATE_ATTACK5 then
				if sprite:IsEventTriggered("Shoot") then
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 10, 1, ProjectileParams())
					entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_2, 1, 0, false, 1)
				elseif sprite:IsEventTriggered("Shoot2") then
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 10, 2, ProjectileParams())
					entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_1, 1, 0, false, 1)
				end
				
				if sprite:IsFinished("Attack1") then
					entity.State = NpcState.STATE_MOVE
				end
			
			elseif entity.State == NpcState.STATE_ATTACK2 then
				entity.I1 = entity.I1 + 1
				if entity.I1 >= 120 then
					entity.State = NpcState.STATE_MOVE
					entity.I1 = 0
				end

			-- Skip brimstone attack
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.State = NpcState.STATE_MOVE
			end


		-- 1st phase
		else
			-- Skip chase
			if entity.State == NpcState.STATE_ATTACK2 then
				entity.State = NpcState.STATE_ATTACK3
				sprite:Play("Attack2", true)
			end

			-- Extra clone
			if sprite:IsFinished("Split") then
				local extra = Isaac.Spawn(EntityType.ENTITY_FALLEN, 0, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
				extra.Scale = 0.75
				extra.HitPoints = extra.MaxHitPoints / 2
			end
		end


	-- Krampus
	elseif entity.Variant == 1 and entity.SubType == 1 then
		-- Replace brimstone attack
		if sprite:IsEventTriggered("StartShoot") then
			entity.I2 = 1
			entity.ProjectileCooldown = 0
			entity.StateFrame = 0
			SFXManager():Play(SoundEffect.SOUND_BLOOD_LASER, 1.1, 0, false, 1)

		elseif sprite:IsEventTriggered("StopShoot") then
			entity.I2 = 0
		end

		if entity.I2 == 1 then
			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = 3
				entity.StateFrame = entity.StateFrame + 1

				local params = ProjectileParams()
				params.CircleAngle = entity.StateFrame * 135
				params.FallingSpeedModifier = -1
				entity:FireProjectiles(entity.Position, Vector(10, 8), 9, params)

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redKrampusUpdate, EntityType.ENTITY_FALLEN)