local mod = BetterMonsters

local Settings = {
	NewHealth = 300,
	Cooldown = 90,

	MoveSpeed = 2.5,
	BallSpeed = 7,
	SuckSpeed = 18,

	OrbitDistance = 30,
	MaxOrbitDistance = 150,
}



--[[ Rag Mega ]]--
function mod:ragMegaInit(entity)
	-- Rag Mega
	if entity.Variant == 0 then
		entity.MaxHitPoints = Settings.NewHealth
		entity.HitPoints = entity.MaxHitPoints
		entity.ProjectileCooldown = Settings.Cooldown / 2

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.SplatColor = IRFcolors.RagManBlood

		-- Spawn the plasmas
		entity:GetData().balls = {}
		for i = 1, 3 do
			local plasma = Isaac.Spawn(IRFentities.Type, IRFentities.RagPlasma, 0, entity.Position, Vector.Zero, entity)
			plasma.Parent = entity
			entity:GetData().balls[i] = plasma
		end


	-- Rebirth pillar
	elseif entity.Variant == 2 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity:GetSprite():Play("Rebirth Pillar", true)
		entity.State = NpcState.STATE_SPECIAL
		mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 1.25)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ragMegaInit, EntityType.ENTITY_RAG_MEGA)

function mod:ragMegaUpdate(entity)
	if entity.Variant == 0 or entity.Variant == 2 then
		local sprite = entity:GetSprite()

		-- Rag Mega
		if entity.Variant == 0 then
			local target = entity:GetPlayerTarget()
			local data = entity:GetData()

			mod:LoopingOverlay(sprite, "Rags", true)

			-- Remove plasmas from the list if they don't exist
			for i = 1, #data.balls do
				local ball = data.balls[i]
				if ball and (not ball:Exists() or ball:IsDead()) then
					if ball.Child then
						ball.Child:Remove()
					end

					table.remove(data.balls, i)
				end
			end


			-- Stationary
			if entity.I1 == 0 then
				entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.1)

			-- Move diagonally
			elseif entity.I1 == 1 then
				mod:MoveDiagonally(entity, Settings.MoveSpeed)
			end


			-- Appear animation fix
			if entity.State == NpcState.STATE_INIT then
				if sprite:IsFinished("Appear") or data.wasDelirium then
					entity.State = NpcState.STATE_MOVE
					entity.Velocity = Vector.FromAngle(45 + mod:Random(3) * 90)
				end


			elseif entity.State == NpcState.STATE_MOVE then
				entity.I1 = 1
				mod:LoopingAnim(sprite, "Idle")

				-- Re-summon plasmas if missing
				if not data.balls or #data.balls < 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Push", true)
				end


				-- Choose attack
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = Settings.Cooldown
					entity.I2 = 0
					entity.StateFrame = 0

					-- Get ragling counts
					local totalRaglings = 0
					local deadRaglings = 0
					for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1, -1, false, true)) do
						if ragling.Parent and ragling.Parent.Index == entity.Index then
							totalRaglings = totalRaglings + 1

							-- If dead
							if ragling:ToNPC().State == NpcState.STATE_SPECIAL then
								deadRaglings = deadRaglings + 1
							end
						end
					end

					-- Decide attack
					local attackCount = 3
					if totalRaglings >= 2 and deadRaglings <= 0 then
						attackCount = 2
					end
					local attack = mod:Random(1, attackCount)

					-- First attack is always a ragling
					if not data.wasDelirium and entity.ProjectileDelay == -1 then
						attack = 3
						entity.ProjectileDelay = 1
					end

					if attack == 1 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("Cover", true)
						mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_3, 1.25)
						mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)

					elseif attack == 2 then
						entity.State = NpcState.STATE_ATTACK2
						sprite:Play("Push", true)

					elseif attack == 3 then
						if totalRaglings < 2 and (deadRaglings <= 0 or mod:Random(1) == 1) then
							entity.State = NpcState.STATE_SUMMON2
							sprite:Play("Summon", true)
						else
							entity.State = NpcState.STATE_ATTACK3
							sprite:Play("Rebirth", true)
						end
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Re-summon plasmas
			elseif entity.State == NpcState.STATE_SUMMON then
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4, 1.25)
					mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 1.2)

					for i = 1, 3 do
						local plasma = Isaac.Spawn(IRFentities.Type, IRFentities.RagPlasma, 0, entity.Position, Vector.Zero, entity)
						plasma.Parent = entity
						data.balls[i] = plasma
					end
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end


			-- Cover attack
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Cover
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1

						-- Plasma attack states
						for i = 1, #data.balls do
							local ball = data.balls[i]:ToNPC()
							ball.State = NpcState.STATE_ATTACK
							ball.I1 = 0
							ball.I2 = 0
							ball.ProjectileCooldown = 10
						end
					end
				
				-- Covered
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "Covered")

					if entity.I2 >= 240 or #data.balls < 1 then
						entity.StateFrame = 2
						sprite:Play("Uncover", true)
						entity.I2 = 0

						-- Return plasmas to idle state
						for i = 1, #data.balls do
							data.balls[i]:ToNPC().State = NpcState.STATE_IDLE
							data.balls[i]:ToNPC().V1 = Vector(Settings.OrbitDistance, 0)
						end

					else
						entity.I2 = entity.I2 + 1
					end
				
				-- Uncover
				elseif entity.StateFrame == 2 then
					if sprite:IsEventTriggered("Sound") then
						mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)
					elseif sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_1, 1.25)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end
				end


			-- Plasma eating attack
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Push away
				if entity.StateFrame == 0 then
					if sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4, 1.25)
						mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 1.2)

						for i = 1, #data.balls do
							local ball = data.balls[i]:ToNPC()
							ball.State = NpcState.STATE_MOVE
							ball.Velocity = (ball.Position - entity.Position):Resized(15)
						end
					end

					if sprite:IsFinished() then
						entity.StateFrame = 1
					end

				-- Wait
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "Idle")

					if #data.balls < 1 then
						entity.State = NpcState.STATE_MOVE
					end

					if entity.I2 >= 60 then
						entity.StateFrame = 2
						sprite:Play("SuckStart", true)
						entity.I1 = 0
						entity.I2 = 0

						-- Stop plasmas
						for i = 1, #data.balls do
							data.balls[i]:ToNPC().State = NpcState.STATE_STOMP
						end

					else
						entity.I2 = entity.I2 + 1
					end

				-- Start sucking
				elseif entity.StateFrame == 2 then
					if sprite:IsFinished() then
						for i = 1, #data.balls do
							local ball = data.balls[i]:ToNPC()
							ball.State = NpcState.STATE_JUMP

							-- Connector beam
							local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.KINETI_BEAM, 0, entity.Position, Vector.Zero, entity):ToEffect()
							beam.Parent = entity
							beam:FollowParent(beam.Parent)

							beam.Target = ball
							ball.Child = beam
							beam.DepthOffset = entity.DepthOffset + ball.DepthOffset
						end

						entity.StateFrame = 3
						mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE, 1.25, 0.95)
						mod:PlaySound(nil, SoundEffect.SOUND_BISHOP_HIT, 1.5)
					end

				-- Gobble them balls
				elseif entity.StateFrame == 3 then
					mod:LoopingAnim(sprite, "SuckLoop")

					for i = 1, #data.balls do
						if data.balls[i] then
							-- Consume ball
							local ball = data.balls[i]:ToNPC()
							if ball.Position:Distance(entity.Position) < 20 then
								if ball.Child then
									ball.Child:Remove()
								end
								ball:Remove()

								entity:AddHealth(4)
								entity:SetColor(Color(1,1,1, 1, 0.35,0.1,0.35), 10, 1, true, false)
								mod:PlaySound(nil, SoundEffect.SOUND_PORTAL_SPAWN, 1.35)
								entity.I2 = entity.I2 + 1
							end
						end
					end

					-- Shoot if all balls are gobbled / go to idle state if no balls are consumed
					if #data.balls < 1 then
						entity.StateFrame = 4
						if entity.I2 > 0 then
							sprite:Play("SuckEnd", true)
						else
							sprite:Play("No Balls", true)
						end
					end

				-- Shoot
				elseif entity.StateFrame == 4 then
					if sprite:IsEventTriggered("Shoot") then
						local params = ProjectileParams()
						params.BulletFlags = ProjectileFlags.SMART
						params.Scale = 1.4
						params.FallingSpeedModifier = 1
						params.FallingAccelModifier = 0
						entity:FireBossProjectiles(5 * entity.I2, target.Position, 0, params)
						mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_4, 1.25)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end
				end


			-- Summon ragling
			elseif entity.State == NpcState.STATE_SUMMON2 then
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_1, 1.25)

					local ragling = Isaac.Spawn(EntityType.ENTITY_RAGLING, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
					local ragSprite = ragling:GetSprite()

					ragling.Parent = entity
					ragling.State = NpcState.STATE_MOVE
					ragSprite:Play("Hop", true)
					ragSprite:SetFrame(4)

					local pos = entity.Position + (target.Position - entity.Position):Resized(240)
					ragling.TargetPosition = Game():GetRoom():GetClampedPosition(pos, 0)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end

			-- Revive ragling
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.I1 = 0

				-- Rebirth pillar
				if sprite:IsEventTriggered("Sound") then
					for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1, -1, false, true)) do
						if ragling.Parent.Index == entity.Index and ragling:ToNPC().State == NpcState.STATE_SPECIAL then
							entity.Child = ragling
							Isaac.Spawn(entity.Type, 2, 0, entity.Child.Position, Vector.Zero, entity).DepthOffset = entity.Child:ToNPC().V2.X - 10
							break
						end
					end

				-- Revive
				elseif sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_2, 1.25)
					entity.Child:ToNPC().State = NpcState.STATE_APPEAR_CUSTOM
					entity.Child = nil
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end


		-- Rebirth pillar
		elseif entity.Variant == 2 then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP_STRONG, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end
			if sprite:IsFinished() then
				entity:Remove()
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ragMegaUpdate, EntityType.ENTITY_RAG_MEGA)

