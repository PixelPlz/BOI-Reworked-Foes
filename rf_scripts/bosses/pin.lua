local mod = ReworkedFoes



--[[ Appear animations for Pin / Scolex / Frail ]]--
function mod:PinAppearInit(entity)
	if mod.Config.AppearPins == true and entity.Variant < 3 -- If it's not Wormwood
	and not entity.Parent and not entity.SpawnerEntity -- Only the head
	and (not FiendFolio or entity.SubType ~= 2) -- Not Fiend Folio Technopin
	and (not GBMd or entity.Variant > 0) then -- Not the Greed Mode skin for Pin (it fucks with the animations for some reason)
		local sprite = entity:GetSprite()

		sprite:Play("Attack1", true)
		entity.State = NpcState.STATE_APPEAR_CUSTOM
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		local frame = 80
		if entity.Variant == 1 then
			frame = 46
		end
		sprite:SetFrame(frame)

		-- Black Frail fix
		if entity.Variant == 2 and entity.SubType == 1 then
			entity.I2 = 1
			sprite:ReplaceSpritesheet(0, "gfx/bosses/afterbirth/boss_thefrail2_black.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PinAppearInit, EntityType.ENTITY_PIN)

function mod:PinAppearUpdate(entity)
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		if entity:GetSprite():IsFinished() then
			entity.State = NpcState.STATE_APPEAR

			-- Black Frail fix
			if entity.Variant == 2 and entity.SubType == 1 then
				entity.I2 = 0
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.PinAppearUpdate, EntityType.ENTITY_PIN)



--[[ Increase Pin's HP ]]--
function mod:PinInit(entity)
	if entity.Variant == 0 then
		local newHealth = 140
		if entity.SubType == 1 then
			newHealth = 175
		end

		entity.MaxHitPoints = newHealth
		entity.HitPoints = entity.MaxHitPoints
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PinInit, EntityType.ENTITY_PIN)



--[[ Burrowing indicator ]]--
function mod:PinUpdate(entity)
	if mod.Config.NoHiddenPins == true and entity.Variant < 3 -- If it's not Wormwood
	and not entity.Parent and entity.Visible == false -- Only the head while it's underground
	and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PinUpdate, EntityType.ENTITY_PIN)