local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 9,
	ShotSpeed = 9
}



function mod:dankDeathsHeadUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 0 then
		local sprite = entity:GetSprite()

		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Move") then
				entity.State = NpcState.STATE_MOVE
			end

		else
			if entity.FrameCount >= 30 then
				entity.Velocity = entity.Velocity:Normalized() * Settings.MoveSpeed
			else
				entity.Velocity = entity.Velocity:Normalized() * ((entity.FrameCount - 20) * 0.9)
			end

			if entity:CollidesWithGrid() then
				entity.Velocity = entity.Velocity:Normalized()
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Bounce", true)

				local params = ProjectileParams()
				params.Color = tarBulletColor
				params.FallingAccelModifier = 0.175
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 7, params)

				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5
				entity:PlaySound(SoundEffect.SOUND_GOOATTACH0, 1, 0, false, 1)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dankDeathsHeadUpdate, EntityType.ENTITY_DEATHS_HEAD)