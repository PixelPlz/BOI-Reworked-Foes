local mod = ReworkedFoes



function mod:ScarredParaBiteInit(entity)
	if entity.Variant == 1 then
		entity.I1 = mod:Random(60, 120)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ScarredParaBiteInit, EntityType.ENTITY_PARA_BITE)

function mod:ScarredParaBiteUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Stop the default shots
		entity.ProjectileCooldown = 100


		-- Custom attack
		if entity.State == NpcState.STATE_MOVE then
			if entity.I1 <= 0 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Attack", true)
				entity.I1 = mod:Random(60, 120)
				entity.I2 = 0

			else
				entity.I1 = entity.I1 - 1
			end

		-- Attacking
		elseif entity.State == NpcState.STATE_ATTACK and sprite:IsEventTriggered("Shoot") then
			entity:FireBossProjectiles(1, Vector.Zero, 4, ProjectileParams())
			entity.I2 = entity.I2 + 1

			if entity.I2 % 2 == 0 then
				mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 0.9)
				mod:ShootEffect(entity, 2, Vector(0, -18))
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ScarredParaBiteUpdate, EntityType.ENTITY_PARA_BITE)