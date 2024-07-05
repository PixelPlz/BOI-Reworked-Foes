local mod = ReworkedFoes



function mod:AdultLeechUpdate(entity)
	-- Don't move while burrowing
	if entity.State == NpcState.STATE_JUMP then
		entity.Velocity = Vector.Zero


	-- Limit their charging speed
	elseif entity.State == NpcState.STATE_ATTACK then
		local length = math.min(22, entity.Velocity:Length())
		entity.Velocity = entity.Velocity:Resized(length)


	-- 50% chance to do the cut attack
	elseif entity.State == NpcState.STATE_STOMP and entity:GetSprite():GetFrame() == 0
	and mod:Random(1) == 1 then
		local target = entity:GetPlayerTarget()
		local room = Game():GetRoom()


		entity.State = NpcState.STATE_ATTACK2
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		entity.Visible = true

		-- Get the charge positions
		local leftPos  = Vector(room:GetTopLeftPos().X, 	target.Position.Y)
		local rightPos = Vector(room:GetBottomRightPos().X, target.Position.Y)

		-- Choose the closest one to the target
		if target.Position:Distance(leftPos) < target.Position:Distance(rightPos) then
			entity.Position = leftPos
			entity.TargetPosition = Vector(1, 0)
		else
			entity.Position = rightPos
			entity.TargetPosition = Vector(-1, 0)
		end

		entity:Update()


		-- Effects
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 4, entity.Position, entity.TargetPosition:Resized(4), entity):GetSprite()
		effect.Color = mod:ColorEx(Color(1,1,1, 1), {2.4, 0.7, 0.7, 1})
		effect.Offset = Vector(0, -14)

		mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_BURST_OUT, 0.9)
		mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS, 0.9)

		-- Rocks
		for i = 1, 5 do
			local vector = entity.TargetPosition:Rotated(math.random(-30, 30)):Resized(math.random(4, 6))
			local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, room:GetBackdropType(), entity.Position, vector, entity):ToEffect()
			rocks:GetSprite():Play("rubble", true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.AdultLeechUpdate, EntityType.ENTITY_ADULT_LEECH)