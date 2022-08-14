local mod = BetterMonsters
local game = Game()



function mod:wrathUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	-- Custom attack
	if entity.State == NpcState.STATE_ATTACK2 then
		entity.State = NpcState.STATE_ATTACK3

	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = Vector.Zero

		if sprite:GetFrame() == 4 then
			-- Wrath bomber man bombs
			if entity.Variant == 0 and entity.SubType == 0 then
				local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
				bomb:AddTearFlags(TearFlags.TEAR_CROSS_BOMB)
				bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS


			-- Super Wrath
			elseif entity.Variant == 1 or entity.SubType == 1 then
				local vector = (target.Position - entity.Position)
				local speed = entity.Position:Distance(target.Position) / 15
				if speed > 12 then
					speed = 12
				end


				local type = BombVariant.BOMB_NORMAL
				local flags = TearFlags.TEAR_NORMAL

				-- Make the second bomb special for Super Wrath
				if entity.Variant == 1 and entity.I2 == 1 then
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
				
				-- Champion Wrath
				elseif entity.Variant == 0 and entity.SubType == 1 then
					flags = TearFlags.TEAR_BURN
				end


				local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, type, 0, entity.Position + (vector:Normalized() * 20), vector:Normalized() * speed, entity):ToBomb()
				bomb.PositionOffset = Vector(0, -28 - (entity.Variant * 10)) -- 28 is the minimum for it to go over rocks
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
			else
				sprite:Play("Attack", true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wrathUpdate, EntityType.ENTITY_WRATH)

function mod:wrathDeath(entity)
	game:BombExplosionEffects(entity.Position, 100, TearFlags.TEAR_NORMAL, Color.Default, entity, 1 + (entity.Variant * 0.3), true, true, DamageFlag.DAMAGE_EXPLOSION)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.wrathDeath, EntityType.ENTITY_WRATH)

-- Don't take damage from non-player explosions
function mod:wrathDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType ~= EntityType.ENTITY_PLAYER and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.wrathDMG, EntityType.ENTITY_WRATH)



function mod:championWrathReward(entity)
	if entity.SpawnerType == EntityType.ENTITY_WRATH and entity.SpawnerEntity and entity.SpawnerEntity.SubType == 1 and entity.SubType ~= Isaac.GetItemIdByName("Hot Bombs") then
		entity:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, Isaac.GetItemIdByName("Hot Bombs"), false, true, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.championWrathReward, PickupVariant.PICKUP_COLLECTIBLE)