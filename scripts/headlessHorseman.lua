local mod = BetterMonsters
local game = Game()



function mod:headlessHorsemanBodyUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		-- Replace shooting attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK2
		
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:GetFrame() == 10 then
				entity:FireProjectiles(entity.Position, Vector(11, 6), 9, ProjectileParams())
				entity:PlaySound(SoundEffect.SOUND_HEARTOUT, 1, 0, false, 1)
			end

			if sprite:IsFinished("Attack") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.headlessHorsemanBodyUpdate, EntityType.ENTITY_HEADLESS_HORSEMAN)

function mod:headlessHorsemanHeadUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		-- Charge at the target horizontally
		if entity.State == NpcState.STATE_ATTACK then
			local room = game:GetRoom()

			if entity.Position.X > room:GetBottomRightPos().X + 120 or entity.Position.X < room:GetTopLeftPos().X - 120 then
				entity.Position = Vector(entity.Position.X, entity:GetPlayerTarget().Position.Y)
			end
		
		-- Replace shooting attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			entity.State = NpcState.STATE_ATTACK3
		
		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 13 then
				entity:FireBossProjectiles(10, entity:GetPlayerTarget().Position, 2, ProjectileParams())
				entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_2, 1, 0, false, 1)
			end

			if sprite:IsFinished("Attack") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.headlessHorsemanHeadUpdate, EntityType.ENTITY_HORSEMAN_HEAD)

function mod:headlessHorsemanCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_HORSEMAN_HEAD then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.headlessHorsemanCollide, EntityType.ENTITY_HEADLESS_HORSEMAN)