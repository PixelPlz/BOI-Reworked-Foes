local mod = BetterMonsters

local Settings = {
	HeadSize = 20,
	--MiddleSize = 18, -- Default size
	TailSize = 15,

	BaseMoveSpeed = 7,
	CreepTime = 20,

	SegmentDelay = 5,
	SubmergeTime = 45,
	Cooldown = 120,

	DashSpeed = 16,

	SubmergeHeight = 7.5,
	Gravity = 0.35,
	AirSpeed = 10,
}



function mod:chadInit(entity)
	if entity.Variant == 1 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = Settings.Cooldown / 2

		mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, entity.Scale + 2, Settings.CreepTime)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chadInit, EntityType.ENTITY_CHUB)

function mod:chadUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		-- Bubble effects
		local function bubbles(position)
			local offset = Vector(math.random(-25, 25) * entity.Scale, math.random(-25, 25) * entity.Scale)
			local bubble = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TAR_BUBBLE, 0, room:GetClampedPosition(position + offset, 5), Vector.Zero, entity):ToEffect()
			bubble.DepthOffset = entity.DepthOffset + 10

			local bubbleSprite = bubble:GetSprite()
			bubbleSprite:ReplaceSpritesheet(0, "gfx/effects/blood_bubble.png")
			bubbleSprite:LoadGraphics()
		end

		-- Creep pool + effects
		if entity:IsFrame(2, 0) and entity.State ~= NpcState.STATE_ATTACK2 and (entity.State ~= NpcState.STATE_IDLE or entity.I1 == 0) then
			local stage = Game():GetLevel():GetAbsoluteStage()

			-- Don't spawn creep in Scarred Womb flooded rooms
			if room:HasWater() == false or (stage ~= LevelStage.STAGE4_1 and stage ~= LevelStage.STAGE4_2) then
				for i = -1, 1, 2 do
					local forward = Vector.Zero
					local side = Vector.Zero

					-- Get offset
					if entity.State ~= NpcState.STATE_IDLE then
						local angleDegrees = entity.Velocity:GetAngleDegrees()

						-- For vertical movement
						if (angleDegrees >= 45 and angleDegrees <= 135) or (angleDegrees < -45 and angleDegrees > -135) then
							forward = entity.Velocity:Resized(20 * entity.Scale)
							side = entity.Velocity:Resized(20 * entity.Scale):Rotated(i * 90)

						-- For horizontal movement
						else
							-- Dashing attack
							if entity.State == NpcState.STATE_ATTACK then
								forward = entity.Velocity:Resized(65 * entity.Scale)
							else
								forward = entity.Velocity:Resized(40 * entity.Scale)
							end
							side = entity.Velocity:Resized(10 * entity.Scale):Rotated(i * 90)
						end
					end

					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position + forward + side, entity.Scale + 1, Settings.CreepTime)
				end

				-- Ripples
				if entity:IsFrame(6, 0) and entity.State ~= NpcState.STATE_IDLE and entity.Velocity:Length() > 1 and room:HasWater() == false then
					local ripple = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.WATER_RIPPLE, 0, entity.Position, Vector.Zero, entity)
					ripple.DepthOffset = entity.DepthOffset - 10
					ripple:GetSprite().Color = Color(1,0,0, 0.5)
				end
			end

			-- Bubbles
			if entity.State == NpcState.STATE_IDLE and entity.ProjectileCooldown > 10 then
				bubbles(entity.Position)
			end
		end

		-- Dive effects and sounds
		local function diveEffects()
			-- Effects
			local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 2, entity.Position, Vector.Zero, entity)
			splash.DepthOffset = entity.DepthOffset + 10

			local splashSprite = splash:GetSprite()
			splashSprite:ReplaceSpritesheet(0, "gfx/effects/blood_splash02.png")
			splashSprite:LoadGraphics()
			splashSprite.Scale = Vector(entity.Scale, entity.Scale)

			-- Sounds
			if entity.I1 == 0 then
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN, 0.9, 0.85)
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_DIVE, 0.9)
			end
		end

		-- Diving helper
		local function dive(beforeAttack, noEffects)
			entity.Visible = false
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = Settings.SubmergeTime

			if beforeAttack ~= true then
				entity.I2 = 0
				entity.TargetPosition = entity.Position
			end

			if noEffects ~= true then
				diveEffects()
			end
		end

		-- Big splash effect
		local function bigSplash()
			local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 0, entity.Position, Vector.Zero, entity)
			splash.DepthOffset = entity.DepthOffset + 10

			local splashSprite = splash:GetSprite()
			splashSprite.Color = Color(1,0,0, 1)
			splashSprite.Scale = Vector(entity.Scale, entity.Scale)
		end

		-- Jump attack projectiles
		local function jumpAttackProjectiles()
			for r = 1, 2 do
				for i = 1, r * 8 do
					local params = ProjectileParams()
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.1
					params.Scale = 1 + mod:Random(35) * 0.01
					entity:FireProjectiles(entity.Position, Vector.FromAngle(360 / (r * 8) * i):Resized(mod:Random(r * 4, r * 4 + 3)), 0, params)
				end
			end
		end

		-- Fix some things on death
		local function deathStuff()
			if entity.Visible == false then
				entity.Visible = true
				diveEffects()
			end

			entity.PositionOffset = Vector.Zero
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 2.5, Settings.CreepTime * 4)
		end



		--[[ Init ]]--
		if entity.State == NpcState.STATE_INIT then
			if entity.FrameCount >= 2 then
				entity.State = NpcState.STATE_MOVE
				entity:SetSize(Settings.HeadSize, Vector(1, 1), 12)
			end

		else
			-- Head
			if entity.I1 == 0 then
				-- Update scale and speed
				local onePercent = entity.MaxHitPoints / 100
				local healthPercent = entity.HitPoints / onePercent

				entity.Scale = 0.75 + (healthPercent / 400)
				data.speed = Settings.BaseMoveSpeed - (healthPercent / 50)

				-- Face movement direction
				mod:FlipTowardsMovement(entity, sprite, true)


			-- Body segments
			else
				-- Kill body segments without a parent, make sure they don't die before it if they have one
				if not entity.Parent or entity.Parent:IsDead() then
					deathStuff()
					entity:Die()

					-- Animations
					local anim = "Middle"
					if entity.I1 == 2 then
						anim = "Tail"
					end
					sprite:Play("Death" .. anim, true)

					return true

				-- Update segments
				else
					-- Get the head segment
					if not data.head then
						if entity.I1 == 1 then
							data.head = entity.Parent:ToNPC()

						elseif entity.I1 == 2 then
							data.head = entity.Parent.Parent:ToNPC()
							entity:SetSize(Settings.TailSize, Vector(1, 1), 12)
						end
					end

					entity.HitPoints = data.head.HitPoints
					entity.Scale = data.head.Scale
				end
			end



			--[[ Idle ]]--
			if entity.State == NpcState.STATE_MOVE then
				-- Head
				if entity.I1 == 0 then
					-- Movement
					mod:MoveRandomGridAligned(entity, data.speed, false, true)
					-- Animations
					local facing = mod:GetDirectionString(entity.Velocity:GetAngleDegrees(), true, true)
					mod:LoopingAnim(sprite, "HeadIdle" .. facing)


				-- Body segments
				else
					--Movement
					local distance = entity.Size * entity.Scale * 0.85
					local pos = entity.Parent.Position + -entity.Parent.Velocity:Resized(distance)

					if entity.Position:Distance(pos) > distance then
						entity.Velocity = mod:Lerp(entity.Velocity, (pos - entity.Position):Resized(entity.Parent.Velocity:Length()), 0.5)
					else
						entity.Velocity = mod:StopLerp(entity.Velocity)
					end

					-- Animations
					local anim = "Middle"
					if entity.I1 == 2 then
						anim = "Tail"
					end
					mod:LoopingAnim(sprite, anim .. "Idle")
				end


				-- Make child segments submerge consistently after the parent
				if entity.Child and entity.Child:ToNPC().State ~= NpcState.STATE_IDLE then
					entity.Child:ToNPC().ProjectileCooldown = Settings.SegmentDelay
				end

				-- Submerge
				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_JUMP

					local anim = "Head"
					if entity.I1 == 1 then
						anim = "Middle"
					elseif entity.I1 == 2 then
						anim = "Tail"
					end

					-- Back facing animation for the head
					local suffix = ""
					if entity.I1 == 0 then
						local childAngleDegrees = (entity.Child.Position - entity.Position):GetAngleDegrees()
						local velocityAngleDegrees = entity.Velocity:GetAngleDegrees()

						if (childAngleDegrees >= 45 and childAngleDegrees <= 135) or (velocityAngleDegrees < -45 and velocityAngleDegrees > -135) then
							suffix = "Back"
						end
					end

					sprite:Play(anim .. "Submerge" .. suffix, true)

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown -1
				end



			--[[ Submerge ]]--
			elseif entity.State == NpcState.STATE_JUMP then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					dive(true)

					-- Head only
					if entity.I1 == 0 then
						-- Choose attack
						local attackCount = 3
						if Isaac.CountEntities(nil, EntityType.ENTITY_SUCKER, -1, -1) >= 3 then
							attackCount = 2
						end
						entity.I2 = mod:Random(1, attackCount)


						-- Dashing attack
						if entity.I2 == 1 then
							local pos = room:GetCenterPos() + Vector(0, mod:Random(-1, 1) * 40)

							local _, posLeft = room:CheckLine(pos, pos + Vector(-1000, 0), 0, 500, false, false)
							local _, posRight = room:CheckLine(pos, pos + Vector(1000, 0), 0, 500, false, false)
							posLeft = posLeft + Vector(20, 0)
							posRight = posRight - Vector(20, 0)

							if entity.Position:Distance(posLeft) > entity.Position:Distance(posRight) then
								entity.TargetPosition = posRight
								entity.V1 = posLeft
							else
								entity.TargetPosition = posLeft
								entity.V1 = posRight
							end


						-- Jumping attack
						elseif entity.I2 == 2 then
							local topLeft = room:GetTopLeftPos() + Vector(20, 20)
							local topRight = Vector(room:GetBottomRightPos().X, room:GetTopLeftPos().Y) + Vector(-20, 20)
							local bottomLeft = Vector(room:GetTopLeftPos().X, room:GetBottomRightPos().Y) + Vector(20, -20)
							local bottomRight = room:GetBottomRightPos() - Vector(20, 20)

							-- Get the closest corner
							local choices = {
								{from = topLeft, to = bottomRight},
								{from = topRight, to = bottomLeft},
								{from = bottomLeft, to = topRight},
								{from = bottomRight, to = topLeft},
							}
							table.sort(choices, function (k1, k2) return k1.from:Distance(entity.Position) < k2.from:Distance(entity.Position) end )

							entity.TargetPosition = choices[1].from
							entity.V1 = choices[1].to

						-- Sucker attack
						elseif entity.I2 == 3 then
							entity.TargetPosition = target.Position + (room:GetCenterPos() - target.Position):Resized(mod:Random(160, 240))
							entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 40, true, false)
						end

						entity.TargetPosition = room:FindFreeTilePosition(entity.TargetPosition, 40)
						entity.V1 = room:FindFreeTilePosition(entity.V1, 40)


					-- Body I2 should be the same as the parent's I2
					else
						entity.I2 = entity.Parent:ToNPC().I2
						entity.V1 = entity.Parent:ToNPC().V1
					end
				end



			--[[ Submerged ]]--
			elseif entity.State == NpcState.STATE_IDLE then
				-- Movement
				-- Head
				if entity.I1 == 0 then
					-- Move to target position
					if room:CheckLine(entity.Position, entity.TargetPosition, 0, 0, false, false) then
						entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(data.speed * 1.5), 0.25)
					else
						entity.Pathfinder:FindGridPath(entity.TargetPosition, Settings.BaseMoveSpeed / 6, 0, false)
					end

					-- For jumping attack
					if entity.I2 == 2 then
						-- Creep
						if entity.ProjectileCooldown <= 10 then
							mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.V1, entity.Scale + (2 - entity.ProjectileCooldown * 0.2), Settings.CreepTime * 4)
							-- Sound
							if entity.ProjectileCooldown % 3 == 0 then
								mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.5)
							end

						-- Warning bubbles
						elseif entity:IsFrame(2, 0) then
							local splatPos = entity.V1 + Vector(math.random(-25, 25) * entity.Scale, math.random(-25, 25) * entity.Scale)
							Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_SPLAT, 0, splatPos, Vector.Zero, entity):ToEffect()
							bubbles(entity.V1)
						end
					end

				-- Body segments
				else
					-- Follow parent
					if entity.Parent:ToNPC().State == NpcState.STATE_IDLE then
						entity.Position = entity.Parent.Position

					-- Go to where the parent jumped out from
					else
						entity.Position = entity.Parent:ToNPC().V2
					end
				end


				-- Make child segments surface consistently after the parent
				if entity.Child and entity.Child:ToNPC().State == NpcState.STATE_IDLE then
					entity.Child:ToNPC().ProjectileCooldown = Settings.SegmentDelay
				end

				-- Surface
				if entity.ProjectileCooldown <= 0 and (entity.Position:Distance(entity.TargetPosition) < 20 or entity.I1 > 0) then
					if entity.I2 ~= 3 or entity.I1 == 0 then
						entity.Visible = true
						entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
						diveEffects()
					end

					entity.V2 = entity.Position
					entity.Velocity = Vector.Zero
					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, entity.Scale + 2, Settings.CreepTime * 3)


					-- After attack
					if entity.I2 == 0 then
						entity.State = NpcState.STATE_APPEAR_CUSTOM

						local anim = "Head"
						if entity.I1 > 0 then
							anim = "Body0" .. entity.I1
						end
						sprite:Play("Appear" .. anim, true)


					-- Dashing attack
					elseif entity.I2 == 1 then
						entity.State = NpcState.STATE_ATTACK

						-- Head only
						if entity.I1 == 0 then
							entity.ProjectileDelay = 0
							entity.Velocity = (entity.V1 - entity.Position):Normalized()
							mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)
						end

						local anim = "HeadSwim"
						if entity.I1 == 1 then
							anim = "Middle"
						elseif entity.I1 == 2 then
							anim = "Tail"
						end
						sprite:Play(anim .. "Appear", true)


					-- Jumping attack
					elseif entity.I2 == 2 then
						entity.State = NpcState.STATE_ATTACK2
						entity.PositionOffset = Vector(0, Settings.SubmergeHeight)
						data.zVelocity = entity.Position:Distance(entity.V1) / 54
						entity.TargetPosition = (entity.V1 - entity.Position):Normalized()

						-- Head only
						if entity.I1 == 0 then
							jumpAttackProjectiles()
							bigSplash()
							mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0, 1.1)
						end


					-- Sucker attack
					elseif entity.I2 == 3 then
						entity.State = NpcState.STATE_ATTACK3
						sprite:Play("HeadSpit", true)

						-- Head only
						if entity.I1 == 0 then
							bigSplash()
							mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR, 1.1)
						end
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end



			--[[ Dashing attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				-- Movement
				-- Go to the other side
				if entity.I1 == 0 or entity.Parent:ToNPC().State ~= NpcState.STATE_ATTACK then
					-- If the head is stunned then body segments also get stunned
					if entity.I1 > 0 and entity.Parent:ToNPC().State == NpcState.STATE_SUICIDE then
						entity.State = NpcState.STATE_SUICIDE
					else
						entity.Velocity = mod:Lerp(entity.Velocity, (entity.V1 - entity.Position):Resized(Settings.DashSpeed), 0.25)
					end

				-- Follow parent
				else
					local distance = entity.Size * entity.Scale * 0.7
					local pos = entity.Parent.Position + -entity.Parent.Velocity:Resized(distance)
					entity.Position = mod:Lerp(entity.Position, pos, 0.35)
				end


				-- Head
				if entity.I1 == 0 then
					if not sprite:IsPlaying("HeadSwimAppear") and not sprite:IsPlaying("HeadSwimSubmerge") then
						mod:LoopingAnim(sprite, "HeadSwim")
					end

					-- Projectiles
					if room:GetGridIndex(entity.Position) ~= entity.ProjectileDelay then
						entity.ProjectileDelay = room:GetGridIndex(entity.Position)

						local params = ProjectileParams()
						params.FallingSpeedModifier = -6
						params.FallingAccelModifier = 0.4
						params.Scale = 1.25

						local dir = mod:GetSign(entity.ProjectileDelay % 2)

						entity:FireProjectiles(entity.Position, Vector(-entity.Velocity:Normalized().X, dir * 9), 0, params)
						entity:FireBossProjectiles(2, entity.Child.Position, 8, ProjectileParams())
					end

				-- Body segment animations
				else
					local anim = "Middle"
					if entity.I1 == 2 then
						anim = "Tail"
					end

					if not sprite:IsPlaying(anim .. "Appear") and not sprite:IsPlaying(anim .. "Submerge") then
						mod:LoopingAnim(sprite, anim .. "Idle")
					end
				end


				-- Play submerge animation
				if entity.Position:Distance(entity.V1) < 140 and entity.StateFrame == 0 then
					local anim = "HeadSwim"
					local frame = 0

					if entity.I1 == 1 then
						anim = "Middle"
						frame = 7
					elseif entity.I1 == 2 then
						anim = "Tail"
						frame = 5
					end

					sprite:Play(anim .. "Submerge", true)
					sprite:SetFrame(frame)
					entity.StateFrame = 1
				end

				-- Submerge
				if entity.Position:Distance(entity.V1) < 15 then
					dive()
					entity.StateFrame = 0
				end



			--[[ Jumping attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK2 then
				-- Update height
				data.zVelocity = data.zVelocity - Settings.Gravity
				entity.PositionOffset = Vector(0, entity.PositionOffset.Y - data.zVelocity)

				-- Update grid collision to allow jumping over obstacles
				if entity.PositionOffset.Y <= -28 then
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				else
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				end


				-- Head
				if entity.I1 == 0 then
					entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition * Settings.AirSpeed, 0.25)

					-- Animations
					local suffix = ""
					if entity.Velocity.Y < 0 then
						suffix = "Back"
					elseif data.zVelocity > 3 then
						suffix = "Up"
					elseif data.zVelocity < -4 then
						suffix = "Down"
					end
					mod:LoopingAnim(sprite, "HeadJump" .. suffix)

					-- Make sure there is always creep at the other end
					if entity:IsFrame(2, 0) then
						mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.V1, entity.Scale + 2, Settings.CreepTime * 2)
					end

				-- Body segments
				else
					-- Go to where the parent landed
					if entity.Parent:ToNPC().State ~= NpcState.STATE_ATTACK2 then
						entity.Position = mod:Lerp(entity.Position, entity.Parent:ToNPC().V2, 0.35)

					-- Follow parent
					else
						entity.Position = mod:Lerp(entity.Position, entity.Parent.Position, 0.25)
					end

					-- Animations
					local anim = "Middle"
					if entity.I1 == 2 then
						anim = "Tail"
					end
					mod:LoopingAnim(sprite, anim .. "Air")
				end


				-- Submerge
				if entity.PositionOffset.Y > Settings.SubmergeHeight then
					dive()
					entity.V2 = entity.Position + entity.Velocity
					entity.PositionOffset = Vector.Zero

					if entity.I1 == 0 then
						jumpAttackProjectiles()
						bigSplash()
					end
				end



			--[[ Sucker attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK3 then
				-- Head only
				if entity.I1 == 0 then
					-- Shoot Sucker projectile
					if sprite:IsEventTriggered("Shoot") then
						local shotSpeed = 11

						local params = ProjectileParams()
						params.Variant = IRFentities.SuckerProjectile
						params.HeightModifier = -90 * entity.Scale
						params.FallingSpeedModifier = 10 * entity.Scale
						params.FallingAccelModifier = -0.1 - (entity.Position:Distance(target.Position) / params.HeightModifier / shotSpeed) -- Can't decide if this is smart or stupid
						entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(shotSpeed), 0, params)

						mod:PlaySound(entity, SoundEffect.SOUND_LITTLE_SPIT, 1.1, 0.95)
						mod:ShootEffect(entity, 2, Vector(0, params.HeightModifier * 0.75)).DepthOffset = entity.DepthOffset + 20

					-- Effects
					elseif sprite:IsEventTriggered("Dive") then
						bigSplash()
					end
				end

				if sprite:IsFinished() then
					-- Only play effects for the head
					local bool = true
					if entity.I1 == 0 then
						bool = false
					end
					dive(false, bool)
				end



			--[[ Surface ]]--
			elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = math.ceil(Settings.Cooldown * entity.Scale)
					data.moveTimer = 0
				end



			--[[ Stunned ]]--
			elseif entity.State == NpcState.STATE_SUICIDE then
				-- Head
				if entity.I1 == 0 then
					entity.Velocity = mod:StopLerp(entity.Velocity)
					mod:LoopingAnim(sprite, "HeadStunned")

					-- Explode bomb
					if entity.StateFrame <= 0 then
						data.bomb.Position = entity.Position
						data.bomb:SetExplosionCountdown(0)
						data.bomb = nil

						entity.State = NpcState.STATE_MOVE
						entity.ProjectileCooldown = math.ceil(Settings.Cooldown * entity.Scale / 2)
						data.moveTimer = 0

					-- Wait
					else
						data.bomb:SetExplosionCountdown(9999)
						entity.StateFrame = entity.StateFrame - 1
					end


				-- Body segments
				else
					-- Get close to parent
					local distance = entity.Size * entity.Scale * 2
					if entity.Position:Distance(entity.Parent.Position) > distance then
						entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (entity.Position - entity.Parent.Position):Resized(distance), 0.25)
					end

					-- Animations
					local anim = "Middle"
					if entity.I1 == 2 then
						anim = "Tail"
					end
					mod:LoopingAnim(sprite, anim .. "Idle")

					-- Unstun
					if entity.Parent:ToNPC().State ~= NpcState.STATE_SUICIDE then
						entity.State = NpcState.STATE_MOVE
					end
				end
			end
		end


		if entity:HasMortalDamage() then
			deathStuff()
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.chadUpdate, EntityType.ENTITY_CHUB)

function mod:chadDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 and not (damageFlags & DamageFlag.DAMAGE_COUNTDOWN > 0) then
		local segment = target:ToNPC()
		local data = segment:GetData()

		-- Head damage color
		if segment.I1 == 0 then
			segment:SetColor(IRFcolors.DamageFlash, 2, 0, false, true)

		-- Redirect damage from body segments to the head
		elseif data.head then
			damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES
			data.head:TakeDamage(damageAmount, damageFlags, damageSource, 5)
			data.head:SetColor(IRFcolors.DamageFlash, 2, 0, false, true)

			return false
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.chadDMG, EntityType.ENTITY_CHUB)

