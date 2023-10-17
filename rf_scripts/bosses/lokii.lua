local mod = ReworkedFoes

local Settings = {
	Cooldown = 50,
	PlayerDistance = 120,
	MoveSpeed = 4,
	HopSpeed = 12,
	TPdistance = 280,

	ShotSpeed = 11,
	AngryShotSpeed = 12,

	-- Fly volleyball
	FlySpeed = 20,
	PushBack = 15,
	MaxFlies = 2,

	-- Laser attack
	LaserSpeed = 5,
	LaserBurstSpeed = 10
}



function mod:LokiiInit(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
		entity.ProjectileCooldown = Settings.Cooldown / 2
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.LokiiInit, EntityType.ENTITY_LOKI)

function mod:LokiiUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
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
					data.brim = nil
				end
			end


			-- Movement types
			-- Stay to the side of the player
			if entity.StateFrame == 0 then
				entity.TargetPosition = Vector(target.Position.X + (mod:GetSign(entity.I1 - 1) * Settings.PlayerDistance), target.Position.Y)

				-- Confused
				if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
					mod:WanderAround(entity, Settings.MoveSpeed)
				-- Feared
				elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Position - entity.TargetPosition):Resized(Settings.MoveSpeed), 0.25)
				-- Normal
				elseif entity.Position:Distance(entity.TargetPosition) > 8 then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.MoveSpeed), 0.25)
				end

			-- Stop
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Move towards the player
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.V2 * Settings.HopSpeed, 0.25)

			-- Stay close to each other
			elseif entity.StateFrame == 3 then
				if entity.Position:Distance(pair.Position) > 100 then
					entity.Velocity = mod:Lerp(entity.Velocity, (pair.Position - entity.Position):Resized(Settings.MoveSpeed), 0.25)
				end

			-- Pushed back from the laser
			elseif entity.StateFrame == 4 then
				entity.Velocity = -Vector.FromAngle(data.brim.AngleDegrees) * Settings.LaserSpeed
			end


			-- Idle
			if entity.State == NpcState.STATE_IDLE then
				entity.StateFrame = 0
				mod:LoopingAnim(sprite, "Walk")

				if entity.ProjectileCooldown <= 0 and pair.State == NpcState.STATE_IDLE then
					local attackCount = 2
					if entity.Position:Distance(target.Position) <= 280 then
						attackCount = 3
					end
					local attack = mod:Random(attackCount)

					-- Teleport attack
					if attack == 0 then
						entity.State = NpcState.STATE_JUMP
						sprite:Play("TeleportUp", true)
						entity.StateFrame = 1

						pair.State = NpcState.STATE_JUMP
						pairSprite:Play("TeleportUp", true)
						pair.StateFrame = 1

					-- Hopping attack
					elseif attack == 1 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("HopAttack", true)
						entity.StateFrame = 1

						pair.State = NpcState.STATE_ATTACK
						pairSprite:Play("HopAttack", true)
						pair.StateFrame = 1

					-- Fly volleyball
					elseif attack == 2 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("FlySummon", true)

					-- Laser attack
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
			-- Teleport up
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				end

				if sprite:IsFinished() then
					local room = Game():GetRoom()

					local sideMulti = mod:GetSign(entity.I1 - 1) * -90
					entity.V1 = target.Position + Vector.FromAngle(target.Velocity:GetAngleDegrees() + sideMulti):Resized(Settings.TPdistance)
					entity.V1 = room:FindFreePickupSpawnPosition(entity.V1, 40, true, false)

					if entity.V1:Distance(Game():GetNearestPlayer(entity.Position).Position) < 160 then
						entity.V1 = target.Position + (room:GetCenterPos() - target.Position):Resized(Settings.TPdistance)
						entity.V1 = room:FindFreePickupSpawnPosition(entity.V1, 40, true, false)
					end

					entity.Position = entity.V1
					entity.State = NpcState.STATE_STOMP
					sprite:Play("TeleportAttack", true)
				end

			-- Teleport down
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsEventTriggered("Land") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

				elseif sprite:IsEventTriggered("Shoot") then
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(Settings.ShotSpeed - entity.I2), 3 + entity.I2, ProjectileParams())
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
				end

				if sprite:IsFinished() then
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
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
					entity.StateFrame = 2

					-- Get direction
					entity.V2 = (target.Position - entity.Position):Normalized()
					-- Confused
					if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
						entity.V2 = mod:RandomVector()
					-- Feared
					elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
						entity.V2 = (entity.Position - target.Position):Normalized()
					end

				elseif sprite:IsEventTriggered("Shoot") then
					if entity.I1 == 1 then
						mod:PlaySound(nil, SoundEffect.SOUND_ANIMAL_SQUISH, 1.35)
					end
					mod:ShootEffect(entity, 3, Vector(0, -12), Color.Default, 1, true)

					entity.Velocity = Vector.Zero
					entity.StateFrame = 1

					-- + / X shots
					if entity.I2 == 0 then
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 4), 5 + entity.I1, ProjectileParams())

					-- X / + shots
					elseif entity.I2 == 1 then
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 4), 8 - entity.I1, ProjectileParams())

					-- 6 shots
					elseif entity.I2 == 2 then
						local params = ProjectileParams()
						params.CircleAngle = (entity.I1 - 1) * 0.5
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 6), 9, params)
					end

					entity.I2 = entity.I2 + 1
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.ProjectileCooldown = Settings.Cooldown
					pair.ProjectileCooldown = Settings.Cooldown
				end


			-- Laser Attack
			elseif entity.State == NpcState.STATE_ATTACK2 then
				if sprite:IsEventTriggered("Jump") then
					mod:PlaySound(nil, SoundEffect.SOUND_ANIMAL_SQUISH, 1.25)
					mod:ShootEffect(entity, 3, Vector(mod:GetSign(entity.I1 - 1) * -8, -16), Color.Default, 0.75, true)

				-- Stop moving
				elseif sprite:IsEventTriggered("Land") then
					entity.StateFrame = 1

				elseif sprite:IsEventTriggered("Shoot") then
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position, (entity.I1 - 1) * 180, 16, Vector(mod:GetSign(entity.I1 - 1) * -12, -18), entity), entity}
					data.brim = laser_ent_pair.laser
					data.brim.DepthOffset = entity.DepthOffset - 10

					-- Laser burst
					if entity.I1 == 1 and entity.Position.Y <= pair.Position.Y + 20 and entity.Position.Y >= pair.Position.Y - 20 then
						mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 1.25)

						local params = ProjectileParams()
						params.Scale = 1.25
						params.Variant = ProjectileVariant.PROJECTILE_HUSH
						params.Color = mod.Colors.BrimShot
						mod:FireProjectiles(entity, entity.Position + Vector(entity.Position:Distance(pair.Position) / 2, 0), Vector(Settings.LaserBurstSpeed, 8), 8, params, Color.Default)
					end
				end

				-- Push back + brimstone "collision"
				if data.brim then
					if not data.brim:Exists() then
						data.brim = nil
						entity.StateFrame = 1

					else
						entity.StateFrame = 4

						-- If they collide
						if entity.Position.Y <= pair.Position.Y + 20 and entity.Position.Y >= pair.Position.Y - 20 and pair:GetData().brim then
							data.brim:SetMaxDistance((entity.Position + Vector(mod:GetSign(entity.I1 - 1) * -12, 0)):Distance(pair.Position) / 2)
							entity.I2 = 1

						else
							-- Cancel the attack if moved
							if entity.I2 == 1 then
								sprite:SetFrame(50)
								data.brim:SetTimeout(1)
								entity.I2 = 2
								entity.StateFrame = 1

							elseif entity.I2 == 0 then
								data.brim:SetMaxDistance(0)
							end
						end
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.ProjectileCooldown = Settings.Cooldown
					pair.ProjectileCooldown = Settings.Cooldown
				end


			-- Fly volleyball
			-- Summon fly
			elseif entity.State == NpcState.STATE_SUMMON then
				entity.StateFrame = 1

				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, entity):GetSprite().Offset = Vector(0, -32)
				end

				if sprite:IsFinished() then
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
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)

					local fly = Isaac.Spawn(EntityType.ENTITY_BOOMFLY, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
					fly.State = NpcState.STATE_SPECIAL
					fly.StateFrame = Settings.MaxFlies

					-- At target
					if entity.I2 >= 1 then
						fly.V2 = (target.Position - entity.Position):Resized(Settings.FlySpeed)
						entity.ProjectileCooldown = Settings.Cooldown
						pair.ProjectileCooldown = Settings.Cooldown

					-- At pair
					else
						fly.V2 = (pair.Position - entity.Position):Resized(Settings.FlySpeed)
						pair.StateFrame = 1
						entity.I2 = entity.I2 + 1
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end

			-- Wait for fly
			elseif entity.State == NpcState.STATE_SUMMON3 then
				if sprite:IsFinished() then
					sprite:Play("FlyWaitLoop", true)
				end

			-- Catch fly
			elseif entity.State == NpcState.STATE_SPECIAL then
				entity.StateFrame = 1
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0)
				end

				if sprite:IsFinished() then
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
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
				return true


			-- Replace default attacks
			elseif entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3 then
				entity.State = entity.State + 2

			-- Custom attacks
			elseif entity.State == NpcState.STATE_ATTACK4 or entity.State == NpcState.STATE_ATTACK5 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
					mod:PlaySound(nil, SoundEffect.SOUND_ANIMAL_SQUISH, 1.1)
					mod:ShootEffect(entity, 3, Vector(0, -12), Color.Default, 1, true)

					-- Ground slam
					if entity.State == NpcState.STATE_ATTACK4 then
						local params = ProjectileParams()
						params.TargetPosition = entity.Position
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.075

						if mod:Random(1) == 1 then
							params.BulletFlags = ProjectileFlags.ORBIT_CW
						else
							params.BulletFlags = ProjectileFlags.ORBIT_CCW
						end
						entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)


					-- Triple attack
					elseif entity.State == NpcState.STATE_ATTACK5 then
						-- + shots
						if entity.I2 == 0 then
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 4), 6, ProjectileParams())
							entity.I2 = entity.I2 + 1

						-- 6 shots
						elseif entity.I2 == 1 then
							local params = ProjectileParams()
							params.CircleAngle = 0
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 6), 9, params)
							entity.I2 = entity.I2 + 1

						-- 8 shots
						elseif entity.I2 == 2 then
							entity:FireProjectiles(entity.Position, Vector(Settings.AngryShotSpeed, 8), 8, ProjectileParams())
							entity.I2 = 0
						end
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.LokiiUpdate, EntityType.ENTITY_LOKI)



--[[ Red boom fly ball ]]--
function mod:RedBoomFlyCollision(entity, target, bool)
	if entity.Variant == 1 and target.Type == EntityType.ENTITY_LOKI and target.Variant == 1 then
		if entity:ToNPC().State == NpcState.STATE_SPECIAL and target:ToNPC().State == NpcState.STATE_SUMMON3 and target:GetData().pair.Index == entity.SpawnerEntity.Index then
			entity:Remove()
			target:ToNPC().State = NpcState.STATE_SPECIAL
			target:GetSprite():Play("FlyCatch", true)
			target.Velocity = (target.Position - entity.Position):Resized(Settings.PushBack)
		end

		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.RedBoomFlyCollision, EntityType.ENTITY_BOOMFLY)

function mod:RedBoomFlyDeath(entity)
	if entity.Variant == 1 and entity.State == NpcState.STATE_SPECIAL and entity.SpawnerEntity and entity.SpawnerEntity:GetData().pair and entity.SpawnerEntity:GetData().pair:ToNPC().State == NpcState.STATE_SUMMON3 then
		entity.SpawnerEntity:GetData().pair:ToNPC().State = NpcState.STATE_IDLE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RedBoomFlyDeath, EntityType.ENTITY_BOOMFLY)