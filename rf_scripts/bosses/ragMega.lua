local mod = ReworkedFoes

local Settings = {
	NewHealth = 350,
	Cooldown = 60,
	MoveSpeed = 2.5,
	MaxRaglings = 3,
	RaglingJumpDistance = 5 * 40,

	-- Plasma balls
	OrbitDistance = 30,
	OrbitSpeed = 2,

	-- Curled up attack
	DamageReduction = 0.5, -- When curled up
	DistanceIncreases = 2,

	DistanceChangeSpeed = 3.5,
	MaxOrbitDistance = 210,
	MaxOrbitSpeed = 3,
	MaxDistanceTime = 30, -- Delay before decreasing distance again

	-- Ball sucking attack
	PushSpeed = 15,
	BallSpeed = 7.5,
	SuckSpeed = 18,

	WaitTime = 60,
	BallHeal = 5,
	BallProjectiles = 4, -- The amount of projectiles each ball gives to Rag Mega's volley
}



--[[ Rag Mega ]]--
function mod:RagMegaInit(entity)
	-- Rag Mega
	if entity.Variant == 0 then
		mod:ChangeMaxHealth(entity, Settings.NewHealth)
		entity.ProjectileCooldown = Settings.Cooldown / 2

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.SplatColor = mod.Colors.RagManBlood

		-- Spawn the plasmas
		local balls = {}

		for i = 1, 3 do
			local plasma = Isaac.Spawn(mod.Entities.Type, mod.Entities.RagPlasma, 0, entity.Position, Vector.Zero, entity):ToNPC()
			plasma.Parent = entity
			table.insert(balls, plasma)
		end
		entity:GetData().balls = balls


	-- Rebirth pillar
	elseif entity.Variant == 2 then
		mod:ChangeMaxHealth(entity, 0)
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

		entity:GetSprite():Play("Rebirth Pillar", true)
		mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.RagMegaInit, EntityType.ENTITY_RAG_MEGA)

