local mod = BetterMonsters

local Settings = {
	-- Fetus
	FetusCooldown = 45,

	-- Guts
	GutsCooldown = 30,
}

IRFitLivesBosses = {
	{ -- 100% - 75%
		EntityType.ENTITY_OOB,
		EntityType.ENTITY_MONSTRO,
		EntityType.ENTITY_GEMINI,
	},
	{ -- 75% - 50%
		EntityType.ENTITY_COHORT,
		EntityType.ENTITY_FISTULA_BIG,
		EntityType.ENTITY_GURDY_JR,
	},
	{ -- 50% - 25%
		EntityType.ENTITY_ADULT_LEECH,
		EntityType.ENTITY_CHUB,
		EntityType.ENTITY_POLYCEPHALUS,
	},
}

IRFitLivesEnemies = {
	{ -- 100% - 75%
		EntityType.ENTITY_PARA_BITE,
		EntityType.ENTITY_WALKINGBOIL,
		EntityType.ENTITY_HOMUNCULUS,
	},
	{ -- 75% - 50%
		EntityType.ENTITY_SWINGER,
		EntityType.ENTITY_FISTULOID,
		EntityType.ENTITY_FACELESS,
	},
	{ -- 50% - 25%
		EntityType.ENTITY_LEECH,
		EntityType.ENTITY_TUMOR,
		EntityType.ENTITY_FLESH_MOBILE_HOST,
	},
}



