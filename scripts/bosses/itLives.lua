local mod = BetterMonsters

local Settings = {
	-- Fetus
	FetusCooldown = 70,


	-- Guts
	GutsCooldown = 60,
}

IRFitLivesSpawns = {
	Fetus = {
		EntityType.ENTITY_DUKE, 	-- <60%
		EntityType.ENTITY_GURDY_JR, -- <40%
		EntityType.ENTITY_CHUB, 	-- <20%
	},

	Guts = {
		EntityType.ENTITY_WALKINGBOIL, -- >80%
		EntityType.ENTITY_GLOBIN, 	   -- <80%
		EntityType.ENTITY_PARA_BITE,   -- <60%
		EntityType.ENTITY_LEECH, 	   -- <40%
		EntityType.ENTITY_BABY, 	   -- <20%
	},
}



function mod:itLivesInit(entity)
	-- Fetus
	if entity.Variant == 1 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = Settings.FetusCooldown
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS


	-- Guts
	elseif entity.Variant == 10 then
		-- Get the parent's variant
		entity.SubType = entity.SpawnerVariant

		if entity.SubType == 1 then
			entity.ProjectileCooldown = Settings.GutsCooldown
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.itLivesInit, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesUpdate(entity)
	if entity.Variant == 1 or (entity.Variant == 10 and entity.SubType == 1) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()

		entity.Velocity = Vector.Zero
		
		--local spawnedEnemyCount = entity:QueryNPCsSpawnerType(EntityType.ENTITY_MOMS_HEART, 0, true).Size - 1 -- Doesn't count enemies spawned by Chub for example
		--print(spawnedEnemyCount)
		local spawnedEnemyCount = entity:GetAliveEnemyCount() - 2 -- Might not work in Delirium fight?
		--print(spawnedEnemyCount)


		--[[ Fetus ]]--
		if entity.Variant == 1 then
			local percentHP = entity.HitPoints / (entity.MaxHitPoints / 100)

			-- Idle
			if entity.State == NpcState.STATE_IDLE then
				-- Homunculi
				if not data.homunculiSpawned then
					for i = -1, 1, 2 do
						local position = Vector(entity.Position.X + i * 160, room:GetTopLeftPos().Y + 80)
						Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
					end

					data.homunculiSpawned = true
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					entity.ProjectileCooldown = Settings.FetusCooldown / 2
				end


				mod:LoopingAnim(sprite, "Idle")

				if entity.ProjectileCooldown <= 0 then
					local maxAttack = 2
					if percentHP <= 60 then
						maxAttack = 3
					end
					local attack = mod:Random(maxAttack)

					if attack == 0 then
						--entity.State = NpcState.STATE_JUMP
						--sprite:Play("HeartRetracted", true)
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("HeartSummon", true)
					elseif attack == 1 then
						entity.State = NpcState.STATE_ATTACK2
						--sprite:Play("HeartSummon", true)
						entity.I1 = 0
						entity.ProjectileDelay = 0
						mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
					
					elseif attack == 2 then
						entity.State = NpcState.STATE_ATTACK3
						entity.I1 = 0
					
					elseif attack == 3 then
						entity.State = NpcState.STATE_SUMMON
						sprite:Play("HeartSummon", true)
					end

					entity.ProjectileCooldown = Settings.FetusCooldown

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Hide
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				end

			-- Come down
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				end


			-- Retracted
			elseif entity.State == NpcState.STATE_MOVE then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")
				
				if sprite:IsEventTriggered("Heartbeat") then
					local pos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 20)

					--[[
					local params = ProjectileParams()
					params.Scale = 1.5
					params.BulletFlags = ProjectileFlags.HIT_ENEMIES
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.15
					
					entity:FireProjectiles(pos, (target.Position - pos):Resized(6), 0, params)
					]]--
					
					local params = ProjectileParams()
					params.Scale = 1.5
					params.BulletFlags = ProjectileFlags.HIT_ENEMIES
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.15
					params.CircleAngle = 0 + entity.I1 * 0.3
					entity:FireProjectiles(pos, Vector(6, 4), 9, params)
					entity.I1 = entity.I1 + 1
				end

				if entity.ProjectileCooldown <= 0 then
					--entity.State = NpcState.STATE_STOMP
					--sprite:Play("HeartComedown", true)
					--entity.ProjectileCooldown = Settings.FetusCooldown
				else
					--entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
				if spawnedEnemyCount <= 0 then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("HeartComedown", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
				end


			-- Burst shot
			elseif entity.State == NpcState.STATE_ATTACK then
				if sprite:IsEventTriggered("Heartbeat") then
					local params = ProjectileParams()
					params.BulletFlags = (ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP | ProjectileFlags.BURST8)
					params.Scale = 2.75
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(12), 0, params)
					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			
			
			-- Lines of shots
			elseif entity.State == NpcState.STATE_ATTACK2 then
				mod:LoopingAnim(sprite, "Heartbeat2")

				--if entity.ProjectileDelay <= 0 then
				if sprite:IsEventTriggered("Heartbeat") then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.BulletFlags = ProjectileFlags.HIT_ENEMIES
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.15

					for i = 0, 1 do
						params.CircleAngle = 0 + (i * 0.8) + (mod:GetSign(i) * entity.I1 * 0.3)
						entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
					end
					entity.I1 = entity.I1 + 1
					--entity.ProjectileDelay = 9
					mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

				--else
					--entity.ProjectileDelay = entity.ProjectileDelay - 1
				end

				if entity.I1 >= 9 then
					entity.State = NpcState.STATE_IDLE
				end
			
			
			-- Explosive shots
			elseif entity.State == NpcState.STATE_ATTACK3 then
				mod:LoopingAnim(sprite, "Heartbeat3")

				--if entity.ProjectileDelay <= 0 then
				if sprite:IsEventTriggered("Heartbeat") then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.BulletFlags = ProjectileFlags.HIT_ENEMIES
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.15
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(6), 0, params)
					
					entity.I1 = entity.I1 + 1

				--else
					--entity.ProjectileDelay = entity.ProjectileDelay - 1
				end

				if entity.I1 >= 11 then
					entity.State = NpcState.STATE_IDLE
				end
			
			
			-- Summon a boss
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Heartbeat") then
					local tableIndex = math.ceil(3 - percentHP / 20)
					local amount = 1
					if tableIndex == 3 then
						amount = 3
					end

					for i = 1, amount do
						local boss = Isaac.Spawn(IRFitLivesSpawns.Fetus[tableIndex], 0, 0, entity.Position + Vector(0, 20), Vector.Zero, entity)
						boss.MaxHitPoints = boss.MaxHitPoints / 2
						boss.HitPoints = boss.MaxHitPoints
					end
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
				end
			end





		--[[ Guts ]]--
		elseif entity.Variant == 10 then
			-- Die without a parent
			if not entity.Parent or entity.Parent:IsDead() then
				--entity.State = NpcState.STATE_DEATH
				--sprite:Play("Death", true)
				entity:Kill()

			else
				entity.Parent.Child = entity
				local fetus = entity.Parent:ToNPC()
				local fetusHP = entity.Parent.HitPoints / (entity.Parent.MaxHitPoints / 100) -- In percent (for some reason trying to use the fetus variable here just doesn't work?)

				-- Shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 15)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(120, 0)
				end


				-- Idle
				if entity.State == NpcState.STATE_IDLE then
					mod:LoopingAnim(sprite, "Heartbeat1")

					if entity.ProjectileCooldown <= 0 then
						local attack = mod:Random(1)
						if attack == 1 and (spawnedEnemyCount >= 2 or fetus.State == 4) then
							attack = 0
						end

						-- Shoot
						if attack == 0 then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("HeartSummon", true)
							
							local maxSF = 2
							if fetusHP <= 40 and fetus.State ~= 4 then
								maxSF = 3
							end
							entity.StateFrame = mod:Random(maxSF)

						-- Summon
						elseif attack == 1 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("HeartSummon", true)
						end

						entity.ProjectileCooldown = Settings.GutsCooldown

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end


				-- Attack
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:GetFrame() == 5 then
						local params = ProjectileParams()
						params.Scale = 1.5
						params.BulletFlags = ProjectileFlags.HIT_ENEMIES
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.15
						
						mod:PlaySound(nil, SoundEffect.SOUND_MEATHEADSHOOT)

						-- Quad shots at the player
						if entity.StateFrame == 0 then
							for i = -1, 1, 2 do
								local pos = getShootPos(i)
								fetus:FireProjectiles(pos, (target.Position - pos):Resized(7), 4, params)
							end

						-- 2 rings of shots
						elseif entity.StateFrame == 1 then
							for i = -1, 1, 2 do
								for j = 0, 5 do
									fetus:FireProjectiles(getShootPos(i), Vector.FromAngle(15 + j * 30):Resized(5.5), 0, params)
								end
							end

						-- Spread of 5 shots at the player
						elseif entity.StateFrame == 2 then
							local pos = getShootPos(mod:Random(1))
							fetus:FireProjectiles(pos, (target.Position - pos):Resized(7), 5, params)
						
						
						-- Brimstone
						elseif entity.StateFrame == 3 then
							for i = -1, 1, 2 do
								local angle = 90 - i * 8
								local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, getShootPos(i) - Vector(0, 15), angle, 25, Vector.Zero, entity), entity}
								laser_ent_pair.laser:SetActiveRotation(0, i * 16, i, -1)
							end
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end


				-- Summon
				elseif entity.State == NpcState.STATE_SUMMON then
					if sprite:GetFrame() == 5 then
						for i = -1, 1, 2 do
							local tableIndex = math.ceil(5 - fetusHP / 20)
							Isaac.Spawn(IRFitLivesSpawns.Guts[tableIndex], 0, 0, getShootPos(i), Vector.Zero, fetus)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end
			end
		end


		if entity.FrameCount > 1 and (entity.Variant == 10 or not entity:HasMortalDamage()) then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.itLivesUpdate, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 and damageSource.SpawnerType == target.Type then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.itLivesDMG, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesCollide(entity, target, bool)
	if entity.Variant == 1 and target.SpawnerType == entity.Type or (target.SpawnerEntity and target.SpawnerEntity.SpawnerType == entity.Type) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.itLivesCollide, EntityType.ENTITY_MOMS_HEART)

-- Burst projectile fix
function mod:itLivesProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MOMS_HEART and projectile.SpawnerVariant == 1
	and projectile:HasProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP) and not projectile:HasProjectileFlags(ProjectileFlags.BURST8) then
		projectile:ClearProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.itLivesProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)