local mod = ReworkedFoes



function mod:UlcerUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	-- Replace default attack
	if entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("DigOut") then
		entity.State = NpcState.STATE_ATTACK2


	-- Custom attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if sprite:IsEventTriggered("Shoot") then
			-- Spawn a Dip
			if (entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == true and Isaac.CountEntities(nil, EntityType.ENTITY_FAMILIAR, FamiliarVariant.DIP, -1) < 8) -- If there are less than 8 friendly Dips
			or (entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == false and entity.Pathfinder:HasPathToPos(target.Position, false) -- If the player can get to it
			and Isaac.CountEntities(entity, EntityType.ENTITY_DIP, -1, -1) < 3 and Isaac.CountEntities(nil, EntityType.ENTITY_DIP, -1, -1) < 5) then -- If there are less than 3 from me / 5 overall
				local pos = entity.Position + (target.Position - entity.Position):Resized(mod:Random(80, 120))
				mod:ThrowDip(entity.Position, entity, pos, mod:Random(1), -20)

			-- Shoot if there are too many Dips
			else
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_PUKE
				params.GridCollision = false
				params.Scale = 1.5
				params.FallingAccelModifier = 1.5
				params.FallingSpeedModifier = -25

				local speed = entity.Position:Distance(target.Position) / 20
				speed = math.min(9, speed)
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(speed), 0, params)
			end

			-- Effects
			mod:PlaySound(entity, SoundEffect.SOUND_WORM_SPIT, 1.25)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOP_EXPLOSION, 0, entity.Position, Vector.Zero, entity).SpriteOffset = Vector(0, entity.Scale * -12)
		end

		if sprite:IsFinished("DigOut") then
			entity.State = NpcState.STATE_JUMP
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.UlcerUpdate, EntityType.ENTITY_ULCER)

function mod:UlcerCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_DIP then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.UlcerCollision, EntityType.ENTITY_ULCER)