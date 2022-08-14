local mod = BetterMonsters
local game = Game()



local function hostRockParticles(entity)
	for i = 0, 5 do
		local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, entity.Position, Vector.FromAngle(math.random(0, 359)) * 3, entity):ToEffect()
		rocks:GetSprite():Play("rubble", true)
		rocks.State = 2
	end
	SFXManager():Play(SoundEffect.SOUND_ROCK_CRUMBLE)
end

local function hostFakeDMG(target, damageAmount)
	target.HitPoints = target.HitPoints - damageAmount
	target:SetColor(Color(1,1,1, 1, 1,-0.25,-0.25), 2, 10, false, true)

	if target.HitPoints <= 0 then
		target:Kill()
	end
end



function mod:hostUpdate(entity)
	if (entity.Variant == 0 or (entity.Variant == 3 and entity.SubType ~= 40)) and IRFconfig.breakableHosts == true then
		local sprite = entity:GetSprite()

		if sprite:IsPlaying("Bombed") then
			local variant = 1
			subtype = 0
			if entity.Variant == 3 then
				variant = 3
				subtype = 40
			end

			entity:Morph(EntityType.ENTITY_HOST, variant, subtype, entity:GetChampionColorIdx())
			sprite:Play("Bombed", true)

			hostRockParticles(entity)
		end
	
	elseif entity.Variant == 3 and entity.SubType == 40 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
		
		if entity.State == NpcState.STATE_ATTACK and entity.StateFrame == 55 then
			entity:FireProjectiles(entity.Position, Vector(11, 0), 8, ProjectileParams())
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.hostUpdate, EntityType.ENTITY_HOST)

-- Shitty workaround for making soft hosts take damage
function mod:hostDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 3 and target.SubType == 40 then
		hostFakeDMG(target, damageAmount)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.hostDMG, EntityType.ENTITY_HOST)



function mod:mobileHostUpdate(entity)
	if IRFconfig.breakableHosts == true then
		local sprite = entity:GetSprite()

		if sprite:IsOverlayPlaying("Bombed") then
			entity:Morph(EntityType.ENTITY_FLESH_MOBILE_HOST, 0, 0, entity:GetChampionColorIdx())
			sprite:PlayOverlay("Bombed", true)
			
			hostRockParticles(entity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.mobileHostUpdate, EntityType.ENTITY_MOBILE_HOST)



function mod:floatingHostUpdate(entity)
	if entity.Variant == 0 and IRFconfig.breakableHosts == true then
		local sprite = entity:GetSprite()

		if sprite:IsPlaying("Bombed") then
			entity:Morph(EntityType.ENTITY_FLOATING_HOST, 1, 0, entity:GetChampionColorIdx())
			sprite:Play("Bombed", true)
			
			hostRockParticles(entity)
		end
	
	elseif entity.Variant == 1 then
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.floatingHostUpdate, EntityType.ENTITY_FLOATING_HOST)

-- Shitty workaround for making flesh floasts take damage
function mod:floatingHostDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 1 then
		hostFakeDMG(target, damageAmount)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.floatingHostDMG, EntityType.ENTITY_FLOATING_HOST)