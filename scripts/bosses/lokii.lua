local mod = BetterMonsters

local Settings = {
	Cooldown = 60,
	PlayerDistance = 120,
	MoveSpeed = 4,
	ShotSpeed = 11,
	AngryShotSpeed = 12,

	FlySpeed = 20,
	PushBack = 15,
	MaxFlies = 2,

	HopSpeed = 12,
	TPdistance = 320,

	LaserSpeed = 5,
	LaserBurstSpeed = 10
}



function mod:lokiiInit(entity)
	if entity.Variant == 1 then
		entity.ProjectileCooldown = Settings.Cooldown
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.lokiiInit, EntityType.ENTITY_LOKI)

function mod:lokiiUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Get corresponding half
		if entity.FrameCount < 2 then
			for i, pair in pairs(Isaac.FindByType(EntityType.ENTITY_LOKI, 1, -1, false, false)) do
				if pair:ToNPC().I1 == 1 and not pair:GetData().pair then
					data.pair = pair
					pair:GetData().pair = entity
					break
				end
			end
		end


		-- For 2 pairs --
		if data.pair then
			local pair = data.pair:ToNPC()
			local pairSprite = pair:GetSprite()

			if data.pair:IsDead() or not data.pair:Exists() then
				data.pair = nil
				entity.State = NpcState.STATE_APPEAR_CUSTOM
				sprite:Play("Angry", true)
				entity.Velocity = Vector.Zero
				entity.I2 = 0

				if data.brim then
					data.brim:SetTimeout(1)
				end
			end
			
			
			-- Movement types
			if entity.StateFrame == 0 then
				entity.TargetPosition = Vector(target.Position.X - Settings.PlayerDistance + ((entity.I1 - 1) * (Settings.PlayerDistance * 2)), target.Position.Y)
				if entity.Position:Distance(entity.TargetPosition) > 8 then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Normalized() * Settings.MoveSpeed, 0.25)
				end
			
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
			
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.V2 * Settings.HopSpeed, 0.25)
			
			elseif entity.StateFrame == 3 then
				if entity.Position:Distance(pair.Position) > 100 then
					entity.Velocity = mod:Lerp(entity.Velocity, (pair.Position - entity.Position):Normalized() * Settings.MoveSpeed, 0.25)
				end
			
			elseif entity.StateFrame == 4 then
				entity.Velocity = -Vector.FromAngle(data.brim.AngleDegrees) * Settings.LaserSpeed
			end


			-- Idle
			if entity.State == NpcState.STATE_IDLE then
				entity.StateFrame = 0
				mod:LoopingAnim(sprite, "Walk")

				if entity.ProjectileCooldown <= 0 and pair.State == NpcState.STATE_IDLE then
					local attack = math.random(0, 3)

					if attack == 0 then
						entity.State = NpcState.STATE_JUMP
						sprite:Play("TeleportUp", true)
						pair.State = NpcState.STATE_JUMP
						pairSprite:Play("TeleportUp", true)
						entity.StateFrame = 1
						pair.StateFrame = 1

					elseif attack == 1 then
						entity.State = NpcState.STATE_ATTACK
						pair.State = NpcState.STATE_ATTACK
						sprite:Play("HopAttack", true)
						pairSprite:Play("HopAttack", true)
						entity.StateFrame = 1
						pair.StateFrame = 1

					elseif attack == 2 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("FlySummon", true)

					elseif attack == 3 then
						entity.State = NpcState.STATE_ATTACK2
						sprite:Play("LaserAttack", true)
						pair.State = NpcState.STATE_ATTACK2
						pairSprite:Play("LaserAttack", true)
					end
					
					entity.I2 = 0
					pair.I2 = 0

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			
			
			-- Teleport Attack
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				end

				if sprite:IsFinished("TeleportUp") then
					local sideL = -60
					local sideH = 60
					if entity.I1 == 1 then
						sideL = 120
						sideH = 240
					end
					entity.V1 = target.Position + Vector.FromAngle(math.random(sideL, sideH)) * Settings.TPdistance
					entity.V1 = Game():GetRoom():FindFreePickupSpawnPosition(entity.V1, 40, true, false)

					entity.Position = entity.V1
					entity.State = NpcState.STATE_STOMP
					sprite:Play("TeleportAttack", true)
				end
			
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsEventTriggered("Land") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

				elseif sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * (Settings.ShotSpeed - entity.I2), 3 + entity.I2, ProjectileParams())
				end

				if sprite:IsFinished("TeleportAttack") then
					if entity.I2 < 1 then
						entity.State = NpcState.STATE_JUMP
						sprite:Play("TeleportUp", true)
						entity.I2 = entity.I2 + 1

					else
						entity.State = NpcState.STATE_IDLE
						entity.ProjectileCooldown = Settings.Cooldown
						pair.ProjectileCooldown = Settings.Cooldown
					end
				end
			
			
			-- Hopping attack
			elseif entity.State == NpcState.STATE_ATTACK then
				if sprite:IsEventTriggered("Jump") then
					entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
					entity.V2 = (target.Position - entity.Position):Normalized()
					entity.StateFrame = 2

				elseif sprite:IsEventTriggered("Shoot") then
					SFXManager():Play(SoundEffect.SOUND_ANIMAL_SQUISH, 1.25)
					entity.Velocity = Vector.Zero
					entity.StateFrame = 1

					if entity.I2 == 0 then
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 4), 5 + entity.I1, ProjectileParams())
					elseif entity.I2 == 1 then
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 4), 8 - entity.I1, ProjectileParams())
					elseif entity.I2 == 2 then
						local params = ProjectileParams()
						params.CircleAngle = 0.5 - ((entity.I1 - 1) * 0.5)
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 6), 9, params)
					end
					
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 3, entity.Position, Vector.Zero, entity)
					effect.DepthOffset = entity.DepthOffset - 10
					effect:GetSprite().Offset = Vector(0, -12)

					entity.I2 = entity.I2 + 1
				end
				
				if sprite:IsFinished("HopAttack") then
					entity.State = NpcState.STATE_IDLE
					entity.ProjectileCooldown = Settings.Cooldown
					pair.ProjectileCooldown = Settings.Cooldown
				end
			
			
			-- Laser Attack
			elseif entity.State == NpcState.STATE_ATTACK2 then
				if sprite:IsEventTriggered("Jump") then
					SFXManager():Play(SoundEffect.SOUND_ANIMAL_SQUISH, 1.25)
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 3, entity.Position, Vector.Zero, entity)
					effect.DepthOffset = entity.DepthOffset - 10
					effect:GetSprite().Offset = Vector(6 - ((entity.I1 - 1) * 12), -12)
					effect.SpriteScale = Vector(0.75, 0.75)
				
				-- Stop moving
				elseif sprite:IsEventTriggered("Land") then
					entity.StateFrame = 1
				
				elseif sprite:IsEventTriggered("Shoot") then
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position, 0 + ((entity.I1 - 1) * 180), 16, Vector(12 - ((entity.I1 - 1) * 24), -18), entity), entity}
					data.brim = laser_ent_pair.laser
					data.brim.DepthOffset = entity.DepthOffset - 10

					-- Laser burst
					if entity.I1 == 1 and entity.Position.Y <= pair.Position.Y + 20 and entity.Position.Y >= pair.Position.Y - 20 then
						SFXManager():Play(SoundEffect.SOUND_HEARTOUT, 1.25)
						local params = ProjectileParams()
						params.Scale = 1.25
						params.Variant = ProjectileVariant.PROJECTILE_HUSH
						params.Color = brimstoneBulletColor
						entity:FireProjectiles(entity.Position + Vector(entity.Position:Distance(pair.Position) / 2, 0), Vector(Settings.LaserBurstSpeed, 8), 8, params)
					end
				end

				-- Push back + brimstone ""collision""
				if data.brim then
					if not data.brim:Exists() then
						data.brim = nil
						entity.StateFrame = 1

					else
						entity.StateFrame = 4
						if entity.Position.Y <= pair.Position.Y + 20 and entity.Position.Y >= pair.Position.Y - 20 and pair:GetData().brim then
							data.brim:SetMaxDistance((entity.Position + Vector(12 - ((entity.I1 - 1) * 24), 0)):Distance(pair.Position) / 2)
						else
							data.brim:SetMaxDistance(0)
						end
					end
				end

				if sprite:IsFinished("LaserAttack") then
					entity.State = NpcState.STATE_IDLE
					entity.ProjectileCooldown = Settings.Cooldown
					pair.ProjectileCooldown = Settings.Cooldown
				end


			-- Fly volleyball
			-- Summon fly
			elseif entity.State == NpcState.STATE_SUMMON then
				entity.StateFrame = 1

				if sprite:IsEventTriggered("Shoot") then
					SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite().Offset = Vector(0, -32)
				end

				if sprite:IsFinished("FlySummon") then
					entity.State = NpcState.STATE_SUMMON2
					sprite:Play("FlyThrow", true)
					
					if entity.I2 == 0 then
						pair.State = NpcState.STATE_SUMMON3
						pairSprite:Play("FlyWaitStart", true)
						pair.StateFrame = 0
					end
				end
			
			-- Throw fly
			elseif entity.State == NpcState.STATE_SUMMON2 then
				entity.StateFrame = 1

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
					local fly = Isaac.Spawn(EntityType.ENTITY_BOOMFLY, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
					fly.State = NpcState.STATE_SPECIAL

					-- At target
					if entity.I2 >= 1 then
						fly.V2 = (target.Position - entity.Position):Normalized()
						entity.ProjectileCooldown = Settings.Cooldown
						pair.ProjectileCooldown = Settings.Cooldown

					-- At pair
					else
						fly.V2 = (pair.Position - entity.Position):Normalized()
						pair.StateFrame = 1
						entity.I2 = entity.I2 + 1
					end
				end

				if sprite:IsFinished("FlyThrow") then
					entity.State = NpcState.STATE_IDLE
				end

			-- Wait for fly
			elseif entity.State == NpcState.STATE_SUMMON3 then
				if sprite:IsFinished("FlyWaitStart") then
					sprite:Play("FlyWaitLoop", true)
				end
			
			-- Catch fly
			elseif entity.State == NpcState.STATE_SPECIAL then
				entity.StateFrame = 1
				if sprite:IsEventTriggered("Shoot") then
					SFXManager():Play(SoundEffect.SOUND_MEAT_FEET_SLOW0)
				end

				if sprite:IsFinished("FlyCatch") then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("FlySummon", true)
					sprite:SetFrame(99) -- Dumb way to do it
				end
			end

			if entity.FrameCount > 1 then
				return true
			end


		-- One pair only --
		else
			-- Do angry animation
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				if sprite:IsFinished("Angry") then
					entity.State = NpcState.STATE_IDLE
				end
				return true


			-- Replace attacks
			elseif entity.State == NpcState.STATE_ATTACK2 then
				entity.State = NpcState.STATE_ATTACK4

			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.State = NpcState.STATE_ATTACK5


			elseif entity.State == NpcState.STATE_ATTACK4 or entity.State == NpcState.STATE_ATTACK5 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 1, 0, false, 1)
					SFXManager():Play(SoundEffect.SOUND_ANIMAL_SQUISH, 1.1)

					-- Ground slam
					if entity.State == NpcState.STATE_ATTACK4 then
						local params = ProjectileParams()
						params.TargetPosition = entity.Position
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.075

						if math.random(0, 1) == 1 then
							params.BulletFlags = ProjectileFlags.ORBIT_CW
						else
							params.BulletFlags = ProjectileFlags.ORBIT_CCW
						end
						entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
					
					
					-- Triple attack
					elseif entity.State == NpcState.STATE_ATTACK5 then
						if entity.I2 == 0 then
							entity.I2 = entity.I2 + 1
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 4), 6, ProjectileParams())

						elseif entity.I2 == 1 then
							entity.I2 = entity.I2 + 1
							local params = ProjectileParams()
							params.CircleAngle = 0
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 6), 9, params)
						
						elseif entity.I2 == 2 then
							entity.I2 = 0
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 8), 8, ProjectileParams())
						end
					end
					
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 3, entity.Position, Vector.Zero, entity)
					effect.DepthOffset = entity.DepthOffset - 10
					effect:GetSprite().Offset = Vector(0, -12)
				end
				
				if sprite:IsFinished(sprite:GetAnimation()) then
					entity.State = NpcState.STATE_IDLE
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.lokiiUpdate, EntityType.ENTITY_LOKI)



