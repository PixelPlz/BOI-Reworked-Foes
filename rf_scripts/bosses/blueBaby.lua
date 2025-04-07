local mod = ReworkedFoes

local Settings = {
	NewHP = 3000,
	SpawnDmgReduction = 60,
	TransitionDmgReduction = 90,

	PlayerDistance = 120,
	MoveSpeed = 5.5,

	Cooldown = 60,
	TearCooldown = 20,
	FlyDelay = 60,

	PooterCount = 4,
	EternalFlyCount = 2,

	ChainLength = 9,
	BodyMaxDistance = 160,
	SwipeSpeed = 36,
}



function mod:BlueBabyInit(entity)
	if entity.Variant == 1 then
		local data = entity:GetData()

		mod:ChangeMaxHealth(entity, Settings.NewHP)
		entity.I1 = 1

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.ProjectileCooldown = Settings.Cooldown
		data.tearCooldown = Settings.TearCooldown
		data.spawnTimer = Settings.FlyDelay
		data.isSoul = false
		data.damageReduction = Settings.SpawnDmgReduction
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlueBabyInit, EntityType.ENTITY_ISAAC)

function mod:BlueBabyUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		-- Change to soul form
		local function soulGetOut()
			local body = Isaac.Spawn(mod.Entities.Type, mod.Entities.BlueBabyExtras, mod.Entities.ForgottenBody, entity.Position, Vector.Zero, entity)
			body.Parent = entity
			entity.Child = body
			data.isSoul = true

			entity:SetColor(Color(1,1,1, 1, 1,1,1), 10, 1, true, false)
			mod:PlaySound(nil, SoundEffect.SOUND_RECALL)

			data.chain = {}
			for i = 1, Settings.ChainLength do
				data.chain[i] = Isaac.Spawn(mod.Entities.Type, mod.Entities.BlueBabyExtras, mod.Entities.ForgottenChain, entity.Position, Vector.Zero, entity):ToNPC()
				data.chain[i].V1 = Vector(i + 0.5, 0)
				data.chain[i].Child = entity.Child
				data.chain[i].Parent = entity

				-- Delirium sprites
				if data.wasDelirium then
					data.chain[i]:GetSprite():ReplaceSpritesheet(0, "gfx/bosses/afterbirthplus/deliriumforms/classic/boss_078_bluebaby.png")
					data.chain[i]:GetSprite():LoadGraphics()
				end
			end

			-- Update parents
			for _,bone in pairs(Isaac.FindByType(mod.Entities.Type, mod.Entities.BoneOrbital, -1, false, true)) do
				if bone.Parent.Index == entity.Index then
					bone.Parent = entity.Child
				end
			end
			for _,bone in pairs(Isaac.FindByType(EntityType.ENTITY_VIS, 22, -1, false, true)) do
				if bone.Parent.Index == entity.Index then
					bone.Parent = entity.Child
				end
			end

			-- Special sprites for the body
			local bodySprite = body:GetSprite()
			-- Delirium
			if data.wasDelirium then
				for i = 0, body:GetSprite():GetLayerCount() do
					bodySprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/classic/boss_078_bluebaby.png")
				end
				bodySprite:LoadGraphics()

			-- G Fuel
			elseif Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_G_FUEL) then
				bodySprite:Load("gfx/promo/gfuel/forgotten body (gfuel).anm2", true)
				bodySprite:Play("Appear", true)
			end
		end

		-- Change from soul form
		local function soulGetIn()
			local vector = (entity.Child.Position - entity.Position):Resized(7)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 10, entity.Position, vector, entity).SpriteOffset = Vector(0, -10)
			entity:SetColor(Color(1,1,1, 1, 1,1,1), 10, 1, true, false)
			mod:PlaySound(nil, SoundEffect.SOUND_RECALL)

			-- Update parents
			for _,bone in pairs(Isaac.FindByType(mod.Entities.Type, mod.Entities.BoneOrbital, -1, false, true)) do
				if bone.Parent.Index == entity.Child.Index then
					bone.Parent = entity
				end
			end

			entity.Position = entity.Child.Position
			entity.Velocity = Vector.Zero
			entity.Child:Remove()
			data.isSoul = false

			for i, chain in pairs(data.chain) do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FORGOTTEN_CHAIN, 0, chain.Position - Vector(0, 30), vector, entity)
				chain:Remove()
			end
			data.chain = nil
		end

		-- Reset back to idle phase
		local function backToIdle()
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = Settings.Cooldown
			data.tearCooldown = Settings.TearCooldown

			if entity.I1 == 2 and (entity.HitPoints < (entity.MaxHitPoints / 2) and mod:Random(1) == 1) then
				if data.isSoul ~= true then
					soulGetOut()
				end
			end
		end



		--[[ Always active outside of transition state ]]--
		if entity.State ~= NpcState.STATE_SPECIAL then
			local thirdHp = (entity.MaxHitPoints / 3)

			-- Transition to next phase
			if entity.HitPoints <= entity.MaxHitPoints - (thirdHp * entity.I1) and not data.wasDelirium then
				entity.State = NpcState.STATE_SPECIAL
				sprite:Play(entity.I1 .. "_Transition", true)
				entity.I2 = 0
				if data.isSoul == true then
					soulGetIn()
				end

				entity:RemoveStatusEffects()
				entity.HitPoints = entity.MaxHitPoints - ((entity.MaxHitPoints / 3) * entity.I1)
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end


			-- 1st phase flies
			if entity.I1 == 1 then
				if data.spawnTimer <= 0 then
					data.spawnTimer = Settings.FlyDelay
					local hpRegion = (entity.HitPoints - (thirdHp * 2)) -- The first phase's hp region

					-- Spawn up to 4 Pooters based on HP (< 25% = 4, < 50% = 3 ..)
					if Isaac.CountEntities(entity, EntityType.ENTITY_POOTER, -1, -1) < Settings.PooterCount - (hpRegion / (thirdHp / Settings.PooterCount)) then
						local fly = Isaac.Spawn(EntityType.ENTITY_POOTER, 0, 1, entity.Position, Vector.Zero, entity)
						fly.Parent = entity
						fly:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						fly.MaxHitPoints = fly.MaxHitPoints * 2
						fly.HitPoints = fly.MaxHitPoints
						fly:ToNPC().Scale = 1.15
					end

					-- Spawn an Eternal Fly at 66% and 33% HP
					local eternalCheck = (Settings.EternalFlyCount + 1)
					if Isaac.CountEntities(entity, EntityType.ENTITY_ETERNALFLY, -1, -1) < eternalCheck - (hpRegion / (thirdHp / eternalCheck) + 1) then
						Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 1, entity.Position, Vector.Zero, entity).Parent = entity
					end

				else
					data.spawnTimer = data.spawnTimer - 1
				end


			-- 2nd phase bone orbitals
			elseif entity.I1 == 2 and data.isSoul ~= true then
				-- Spawn one for every 10% HP lost in this phase
				if entity.HitPoints > entity.MaxHitPoints - (thirdHp * 2) -- The first phase's hp region
				and entity.HitPoints <= entity.MaxHitPoints - (thirdHp + (thirdHp / 10) * (data.spawnTimer + 1)) then
					Isaac.Spawn(mod.Entities.Type, mod.Entities.BoneOrbital, 1, entity.Position, Vector.Zero, entity).Parent = entity
					mod:PlaySound(nil, SoundEffect.SOUND_BONE_SNAP, 0.5)
					data.spawnTimer = data.spawnTimer + 1
				end
			end


			-- Damage reduction timer
			if data.damageReduction > 0 then
				data.damageReduction = data.damageReduction - 1
			end
		end



		--[[ Idle phase ]]--
		if entity.State == NpcState.STATE_IDLE then
			-- Movement
			-- Confused / feared
			if mod:IsConfused(entity) or mod:IsFeared(entity) then
				mod:ChasePlayer(entity, Settings.MoveSpeed)

			-- Normal
			else
				local vector = mod:ClampVector(entity.Position - target.Position, 90):Resized(Settings.PlayerDistance)
				local pos = target.Position + vector

				if entity.Position:Distance(pos) < 20 then
					entity.Velocity = mod:StopLerp(entity.Velocity)
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (pos - entity.Position):Resized(Settings.MoveSpeed), 0.25)
				end
			end


			if data.isSoul == true then
				mod:LoopingAnim(sprite, "2_Idle_Soul")
				-- Keep the soul chained to the body
				if entity.Position:Distance(entity.Child.Position) >= Settings.BodyMaxDistance then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Child.Position - entity.Position):Resized(Settings.MoveSpeed), 0.2)
				end

			else
				mod:LoopingAnim(sprite, entity.I1 .. "_Idle")
			end


			-- Shoot at the player
			if data.tearCooldown <= 0 then
				-- Forgotten bones
				if entity.I1 == 2 and data.isSoul ~= true then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.Color = mod.Colors.ForgottenBone
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(10), 0, params)
					mod:PlaySound(nil, SoundEffect.SOUND_SCAMPER)

				-- Pairs of tear shots
				else
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_TEAR

					-- Get the color
					if entity.I1 == 2 then
						params.Color = mod.Colors.SoulShot
					elseif entity.I1 == 3 then
						params.Color = mod.Colors.LostShot
					end

					local targetVector = (target.Position - entity.Position)
					for i = -1, 1, 2 do
						local offset = targetVector:Resized(8):Rotated(i * 90)
						entity:FireProjectiles(entity.Position + offset, targetVector:Resized(10), 0, params)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_TEARS_FIRE)
				end
				data.tearCooldown = Settings.TearCooldown

			else
				data.tearCooldown = data.tearCooldown - 1
			end


			-- Choose an attack
			if entity.ProjectileCooldown <= 0 then
				local attacks = {1, 2, 3}
				if data.lastAttack then
					table.remove(attacks, data.lastAttack)
				end

				local attack = mod:RandomIndex(attacks)
				data.lastAttack = attack

				if data.isSoul == true and attack ~= 2 then
					soulGetIn()
				end

				entity.I2 = 0
				entity.StateFrame = 0

				-- Attack 1
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play(entity.I1 .. "_Attack1", true)

				-- Attack 2
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play(entity.I1 .. "_Attack2", true)
					entity.V1 = Vector(mod:Random(10, 100) * 0.01, 0)

				-- Attack 3
				elseif attack == 3 then
					entity.State = NpcState.STATE_ATTACK3
					sprite:Play(entity.I1 .. "_Attack3", true)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Transition ]]--
		elseif entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = Vector.Zero

			-- 1st to 2nd phase
			if entity.I1 == 1 then
				if sprite:IsEventTriggered("BloodStart") then
					entity.I2 = 1
				elseif sprite:IsEventTriggered("BloodStop") then
					entity.I2 = 0

				elseif sprite:IsEventTriggered("Explosion") then
					entity:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
					entity:BloodExplode()
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite().Offset = Vector(8, -10)

					-- Get rid of Pooters and Eternal Flies
					for i = 0, 1 do
						local type = EntityType.ENTITY_POOTER
						if i == 1 then
							type = EntityType.ENTITY_ETERNALFLY
						end

						for _,fly in pairs(Isaac.FindByType(type, -1, -1, false, true)) do
							if fly.Parent.Index == entity.Index then
								fly:Kill()
							end
						end
					end
				end

				-- Recreate blood death animation
				if entity.I2 == 1 and entity:IsFrame(math.random(3, 4), 0) then
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.9)

					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, entity.Position, Vector.Zero, entity):ToEffect()
					effect.DepthOffset = entity.DepthOffset + 10
					effect:GetSprite().Offset = Vector(math.random(-20, 20), -20 + math.random(-20, 20))

					local effectScale = 1 + (math.random(0, 20) * -0.01)
					effect:GetSprite().Scale = Vector(effectScale, effectScale)
				end


			-- 2nd to 3rd phase
			elseif entity.I1 == 2 then
				if sprite:IsEventTriggered("BloodStart") then
					mod:PlaySound(nil, SoundEffect.SOUND_DEATH_BURST_BONE)

				elseif sprite:IsEventTriggered("BloodStop") then
					local boneEffect = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, entity.Position, Vector.Zero, entity)
					boneEffect.Visible = false
					boneEffect:Kill()

				elseif sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(nil, SoundEffect.SOUND_BONE_HEART)

					-- Get rid of bone orbitals
					for _,bone in pairs(Isaac.FindByType(mod.Entities.Type, mod.Entities.BoneOrbital, -1, false, true)) do
						if bone.Parent.Index == entity.Index then
							bone:Kill()
						end
					end

				elseif sprite:IsEventTriggered("Start") then
					mod:PlaySound(nil, SoundEffect.SOUND_BEAST_GHOST_DASH)

				elseif sprite:IsEventTriggered("End") then
					mod:PlaySound(nil, SoundEffect.SOUND_SUPERHOLY)

				elseif sprite:IsEventTriggered("Explosion") then
					local boneEffect = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, entity.Position, Vector.Zero, entity)
					boneEffect.Visible = false
					boneEffect:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
					boneEffect:Kill()
				end
			end

			if sprite:IsFinished() then
				entity.I1 = entity.I1 + 1
				data.spawnTimer = 0
				data.lastAttack = nil
				backToIdle()
				entity.ProjectileCooldown = Settings.Cooldown / 2
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				data.damageReduction = Settings.TransitionDmgReduction
			end



		--[[ Attack 1 ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- 1st / 2nd phase
			if entity.I1 <= 2 then
				if sprite:IsEventTriggered("Shoot") then
					-- 1st phase wiggle worm tears
					if entity.I1 == 1 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.1
						params.BulletFlags = ProjectileFlags.MEGA_WIGGLE

						params.Scale = 1.35
						entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)

						params.Scale = 1.65
						params.WiggleFrameOffset = 10
						params.CircleAngle = mod:DegreesToRadians(22.5)
						entity:FireProjectiles(entity.Position, Vector(6, 8), 9, params)
						mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)


					-- 2nd phase curving shots
					elseif entity.I1 == 2 then
						mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)

						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.09

						-- Fast ring
						params.Scale = 1.35
						params.BulletFlags = ProjectileFlags.CURVE_RIGHT
						entity:FireProjectiles(entity.Position, Vector(9, 8), 9, params)

						-- Slow ring
						params.Scale = 1.65
						params.BulletFlags = ProjectileFlags.CURVE_LEFT
						params.Color = mod.Colors.SoulShot
						entity:FireProjectiles(entity.Position, Vector(5, 8), 9, params)
					end
				end

				if sprite:IsFinished() then
					backToIdle()
				end


			-- 3rd phase teleporting attack
			elseif entity.I1 == 3 then
				-- Teleport away
				if entity.I2 == 0 then
					if sprite:IsEventTriggered("Shoot") then
						entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
						mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL2, 1.2)

					elseif sprite:IsEventTriggered("Start") then
						entity.Visible = false
					end

					if sprite:IsFinished() then
						entity.I2 = 1
						sprite:Play("3_Attack1_End", true)
						entity.Visible = true

						-- Choose location
						if entity.StateFrame <= 2 then
							local corners = {
								room:GetTopLeftPos() + Vector(20, 20), -- Top left
								Vector(room:GetBottomRightPos().X, room:GetTopLeftPos().Y) + Vector(-20, 20), -- Top right
								Vector(room:GetTopLeftPos().X, room:GetBottomRightPos().Y) + Vector(20, -20), -- Bottom left
								room:GetBottomRightPos() - Vector(20, 20), -- Bottom right
							}
							table.sort(corners, function (k1, k2) return k1:Distance(target.Position) > k2:Distance(target.Position) end )

							-- Don't teleport to the current corner
							if data.lastCorner then
								for i, corner in pairs(corners) do
									if corner:Distance(data.lastCorner) < 10 then
										table.remove(corners, i)
									end
								end
							end
							table.remove(corners, #corners)

							local corner = mod:RandomIndex(corners)
							entity.Position = room:FindFreePickupSpawnPosition(corner, 0, true, true)
							data.lastCorner = corner


						-- Go to the center of the room after 3 attacks
						else
							data.lastCorner = nil
							entity.Position = room:FindFreePickupSpawnPosition(room:GetCenterPos(), 0, true, true)
						end
					end

				-- Re-appear
				elseif entity.I2 == 1 then
					if sprite:IsEventTriggered("Flap") then
						entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
						mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL1, 1.2)
					end

					if sprite:IsFinished() then
						if entity.StateFrame <= 2 then
							entity.I2 = 2
							sprite:Play("3_Attack1_Shoot", true)
						else
							backToIdle()
						end
					end

				-- Attack
				elseif entity.I2 == 2 then
					if sprite:IsEventTriggered("Start") then
						mod:FlipTowardsTarget(entity, sprite)

					elseif sprite:IsEventTriggered("Shoot") then
						-- 1st attack is Holy Orb
						if entity.StateFrame == 0 and not data.wasDelirium then
							Isaac.Spawn(mod.Entities.Type, mod.Entities.BlueBabyExtras, mod.Entities.LostHolyOrb, entity.Position, (target.Position - entity.Position):Resized(20), entity).Parent = entity
							mod:PlaySound(nil, SoundEffect.SOUND_THUMBSUP, 0.6)
							mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT)

						-- Feather shots for the rest
						else
							local params = ProjectileParams()
							params.Variant = mod.Entities.FeatherProjectile
							params.FallingSpeedModifier = 1
							params.FallingAccelModifier = -0.15
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(5), 4, params)

							params.Spread = 1.3
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(7), 5, params)
							mod:PlaySound(nil, SoundEffect.SOUND_THUMBSDOWN_AMPLIFIED, 1.25)
						end

					elseif sprite:IsEventTriggered("End") then
						sprite.FlipX = false
					end

					if sprite:IsFinished() then
						sprite:Play("3_Attack1", true)
						entity.I2 = 0
						entity.StateFrame = entity.StateFrame + 1
					end
				end
			end



		--[[ Attack 2 ]]--
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if data.soulMoving then
				entity.Velocity = (entity.Position - target.Position):Resized(Settings.MoveSpeed * 1.5)
			else
				entity.Velocity = mod:StopLerp(entity.Velocity)
			end


			-- Start
			if entity.I2 == 0 then
				-- In 2nd phase go into the soul form and move away from the body
				if entity.I1 == 2 then
					if sprite:IsEventTriggered("BloodStart") and data.isSoul ~= true then
						soulGetOut()
						data.soulMoving = true
					elseif sprite:IsEventTriggered("BloodStop") and data.soulMoving then
						data.soulMoving = nil
					end
				end

				if sprite:IsEventTriggered("Start") then
					entity.I2 = 1
					entity.StateFrame = 0
					entity.ProjectileDelay = 0
					mod:PlaySound(nil, SoundEffect.SOUND_POWERUP2, 0.9)

					-- 3rd phase boomerang shot tracker
					if entity.I1 == 3 then
						data.boomerangShots = {}
					end
				end


			-- Loop
			elseif entity.I2 == 1 then
				-- Don't interrupt the previous animation
				if not sprite:IsPlaying(entity.I1 .. "_Attack2") then
					-- Don't do shake animation in 3rd phase if all shots have been shot
					if entity.I1 == 3 and entity.StateFrame >= 6 then
						mod:LoopingAnim(sprite, "3_Attack2_Loop_Alt")
					else
						mod:LoopingAnim(sprite, entity.I1 .. "_Attack2_Loop")
					end
				end

				-- Remove non-existent boomerang tears from the tracker in the 3rd phase
				if entity.I1 == 3 then
					for i, projectile in pairs(data.boomerangShots) do
						if not projectile:Exists() then
							table.remove(data.boomerangShots, i)
						end
					end
				end

				-- Advance the pattern 6 times
				if entity.StateFrame < 6 then
					if entity.ProjectileDelay <= 0 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						params.Scale = 1.35

						-- 1st phase spiral shots
						if entity.I1 == 1 then
							params.CircleAngle = entity.V1.X + entity.StateFrame * 0.3
							params.FallingSpeedModifier = -1
							entity:FireProjectiles(entity.Position, Vector(10, 6), 9, params)

						-- 2nd phase soul's spiral shots
						elseif entity.I1 == 2 then
							params.FallingSpeedModifier = -1

							if entity.StateFrame < 3 then
								params.Color = mod.Colors.SoulShot
								params.CircleAngle = mod:DegreesToRadians(45) + entity.StateFrame * 0.3
								entity:FireProjectiles(entity.Position, Vector(10, 4), 9, params)

							else
								params.Variant = ProjectileVariant.PROJECTILE_NORMAL
								params.BulletFlags = ProjectileFlags.SMART
								params.CircleAngle = 0 - entity.StateFrame * 0.3
								entity:FireProjectiles(entity.Position, Vector(10, 4), 9, params)
							end

						-- 3rd phase boomerang shots
						elseif entity.I1 == 3 then
							params.Color = mod.Colors.LostShot
							params.CircleAngle = entity.V1.X + entity.StateFrame * 0.6
							params.FallingSpeedModifier = 1
							params.FallingAccelModifier = -0.1
							params.BulletFlags = (ProjectileFlags.BOOMERANG | ProjectileFlags.CURVE_RIGHT | ProjectileFlags.NO_WALL_COLLIDE)
							local projectiles = mod:FireProjectiles(entity, entity.Position, Vector(10, 6), 9, params)

							for i, projectile in pairs(projectiles) do
								projectile.Parent = entity
								projectile:GetData().blueBabyBoomerangShot = 10
								table.insert(data.boomerangShots, projectile)
							end
						end

						entity.ProjectileDelay = entity.I1 == 3 and 4 or 3 -- 3rd phase has more time between shots
						entity.StateFrame = entity.StateFrame + 1
						mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

				else
					-- 3rd phase only finishes if all shots have disappeared
					if entity.I1 <= 2 or (entity.I1 == 3 and #data.boomerangShots <= 0) then
						entity.I2 = 2
						sprite:Play(entity.I1 .. "_Attack2_End", true)
						data.boomerangShots = nil
					end
				end


			-- End
			elseif entity.I2 == 2 then
				-- 1st / 3rd phase finishing shots
				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.BulletFlags = ProjectileFlags.SMART
					params.FallingSpeedModifier = -1

					-- 1st phase
					if entity.I1 == 1 then
						params.Scale = 1.65
						params.CircleAngle = entity.V1.X + 0.8
						entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)

					-- 3rd phase
					elseif entity.I1 == 3 then
						params.Scale = 1.65
						entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
				end

				if sprite:IsFinished() then
					backToIdle()
				end
			end



		--[[ Attack 3 ]]--
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- 1st phase butt bombs
			if entity.I1 == 1 then
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(nil, SoundEffect.SOUND_POOPITEM_THROW)

					local offset = mod:Random(359)
					for i = 0, 2 do
						local vector = Vector.FromAngle(offset + (i * 120))
						local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_BUTT, 0, entity.Position + (vector * 20), vector * mod:Random(7, 10), entity):ToBomb()
						bomb.PositionOffset = Vector(0, -38)
						bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
						bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					end
				end


			-- 2nd phase club attack
			elseif entity.I1 == 2 then
				-- Swipe towards the player
				if sprite:IsEventTriggered("Start") then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.Color = mod.Colors.ForgottenBone
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)

					entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)
					entity.Velocity = mod:GetTargetVector(entity, target):Resized(Settings.SwipeSpeed)
					mod:PlaySound(nil, SoundEffect.SOUND_SHELLGAME, 1.1)

				-- Throw the bone club at the player
				elseif sprite:IsEventTriggered("Shoot") then
					local club = Isaac.Spawn(EntityType.ENTITY_VIS, 22, 2, entity.Position, (target.Position - entity.Position):Resized(25), entity)
					club:GetSprite():Load("gfx/039.022_forgotten bone projectile.anm2", true)
					club.Parent = entity

					mod:PlaySound(nil, SoundEffect.SOUND_SHELLGAME, 0.8)
					mod:PlaySound(nil, SoundEffect.SOUND_SCAMPER, 1.1)
				end


			-- 3rd phase light beam attack
			elseif entity.I1 == 3 then
				-- Start
				if entity.I2 == 0 then
					if sprite:IsEventTriggered("Start") then
						entity.I2 = 1
						entity.StateFrame = 0
						data.beamTarget = target
						mod:PlaySound(nil, SoundEffect.SOUND_POWERUP1, 0.9)
					end

				-- Loop
				elseif entity.I2 == 1 then
					-- Don't interrupt previous animation
					if not sprite:IsPlaying("3_Attack3") and not sprite:IsPlaying("3_Attack3_Shoot") then
						mod:LoopingAnim(sprite, "3_Attack3_Loop")
					end

					-- Repeat 3 times
					if Isaac.CountEntities(entity, EntityType.ENTITY_LASER, LaserVariant.LIGHT_BEAM, -1) <= 0 then
						if entity.StateFrame < 3 then
							-- Spawn tracers if they don't exist
							if not data.lightTracers then
								mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
								data.lightTracers = {}

								for i = 1, 3 + entity.StateFrame do
									local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.HolyTracer, 0, data.beamTarget.Position + mod:RandomVector(600), Vector.Zero, entity):ToEffect()
									tracer.Timeout = 32
									tracer.TargetPosition = (data.beamTarget.Position - tracer.Position):Normalized()
									tracer:GetSprite():Play("FadeIn", true)
									data.lightTracers[i] = tracer
								end

							else
								local doAttack = false

								for i, tracer in pairs(data.lightTracers) do
									-- Update tracers
									if tracer:Exists() then
										if tracer.Timeout > 10 then
											tracer.TargetPosition = (data.beamTarget.Position - tracer.Position):Normalized()

										-- Play animation
										elseif tracer.Timeout == 10 and i == 1 then
											sprite:Play("3_Attack3_Shoot", true)
										end

									-- Shoot lasers if the tracers are gone
									else
										doAttack = true
										local laser = EntityLaser.ShootAngle(LaserVariant.LIGHT_BEAM, tracer.Position, tracer.TargetPosition:GetAngleDegrees(), 10, Vector.Zero, entity)
										laser.Mass = 0
									end
								end

								if doAttack == true then
									entity.StateFrame = entity.StateFrame + 1
									data.lightTracers = nil
								end
							end

						-- Only finish the attack if all lasers are gone
						else
							entity.I2 = 2
							sprite:Play("3_Attack3_End", true)
						end
					end
				end
			end

			if sprite:IsFinished() then
				backToIdle()
			end



		-- Delirium fix
		elseif data.wasDelirium then
			entity.State = NpcState.STATE_IDLE
			entity.I1 = 4 - math.ceil(entity.HitPoints / (entity.MaxHitPoints / 3))
			entity.ProjectileCooldown = Settings.Cooldown / 2
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlueBabyUpdate, EntityType.ENTITY_ISAAC)

