local mod = BetterMonsters

local Settings = {
	Cooldown = 60,
	RollTime = 180,
	RollSpeed = 11,
}



function mod:sisterVisInit(entity)
	entity.ProjectileCooldown = Settings.Cooldown / 2

	if entity.SpawnerEntity then
		entity.GroupIdx = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sisterVisInit, EntityType.ENTITY_SISTERS_VIS)

function mod:sisterVisUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()

	local function resetVariables(sis)
		sis.ProjectileCooldown = Settings.Cooldown
		sis.I1 = 0
		sis.I2 = 0
		sis.StateFrame = 0
	end


	--[[ Alive and well ]]--
	if not data.corpse then
		local pair, pairSprite
		if entity.Child then
			pair = entity.Child:ToNPC()
			pairSprite = pair:GetSprite()
		end


		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 and pair and pair.State == NpcState.STATE_IDLE then
				-- Reset variables
				resetVariables(entity)
				resetVariables(pair)

				local attackCount = 3
				-- Don't do the jump attack if the sibling doesn't exist
				if not entity.Child or not entity.Child:Exists() then
					attackCount = 2
				end
				local attack = mod:Random(1, attackCount)
				attack = 1

				-- Roll
				if attack == 1 then
					entity.State = NpcState.STATE_MOVE
					sprite:Play("RollStart", true)

				-- Laser
				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("LaserStartDown", true)

				-- Jump
				elseif attack == 3 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Jumping", true)
				end

				if not pair:GetData().corpse then
					pair.State = entity.State
					pairSprite:Play(sprite:GetAnimation(), true)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Rollin'
		elseif entity.State == NpcState.STATE_MOVE then
			-- Start rolling
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.I1 = Settings.RollTime
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					-- Get direction
					local vector = (target.Position - entity.Position):Normalized()

					-- Random if confused
					if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
						vector = mod:RandomVector()

					-- Away from target if feared or the other half
					elseif (entity.GroupIdx >= 1 and not pair:GetSprite().corpse) or entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
						vector = -vector

					-- At the sibling's corpse if it exists
					elseif entity.Child:GetData().corpse then
						vector = (entity.Child.Position - entity.Position):Normalized()
					end

					entity.Velocity = vector
				end

			-- Rollin' around
			elseif entity.StateFrame == 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)
				mod:LoopingAnim(sprite, "RollLoop")
				sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11

				-- Bounce off of obstacles
				if entity:CollidesWithGrid() then
					mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
					Game():ShakeScreen(math.floor(entity.Scale * 4))
				end

				-- Stop
				if entity.I1 <= 0 then
					entity.StateFrame = 2
					sprite:Play("Taunt", true)
					sprite.PlaybackSpeed = 1
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

				else
					entity.I1 = entity.I1 - 1
				end

			-- Stop rolling
			elseif entity.StateFrame == 2 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_IDLE
				end
			end
		end



	--[[ Corpse moding ]]--
	else
		-- Fake death
		if entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("BloodStop") then
				entity.State = NpcState.STATE_IDLE
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_FEET_SLOW0)
			end


		-- Chillin'
		elseif entity.State == NpcState.STATE_IDLE then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "RollLoop")
			sprite:SetFrame(4)


		-- Rollin'
		elseif entity.State == NpcState.STATE_MOVE then
			entity.Velocity = mod:Lerp(entity.Velocity, entity.Velocity:Resized(Settings.RollSpeed), 0.3)
			mod:LoopingAnim(sprite, "RollLoop")
			sprite.PlaybackSpeed = entity.Velocity:Length() * 0.11

			-- Bounce off of obstacles
			if entity:CollidesWithGrid() then
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
				Game():ShakeScreen(math.floor(entity.Scale * 4))

				-- Stop
				if entity.I1 >= 1 then
					entity.State = NpcState.STATE_STOMP
					sprite:Play("Landing", true)
					sprite:SetFrame(4)
					sprite.PlaybackSpeed = 1
					entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

					-- Projectiles
					entity:FireBossProjectiles(12, Vector.Zero, 2, ProjectileParams())

				else
					entity.I1 = entity.I1 + 1
				end
			end


		-- Splattered on the wall
		elseif entity.State == NpcState.STATE_STOMP then
			--entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:GetFrame() == 9 then
				entity.State = NpcState.STATE_IDLE
			end
		end


		-- Creep
		if entity.State ~= NpcState.STATE_SPECIAL and entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position + mod:RandomVector(mod:Random(30)), 2, 90)
		end


		-- Die for real -- TODO: make them not die if there are alive sisters in the room that arent its pair
		if not entity.Child then
			entity:Kill()
			entity.State = NpcState.STATE_UNIQUE_DEATH
			sprite:Play("Death", true)
			sprite:SetFrame(45)
		end
	end


	-- Cancel death for the first sister and turn into a corpse
	if entity:HasMortalDamage() and not data.corpse
	and entity.Child and not entity.Child:GetData().corpse then
		entity.State = NpcState.STATE_SPECIAL
		sprite:Play("Death", true)
		resetVariables(entity)

		entity.HitPoints = entity.MaxHitPoints
		data.corpse = true
		entity:AddEntityFlags(EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_BOSSDEATH_TRIGGERED | EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	elseif entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.sisterVisUpdate, EntityType.ENTITY_SISTERS_VIS)

function mod:sisterVisDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target:GetData().corpse then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.sisterVisDMG, EntityType.ENTITY_SISTERS_VIS)

function mod:sisterVisCollide(entity, target, bool)
	if target.Type == entity.Type or target.Type == EntityType.ENTITY_CAGE then
		local data = entity:GetData()

		-- Alive
		if entity.State == NpcState.STATE_MOVE and (data.corpse or entity.StateFrame == 1) then
			entity.Velocity = (entity.Position - target.Position):Normalized()
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)

			-- Reset bounce count
			if data.corpse then
				entity.I1 = 0
			end


		-- Dead
		elseif entity.State == NpcState.STATE_IDLE and data.corpse -- Idle
		and ((target.Type == entity.Type and target:ToNPC().State == NpcState.STATE_MOVE and target:ToNPC().StateFrame == 1) -- Hit by a sister
		or (target.Type == EntityType.ENTITY_CAGE and target:ToNPC().State == NpcState.STATE_ATTACK and target:ToNPC().I1 == 1)) then -- Hit by the Cage
			entity.State = NpcState.STATE_MOVE
			entity.Velocity = (entity.Position - target.Position):Normalized():Rotated(mod:Random(-10, 10))
			entity.I1 = 0
			entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.sisterVisCollide, EntityType.ENTITY_SISTERS_VIS)