local mod = BetterMonsters



function mod:megaClottyUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Attack") then
		entity.Velocity = Vector.Zero
		entity.State = NpcState.STATE_ATTACK
	end

	if sprite:IsEventTriggered("Shoot1") or sprite:IsEventTriggered("Shoot2") or sprite:IsEventTriggered("Shoot3") then
		local mode = 6
		if sprite:IsEventTriggered("Shoot2") then
			mode = 7
		elseif sprite:IsEventTriggered("Shoot3") then
			mode = 8
		end
		entity:FireProjectiles(entity.Position, Vector(10, 0), mode, ProjectileParams())

		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(entity.Scale * 0.75, entity.Scale * 0.75)
		SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.75)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.megaClottyUpdate, EntityType.ENTITY_MEGA_CLOTTY)