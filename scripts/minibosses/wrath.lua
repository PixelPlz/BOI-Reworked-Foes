local mod = BetterMonsters



function mod:wrathUpdate(entity)
	if mod:CheckForRev() == false and ((entity.Variant == 0 and entity.SubType <= 1) or entity.Variant == 1) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Custom attack
		if entity.State == NpcState.STATE_ATTACK2 then
			-- Prevent Super Wrath from spamming the bombs
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_ATTACK3
			else
				entity.State = NpcState.STATE_MOVE
				sprite:Play(data.lastAnim, true)
			end


		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.Velocity = Vector.Zero

			if sprite:GetFrame() == 4 then
				-- Wrath bomber man bombs
				if entity.Variant == 0 then
					local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
					if entity.SubType == 0 then
						bomb:AddTearFlags(TearFlags.TEAR_CROSS_BOMB)
					elseif entity.SubType == 1 then
						bomb:AddTearFlags(TearFlags.TEAR_BURN)
					end
					bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS


				-- Super Wrath
				elseif entity.Variant == 1 then
					local vector = (target.Position - entity.Position)
					local speed = entity.Position:Distance(target.Position) / 15
					if speed > 12 then
						speed = 12
					end


					local type = BombVariant.BOMB_NORMAL
					local flags = TearFlags.TEAR_NORMAL

					-- Make the second bomb special
					if entity.I2 == 1 then
						local choose = math.random(1, 5)
						if choose == 1 then
							flags = TearFlags.TEAR_BURN

						elseif choose == 2 then
							type = BombVariant.BOMB_SAD_BLOOD
							flags = TearFlags.TEAR_SAD_BOMB

						elseif choose == 3 then
							flags = TearFlags.TEAR_POISON

						elseif choose == 4 then
							flags = TearFlags.TEAR_SCATTER_BOMB

						elseif choose == 5 then
							flags = TearFlags.TEAR_CROSS_BOMB
						end
					end


					local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, type, 0, entity.Position + (vector:Normalized() * 20), vector:Normalized() * speed, entity):ToBomb()
					bomb.PositionOffset = Vector(0, -38) -- 28 is the minimum for it to go over rocks
					bomb:AddTearFlags(flags)
					bomb.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				end
			end


			-- Super Wrath attacks 2 times
			if sprite:IsFinished("Attack") then
				entity.I2 = entity.I2 + 1
				if entity.I2 >= 2 or entity.Variant == 0 then
					entity.I2 = 0
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = 10
				else
					sprite:Play("Attack", true)
				end
			end


		-- Cooldown
		else
			if entity.ProjectileCooldown > 0 then
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
			data.lastAnim = sprite:GetAnimation()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wrathUpdate, EntityType.ENTITY_WRATH)

-- Don't take damage from non-player explosions
function mod:wrathDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod:CheckForRev() == false and damageSource.SpawnerType ~= EntityType.ENTITY_PLAYER and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.wrathDMG, EntityType.ENTITY_WRATH)



function mod:championWrathReward(entity)
	-- Hot Bombs
	if mod:CheckForRev() == false and entity.SpawnerType == EntityType.ENTITY_WRATH and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= 256 then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 256, false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championWrathReward, PickupVariant.PICKUP_COLLECTIBLE)