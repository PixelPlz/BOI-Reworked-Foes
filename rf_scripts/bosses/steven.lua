local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 5,
	ChaseSpeed = 12,

	Cooldown = 90,
	ChaseTime = 180,
	TeleportCooldown = 120,
	TeleportTime = 15,

	LilStevenMaxDistance = 20,

	-- 2nd phase
	SecondPhaseHP = 100,
	Gravity = 0.5,
	WallaceOffset = Vector(80, -15)
}



function mod:StevenInit(entity)
	if entity.Variant == 1 or entity.Variant == 11 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown / 2, Settings.Cooldown * 2)

		-- Big Steven
		if entity.Variant == 1 then
			entity.I2 = Settings.TeleportCooldown


		-- Little Steven
		elseif entity.Variant == 11 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

			-- If spanwed by Steven
			if entity.SpawnerEntity then
				entity.SpawnerEntity.Child = entity
				entity:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)

			-- If spawned by himself (why must Fiend Folio ruin things once again)
			else
				entity.I1 = 1
				entity:SetColor(Color(1,0,0, 1), -1, 1, false, false)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.StevenInit, EntityType.ENTITY_GEMINI)

function mod:StevenUpdate(entity)
	if entity.Variant == 1 or entity.Variant == 11 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		--[[ Big Steven ]]--
		if entity.Variant == 1 then
			-- When you walkin'
			if entity.State == NpcState.STATE_MOVE then
				mod:ChasePlayer(entity, Settings.MoveSpeed)

				if entity.Velocity:Length() >= 0.5 then
					mod:LoopingAnim(sprite, "Walk" .. mod:GetDirectionString(entity.Velocity:GetAngleDegrees(), true))
					mod:FlipTowardsMovement(entity, sprite)
				else
					mod:LoopingAnim(sprite, "Idle")
				end

				-- Teleport
				if not entity:GetData().wasDelirium then
					if entity.I2 <= 0 then
						entity.I2 = Settings.TeleportTime
						entity.State = NpcState.STATE_JUMP
						sprite:Play("TeleportStart", true)
						entity.StateFrame = 0

						mod:PlaySound(entity, mod.Sounds.StevenVoice, 1.3)
						mod:PlaySound(nil, mod.Sounds.StevenTP, 1.1, 1, 0, true)

					else
						entity.I2 = entity.I2 - 1
					end
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
						mod:PlaySound(nil, mod.Sounds.StevenLand, 1.5)
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
							if room:CheckLine(entity.Position, target.Position, 1, 0, false, false) then
								entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Resized(speed), 0.04)

							else
								local before = entity.Velocity
								entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
								local after = entity.Velocity * 6

								entity.Velocity = mod:Lerp(before, after, 0.045)
							end

						-- Otherwise stay still
						else
							entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.05)
						end
					end

					mod:LoopingAnim(sprite, "Roll" .. mod:GetDirectionString(entity.Velocity:GetAngleDegrees(), true))
					mod:FlipTowardsMovement(entity, sprite)
					sprite.PlaybackSpeed = entity.Velocity:Length() * 0.125

					-- Cooldown
					if entity.ProjectileCooldown <= 0 then
						entity.StateFrame = 2
						sprite:Play("RollEnd", true)
						sprite.PlaybackSpeed = 1

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end

				-- Stop
				elseif entity.StateFrame == 2 then
					entity.Velocity = mod:StopLerp(entity.Velocity)

					if sprite:IsEventTriggered("Shoot") then
						mod:PlaySound(nil, mod.Sounds.StevenLand, 1.25)
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
						mod:PlaySound(nil, mod.Sounds.StevenChange, 2.75, 1.05)
						SFXManager():StopLoopingSounds()

						-- Change position
						entity.Position = entity.TargetPosition
						entity.Child.Position = entity.Position
						entity.Child:ToNPC().ProjectileCooldown = entity.Child:ToNPC().ProjectileCooldown + 30

						-- Trigger Future enemy swap
						if TheFuture then
							Isaac.RunCallbackWithParam("POST_MANTIS_CLAP")
						end
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
				mod:LoopingAnim(sprite, "WalkVert")

				-- Wait before starting
				if entity.StateFrame == 0 then
					if entity.I2 <= 0 then
						entity.StateFrame = 1

						-- Static effect
						if not mod.StevenStatic then
							mod.StevenStatic = Sprite()
							mod.StevenStatic:Load("gfx/steven static.anm2", true)
							mod:PlaySound(nil, mod.Sounds.StevenChange, 2.75, 1.05)
						end

						-- Get rid of rocks in the middle
						if room:GetRoomShape() == RoomShape.ROOMSHAPE_1x1 then
							for i = -1, 1 do
								for j = -2, 2 do
									local pos = room:GetCenterPos() + Vector(i * 40, j * 40)
									room:DestroyGrid(room:GetGridIndex(pos), true)
								end
							end
						end

						-- Looping sound fix
						SFXManager():StopLoopingSounds()

						-- Trigger Future enemy swap
						if TheFuture then
							Isaac.RunCallbackWithParam("POST_MANTIS_CLAP")
						end

					else
						entity.I2 = entity.I2 - 1
					end


				-- Give birth to Wallaces
				elseif entity.StateFrame == 1 then
					if entity.ProjectileCooldown <= 0 then
						entity.ProjectileCooldown = entity.I1
						entity.I2 = entity.I2 + 1

						-- Short rooms only have the top line
						local shape = room:GetRoomShape()
						local maxI = 1

						if shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IIH then
							maxI = -1
						end

						-- -1 = top wall / 1 = bottom wall
						for i = -1, maxI, 2 do
							local pos = room:GetTopLeftPos() - Settings.WallaceOffset
							if i == 1 then
								pos = room:GetBottomRightPos() + Settings.WallaceOffset
							end

							local wallace = Isaac.Spawn(mod.Entities.Type, mod.Entities.Wallace, entity.SubType, pos, Vector.Zero, entity):ToNPC()
							wallace.Parent = entity
							wallace.TargetPosition = Vector(-i, 0)
							wallace.V1 = Vector(i ,pos.Y)

							-- Attacking variants
							if entity.I2 % 3 == 0 then
								wallace.I1 = mod:Random(1, 2)

								local cdMin = 20
								local cdMax = 50

								-- Wide rooms
								if shape >= 6 then
									cdMax = 110
								-- Thin rooms
								elseif shape == RoomShape.ROOMSHAPE_IV or shape == RoomShape.ROOMSHAPE_IIV then
									cdMin = 5
									cdMax = 10
								end

								wallace.ProjectileCooldown = mod:Random(cdMin, cdMax)
							end

							local wallaceSprite = wallace:GetSprite()
							wallaceSprite.FlipY = i == -1
							wallaceSprite.Color = Color(1,1,1, 0)

							-- Delirious fix
							if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
								for j = 0, wallaceSprite:GetLayerCount() do
									wallaceSprite:ReplaceSpritesheet(j, "gfx/bosses/afterbirthplus/deliriumforms/classic/boss_013_steven.png")
								end
								wallaceSprite:LoadGraphics()
							end
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end
			end





		--[[ Little Steven ]]--
		elseif entity.Variant == 11 then
			-- Spawned by himself
			if entity.I1 == 1 then
				mod:ChasePlayer(entity, Settings.MoveSpeed, true)
				mod:FlipTowardsMovement(entity, sprite)


			-- Spawned by Steven
			else
				-- Die without a parent
				if not entity.Parent or entity.Parent:IsDead() then
					entity:Die()
					return true

				-- Big bro is alive :)
				else
					entity.MaxHitPoints = entity.Parent.MaxHitPoints
					entity.HitPoints = entity.Parent.HitPoints

					-- Movement
					local distance = entity.Parent.Size + entity.Size + Settings.LilStevenMaxDistance

					if entity.Position:Distance(entity.Parent.Position) > distance then
						entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (entity.Position - entity.Parent.Position):Resized(distance), 0.2)
					end

					entity.Velocity = Vector.Zero
					mod:FlipTowardsTarget(entity, sprite)
				end
			end


			-- Idle
			if entity.State == NpcState.STATE_MOVE then
				-- Shoot
				if entity.ProjectileCooldown <= 0 then
					if entity.Position:Distance(target.Position) <= 240 and (entity.I1 == 1 or not (entity.Parent:ToNPC().State == NpcState.STATE_JUMP and entity.Parent:ToNPC().StateFrame > 0)) then
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
					mod:PlaySound(entity, mod.Sounds.StevenDeath)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = Settings.Cooldown
				end
			end
		end



		if entity.FrameCount > 1 then
			-- Big Steven death
			if entity.Variant == 1 and entity:IsDead() and entity.State ~= NpcState.STATE_SPECIAL then
				mod:PlaySound(nil, mod.Sounds.StevenDeath, 1.25)

				-- Start 2nd phase
				local hasSteven = false

				-- Increase the hp for an existing one
				for i, steven in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, true)) do
					if steven:ToNPC().State == NpcState.STATE_SPECIAL then
						steven.MaxHitPoints = steven.MaxHitPoints + Settings.SecondPhaseHP
						steven.HitPoints = steven.HitPoints + Settings.SecondPhaseHP
						steven:ToNPC().I1 = steven:ToNPC().I1 - 4

						hasSteven = true
						break
					end
				end

				-- Create a new Steven
				if hasSteven == false then
					local newSteven = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, room:GetCenterPos(), Vector.Zero, entity):ToNPC()
					newSteven.State = NpcState.STATE_SPECIAL
					newSteven.I1 = 30
					newSteven.I2 = 50
					newSteven.ProjectileCooldown = 0

					newSteven.Visible = false
					newSteven.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					newSteven.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
					newSteven:AddEntityFlags(EntityFlag.FLAG_NO_BLOOD_SPLASH | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					newSteven.SplatColor = Color(0,0,0, 0)

					newSteven.MaxHitPoints = Settings.SecondPhaseHP
					newSteven.HitPoints = newSteven.MaxHitPoints
				end

				-- Silhouette fix
				if entity:GetData().effect then
					entity:GetData().effect:Play("Disappear", true)
					SFXManager():StopLoopingSounds()
				end


			-- If not dead Little Steven that spawned by itself
			elseif not (entity.Variant == 11 and entity.I1 == 1 and entity:IsDead()) then
				return true
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.StevenUpdate, EntityType.ENTITY_GEMINI)