function mod:itLivesInit(entity)
	-- Fetus
	if entity.Variant == 1 then
		local data = entity:GetData()

		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.TargetPosition = entity.Position

		data.phase = 1
		data.attackCounter = 1
		data.spawnCounter = 1

		data.rotation = 1
		data.rotationDelay = 6

		mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.LoomingShadow, 0, Vector.Zero, Vector.Zero, entity).Parent = entity


	-- Guts
	elseif entity.Variant == 10 then
		-- Get the parent's variant
		entity.SubType = entity.SpawnerVariant

		-- It Lives' guts
		if entity.SubType == 1 then
			--entity:GetSprite():Load("gfx/078.010_it lives guts.anm2", true)
			entity.ProjectileCooldown = Settings.GutsCooldown

			if entity.SpawnerEntity then
				entity.SpawnerEntity.Child = entity
			end
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

		local spawnedEnemyCount = entity:GetAliveEnemyCount() - 2

		local baseProjectileParams = ProjectileParams()
		baseProjectileParams.Scale = 1.5
		baseProjectileParams.BulletFlags = ProjectileFlags.HIT_ENEMIES
		baseProjectileParams.FallingSpeedModifier = 1
		baseProjectileParams.FallingAccelModifier = -0.13


		--[[ Fetus ]]--
		if entity.Variant == 1 then
			--[[ Functions ]]--
			--



			--[[ Always active ]]--
			local guts = nil
			if entity.Child then
				guts = entity.Child:ToNPC()
			end

			-- Always stay in the spawn position
			entity.Velocity = Vector.Zero
			entity.Position = entity.TargetPosition

			if entity:HasEntityFlags(EntityFlag.FLAG_KNOCKED_BACK) then
				entity:ClearEntityFlags(EntityFlag.FLAG_KNOCKED_BACK)
			end


			-- Transition to next phase
			local quarterHp = (entity.MaxHitPoints / 4)

			if entity.HitPoints <= entity.MaxHitPoints - (quarterHp * data.phase) then
				data.phase = data.phase + 1
				data.spawnCounter = 1

				-- Enrage
				if data.phase == 4 then
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("HeartSummon", true)
					mod:PlaySound(entity, SoundEffect.SOUND_MULTI_SCREAM)
					entity:SetColor(Color(1,1,1, 1, 0.5,0,0), -1, 1, false, true)
					Game():MakeShockwave(entity.Position, 0.02, 0.025, 15)

					-- Summon spikes to kill all enemies
					for i, enemy in pairs(Isaac.GetRoomEntities()) do
						if enemy:ToNPC() and enemy.Type ~= EntityType.ENTITY_MOMS_HEART then
							Isaac.Spawn(IRFentities.Type, IRFentities.GiantSpike, 0, enemy.Position, Vector.Zero, entity).Target = enemy
						end
					end
				end
			end


			-- Make other enemies not go near him
			local startPos = entity.Position
			if entity.State == NpcState.STATE_MOVE then
				startPos = Vector(entity.Position.X, room:GetTopLeftPos().Y + 60)
			end

			for i = -1, 1 do
				for j = -1, 1 do
					local gridPos = startPos + Vector(i * 40, j * 40)
					local grid = room:GetGridIndex(gridPos)
					room:SetGridPath(grid, 900)
				end
			end


			-- Sway left and right
			if (data.rotation == 1 and sprite.Rotation < 1) or (data.rotation == -1 and sprite.Rotation > -1) then
				sprite.Rotation = sprite.Rotation + data.rotation * 0.04
				sprite.Offset = Vector(sprite.Rotation * -3, 0)
			else
				if data.rotationDelay <= 0 then
					data.rotation = data.rotation * -1
					data.rotationDelay = 6
				else
					data.rotationDelay = data.rotationDelay - 1
				end
			end



			--[[ Idle ]]--
			if entity.State == NpcState.STATE_IDLE then
				-- Homunculi
				if not data.homunculiSpawned and not data.wasDelirium then
					for i = -1, 1, 2 do
						local position = Vector(entity.Position.X + i * 160, room:GetTopLeftPos().Y + 80)
						Isaac.Spawn(EntityType.ENTITY_HOMUNCULUS, 0, 0, room:FindFreePickupSpawnPosition(position, 0, true, true), Vector.Zero, entity)
					end
					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

					data.homunculiSpawned = true
					entity.ProjectileCooldown = Settings.FetusCooldown
				end


				mod:LoopingAnim(sprite, "Idle")

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = Settings.FetusCooldown
					entity.I1 = 0
					entity.I2 = 0
					entity.StateFrame = 0
					entity.ProjectileDelay = 0


					-- Choose an attack, don't repeat it this cycle
					local function chooseAttack()
						local attacks = {1, 2, 3, 4}
						if data.lastAttack then
							table.remove(attacks, data.lastAttack)
						end

						local attack = mod:RandomIndex(attacks)
						data.lastAttack = attack

						if attack == 1 then
							entity.State = NpcState.STATE_ATTACK

						elseif attack == 2 then
							entity.State = NpcState.STATE_ATTACK

						elseif attack == 3 then
							entity.State = NpcState.STATE_ATTACK

						elseif attack == 4 then
							entity.State = NpcState.STATE_ATTACK
						end
						sprite:Play("HeartSummon", true)
					end


					-- Enraged
					if data.phase == 4 then
						-- Attack
						if data.attackCounter == 1 then
							chooseAttack()

						-- Attack
						elseif data.attackCounter == 2 then
							chooseAttack()

						-- Retract
						elseif data.attackCounter == 3 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play("HeartRetracted", true)
						end

					-- Not enraged
					else
						-- Attack
						if data.attackCounter == 1 then
							chooseAttack()

						-- Summon enemies
						elseif data.attackCounter == 2 then
							guts.State = NpcState.STATE_SUMMON
							guts:GetSprite():Play("HeartSummon", true)

						-- Attack
						elseif data.attackCounter == 3 then
							chooseAttack()

						-- Summon harder enemies / retract
						elseif data.attackCounter == 4 then
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("HeartSummon", true)
						end
					end


					-- Perform attacks in the same order
					if data.attackCounter >= 4 then
						data.attackCounter = 1
						data.lastAttack = nil
					else
						data.attackCounter = data.attackCounter + 1
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end



			--[[ Attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				if data.attackCounter == 2 then
					mod:LoopingAnim(sprite, "Heartbeat3")

					if entity.ProjectileDelay <= 0 then
						for i = 0, 1 do
							local params = baseProjectileParams
							params.CircleAngle = 0 + (i * 0.8) + (mod:GetSign(i) * entity.I1 * 0.3)
							entity:FireProjectiles(entity.Position, Vector(6, 4), 9, params)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1
						entity.ProjectileDelay = 4

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

					if entity.I1 >= 9 then
						entity.State = NpcState.STATE_IDLE
					end

				elseif data.attackCounter == 4 then
					if sprite:IsEventTriggered("Heartbeat") then
						for i = 0, 3 do
							local angle = 45 + i * 90
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 2, entity.Position + Vector.FromAngle(angle):Resized(20), Vector.Zero, entity):ToEffect().Rotation = angle
						end

						for i = 1, 3 do
							local pos = target.Position
							if i == 2 then
								pos = entity.Position + mod:RandomVector(mod:Random(80, 160))
							elseif i == 1 then
								pos = target.Position + mod:RandomVector(mod:Random(40, 120))
							end
							pos = room:GetClampedPosition(pos, -10)

							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, pos, Vector.Zero, entity):ToEffect().Timeout = 30

							local params = ProjectileParams()
							params.HeightModifier = -500
							params.FallingAccelModifier = 2.5
							params.BulletFlags = ProjectileFlags.EXPLODE
							params.Scale = 1.75
							mod:FireProjectiles(entity, pos, Vector.Zero, 0, params, Color.Default)
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end
				end



			--[[ Summon ]]--
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Heartbeat") then
					local spawnGroup = IRFitLivesBosses[data.phase]
					local spawnType = spawnGroup[data.spawnCounter]

					-- For Chub
					if spawnType == EntityType.ENTITY_CHUB then
						for i = -1, 1 do
							Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(i * 30, 30), Vector.Zero, entity)
						end
					else
						Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(0, 30), Vector.Zero, entity)
					end

					-- Always follow the same order
					if data.spawnCounter >= 3 then
						data.spawnCounter = 1
					else
						data.spawnCounter = data.spawnCounter + 1
					end

					mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_EVILLAUGH)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("HeartRetracted", true)
					mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
				end



			--[[ Retract ]]--
			elseif entity.State == NpcState.STATE_JUMP then
				if sprite:IsFinished() then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.State = NpcState.STATE_SUMMON2
				end
			
			-- Retracted
			elseif entity.State == NpcState.STATE_SUMMON2 then
				mod:LoopingAnim(sprite, "HeartHidingHeartbeat")

				-- Come down if all enemies are dead
				if spawnedEnemyCount <= 0 then
					-- Delay before coming down
					if entity.StateFrame <= 0 then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("HeartComedown", true)

						mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
						Game():ShakeScreen(6)
						mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_FILTERED_ISAAC)

						guts.State = NpcState.STATE_IDLE
						guts.ProjectileCooldown = Settings.GutsCooldown

					else
						entity.StateFrame = entity.StateFrame - 1
					end

				else
					entity.StateFrame = 20
				end

			-- Come down
			elseif entity.State == NpcState.STATE_STOMP then
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				end



			--[[ Enrage ]]--
			elseif entity.State == NpcState.STATE_SPECIAL then
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
				entity.State = NpcState.STATE_DEATH
				sprite:Play("Death", true)
				--entity:Kill()


			else
				--[[ Functions ]]--
				-- Get shoot positions
				local function getShootPos(side)
					local position = Vector(entity.Position.X, room:GetTopLeftPos().Y + 15)
					local sign = mod:GetSign(side > 0)
					return position + sign * Vector(120, 0)
				end



				--[[ Always active ]]--
				local fetus = entity.Parent:ToNPC()

				-- Make enemies not go near the holes
				for side = -1, 1, 2 do
					for i = -1, 1 do
						for j = 0, 1 do
							local startPos = getShootPos(side)
							local gridPos = startPos + Vector(i * 40, j * 40)
							local grid = room:GetGridIndex(gridPos)
							room:SetGridPath(grid, 900)
						end
					end
				end



				--[[ Idle ]]--
				if entity.State == NpcState.STATE_IDLE then
					mod:LoopingAnim(sprite, "Heartbeat1")

					if fetus.State == NpcState.STATE_SUMMON2 then
						if entity.ProjectileCooldown <= 0 then
							entity.ProjectileCooldown = Settings.GutsCooldown
							entity.I1 = 0
							entity.I2 = 0
							entity.StateFrame = 0
							entity.ProjectileDelay = 0

							local attack = mod:Random(1, 5)
							attack = 5

							if attack == 1 then
								entity.State = NpcState.STATE_ATTACK

							elseif attack == 2 then
								entity.State = NpcState.STATE_ATTACK2

							elseif attack == 3 then
								entity.State = NpcState.STATE_ATTACK3

							elseif attack == 4 then
								entity.State = NpcState.STATE_ATTACK4

							elseif attack == 5 then
								entity.State = NpcState.STATE_ATTACK5
							end
							sprite:Play("HeartSummon", true)

						else
							entity.ProjectileCooldown = entity.ProjectileCooldown - 1
						end
					end



				--[[ Summon ]]--
				elseif entity.State == NpcState.STATE_SUMMON then
					if sprite:GetFrame() == 5 then
						local spawnGroup = IRFitLivesEnemies[fetus:GetData().phase]
						local spawnType = mod:RandomIndex(spawnGroup)

						for i = -1, 1, 2 do
							Isaac.Spawn(spawnType, 0, 0, getShootPos(i), Vector.Zero, fetus)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:GetFrame() == 5 then
						if entity.I1 < 5 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end

						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							fetus:FireProjectiles(pos, (target.Position - pos):Resized(6), 0, baseProjectileParams)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK2 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							params.CircleAngle = 0 + i * entity.I1 * 0.3
							fetus:FireProjectiles(pos, Vector(4, 4), 9, params)
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1

					elseif sprite:GetFrame() == 10 then
						if entity.I1 < 10 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						params.BulletFlags = params.BulletFlags + ProjectileFlags.SINE_VELOCITY

						for i = -1, 1, 2 do
							for j = 0, 5 do
								fetus:FireProjectiles(getShootPos(i), Vector.FromAngle(15 + j * 30):Resized(4), 0, params)
							end
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK4 then
					if sprite:GetFrame() == 5 then
						local pos = getShootPos(entity.I1)
						fetus:FireProjectiles(pos, (target.Position - pos):Resized(5), 5, baseProjectileParams)
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

						entity.I1 = entity.I1 + 1

					elseif sprite:GetFrame() == 20 then
						if entity.I1 < 2 then
							sprite:SetFrame(0)
						else
							entity.I1 = 0
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_IDLE
					end



				--[[ Attack ]]--
				elseif entity.State == NpcState.STATE_ATTACK5 then
					if sprite:GetFrame() == 5 then
						local params = baseProjectileParams
						params.FallingAccelModifier = -0.09
						params.BulletFlags = params.BulletFlags + ProjectileFlags.BOUNCE

						for i = -1, 1, 2 do
							local pos = getShootPos(i)
							for i, projectile in pairs(mod:FireProjectiles(fetus, pos, Vector(4.5, 3), 9, params)) do
								mod:QuickTrail(projectile, 0.09, Color(1,0.25,0.25, 1), projectile.Scale * 1.75)
							end
						end
						mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
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
	if target.Variant == 1 then
		-- Don't take damage from his spawns
		if damageSource.SpawnerType == target.Type then
			return false

		-- Grunt on high damage (like Mom's Heart)
		elseif damageAmount >= 40 then
			mod:PlaySound(target, SoundEffect.SOUND_MOM_VOX_FILTERED_HURT, 1, 1, 40)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.itLivesDMG, EntityType.ENTITY_MOMS_HEART)