-- Appear sounds
function mod:BlueBabyRender(entity, offset)
	if entity.Variant == 1 and mod:ShouldDoRenderEffects()
	and entity:GetSprite():IsPlaying("Appear") then
        local sprite = entity:GetSprite()
		local data = entity:GetData()


        -- Get up
        if sprite:IsEventTriggered("Start") and not data.AppearGetUp then
            data.AppearGetUp = true
            mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP, 0.8, 0.95)

        -- Gain wings
		elseif sprite:IsEventTriggered("Shoot") and not data.AppearWings then
            data.AppearWings = true
		    mod:PlaySound(nil, SoundEffect.SOUND_SUPERHOLY)

		-- Flap
		elseif sprite:IsEventTriggered("Flap") and not data.AppearFlap then
			data.AppearFlap = true
			mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING, 0.7)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.BlueBabyRender, EntityType.ENTITY_ISAAC)

function mod:BlueBabyDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 1 then
		-- Don't take damage during transitioning
		if (entity:ToNPC().State == NpcState.STATE_SPECIAL or (damageSource.SpawnerType == entity.Type and damageSource.SpawnerVariant == entity.Variant)) then
			return false

		-- Damage reduction after transitioning (disabled in REP+ because of his armor)
		elseif not REPENTANCE_PLUS and entity:GetData().damageReduction > 0 and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
			local onePercent = damageAmount / 100
			entity:TakeDamage(damageAmount - entity:GetData().damageReduction * onePercent, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
			entity:SetColor(mod.Colors.ArmorFlash, 2, 0, false, false)
			return false
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BlueBabyDMG, EntityType.ENTITY_ISAAC)



