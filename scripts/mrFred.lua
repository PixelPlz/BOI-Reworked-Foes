local mod = BetterMonsters
local game = Game()



function mod:mrFredInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		entity.MaxHitPoints = 650
		entity.HitPoints = entity.MaxHitPoints
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = 30
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.mrFredInit, EntityType.ENTITY_MR_FRED)

function mod:mrFredUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = game:GetRoom()


		if entity.StateFrame == 1 then
			entity.Velocity = mod:Lerp(entity.Velocity, (entity.V1 - entity.Position):Normalized() * 11, 0.25)
		else
			entity.Velocity = Vector.Zero
		end


		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = math.random(60, 90)

				-- Decide attack
				local attack = math.random(1, 5)
				if attack == 1 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("LeapDown", true)

				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Shoot", true)

				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("Barf", true)
					entity.I1 = 0
				
				elseif attack == 4 then
					entity.State = NpcState.STATE_ATTACK3
					sprite:Play("Squirt", true)
					entity.I2 = 0

				elseif attack == 5 then
					local homoCount = Isaac.CountEntities(nil, EntityType.ENTITY_HOMUNCULUS, 0, 0)
					if (homoCount > 0 and math.random(0, 1) == 1) or homoCount > 2 then
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
				entity.V1 = room:FindFreePickupSpawnPosition(target.Position, 40, true, false)
				if (entity.V1 - entity.Position):GetAngleDegrees() < 0 then
					sprite:SetAnimation("LeapUp", false)
				end
			end

			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
				entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8, 0, false, 1)
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.75)

			elseif sprite:IsEventTriggered("Jump") then
				entity.StateFrame = 1
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

			elseif sprite:IsEventTriggered("Land") then
				entity.StateFrame = 0
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

			elseif sprite:IsEventTriggered("Burrow") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_APPEAR_CUSTOM
				sprite:Play("Appear", true)
				entity.Position = room:FindFreePickupSpawnPosition(entity.Position, 40, true, false)
			end

		-- Popup
		elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
			if sprite:IsEventTriggered("Burrow") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.75)

			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
				entity:PlaySound(SoundEffect.SOUND_FAT_WIGGLE, 1.25, 0, false, 0.95)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end


		-- Harlequin baby attack
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_LITTLE_SPIT, 1, 0, false, 0.9)
				entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR, 1.1, 0, false, 1)

				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.BROCCOLI | ProjectileFlags.ACID_RED)
				params.Scale = 2.5
				params.FallingAccelModifier = -0.175
				for i = -1, 1, 2 do
					entity:FireProjectiles(entity.Position, Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + (i * 20)) * 13, 0, params)
				end
			end

			if sprite:IsFinished("Shoot") then
				entity.State = NpcState.STATE_IDLE
				entity.ProjectileCooldown = 60
			end


		-- Barf attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:IsEventTriggered("Sound") then
				entity:PlaySound(SoundEffect.SOUND_ANGRY_GURGLE, 1.25, 0, false, 0.95)

			elseif sprite:IsEventTriggered("Shoot") then
				entity.TargetPosition = room:GetClampedPosition(target.Position + (Vector.FromAngle(math.random(0, 359)) * math.random(10, 100)), 0)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, entity.TargetPosition, Vector.Zero, entity):ToEffect().Timeout = 30
				
				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.EXPLODE
				params.GridCollision = false
				params.Scale = 1.75
				params.FallingAccelModifier = 1.5
				params.FallingSpeedModifier = -40
				entity:FireProjectiles(entity.Position, (entity.TargetPosition - entity.Position):Normalized() * (entity.Position:Distance(entity.TargetPosition) / 32), 0, params)
				
				if entity.I1 < 2 then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position + Vector(0, 1), Vector.Zero, entity):GetSprite().Offset = Vector(1, -44)
					if entity.I1 == 0 then
						entity:PlaySound(SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 1, 0, false, 1)
					end
				end
				entity.I1 = entity.I1 + 1
			end
			
			if sprite:IsFinished("Barf") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Squirt attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:IsEventTriggered("Sound") then
				entity:PlaySound(SoundEffect.SOUND_FAT_WIGGLE, 1.25, 0, false, 0.95)

			elseif sprite:IsEventTriggered("Land") then
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position - Vector(0, 8), 2.5)
				SFXManager():Play(SoundEffect.SOUND_HEARTOUT, 0.8)
			
			elseif sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 0.9, 0, false, 1)
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
				local multiplier = 1
				if entity.FrameCount % 2 ~= 0 then
					multiplier = -1
				end
				entity.V2 = entity.Position + (Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + (multiplier * 90)) * 1040)
				entity.V2 = room:FindFreePickupSpawnPosition(entity.V2, 40, true, false)

				local angleDegrees = (entity.V2 - entity.Position):GetAngleDegrees()
				local facing = "Left"
				if angleDegrees > -45 and angleDegrees < 45 then
					facing = "Right"
				elseif angleDegrees >= 45 and angleDegrees <= 135 then
					facing = "Down"
				elseif angleDegrees < -45 and angleDegrees > -135 then
					facing = "Up"
				end

				sprite:SetAnimation("Summon" .. facing, false)
			end

			if sprite:IsEventTriggered("Shoot") then
				Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, entity.V2, Vector.Zero, entity)
				SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end

		-- Release a Homunculus
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Sound") then
				entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 1, 0, false, 1)

			elseif sprite:IsEventTriggered("Shoot") then
				entity:FireBossProjectiles(9, Vector.Zero, 10, ProjectileParams())
				SFXManager():Play(SoundEffect.SOUND_HEARTIN)
				SFXManager():Play(SoundEffect.SOUND_WHIP_HIT, 0.75)

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
		end


		if entity.FrameCount > 1 then
			return true
		else
			for i, stuff in pairs(Isaac.FindByType(EntityType.ENTITY_FRED, -1, -1, false, false)) do
				stuff:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.mrFredUpdate, EntityType.ENTITY_MR_FRED)

-- Trail projectile
function mod:trailProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MR_FRED and projectile:HasProjectileFlags(ProjectileFlags.BROCCOLI) and projectile.SpawnerEntity and projectile.FrameCount % 3 == 0 then
		local params = ProjectileParams()
		params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
		params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
		params.ChangeTimeout = 120

		params.Acceleration = 1.1
		params.FallingSpeedModifier = 1
		params.FallingAccelModifier = -0.2
		params.Scale = 1 + (math.random(25, 40) * 0.01)

		projectile.SpawnerEntity:ToNPC():FireProjectiles(projectile.Position - projectile.Velocity:Normalized(), Vector.FromAngle(projectile.Velocity:GetAngleDegrees() + math.random(-10, 10)) * 3, 0, params)
		mod:QuickCreep(EffectVariant.CREEP_RED, projectile.SpawnerEntity, projectile.Position, 1.25, 120)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.trailProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)