function mod:RagMegaUpdate(entity)
	--[[ Rag Mega ]]--
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		for i, ball in pairs(data.balls) do
			-- Remove plasmas from the list if they don't exist
			if not ball:Exists() or ball:IsDead() then
				table.remove(data.balls, i)

			-- Spawned from Delirious
			elseif entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
				ball:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
			end
		end



		--[[ Appear animation fix ]]--
		if entity.State == NpcState.STATE_INIT then
			if sprite:IsFinished("Appear") or data.wasDelirium then
				entity.State = NpcState.STATE_MOVE
				entity.Velocity = Vector.FromAngle(45 + mod:Random(3) * 90)
			end


		--[[ Idle ]]--
		elseif entity.State == NpcState.STATE_MOVE then
			mod:MoveDiagonally(entity, Settings.MoveSpeed)
			mod:LoopingAnim(sprite, "Walk")

			-- Re-summon plasmas if missing
			if not data.balls or #data.balls < 1 then
				entity.State = NpcState.STATE_SUMMON
				sprite:Play("Push", true)
			end


			-- Choose attack
			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = Settings.Cooldown
				entity.StateFrame = 0
				entity.I1 = 0

				-- Get Ragling counts
				local totalRaglings = 0
				local deadRaglings = 0

				for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1)) do
					if ragling.Parent and ragling.Parent.Index == entity.Index then
						totalRaglings = totalRaglings + 1

						-- If dead
						if ragling:ToNPC().State == NpcState.STATE_SPECIAL then
							deadRaglings = deadRaglings + 1
						end
					end
				end


				-- Choose attack
				local attack = 3

				-- Always spawn a Ragling first
				if data.didFirstRagling then
					local attackCount = 3

					-- Don't summon more Raglings
					if totalRaglings >= Settings.MaxRaglings and deadRaglings <= 0 then
						attackCount = 2

					elseif (totalRaglings >= Settings.MaxRaglings and deadRaglings > 0) -- More likely to revive if there are dead Raglings at the max count
					or totalRaglings < math.ceil(Settings.MaxRaglings / 2) then -- More likely to summon Raglings if there are less than 2
						attackCount = 4
					end

					attack = mod:Random(1, attackCount)
					attack = math.min(3, attack)
				end


				-- Cover attack
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Cover", true)
					mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_3, 1.25)
					mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)

				-- Plasma eating attack
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("Push", true)

				-- Summon / revive Raglings
				elseif attack == 3 then
					data.didFirstRagling = true

					-- Summon
					if totalRaglings < Settings.MaxRaglings
					and (deadRaglings <= 0 or mod:Random(1) == 1) then
						entity.State = NpcState.STATE_SUMMON2
						sprite:Play("Summon", true)

					-- Revive
					else
						entity.State = NpcState.STATE_ATTACK3
						sprite:Play("Rebirth", true)
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Re-summon plasmas ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			mod:MoveDiagonally(entity, Settings.MoveSpeed)

			if sprite:IsEventTriggered("Shoot") then
				for i = 1, 3 do
					local plasma = Isaac.Spawn(mod.Entities.Type, mod.Entities.RagPlasma, 0, entity.Position, Vector.Zero, entity):ToNPC()
					plasma.Parent = entity
					table.insert(data.balls, plasma)
				end

				-- Effects
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 1.1, 0.9)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Cover attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			mod:MoveDiagonally(entity, Settings.MoveSpeed)

			-- Cover up
			if entity.StateFrame == 0 then
				if sprite:IsFinished() then
					entity.StateFrame = 1

					-- Set the states for the plasmas
					for i, ball in pairs(data.balls) do
						ball.State = NpcState.STATE_ATTACK
						ball.I1 = 0
						ball.I2 = 0
					end
				end


			-- Covered
			elseif entity.StateFrame == 1 then
				mod:LoopingAnim(sprite, "Covered")

				-- Check if all the plasmas are done (or if there aren't any)
				local allDone = true

				for i, ball in pairs(data.balls) do
					if ball.I2 < Settings.DistanceIncreases then
						allDone = false
					end
				end

				if allDone then
					entity.StateFrame = 2
					sprite:Play("Uncover", true)

					-- Return the plasmas to the idle state
					for i, ball in pairs(data.balls) do
						ball.State = NpcState.STATE_IDLE
					end
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



		--[[ Plasma eating attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK2 then
			-- Push away the balls
			if entity.StateFrame == 0 then
				mod:MoveDiagonally(entity, Settings.MoveSpeed)

				if sprite:IsEventTriggered("Shoot") then
					for i, ball in pairs(data.balls) do
						ball.State = NpcState.STATE_MOVE
						ball.Velocity = (ball.Position - entity.Position):Resized(Settings.PushSpeed)
						mod:QuickTrail(ball, 0.1, mod.Colors.RagManPurple, 3)
					end

					-- Effects
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4, 1.25)
					mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP, 1.2)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = Settings.WaitTime
				end


			-- Wait
			elseif entity.StateFrame == 1 then
				mod:MoveDiagonally(entity, Settings.MoveSpeed)
				mod:LoopingAnim(sprite, "Walk")

				-- Stop the attak if the plasmas are gone
				if #data.balls <= 0 then
					entity.State = NpcState.STATE_MOVE
				end

				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play("SuckStart", true)

					-- Stop the plasmas
					for i, ball in pairs(data.balls) do
						ball.State = NpcState.STATE_STOMP
					end

				else
					entity.I1 = entity.I1 - 1
				end


			-- Start sucking
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

				if sprite:IsFinished() then
					entity.StateFrame = 3

					-- Connect to the plamas and start sucking!
					for i, ball in pairs(data.balls) do
						ball.State = NpcState.STATE_JUMP
						ball:GetData().spriteTrail:Remove()

						-- Connector beam
						local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.KINETI_BEAM, 0, entity.Position, Vector.Zero, entity):ToEffect()
						beam.Parent = entity
						beam:FollowParent(beam.Parent)

						beam.Target = ball
						ball.Child = beam
						beam.DepthOffset = entity.DepthOffset + ball.DepthOffset
					end

					-- Effects
					mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE, 1.25, 0.95)
					mod:PlaySound(nil, SoundEffect.SOUND_BISHOP_HIT, 1.5)
				end


			-- Gobble them balls
			elseif entity.StateFrame == 3 then
				entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)
				mod:LoopingAnim(sprite, "SuckLoop")

				-- Consume the plamas if close enough
				for i, ball in pairs(data.balls) do
					if ball.Position:Distance(entity.Position) <= ball.Size then
						if ball.Child then
							ball.Child:Remove()
						end
						ball:Remove()

						-- Health + projectile count
						entity.I1 = entity.I1 + 1
						entity:AddHealth(Settings.BallHeal)

						-- Effects
						entity:SetColor(Color(1,1,1, 1, 0.35,0.1,0.35), 10, 1, true, false)
						mod:PlaySound(nil, SoundEffect.SOUND_PORTAL_SPAWN, 1.35)
					end
				end

				-- Shoot if all plasmas are gobbled / Go to the idle state if none were consumed
				if #data.balls <= 0 then
					entity.StateFrame = 4

					if entity.I1 > 0 then
						sprite:Play("SuckEnd", true)
					else
						sprite:Play("No Balls", true)
					end
				end


			-- Shoot
			elseif entity.StateFrame == 4 then
				entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.BulletFlags = ProjectileFlags.SMART
					params.HeightModifier = -10
					entity:FireBossProjectiles(entity.I1 * Settings.BallProjectiles, target.Position, 0, params)
					mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_4, 1.25)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end



		--[[ Summon a Ragling ]]--
		elseif entity.State == NpcState.STATE_SUMMON2 then
			mod:MoveDiagonally(entity, Settings.MoveSpeed)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_1, 1.25)

				local ragling = Isaac.Spawn(EntityType.ENTITY_RAGLING, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
				ragling.Parent = entity
				ragling.State = NpcState.STATE_MOVE

				-- Make it jump at the player
				local raglingSprite = ragling:GetSprite()
				raglingSprite:Play("Hop", true)
				raglingSprite:SetFrame(4)

				local pos = entity.Position + (target.Position - entity.Position):Resized(Settings.RaglingJumpDistance)
				ragling.TargetPosition = Game():GetRoom():GetClampedPosition(pos, ragling.Size)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Revive a Ragling ]]--
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

			-- Create the rebirth pillar
			if sprite:IsEventTriggered("Sound") then
				for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1)) do
					ragling = ragling:ToNPC()

					-- Choose a valid Ragling
					if ragling.Parent.Index == entity.Index and ragling.State == NpcState.STATE_SPECIAL then
						local pillar = Isaac.Spawn(entity.Type, 2, 0, ragling.Position, Vector.Zero, entity)
						pillar.Child = ragling
						pillar.DepthOffset = ragling.V2.X - 10 -- I don't remember why I did it like this lol
						break
					end
				end

			-- RARGH!!
			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_2, 1.25)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true





	--[[ Rebirth pillar ]]--
	elseif entity.Variant == 2 then
		local sprite = entity:GetSprite()

		if sprite:IsEventTriggered("Shoot") then
			-- Revive the Ragling
			if entity.Child then
				entity.Child:ToNPC().State = NpcState.STATE_APPEAR_CUSTOM
			end

			-- Projectiles
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Scale = 1.5
			params.BulletFlags = ProjectileFlags.SMART
			mod:FireProjectiles(entity, entity.Position, Vector(10, 4), 6, params, mod.Colors.RagManPurple)

			-- Effects
			mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP_STRONG, 1.5)
			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)

		elseif sprite:IsFinished() then
			entity:Remove()
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.RagMegaUpdate, EntityType.ENTITY_RAG_MEGA)