--[[ Butt bombs ]]--
function mod:BlueBabyButtBomb(entity)
	if entity.SpawnerType == EntityType.ENTITY_ISAAC and entity.SpawnerVariant == 1 then
		if entity:IsDead() and entity.SpawnerEntity then
			local spawner = entity.SpawnerEntity:ToNPC()
			mod:QuickCreep(EffectVariant.CREEP_SLIPPERY_BROWN, spawner, entity.Position, 2, 90)

			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_PUKE
			spawner:FireProjectiles(entity.Position, Vector(8, 4), 6, params)

			for i = 0, 4 do
				params.Scale = 1.65 - (i * 0.15)
				params.FallingAccelModifier = 1.25
				params.FallingSpeedModifier = -8 + (i * -6)
				spawner:FireProjectiles(entity.Position, mod:RandomVector(1.5), 0, params)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BlueBabyButtBomb, BombVariant.BOMB_BUTT)



--[[ Forgotten body and chain, Lost Holy orb ]]--
function mod:BlueBabyExtrasInit(entity)
	if entity.Variant == mod.Entities.BlueBabyExtras then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
		entity.State = NpcState.STATE_IDLE

		-- Body
		if entity.SubType == mod.Entities.ForgottenBody then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity:GetSprite():Play("Appear", true)
			entity:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
			entity.ProjectileCooldown = Settings.TearCooldown

		-- Chain
		elseif entity.SubType == mod.Entities.ForgottenChain then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity:GetSprite():Play("Chain", true)

		-- Holy orb
		elseif entity.SubType == mod.Entities.LostHolyOrb then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			entity:GetSprite():Play("Idle", true)
			entity.ProjectileCooldown = 12
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlueBabyExtrasInit, mod.Entities.Type)