function mod:ragMegaDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Reduced damage while curled up
	if target.Variant == 0 and target:ToNPC().State == NpcState.STATE_ATTACK and target:ToNPC().StateFrame == 1 and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		target:TakeDamage(damageAmount / 2, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		target:SetColor(IRFcolors.ArmorFlash, 2, 0, false, false)
		return false

	-- Rebirth pillar
	elseif target.Variant == 2 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ragMegaDMG, EntityType.ENTITY_RAG_MEGA)

function mod:ragMegaDeath(entity)
	if entity.Variant == 0 then
		for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1, -1, false, true)) do
			ragling:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ragMegaDeath, EntityType.ENTITY_RAG_MEGA)



--[[ Plasmas ]]--
function mod:ragPlasmaInit(entity)
	if entity.Variant == IRFentities.RagPlasma then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.V1 = Vector(Settings.OrbitDistance, 0) -- Distance from parent
		entity.State = NpcState.STATE_IDLE
		entity.SplatColor = IRFcolors.RagManPurple
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ragPlasmaInit, IRFentities.Type)

function mod:ragPlasmaUpdate(entity)
	if entity.Variant == IRFentities.RagPlasma then
		if entity.Parent then
			local sprite = entity:GetSprite()

			-- Orbit parent
			if entity.State == NpcState.STATE_IDLE or entity.State == NpcState.STATE_ATTACK then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				mod:OrbitParent(entity, entity.Parent, 2, entity.V1.X)


				-- Curled up attack
				if entity.State == NpcState.STATE_ATTACK then
					-- Increase / decrease orbit distance
					if entity.I1 == 0 then
						if entity.V1.X < Settings.MaxOrbitDistance then
							entity.V1 = Vector(entity.V1.X + 1, 0)
						else
							entity.I1 = 1
						end

					elseif entity.I1 == 1 then
						if entity.V1.X > Settings.OrbitDistance then
							entity.V1 = Vector(entity.V1.X - 1, 0)
						else
							entity.I1 = 0
						end
					end


					-- Shoot
					if entity.I2 == 0 then
						mod:LoopingAnim(sprite, "Idle")

						if entity.ProjectileCooldown <= 0 then
							entity.I2 = 1
							sprite:Play("Shoot", true)
						else
							entity.ProjectileCooldown = entity.ProjectileCooldown - 1
						end

					elseif entity.I2 == 1 then
						if sprite:IsEventTriggered("Shoot") then
							local params = ProjectileParams()
							params.Variant = ProjectileVariant.PROJECTILE_HUSH
							params.Scale = 1.65
							params.BulletFlags = (ProjectileFlags.SMART | ProjectileFlags.NO_WALL_COLLIDE)
							mod:FireProjectiles(entity, entity.Position, (entity.Parent:ToNPC():GetPlayerTarget().Position - entity.Parent.Position):Resized(9), 0, params, IRFcolors.RagManPurple)
							mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP_STRONG)
						end

						if sprite:IsFinished("Shoot") then
							entity.I2 = 0
							entity.ProjectileCooldown = 40
						end
					end

				else
					mod:LoopingAnim(sprite, "Idle")
				end


			-- Move diagonally
			elseif entity.State == NpcState.STATE_MOVE then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				mod:MoveDiagonally(entity, Settings.BallSpeed)


			-- Slow down
			elseif entity.State == NpcState.STATE_STOMP then
				entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.1)
			-- Go to parent
			elseif entity.State == NpcState.STATE_JUMP then
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.Parent.Position - entity.Position):Resized(Settings.SuckSpeed), 0.1)
			end

		else
			entity:Kill()
			mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP_BURST, 0.8)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ragPlasmaUpdate, IRFentities.Type)

function mod:ragPlasmaDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == IRFentities.RagPlasma then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ragPlasmaDMG, IRFentities.Type)