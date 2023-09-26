local mod = ReworkedFoes

local Settings = {
	NewHealth = 220,
	BlackHealth = 352,

	MoveSpeed = {4.5, 3.5, 5.5, 4.5,},
	Cooldown = 60,

	-- Summon limits
	MaxSpawns = {11, 5, 3, 4},
	MaxClosestFlies = 5,
	MaxPooters = 4,
	MaxSpiders = 2,

	EffectColors = {
		Color(0.1,0.1,0.1, 0.25),
		Color(0,0,0, 0.25),
		Color(0.1,0.1,0.1, 0.25, 0.15,0,0),
		Color(0.1,0.1,0.1, 0.35, 0.15,0,0.15),
	},

	-- Orbitals
	OrbitDistances = {25, 65, 105},
	OrbitSpeed = 2.25,
	PushSpeed = 16,
}



function mod:HuskInit(entity)
	if entity.Variant == 1 then
		local newHP = Settings.NewHealth
		if entity.SubType == 1 then
			newHP = Settings.BlackHealth
		end

		entity.MaxHitPoints = newHP
		entity.HitPoints = entity.MaxHitPoints
		entity.ProjectileCooldown = Settings.Cooldown / 3
		entity.Mass = 40

		entity:GetData().orbitals = {{}, {}, {}}
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.HuskInit, EntityType.ENTITY_DUKE)

