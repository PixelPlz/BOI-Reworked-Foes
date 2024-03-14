local mod = ReworkedFoes



function mod:EternalFlyInit(entity)
	if entity.Type == EntityType.ENTITY_ETERNALFLY
	or (FiendFolio and entity.Type == FiendFolio.FF.DeadFlyOrbital.ID and entity.Variant == FiendFolio.FF.DeadFlyOrbital.Var) then
		entity:GetData().isEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.EternalFlyInit)

function mod:EternalFlyUpdate(entity)
	-- Make them properly keep up with their parents
	if entity.Parent then
		entity.Velocity = entity.Parent.Velocity
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EternalFlyUpdate, EntityType.ENTITY_ETERNALFLY)



function mod:EternalFlyConvert(entity)
	if mod.Config.ClassicEternalFlies == true and not entity:GetData().ConvertedEternalFly
	and (entity:GetData().isEternalFly or entity.SubType == 96) then
		entity:GetSprite():Load("gfx/018.000_attack eternal fly.anm2", true)
		entity.SubType = 96

		entity.MaxHitPoints = 10
		entity.HitPoints = entity.MaxHitPoints
		entity:SetSize(11, Vector(1, 1), 4)
		entity.I1 = 0

		entity:GetData().isEternalFly = nil
		entity:GetData().ConvertedEternalFly = true
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.EternalFlyConvert, EntityType.ENTITY_ATTACKFLY)

-- RAT TIME!!!
function mod:EternalFlyBloodExplosion(entity)
    if entity.SubType == 96 then
		for _, effect in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.FLY_EXPLOSION, -1, false, false)) do
			if effect.Position:Distance(entity.Position) <= 16 and effect.FrameCount == 0 then
				local sprite = effect:GetSprite()
				sprite:ReplaceSpritesheet(0, "gfx/monsters/classic/monster_010_eternalfly.png")
				sprite:LoadGraphics()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.EternalFlyBloodExplosion, EntityType.ENTITY_ATTACKFLY)