-- Red boom fly ball
function mod:redBoomFlyUpdate(entity)
	if entity.Variant == 1 and entity.State == NpcState.STATE_SPECIAL and not entity:IsDead() and not entity:HasMortalDamage() then
		local sprite = entity:GetSprite()
		if not sprite:IsPlaying("Fly") then
			sprite:Play("Fly", true)
		end

		entity.Velocity = entity.V2 * Settings.FlySpeed
		entity.Mass = 0.1
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		-- Die / Return to regular state when hitting a wall
		if entity:CollidesWithGrid() then
			if Isaac.CountEntities(nil, EntityType.ENTITY_BOOMFLY, 1, -1) <= Settings.MaxFlies then
				entity.State = NpcState.STATE_MOVE
				entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.Mass = 7
				SFXManager():Play(SoundEffect.SOUND_MEAT_FEET_SLOW0)

			else
				entity:TakeDamage(entity.MaxHitPoints * 2, 0, EntityRef(nil), 0)
				entity.Velocity = Vector.Zero
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.redBoomFlyUpdate, EntityType.ENTITY_BOOMFLY)

function mod:redBoomFlyCollide(entity, target, bool)
	if entity.Variant == 1 and target.Type == EntityType.ENTITY_LOKI and target.Variant == 1 then
		if entity:ToNPC().State == NpcState.STATE_SPECIAL and target:ToNPC().State == NpcState.STATE_SUMMON3 and target:GetData().pair.Index == entity.SpawnerEntity.Index then
			entity:Remove()
			target:ToNPC().State = NpcState.STATE_SPECIAL
			target:GetSprite():Play("FlyCatch", true)
			target.Velocity = (target.Position - entity.Position):Normalized() * Settings.PushBack
		end
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.redBoomFlyCollide, EntityType.ENTITY_BOOMFLY)

function mod:redBoomFlyDeath(entity)
	if entity.Variant == 1 and entity.State == NpcState.STATE_SPECIAL and entity.SpawnerEntity and entity.SpawnerEntity:GetData().pair and entity.SpawnerEntity:GetData().pair:ToNPC().State == NpcState.STATE_SUMMON3 then
		entity.SpawnerEntity:GetData().pair:ToNPC().State = NpcState.STATE_IDLE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.redBoomFlyDeath, EntityType.ENTITY_BOOMFLY)