function mod:chadCollision(entity, target, bool)
	if entity.Variant == 1 then
		-- Jump over the player
		if entity.PositionOffset.Y <= -40 and (target.Type == EntityType.ENTITY_PLAYER or target.Type == EntityType.ENTITY_FAMILIAR or target.Type == EntityType.ENTITY_BOMB) then
			-- Bombs just don't give a fuck apparently?
			if target.Type == EntityType.ENTITY_BOMB then
				target.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			end
			return true -- Ignore collision


		-- Head only
		elseif entity:ToNPC().I1 == 0 then
			-- Kiss :3
			if target.Type == EntityType.ENTITY_PLAYER then
				mod:PlaySound(entity:ToNPC(), SoundEffect.SOUND_KISS_LIPS1, 1, 1, 30)

			elseif entity:ToNPC().State == NpcState.STATE_ATTACK then
				-- Kill Suckers it dashes into
				if target.Type == EntityType.ENTITY_SUCKER then
					target:Kill()

				-- Eat bombs when dashing
				elseif target.Type == EntityType.ENTITY_BOMB then
					entity:GetData().bomb = target:ToBomb()
					target.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					target.Visible = false

					entity:ToNPC().State = NpcState.STATE_SUICIDE
					entity:ToNPC().StateFrame = 35
					mod:PlaySound(entity:ToNPC(), SoundEffect.SOUND_MONSTER_ROAR_2)
					return true -- Ignore collision
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.chadCollision, EntityType.ENTITY_CHUB)



-- Sucker projectile
local function suckerProjectilePop(projectile)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile)
	mod:PlaySound(nil, SoundEffect.SOUND_PLOP, 0.9)

	if projectile.SpawnerEntity then
		local sucker = Isaac.Spawn(EntityType.ENTITY_SUCKER, 0, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ToNPC()
		sucker:FireProjectiles(projectile.Position, Vector(11, 4), 7, ProjectileParams())
		mod:QuickCreep(EffectVariant.CREEP_RED, projectile.SpawnerEntity, projectile.Position, 1.5, 90)
	end
end

function mod:suckerProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()

	if projectile.FrameCount <= 2 then
		sprite:Play("Fly", true)
		projectile:GetData().trailColor = Color.Default
		projectile.Scale = 1.5
	end

	sprite.Rotation = projectile.Velocity:GetAngleDegrees() + 90

	if projectile:IsDead() then
		suckerProjectilePop(projectile)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.suckerProjectileUpdate, IRFentities.SuckerProjectile)

function mod:suckerProjectileCollision(projectile)
	suckerProjectilePop(projectile)
end
mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, mod.suckerProjectileCollision, IRFentities.SuckerProjectile)