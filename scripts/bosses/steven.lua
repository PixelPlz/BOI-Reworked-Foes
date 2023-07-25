local mod = BetterMonsters

local Settings = {
	Cooldown = 90,
	TeleportCooldown = 120,

	MoveSpeed = 5,
	ChaseSpeed = 12,

	ChaseTime = 180,
	TeleportTime = 15,

	LilStevenMaxDistance = 20,

	SecondPhaseHP = 100,
	Gravity = 0.5,
}



function mod:stevenInit(entity)
	if entity.Variant == 1 or entity.Variant == 11 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown / 2, Settings.Cooldown * 2)

		-- Big Steven
		if entity.Variant == 1 then
			entity.I2 = Settings.TeleportCooldown

		-- Little Steven
		elseif entity.Variant == 11 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

			entity.SpawnerEntity.Child = entity
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.stevenInit, EntityType.ENTITY_GEMINI)

function mod:stevenUpdate(entity)
	if entity.Variant == 1 or entity.Variant == 11 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		--[[ Big Steven ]]--
		if entity.Variant == 1 then
			-- When you're walkin'
			if entity.State == NpcState.STATE_MOVE then
				mod:ChasePlayer(entity, Settings.MoveSpeed)

				if entity.Velocity:Length() > 0.1 then
					mod:LoopingAnim(sprite, "Walk" .. mod:GetDirectionString(entity.Velocity:GetAngleDegrees(), true))
					mod:FlipTowardsMovement(entity, sprite)
				else
					mod:LoopingAnim(sprite, "Idle")
				end

				-- Teleport
				if entity.I2 <= 0 then
					entity.I2 = Settings.TeleportTime
					entity.State = NpcState.STATE_JUMP
					sprite:Play("TeleportStart", true)
					entity.StateFrame = 0

					mod:PlaySound(entity, IRFsounds.StevenVoice, 1.3)
					mod:PlaySound(nil, IRFsounds.StevenTP, 1.1, 1, 0, true)

				else
					entity.I2 = entity.I2 - 1
				end

				-- Start rolling
				if entity.ProjectileCooldown <= 0 then
					if entity.Pathfinder:HasPathToPos(target.Position) and entity.State ~= NpcState.STATE_JUMP then -- Teleporting has a higher priority over rolling
						entity.ProjectileCooldown = Settings.ChaseTime
						entity.State = NpcState.STATE_ATTACK
						entity.StateFrame = 0
						sprite:Play("RollStart", true)
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- They see me rollin', they Stevin'
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Start
				if entity.StateFrame == 0 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(nil, IRFsounds.StevenLand, 1.5)
					end
					if sprite:IsFinished() then
						entity.StateFrame = 1
					end

				-- Rollin'
				elseif entity.StateFrame == 1 then
					-- This sucks
					local speed = Settings.ChaseSpeed
					-- Reverse movement if feared
					if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
						speed = -speed
					end

					-- Move randomly if confused
					if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
						mod:WanderAround(entity, speed / 2)

					else
						-- If there is a path to the player
						if entity.Pathfinder:HasPathToPos(target.Position) then
							-- If there is a direct line to the player
							if Game():GetRoom():CheckLine(entity.Position, target.Position, 1, 0, false, false) then
								entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Resized(speed), 0.04)

							else
								local before = entity.Velocity
								entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
								local after = entity.Velocity * 6

								entity.Velocity = mod:Lerp(before, after, 0.045)
							end

						-- Otherwise stay still
						else
							entity.Velocity = mod:StopLerp(entity.Velocity)
						end
					end

					mod:LoopingAnim(sprite, "Roll" .. mod:GetDirectionString(entity.Velocity:GetAngleDegrees(), true))
					mod:FlipTowardsMovement(entity, sprite)

					-- Cooldown
					if entity.ProjectileCooldown <= 0 then
						entity.StateFrame = 2
						sprite:Play("RollEnd", true)

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end

				-- Stop
				elseif entity.StateFrame == 2 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(nil, IRFsounds.StevenLand, 1.25)
					end
					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
						entity.ProjectileCooldown = Settings.Cooldown
					end
				end


			-- Teleport
			elseif entity.State == NpcState.STATE_JUMP then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Start
				if entity.StateFrame == 0 then
					if sprite:IsFinished() then
						entity.StateFrame = 1

						-- Get teleport position
						entity.TargetPosition = Vector(room:GetBottomRightPos().X + (room:GetTopLeftPos().X - entity.Position.X), room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - entity.Position.Y))
						entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)

						-- Effect
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, 132, 1, entity.TargetPosition, Vector.Zero, entity):GetSprite()
						entity:GetData().effect = effect
						effect:Load("gfx/steven silhouette.anm2", true)
						effect:Play("Appear", true)
					end

				-- Loop
				elseif entity.StateFrame == 1 then
					mod:LoopingAnim(sprite, "TeleportLoop")

					-- Effect
					local effect = entity:GetData().effect
					if effect:IsPlaying("Appear") and effect:GetFrame() == 3 then
						mod:LoopingAnim(effect, "Idle")
					end

					-- Cooldown
					if entity.I2 <= 0 then
						entity.StateFrame = 2
						sprite:Play("Teleport", true)

					else
						entity.I2 = entity.I2 - 1
					end

				-- Teleport
				elseif entity.StateFrame == 2 then
					if sprite:IsEventTriggered("Shoot") then
						-- Projectiles
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_FCUK
						params.BulletFlags = ProjectileFlags.GHOST
						entity:FireProjectiles(entity.Position, Vector(11, 4), 6, params)

						-- Poof
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, entity.Position, Vector.Zero, entity):GetSprite()
						effect.Color = Color(1,1,1, 1, 1,1,1)
						effect.Offset = Vector(0, -16)

						-- Silhouette
						entity:GetData().effect:Play("Disappear", true)
						entity:GetData().effect = nil

						-- Sounds
						mod:PlaySound(nil, IRFsounds.StevenChange, 2.75, 1.05)
						SFXManager():StopLoopingSounds()

						entity.Position = entity.TargetPosition
						entity.Child.Position = entity.Position
						entity.Child:ToNPC().ProjectileCooldown = entity.Child:ToNPC().ProjectileCooldown + 30
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
						entity.I2 = Settings.TeleportCooldown
					end
				end


			-- 2nd phase
			elseif entity.State == NpcState.STATE_SPECIAL then
				entity.Position = room:GetCenterPos()
				entity.Velocity = Vector.Zero

				-- Wait before starting
				if entity.StateFrame == 0 then
					if entity.I2 <= 0 then
						entity.StateFrame = 1

						-- Static effect
						if not IRF_Steven_Static then
							IRF_Steven_Static = Sprite()
							IRF_Steven_Static:Load("gfx/steven static.anm2", true)
							mod:PlaySound(nil, IRFsounds.StevenChange, 2.75, 1.05)
						end

					else
						entity.I2 = entity.I2 - 1
					end

				-- Give birth to Wallaces
				elseif entity.StateFrame == 1 then
					if entity.ProjectileCooldown <= 0 then
						entity.ProjectileCooldown = 25
						entity.I2 = entity.I2 + 1

						for i = -1, 1, 2 do
							local pos = room:GetTopLeftPos() - Vector(80, -15)
							if i == 1 then
								pos = room:GetBottomRightPos() + Vector(80, -15)
							end

							local wallace = Isaac.Spawn(IRFentities.Type, IRFentities.Wallace, entity.SubType, pos, Vector.Zero, entity):ToNPC()
							wallace.Parent = entity
							wallace.TargetPosition = Vector(-i, 0)

							if entity.I2 % 3 == 0 then
								wallace.I1 = mod:Random(1, 2)
							end

							wallace.ProjectileCooldown = mod:Random(20, 50)
							wallace.V1 = pos
							wallace.I2 = i

							wallace:GetSprite().FlipY = i == -1
							wallace:GetSprite().Color = Color(1,1,1, 0)
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end
			end





		--[[ Little Steven ]]--
		elseif entity.Variant == 11 then
			-- Die without a parent
			if not entity.Parent or entity.Parent:IsDead() then
				entity:Die()


			-- Big bro is alive :)
			else
				entity.HitPoints = entity.Parent.HitPoints

				-- Movement
				local distance = entity.Parent.Size + entity.Size + Settings.LilStevenMaxDistance

				if entity.Position:Distance(entity.Parent.Position) > distance then
					entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (entity.Position - entity.Parent.Position):Resized(distance), 0.2)
				end

				entity.Velocity = Vector.Zero
				mod:FlipTowardsTarget(entity, sprite)


				-- Idle
				if entity.State == NpcState.STATE_MOVE then
					mod:LoopingAnim(sprite, "Walk01")

					-- Shoot
					if entity.ProjectileCooldown <= 0 then
						if entity.Position:Distance(target.Position) <= 240 and not (entity.Parent:ToNPC().State == NpcState.STATE_JUMP and entity.Parent:ToNPC().StateFrame > 0) then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("Attack01", true)
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end


				-- Shoot
				elseif entity.State == NpcState.STATE_ATTACK then
					if sprite:IsEventTriggered("Shoot") then
						local params = ProjectileParams()
						params.Variant = ProjectileVariant.PROJECTILE_FCUK
						params.BulletFlags = ProjectileFlags.GHOST
						entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(12), 0, params)
						mod:PlaySound(entity, IRFsounds.StevenDie)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
						entity.ProjectileCooldown = Settings.Cooldown
					end
				end
			end
		end


		if entity.FrameCount > 1 then
			if entity.Variant == 1 and entity:IsDead() and entity.State ~= NpcState.STATE_SPECIAL then
				mod:PlaySound(nil, IRFsounds.StevenDie, 1.25)

				-- Start 2nd phase
				local newSteven = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, room:GetCenterPos(), Vector.Zero, entity):ToNPC()
				newSteven.State = NpcState.STATE_SPECIAL
				newSteven.I2 = 50
				newSteven.ProjectileCooldown = 0

				newSteven.Visible = false
				newSteven.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				newSteven.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
				newSteven:AddEntityFlags(EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

				newSteven.MaxHitPoints = Settings.SecondPhaseHP
				newSteven.HitPoints = newSteven.MaxHitPoints

				-- Silhouette fix
				if entity:GetData().effect then
					entity:GetData().effect:Play("Disappear", true)
				end

			else
				return true
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.stevenUpdate, EntityType.ENTITY_GEMINI)

