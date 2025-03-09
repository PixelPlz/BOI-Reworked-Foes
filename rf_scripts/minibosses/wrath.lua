local mod = ReworkedFoes



function mod:WrathUpdate(entity)
	if mod:CheckValidMiniboss() then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Fire effects for champion
		if entity.Variant == 0 and mod:IsRFChampion(entity, "Wrath") then
			mod:EmberParticles(entity, Vector(0, -40))

			-- Fire overlay
			if entity.State == NpcState.STATE_MOVE then
				mod:LoopingOverlay(sprite, "Fire", true)
			else
				sprite:RemoveOverlay()
			end
		end


		-- Replace charge with custom bomb attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK3
			sprite:Play("Attack", true)

		-- Custom bomb attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:GetFrame() == 4 then
				local vector = (target.Position - entity.Position):Normalized()
				vector = mod:ClampVector(vector, 90)

				-- Champion
				if mod:IsRFChampion(entity, "Wrath") then
					local rocket = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_ROCKET, 0, entity.Position + vector:Resized(20), vector:Resized(2), entity):ToBomb()
					rocket.RadiusMultiplier = 0.75
					rocket:SetRocketAngle(vector:GetAngleDegrees())
					rocket:SetRocketSpeed(-5)
					rocket:Update()
					mod:PlaySound(nil, SoundEffect.SOUND_ROCKET_LAUNCH_SHORT, 0.75)


				-- Regular / Super
				else
					local speed = math.min(13, entity.Position:Distance(target.Position) / 15)
					local throwHeight = -28

					local type = BombVariant.BOMB_NORMAL
					local flags = TearFlags.TEAR_NORMAL

					-- Super Wrath has special bombs
					if entity.Variant == 1 then
						throwHeight = -36
						local choose = mod:Random(3)

						-- Scatter Bombs
						if choose == 0 then
							flags = TearFlags.TEAR_SCATTER_BOMB

						-- Bob's Curse
						elseif choose == 1 then
							flags = TearFlags.TEAR_POISON

						-- Hot Bombs
						elseif choose == 2 then
							flags = TearFlags.TEAR_BURN

						-- Sad Bombs
						elseif choose == 3 then
							type = BombVariant.BOMB_SAD_BLOOD
							flags = TearFlags.TEAR_SAD_BOMB
						end
					end

					local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, type, 40, entity.Position + vector:Resized(entity.Size), vector:Resized(speed), entity):ToBomb()
					bomb.PositionOffset = Vector(0, throwHeight) -- 28 is the minimum for it to go over rocks
					bomb:AddTearFlags(flags)
					bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

					mod:PlaySound(nil, SoundEffect.SOUND_FETUS_JUMP, 1, 0.9)

					-- Make him run away from where he threw the bomb
					entity.V1 = bomb.Position
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE

				-- Make him run away from where he threw the bomb if not champion
				if mod:IsRFChampion(entity, "Wrath") then
					entity.StateFrame = 10
				else
					entity.StateFrame = 60
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.WrathUpdate, EntityType.ENTITY_WRATH)

-- Don't take damage from non-player explosions
function mod:WrathDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:CheckValidMiniboss() and damageSource.SpawnerType ~= EntityType.ENTITY_PLAYER and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0)
	and Isaac.GetChallenge() ~= Challenge.CHALLENGE_HOT_POTATO then -- HOT POTATO EXPLOSIONS DOESN'T COUNT AS PLAYER EXPLOSIONS FUCK THIS GAME
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.WrathDMG, EntityType.ENTITY_WRATH)



-- Replace regular bombs
function mod:WrathBombInit(bomb)
	if bomb.SpawnerType == EntityType.ENTITY_WRATH and mod:CheckValidMiniboss()
	and bomb.SpawnerVariant == 0 and bomb.SubType ~= 40 then
		-- Hot Bombs for champion Wrath
		if mod:IsRFChampion(bomb.SpawnerEntity, "Wrath") then
			bomb:AddTearFlags(TearFlags.TEAR_BURN)
			bomb.Velocity = Vector.Zero

		-- Mr. Mega bombs for regular Wrath
		else
			bomb:Remove()
			local newBomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_MR_MEGA, 40, bomb.Position, Vector.Zero, bomb.SpawnerEntity):ToBomb()
			newBomb.RadiusMultiplier = 1.4
		end

		mod:PlaySound(nil, SoundEffect.SOUND_FETUS_LAND)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, mod.WrathBombInit, BombVariant.BOMB_NORMAL)

function mod:WrathBombCollision(bomb, collider, bool)
	if bomb.SpawnerType == EntityType.ENTITY_WRATH then
		-- Champion rockets
		if bomb.Variant == BombVariant.BOMB_ROCKET
		and ((collider.Type == EntityType.ENTITY_FIREPLACE and collider.Variant >= 10) -- Go through fires from Hot Bombs
		or collider.Type == EntityType.ENTITY_PLAYER) then -- Don't go through players
			-- Explode on collision with players
			if collider.Type == EntityType.ENTITY_PLAYER then
				bomb:SetExplosionCountdown(0)
			end
			return true

		-- Bombs placed by Wrath
		elseif collider.Type == EntityType.ENTITY_WRATH then
			return true -- I have to make the bombs ignore the collision instead of Wrath otherwise they can still go through them for some reason
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_BOMB_COLLISION, mod.WrathBombCollision)



function mod:ChampionWrathReward(pickup)
	-- Hot Bombs
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_WRATH, "Wrath")
	and pickup.SubType ~= CollectibleType.COLLECTIBLE_HOT_BOMBS then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_HOT_BOMBS, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionWrathReward, PickupVariant.PICKUP_COLLECTIBLE)