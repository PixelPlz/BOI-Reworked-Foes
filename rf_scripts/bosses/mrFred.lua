local mod = ReworkedFoes

local Settings = {
	NewHP = 650,
	Cooldown = 50,
	MaxHomonculi = 3,
}



function mod:MrFredInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		entity.MaxHitPoints = Settings.NewHP
		entity.HitPoints = entity.MaxHitPoints
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = Settings.Cooldown / 2
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MrFredInit, EntityType.ENTITY_MR_FRED)

function mod:MrFredUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		-- Jumping to target position
		if entity.StateFrame == 1 then
			if entity.Position:Distance(entity.V1) < 20 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
			else
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.V1 - entity.Position):Resized(14), 0.25)
			end

		-- Stationary
		else
			entity.Velocity = Vector.Zero
		end


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = Settings.Cooldown

				-- Decide attack
				local attack = mod:Random(1, 5)

				-- Jump
				if attack == 1 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("LeapDown", true)

				-- Harlequin baby attack
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Shoot", true)

				-- Barf attack
				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("Barf", true)
					entity.I1 = 0

				-- Squirt attack
				elseif attack == 4 then
					entity.State = NpcState.STATE_ATTACK3
					sprite:Play("Squirt", true)
					entity.I2 = 0

				-- Summon / release Homunculus
				elseif attack == 5 then
					local homoCount = Isaac.CountEntities(nil, EntityType.ENTITY_HOMUNCULUS, 0, 0)
					if (homoCount > 0 and mod:Random(1) == 1) or homoCount >= Settings.MaxHomonculi then
						entity.State = NpcState.STATE_ATTACK4
						sprite:Play("Cord", true)
					else
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("SummonLeft", true)
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Leap to a different position
		elseif entity.State == NpcState.STATE_JUMP then
			-- Get position
			if sprite:GetFrame() == 6 then
				local pos = target.Position

				-- Confused
				if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
					pos = entity.Position + mod:RandomVector(mod:Random(120, 200))
				-- Feared
				elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
					pos = entity.Position + (entity.Position - target.Position):Resized(mod:Random(120, 200))

				-- Limit jump distance
				elseif target.Position:Distance(entity.Position) > 200 then
					pos = entity.Position + (target.Position - entity.Position):Resized(200)
				end

				entity.V1 = room:FindFreePickupSpawnPosition(pos, 0, false, false)
				if (entity.V1 - entity.Position):GetAngleDegrees() < 0 then
					sprite:SetAnimation("LeapUp", false)
				end
			end

			-- Projectiles
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)

				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8)
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.75)


			-- Start moving
			elseif sprite:IsEventTriggered("Jump") then
				entity.StateFrame = 1
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

			elseif sprite:IsEventTriggered("Land") then
				entity.StateFrame = 0
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND


			-- Burrow
			elseif sprite:IsEventTriggered("Burrow") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_APPEAR_CUSTOM
				sprite:Play("Appear", true)
				entity.Position = room:FindFreePickupSpawnPosition(entity.Position, 0, false, false)
			end

		-- Popup
		elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
			if sprite:IsEventTriggered("Burrow") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.75)

			-- Projectiles
			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.5
				params.CircleAngle = 0
				entity:FireProjectiles(entity.Position, Vector(10, 12), 9, params)

				mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE, 1.25, 0.95)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end


		-- Harlequin baby attack
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 2.5
				params.FallingAccelModifier = -0.175
				for i = -1, 1, 2 do
					local angle = (target.Position - entity.Position):GetAngleDegrees() + i * 30
					mod:FireProjectiles(entity, entity.Position, Vector.FromAngle(angle):Resized(13), 0, params):GetData().mrFredTrail = true
				end

				-- Effects
				mod:ShootEffect(entity, 5, Vector(4, -20))
				mod:PlaySound(entity, SoundEffect.SOUND_LITTLE_SPIT, 1, 0.9)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1.1)
			end

			if sprite:IsFinished("Shoot") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Barf attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(entity, SoundEffect.SOUND_ANGRY_GURGLE, 1.25, 0.95)

			-- Projectiles
			elseif sprite:IsEventTriggered("Shoot") then
				entity.TargetPosition = room:GetClampedPosition(target.Position + mod:RandomVector(mod:Random(10, 100)), 0)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, entity.TargetPosition, Vector.Zero, entity):ToEffect().Timeout = 30

				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.EXPLODE
				params.GridCollision = false
				params.Scale = 1.75
				params.FallingAccelModifier = 1.5
				params.FallingSpeedModifier = -40
				mod:FireProjectiles(entity, entity.Position, (entity.TargetPosition - entity.Position):Resized(entity.Position:Distance(entity.TargetPosition) / 32), 0, params, Color.Default)

				-- Effects
				if entity.I1 < 2 then
					mod:ShootEffect(entity, 2, Vector(2, -44))
					-- Sound
					if entity.I1 == 0 then
						mod:PlaySound(entity, SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF)
					end
				end
				entity.I1 = entity.I1 + 1
			end

			if sprite:IsFinished("Barf") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Squirt attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			-- Effects
			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(entity, SoundEffect.SOUND_FAT_WIGGLE, 1.25, 0.95)

			elseif sprite:IsEventTriggered("Land") then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 0.8)


			-- Projectiles
			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.9)
				entity.I2 = entity.I2 + 1

				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.ORBIT_CW | ProjectileFlags.CURVE_RIGHT)
				params.Scale = 1 + (entity.I2 * 0.15)
				params.CurvingStrength = 0 + (entity.I2 * 0.005)
				params.TargetPosition = entity.Position
				params.FallingAccelModifier = -0.135

				for i = 0, 3 do
					local vector = Vector.FromAngle((i * 90) + (entity.I2 * 45))
					entity:FireProjectiles(entity.Position + (vector * 20), vector * (15 - entity.I2), 0, params)
				end
			end

			if sprite:IsFinished("Squirt") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Summon
		elseif entity.State == NpcState.STATE_SUMMON then
			-- Get position
			if sprite:GetFrame() == 6 then
				local multiplier = mod:GetSign(entity.FrameCount % 2)
				entity.V2 = entity.Position + Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + (multiplier * 90)):Resized(1040)
				entity.V2 = room:FindFreePickupSpawnPosition(entity.V2, 40, true, false)

				local angleDegrees = (entity.V2 - entity.Position):GetAngleDegrees()
				local facing = mod:GetDirectionString(angleDegrees)
				sprite:SetAnimation("Summon" .. facing, false)
			end

			if sprite:IsEventTriggered("Shoot") then
				Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, entity.V2, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end

		-- Release a Homunculus
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)

			elseif sprite:IsEventTriggered("Shoot") then
				entity:FireBossProjectiles(9, Vector.Zero, 10, ProjectileParams())
				mod:PlaySound(nil, SoundEffect.SOUND_WHIP_HIT, 0.75)

				for i,h in pairs(Isaac.FindByType(EntityType.ENTITY_HOMUNCULUS, 0, -1, false, true)) do
					if h:ToNPC().State == NpcState.STATE_MOVE then
						h:ToNPC().State = NpcState.STATE_ATTACK
						h.SubType = 40
						break
					end
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end


		-- Delirium fix
		elseif entity:GetData().wasDelirium then
			entity.State = NpcState.STATE_IDLE
		end


		if entity.FrameCount > 1 then
			return true

		else
			-- Remove Freds from the arena
			for i, stuff in pairs(Isaac.FindByType(EntityType.ENTITY_FRED, -1, -1, false, false)) do
				stuff:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.MrFredUpdate, EntityType.ENTITY_MR_FRED)



--[[ Trailing projectile ]]--
function mod:TrailingProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MR_FRED and projectile:GetData().mrFredTrail and projectile.SpawnerEntity and projectile.FrameCount % 3 == 0 then
		local params = ProjectileParams()
		params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
		params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
		params.ChangeTimeout = 120

		params.Acceleration = 1.1
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.2
		params.Scale = 1 + (mod:Random(25, 40) * 0.01)

		projectile.SpawnerEntity:ToNPC():FireProjectiles(projectile.Position - projectile.Velocity:Normalized(), Vector.FromAngle(projectile.Velocity:GetAngleDegrees() + mod:Random(-10, 10)):Resized(3), 0, params)
		mod:QuickCreep(EffectVariant.CREEP_RED, projectile.SpawnerEntity, projectile.Position, 1.25, 120)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.TrailingProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)