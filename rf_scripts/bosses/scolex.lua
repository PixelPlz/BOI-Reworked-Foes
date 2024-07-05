local mod = ReworkedFoes

local Settings = {
	Length = 19, -- Doesn't include head
	ArmorHealth = 40,
	TailMulti = 1.25,

	BurrowTime = 30,
	SegmentDelay = 5,
	BurrowHeight = 7.5,

	MoveSpeed = 5,
	Gravity = 0.5,

	JumpSpeed = 9,
	LongJumpSpeed = 6,
	SteerJumpSpeed = 11,

	AttackDelay = 10,
	Cooldown = 2,
}



function mod:ScolexInit(entity)
	if entity.Variant == 1 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

		if mod.Config.AppearPins == false then
			entity.Visible = false
		end

		if FiendFolio and entity:GetData().wasWaitingWorm then
			entity:GetData().wasWaitingWorm = nil -- Fuck off with the stupid waiting worm shit
			entity.State = NpcState.STATE_APPEAR_CUSTOM
			entity:GetSprite():Play("Attack1", true)
			entity:GetSprite():SetFrame(46)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ScolexInit, EntityType.ENTITY_PIN)

function mod:ScolexUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()
		local room = Game():GetRoom()


		-- Dirt helper function
		local function dirtEffect()
			local hasDirt = false

			-- Update existing one
			for i, dirt in pairs(Isaac.FindByType(mod.Entities.Type, mod.Entities.DirtHelper, -1, false, false)) do
				if dirt.Position:Distance(entity.V2) <= 20 then
					dirt.Position = entity.V2
					dirt:ToNPC().StateFrame = 10
					dirt.DepthOffset = entity.DepthOffset + 10
					hasDirt = true
					break
				end
			end

			-- Create new one
			if hasDirt == false then
				Isaac.Spawn(mod.Entities.Type, mod.Entities.DirtHelper, 0, entity.Position, Vector.Zero, entity):ToNPC().StateFrame = 10
			end
		end


		-- Initialize
		if entity.State == NpcState.STATE_INIT then
			-- Head
			entity.GroupIdx = 0
			entity.I1 = mod:Random(Settings.BurrowTime / 2, Settings.BurrowTime * 2)
			data.zVelocity = 0
			entity.ProjectileCooldown = 1

			if mod.Config.AppearPins == true then
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.75)
			end
			entity.Visible = false


			-- Create all segments
			local previous = entity

			for i = 1, Settings.Length do
				local newSegment = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
				newSegment.GroupIdx = i
				newSegment.State = NpcState.STATE_MOVE
				newSegment.I1 = 9999
				newSegment:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_NO_REWARD)

				newSegment:GetData().zVelocity = 0
				newSegment:GetData().head = entity
				newSegment.Visible = false


				-- Set up individual segments
				-- Tail
				if i == Settings.Length then
					newSegment.I2 = 2
					data.tail = newSegment

				-- Body segments
				else
					local anim = "Body" .. tostring(math.random(1, 3))
					local middle = math.floor(Settings.Length / 2)

					-- Second to last one has its shell broken
					if i == Settings.Length - 1 then
						anim = "Body3"
						newSegment.I2 = 2

					-- Third to last one and two in the middle are half-broken
					elseif i == Settings.Length - 2 or i == middle or i == middle - 1 then
						newSegment.I2 = 1
						newSegment.V1 = Vector(Settings.ArmorHealth / 2, 0)

					else
						newSegment.V1 = Vector(Settings.ArmorHealth, 0)
					end

					newSegment:GetData().anim = anim
				end


				-- Set up parent and child connections
				newSegment.Parent = previous
				previous.Child = newSegment
				previous = newSegment
			end

			entity.State = NpcState.STATE_MOVE


		else
			if entity.GroupIdx > 0 then
				-- Kill body segments without a parent, make sure they don't die before it if they have one
				if (not entity.Parent or entity.Parent:IsDead()) or (not data.head or data.head:IsDead()) then
					entity:Die()
					sprite:Play("DeathBody", true)
					return true

				-- Update segments
				else
					entity.HitPoints = entity.Parent.HitPoints

					-- Shell phases
					if entity.I2 < 2 and entity.V1.X <= Settings.ArmorHealth - (Settings.ArmorHealth / 2) * (entity.I2 + 1) then
						entity.I2 = entity.I2 + 1

						-- Effects
						for i = 0, 5 do
							local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, BackdropType.WOMB, entity.Position, mod:RandomVector(3), entity):ToEffect()
							rocks:GetSprite():Play("rubble", true)
							rocks.State = 2
							rocks.m_Height = entity.PositionOffset.Y
							rocks:Update()
						end

						mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE, 0.9)
					end
				end
			end


			-- Animations
			-- Head
			if entity.GroupIdx == 0 then
				if entity.State ~= NpcState.STATE_ATTACK then
					local suffix = ""
					if entity.Velocity.Y <= -0.5 then
						suffix = suffix .. "Up"
					end
					mod:LoopingAnim(sprite, "Head" .. suffix)
				end

			-- Tail
			elseif entity.GroupIdx == Settings.Length then
				if entity.State ~= NpcState.STATE_ATTACK then
					mod:LoopingAnim(sprite, "Tail")
				end

			-- Body segments
			else
				mod:LoopingAnim(sprite, data.anim .. "_" .. entity.I2)
			end



			--[[ Underground ]]--
			if entity.State == NpcState.STATE_MOVE then
				-- Movement
				-- Head
				if entity.GroupIdx == 0 then
					if entity.StateFrame ~= 2 then
						entity.TargetPosition = target.Position + (entity.Position - target.Position):Resized(120)
					end

					if room:CheckLine(entity.Position, entity.TargetPosition, 0, 0, false, false) then
						entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.MoveSpeed), 0.25)
					else
						entity.Pathfinder:FindGridPath(entity.TargetPosition, Settings.MoveSpeed / 6, 0, false)
					end

				-- Body segments
				else
					-- Follow parent
					if entity.Parent:ToNPC().State == NpcState.STATE_MOVE then
						local distance = entity.Size * 0.85

						if entity.Position:Distance(entity.Parent.Position) > distance then
							entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (entity.Position - entity.Parent.Position):Resized(distance), 0.25)
						end

					-- Go to where the parent jumped out from
					else
						entity.Position = entity.Parent:ToNPC().V2
					end
				end


				-- Make child segments jump out consistently after the parent
				if entity.Child then
					entity.Child:ToNPC().I1 = Settings.SegmentDelay
				end

				-- Jump out
				if entity.I1 <= -60 -- If underground for too long
				or (entity.I1 <= 0 and (entity.StateFrame ~= 2 -- Regular jump
				or (entity.Position:Distance(entity.TargetPosition) < 40 or entity.GroupIdx > 0) -- At target position for long jump
				or not entity.Pathfinder:HasPathToPos(entity.TargetPosition))) then -- If it doesn't have a path to the target position
					entity.State = NpcState.STATE_JUMP
					entity.V2 = entity.Position
					entity.Velocity = Vector.Zero
					entity.PositionOffset = Vector(0, Settings.BurrowHeight)

					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
					entity.Visible = true
					dirtEffect()


					-- Attacks
					local delay = Settings.AttackDelay

					-- Long jump
					if entity.StateFrame == 2 then
						data.zVelocity = Settings.LongJumpSpeed
						entity.TargetPosition = Vector(entity.ProjectileDelay, 0)

						if entity.GroupIdx == 0 or entity.GroupIdx == Settings.Length then
							delay = Settings.AttackDelay * 2
						else
							delay = mod:Random(Settings.AttackDelay, Settings.AttackDelay * 4)
						end

					-- Steering jump
					elseif entity.StateFrame == 3 then
						data.zVelocity = Settings.SteerJumpSpeed

					-- No attack
					else
						local vector = (target.Position - entity.Position):Normalized()
						if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
							vector = -vector
						elseif entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
							vector = mod:RandomVector()
						end

						data.zVelocity = Settings.JumpSpeed
						entity.TargetPosition = vector
					end

					entity.ProjectileDelay = delay


					-- Dig effects
					if entity.GroupIdx == 0 then
						mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.65)

						-- Long and steering jump projectiles
						if entity.StateFrame == 2 or entity.StateFrame == 3 then
							local params = ProjectileParams()
							local bg = room:GetBackdropType()

							-- Get fitting projectile
							if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
								params.Color = mod.Colors.CorpseGreen
							elseif bg ~= BackdropType.WOMB and bg ~= BackdropType.UTERO and bg ~= BackdropType.SCARRED_WOMB and bg ~= BackdropType.CORPSE3 then
								params.Variant = ProjectileVariant.PROJECTILE_ROCK
							end

							if entity.StateFrame == 3 then
								entity:FireProjectiles(entity.Position, Vector(9, 9), 9, params)
							else
								entity:FireBossProjectiles(15, Vector.Zero, 2, params)
							end
							mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.75)
						end
					end

				else
					entity.I1 = entity.I1 - 1
				end



			--[[ Jumping ]]--
			elseif entity.State == NpcState.STATE_JUMP or entity.State == NpcState.STATE_ATTACK then
				-- Head and tail attack
				if entity.State == NpcState.STATE_ATTACK then
					if sprite:IsEventTriggered("Shoot") then
						local params = ProjectileParams()
						mod:ShootEffect(entity, 2, Vector(0, entity.PositionOffset.Y * 0.225))

						-- Head
						if entity.GroupIdx == 0 then
							params.Scale = 1.15
							params.HeightModifier = entity.PositionOffset.Y * 0.65

							entity:FireBossProjectiles(15, target.Position, 3, params)
							mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_HISS, 0.9)

						-- Tail
						else
							-- Long jump
							if entity.StateFrame == 2 then
								params.HeightModifier = entity.PositionOffset.Y * 0.65
								params.Scale = 1.5
								params.FallingAccelModifier = 1.25
								params.FallingSpeedModifier = -15
								params.BulletFlags = (ProjectileFlags.EXPLODE | ProjectileFlags.ACID_RED)

								local offset = mod:Random(359)
								for i = 0, 2 do
									mod:FireProjectiles(entity, entity.Position, Vector.FromAngle(offset + 120 * i):Resized(6), 0, params, Color.Default)
								end

							-- Regular jump
							else
								params.HeightModifier = entity.PositionOffset.Y * 0.5
								params.FallingSpeedModifier = 2
								entity:FireProjectiles(entity.Position, Vector(10, 8), 8, params)
							end

							mod:PlaySound(entity, SoundEffect.SOUND_MEATHEADSHOOT, 1.25)
						end
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_JUMP
					end

				-- Attack after jumping out
				else
					if entity.ProjectileDelay == 0 then
						entity.ProjectileDelay = -1

						-- Head and tail
						if (entity.GroupIdx == 0 or entity.GroupIdx == Settings.Length) and (entity.StateFrame == 1 or entity.StateFrame == 2) then
							local anim = "TailAttack"

							-- Head animation
							if entity.GroupIdx == 0 then
								local suffix = ""
								if entity.Velocity.Y <= -0.5 then
									suffix = suffix .. "Up"
								end
								anim = "HeadAttack" .. suffix
							end

							entity.State = NpcState.STATE_ATTACK
							sprite:Play(anim, true)

						-- Cracked segments
						elseif entity.GroupIdx < Settings.Length and entity.I2 == 2 and entity.StateFrame == 2 then
							local shotSpeed = 10

							local params = ProjectileParams()
							params.HeightModifier = entity.PositionOffset.Y * 0.85
							params.FallingSpeedModifier = 1
							params.FallingAccelModifier = -0.1 - (entity.Position:Distance(target.Position) / params.HeightModifier / shotSpeed) -- Can't decide if this is smart or stupid
							params.Color = Color(1,1,1, 1, 0.25,0,0)
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(shotSpeed), 0, params)

							mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)
							mod:ShootEffect(entity, 2, Vector(0, entity.PositionOffset.Y * 0.225))
						end

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end
				end


				-- Update height
				local appliedGravity = Settings.Gravity
				-- Long jump
				if entity.StateFrame == 2 then
					appliedGravity = Settings.Gravity * 0.5
				end

				data.zVelocity = data.zVelocity - appliedGravity
				entity.PositionOffset = Vector(0, entity.PositionOffset.Y - data.zVelocity)

				-- Update grid collision to allow jumping over obstacles
				if entity.PositionOffset.Y <= -28 then
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				else
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				end


				-- Movement
				-- Head
				if entity.GroupIdx == 0 then
					-- Steering jump
					if entity.StateFrame == 3 then
						-- Confused
						if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
							mod:WanderAround(entity, Settings.MoveSpeed + 1)

						else
							local vector = (target.Position - entity.Position):Normalized()
							if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
								vector = -vector
							end

							entity.Velocity = mod:Lerp(entity.Velocity, vector * (Settings.MoveSpeed + 1), 0.2)
						end

					-- Long and regular jump
					else
						local speed = Settings.MoveSpeed
						-- Long jump
						if entity.StateFrame == 2 then
							speed = Settings.MoveSpeed + 5.5
						end

						entity.Velocity = mod:Lerp(entity.Velocity, entity.TargetPosition * speed, 0.25)
					end

				-- Body segments
				else
					-- Go to where the parent landed
					if entity.Parent:ToNPC().State == NpcState.STATE_MOVE then
						entity.Position = mod:Lerp(entity.Position, entity.Parent:ToNPC().V2, 0.35)

					-- Follow parent
					else
						local step = 0.25
						local distance = entity.Size * 0.85

						if entity.Parent.PositionOffset.Y > -10 then
							distance = 0
						end
						-- Long and steering jump
						if entity.StateFrame == 2 or entity.StateFrame == 3 then
							step = 0.2
							distance = entity.Size * 0.6
						end

						if entity.Position:Distance(entity.Parent.Position) > distance then
							entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (entity.Position - entity.Parent.Position):Resized(distance), step)
						end
					end

					-- Creep from fully cracked segments
					if entity.GroupIdx < Settings.Length and entity.I2 == 2 and entity:IsFrame(mod:Random(8, 16), 0) then
						mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.9, mod:Random(30, 60))
					end
				end


				-- Dig in
				if entity.PositionOffset.Y > Settings.BurrowHeight then
					entity.State = NpcState.STATE_MOVE
					entity.V2 = entity.Position + entity.Velocity
					entity.PositionOffset = Vector(0, Settings.BurrowHeight)
					entity.I1 = Settings.BurrowTime

					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.Visible = false
					dirtEffect()

					-- Head
					if entity.GroupIdx == 0 then
						mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.75)

						-- Longer burrow time after long jump
						if entity.StateFrame == 2 then
							entity.I1 = Settings.BurrowTime * 3
						end

						-- Attacks
						if entity.ProjectileCooldown <= 0 then
							entity.StateFrame = mod:Random(1, 3)
							entity.ProjectileCooldown = Settings.Cooldown

							-- Long jump
							if entity.StateFrame == 2 then
								local posLeft = Vector(room:GetTopLeftPos().X + 20, target.Position.Y)
								local posRight = Vector(room:GetBottomRightPos().X - 20, target.Position.Y)

								-- Get closest side
								if entity.Position:Distance(posLeft) > entity.Position:Distance(posRight) then
									entity.TargetPosition = posRight
									entity.ProjectileDelay = -1
								else
									entity.TargetPosition = posLeft
									entity.ProjectileDelay = 1
								end

								entity.TargetPosition = room:FindFreeTilePosition(entity.TargetPosition, 40)

								-- Dumb piece of shit function doesn't take into account spikes...
								local gridHere = room:GetGridEntityFromPos(entity.TargetPosition)
								if (gridHere ~= nil and gridHere:ToSpikes() ~= nil) or entity.Pathfinder:HasPathToPos(entity.TargetPosition, false) == false then
									entity.TargetPosition = room:FindFreePickupSpawnPosition(entity.TargetPosition, 60, false, false)
								end

								-- Longer burrow time before long jump
								entity.I1 = Settings.BurrowTime * 3
							end

						-- No attack
						else
							entity.StateFrame = 0
							entity.ProjectileCooldown = entity.ProjectileCooldown - 1
						end

					-- Body StateFrame should be the same as the parent's StateFrame
					else
						entity.StateFrame = entity.Parent:ToNPC().StateFrame
					end
				end
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ScolexUpdate, EntityType.ENTITY_PIN)

