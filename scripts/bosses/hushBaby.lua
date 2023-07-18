local mod = BetterMonsters

local Settings = {
	MoveSpeed = 5,
	Cooldown = 60,
	TearCooldown = 22,
	TeleportCooldown = {90, 180},
	SoundTimer = {120, 180},
}



function mod:hushBabyInit(entity)
	if entity.Variant == 2 then
		local data = entity:GetData()

		entity.I1 = 0
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		data.tearCooldown = Settings.TearCooldown
		data.shotCount = 1
		data.teleportTimer = Settings.TeleportCooldown[2]
		data.soundTimer = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.hushBabyInit, EntityType.ENTITY_ISAAC)

function mod:hushBabyUpdate(entity)
	if entity:GetSprite():IsEventTriggered("Flap") then
		mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING, 0.75)
	end


	if entity.Variant == 2 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		--[[ Always active outside of transition state ]]--
		if entity.State ~= NpcState.STATE_SPECIAL then
			local tenPercent = (entity.MaxHitPoints / 10)

			-- Transition to next phase
			if ((entity.I1 == 1 and entity.HitPoints <= tenPercent * 7) -- 1st to 2nd phase
			or (entity.I1 == 2 and entity.HitPoints <= tenPercent * 4)) -- 2nd to 3rd phase
			and not data.wasDelirium then
				entity.State = NpcState.STATE_SPECIAL

				if entity.I1 == 1 then
					sprite:Play("1StandUp", true)
				elseif entity.I1 == 2 then
					sprite:Play("2Evolve", true)
				end
			end
		end



		--[[ Idle phase ]]--
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, math.max(1, entity.I1) .. "Idle")

			-- Movement
			if entity.I1 == 3 then
				-- Confused
				if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
					mod:WanderAround(entity, Settings.MoveSpeed)

				-- Feared
				elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Position - target.Position):Resized(Settings.MoveSpeed), 0.25)

				-- Normal
				else
					-- Stay at a point around the player, change this point every 60 frames
					if not data.angle or entity:IsFrame(60, 0) then
						data.angle = mod:Random(7) * 45
					end
					local pos = target.Position + Vector.FromAngle(data.angle):Resized(100)

					if entity.Position:Distance(pos) < 20 then
						entity.Velocity = mod:StopLerp(entity.Velocity)
					else
						entity.Velocity = mod:Lerp(entity.Velocity, (pos - entity.Position):Resized(Settings.MoveSpeed), 0.25)
					end
				end

			-- Stationary
			else
				entity.Velocity = mod:StopLerp(entity.Velocity)
			end


			if entity.I1 <= 1 then
				if data.soundTimer <= 0 then
					mod:PlaySound(entity, SoundEffect.SOUND_SCARED_WHIMPER)
					data.soundTimer = mod:Random(Settings.SoundTimer[1], Settings.SoundTimer[2])
				else
					data.soundTimer = data.soundTimer - 1
				end
			end


			if entity.I1 > 0 then
				-- Shoot at the player
				if data.tearCooldown <= 0 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.15

					-- Every 3rd attack has more shots
					if data.shotCount % 3 == 0 then
						local mode = 2 + entity.I1

						if entity.I1 == 1 then
							mode = 2
						end
						params.Color = IRFcolors.HushGreen

						entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(9 - entity.I1), mode, params)

					else
						params.Color = IRFcolors.HushBlue
						for i = -1, 1, 2 do
							entity:FireProjectiles(entity.Position + (target.Position - entity.Position):Resized(8):Rotated(i * 90), (target.Position - entity.Position):Resized(10), 0, params)
						end
					end

					data.tearCooldown = Settings.TearCooldown
					data.shotCount = data.shotCount + 1
					mod:PlaySound(nil, SoundEffect.SOUND_TEARS_FIRE)

				else
					data.tearCooldown = data.tearCooldown - 1
				end


				-- Teleport
				if data.teleportTimer <= 0 then
					entity.State = NpcState.STATE_JUMP
					data.teleportTimer = mod:Random(Settings.TeleportCooldown[1], Settings.TeleportCooldown[2])

					if entity.I1 == 3 then
						sprite:Play("3FBAttack3", true)
					else
						sprite:Play(entity.I1 .. "Teleport", true)
					end

				else
					data.teleportTimer = data.teleportTimer - 1
				end


				-- Choose an attack
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = Settings.Cooldown
					data.tearCooldown = Settings.TearCooldown

					local attackCount = 2
					if entity.I1 == 3 and Isaac.CountEntities(entity, EntityType.ENTITY_HUSH_GAPER, -1, -1) <= 4 then
						attackCount = 3
					end
					local attack = mod:Random(1, attackCount)


					if attack == 3 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("3Summon", true)

					else
						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK
						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK2
						end

						entity.I2 = 0
						entity.StateFrame = 0
						entity.V1 = Vector(mod:Random(10, 100) * 0.01, 0)

						if entity.I1 == 2 then
							sprite:Play("2Attack", true)
						elseif entity.I1 == 3 then
							sprite:Play("3FBAttack4Start", true)
						end
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			end



		--[[ Transition ]]--
		elseif entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("Shoot") then
				Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 1, entity.Position, Vector.Zero, entity).Parent = entity

				-- 1st to 2nd phase
				if entity.I1 == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_HOLY)

				-- 2nd to 3rd phase
				elseif entity.I1 == 2 then
					mod:PlaySound(nil, SoundEffect.SOUND_SUPERHOLY)
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				end
			end

			if sprite:IsFinished() then
				entity.I1 = entity.I1 + 1
				entity.ProjectileCooldown = Settings.Cooldown / 2
				data.spawnTimer = 0
				data.shotCount = 1
				entity.State = NpcState.STATE_IDLE
			end



		--[[ Teleport ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get position
			if sprite:IsEventTriggered("Shoot") or sprite:IsFinished("3FBAttack3") then
				local position = target.Position + target.Velocity:Resized(240)
				if room:IsPositionInRoom(position, 0) == false or target.Velocity:Length() <= 0.1 then
					position = target.Position + (room:GetCenterPos() - target.Position):Resized(240)
				end
				entity.Position = room:FindFreePickupSpawnPosition(position, 40, true, false)

			-- Teleport away
			elseif sprite:IsEventTriggered("TeleportUp") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL2, 1.2)

				-- Projectiles
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.1
				params.CircleAngle = 0
				params.Color = IRFcolors.HushBlue
				entity:FireProjectiles(entity.Position, Vector(9, 12), 9, params)

			-- Teleported
			elseif sprite:IsEventTriggered("TeleportDown") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL1, 1.2)
			end

			if sprite:IsFinished("3FBAttack3") then
				sprite:Play("3Appear", true)
			elseif sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end



		--[[ Attacks ]]--
		elseif entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- 2nd phase
			if entity.I1 == 2 then
				if sprite:IsEventTriggered("Shoot") then
					-- Fly attack
					if entity.State == NpcState.STATE_ATTACK then
						local sign = mod:RandomSign()

						for i = 0, 3 do
							local fly = Isaac.Spawn(IRFentities.Type, IRFentities.HushFlyAttack, 0, entity.Position, Vector.Zero, entity):ToNPC()
							fly.Parent = entity
							fly.TargetPosition = entity.Position
							fly.StateFrame = i
							fly.I1 = 100
							fly.V2 = Vector(sign * fly.V2.X, fly.V2.Y)
						end
					
					-- Orbiting shots
					else
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_HUSH
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.09
						params.CircleAngle = entity.V1.X
						params.Color = IRFcolors.HushOrange
						params.TargetPosition = entity.Position

						params.BulletFlags = ProjectileFlags.ORBIT_CCW
						entity:FireProjectiles(entity.Position, Vector(12, 12), 9, params)
						params.BulletFlags = ProjectileFlags.ORBIT_CW
						entity:FireProjectiles(entity.Position, Vector(7, 12), 9, params)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_THUMBSUP, 0.6)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end



			-- 1st / 3rd phase
			else
				local shotCount = 4
				if entity.State == NpcState.STATE_ATTACK2 then
					shotCount = 6
				end

				-- Attacks
				local function shoot()
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					params.CircleAngle = entity.V1.X

					-- Continuum shots
					if entity.State == NpcState.STATE_ATTACK then
						params.BulletFlags = (ProjectileFlags.CONTINUUM | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
						params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
						params.ChangeTimeout = 180
						entity:FireProjectiles(entity.Position, Vector(10, 6), 9, params)

					-- Sawtooth wiggle shots
					else
						params.BulletFlags = ProjectileFlags.TRIANGLE
						params.Color = IRFcolors.HushOrange
						entity:FireProjectiles(entity.Position, Vector(12, 6), 9, params)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
					entity.I2 = entity.I2 + 1
				end


				-- 1st phase
				if entity.I1 == 1 then
					if sprite:IsEventTriggered("Shoot") then
						shoot()
					end

					-- Repeat 4 / 6 times
					if entity.I2 < shotCount then
						if entity.StateFrame <= 0 then
							sprite:Play("1Attack", true)
							entity.StateFrame = 3
						else
							entity.StateFrame = entity.StateFrame - 1
						end

					elseif sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end


				-- 3rd phase
				elseif entity.I1 == 3 then
					if sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(nil, SoundEffect.SOUND_POWERUP2, 0.9)
					end

					if sprite:IsFinished("3FBAttack4Start") or sprite:IsPlaying("3FBAttack4Loop") then
						if not sprite:IsPlaying("3FBAttack4Start") then
							mod:LoopingAnim(sprite, "3FBAttack4Loop")
						end

						-- Repeat 4 / 6 times
						if entity.I2 < shotCount then
							if entity.StateFrame <= 0 then
								shoot()
								entity.StateFrame = 3
							else
								entity.StateFrame = entity.StateFrame - 1
							end

						else
							sprite:Play("3FBAttack4End", true)
						end

					elseif sprite:IsFinished("3FBAttack4End") then
						entity.State = NpcState.STATE_IDLE
					end
				end
			end



		--[[ Summon ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 3 do
					local gaper = Isaac.Spawn(EntityType.ENTITY_HUSH_GAPER, 0, 0, entity.Position + Vector.FromAngle(i * 90):Resized(50), Vector.Zero, entity):ToNPC()
					gaper:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					gaper.State = NpcState.STATE_SPECIAL
					gaper:GetSprite():Play("JumpOut", true)
					gaper.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				end
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end



		-- Delirium fix
		elseif data.wasDelirium then
			entity.State = NpcState.STATE_IDLE
			entity.I1 = 4 - math.ceil(entity.HitPoints / (entity.MaxHitPoints / 3))
			entity.ProjectileCooldown = 60
		end


		if entity.FrameCount > 1 and not entity:IsDead() then
			return true

		elseif entity:IsDead() then
			-- Get rid of Hush Gapers and Eternal Flies
			for i = 0, 1 do
				local type = EntityType.ENTITY_HUSH_GAPER
				if i == 1 then
					type = EntityType.ENTITY_ATTACKFLY
				end

				for _,guy in pairs(Isaac.FindByType(type, -1, -1, false, true)) do
					guy:Kill()
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.hushBabyUpdate, EntityType.ENTITY_ISAAC)

function mod:hushBabyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 2 and target:ToNPC().I1 == 0 then
		target:ToNPC().I1 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hushBabyDMG, EntityType.ENTITY_ISAAC)



--[[ Circling fly attack ]]--
function mod:hushFlyAttackInit(entity)
	if entity.Variant == IRFentities.HushFlyAttack then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.V2 = Vector(4, 20) -- Rotation speed / Distance from parent

		-- Set random sprite
		entity.Scale = 1.25
		local sprite = entity:GetSprite()
		sprite:Play("Fly", true)
		sprite:ReplaceSpritesheet(0, "gfx/monsters/afterbirth/monster_010_fly_hush_" .. mod:Random(1, 3) .. ".png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.hushFlyAttackInit, IRFentities.Type)

function mod:hushFlyAttackUpdate(entity)
	if entity.Variant == IRFentities.HushFlyAttack then
		if entity.Parent and entity.I1 > 0 then
			-- Orbit spawn position
			entity.V1 = Vector((90 * entity.StateFrame), entity.V1.Y + entity.V2.X) -- Rotation offset / Current rotation

			if entity.V1.Y >= 360 then
				entity.V1 = Vector(entity.V1.X, entity.V1.Y - 360)
			elseif entity.V1.Y < 0 then
				entity.V1 = Vector(entity.V1.X, entity.V1.Y + 360)
			end

			entity.Position = mod:Lerp(entity.Position, entity.TargetPosition + Vector.FromAngle(entity.V1.X + entity.V1.Y):Resized(entity.V2.Y), 0.1)
			entity.Velocity = Vector.Zero


			-- Increase distance
			entity.V2 = Vector(entity.V2.X, entity.V2.Y + 9)
			entity.I1 = entity.I1 - 1


			-- Projectiles
			if entity.FrameCount >= 8 and entity:IsFrame(4, 0) then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = IRFcolors.HushPink
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.2

				params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 120

				entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
			end

		else
			entity:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hushFlyAttackUpdate, IRFentities.Type)

function mod:hushFlyAttackDeath(entity)
	if entity.Variant == IRFentities.HushFlyAttack then
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FLY_EXPLOSION, 1, entity.Position, Vector.Zero, entity):GetSprite()
		effect:Load("gfx/296.000_hush fly.anm2", true)
		effect:Play("Die", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.hushFlyAttackDeath, IRFentities.Type)



--[[ Hush Gaper special appear animation ]]--
function mod:hushGaperUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL and entity:GetSprite():IsPlaying("JumpOut") then
		entity.Velocity = Vector.Zero

		if entity:GetSprite():IsEventTriggered("Jump") then
			mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL, 0.9)
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hushGaperUpdate, EntityType.ENTITY_HUSH_GAPER)