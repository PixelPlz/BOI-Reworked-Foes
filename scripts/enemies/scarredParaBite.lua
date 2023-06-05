local mod = BetterMonsters



function mod:scarredParaBiteInit(entity)
	if entity.Variant == 1 then
		entity.I1 = mod:Random(60, 120)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.scarredParaBiteInit, EntityType.ENTITY_PARA_BITE)

function mod:scarredParaBiteUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Prevent regular shots
		entity.ProjectileCooldown = 100

		if entity.State == NpcState.STATE_MOVE then
			if entity.I1 <= 0 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Attack", true)
			else
				entity.I1 = entity.I1 - 1
			end


		-- Attack
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS2_BUBBLES, 0.6)

				-- Effect
				if sprite:GetFrame() < 12 then
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Scale = Vector(entity.Scale * 0.5, entity.Scale * 0.5)
					effect.Offset = Vector(entity.Scale * 3, entity.Scale * -6)
				end

				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 90

				params.Acceleration = 1.1
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.2
				params.Scale = 1 + mod:Random(5) * 0.1

				entity:FireProjectiles(entity.Position, mod:RandomVector(mod:Random(3, 5)), 0, params)
			end

			if sprite:GetFrame() == 28 then
				entity.I1 = mod:Random(90, 180)

				if mod:Random(1) == 1 then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("DigIn", true)
				else
					entity.State = NpcState.STATE_MOVE
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.scarredParaBiteUpdate, EntityType.ENTITY_PARA_BITE)