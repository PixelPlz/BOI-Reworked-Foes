local mod = BetterMonsters

local Settings = {
	NewHP = 3000,
	MoveSpeed = 4.75,
	SoulSpeed = 3.75,

	Cooldown = {90, 120},
	TearCooldown = 22,
	FlyDelay = 60,

	PooterCount = 4,
	EternalFlyCount = 2,
	
	ChainLength = 9,
	BodyMaxDistance = 160,
}



function mod:blueBabyInit(entity)
	if entity.Variant == 1 then
		local data = entity:GetData()

		entity.MaxHitPoints = Settings.NewHP
		entity.HitPoints = entity.MaxHitPoints
		entity.I1 = 1
		entity.I2 = 0

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.ProjectileCooldown = Settings.Cooldown[2]
		data.tearCooldown = Settings.TearCooldown * 2
		data.shotCount = 0
		data.spawnTimer = Settings.FlyDelay
		data.isSoul = false
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blueBabyInit, EntityType.ENTITY_ISAAC)

function mod:blueBabyUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		if sprite:IsEventTriggered("Flap") then
			SFXManager():Play(SoundEffect.SOUND_ANGEL_WING, 0.75)
		end

		-- Change to soul form
		local function soulGetOut()
			local body = Isaac.Spawn(200, IRFentities.forgottenBody, 0, entity.Position, Vector.Zero, entity)
			body.Parent = entity
			entity.Child = body
			data.isSoul = true

			entity:SetColor(Color(1,1,1, 1, 1,1,1), 10, 1, true, false)
			SFXManager():Play(SoundEffect.SOUND_RECALL)
			
			data.chain = {}
			for i = 1, Settings.ChainLength do
				data.chain[i] = Isaac.Spawn(200, IRFentities.forgottenBody, 1, entity.Position, Vector.Zero, entity):ToNPC()
				data.chain[i].V1 = Vector(i + 0.5, 0)
				data.chain[i].Child = entity.Child
				data.chain[i].Parent = entity
			end
			
			-- Update parents
			for _,bone in pairs(Isaac.FindByType(200, IRFentities.boneOrbital, -1, false, true)) do
				if bone.Parent.Index == entity.Index then
					bone.Parent = entity.Child
				end
			end
			for _,bone in pairs(Isaac.FindByType(EntityType.ENTITY_VIS, 22, 102, false, true)) do
				if bone.Parent.Index == entity.Index then
					bone.Parent = entity.Child
				end
			end
		end
		
		-- Change from soul form
		local function soulGetIn()
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 10, entity.Position, (entity.Child.Position - entity.Position):Normalized() * 7, entity).SpriteOffset = Vector(0, -10)
			entity:SetColor(Color(1,1,1, 1, 1,1,1), 10, 1, true, false)
			SFXManager():Play(SoundEffect.SOUND_RECALL)
			
			-- Update parents
			for _,bone in pairs(Isaac.FindByType(200, IRFentities.boneOrbital, -1, false, true)) do
				if bone.Parent.Index == entity.Child.Index then
					bone.Parent = entity
				end
			end

			entity.Position = entity.Child.Position
			entity.Child:Remove()
			data.isSoul = false

			for i, chain in pairs(data.chain) do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FORGOTTEN_CHAIN, 0, chain.Position - Vector(0, 30), (entity.Child.Position - entity.Position):Normalized() * 7, entity)
				chain:Remove()
			end
			data.chain = nil
		end
		
		-- Reset back to idle phase
		local function backToIdle()
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = math.random(Settings.Cooldown[1], Settings.Cooldown[2])
			data.tearCooldown = Settings.TearCooldown
			entity.I2 = 0
			entity.StateFrame = 0
			
			if entity.I1 == 2 and (entity.HitPoints < (entity.MaxHitPoints / 2) and math.random(0, 1) == 1) then
				if data.isSoul ~= true then
					soulGetOut()
				end
			end
		end



		--[[ Always active outside of transition state ]]--
		if entity.State ~= NpcState.STATE_SPECIAL then
			local thirdHp = (entity.MaxHitPoints / 3)

			-- Transition to next phase
			if entity.HitPoints <= entity.MaxHitPoints - (thirdHp * entity.I1) and room:GetBossID() ~= 70 then
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
				if entity.HitPoints > entity.MaxHitPoints - ((entity.MaxHitPoints / 3) * 2) and entity.HitPoints <= entity.MaxHitPoints - (thirdHp + (thirdHp / 10) * (data.spawnTimer + 1)) then
					Isaac.Spawn(200, IRFentities.boneOrbital, 1, entity.Position, Vector.Zero, entity).Parent = entity
					SFXManager():Play(SoundEffect.SOUND_BONE_SNAP, 0.6)
					data.spawnTimer = data.spawnTimer + 1
				end
			end
		end



		--[[ Idle phase ]]--
		if entity.State == NpcState.STATE_IDLE then
			-- Stay at a point around the player, change this point every 60 frames
			if not data.angle or entity:IsFrame(60, 0) then
				data.angle = math.random(0, 7) * 45
			end
			entity.Velocity = mod:Lerp(entity.Velocity, ((target.Position + (Vector.FromAngle(data.angle) * 100)) - entity.Position):Normalized() * Settings.MoveSpeed, 0.25)

			if data.isSoul == true then
				mod:LoopingAnim(sprite, "2_Idle_Soul")
				-- Keep the soul chained to the body
				if entity.Position:Distance(entity.Child.Position) >= Settings.BodyMaxDistance then
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Child.Position - entity.Position):Normalized() * Settings.MoveSpeed, 0.2)
				end

			else
				mod:LoopingAnim(sprite, entity.I1 .. "_Idle")
			end


			-- Shoot at the player
			if data.tearCooldown <= 0 then
				-- Forgotten (skeleton form)
				if entity.I1 == 2 and data.isSoul ~= true then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.Color = forgottenBoneColor
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * (10 - (data.shotCount % 3)), 0 + (data.shotCount % 3), params)
					SFXManager():Play(SoundEffect.SOUND_SCAMPER)

				else
					SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE)
					local params = ProjectileParams()
					params.Scale = 1.35

					-- Every 3rd attack is homing in 1st phase
					local isHoming = 0
					if entity.I1 == 1 and data.shotCount % 3 == 0 then
						isHoming = 1
					end
					-- Is attack homing or not
					if isHoming == 1 then
						params.BulletFlags = ProjectileFlags.SMART
					else
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						if entity.I1 == 2 then
							params.Color = forgottenBulletColor
						elseif entity.I1 == 3 then
							params.Color = lostBulletColor
						end
					end

					-- Every 3th attack in 3rd phase is burst one
					if entity.I1 == 3 and data.shotCount % 3 == 0 then
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.1
						params.BulletFlags = ProjectileFlags.BURST
						params.Scale = 1.9
						params.Color = forgottenBulletColor
						for i = 0, 2 do
							entity:FireProjectiles(entity.Position, Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees() + (i * 120)) * 8, 0, params)
						end
					else
						for i = -1, 1, 2 do
							entity:FireProjectiles(entity.Position + ((target.Position - entity.Position):Normalized():Rotated(i * 90) * 8), (target.Position - entity.Position):Normalized() * (10 - isHoming), 0, params)
						end
					end
				end

				data.tearCooldown = Settings.TearCooldown
				data.shotCount = data.shotCount + 1

			else
				data.tearCooldown = data.tearCooldown - 1
			end


			-- Choose an attack
			if entity.ProjectileCooldown <= 0 then
				local attack = math.random(1, 3)
				if data.isSoul == true and attack ~= 2 then
					soulGetIn()
				end
				entity.I2 = 0

				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play(entity.I1 .. "_Attack1", true)

				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play(entity.I1 .. "_Attack2", true)
					entity.V1 = Vector(math.random(10, 100) * 0.01, 0)

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
				if entity.I2 == 1 then
					if entity:IsFrame(4, 0) then
						SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS)
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 0, entity.Position, Vector.Zero, entity):ToEffect()
						effect:GetSprite().Offset = Vector(math.random(-20, 20), -20 + math.random(-20, 20))
						local effectScale = 1 + (math.random(-20, 20) * 0.01)
						effect:GetSprite().Scale = Vector(effectScale, effectScale)
						effect.DepthOffset = entity.DepthOffset + 10
					end
				end


			-- 2nd to 3rd phase
			elseif entity.I1 == 2 then
				if sprite:IsEventTriggered("BloodStart") then
					SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_BONE)
				elseif sprite:IsEventTriggered("BloodStop") then
					Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, entity.Position, Vector.Zero, entity):Kill()
				elseif sprite:IsEventTriggered("Shoot") then
					SFXManager():Play(SoundEffect.SOUND_BONE_HEART)

					-- Get rid of bone orbitals
					for _,bone in pairs(Isaac.FindByType(200, IRFentities.boneOrbital, -1, false, true)) do
						if bone.Parent.Index == entity.Index then
							bone:Kill()
						end
					end

				elseif sprite:IsEventTriggered("Start") then
					SFXManager():Play(SoundEffect.SOUND_BEAST_GHOST_DASH)
				elseif sprite:IsEventTriggered("End") then
					SFXManager():Play(SoundEffect.SOUND_SUPERHOLY)

				elseif sprite:IsEventTriggered("Explosion") then
					local boneEffect = Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
					boneEffect:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
					boneEffect:Kill()
				end
			end

			if sprite:IsFinished() then
				entity.I1 = entity.I1 + 1
				data.spawnTimer = 0
				backToIdle()
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
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
						params.Scale = 1.65
						params.BulletFlags = ProjectileFlags.MEGA_WIGGLE
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.1

						entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)
						params.WiggleFrameOffset = 10
						params.CircleAngle = 0.41
						entity:FireProjectiles(entity.Position, Vector(6, 8), 9, params)
						entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)


					-- 2nd phase curving shots
					elseif entity.I1 == 2 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = -0.1

						params.Scale = 1.35
						params.BulletFlags = ProjectileFlags.CURVE_RIGHT
						entity:FireProjectiles(entity.Position, Vector(10, 12), 9, params)

						params.Scale = 1.65
						params.BulletFlags = ProjectileFlags.CURVE_LEFT
						params.Color = forgottenBulletColor
						entity:FireProjectiles(entity.Position, Vector(5, 12), 9, params)
						entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
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
						SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL2, 1.2)
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
							local choices = {1, 2, 3, 4}

							-- Don't teleport to the current corner
							if data.lastCorner then
								table.remove(choices, data.lastCorner)
							end

							local corner = math.random(1, #choices)
							entity.Position = room:FindFreePickupSpawnPosition(corners[choices[corner]], 0, true, true)
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
						SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL1, 1.2)
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
						-- Face towards the player
						if target.Position.X < entity.Position.X then
							sprite.FlipX = true
						else
							sprite.FlipX = false
						end

					elseif sprite:IsEventTriggered("Shoot") then
						-- 1st attack is Holy Orb
						if entity.StateFrame == 0 then
							Isaac.Spawn(200, IRFentities.forgottenBody, 2, entity.Position, (target.Position - entity.Position):Normalized() * 20, entity)
							SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT)

						-- Feather shots for the rest
						else
							local params = ProjectileParams()
							params.Variant = IRFentities.featherProjectile
							params.FallingSpeedModifier = 1
							params.FallingAccelModifier = -0.15
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 5, 4, params)

							params.Spread = 1.3
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 7, 5, params)
							entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
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
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Start
			if entity.I2 == 0 then
				-- In 2nd phase go to soul form and move away from body
				if entity.I1 == 2 then
					if sprite:IsEventTriggered("BloodStart") and data.isSoul ~= true then
						soulGetOut()
						data.soulMoving = true
					elseif sprite:IsEventTriggered("BloodStop") and data.soulMoving then
						data.soulMoving = nil
					end

					if data.soulMoving and data.soulMoving == true then
						entity.Velocity = (entity.Position - target.Position):Normalized() * (Settings.MoveSpeed * 2)
					end
				end

				if sprite:IsEventTriggered("Start") then
					entity.I2 = 1
					entity.StateFrame = 0
					entity.ProjectileDelay = 0
					SFXManager():Play(SoundEffect.SOUND_POWERUP2, 0.9)
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

				-- Advance the pattern 6 times
				if entity.StateFrame < 6 then
					if entity.ProjectileDelay <= 0 then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_TEAR
						params.Scale = 1.35
						
						-- 1st phase spiral shots
						if entity.I1 == 1 then
							params.CircleAngle = entity.V1.X + entity.StateFrame * 0.2
							params.FallingSpeedModifier = -1
							entity:FireProjectiles(entity.Position, Vector(10, 6), 9, params)

						-- 2nd phase soul's spiral shots
						elseif entity.I1 == 2 then
							params.FallingSpeedModifier = -1

							if entity.StateFrame < 3 then
								params.Color = forgottenBulletColor
								params.CircleAngle = 0.8 + entity.StateFrame * 0.3
								entity:FireProjectiles(entity.Position, Vector(11, 4), 9, params)

							else
								params.Variant = ProjectileVariant.PROJECTILE_NORMAL
								params.BulletFlags = ProjectileFlags.SMART
								params.CircleAngle = 0 - entity.StateFrame * 0.3
								entity:FireProjectiles(entity.Position, Vector(11, 4), 9, params)
							end

						-- 3rd phase boomerang shots
						elseif entity.I1 == 3 then
							params.Color = lostBulletColor
							params.CircleAngle = entity.V1.X + entity.StateFrame * 0.4
							params.FallingSpeedModifier = 1
							params.FallingAccelModifier = -0.1

							params.BulletFlags = (ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT | ProjectileFlags.BOOMERANG | ProjectileFlags.CURVE_RIGHT | ProjectileFlags.NO_WALL_COLLIDE)
							params.ChangeFlags = ProjectileFlags.FADEOUT
							params.ChangeTimeout = 108

							entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)
						end

						-- 3rd phase has more time between shots
						if entity.I1 == 3 then
							entity.ProjectileDelay = 3
						else
							entity.ProjectileDelay = 2 + (entity.StateFrame % 2)
						end
						entity.StateFrame = entity.StateFrame + 1
						entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end

				else
					-- 3rd phase only finishes if all shots have disappeared
					if entity.I1 <= 2 or (entity.I1 == 3 and Isaac.CountEntities(entity, EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_TEAR, -1) <= 0) then
						entity.I2 = 2
						sprite:Play(entity.I1 .. "_Attack2_End", true)
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
						params.CircleAngle = entity.V1.X + 0.4
						entity:FireProjectiles(entity.Position, Vector(12, 6), 9, params)

					-- 3rd phase
					elseif entity.I1 == 3 then
						params.Scale = 1.35
						entity:FireProjectiles(entity.Position, Vector(12, 8), 8, params)
						params.Scale = 1.85
						params.CircleAngle = 0.41
						entity:FireProjectiles(entity.Position, Vector(7, 8), 9, params)
					end

					entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
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
					SFXManager():Play(SoundEffect.SOUND_POOPITEM_THROW)

					local offset = math.random(0, 359)
					for i = 0, 2 do
						local vector = Vector.FromAngle(offset + (i * 120))
						local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_BUTT, 0, entity.Position + (vector * 20), vector * math.random(7, 10), entity):ToBomb()
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
					params.Color = forgottenBoneColor
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					entity:FireProjectiles(entity.Position, Vector(10, 6), 9, params)

					entity.Velocity = (target.Position - entity.Position):Normalized() * 35
					SFXManager():Play(SoundEffect.SOUND_SHELLGAME, 1.1)

				-- Throw bone at player
				elseif sprite:IsEventTriggered("Shoot") then
					Isaac.Spawn(EntityType.ENTITY_VIS, 22, 102, entity.Position, (target.Position - entity.Position):Normalized() * 25, entity).Parent = entity
					SFXManager():Play(SoundEffect.SOUND_SHELLGAME, 0.8)
					SFXManager():Play(SoundEffect.SOUND_SCAMPER, 1.1)
				end


			-- 3rd phase light beam attack
			elseif entity.I1 == 3 then
				-- Start
				if entity.I2 == 0 then
					if sprite:IsEventTriggered("Start") then
						entity.I2 = 1
						entity.StateFrame = 0
						data.beamTarget = target
						SFXManager():Play(SoundEffect.SOUND_POWERUP1, 0.9)
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
								SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
								data.lightTracers = {}

								for i = 1, 3 + entity.StateFrame do
									local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.holyTracer, 0, data.beamTarget.Position + (Vector.FromAngle(math.random(0, 359)) * 600), Vector.Zero, entity):ToEffect()
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
										local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.LIGHT_BEAM, tracer.Position, tracer.TargetPosition:GetAngleDegrees(), 10, Vector.Zero, entity), entity}
										laser_ent_pair.laser.Mass = 0
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
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blueBabyUpdate, EntityType.ENTITY_ISAAC)

