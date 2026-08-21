local mod = ReworkedFoes

local Settings = {
	NewHP = 240,
	Cooldown = 90,
	TeleportCooldown = 150,

	MoveSpeed = 5.5,
	ChaseSpeed = 6.5,

	ChaseTime = 120,
	CreepTime = 100,

	MinShootDistance = 240,
	TransparencyTimer = 10,
	GhostExplosionRadius = 60,
	GhostExplosionDamage = 40,
}



function mod:BlightedOvumInit(entity)
	if entity.Variant == 2 or entity.Variant == 12 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown / 2, Settings.Cooldown * 2)

		-- Contusion
		if entity.Variant == 2 and not mod:IsFFChampion(entity, "RedBlightedOvum") then
			mod:ChangeMaxHealth(entity, Settings.NewHP)

		-- Suture
		elseif entity.Variant == 12 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE

			-- Blue champion
			if mod:IsFFChampion(entity, "BlueBlightedOvumBaby") then
				entity.StateFrame = Settings.TeleportCooldown
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlightedOvumInit, EntityType.ENTITY_GEMINI)

function mod:BlightedOvumUpdate(entity)
	if entity.Variant == 2 or entity.Variant == 12 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		--[[ Contusion ]]--
		if entity.Variant == 2 then
			local createCreep = mod:IsFFChampion(entity, "RedBlightedOvum")

			if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK
			or entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3 then
				local speed = Settings.MoveSpeed
				local anim = "IdleHead"


				-- 2nd phase
				if entity.I1 == 1 then
					-- Effects
					if entity:IsFrame(2, 0) then
						for i = 1, 3 do
							local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, entity.Position, Vector.Zero, entity):ToEffect()
							local scaler = math.random(70, 90) / 100
							trail.SpriteScale = Vector(scaler, scaler)
							trail.SpriteOffset = Vector(math.random(-8, 8), math.random(20, 26) * -1)
							trail.DepthOffset = entity.DepthOffset - 50
							trail:GetSprite().Color = mod.Colors.GhostTrail
							trail:Update()
						end
					end

					-- Spit attack
					if entity.State == NpcState.STATE_ATTACK2 then
						anim = "Shoot"

						if sprite:IsOverlayPlaying("Shoot") then
							if sprite:GetOverlayFrame() == 16 then
								local params = ProjectileParams()
								params.BulletFlags = ProjectileFlags.GHOST
								entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(12), 3, params)

								mod:ShootEffect(entity, 5, Vector(0, -30), Color(0,0,0, 0.5, 0.5,0.5,0.5))
								mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0.9)

							elseif sprite:GetOverlayFrame() == 31 then
								entity.State = NpcState.STATE_MOVE
								entity.ProjectileCooldown = Settings.Cooldown
							end
						end

					-- Chase
					else
						anim = "HeadPossessed"

						-- Ghostly chase
						if entity.State == NpcState.STATE_ATTACK3 then
							speed = Settings.ChaseSpeed
							entity:SetColor(Color(1,1,1, 0.5, 0.25,0.25,0.25), 10, 1, true, false)
						end
					end

				-- 1st phase chase
				elseif entity.State == NpcState.STATE_ATTACK then
					anim = "RageBody"
					speed = Settings.ChaseSpeed
					createCreep = not mod:IsFFChampion(entity, "BlueBlightedOvum")
				end


				-- Movement
				mod:ChasePlayer(entity, speed)

				-- Animations
				entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
				mod:LoopingOverlay(sprite, anim)


				-- Timers
				if entity.ProjectileCooldown <= 0 then
					-- Attack cooldown
					if entity.State == NpcState.STATE_MOVE then
						-- 2nd phase
						if entity.I1 == 1 then
							if mod:Random(1) == 1 then
								entity.State = NpcState.STATE_ATTACK2
							else
								entity.State = NpcState.STATE_ATTACK3
								entity.ProjectileCooldown = Settings.ChaseTime
								entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
								mod:PlaySound(entity, SoundEffect.SOUND_BEAST_GHOST_DASH)
							end

						-- 1st phase
						else
							entity.State = NpcState.STATE_ATTACK
							entity.ProjectileCooldown = Settings.ChaseTime
							mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_B, 0.8)
						end

					-- Chase timer
					elseif entity.State == NpcState.STATE_ATTACK
					or (entity.State == NpcState.STATE_ATTACK3 and room:GetGridCollisionAtPos(entity.Position) == GridCollisionClass.COLLISION_NONE) then
						if entity.State == NpcState.STATE_ATTACK3 then
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
							mod:PlaySound(entity, SoundEffect.SOUND_BEAST_GHOST_DASH, 0.75, 0.9)
						end

						entity.State = NpcState.STATE_MOVE
						entity.ProjectileCooldown = Settings.Cooldown
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


				-- Transition to the 2nd phase
				if not mod:IsFFChampion(entity, "BlueBlightedOvum")
				and entity.I1 == 0 and entity.HitPoints <= (entity.MaxHitPoints / 2) then
					if entity:GetData().wasDelirium then
						entity.I1 = 1

					else
						entity.State = NpcState.STATE_SPECIAL
						sprite:PlayOverlay("Transition1", true)

						entity:BloodExplode()
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity)
						mod:PlaySound(nil, SoundEffect.SOUND_DEATH_BURST_LARGE)
						mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS)

						-- Red champion shots
						if mod:IsFFChampion(entity, "RedBlightedOvum") then
							entity:FireProjectiles(entity.Position, Vector(12, 8), 8, ProjectileParams())
						end
					end
				end


			-- Transitioning
			elseif entity.State == NpcState.STATE_SPECIAL then
				entity.Velocity = mod:StopLerp(entity.Velocity)
				entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

				if sprite:IsOverlayFinished("Transition1") then
					entity.State = NpcState.STATE_IDLE
				elseif sprite:IsOverlayFinished("Transition2") then
					entity.State = NpcState.STATE_MOVE
					entity.I1 = 1
					entity.ProjectileCooldown = Settings.Cooldown
				end

			-- Run away
			elseif entity.State == NpcState.STATE_IDLE then
				mod:AvoidPlayer(entity, 160, Settings.MoveSpeed / 2, Settings.MoveSpeed)
				entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
				mod:LoopingOverlay(sprite, "HeadHalf")


			-- Swapping places
			elseif entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_STOMP then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					if entity.State == NpcState.STATE_JUMP then
						entity.State = NpcState.STATE_STOMP
						sprite:Play("TeleportDown", true)
						mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL1)

						-- Set the new position
						local newPos = mod:GetMirroredPosition(entity.Position)
						entity.Position = room:FindFreeTilePosition(newPos, 0)

						-- Set the child's state
						if entity.Child and entity.Child.Type == entity.Type and entity.Child.Variant == 12 then
							entity.Child:ToNPC().State = NpcState.STATE_STOMP
							entity.Child:GetSprite():Play("TeleportDown", true)
						end

					-- Go back to the previous state
					elseif entity.State == NpcState.STATE_STOMP then
						entity.State = entity.I2
					end
				end
			end


			-- Creep
			if createCreep and entity:IsFrame(4, 0) then
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 1, Settings.CreepTime)
			end





		--[[ Suture ]]--
		elseif entity.Variant == 12 then
			-- Transparency
			if entity.I2 > 0 then
				sprite.Color = mod.Colors.GhostTransparent
				entity.I2 = entity.I2 - 1
			else
				sprite.Color = Color.Default
			end


			-- Die if it has no parent
			if not entity.Parent or not entity.Parent:Exists() then
				entity.Visible = true
				entity.State = NpcState.STATE_DEATH
				sprite:Play("Death", true)
			end


			if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK
			or entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_STOMP then
				-- Haunt Contusion when entering the 2nd phase
				if not mod:IsFFChampion(entity, "RedBlightedOvumBaby") and entity.Parent:ToNPC().State == NpcState.STATE_IDLE then
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("Haunt", true)
				end


				-- Mirror the parent's position
				if mod:IsFFChampion(entity, "BlueBlightedOvumBaby") then
					entity.Position = mod:GetMirroredPosition(entity.Parent.Position)
					entity.Velocity = -entity.Parent.Velocity

				-- Orbit parent
				else
					mod:OrbitParent(entity, entity.Parent, 3.5, 30)
				end

				-- Set the sprite direction
				if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK then
					mod:FlipTowardsTarget(entity, sprite)
				end


				-- Idle
				if entity.State == NpcState.STATE_MOVE then
					mod:LoopingAnim(sprite, "Walk01")

					-- Swap positions with the parent
					local allowShooting = true

					if mod:IsFFChampion(entity, "BlueBlightedOvumBaby")
					and entity.Parent.Type == entity.Type and entity.Parent.Variant == 2 then
						if entity.StateFrame <= 0 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play("TeleportUp", true)
							mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL1)

							entity.StateFrame = Settings.TeleportCooldown
							allowShooting = false

							-- Set the state for the parent
							local parent = entity.Parent:ToNPC()
							parent.I2 = parent.State
							parent.State = NpcState.STATE_JUMP
							parent.Velocity = Vector.Zero

							local parentSprite = parent:GetSprite()
							parentSprite:Play("TeleportUp", true)
							parentSprite:RemoveOverlay()

						else
							entity.StateFrame = entity.StateFrame - 1
						end
					end

					-- Shoot
					if entity.ProjectileCooldown <= 0 then
						if allowShooting and (mod:IsFFChampion(entity, "BlueBlightedOvumBaby")
						or entity.Position:Distance(target.Position) <= Settings.MinShootDistance) then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("Attack01", true)
							entity.ProjectileCooldown = Settings.Cooldown
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end


				-- Shoot
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:IsEventTriggered("Shoot") then
						local params = ProjectileParams()
						local shootMode = 0
						local speed = (mod:IsFFChampion(entity, "RedBlightedOvumBaby") or mod:IsFFChampion(entity, "BlueBlightedOvumBaby")) and 11 or 12
						local effectColor

						-- Blue champion
						if mod:IsFFChampion(entity, "BlueBlightedOvumBaby") then
							shootMode = 3
							params.Variant = ProjectileVariant.PROJECTILE_TEAR
							params.BulletFlags = ProjectileFlags.NO_WALL_COLLIDE
							params.Color = mod.Colors.SoulShot
							effectColor = Color(1,1,1, 0.6, 0.1,0.2,0.4, 1,1,1, 1)

						-- Regular
						elseif not mod:IsFFChampion(entity, "RedBlightedOvumBaby") then
							params.BulletFlags = ProjectileFlags.GHOST
							effectColor = Color(0,0,0, 0.5, 0.5,0.5,0.5)
						end

						local velocity = (target.Position - entity.Position):Resized(speed)
						entity:FireProjectiles(entity.Position, velocity, shootMode, params)
						mod:ShootEffect(entity, 5, Vector(0, -20), effectColor)
						mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0.9)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end


				-- Swapping places
				elseif entity.State == NpcState.STATE_JUMP then
					local parentSprite = entity.Parent:GetSprite()

					if parentSprite:GetAnimation() == sprite:GetAnimation() then
						sprite:SetFrame( parentSprite:GetFrame() )
					end

				elseif entity.State == NpcState.STATE_STOMP then
					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end
				end


			-- Haunt
			elseif entity.State == NpcState.STATE_SPECIAL then
				if entity.I1 == 0 then
					entity.Velocity = mod:StopLerp(entity.Velocity)
				elseif entity.I1 == 1 then
					entity.Position = entity.Parent.Position
					entity.Velocity = entity.Parent.Velocity
				end

				-- Start following the parent
				if sprite:IsEventTriggered("Shoot") then
					entity.I1 = 1
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					mod:PlaySound(nil, SoundEffect.SOUND_BEAST_GHOST_DASH)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
					entity.Parent:SetColor(Color(1,1,1, 1, 0.4,0.4,0.4), 8, 1, true, false)
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 1.1)

					-- Set the state for the parent
					if entity.Parent.Type == entity.Type and entity.Parent.Variant == 2 then
						entity.Parent:ToNPC().State = NpcState.STATE_SPECIAL
						entity.Parent:GetSprite():PlayOverlay("Transition2", true)
					end
				end

			-- Haunting
			elseif entity.State == NpcState.STATE_IDLE then
				entity.Position = entity.Parent.Position
				entity.Velocity = entity.Parent.Velocity
				entity.Visible = false
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlightedOvumUpdate, EntityType.ENTITY_GEMINI)

