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
		local data = entity:GetData()
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
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * Settings.ShotSpeed, 0, params)
					entity:PlaySound(SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
				end

				if sprite:IsOverlayFinished() then
					entity.State = NpcState.STATE_ATTACK
					entity.ProjectileCooldown = Settings.Cooldown
				end

			else
				mod:LoopingOverlay(sprite, "HeadFast")

				-- Creep
				if entity.Variant == 0 and entity:IsFrame(4, 0) then
					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.75, Settings.CreepTime)

				-- Bullets
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
				SFXManager():Play(SoundEffect.SOUND_SKIN_PULL, 0.75, 0, false, 0.9)
			end

			-- Complete transition
			if sprite:IsOverlayFinished() then
				entity.State = NpcState.STATE_ATTACK

				if entity.Variant == 1 then
					entity.ProjectileCooldown = Settings.Cooldown
					entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 1, 0, false, 1)
				end
			end

		-- 1st phase
		else
			sprite:SetOverlayFrame("Head", sprite:GetFrame())
		end


		-- Movement
		if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
			speed = -speed
		end

		if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
			entity.Pathfinder:MoveRandomly(false)
		else
			if entity.Pathfinder:HasPathToPos(target.Position) then
				if Game():GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false) then
					entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * speed, 0.25)
				else
					entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
				end
			else
				entity.Velocity = mod:StopLerp(entity.Velocity)
			end
		end

		entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)


		-- Sounds
		if entity.I2 <= 0 then
			local sound = SoundEffect.SOUND_ANGRY_GURGLE
			if entity.Variant == 1 and entity.State ~= NpcState.STATE_MOVE then
				sound = SoundEffect.SOUND_MONSTER_ROAR_1
			end

			entity:PlaySound(sound, 1, 0, false, 1)
			entity.I2 = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
		else
			entity.I2 = entity.I2 - 1
		end


		-- Transition
		if entity.State == NpcState.STATE_MOVE and entity.HitPoints <= ((entity.MaxHitPoints / 3) * 2) then
			entity.State = NpcState.STATE_SPECIAL
			sprite:PlayOverlay("Transition", true)
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.skinnyUpdate, EntityType.ENTITY_SKINNY)

function mod:rottyDeath(entity)
	if entity.Variant == 1 then
		for i = 0, 1 do
			Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, Vector.FromAngle(math.random(0, 359)) * 5, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.rottyDeath, EntityType.ENTITY_SKINNY)

-- Turn Skinnies into Crispies when burnt
function mod:skinnyIgnite(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 0 and damageFlags & DamageFlag.DAMAGE_FIRE > 0 then
		target:ToNPC():Morph(target.Type, 2, 0, target:ToNPC():GetChampionColorIdx())

		if target:ToNPC().State ~= NpcState.STATE_MOVE then
			target:ToNPC().State = NpcState.STATE_MOVE
			target.HitPoints = 9.9
		end

		target:GetSprite():PlayOverlay("Head", true)
		target:Update()
		SFXManager():Play(SoundEffect.SOUND_FIREDEATH_HISS)

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.skinnyIgnite, EntityType.ENTITY_SKINNY)