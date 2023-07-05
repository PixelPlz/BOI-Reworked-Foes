local mod = BetterMonsters

local Settings = {
	Cooldown = 30,
	DamageReduction = 20,
	HeadSmashScreenShake = 14,

	HopperHealth = 25
}



function mod:gateInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity:SetSize(66, Vector(1, 0.5), 12)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gateInit, EntityType.ENTITY_GATE)

function mod:gateUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	entity.Velocity = Vector.Zero

	-- Ember particles
	if entity.SubType ~= 1 then
		local color = Color.Default
		if entity.SubType == 2 then
			color = IRFcolors.BlueFire
		end
		mod:EmberParticles(entity, Vector(0, -math.random(110, 120)), 40, color)
	end


	-- Toggle damage reduction
	if sprite:IsEventTriggered("Open") then
		entity.ProjectileCooldown = 1
		mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.5)

	elseif sprite:IsEventTriggered("Close") then
		entity.ProjectileCooldown = 0
		mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS, 0.5)
	end


	-- Stagger Cooldown
	if entity.ProjectileDelay > 0 and entity.State ~= NpcState.STATE_SPECIAL and entity.State ~= NpcState.STATE_ATTACK3 then
		entity.ProjectileDelay = entity.ProjectileDelay - 1
	end

	-- Cooldown between attacks
	if entity.SubType ~= 1 and entity.StateFrame > 0 then
		entity.StateFrame = entity.StateFrame - 1
		if entity.State ~= NpcState.STATE_SPECIAL and entity.State ~= NpcState.STATE_ATTACK3 then
			entity.State = NpcState.STATE_IDLE
		end
		-- For black champion
		if entity.SubType == 2 then
			entity.I2 = 0
		end


	-- Summon attack
	elseif entity.State == NpcState.STATE_SUMMON then
		if entity.SubType == 0 and sprite:GetFrame() == 0 then
			-- Don't have more than 3 Flaming Hoppers
			if Isaac.CountEntities(nil, EntityType.ENTITY_FLAMINGHOPPER, -1, -1) >= 3 then
				entity.State = NpcState.STATE_ATTACK
				SFXManager():Stop(SoundEffect.SOUND_MONSTER_GRUNT_4)

			-- Let him do other attacks before spawning Flaming Hoppers
			elseif mod:Random(1) == 0 then
				entity.State = NpcState.STATE_ATTACK2
				SFXManager():Stop(SoundEffect.SOUND_MONSTER_GRUNT_4)
			end
		end


		-- Spawn
		if sprite:IsEventTriggered("Shoot") then
			-- Red champion splort
			if entity.SubType == 1 then
				mod:PlaySound(nil, SoundEffect.SOUND_PLOP, 0.9) -- Fuck you Amy I'll include it if I want!
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTIN)
				mod:ShootEffect(entity, 3, Vector(0, -56))


			else
				-- Black champion blue fire bones
				if entity.SubType == 2 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.BLUE_FIRE_SPAWN)
					params.Scale = 1.5
					params.Color = IRFcolors.BlackBony
					params.FallingAccelModifier = 1.25
					params.FallingSpeedModifier = -10
					params.HeightModifier = -54

					for i = 0, 3 do
						local pos = target.Position
						if i >= 1 then
							local angleToCenter = (Game():GetRoom():GetCenterPos() - entity.Position):GetAngleDegrees()
							local angle = mod:Random(angleToCenter - 100, angleToCenter + 100)
							pos = entity.Position + Vector.FromAngle(angle):Resized(mod:Random(80, 160))
						end
						entity:FireProjectiles(entity.Position, (pos - entity.Position):Resized(entity.Position:Distance(pos) / 20), 0, params)
					end

					mod:PlaySound(nil, SoundEffect.SOUND_SCAMPER)


				-- Flaming Hoppers
				else
					local hopper = Isaac.Spawn(EntityType.ENTITY_FLAMINGHOPPER, 0, 0, entity.Position + Vector(0, 1), Vector.Zero, entity):ToNPC()
					hopper.State = NpcState.STATE_MOVE
					hopper.TargetPosition = entity.Position + (target.Position - entity.Position):Resized(mod:Random(120, 200))
					hopper.PositionOffset = Vector(0, -64)
					hopper.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

					hopper.MaxHitPoints = Settings.HopperHealth
					hopper.HitPoints = hopper.MaxHitPoints

					local hopperSprite = hopper:GetSprite()
					hopperSprite:Play("Attack", true)
					hopperSprite:SetFrame(12)

					mod:PlaySound(nil, SoundEffect.SOUND_ANIMAL_SQUISH)
				end

				mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END)
			end
		end


		-- Pop goes the measle!
		if entity.SubType == 1 and sprite:WasEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Scale = 1 + mod:Random(10, 50) * 0.01
			params.FallingAccelModifier = 1.25
			params.FallingSpeedModifier = -35
			params.HeightModifier = -54

			for i = 0, 1 do
				local pos = target.Position + mod:RandomVector(mod:Random(150))
				entity:FireProjectiles(entity.Position, (pos - entity.Position):Resized(entity.Position:Distance(pos) / 35), 0, params)
			end

			-- Sound
			if entity:IsFrame(2, 0) then
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.6)
			end
		end

		if sprite:GetFrame() == 42 then -- Fucking why does IsFinished() not work...
			if entity.SubType == 2 then
				entity.I2 = 1
				entity.State = NpcState.STATE_ATTACK2
			else
				entity.StateFrame = Settings.Cooldown
			end
		end


	-- Laser attack
	elseif entity.State == NpcState.STATE_ATTACK then
		-- Stop the attack if there are other bosses alive
		if entity.SubType ~= 2 and sprite:GetFrame() == 0 then
			local canDoAttack = true
			for i, guy in pairs(Isaac.GetRoomEntities()) do
				if guy:ToNPC() and guy:ToNPC():IsBoss() == true and guy.Type ~= entity.Type then
					canDoAttack = false
					break
				end
			end

			if canDoAttack == false then
				entity.State = NpcState.STATE_ATTACK3
				sprite:Play("Raise", true)
				SFXManager():Stop(SoundEffect.SOUND_MOUTH_FULL)
			end


		-- Black champion flamethrower attack
		elseif entity.SubType == 2 and sprite:IsPlaying("Shooting") then
			-- Replace default attack
			if entity.I1 ~= 2 then
				entity.I1 = 2

			else
				-- Start
				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_GHOST_ROAR)
					mod:PlaySound(nil, SoundEffect.SOUND_FLAMETHROWER_END)
					sprite.PlaybackSpeed = 0.8 -- Yes I'm really gonna extend the duration by slowing down the animation, I don't care
				end
				-- Shooting
				if sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Close") and entity:IsFrame(2, 0) then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.Color = IRFcolors.BlueFire
					params.BulletFlags = ProjectileFlags.FIRE
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Rotated(mod:Random(-15, 15)):Resized(9), 0, params)
				end
				-- Stop
				if sprite:IsEventTriggered("Close") then
					sprite.PlaybackSpeed = 1
				end

				if sprite:GetFrame() == 30 then
					entity.State = NpcState.STATE_IDLE
					entity.StateFrame = Settings.Cooldown
				end
			end
		end


	-- Flame attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		-- Sometimes do the skull raising attack instead
		if sprite:IsPlaying("Charging") and sprite:GetFrame() == 0 and mod:Random(1) == 0 then
			if entity.SubType ~= 0 and mod:Random(1) == 0 then
				-- Summon attack for red champion
				if entity.SubType == 1 then
					entity.State = NpcState.STATE_SUMMON
				-- Laser attack for black champion
				else
					entity.State = NpcState.STATE_ATTACK
				end

			else
				entity.State = NpcState.STATE_ATTACK3
				sprite:Play("Raise", true)
			end
			SFXManager():Stop(SoundEffect.SOUND_LOW_INHALE)

		-- Cooldown
		elseif sprite:IsPlaying("Shooting") and sprite:GetFrame() == 30 then
			entity.StateFrame = Settings.Cooldown
		end

		-- Cringe red champion moment
		if entity.SubType == 1 then
			if sprite:IsEventTriggered("Open") and entity.I2 == 3 then
				entity.I2 = mod:Random(2)

			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(entity, SoundEffect.SOUND_FIRE_RUSH)
			end
		
		elseif entity.SubType == 2 and sprite:GetFrame() == 0 and entity.I2 ~= 1 then
			entity.State = NpcState.STATE_SUMMON
		end


	-- Stagger
	elseif entity.State == NpcState.STATE_SPECIAL then
		if sprite:IsFinished() then
			entity.State = NpcState.STATE_ATTACK3
			sprite:Play("Raise", true)
			entity.I1 = 0
		end

	-- Raise skull
	elseif entity.State == NpcState.STATE_ATTACK3 then
		if sprite:IsEventTriggered("Open") then
			mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_ROAR)

		-- Projectiles
		elseif sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()

			-- Red champion blood shoots
			if entity.SubType == 1 then
				params.BulletFlags = entity.I1 == 0 and ProjectileFlags.ORBIT_CW or ProjectileFlags.ORBIT_CCW
				params.TargetPosition = entity.Position
				params.Scale = 1.75
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.09
				entity:FireProjectiles(entity.Position, Vector(9, 8), 9, params)

			-- Black champion fire wave shots
			elseif entity.SubType == 2 then
				params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.FIRE_WAVE)
				params.Scale = 2
				params.Color = IRFcolors.BlueFireShot
				params.FallingAccelModifier = 1.25
				params.FallingSpeedModifier = -20
				mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(entity.Position:Distance(target.Position) / 24), 0, params):GetData().dontChange = true

			-- Default blood shots
			else
				params.Scale = 1.75 - entity.I1 * 0.25
				params.BulletFlags = ProjectileFlags.HIT_ENEMIES
				params.Spread = 1.2

				for i, projectile in pairs(mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(11 - entity.I1), 2 + entity.I1 * 3, params)) do
					projectile:GetData().dontChange = true
				end
			end

			mod:ShootEffect(entity, 5, Vector(2, -20), Color(1,1,1, 0.7), 1.25)
			mod:PlaySound(entity, SoundEffect.SOUND_GHOST_SHOOT)
			mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 0.8)
			entity.I1 = entity.I1 + 1


		-- Slam
		elseif sprite:IsEventTriggered("Close") then
			-- Red champion Projectiles
			if entity.SubType == 1 then
				local params = ProjectileParams()
				params.Scale = 1.75
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.1
				entity:FireProjectiles(entity.Position, Vector(10, 14), 9, params)

			-- Black champion fire waves
			elseif entity.SubType == 2 then
				for i = 0, 3 do
					local angle = 45 + i * 90
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_WAVE, 3, entity.Position + Vector.FromAngle(angle):Resized(20), Vector.Zero, entity):ToEffect().Rotation = angle
				end

			-- Default crackwaves
			else
				for i = -1, 1 do
					local angle = (target.Position - entity.Position):GetAngleDegrees() + i * mod:Random(50, 80)
					local subtype = 0
					if i == 0 then
						subtype = 2
					end

					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, subtype, entity.Position + Vector.FromAngle(angle):Resized(20), Vector.Zero, entity):ToEffect().Rotation = angle
				end
			end

			-- Effects
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
			mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.1)
			mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 1.1)
			Game():ShakeScreen(Settings.HeadSmashScreenShake)
			Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_IDLE
			entity.StateFrame = Settings.Cooldown
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gateUpdate, EntityType.ENTITY_GATE)

