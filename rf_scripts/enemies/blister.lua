local mod = ReworkedFoes



function mod:BlisterInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		entity.StateFrame = mod:Random(15, 45)
		entity.ProjectileCooldown = mod:Random(1, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlisterInit, EntityType.ENTITY_BLISTER)

function mod:BlisterUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		--[[ Idle ]]--
		if entity.State == NpcState.STATE_MOVE then
			entity.Velocity = Vector.Zero
			mod:LoopingAnim(sprite, "Idle")

			if entity.StateFrame <= 0 then
				entity.StateFrame = mod:Random(15, 45)

				-- Only attack every 3 jumps and if the target is close enough
				if entity.ProjectileCooldown <= 0 and entity.Position:Distance(target.Position) <= 240 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
				else
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Hop")
				end

			else
				entity.StateFrame = entity.StateFrame - 1
			end



		--[[ Jump ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			if sprite:IsEventTriggered("Jump") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

				-- Get position to jump to
				local distance = mod:Random(80, 120)
				local offset = mod:Random(-45, 45)
				local vector = mod:GetTargetVector(entity, target)

				-- Target isn't in range
				if entity.Position:Distance(target.Position) > 240 and not mod:IsConfused(entity) then
					vector = mod:RandomVector()
				end

				entity.TargetPosition = entity.Position + vector:Resized(distance):Rotated(offset)
				entity.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)

			elseif sprite:IsEventTriggered("Land") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
			end


			-- Movement
			if sprite:WasEventTriggered("Jump") and not sprite:WasEventTriggered("Land") then
				local speed = entity.TargetPosition:Distance(entity.Position) / 6
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(speed), 0.25)
			else
				entity.Velocity = Vector.Zero
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("Start") then
				entity.I1 = 0
				entity.I2 = 0
				entity.TargetPosition = target.Position
			end

			-- Splooging
			if sprite:WasEventTriggered("Start") and not sprite:WasEventTriggered("Stop") then
				if entity.I1 <= 0 then
					local params = ProjectileParams()
					params.Scale = 1 + (mod:Random(50) / 100)
					params.Color = mod.Colors.WhiteShot
					params.FallingAccelModifier = 1.5
					params.FallingSpeedModifier = -25

					local offset = (entity.TargetPosition - entity.Position):Resized((entity.I2 - 3) * 20)
					local vector = entity.TargetPosition + offset + mod:RandomVector(mod:Random(15))
					local projectile = mod:FireProjectiles(entity, entity.Position, (vector - entity.Position):Resized(entity.Position:Distance(vector) / 20), 0, params)
					projectile:GetData().RFLeaveCreep = { Type = EffectVariant.CREEP_WHITE, }

					-- Effects
					mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)
					mod:ShootEffect(entity, 1, Vector(0, -25), mod.Colors.WhiteShot)

					entity.I1 = 1
					entity.I2 = entity.I2 + 1

				else
					entity.I1 = entity.I1 - 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = mod:Random(1, 3)
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlisterUpdate, EntityType.ENTITY_BLISTER)

function mod:BlisterDeath(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 1.25)
		Isaac.Spawn(EntityType.ENTITY_BOIL, 2, 0, entity.Position, Vector.Zero, entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.BlisterDeath, EntityType.ENTITY_BLISTER)