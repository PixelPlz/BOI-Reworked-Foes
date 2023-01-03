local mod = BetterMonsters



function mod:pinUpdate(entity)
	local sprite = entity:GetSprite()

	-- Always do tail attack after head attack for Scolex
	if entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK2 and sprite:IsFinished("Attack2") then
		entity.State = NpcState.STATE_ATTACK
		sprite:Play("Attack1", true)
		entity.StateFrame = 0


	-- Black Champion Frail spiders
	elseif entity.Variant == 2 and entity.SubType == 1 then
		if entity.State == NpcState.STATE_ATTACK2 then
			if sprite:IsPlaying("Attack2") and sprite:GetFrame() == 44 then
				entity.State = NpcState.STATE_SUMMON
			end
		
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetFrame() == 45 then
				local offset = math.random(0, 359)
				for i = 0, 2 do
					EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (Vector.FromAngle(offset + (i * 120)) * math.random(80, 120)), false, -50)
				end
				entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_2, 1, 0, false, 1)
			
			elseif sprite:GetFrame() == 48 then
				entity.State = NpcState.STATE_ATTACK2
				entity.StateFrame = 48
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.pinUpdate, EntityType.ENTITY_PIN)

function mod:pinDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_PIN and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.pinDMG, EntityType.ENTITY_PIN)