function mod:gateDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Prevent him from taking damage from his Flaming Hoppers or other Gates
	if damageSource.Type == EntityType.ENTITY_FLAMINGHOPPER or damageSource.SpawnerType == EntityType.ENTITY_FLAMINGHOPPER
	or damageSource.Type == EntityType.ENTITY_GATE or damageSource.SpawnerType == EntityType.ENTITY_GATE then
		return false


	-- Stagger from explosions
	elseif target.SubType ~= 1 and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) and target:ToNPC().ProjectileDelay <= 0 and target:ToNPC().State ~= NpcState.STATE_ATTACK3 then
		target:ToNPC().State = NpcState.STATE_SPECIAL
		target:GetSprite():Play("Stagger", true)
		target:ToNPC().ProjectileDelay = 120

		mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)
		mod:PlaySound(target, SoundEffect.SOUND_MONSTER_GRUNT_4)


	-- Reduced damage if skull is not raised
	elseif target.SubType ~= 1 and target:ToNPC().ProjectileCooldown ~= 1 and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0) then
		local onePercent = damageAmount / 100
		local reduction = onePercent * Settings.DamageReduction

		target:TakeDamage(damageAmount - reduction, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		target:SetColor(IRFcolors.ArmorFlash, 2, 0, false, false)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gateDMG, EntityType.ENTITY_GATE)

function mod:gateCollide(entity, target, bool)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.gateCollide, EntityType.ENTITY_GATE)


-- Remove default spawns
function mod:gateSpawns(entity)
	if entity.SpawnerType == EntityType.ENTITY_GATE and (entity.Type == EntityType.ENTITY_LEAPER or entity.Type == EntityType.ENTITY_BIGSPIDER) then
		entity:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gateSpawns)

-- Turn fire waves into blue ones
function mod:gateBlueFireJet(effect)
	if effect.SpawnerType == EntityType.ENTITY_GATE and effect.SubType ~= 3 then
		effect.SubType = 3
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.gateBlueFireJet, EffectVariant.FIRE_WAVE)