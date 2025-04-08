local mod = ReworkedFoes



-- Stupid grid collision size fix
function mod:FamineInit(entity)
	local oldSize = entity.Size
	entity:SetSize(entity.Size + 1, entity.SizeMulti, 12)
	entity:SetSize(oldSize, entity.SizeMulti, 12)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FamineInit, EntityType.ENTITY_FAMINE)

function mod:FamineUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()


	--[[ 1st phase ]]--
	-- Do the summon attack immediately after charging
	if entity.State == NpcState.STATE_ATTACK then
		data.wasCharging = true

	elseif entity.State == NpcState.STATE_MOVE and data.wasCharging
	and (entity.SubType == 1 or Isaac.CountEntities(entity, EntityType.ENTITY_POOTER) < 2) then
		entity.State = NpcState.STATE_SUMMON
		sprite:Play("Attack1", true)
		data.wasCharging = nil


	-- Have a chance to charge even when not horizontally lined up
	elseif entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 1
	and entity.SubType == 0 and entity.StateFrame <= 0 -- Not champion and not performed after a charge
	and mod:Random(1) == 1 then -- 50% chance
		entity.State = NpcState.STATE_ATTACK
		sprite:Play("AttackDashStart", true)
		mod:FlipTowardsTarget(entity, sprite) -- Charge towards the player
		entity.TargetPosition = entity.Position
		mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 1, 1, 2)



	--[[ 2nd phase ]]--
	elseif entity.State == NpcState.STATE_ATTACK2 then
		-- Face the movement direction
		if sprite:IsPlaying("HeadWalk") then
			mod:FlipTowardsMovement(entity, sprite)

		-- 50% chance to do the new attack instead
		elseif sprite:IsPlaying("HeadAttack") and sprite:GetFrame() == 1
		and mod:Random(1) == 1 then
			entity.State = NpcState.STATE_ATTACK3
			entity.StateFrame = 0
			sprite:Play("HeadDoubleAttack", true)

			-- Champion variables
			if entity.SubType == 1 then
				entity.I1 = 0
				entity.I2 = mod:Random(359)
			end

			return true
		end



	--[[ Alternate 2nd phase attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK3 then
		if not sprite:WasEventTriggered("Shoot") then
			mod:ChasePlayer(entity, 1.5)
		else
			entity.Velocity = mod:StopLerp(entity.Velocity, 0.15)
		end


		if sprite:IsEventTriggered("Shoot") then
			-- Champion Monstro shots
			if entity.SubType == 1 then
				entity:FireBossProjectiles(8, Vector.Zero, 3, ProjectileParams())

			-- 6 shots
			else
				local params = ProjectileParams()
				local angle = (entity.StateFrame % 2) * 30
				params.CircleAngle = mod:DegreesToRadians(angle)

				for i = 0, 1 do
					local speed = 10 - (i * 3.5)
					entity:FireProjectiles(entity.Position, Vector(speed, 6), 9, params)
				end
			end

			entity.StateFrame = entity.StateFrame + 1


			-- Effects
			mod:ShootEffect(entity, 3, Vector(0, -22), nil, 0.9)
			mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT)

			local pitch = entity.StateFrame % 2 == 1 and 0.95 or 1
			mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_0, 1, pitch)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_ATTACK2
			entity.ProjectileCooldown = 3
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.FamineUpdate, EntityType.ENTITY_FAMINE)



-- Have a chance to spawn a Super Pooter instead
function mod:ReplaceFaminePooter(type, variant, subtype, position, velocity, spawner, seed)
	if type == EntityType.ENTITY_POOTER and variant == 0
	and spawner and spawner.Type == EntityType.ENTITY_FAMINE
	and mod:Random(1, 10) <= 4  then -- 40% chance
		return { type, 1, subtype, seed, }
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.ReplaceFaminePooter)