function mod:HuskUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()

		-- Move diagonally
		mod:MoveDiagonally(entity, Settings.MoveSpeed[entity.SubType + 1])


		-- Update the list of orbitals
		for i = 1, 3 do
			for j = 1, #data.orbitals[i] do
				if data.orbitals[i][j] then
					local fly = data.orbitals[i][j]

					-- Remove them from the list
					if not fly:Exists() or fly:IsDead() or not fly:GetData().huskOrbitalGroup then
						table.remove(data.orbitals[i], j)

					-- Put them in the correct list
					else
						local flyData = fly:GetData()
						if flyData.huskOrbitalGroup and flyData.huskOrbitalGroup ~= i then
							table.insert(data.orbitals[flyData.huskOrbitalGroup], fly)
							table.remove(data.orbitals[i], j)
						end
					end
				end
			end
		end


		-- Check for the amount of spawned enemies in the room
		local enemyScore = Isaac.CountEntities(entity, EntityType.ENTITY_ATTACKFLY, -1, -1) + Isaac.CountEntities(entity, EntityType.ENTITY_POOTER, -1, -1)
		-- Black champion
		if entity.SubType == 1 then
			enemyScore = Isaac.CountEntities(entity, EntityType.ENTITY_BOOMFLY, -1, -1) + Isaac.CountEntities(entity, EntityType.ENTITY_TICKING_SPIDER, -1, -1)
		-- Pink champion
		elseif entity.SubType == 2 then
			enemyScore = Isaac.CountEntities(entity, EntityType.ENTITY_SUCKER, -1, -1)
		-- Wine champion
		elseif entity.SubType == 3 and FiendFolio then
			enemyScore = Isaac.CountEntities(entity, FiendFolio.FF.Grape.ID, FiendFolio.FF.Grape.Var, FiendFolio.FF.Grape.Sub)
			+ Isaac.CountEntities(entity, FiendFolio.FF.Bunch.ID, FiendFolio.FF.Bunch.Var, 0) * 3
		end



		-- Idle
		if entity.State == NpcState.STATE_MOVE then
			mod:LoopingAnim(sprite, "Walk")

			-- Choose attack
			if entity.ProjectileCooldown <= 0 then
				if entity.SubType == 2 then
					entity.ProjectileCooldown = Settings.Cooldown / 2
				else
					entity.ProjectileCooldown = Settings.Cooldown
				end

				-- Decide attack
				local attack = 1

				-- Only do other attacks if there are at least 2 flies alive
				if (entity.SubType == 1 and enemyScore > 0) or enemyScore > 1 or entity.SubType >= 2 then
					local lowest = 1

					-- Don't spawn more flies if there are too many in the room or in the closest orbit
					local maxFlies = Settings.MaxSpawns[entity.SubType + 1]
					if enemyScore >= maxFlies or #data.orbitals[1] >= Settings.MaxClosestFlies then
						lowest = 2
					end

					attack = mod:Random(lowest, 3)

					-- Pink champion doesn't do volley attack
					if entity.SubType == 2 and (attack == 2 or enemyScore >= maxFlies) then
						attack = 3
					end
				end


				-- Summon
				if attack == 1 then
					entity.State = NpcState.STATE_SUMMON
				-- Shoot
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK
				-- Push away
				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK2
				end

				sprite:Play("Attack0" .. tostring(attack), true)

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		-- Summon
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetFrame() == 18 then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_2)

				-- Black champion
				if entity.SubType == 1 then
					Isaac.Spawn(EntityType.ENTITY_BOOMFLY, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)


				-- Pink champion
				elseif entity.SubType == 2 then
					local params = ProjectileParams()
					params.Variant = mod.Entities.SuckerProjectile
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(12), 0, params)


				-- Wine champion
				elseif entity.SubType == 3 and FiendFolio then
					for i = 1, mod:Random(1, 2) do
						local grape = Isaac.Spawn(FiendFolio.FF.Grape.ID, FiendFolio.FF.Grape.Var, FiendFolio.FF.Grape.Sub, entity.Position + Vector(0, 10), Vector.Zero, entity)
						grape:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						grape.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
						grape:Update()
					end


				-- Default
				else
					for i = 1, 3 do
						local spawnType = EntityType.ENTITY_POOTER
						if Isaac.CountEntities(entity, EntityType.ENTITY_POOTER, -1, -1) >= Settings.MaxPooters then
							spawnType = EntityType.ENTITY_ATTACKFLY
						end

						local fly = Isaac.Spawn(spawnType, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity):ToNPC()
						fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						fly.Parent = entity
						fly:GetData().huskOrbitalGroup = 1
						table.insert(data.orbitals[1], fly)

						if fly.SpawnerType == EntityType.ENTITY_ATTACKFLY then
							fly:GetData().huskSpawn = true
						end
					end
				end


				-- Effects
				for i = -1, 1, 2 do
					-- Yes haha it unlocked the Forgorten for Oily before, how smart of you
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.HuskEffect, 0, entity.Position, Vector.Zero, entity):ToEffect()
					effect:FollowParent(entity)
					effect.DepthOffset = entity.DepthOffset + 10

					local effectSprite = effect:GetSprite()
					effectSprite:Load("gfx/1000.001_bomb explosion.anm2", true)
					effectSprite:Play("Explosion", true)

					effectSprite.Rotation = i * 90
					effectSprite.Scale = Vector(entity.Scale * 0.9, entity.Scale * 0.9)
					effectSprite.Offset = Vector(0, entity.Scale * -28)
					effectSprite.Color = Settings.EffectColors[entity.SubType + 1]

					effect:Update()
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		-- Shoot + Spider
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:GetFrame() == 18 then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_1)

				-- Wine champion (Copy / Pasted from Fiend Folio so I have no idea how it works)
				if entity.SubType == 3 and FiendFolio then
					for i = -1, 3 do
						local vec = (target.Position - entity.Position):Resized(6)

						local proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, entity.Position, vec, entity):ToProjectile()
						proj.Color = FiendFolio.ColorKickDrumsAndRedWine
						proj.FallingSpeed = 0
						proj.FallingAccel = -0.1

						local projD = proj:GetData()
						projD.projType = "wineHuskFunny"
						projD.startpos = entity.Position
						projD.targvel = vec
						projD.Timer = i * 2

						proj:Update()
					end


				-- Regular
				else
					entity:FireBossProjectiles(12, target.Position, 1, ProjectileParams())

					-- Get the entity to check for
					local typeToCheck = EntityType.ENTITY_SPIDER
					if entity.SubType == 1 then
						typeToCheck = EntityType.ENTITY_TICKING_SPIDER
					end

					-- Only spawn spiders if there are less than 2
					if Isaac.CountEntities(entity, typeToCheck, -1, -1) < Settings.MaxSpiders and enemyScore < Settings.MaxSpawns[entity.SubType + 1] then
						local distance = mod:Random(100, 160)

						-- Ticking Spider
						if entity.SubType == 1 then
							local spider = Isaac.Spawn(EntityType.ENTITY_TICKING_SPIDER, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
							spider.State = NpcState.STATE_JUMP
							spider.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(distance)
							spider:GetSprite():Play("Jump")
							spider:GetSprite():SetFrame(7)

						-- Spider
						else
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (target.Position - entity.Position):Resized(distance), false, -10)
						end
					end
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		-- Push away
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:GetFrame() == 18 then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)

				-- Black champion
				if entity.SubType == 1 then
					-- Push away Boom Flies
					local pushed = false
					for i, fly in pairs(Isaac.FindInRadius(entity.Position, 130, EntityPartition.ENEMY)) do
						if fly.Type == EntityType.ENTITY_BOOMFLY then
							fly:ToNPC().State = NpcState.STATE_SPECIAL
							fly:ToNPC().V2 = (fly.Position - entity.Position):Resized(Settings.PushSpeed)
							pushed = true
						end
					end

					-- Shoot if it didn't push away any
					if pushed == false then
						entity:FireProjectiles(entity.Position, Vector(11, 8), 8, ProjectileParams())
					end


				-- Pink champion
				elseif entity.SubType == 2 then
					entity:FireProjectiles(entity.Position, Vector(11.5, 8), 9, ProjectileParams())
					entity.I1 = entity.I1 + 1


				-- Wine champion
				elseif entity.SubType == 3 and FiendFolio then
					entity.I1 = 1
					entity.TargetPosition = mod:RandomVector()


				-- Regular
				elseif enemyScore < Settings.MaxSpawns[1] then
					-- Increase orbit for flies
					for i = 1, 3 do
						for j = 1, #data.orbitals[i] do
							local fly = data.orbitals[i][j]
							local flyData = fly:GetData()

							-- Only affect 4 of them
							if j <= 4 then
								-- Remove them from orbit
								if i == 3 then
									flyData.huskOrbitalGroup = nil
									fly.Velocity = (fly.Position - entity.Position):Resized(Settings.PushSpeed)
									fly.Parent = nil
									fly.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

								-- Push them further
								else
									flyData.huskOrbitalGroup = flyData.huskOrbitalGroup + 1
								end

							else
								break
							end
						end
					end

					-- Spawn Attack Flies
					for i = 1, 3 do
						local fly = Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
						fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						fly.Parent = entity
						fly:GetData().huskOrbitalGroup = 1
						fly:GetData().huskSpawn = true
						table.insert(data.orbitals[1], fly)
					end
				end


			-- Pink champion attacks twice
			elseif sprite:GetFrame() == 26 and entity.SubType == 2 then
				if entity.I1 > 1 then
					entity.I1 = 0
				else
					sprite:SetFrame(6)
				end
			end


			-- Wine champion shots
			if entity.SubType == 3 and FiendFolio and entity.I1 == 1 and entity:IsFrame(2, 0) then
				-- Stop shooting
				if entity.I2 > 3 then
					entity.I1 = 0
					entity.I2 = 0

				-- Shoot
				else
					local params = ProjectileParams()
					params.Scale = 1 + entity.I2 * 0.3
					params.Color = FiendFolio.ColorKickDrumsAndRedWine

					for i = 0, 2 do
						local vector = entity.TargetPosition:Rotated(i * 120 + entity.I2 * 15)
						entity:FireProjectiles(entity.Position, vector:Resized(10), 0, params)

						-- Effects
						if entity.I2 % 2 == 0 then
							mod:ShootEffect(entity, 2, Vector(0, -36) + vector:Resized(20), Color(0,0,0, 1, 0.4,0,0.4), 1, true)
						end
					end

					entity.I2 = entity.I2 + 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end


		-- Delirium fix
		elseif entity.State == NpcState.STATE_INIT and data.wasDelirium then
			entity.State = NpcState.STATE_MOVE
			entity.Velocity = Vector.FromAngle(45 + mod:Random(3) * 90)
		end


		if entity.FrameCount > 1 and not entity:HasMortalDamage() then
			return true

		-- Black champion explodes on death
		elseif entity:IsDead() and entity.SubType == 1 then
			Game():BombExplosionEffects(entity.Position, 80, TearFlags.TEAR_NORMAL, Color.Default, entity, 1.25, true, true, DamageFlag.DAMAGE_EXPLOSION)
			mod:PlaySound(nil, SoundEffect.SOUND_BOSS1_EXPLOSIONS, 1, 0.9)

		-- Wine champion shoots on death
		elseif entity.SubType == 3 and FiendFolio and entity:HasMortalDamage() then
			local params = ProjectileParams()
			params.Scale = 2
			params.Color = FiendFolio.ColorKickDrumsAndRedWine
			entity:FireProjectiles(entity.Position, Vector(8, 6), 9, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.HuskUpdate, EntityType.ENTITY_DUKE)

