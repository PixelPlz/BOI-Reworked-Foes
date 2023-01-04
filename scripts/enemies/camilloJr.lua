local mod = BetterMonsters



function mod:camilloJrUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	if entity.State == NpcState.STATE_MOVE then
		mod:LoopingAnim(sprite, "FloatDown")
		-- Face towards the player
		if target.Position.X < entity.Position.X then
			sprite.FlipX = true
		else
			sprite.FlipX = false
		end

		if entity.ProjectileCooldown <= 0 then
			if entity.Position:Distance(target.Position) <= 200 then
				entity.State = NpcState.STATE_ATTACK2
				sprite:Play("Attack", true)
			end
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if entity.I1 == 1 then
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end
		mod:LoopingAnim(sprite, "Attack")

		if sprite:IsEventTriggered("Worm") then
			entity.I1 = 1
			entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 1.2, 0, false, 1)
			mod:shootEffect(entity, 2, Vector(0, -14), nil, 1, true)

			local worm = Isaac.Spawn(EntityType.ENTITY_VIS, 22, 230, entity.Position, (target.Position - entity.Position):Normalized() * 20, entity)
			worm.Parent = entity
			worm.DepthOffset = entity.DepthOffset + 400

			if not (entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
				mod:QuickCord(entity, worm, "230.000_camillojr")
			end

		elseif sprite:IsEventTriggered("Sound") then
			entity.I1 = 0
			entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
			if entity.Child then
				entity.Child:Remove()
				entity.Child = nil
			end

		elseif sprite:IsEventTriggered("Stop") then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = 30
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.camilloJrUpdate, EntityType.ENTITY_CAMILLO_JR)