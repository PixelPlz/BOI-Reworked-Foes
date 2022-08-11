local mod = BetterMonsters
local game = Game()

local Settings = {
	SpeedMultiplier = 1.2,
	Cooldown = 80,
	MoveTime = 60
}

local States = {
	Extinguished = 0,
	Flaming = 1
}



function mod:flamingGaperInit(entity)
	if entity.Variant == 1 and entity.SubType == 442 or entity.Variant == 2 then
		local data = entity:GetData()
		data.cooldown = math.random(Settings.Cooldown / 2, Settings.Cooldown)
		data.state = States.Extinguished
		
		if entity.Variant == 2 then
			entity:Morph(EntityType.ENTITY_GAPER, 1, 442, entity:GetChampionColorIdx())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.flamingGaperInit, EntityType.ENTITY_GAPER)

function mod:flamingGaperUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 442 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		if data.state == States.Extinguished then
			if not sprite:IsOverlayPlaying("Head") and not sprite:IsOverlayPlaying("Ignite") then
				sprite:PlayOverlay("Head", true)
			end

			if data.cooldown <= 0 then
				if not sprite:IsOverlayPlaying("Ignite") then
					sprite:PlayOverlay("Ignite", true)
				end
				
				if sprite:GetOverlayFrame() == 8 then
					data.state = States.Flaming
					data.moveTime = Settings.MoveTime
					SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END)
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 0, entity.Position, Vector.Zero, entity)
				end
			else
				data.cooldown = data.cooldown - 1
			end


		elseif data.state == States.Flaming then
			entity.Velocity = entity.Velocity * Settings.SpeedMultiplier
			if not sprite:IsOverlayPlaying("HeadFast") and not sprite:IsOverlayPlaying("Extinguish") then
				sprite:PlayOverlay("HeadFast", true)
			end
			
			if data.moveTime <= 0 then
				if not sprite:IsOverlayPlaying("Extinguish") then
					sprite:PlayOverlay("Extinguish", true)
				end
				
				if sprite:GetOverlayFrame() == 6 then
					data.state = States.Extinguished
					data.cooldown = Settings.Cooldown
					SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.6)
				end
			else
				data.moveTime = data.moveTime - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingGaperUpdate, EntityType.ENTITY_GAPER)

-- Turn regular gapers into flaming ones when burnt
function mod:gaperIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 and (target.SubType == 0 or target.SubType == 442) and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		if target.SubType == 0 then
			target:ToNPC():Morph(EntityType.ENTITY_GAPER, 1, 442, target:ToNPC():GetChampionColorIdx())
			target:GetData().state = States.Extinguished
			target:GetData().cooldown = 0
			target:Update()
			SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS)
		end
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gaperIgnite, EntityType.ENTITY_GAPER)