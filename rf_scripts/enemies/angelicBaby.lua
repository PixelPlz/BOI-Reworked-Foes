local mod = ReworkedFoes



function mod:AngelicBabyInit(entity)
	if entity.Variant == 1 and entity.SubType == 0 and entity.SpawnerType == EntityType.ENTITY_GABRIEL then
		-- Turn Fallen Gabriel's angels into Imps
		if entity.SpawnerVariant == 1 then
			entity:Morph(EntityType.ENTITY_IMP, 0, 0, entity:GetChampionColorIdx())
		-- Turn regular Gabriel's angels into small ones
		else
			entity:Morph(entity.Type, 1, 1, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.AngelicBabyInit, EntityType.ENTITY_BABY)

function mod:BabyUpdate(entity)
	local sprite = entity:GetSprite()

	-- Stop them from moving while teleporting
	if sprite:IsPlaying("Vanish2") then
		entity.Velocity = Vector.Zero
	end


	-- Angelic Babies create a lightbeam at their teleport destination
	if entity.Variant == 1 and entity.SubType == 0 then
		if sprite:IsPlaying("Vanish") and sprite:IsEventTriggered("Jump") then
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 2, entity.TargetPosition, Vector.Zero, entity).DepthOffset = entity.DepthOffset - 10

		-- Projectiles
		elseif sprite:IsPlaying("Vanish2") and sprite:GetFrame() == 2 then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Color = Color(1,1,1, 1, 0.25,0.25,0.25)
			entity:FireProjectiles(entity.Position, Vector(10, 4), 6, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BabyUpdate, EntityType.ENTITY_BABY)