function mod:BlueBabyExtrasUpdate(entity)
	if entity.Variant == mod.Entities.BlueBabyExtras then
		local sprite = entity:GetSprite()


		if entity.Parent and (entity.SubType ~= mod.Entities.ForgottenChain or entity.Child) then
			--[[ Body ]]--
			if entity.SubType == mod.Entities.ForgottenBody then
				if sprite:IsFinished("Appear") then
					mod:LoopingAnim(sprite, "Idle")
				end
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Shoot at the parent's target
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = Settings.TearCooldown

					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.Color = mod.Colors.ForgottenBone
					entity:FireProjectiles(entity.Position, (entity.Parent:ToNPC():GetPlayerTarget().Position - entity.Position):Resized(9), 0, params)
					mod:PlaySound(nil, SoundEffect.SOUND_SCAMPER)

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end

				-- Flap sounds
				if sprite:IsEventTriggered("Flap") then
					mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING, 0.6)
				end



			--[[ Chain ]]--
			elseif entity.SubType == mod.Entities.ForgottenChain then
				local vector = entity.Child.Position - entity.Parent.Position
				local length = vector:Length()
				entity.TargetPosition = entity.Parent.Position + vector:Resized((length / (Settings.ChainLength + 2)) * entity.V1.X)
				entity.Velocity = entity.TargetPosition - entity.Position

				-- Different heights
				local slack = math.min(entity.Position:Distance(entity.Parent.Position), entity.Position:Distance(entity.Child.Position))
				slack = slack * (math.max(0, Settings.BodyMaxDistance - entity.Parent.Position:Distance(entity.Child.Position)) / 800)
				entity.SpriteOffset = Vector(0, -15 + slack)



			--[[ Holy orb ]]--
			elseif entity.SubType == mod.Entities.LostHolyOrb then
				-- Go towards the target
				if entity.State == NpcState.STATE_IDLE then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity:GetPlayerTarget().Position - entity.Position):Resized(1.5), 0.25)

					-- Rotating + pattern shots
					if entity.ProjectileCooldown <= 0 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_HUSH
						params.Scale = 1.35
						params.Color = mod.Colors.HolyOrbShot
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.1
						params.CircleAngle = 0 + (entity.StateFrame * 0.25)

						entity:FireProjectiles(entity.Position, Vector(8, 4), 9, params)
						entity.ProjectileCooldown = 12
						entity.StateFrame = entity.StateFrame + 1

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end

					-- Laser timer
					if entity.I1 >= 180 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("Shoot", true)
						mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)

						-- Tracers
						for i = 0, 3 do
							mod:QuickTracer(entity, i * 90, Vector(0, -35), 10, 3, Color(1,1,0.5, 0.5))
						end

					else
						entity.I1 = entity.I1 + 1
					end


				-- Shoot lasers, disappear
				elseif entity.State == NpcState.STATE_ATTACK then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if sprite:IsEventTriggered("Shoot") then
						-- Lasers
						for i = 0, 3 do
							local laser = EntityLaser.ShootAngle(LaserVariant.LIGHT_BEAM, entity.Position, i * 90, 15, Vector(0, -35), entity)
							laser.DepthOffset = entity.DepthOffset - 10
							laser.Mass = 0
						end
					end

					if sprite:IsFinished() then
						entity:Remove()
					end
				end
			end



		-- Die if they don't have a parent or if the chain has no child
		else
			if entity.SubType == 2 then
				entity.State = NpcState.STATE_DEATH
				sprite:Play("Disappear", true)
			else
				entity:Kill()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BlueBabyExtrasUpdate, mod.Entities.Type)



