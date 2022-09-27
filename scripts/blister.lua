local mod = BetterMonsters
local game = Game()

local Settings = {
	SpeedMultiplier = 0.8,
	Range = 240,
	Cooldown = 4, -- Jumps
	ShotSpeed = 9
}



function mod:blisterReplace(entity)
	if entity.Variant == 0 and entity.SubType == 0 then
		entity:Morph(EntityType.ENTITY_HOPPER, 1, 303, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blisterReplace, EntityType.ENTITY_BLISTER)

function mod:blisterUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 303 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		entity.Velocity = entity.Velocity * Settings.SpeedMultiplier

		if sprite:IsPlaying("Hop") and sprite:GetFrame() == 25 then
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1

			if entity.ProjectileCooldown <= 0 and entity.Position:Distance(target.Position) <= Settings.Range and
			game:GetRoom():CheckLine(entity.Position, target.Position, 3, 0, false, false) then
				sprite:Play("Attack", true)
			end
		end


		if sprite:IsEventTriggered("Shoot") then
			entity.ProjectileCooldown = Settings.Cooldown
			entity:PlaySound(SoundEffect.SOUND_BOIL_HATCH, 1, 0, false, 1.5)

			local params = ProjectileParams()
			params.Variant = IRFentities.cocoonProjectile
			params.FallingSpeedModifier = -6
			params.FallingAccelModifier = 0.75
			entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * Settings.ShotSpeed, 0, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blisterUpdate, EntityType.ENTITY_HOPPER)

function mod:blisterDeath(entity)
	if entity.Variant == 1 and entity.SubType == 303 then
		mod:QuickCreep(EffectVariant.CREEP_WHITE, entity, entity.Position)
		Isaac.Spawn(EntityType.ENTITY_BOIL, 2, 0, entity.Position, Vector.Zero, nil)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blisterDeath, EntityType.ENTITY_HOPPER)