function mod:itLivesCollide(entity, target, bool)
	if entity.Variant == 1 and target.SpawnerType == entity.Type or (target.SpawnerEntity and target.SpawnerEntity.SpawnerType == entity.Type) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.itLivesCollide, EntityType.ENTITY_MOMS_HEART)



-- Burst projectiles
function mod:itLivesProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_MOMS_HEART and projectile.SpawnerVariant == 1 then
		local sprite = projectile:GetSprite()
		local data = projectile:GetData()

		-- Burst projectile fix
		if projectile:HasProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP) and not projectile:HasProjectileFlags(ProjectileFlags.BURST8) then
			projectile:ClearProjectileFlags(ProjectileFlags.ACID_RED | ProjectileFlags.RED_CREEP)


		-- Bursting cell
		elseif data.splitTimer then
			if data.splitTimer <= 0 then
				if sprite:IsPlaying("IdleBurst") then
					sprite:Play("Burst", true)

				elseif sprite:IsFinished() then
					projectile:ClearProjectileFlags(ProjectileFlags.WIGGLE)
					projectile:AddProjectileFlags(ProjectileFlags.BURST8)
					projectile:Die()
				end

			else
				data.splitTimer = data.splitTimer - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.itLivesProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)



-- Mom's Looming Shadow
function mod:loomingShadowUpdate(effect)
	local sprite = effect:GetSprite()

	effect.Position = Vector(-26, 52)
	effect.Velocity = Vector.Zero

	mod:LoopingOverlay(sprite, "Guts")
	effect.SortingLayer = SortingLayer.SORTING_DOOR


	-- Heart
	if effect.State == 0 then
		-- Die without a parent or if the parent dies
		if not effect.Parent or effect.Parent:IsDead() then
			effect.State = 1
			sprite:Play("Die", true)

		-- Beating
		else
			local phase = effect.Parent:GetData().phase

			mod:LoopingAnim(sprite, "Heartbeat" .. math.max(1, phase - 1))

			-- Effects
			if sprite:IsEventTriggered("Heartbeat") then
				local sound = SoundEffect.SOUND_HEARTBEAT
				if phase == 3 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTER
				elseif phase == 4 then
					sound = SoundEffect.SOUND_HEARTBEAT_FASTEST
				end

				mod:PlaySound(nil, sound, 0.9)

				local beatPos = Vector(effect.Parent.Position.X, Game():GetRoom():GetTopLeftPos().Y) - Vector(0, 160)
				local beatStrength = 0.012 - math.max(1, phase - 1) * 0.001
				Game():MakeShockwave(beatPos, beatStrength, 0.025, 25)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.loomingShadowUpdate, IRFentities.LoomingShadow)