local mod = BetterMonsters
local game = Game()



-- [[ Pin / Scolex / Frail ]]--
function mod:pinInit(entity)
	if IRFconfig.hiddenAppearAnims == true and entity.Variant < 3 and not entity.Parent and not entity.SpawnerEntity then
		local sprite = entity:GetSprite()

		sprite:Play("Attack1", true)
		sprite:SetFrame(80)
		entity.State = NpcState.STATE_APPEAR_CUSTOM
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		-- Black Frail fix
		if entity.Variant == 2 and entity.SubType == 1 then
			entity.I2 = 1
			sprite:ReplaceSpritesheet(0, "gfx/bosses/afterbirth/boss_thefrail2_black.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.pinInit, EntityType.ENTITY_PIN)

function mod:pinUpdate(entity)
	local sprite = entity:GetSprite()

	-- Appear animation
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		if sprite:IsFinished("Attack1") then
			entity.State = NpcState.STATE_APPEAR

			-- Black Frail fix
			if entity.Variant == 2 and entity.SubType == 1 then
				entity.I2 = 0
			end
		end

		return true
	end

	-- Dirt effect
	if IRFconfig.clearerHiddenEnemies == true and entity.Variant < 3 and entity:IsFrame(6, 0) and not entity.Parent and entity.Visible == false then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end


	-- Always do tail attack after head attack for Scolex
	if entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK2 and sprite:IsFinished("Attack2") then
		entity.State = NpcState.STATE_ATTACK
		sprite:Play("Attack1", true)
		entity.StateFrame = 0
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.pinUpdate, EntityType.ENTITY_PIN)



-- [[ Polycephalus ]]--
function mod:polycephalusUpdate(entity)
	if IRFconfig.clearerHiddenEnemies == true and entity.Variant == 0 and entity.State == 4 and entity.I1 == 2 and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.polycephalusUpdate, EntityType.ENTITY_POLYCEPHALUS)



--[[ Needle / Pasty ]]--
function mod:needleInit(entity)
	if IRFconfig.hiddenAppearAnims == true then
		entity:GetSprite():Play("Appear", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.needleInit, EntityType.ENTITY_NEEDLE)

function mod:needleUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("Appear") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.needleUpdate, EntityType.ENTITY_NEEDLE)