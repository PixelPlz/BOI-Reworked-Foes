local mod = BetterMonsters
local game = Game()



function mod:eyeUpdate(entity)
	local sprite = entity:GetSprite()
	local canAttack = true

	if entity.ProjectileCooldown > 0 then
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end


	-- Make only one eye shoot at a time
	for i, eye in pairs(Isaac.FindByType(EntityType.ENTITY_EYE, entity.Variant, 0, false, true)) do
		if eye.Index ~= entity.Index and eye:ToNPC().State == NpcState.STATE_ATTACK and ((entity.Variant == 0 and eye:GetSprite():GetAnimation() == "Shoot") or
		(entity.Variant == 1 and eye:GetSprite():GetOverlayFrame() > 0)) then
			canAttack = false
			break
		end
	end


	if entity.State == NpcState.STATE_ATTACK then
		-- Give cooldown
		if (entity.Variant == 0 and sprite:GetFrame() == 19) or (entity.Variant == 1 and sprite:GetOverlayFrame() == 19) then
			entity.ProjectileCooldown = 15 + (entity.Variant * 15)
		end

		-- Prevent them from shooting if they have a cooldown / there is another eye shooting
		if entity.ProjectileCooldown > 0 or canAttack == false then
			if entity.Variant == 0 then
				sprite:Stop()
				entity.State = NpcState.STATE_IDLE
			elseif entity.Variant == 1 then
				sprite:SetOverlayFrame("ShootOverlay", 0)
			end
		end

		-- Telegraphs
		if (entity.Variant == 0 and sprite:GetFrame() == 1) or (entity.Variant == 1 and sprite:GetOverlayFrame() == 1) then
			local pitch = 1.1
			local offset = 16
			if entity.Variant == 1 then
				pitch = 1
				offset = 0
				sprite.PlaybackSpeed = 0.9
			end
			SFXManager():Play(SoundEffect.SOUND_LASERRING_WEAK, 1.15, 0, false, pitch)

			local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, entity.Position + (Vector.FromAngle(entity.V1.X) * 20) + Vector(0, entity.SpriteScale.Y * offset), Vector.Zero, entity):ToEffect()
			tracer.LifeSpan = 15
			tracer.Timeout = 1
			tracer.TargetPosition = Vector.FromAngle(entity.V1.X)
			tracer:GetSprite().Color = Color(1,0,0, 0.25)
			tracer.SpriteScale = Vector(2, 0)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.eyeUpdate, EntityType.ENTITY_EYE)


--entity.V2 = entity.V2 + Vector(5, 0)
--entity.V1 = entity.V2