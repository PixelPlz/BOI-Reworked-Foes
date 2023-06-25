local mod = BetterMonsters



function mod:wrathUpdate(entity)
	if mod:CheckValidMiniboss(entity) == true then
		local sprite = entity:GetSprite()

		-- Fire effects for Burning Wrath
		if entity.Variant == 0 and entity.SubType == 1 then
			if entity.I2 == 0 then
				mod:LoopingOverlay(sprite, "FireAppear", true)
				if sprite:GetOverlayFrame() == 11 then
					entity.I2 = 1
				end

			else
				mod:LoopingOverlay(sprite, "Fire", true)
				mod:EmberParticles(entity, Vector(0, -40))
			end


		-- Super Wrath
		elseif entity.Variant == 1 then
			if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK then
				entity:GetData().lastAnim = sprite:GetAnimation()

				-- Attack cooldown
				if entity.StateFrame > 0 then
					entity.StateFrame = entity.StateFrame - 1
				end

				-- Faster charge (yes, he can charge at you)
				if entity.State == NpcState.STATE_ATTACK then
					entity.V2 = entity.V2:Resized(1.5)
				end


			-- Replace original attack
			elseif entity.State == NpcState.STATE_ATTACK2 then
				if entity.StateFrame <= 0 then
					entity.State = NpcState.STATE_ATTACK3
					entity.I1 = 0
				else
					entity.State = NpcState.STATE_MOVE
					sprite:Play(entity:GetData().lastAnim, true)
				end


			-- Custom attack
			elseif entity.State == NpcState.STATE_ATTACK3 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:GetFrame() == 4 then
					local target = entity:GetPlayerTarget()
					local vector = (target.Position - entity.Position):Normalized()
					local speed = math.min(12, entity.Position:Distance(target.Position) / 15)

					local type = BombVariant.BOMB_NORMAL
					local flags = TearFlags.TEAR_NORMAL

					-- Second bomb has bomb effects
					if entity.I1 == 1 then
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

					local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, type, 0, entity.Position + vector:Resized(20), vector:Resized(speed), entity):ToBomb()
					bomb.PositionOffset = Vector(0, -38) -- 28 is the minimum for it to go over rocks
					bomb:AddTearFlags(flags)
					bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

					entity.I1 = entity.I1 + 1
				end

				if sprite:IsFinished() then
					-- Attack twice
					if entity.I1 >= 2 then
						entity.State = NpcState.STATE_MOVE
						entity.StateFrame = 30
					else
						sprite:Play("Attack", true)
					end
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wrathUpdate, EntityType.ENTITY_WRATH)

function mod:wrathBombInit(bomb)
	if bomb.SpawnerType == EntityType.ENTITY_WRATH and bomb.SpawnerEntity and mod:CheckValidMiniboss(bomb.SpawnerEntity) == true and bomb.SpawnerVariant == 0 then
		-- Hot Bombs for champion Wrath
		if bomb.SpawnerEntity.SubType == 1 then
			bomb:AddTearFlags(TearFlags.TEAR_BURN)

		-- Bomber Boy bombs for regular Wrath
		else
			bomb:AddTearFlags(TearFlags.TEAR_CROSS_BOMB)
			bomb.Velocity = Vector.Zero
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, mod.wrathBombInit, BombVariant.BOMB_NORMAL)

-- Don't take damage from non-player explosions
function mod:wrathDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:CheckForRev() == false and damageSource.SpawnerType ~= EntityType.ENTITY_PLAYER and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.wrathDMG, EntityType.ENTITY_WRATH)



function mod:championWrathReward(entity)
	-- Hot Bombs
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_WRATH and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= CollectibleType.COLLECTIBLE_HOT_BOMBS then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_HOT_BOMBS, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championWrathReward, PickupVariant.PICKUP_COLLECTIBLE)