local mod = BetterMonsters

local Settings = {
	MaxPoops = 3,
	PushBackSpeed = 5,
	Cooldown = 30,
	FartRadius = 80,
}



function mod:fatBatUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	-- Custom attacks
	if entity.State == NpcState.STATE_ATTACK then
		if entity.I2 < Settings.MaxPoops and mod:Random(1, 10) <= 4 and Game():GetRoom():GetGridEntityFromPos(entity.Position) == nil then
			entity.State = NpcState.STATE_ATTACK3
		else
			entity.State = NpcState.STATE_ATTACK2
		end
		sprite:Play("Shooting", true)


	-- Puke
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if sprite:IsEventTriggered("Shoot") then
			entity.I1 = 1
			entity.V1 = (target.Position - entity.Position):Normalized()
			mod:PlaySound(entity, SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0.9)

		elseif sprite:GetFrame() == 14 then
			entity.I1 = 0
		end

		-- Shooting
		if entity.I1 == 1 then
			entity.Velocity = -entity.V1 * Settings.PushBackSpeed

			local params = ProjectileParams()
			params.FallingSpeedModifier = 5
			params.Variant = ProjectileVariant.PROJECTILE_PUKE
			entity:FireBossProjectiles(1, entity.Position + (entity.V1 * 10), 4, params)

			-- Effects
			if entity:IsFrame(3, 0) then
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.6)
				mod:ShootEffect(entity, 1, Vector(0, 3), Color(0,0,0, 1, 0.5,0.4,0.3))
			end

		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown
		end


	-- Shit
	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Shoot") then
			Game():ButterBeanFart(entity.Position, Settings.FartRadius, entity, true, false)
			mod:PlaySound(entity, SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0.9)

			if Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, entity.Position, false) then
				entity.I2 = entity.I2 + 1
			end
		end

		if sprite:IsFinished("Shooting") then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown / 2
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fatBatUpdate, EntityType.ENTITY_FAT_BAT)