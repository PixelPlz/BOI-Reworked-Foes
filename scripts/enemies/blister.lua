local mod = BetterMonsters



function mod:blisterInit(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		entity.StateFrame = mod:Random(15, 45)
		entity.ProjectileCooldown = mod:Random(1, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blisterInit, EntityType.ENTITY_BLISTER)

function mod:blisterUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Idle
		if entity.State == NpcState.STATE_MOVE then
			entity.Velocity = Vector.Zero
			mod:LoopingAnim(sprite, "Idle")

			if entity.StateFrame <= 0 then
				-- Only attack every 3 jumps and if target is close enough
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


		-- Jump
		elseif entity.State == NpcState.STATE_JUMP then
			if sprite:IsEventTriggered("Jump") then
				entity.I1 = 1
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

				-- Get position to jump to
				entity.TargetPosition = entity.Position + (target.Position - entity.Position):Rotated(mod:Random(-60, 60)):Resized(mod:Random(80, 120))

				-- No players in range / confused
				if entity.Position:Distance(Game():GetNearestPlayer(entity.Position).Position) > 240 or entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
					entity.TargetPosition = entity.Position + mod:RandomVector(80, 120)

				-- Feared
				elseif entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
					entity.TargetPosition = entity.Position + (entity.Position - target.Position):Resized(mod:Random(80, 120))
				end

				entity.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(entity.TargetPosition, 0, true, false)


			elseif sprite:IsEventTriggered("Land") then
				entity.I1 = 0
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
			end


			if entity.I1 == 1 then
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(entity.TargetPosition:Distance(entity.Position) / 6), 0.25)
			else
				entity.Velocity = Vector.Zero
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.StateFrame = 30
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Attack
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = Vector.Zero

			if sprite:IsEventTriggered("Start") then
				entity.I1 = 1
				entity.I2 = -3
				entity.V1 = target.Position
			elseif sprite:IsEventTriggered("Stop") then
				entity.I1 = 0
			end

			if entity.I1 == 1 and entity:IsFrame(2, 0) then
				entity.I2 = entity.I2 + 1

				local params = ProjectileParams()
				params.Scale = 1 + (mod:Random(5) * 0.1)
				params.Color = IRFcolors.WhiteShot
				params.FallingAccelModifier = 1.5
				params.FallingSpeedModifier = -25

				local vector = entity.V1 + (entity.V1 - entity.Position):Resized(20 * entity.I2)
				entity:FireProjectiles(entity.Position, (vector - entity.Position):Rotated(mod:Random(-10, 10)):Resized(entity.Position:Distance(vector) / 20), 0, params)
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)
				mod:ShootEffect(entity, 1, Vector(0, -25), IRFcolors.WhiteShot)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.StateFrame = 30
				entity.ProjectileCooldown = mod:Random(1, 3)
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blisterUpdate, EntityType.ENTITY_BLISTER)

function mod:blisterDeath(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position, 1.25)
		Isaac.Spawn(EntityType.ENTITY_BOIL, 2, 0, entity.Position, Vector.Zero, nil)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blisterDeath, EntityType.ENTITY_BLISTER)

function mod:blisterProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_BLISTER and projectile:IsDead() then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position, 1.25)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.blisterProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)