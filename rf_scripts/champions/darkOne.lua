local mod = BetterMonsters



function mod:darkOneUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		-- Particles
		if entity.I2 == 0 then
			mod:SmokeParticles(entity, Vector(0, -30), 15, Vector(100, 120), Color.Default, "effects/effect_088_darksmoke_black")
		end


		-- Teleport effect
		local function teleportPoof()
			local smokeColor = Color(0,0,0, 1)
			smokeColor:SetColorize(1, 1, 1, 1)

			local poofColor = Color(0,0,0, 0.5)
			poofColor:SetColorize(1, 1, 1, 1)


			local smoke = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FART, 2, entity.Position, Vector.Zero, entity):GetSprite()
			smoke.Color = smokeColor
			smoke.Offset = Vector(0, -10)
			SFXManager():Stop(SoundEffect.SOUND_FART)

			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, entity.Position, Vector.Zero, entity):GetSprite()
			poof.Color = poofColor
			poof.Offset = Vector(0, -10)
			poof.Scale = Vector(0.85, 0.85)

			mod:PlaySound(nil, SoundEffect.SOUND_BLACK_POOF)
		end


		-- Enable permanent darkness
		if entity.State == NpcState.STATE_SPECIAL then
			if data.darkened then
				entity.State = NpcState.STATE_IDLE
			end

			if sprite:GetFrame() == 10 then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_0)

			elseif sprite:GetFrame() == 36 then
				data.darkened = true
				entity.ProjectileCooldown = 30
			end

		elseif not data.darkened then
			entity.State = NpcState.STATE_SPECIAL
			sprite:Play("Darkness", true)
		end

		if data.darkened then
			Game():Darken(1, 45)
		end


		-- Override default idle behaviour
		if entity.State == NpcState.STATE_MOVE then
			entity.State = NpcState.STATE_IDLE

		elseif entity.State == NpcState.STATE_IDLE then
			mod:WanderAround(entity, 2.25)
			mod:LoopingAnim(sprite, "Walk")

			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_JUMP
				sprite:Play("Attack1", true)
				entity.StateFrame = 0
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Teleport and choose an attack
		elseif entity.State == NpcState.STATE_JUMP then
			-- Teleport away
			if entity.StateFrame == 0 then
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)
				end

				if sprite:GetFrame() == 27 then
					entity.StateFrame = 1
					entity.Visible = false
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					teleportPoof()

					entity.I2 = 1
					entity.ProjectileCooldown = 45
				end

			-- Stay hidden
			elseif entity.StateFrame == 1 then
				-- Choose attack
				if entity.ProjectileCooldown == 10 then
					local highest = 2
					if target.Position.Y < room:GetTopLeftPos().Y + 60 then
						highest = 1
					end
					entity.I1 = mod:Random(highest)

					-- Projectiles
					if entity.I1 == 0 then
						entity.V1 = target.Position + (room:GetCenterPos() - target.Position):Resized(240)

					-- Charge
					elseif entity.I1 == 1 then
						local posLeft = Vector(room:GetTopLeftPos().X, target.Position.Y)
						local posRight = Vector(room:GetBottomRightPos().X, target.Position.Y)

						if target.Position:Distance(posLeft) < target.Position:Distance(posRight) then
							entity.V1 = posRight
						else
							entity.V1 = posLeft
						end

					-- Brimstone
					elseif entity.I1 == 2 then
						entity.V1 = Vector(target.Position.X, room:GetTopLeftPos().Y)
					end

					entity.Position = room:FindFreePickupSpawnPosition(entity.V1, 40, false, false)
					entity.I2 = 0
				end

				-- Appear
				if entity.ProjectileCooldown <= 0 then
					entity.StateFrame = 2
					entity.Visible = true
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
					teleportPoof()

					sprite:Play("Darkness", true)
					sprite:SetFrame(3)
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_0)

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end

			-- Appear and perform chosen attack
			elseif entity.StateFrame == 2 then
				if sprite:IsFinished() then
					local cooldown = 60

					-- Projectiles
					if entity.I1 == 0 then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("Attack1", true)
						cooldown = 45

					-- Charge
					elseif entity.I1 == 1 then
						entity.State = NpcState.STATE_ATTACK3
						sprite:Play("Charge", true)
						mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)

						entity.StateFrame = 0
						entity.TargetPosition = entity.Position

						-- Charge towards the target
						mod:FlipTowardsTarget(entity, sprite)

					-- Brimstone
					elseif entity.I1 == 2 then
						entity.State = NpcState.STATE_ATTACK2
						sprite:Play("Attack2", true)
					end

					entity.ProjectileCooldown = cooldown
				end
			end


		-- Harder brimstone attack
		elseif entity.State == NpcState.STATE_ATTACK2 and sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Color = IRFcolors.BrimShot
			params.Scale = 1.25
			params.CircleAngle = 0
			mod:FireProjectiles(entity, Vector(entity.Position.X, room:GetBottomRightPos().Y - 1), Vector(11, 12), 9, params, Color.Default)
		end


		-- Splat color
		if entity:HasMortalDamage() then
			entity.SplatColor = Color(0,0,0, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.darkOneUpdate, EntityType.ENTITY_DARK_ONE)