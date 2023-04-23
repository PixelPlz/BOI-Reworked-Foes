local mod = BetterMonsters

local Settings = {
	SpeedMultiplier = 1.15,
	Cooldown = 80,
	MoveTime = 60
}



function mod:flamingGaperInit(entity)
	if entity.Variant == 2 then
		entity.ProjectileCooldown = math.random(Settings.Cooldown / 2, Settings.Cooldown)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.flamingGaperInit, EntityType.ENTITY_GAPER)

function mod:flamingGaperUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()


		if entity.I1 == 0 then
			if not sprite:IsOverlayPlaying("HeadNew") and not sprite:IsOverlayPlaying("Ignite") then
				sprite:PlayOverlay("HeadNew", true)
			end

			if entity.ProjectileCooldown <= 0 then
				if entity.Pathfinder:HasPathToPos(entity:GetPlayerTarget().Position, false) then
					if not sprite:IsOverlayPlaying("Ignite") then
						sprite:PlayOverlay("Ignite", true)
					end
					
					if sprite:GetOverlayFrame() == 8 then
						entity.I1 = 1
						entity.ProjectileCooldown = Settings.MoveTime
						SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END)
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 0, entity.Position, Vector.Zero, entity)
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		elseif entity.I1 == 1 then
			entity.Velocity = entity.Velocity * Settings.SpeedMultiplier
			if not sprite:IsOverlayPlaying("HeadFast") and not sprite:IsOverlayPlaying("Extinguish") then
				sprite:PlayOverlay("HeadFast", true)
			end
			
			if entity.ProjectileCooldown <= 0 then
				if not sprite:IsOverlayPlaying("Extinguish") then
					sprite:PlayOverlay("Extinguish", true)
				end
				
				if sprite:GetOverlayFrame() == 6 then
					entity.I1 = 0
					entity.ProjectileCooldown = Settings.Cooldown
					SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.6)
				end
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingGaperUpdate, EntityType.ENTITY_GAPER)

-- Turn regular gapers into flaming ones when burnt
function mod:gaperIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(EntityType.ENTITY_GAPER, 2, 0, target:ToNPC():GetChampionColorIdx())
		target:Update()
		SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gaperIgnite, EntityType.ENTITY_GAPER)