function mod:HuskCollision(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_DUKE then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.HuskCollision, EntityType.ENTITY_DUKE)

function mod:HuskDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Only take 10 damage from Boom Fly and Ticking Spider explosions
	if entity.Variant == 1 and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) and damageSource.SpawnerType == EntityType.ENTITY_DUKE and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		entity:TakeDamage(math.min(damageAmount, 10), damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.HuskDMG, EntityType.ENTITY_DUKE)



--[[ Spawn effect ]]--
function mod:HuskEffectUpdate(effect)
	if effect:GetSprite():IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.HuskEffectUpdate, mod.Entities.HuskEffect)



--[[ Orbiting flies ]]--
function mod:HuskOrbitingFlyUpdate(entity)
	if entity.Parent and entity:GetData().huskOrbitalGroup then
		if entity.Parent:IsDead() then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			entity:GetData().huskOrbitalGroup = nil

		else
			local group = entity:GetData().huskOrbitalGroup
			mod:OrbitParent(entity, entity.Parent, Settings.OrbitSpeed, Settings.OrbitDistances[group], group)

			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HuskOrbitingFlyUpdate, EntityType.ENTITY_ATTACKFLY)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.HuskOrbitingFlyUpdate, EntityType.ENTITY_POOTER)

function mod:HuskObitingFlyCollision(entity, target, bool)
	if entity:GetData().huskSpawn == true and target.Type == EntityType.ENTITY_PLAYER then
		entity:Kill()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.HuskObitingFlyCollision, EntityType.ENTITY_ATTACKFLY)
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.HuskObitingFlyCollision, EntityType.ENTITY_POOTER)