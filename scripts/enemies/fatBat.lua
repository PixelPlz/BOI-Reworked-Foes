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
		if entity.I2 < Settings.MaxPoops and math.random(1, 10) <= 4 and Game():GetRoom():GetGridEntityFromPos(entity.Position) == nil then
			entity.State = NpcState.STATE_ATTACK3
		else
			entity.State = NpcState.STATE_ATTACK2
		end
		sprite:Play("Shooting", true)


	-- Shoot
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if entity.I1 == 1 then
			entity.Velocity = -entity.V1 * Settings.PushBackSpeed
			SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)

			local params = ProjectileParams()
			params.FallingSpeedModifier = 5
			params.Variant = ProjectileVariant.PROJECTILE_PUKE
			entity:FireBossProjectiles(1, entity.Position + (entity.V1 * 10), 4, params)

		else
			entity.Velocity = mod:StopLerp(entity.Velocity)
		end


		if sprite:IsEventTriggered("Shoot") then
			entity.I1 = 1
			entity.V1 = (target.Position - entity.Position):Normalized()
			entity:PlaySound(SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0, false, 0.9)

		elseif sprite:GetFrame() == 14 then
			entity.I1 = 0
		end

		if sprite:IsFinished("Shooting") then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown
		end


	-- Shit
	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Shoot") then
			Game():ButterBeanFart(entity.Position, Settings.FartRadius, entity, true, false)
			entity:PlaySound(SoundEffect.SOUND_SHAKEY_KID_ROAR, 0.9, 0, false, 1)

			local poop = Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, entity.Position, false)
			if poop then
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