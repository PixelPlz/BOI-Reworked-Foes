local mod = ReworkedFoes



function mod:SirenUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()


	-- Can't instantly change state when spawning a new one otherwise it crashes the game
	if data.revive then
		entity.State = NpcState.STATE_SPECIAL
		data.revive = nil

		-- Remove skull
		for i, skull in pairs(Isaac.FindByType(entity.Type, 1, -1, false, true)) do
			if skull.Position:Distance(entity.Position) <= 1 then
				skull:Remove()
			end
		end
	end


	-- Reviving
	if entity.State == NpcState.STATE_SPECIAL then
		-- Sike!
		if sprite:GetFrame() == 30 then
			entity.Visible = true

			-- Re-charm the reviver
			local minion = Isaac.Spawn(EntityType.ENTITY_SIREN_HELPER, 0, 0, entity.Position, Vector.Zero, nil):ToNPC()
			minion.Parent = entity
			minion.Target = entity.Target
			minion:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

			entity.Target.Parent = entity
			entity.Target = nil


		-- Restart boss music
		elseif sprite:GetFrame() == 40 then
			Game():GetRoom():PlayMusic()


		-- Item visual + health
		elseif sprite:IsEventTriggered("Sound") then
			-- Item effect
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, entity.Position, Vector.Zero, entity):ToEffect()
			data.itemEffect = effect
			effect:FollowParent(entity)
			effect.DepthOffset = entity.DepthOffset + 1

			local effectSprite = effect:GetSprite()
			effectSprite.Offset = Vector(0, -60)
			effectSprite:Load("gfx/005.100_collectible.anm2", true)
			effectSprite:Play("PlayerPickupSparkle", true)

			-- Heal + proper item sprite
			if entity.I1 == FamiliarVariant.DEAD_CAT then
				entity.HitPoints = entity.MaxHitPoints / 10
				effectSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/collectibles_081_deadcat.png")
			else
				entity.HitPoints = entity.MaxHitPoints / 2
				effectSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/collectibles_011_1up.png")
			end
			effectSprite:LoadGraphics()

			-- Reset back to normal
			entity.I1 = 0
			entity.I2 = 0
			entity:ClearEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)


		-- Get rid of the item visual
		elseif sprite:GetFrame() == 75 then
			data.itemEffect:Remove()
		end
	end


	-- Do fake death if she charmed 1up or Dead Cat
	if entity:HasMortalDamage() then
		for i, minion in pairs(Isaac.FindByType(EntityType.ENTITY_SIREN_HELPER, -1, -1, false, true)) do
			if minion.Parent.Index == entity.Index and minion.Target and (minion.Target.Variant == FamiliarVariant.DEAD_CAT or minion.Target.Variant == FamiliarVariant.ONE_UP) then
				entity.I2 = 100
				entity.Target = minion.Target
				minion:Kill()
				break
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.SirenUpdate, EntityType.ENTITY_SIREN)

function mod:SirenDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity:ToNPC().State == NpcState.STATE_SPECIAL and not entity:GetSprite():WasEventTriggered("Sound") then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SirenDMG, EntityType.ENTITY_SIREN)

-- Create new Siren from revive
function mod:SirenDeath(entity)
	if entity.I2 == 100 then
		local newSiren = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, entity.Position, entity.Velocity, entity):ToNPC()
		newSiren:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		newSiren:GetData().revive = true
		newSiren.Target = entity.Target
		newSiren.I1 = newSiren.Target.Variant
		newSiren.I2 = 100

		newSiren.Visible = false
		newSiren.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		newSiren:AddEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP | EntityFlag.FLAG_HIDE_HP_BAR)

		-- Remove heart drops
		for i, heart in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, -1, false, false)) do
			if heart.SpawnerEntity and heart.SpawnerEntity.Index == entity.Index then
				heart:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.SirenDeath, EntityType.ENTITY_SIREN)

-- Fix for revive familiars not going back to the player
function mod:SirenHelperDeath(entity)
	if entity.Target then
		entity.Target.Parent = nil
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.SirenHelperDeath, EntityType.ENTITY_SIREN_HELPER)