function mod:ScolexDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 1 then
		-- Don't take damage from his and other Pin variants' explosive shots
		if damageSource.SpawnerType == entity.Type and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
			return false

		else
			local segment = entity:ToNPC()
			local data = segment:GetData()

			-- Head only takes damage through its body segments
			if segment.GroupIdx == 0 then
				if not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
					return false
				end


			-- Body segments
			elseif data.head then
				-- Redirect damage from exposed segments to the head
				if segment.I2 >= 2 then
					-- Tail takes extra damage
					if segment.GroupIdx == Settings.Length then
						damageAmount = damageAmount * Settings.TailMulti
					end

					damageFlags = damageFlags + DamageFlag.DAMAGE_COUNTDOWN + DamageFlag.DAMAGE_CLONES

					data.head:GetData().redamaging = true -- Retribution bullshit fix (I FUCKING HATE THIS MOD WHY CAN'T YOU BE FUCKING NORMAL)
					data.head:TakeDamage(damageAmount, damageFlags, damageSource, 1)
					data.head:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
					data.head:GetData().redamaging = false

				-- Damage the shell
				else
					segment.V1 = Vector(segment.V1.X - damageAmount, 0)
					data.head:SetColor(mod.Colors.ArmorFlash, 2, 0, false, true)
				end

				return false
			end
		end
	end
end
mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE, mod.ScolexDMG, EntityType.ENTITY_PIN)