function mod:blueBabyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 and (target:ToNPC().State == NpcState.STATE_SPECIAL or (damageSource.SpawnerType == target.Type and damageSource.SpawnerVariant == target.Variant)) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blueBabyDMG, EntityType.ENTITY_ISAAC)



-- Butt bombs
function mod:blueBabyBomb(entity)
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
				spawner:FireProjectiles(entity.Position, Vector.FromAngle(math.random(0, 359)) * 1.5, 0, params)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.blueBabyBomb, BombVariant.BOMB_BUTT)



-- Forgotten body and chain, Lost Holy orb
function mod:forgottenBodyInit(entity)
	if entity.Variant == IRFentities.forgottenBody then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
		entity.State = NpcState.STATE_IDLE

		-- Body
		if entity.SubType == 0 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity:GetSprite():Play("Appear", true)

		-- Chain
		elseif entity.SubType == 1 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity:GetSprite():Play("Chain", true)

		-- Holy orb
		elseif entity.SubType == 2 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			entity:GetSprite():Play("Idle", true)
			entity.ProjectileCooldown = 12
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.forgottenBodyInit, 200)

function mod:forgottenBodyUpdate(entity)
	if entity.Variant == IRFentities.forgottenBody then
		local sprite = entity:GetSprite()


		-- Holy orb
		if entity.SubType == 2 then
			-- Go towards target
			if entity.State == NpcState.STATE_IDLE then
				entity.Velocity = mod:Lerp(entity.Velocity, (entity:GetPlayerTarget().Position - entity.Position):Normalized() * 1.5, 0.25)

				-- Rotating + pattern shots
				if entity.ProjectileCooldown <= 0 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_HUSH
					params.Scale = 1.35
					params.Color = Color(1,1,1, 0.7, 0.4,0.4,0)
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
					SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)

					-- Tracers
					for i = 0, 3 do
						local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, entity.Position, Vector.Zero, entity):ToEffect()
						tracer.LifeSpan = 15
						tracer.Timeout = 15
						tracer.TargetPosition = Vector.FromAngle(i * 90)
						tracer:GetSprite().Color = Color(1,1,0.5, 0.5)
						tracer.SpriteScale = Vector(3, 0)
						tracer:FollowParent(entity)
						tracer.ParentOffset = Vector(0, -35)
						tracer:Update()
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
						local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.LIGHT_BEAM, entity.Position, i * 90, 15, Vector(0, -35), entity), entity}
						local laser = laser_ent_pair.laser
						laser.DepthOffset = entity.DepthOffset - 10
						laser.Mass = 0
					end
				end

				if sprite:IsFinished() then
					entity:Remove()
				end
			end


		-- Body / Chain
		else
			if entity.Parent and (entity.SubType == 0 or entity.Child) then
				-- Body
				if entity.SubType == 0 then
					if sprite:IsFinished("Appear") then
						mod:LoopingAnim(sprite, "Idle")
					end
					entity.Velocity = mod:StopLerp(entity.Velocity)

					-- Shoot at the parent's target
					if sprite:IsEventTriggered("Flap") then
						SFXManager():Play(SoundEffect.SOUND_ANGEL_WING, 0.6)

						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_BONE
						params.Color = forgottenBoneColor
						entity:FireProjectiles(entity.Position, (entity.Parent:ToNPC():GetPlayerTarget().Position - entity.Position):Normalized() * 9, 0, params)
						SFXManager():Play(SoundEffect.SOUND_SCAMPER)
					end


				-- Chain
				elseif entity.SubType == 1 then
					local vector = entity.Child.Position - entity.Parent.Position
					local length = vector:Length()
					entity.TargetPosition = entity.Parent.Position + vector:Resized((length / (Settings.ChainLength + 2)) * entity.V1.X)
					entity.Velocity = entity.TargetPosition - entity.Position

					-- Different heights
					local slack = math.min(entity.Position:Distance(entity.Parent.Position), entity.Position:Distance(entity.Child.Position))
					slack = slack * (math.max(0, Settings.BodyMaxDistance - entity.Parent.Position:Distance(entity.Child.Position)) / 800)
					entity.SpriteOffset = Vector(0, -15 + slack)
				end


			-- Die if they don't have a parent or if the chain has no child
			else
				entity:Kill()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.forgottenBodyUpdate, 200)

function mod:forgottenBodyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == IRFentities.forgottenBody then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.forgottenBodyDMG, 200)



-- Holy tracers
function mod:holyTracerUpdate(effect)
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
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.holyTracerUpdate, IRFentities.holyTracer)