local mod = BetterMonsters

local Settings = {
	SpeedMultiplier = 1.15,
	Cooldown = 80,
	MoveTime = 60
}



function mod:flamingGaperInit(entity)
	if entity.Variant == 2 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown / 2, Settings.Cooldown)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.flamingGaperInit, EntityType.ENTITY_GAPER)

function mod:flamingGaperUpdate(entity)
	local data = entity:GetData()


	if entity.Variant == 2 then
		local sprite = entity:GetSprite()

		if not data.wasFlamingGaper then
			-- Bestiary fix
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(5, "")
			sprite:LoadGraphics()

			data.wasFlamingGaper = true
		end


		-- Regular form
		if entity.I1 == 0 then
			if not sprite:IsOverlayPlaying("Ignite") and not sprite:IsOverlayPlaying("Extinguish") then
				mod:LoopingOverlay(sprite, "HeadNew")
			end

			if entity.ProjectileCooldown <= 0 then
				-- Only ignite if it has a path to the player
				if entity.Pathfinder:HasPathToPos(entity:GetPlayerTarget().Position, false) then
					if not sprite:IsOverlayPlaying("Ignite") then
						sprite:PlayOverlay("Ignite", true)
					end

					-- Ignite
					if sprite:GetOverlayFrame() == 8 then
						entity.I1 = 1
						entity.ProjectileCooldown = Settings.MoveTime
						mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END)
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Ignited form
		elseif entity.I1 == 1 then
			entity.Velocity = entity.Velocity * Settings.SpeedMultiplier

			if not sprite:IsOverlayPlaying("Ignite") and not sprite:IsOverlayPlaying("Extinguish") then
				mod:LoopingOverlay(sprite, "HeadFast")
			end
			mod:EmberParticles(entity, Vector(0, -40))

			if entity.ProjectileCooldown <= 0 then
				if not sprite:IsOverlayPlaying("Extinguish") then
					sprite:PlayOverlay("Extinguish", true)
				end

				-- Extinguish
				if sprite:GetOverlayFrame() == 6 then
					entity.I1 = 0
					entity.ProjectileCooldown = Settings.Cooldown
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END, 0.6)
				end
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end


	-- Extinguished Flaming Gaper
	elseif entity.Variant == 1 and data.wasFlamingGaper then
		data.wasFlamingGaper = nil
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingGaperUpdate, EntityType.ENTITY_GAPER)

-- Turn regular Gapers into flaming ones when burnt
function mod:gaperIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if Game():GetRoom():HasWater() == false and target.Variant == 1 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(EntityType.ENTITY_GAPER, 2, 0, target:ToNPC():GetChampionColorIdx())
		target:Update()
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gaperIgnite, EntityType.ENTITY_GAPER)



--[[ Brazier ]]--
function mod:flamingGusherUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.Variant == IRFentities.Brazier then
		mod:LoopingOverlay(sprite, "Fire", true)
		mod:EmberParticles(entity, Vector(0, -28))

		-- Shoot
		if entity.ProjectileCooldown <= 0 then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Color = Color(1,1,0, 1, 0.4,0,0)
			params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.FIRE_SPAWN)
			params.Scale = 0.75
			params.FallingAccelModifier = 0.175
			mod:FireProjectiles(entity, entity.Position, mod:RandomVector(5), 0, params, Color(0,0,0, 1, 0.9,0.45,0))

			mod:ShootEffect(entity, 5, Vector(0, -16), Color(1,1,1, 1, 0,0.25,0), 0.75, true)
			entity.ProjectileCooldown = mod:Random(20, 40)

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end

		-- Dumb Fiend Folio Water TNT compatibility
		if FiendFolio then											 -- FUCKING USE ENUMS!!
			for i, water in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, 7019, 0, false, false)) do
				if water.Position:Distance(entity.Position) <= 80 then
					entity:Morph(entity.Type, 1, 0, entity:GetChampionColorIdx())
					mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS, 1, 1.5)
					entity:TakeDamage(entity.MaxHitPoints / 5, 0, EntityRef(Game():GetNearestPlayer(water.Position)), 0)
					break
				end
			end
		end


	-- Turn Gushers and Pacers from Flaming Gapers into Braziers
	elseif entity:GetData().wasFlamingGaper then
		if IRFConfig.burningGushers == true then
			entity:Morph(EntityType.ENTITY_GUSHER, IRFentities.Brazier, 0, entity:GetChampionColorIdx())

		else
			local suffix = ""
			if entity:IsChampion() then
				suffix = "_champion"
			end

			sprite:ReplaceSpritesheet(0, "gfx/monsters/better/monster_000_flaming_bodies02" .. suffix .. ".png")
			sprite:LoadGraphics()
		end

		entity:GetData().wasFlamingGaper = nil
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.flamingGusherUpdate, EntityType.ENTITY_GUSHER)

-- Turn regular Gushers into Braziers when burnt
function mod:gusherIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if Game():GetRoom():HasWater() == false and target.Variant < 2 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(EntityType.ENTITY_GUSHER, IRFentities.Brazier, 0, target:ToNPC():GetChampionColorIdx())
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gusherIgnite, EntityType.ENTITY_GUSHER)