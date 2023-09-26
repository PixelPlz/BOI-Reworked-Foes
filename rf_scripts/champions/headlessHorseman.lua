local mod = ReworkedFoes



--[[ Body ]]--
function mod:PurpleHeadlessHorsemanBodyUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()

		-- Replace shooting attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK2

		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:GetFrame() == 10 then
				entity:FireProjectiles(entity.Position, Vector(12, 6), 9, ProjectileParams())
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT)
			end

			if sprite:IsFinished("Attack") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PurpleHeadlessHorsemanBodyUpdate, EntityType.ENTITY_HEADLESS_HORSEMAN)



--[[ Head ]]--
function mod:PurpleHeadlessHorsemanHeadUpdate(entity)
	if entity.SubType == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		-- Appear horizontally to the target
		if entity.State == NpcState.STATE_ATTACK then
			local room = Game():GetRoom()

			if entity.Position.X >= room:GetBottomRightPos().X + 200 or entity.Position.X <= room:GetTopLeftPos().X - 200 then
				entity.Position = Vector(entity.Position.X, target.Position.Y)
			end


		-- Replace shooting attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			entity.State = NpcState.STATE_ATTACK3

		elseif entity.State == NpcState.STATE_ATTACK3 then
			if sprite:GetFrame() == 13 then
				entity:FireBossProjectiles(10, target.Position, 2, ProjectileParams())
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_2)
			end

			if sprite:IsFinished("Attack") then
				entity.State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PurpleHeadlessHorsemanHeadUpdate, EntityType.ENTITY_HORSEMAN_HEAD)

function mod:PurpleHeadlessHorsemanCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_HORSEMAN_HEAD then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.PurpleHeadlessHorsemanCollision, EntityType.ENTITY_HEADLESS_HORSEMAN)