function mod:BlightedOvumDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 12 then
		entity:ToNPC().I2 = Settings.TransparencyTimer
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BlightedOvumDMG, EntityType.ENTITY_GEMINI)

function mod:BlightedOvumDeath(entity)
	-- Red champion shots on death
	if entity.Variant == 2 and mod:IsFFChampion(entity, "RedBlightedOvum") then
		entity:FireProjectiles(entity.Position, Vector(12, 8), 8, ProjectileParams())


	-- Suture ghost explosion on death
	elseif entity.Variant == 12 then
		-- Damage entities in its radius
		local colliders = Isaac.FindInRadius(entity.Position, Settings.GhostExplosionRadius, EntityPartition.FAMILIAR | EntityPartition.ENEMY | EntityPartition.PLAYER)

		for i, collider in pairs(colliders) do
			if collider.EntityCollisionClass >= EntityCollisionClass.ENTCOLL_ENEMIES then
				-- Get the amount of damage to deal
				local damage = Settings.GhostExplosionDamage
				if collider:ToPlayer() then -- To players
					damage = 1
				end

				collider:TakeDamage(damage, DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(entity), 0)
			end
		end

		-- Effects
		local subType = mod:IsFFChampion(entity, "RedBlightedOvumBaby") and 1 or 2
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, subType, entity.Position, Vector.Zero, entity)
		mod:PlaySound(nil, SoundEffect.SOUND_DEMON_HIT)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.BlightedOvumDeath, EntityType.ENTITY_GEMINI)