function mod:lilStevenDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 11 then
		damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES
		target.Parent:TakeDamage(damageAmount, damageFlags, damageSource, 5)
		target:SetColor(IRFcolors.DamageFlash, 2, 0, false, true)

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.lilStevenDMG, EntityType.ENTITY_GEMINI)



--[[ Wallace ]]--
function mod:wallaceInit(entity)
	if entity.Variant == IRFentities.Wallace then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

		entity.State = NpcState.STATE_MOVE
		entity.SplatColor = Color(0,0,0, 1)

		-- Off-screen inficator blacklist
		if OffscreenIndicators then
			OffscreenIndicators:addOIblacklist(entity.Type, entity.Variant, -1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.wallaceInit, IRFentities.Type)

function mod:wallaceUpdate(entity)
	if entity.Variant == IRFentities.Wallace then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		-- Die without a parent
		if not entity.Parent or entity.Parent:IsDead() then
			--entity:Die()
			entity.State = NpcState.STATE_UNIQUE_DEATH
			sprite:Play("WallaceDeath", true)


		-- Steven is alive :)
		else
			entity.HitPoints = entity.Parent.HitPoints

			-- Stroll across the screen
			entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition:Resized(Settings.MoveSpeed), 0.25)
			mod:FlipTowardsMovement(entity, sprite)


			-- Fade in / out
			local alphaModifier = (room:GetTopLeftPos().X - entity.Position.X) * 0.025
			if entity.Position.X > room:GetCenterPos().X then
				alphaModifier = (entity.Position.X - room:GetBottomRightPos().X) * 0.025
			end
			sprite.Color = Color(1,1,1, math.min(1, 1 - alphaModifier))

			-- Despawn if far enough outside the room
			if room:IsPositionInRoom(entity.Position, -80) == false then
				entity:Remove()
			end


			-- Conga line
			if entity.State == NpcState.STATE_MOVE then
				local anim = "WallWalk"
				if entity.I1 == 1 then
					anim = "BabyWalk"
				end
				mod:LoopingAnim(sprite, anim)

				-- Attacking variants
				if entity.I1 > 0 and entity.StateFrame == 0 then
					if entity.ProjectileCooldown <= 0 then
						-- Shoot
						if entity.I1 == 1 then
							entity.State = NpcState.STATE_ATTACK
							sprite:Play("ShootWalk", true)

						-- Jump
						elseif entity.I1 == 2 then
							entity.State = NpcState.STATE_JUMP
							sprite:Play("RollJump", true)
							entity.StateFrame = 0
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end


			-- Shoot
			elseif entity.State == NpcState.STATE_ATTACK then
				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_FCUK
					params.BulletFlags = ProjectileFlags.GHOST
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(12), 0, params)
					mod:PlaySound(entity, IRFsounds.StevenDie)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.StateFrame = 1
				end


			-- Jump
			elseif entity.State == NpcState.STATE_JUMP then
				-- Update height
				local data = entity:GetData()
				if data.zVelocity then
					data.zVelocity = data.zVelocity - Settings.Gravity
					entity.Position = Vector(entity.Position.X, math.min(room:GetBottomRightPos().Y + 12, entity.Position.Y - data.zVelocity * entity.I2))
				end

				if entity.StateFrame == 0 then
					-- Jump velocity
					if sprite:IsEventTriggered("Shoot") then
						entity:GetData().zVelocity = 12
						entity.StateFrame = 1
						mod:PlaySound(entity, IRFsounds.StevenVoice, 0.8, 1, 5)
						mod:PlaySound(nil, IRFsounds.StevenLand, 1.5)
					end

				elseif entity.StateFrame == 1 then
					if data.zVelocity and data.zVelocity <= 1 then
						entity.StateFrame = 2
						sprite:Play("JumpDown", true)
					end

				elseif entity.StateFrame == 2 then
					-- Land
					if sprite:IsFinished() and ((entity.I2 == 1 and entity.Position.Y >= entity.V1.Y) or (entity.I2 == -1 and entity.Position.Y <= entity.V1.Y)) then
						entity.State = NpcState.STATE_MOVE
						entity.StateFrame = 1

						-- Effects
						mod:PlaySound(nil, IRFsounds.StevenLand, 2)
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position + Vector(0, entity.I2 * 30), Vector.Zero, entity):GetSprite()
						effect.Color = Color(0,0,0, 0.5)
						effect.Scale = Vector(0.6, 0.6)
						effect.FlipY = entity.I2 == -1
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wallaceUpdate, IRFentities.Type)

function mod:wallaceDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == IRFentities.Wallace then
		damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES
		target.Parent:TakeDamage(damageAmount, damageFlags, damageSource, 5)
		target:SetColor(IRFcolors.DamageFlash, 2, 0, false, true)

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.wallaceDMG, IRFentities.Type)



function mod:stevenStaticOverlay()
	if IRF_Steven_Static then
		IRF_Steven_Static:Render(Game():GetRoom():GetRenderSurfaceTopLeft(), Vector.Zero, Vector.Zero)
		IRF_Steven_Static:Play("Static", false)
		IRF_Steven_Static:Update()
		
		if IRF_Steven_Static:IsFinished() then
			IRF_Steven_Static = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.stevenStaticOverlay)