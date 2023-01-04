local mod = BetterMonsters

local Settings = {
	MoveSpeed = 2,
	AngrySpeed = 4.25,
	CreepTime = 45,
	SoundTimer = {90, 150}
}



function mod:skinnyInit(entity)
	if entity.Variant == 0 or entity.Variant == 1 then
		entity.I2 = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.skinnyInit, EntityType.ENTITY_SKINNY)

function mod:skinnyUpdate(entity)
	if entity.Variant == 0 or entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()

		local speed = Settings.MoveSpeed
		local anim = "Head"


		if entity.State == NpcState.STATE_ATTACK then
			speed = Settings.AngrySpeed
			anim = "HeadFast"

			-- Creep
			if entity.Variant == 0 and entity:IsFrame(4, 0) then
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.75, Settings.CreepTime)

			-- Bullets
			elseif entity.Variant == 1 and entity:IsFrame(16, 0) then
				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 48
				
				params.FallingAccelModifier = -0.2
				params.Scale = 1 + (math.random(25, 40) / 100)
				entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
			end


		elseif entity.State == NpcState.STATE_SPECIAL then
			anim = "Transition"

			if sprite:IsOverlayPlaying(anim) then
				if sprite:GetOverlayFrame() == 5 then
					SFXManager():Play(SoundEffect.SOUND_SKIN_PULL, 0.75, 0, false, 0.9)

				-- Complete transition
				elseif sprite:GetOverlayFrame() == 14 then
					entity.State = NpcState.STATE_ATTACK

					-- Spawn death's head
					if entity.Variant == 1 then
						local skull = Isaac.Spawn(EntityType.ENTITY_DEATHS_HEAD, 0, 0, entity.Position + Vector(0, entity.Scale * -5), Vector.Zero, entity)
						skull:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						skull:ToNPC().Scale = entity.Scale

						if Game():IsGreedMode() then
							entity.Child = skull
						end
					end
				end
			end
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


		-- Animation
		entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
		mod:LoopingOverlay(sprite, anim)
		if anim == "Head" then
			sprite:SetOverlayFrame(anim, sprite:GetFrame())
		end

		-- Sounds
		if entity.I2 <= 0 then
			entity:PlaySound(SoundEffect.SOUND_ANGRY_GURGLE, 1, 0, false, 1)
			entity.I2 = math.random(Settings.SoundTimer[1], Settings.SoundTimer[2])
		else
			entity.I2 = entity.I2 - 1
		end


		-- Transition
		if entity.State == NpcState.STATE_MOVE and entity.HitPoints <= ((entity.MaxHitPoints / 3) * 2) then
			entity.State = NpcState.STATE_SPECIAL
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.skinnyUpdate, EntityType.ENTITY_SKINNY)

function mod:rottyGreedDeath(entity)
	if entity.Variant == 1 and Game():IsGreedMode() and entity.Child then
		entity.Child:Kill()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.rottyGreedDeath, EntityType.ENTITY_SKINNY)

function mod:rottyProjectileUpdate(projectile)
	if projectile.SpawnerType == EntityType.ENTITY_SKINNY and projectile.SpawnerVariant == 1 then
		projectile.CollisionDamage = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.rottyProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)