--[[ Holy tracers ]]--
function mod:HolyTracerUpdate(effect)
	local sprite = effect:GetSprite()

	sprite.Rotation = effect.TargetPosition:GetAngleDegrees() - 90

	if effect.State == 0 then
		if sprite:IsFinished("FadeIn") then
			effect.State = 1
		end

	elseif effect.State == 1 then
		mod:LoopingAnim(sprite, "Idle")

		if effect.Timeout <= 0 then
			effect.State = 2
			sprite:Play("FadeOut", true)
		else
			effect.Timeout = effect.Timeout - 1
		end

	elseif effect.State == 2 then
		if sprite:IsFinished("FadeOut") then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.HolyTracerUpdate, mod.Entities.HolyTracer)



--[[ Lost boomerang shots ]]--
function mod:BlueBabyBoomerangShotUpdate(projectile)
	local data = projectile:GetData()

	if data.blueBabyBoomerangShot then
		-- Die without a parent
		if not projectile.Parent or not projectile.Parent:Exists() or projectile.Parent:IsDead() then
			projectile:Die()

		-- Delay before checking for returning back
		elseif data.blueBabyBoomerangShot > 0 then
			data.blueBabyBoomerangShot = data.blueBabyBoomerangShot - 1

		-- Get removed when it returns to the parent
		elseif projectile.Position:Distance(projectile.Parent.Position) <= projectile.Parent.Size / 2 then
			projectile:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.BlueBabyBoomerangShotUpdate, ProjectileVariant.PROJECTILE_TEAR)