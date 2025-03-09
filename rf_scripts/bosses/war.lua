local mod = ReworkedFoes



function mod:WarUpdate(entity)
	--[[ 1st phase projectile attack nerf ]]--
	if (entity.Variant == 0 or entity.Variant == 1)
	and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() <= 1 then
		entity.StateFrame = entity.StateFrame - 3



	--[[ 2nd phase ]]--
	elseif entity.Variant == 10 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Handle the walking animation stuff
		local function handleWalkingAnimations(anim)
			mod:LoopingAnim(sprite, anim)
			sprite.PlaybackSpeed = entity.Velocity:Length() / 5.2

			if entity.Velocity:Length() <= 0.1 then
				sprite:SetFrame(0)
			else
				mod:FlipTowardsMovement(entity, sprite)
			end
		end



		--[[ Crying ;( ]]--
		if entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
			elseif sprite:IsEventTriggered("Sound") then
				mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = mod:Random(30, 60)
			end



		--[[ Chasing ]]--
		elseif entity.State == NpcState.STATE_MOVE then
			local speed = entity.SubType == 1 and 4 or 5
			mod:ChasePlayer(entity, speed)
			handleWalkingAnimations("WalkHori")

			-- Pull out a bomb
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_SUMMON
				sprite:Play("PullOutBomb", true)
				entity.ProjectileCooldown = mod:Random(45, 90)
				entity.StateFrame = 0
				sprite.PlaybackSpeed = 1
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Bomb chase ]]--
		elseif entity.State	== NpcState.STATE_SUMMON then
			-- Pull out the bomb
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Sound") then
					mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP, 1.1, 0.9)
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
				end

			-- Chasing
			elseif entity.StateFrame == 1 then
				local speed = entity.SubType == 1 and 6.5 or 7.5
				mod:ChasePlayer(entity, speed)
				handleWalkingAnimations("RunBomb")

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					entity.ProjectileCooldown = mod:Random(30, 60)
					entity.StateFrame = 0
					sprite.PlaybackSpeed = 1

					-- Kamikaze
					if mod:Random(1) == 1 then
						entity.State = NpcState.STATE_ATTACK3
						sprite:Play("Idiot", true)
					-- Throw
					else
						entity.State = NpcState.STATE_ATTACK2
						sprite:Play("ThrowBomb", true)
					end

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			end



		--[[ Throw attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Face towards the target
			if not sprite:WasEventTriggered("Shoot") then
				mod:FlipTowardsTarget(entity, sprite)
			end

			if sprite:IsEventTriggered("Shoot") then
				local pos = target.Position + (target.Velocity * 40)
				local vector = pos - entity.Position
				local speed = math.min(18, vector:Length() / 15)

				local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, 0, entity.Position, vector:Resized(speed), entity):ToBomb()
				bomb.PositionOffset = Vector(0, -50)
				bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				bomb:GetSprite():Play("Pulse", true)
				bomb:SetExplosionCountdown(mod:Random(20, 30))

				-- Effects
				sprite.FlipX = vector.X < 0
				mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP, 1.1, 0.9)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Kamikaze attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK3 then
			-- Start the fling
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				-- Face away from the target
				if sprite:WasEventTriggered("Sound") and not sprite:WasEventTriggered("Shoot") then
					mod:FlipTowardsTarget(entity, sprite, true)
				end

				-- Effects
				if sprite:IsEventTriggered("Shoot") then
					entity.V2 = target.Position - entity.Position
				elseif sprite:IsEventTriggered("Sound") then
					mod:PlaySound(nil, SoundEffect.SOUND_FETUS_LAND, 1.2)
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_1)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
					entity.TargetPosition = Vector(28, 0)
					entity.Velocity = entity.V2:Resized(entity.TargetPosition.X)
					entity.PositionOffset = Vector(0, -12)

					Game():BombExplosionEffects(entity.Position, 40, TearFlags.TEAR_NORMAL, Color.Default, entity, 1, true, true, DamageFlag.DAMAGE_EXPLOSION)
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

					-- Champion shots
					if entity.SubType == 1 then
						entity:FireProjectiles(entity.Position, Vector(11, 6), 9, ProjectileParams())
					end
				end


			-- Midair
			elseif entity.StateFrame == 1 or entity.StateFrame == 2 then
				entity.Velocity = entity.Velocity:Resized(entity.TargetPosition.X)
				mod:LoopingAnim(sprite, "Fly")
				mod:FlipTowardsMovement(entity, sprite, true)

				for i = 1, 2 do
					mod:SmokeParticles(entity, entity.PositionOffset + Vector(0, -15), 0, Vector(100, 120), Color(1,1,1, 1, 0.1,0.1,0.1))
				end


				-- Falling down
				if entity.StateFrame == 2 then
					-- Land
					if entity.PositionOffset.Y >= 0 then
						entity.StateFrame = 3
						sprite:Play("Land", true)
						entity.PositionOffset = Vector.Zero
						entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
						entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

						mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)

					else
						entity.V1 = Vector(0, entity.V1.Y - 0.8)
						entity.PositionOffset = Vector(0, math.min(0, entity.PositionOffset.Y - entity.V1.Y))
					end

				-- Start falling down if the speed is low enough
				elseif entity.Velocity:Length() <= 12 then
					entity.StateFrame = 2
					entity.V1 = Vector(0, 5)
				end


				-- Slow down when bouncing off of obstacles
				if entity:CollidesWithGrid() then
					local newX = math.max(0, entity.TargetPosition.X - 6)
					entity.TargetPosition = Vector(newX, entity.TargetPosition.Y)
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS, 0.75, math.random(95, 105) / 100, 6)
				end


			-- Landed
			elseif entity.StateFrame == 3 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Sound") then
					mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.WarUpdate, EntityType.ENTITY_WAR)

function mod:WarDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Entity and (damageSource.Type == entity.Type or damageSource.Entity.SpawnerType == entity.Type) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.WarDMG, EntityType.ENTITY_WAR)



-- Champion Sad Troll Bombs
function mod:WarBombInit(bomb)
	if bomb.SpawnerType == EntityType.ENTITY_WAR and (bomb.SpawnerVariant == 0 or bomb.SpawnerVariant == 10)
	and bomb.SpawnerEntity and bomb.SpawnerEntity.SubType == 1 then
		bomb:GetData().warSadBomb = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, mod.WarBombInit, BombVariant.BOMB_TROLL)

function mod:WarBombExplosion(bomb)
	if bomb:IsDead() and bomb:GetData().warSadBomb then
		local offset = mod:Random(359)

		for i = 1, 6 do
			local angle = offset + i * (360 / 6)
			local vector = Vector.FromAngle(angle):Resized(11)
			Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, bomb.Position, vector, bomb.SpawnerEntity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.WarBombExplosion, BombVariant.BOMB_TROLL)

-- Ignore collision with his own bombs
function mod:WarBombCollision(bomb, collider, bool)
	if bomb.SpawnerType == EntityType.ENTITY_WAR and collider.Type == EntityType.ENTITY_WAR then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_BOMB_COLLISION, mod.WarBombCollision)