-- Appear sounds
function mod:RagMegaRender(entity, offset)
	if entity.Variant == 0 and mod:ShouldDoRenderEffects() and entity.State == NpcState.STATE_APPEAR then
        local sprite = entity:GetSprite()
		local data = entity:GetData()


        if sprite:IsEventTriggered("Sound") and not data.AppearUncover then
			data.AppearUncover = true
			mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)

		elseif sprite:IsEventTriggered("Shoot") and not data.AppearSound then
			data.AppearSound = true
			mod:PlaySound(entity, SoundEffect.SOUND_RAGMAN_1, 1.25)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.RagMegaRender, EntityType.ENTITY_RAG_MEGA)

-- Reduced damage while curled up
function mod:RagMegaDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	entity = entity:ToNPC()

	if entity.Variant == 0
	and entity.State == NpcState.STATE_ATTACK and entity.StateFrame == 1
	and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		entity:TakeDamage(damageAmount * Settings.DamageReduction, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		entity:SetColor(mod.Colors.ArmorFlash, 2, 0, false, false)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.RagMegaDMG, EntityType.ENTITY_RAG_MEGA)

-- Kill any Raglings on death
function mod:RagMegaDeath(entity)
	if entity.Variant == 0 then
		for i, ragling in pairs(Isaac.FindByType(EntityType.ENTITY_RAGLING, 1)) do
			ragling:Kill()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.RagMegaDeath, EntityType.ENTITY_RAG_MEGA)





