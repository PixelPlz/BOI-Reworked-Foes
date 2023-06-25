local mod = BetterMonsters

local Settings = {
	MoveSpeed = 2,
	AngrySpeed = 4.25,
	CreepTime = 45,
	Cooldown = 15,
	ShotSpeed = 10,
	SoundTimer = {90, 150}
}



function mod:skinnyInit(entity)
	if entity.Variant <= 1 then
		entity.I2 = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.skinnyInit, EntityType.ENTITY_SKINNY)

function mod:skinnyUpdate(entity)
	if entity.Variant <= 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local speed = Settings.MoveSpeed


		-- 2nd phase
		if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2 then
			speed = Settings.AngrySpeed

			-- Rotty attack
			if entity.State == NpcState.STATE_ATTACK2 then
				if sprite:GetOverlayFrame() == 8 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(Settings.ShotSpeed), 0, params)
					mod:PlaySound(nil, SoundEffect.SOUND_SCAMPER)
				end

				if sprite:IsOverlayFinished() then
					entity.State = NpcState.STATE_ATTACK
					entity.ProjectileCooldown = Settings.Cooldown
				end

			else
				mod:LoopingOverlay(sprite, "HeadAngry")

				-- Creep
				if entity.Variant == 0 and entity:IsFrame(4, 0) then
					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.5, Settings.CreepTime)

				-- Rotty projectile
				elseif entity.Variant == 1 then
					if entity.ProjectileCooldown <= 0 then
						if entity.Position:Distance(target.Position) <= 220 and Game():GetRoom():CheckLine(entity.Position, target.Position, 3, 0, false, false) then
							entity.State = NpcState.STATE_ATTACK2
							sprite:PlayOverlay("HeadShoot", true)
						end

					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end
			end


		-- Transition
		elseif entity.State == NpcState.STATE_SPECIAL then
			if sprite:GetOverlayFrame() == 5 then
				mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL, 0.75, 0.9)
			end

			-- Complete transition
			if sprite:IsOverlayFinished() then
				entity.State = NpcState.STATE_ATTACK

				if entity.Variant == 1 then
					entity.ProjectileCooldown = Settings.Cooldown
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)
				end
			end

		-- 1st phase
		else
			sprite:SetOverlayFrame("Head", sprite:GetFrame())
		end


		-- Movement
		mod:ChasePlayer(entity, speed)
		entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

		-- Sounds
		if entity.I2 <= 0 then
			local sound = SoundEffect.SOUND_ANGRY_GURGLE
			if entity.Variant == 1 and entity.State ~= NpcState.STATE_MOVE then
				sound = SoundEffect.SOUND_MONSTER_ROAR_1
			end

			mod:PlaySound(entity, sound)
			entity.I2 = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
		else
			entity.I2 = entity.I2 - 1
		end


		-- Transition
		if entity.State == NpcState.STATE_MOVE and entity.HitPoints <= ((entity.MaxHitPoints / 3) * 2) then
			entity.State = NpcState.STATE_SPECIAL
			sprite:PlayOverlay("HeadTransition", true)
		end


		if entity.FrameCount > 1 then
			return true

		-- For some reason they spawn at 50% hp when they're champions?
		elseif entity:IsChampion() then
			entity.HitPoints = entity.MaxHitPoints
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.skinnyUpdate, EntityType.ENTITY_SKINNY)

function mod:rottyDeath(entity)
	if entity.Variant == 1 then
		for i = 0, 1 do
			Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, mod:RandomVector(5), entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.rottyDeath, EntityType.ENTITY_SKINNY)

-- Turn Skinnies into Crispies when burnt
function mod:skinnyIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 0 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(target.Type, 2, 0, target:ToNPC():GetChampionColorIdx())
		local sprite = target:GetSprite()

		-- Unique appearance for ones that took off their skin already
		if target:ToNPC().State == NpcState.STATE_SPECIAL or target:ToNPC().State == NpcState.STATE_ATTACK then
			target:ToNPC().State = NpcState.STATE_MOVE

			local suffix = ""
			if target:ToNPC():IsChampion() then
				suffix = "_champion"
			end

			sprite:ReplaceSpritesheet(1, "gfx/monsters/better/grilled crispy" .. suffix .. ".png")
			sprite:ReplaceSpritesheet(2, "gfx/monsters/better/grilled crispy" .. suffix .. ".png")
			sprite:LoadGraphics()
			sprite:PlayOverlay("HeadAngry", true)

		else
			sprite:PlayOverlay("Head", true)
		end

		target:Update()
		mod:PlaySound(nil, SoundEffect.SOUND_FIREDEATH_HISS)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.skinnyIgnite, EntityType.ENTITY_SKINNY)