function mod:StevenDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- 2nd phase only takes damage when Wallaces take damage
	if entity.Variant == 1 and entity:ToNPC().State == NpcState.STATE_SPECIAL then
		if not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
			return false
		end

	-- Little Steven
	elseif entity.Variant == 11 and entity:ToNPC().I1 ~= 1 then
		if entity.Parent then
			damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES
			entity.Parent:TakeDamage(damageAmount, damageFlags, damageSource, 1)
			entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
		end

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.StevenDMG, EntityType.ENTITY_GEMINI)



--[[ Wallace ]]--
function mod:WallaceInit(entity)
	if entity.Variant == mod.Entities.Wallace then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_REWARD)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR | EntityFlag.FLAG_NO_TARGET)

		entity.State = NpcState.STATE_MOVE
		entity:GetSprite().Offset = Vector(0, 20)
		entity.SplatColor = Color(0,0,0, 1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.WallaceInit, mod.Entities.Type)

function mod:WallaceUpdate(entity)
	if entity.Variant == mod.Entities.Wallace then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		-- Die without a parent
		if not entity.Parent or entity.Parent:IsDead() then
			entity.State = NpcState.STATE_UNIQUE_DEATH
			sprite:Play("WallaceDeath", true)


		-- Steven is alive :)
		else
			entity.MaxHitPoints = entity.Parent.MaxHitPoints
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
				local anim = "WalkHori"
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
							sprite:Play("JumpUp", true)
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
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(11), 0, params)
					mod:PlaySound(entity, mod.Sounds.StevenDeath)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.StateFrame = 1
				end


			-- Jump
			elseif entity.State == NpcState.STATE_JUMP then
				-- Update height
				if entity.StateFrame > 0 then
					entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
					entity.Position = Vector(entity.Position.X, entity.Position.Y - entity.V2.Y * entity.V1.X)
				end

				-- Telegraph
				if entity.StateFrame == 0 then
					if sprite:IsEventTriggered("Shoot") then
						entity.StateFrame = 1
						mod:PlaySound(entity, mod.Sounds.StevenVoice, 0.8, 1, 5)
						mod:PlaySound(nil, mod.Sounds.StevenLand, 1.5)

						-- Get jump height
						local jumpHeight = 12
						local shape = room:GetRoomShape()

						if shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV or shape >= 8 then
							jumpHeight = 15
						elseif shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IIH then
							jumpHeight = 9
						end

						entity.V2 = Vector(0, jumpHeight)
					end

				-- Going up
				elseif entity.StateFrame == 1 then
					-- Peak of the jump
					if entity.V2.Y <= 1 then
						entity.StateFrame = 2
						sprite:Play("JumpDown", true)
					end

				-- Going down
				elseif entity.StateFrame == 2 then
					-- Land
					if (entity.V1.X == 1 and entity.Position.Y >= entity.V1.Y) or (entity.V1.X == -1 and entity.Position.Y <= entity.V1.Y) then
						entity.State = NpcState.STATE_MOVE
						entity.StateFrame = 1
						mod:PlaySound(nil, mod.Sounds.StevenLand, 2)

						-- Effect
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position + Vector(0, entity.V1.X * 30), Vector.Zero, entity):GetSprite()
						effect.Color = Color(0,0,0, 0.5)
						effect.Scale = Vector(0.6, 0.6)
						effect.FlipY = entity.V1.X == -1
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.WallaceUpdate, mod.Entities.Type)

function mod:WallaceDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == mod.Entities.Wallace then
		if entity.Parent then
			damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES

			entity.Parent:GetData().redamaging = true -- Retribution bullshit fix again...
			entity.Parent:TakeDamage(damageAmount, damageFlags, damageSource, 1)
			entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
			entity.Parent:GetData().redamaging = false
		end

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.WallaceDMG, mod.Entities.Type)



--[[ Static overlay ]]--
function mod:StevenStaticOverlay()
	if mod.StevenStatic then
		mod.StevenStatic:Render(Game():GetRoom():GetRenderSurfaceTopLeft(), Vector.Zero, Vector.Zero)
		mod.StevenStatic:Play("Static", false)
		mod.StevenStatic:Update()

		if mod.StevenStatic:IsFinished() then
			mod.StevenStatic = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.StevenStaticOverlay)