--[[ Plasma balls ]]--
function mod:RagPlasmaInit(entity)
	if entity.Variant == mod.Entities.RagPlasma then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)

		entity.V1 = Vector(Settings.OrbitSpeed, Settings.OrbitDistance) -- Distance from parent
		entity.State = NpcState.STATE_IDLE
		entity.SplatColor = mod.Colors.PurpleFade
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.RagPlasmaInit, mod.Entities.Type)

function mod:RagPlasmaUpdate(entity)
	if entity.Variant == mod.Entities.RagPlasma then
		if not entity.Parent or not entity.Parent:Exists() or entity.Parent:IsDead() then
			entity:Kill()
			mod:PlaySound(nil, SoundEffect.SOUND_REDLIGHTNING_ZAP_BURST, 0.75)

		else
			local sprite = entity:GetSprite()
			mod:LoopingAnim(sprite, "Idle")



			--[[ Idle / Curled up attack ]]--
			if entity.State == NpcState.STATE_IDLE or entity.State == NpcState.STATE_ATTACK then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				mod:OrbitParent(entity, entity.Parent, entity.V1.X, entity.V1.Y)


				-- Curled up attack
				if entity.State == NpcState.STATE_ATTACK then
					if entity.StateFrame <= 0 then
						-- Increase orbit distance
						if entity.I1 == 0 then
							local distance = math.min(Settings.MaxOrbitDistance, entity.V1.Y + Settings.DistanceChangeSpeed)
							entity.V1 = Vector(entity.V1.X, distance)

							if entity.V1.Y >= Settings.MaxOrbitDistance then
								entity.I1 = 1
								entity.StateFrame = Settings.MaxDistanceTime
							end


						-- Decrease orbit distance
						elseif entity.I1 == 1 then
							local distance = math.max(Settings.OrbitDistance, entity.V1.Y - Settings.DistanceChangeSpeed)
							entity.V1 = Vector(entity.V1.X, distance)

							if entity.V1.Y <= Settings.OrbitDistance then
								entity.I2 = entity.I2 + 1

								-- Stop if it did it enough times
								if entity.I2 < Settings.DistanceIncreases then
									entity.I1 = 0
									entity.StateFrame = Settings.MaxDistanceTime / 2
								end
							end
						end

					else
						entity.StateFrame = entity.StateFrame - 1
					end


					-- Set the orbit speed based on the distance
					local distanceMulti = (entity.V1.Y - Settings.OrbitDistance) / (Settings.MaxOrbitDistance - Settings.OrbitDistance)
					local extraSpeed = (Settings.MaxOrbitSpeed - Settings.OrbitSpeed) * distanceMulti
					entity.V1 = Vector(Settings.OrbitSpeed + extraSpeed, entity.V1.Y)
				end



			--[[ Ball sucking attack ]]--
			-- Move diagonally
			elseif entity.State == NpcState.STATE_MOVE then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				mod:MoveDiagonally(entity, Settings.BallSpeed)

			-- Slow down
			elseif entity.State == NpcState.STATE_STOMP then
				entity.Velocity = mod:StopLerp(entity.Velocity, 0.1)

			-- Go to parent
			elseif entity.State == NpcState.STATE_JUMP then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.Parent.Position - entity.Position):Resized(Settings.SuckSpeed), 0.1)
			end



			-- Update the sprite trail if it exists
			local data = entity:GetData()

			if data.spriteTrail then
				data.spriteTrail.Velocity = entity.Position + Vector(0, -36) - data.spriteTrail.Position
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.RagPlasmaUpdate, mod.Entities.Type)