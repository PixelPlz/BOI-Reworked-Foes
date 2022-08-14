local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 4,
	RunSpeed = 5.5,

	DeathShotSpeed = 12,
	TransparencyTimer = 10,
	Cooldown = {80, 120},
	Range = 440
}

local States = {
	Appear = 0,
	Moving = 1,
	Attacking = 2,
	Enrage = 3
}



function mod:blightedOvumBabyInit(entity)
	if entity.Variant == 12 then
		entity:Morph(200, 4079, 0, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blightedOvumBabyInit, EntityType.ENTITY_GEMINI)

function mod:blightedOvumDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 2 and damageSource.Type == 200 and damageSource.Variant == 4079 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blightedOvumDMG, EntityType.ENTITY_GEMINI)

function mod:blightedOvumDeath(entity)
	if entity.Variant == 2 then
		if entity.Child then
			entity.Child:GetData().state = States.Enrage
			entity.Child:ToNPC().I1 = 1

			-- Remove brimstone
			if entity.Child:GetData().brim then
				entity.Child:GetData().brim:ToLaser():SetTimeout(1)
			end
		end

		entity:FireProjectiles(entity.Position, Vector(Settings.DeathShotSpeed, 0), 8, ProjectileParams())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blightedOvumDeath, EntityType.ENTITY_GEMINI)



function mod:blightedOvumBabyUpdate(entity)
	if entity.Variant == 4079 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()

		
		-- Transparency
		if entity.I1 == 0 then
			sprite.Color = Color(1,1,1, 0.6)
		else
			sprite.Color = Color(1,1,1, 1)
			data.transTimer = nil
		end

		if data.transTimer ~= nil then -- trans rights
			if data.transTimer <= 0 then
				sprite.Color = Color(1,1,1, 0.6)
				data.transTimer = nil
			else
				sprite.Color = Color(1,1,1, 0.3)
				data.transTimer = data.transTimer - 1
			end
		end


		if not data.state then
			data.state = States.Appear
			entity.SplatColor = ghostGibs

		elseif data.state == States.Appear then
			data.state = States.Moving
			entity.ProjectileCooldown = Settings.Cooldown[1]


		elseif data.state == States.Moving then
			-- Movement
			if entity.I1 == 1 then
				entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * Settings.RunSpeed - entity.Velocity) * 0.25)
			else
				if entity.Parent then
					entity.Velocity = (entity.Parent.Position - entity.Position):Normalized() * Settings.MoveSpeed
					--entity.Velocity = (entity.Velocity + ((entity.Parent.Position - entity.Position):Normalized() * Settings.BabySpeed - entity.Velocity) * 0.25) -- doesn't work the way it's supposed to??
				else
					entity.I1 = 1
				end
			end

			if not sprite:IsPlaying("Walk0" .. entity.I1 + 1) then
				sprite:Play("Walk0" .. entity.I1 + 1, true)
			end
			-- Flip sprite
			if entity.Velocity.X < 0 then
				sprite.FlipX = true
			elseif entity.Velocity.X > 0 then
				sprite.FlipX = false
			end

			if entity.ProjectileCooldown <= 0 then
				if entity.Position:Distance(target.Position) <= Settings.Range then
					data.state = States.Attacking
				end
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Laser
		elseif data.state == States.Attacking then
			if not sprite:IsPlaying("Attack0" .. entity.I1 + 1) then
				sprite:Play("Attack0" .. entity.I1 + 1, true)
			end

			-- Shoot laser
			if sprite:IsEventTriggered("GetPos") then
				data.angle = (target.Position - entity.Position):GetAngleDegrees()

			elseif sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0, false, 0.9)
				entity.ProjectileCooldown = math.random(Settings.Cooldown[1], Settings.Cooldown[2])

				-- Flip sprite
				if target.Position.X < entity.Position.X then
					sprite.FlipX = true
				elseif target.Position.X > entity.Position.X then
					sprite.FlipX = false
				end

				local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position, data.angle, 26, Vector(0, entity.SpriteScale.Y * -38), entity), entity}
				data.brim = laser_ent_pair.laser
				data.brim.DepthOffset = entity.DepthOffset + 10
			
			elseif sprite:IsEventTriggered("Stop") then
				data.state = States.Moving
			end

			-- Push back
			if data.brim then
				if not data.brim:Exists() then
					data.brim = nil
				else
					entity.Velocity = -Vector.FromAngle(data.brim.Angle) * 1.25
				end
			else
				entity.Velocity = Vector.Zero
			end


		-- Go to 2nd phase
		elseif data.state == States.Enrage then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("Enrage") then
				sprite:Play("Enrage", true)
				entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0, false, 0.9)
			end

			if sprite:IsEventTriggered("Shoot") then
				data.state = States.Moving
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blightedOvumBabyUpdate, 200)

function mod:blightedOvumBabyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4079 then
		if target:ToNPC().I1 == 0 then
			target:GetData().transTimer = Settings.TransparencyTimer
			return false
		
		elseif damageSource.Type == 200 and damageSource.Variant == 4079 then
			return false
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blightedOvumBabyDMG, 200)

function mod:blightedOvumBabyCollide(entity, target, bool)
	if entity.Variant == 4079 and (target.Type == 200 and target.Variant == 4079) or target.Type == EntityType.ENTITY_GEMINI then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.blightedOvumBabyCollide, 200)

function mod:blightedOvumBabyDeath(entity)
	if entity.Variant == 4079 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, 2, entity.Position, Vector.Zero, entity)
		SFXManager():Play(SoundEffect.SOUND_DEMON_HIT)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blightedOvumBabyDeath, 200)