function mod:ScolexCollision(entity, target, bool)
	-- Jump over the player
	if entity.Variant == 1 and entity.PositionOffset.Y <= -44
	and (target.Type == EntityType.ENTITY_PLAYER or target.Type == EntityType.ENTITY_FAMILIAR or target.Type == EntityType.ENTITY_BOMB) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.ScolexCollision, EntityType.ENTITY_PIN)



--[[ Dirt helper ]]--
function mod:DirtHelperInit(entity)
	if entity.Variant == mod.Entities.DirtHelper then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.State = NpcState.STATE_IDLE
		entity:GetSprite():Play("Ground", true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DirtHelperInit, mod.Entities.Type)

function mod:DirtHelperUpdate(entity)
	if entity.Variant == mod.Entities.DirtHelper then
		local sprite = entity:GetSprite()

		entity.Velocity = Vector.Zero

		-- Loop
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, "Ground")

			if entity.StateFrame <= 0 then
				entity.State = NpcState.STATE_SUICIDE
				sprite:Play("HoleClose", true)
			else
				entity.StateFrame = entity.StateFrame - 1
			end

		-- Close
		elseif entity.State == NpcState.STATE_SUICIDE then
			if sprite:IsFinished() then
				entity:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DirtHelperUpdate, mod.Entities.Type)