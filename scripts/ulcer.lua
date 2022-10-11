local mod = BetterMonsters
local game = Game()



function mod:ulcerUpdate(entity)
	local sprite = entity:GetSprite()
	
	if entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("DigOut") then
		entity.State = NpcState.STATE_ATTACK2

	elseif entity.State == NpcState.STATE_ATTACK2 then
		if sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_WORM_SPIT, 1.25, 0, false, 1)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOP_EXPLOSION, 0, entity.Position, Vector.Zero, entity).SpriteOffset = Vector(0, -12)

			if Isaac.CountEntities(entity, EntityType.ENTITY_DIP, -1, -1) < 4 and entity.Pathfinder:HasPathToPos(entity:GetPlayerTarget().Position, false) == true then
				Isaac.Spawn(EntityType.ENTITY_DIP, math.random(0, 1), 0, entity.Position - Vector(0, 5), Vector.Zero, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)

			else
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_PUKE
				params.FallingAccelModifier = 0.2
				entity:FireBossProjectiles(6, Vector.Zero, 9, params)
			end
		end
		
		if sprite:IsFinished("DigOut") then
			entity.State = NpcState.STATE_JUMP
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ulcerUpdate, EntityType.ENTITY_ULCER)

function mod:ulcerCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_DIP then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.ulcerCollide, EntityType.ENTITY_ULCER)