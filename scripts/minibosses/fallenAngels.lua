local mod = BetterMonsters



-- Uriel
function mod:fallenUrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Spread attack
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsPlaying("SpreadShot") then
				if sprite:IsEventTriggered("Shoot") then
					entity.V2 = target.Position

				elseif sprite:GetFrame() == 11 then
					entity:FireProjectiles(entity.Position, (entity.V2 - entity.Position):Normalized() * 7.5, 4, ProjectileParams())
					entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
				end
			end


		-- Custom laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end


		-- Single laser attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Shoot") then
				local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), 90, 20, Vector.Zero, entity), entity}
				data.brim = laser_ent_pair.laser
				data.brim.DepthOffset = entity.DepthOffset + 100
				
				-- Shots
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = brimstoneBulletColor
				params.Scale = 1.25
				params.CircleAngle = 0
				entity:FireProjectiles(Vector(entity.Position.X, Game():GetRoom():GetBottomRightPos().Y - 1), Vector(11, 16), 9, params)
			end

			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
			end


		-- Double laser attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			-- Lasers
			if sprite:IsEventTriggered("Shoot") then
				entity.I2 = 1
				entity.ProjectileCooldown = 30
				entity.V2 = target.Position

				for i = -1, 1, 2 do
					local angle = (entity.V2 - (entity.Position - Vector(0, 40))):GetAngleDegrees() + (i * 40)
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), angle, 25, Vector.Zero, entity), entity}
					laser_ent_pair.laser.DepthOffset = entity.DepthOffset + 100
				end
			end
			
			-- Shots
			if entity.I2 == 1 then
				if entity.ProjectileCooldown == 18 then
					local params = ProjectileParams()
					params.Spread = 1.2
					entity:FireProjectiles(entity.Position, (entity.V2 - (entity.Position - Vector(0, 40))):Normalized() * 9, 5, params)
					entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
				end

				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
			
			if sprite:IsFinished("LaserShot") and entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
				entity.I2 = 0
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fallenUrielUpdate, EntityType.ENTITY_URIEL)



-- Gabriel
function mod:fallenGabrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Spread attack
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsPlaying("SpreadShot") and sprite:GetFrame() == 10 then
				local params = ProjectileParams()
				params.CircleAngle = 0.1
				entity:FireProjectiles(entity.Position, Vector(8, 12), 9, params)
				entity:PlaySound(SoundEffect.SOUND_THUMBS_DOWN, 0.6, 0, false, 1)
			end


		-- Custom laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end


		-- Rotating laser attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			-- Laser swirls
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 2, 2 do
					local swirl = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.brimstoneSwirl, 1, entity.Position - Vector(0, 40) + (Vector.FromAngle(i * 90) * 10), Vector.FromAngle(i * 90) * 8, entity)
					swirl.Parent = entity
					swirl:GetSprite():Play("IdleQuick", true)
					swirl:GetSprite().PlaybackSpeed = 0.9
					data.brim = swirl
				end

				SFXManager():Play(SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end

			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = 0
			end


		-- X laser attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 3 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position - Vector(0, 40), (i * 90) - 45, 20, Vector.Zero, entity), entity}
					data.brim = laser_ent_pair.laser
					
					local params = ProjectileParams()
					params.Spread = 1.2
					entity:FireProjectiles(entity.Position - Vector(0, 20), Vector.FromAngle(i * 90) * 10, 2, params)
				end
			end

			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fallenGabrielUpdate, EntityType.ENTITY_GABRIEL)

function mod:gabrielCollision(entity, target, cock)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.gabrielCollision, EntityType.ENTITY_GABRIEL)

function mod:fallenGabrielDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_EFFECT and damageSource.SpawnerType == EntityType.ENTITY_GABRIEL then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.fallenGabrielDMG, EntityType.ENTITY_GABRIEL)



--[[ Single Laser Brimstone Swirl ]]--
function mod:singleBrimstoneSwirlUpdate(effect)
	local sprite = effect:GetSprite()
	local data = effect:GetData()

	local target = Isaac.GetPlayer(0)
	if effect.Parent then
		target = effect.Parent:ToNPC():GetPlayerTarget()
	end

	local spawner = effect
	if effect.Parent then
		spawner = effect.Parent
	end

	effect.Velocity = mod:Lerp(effect.Velocity, Vector.Zero, 0.1)


	-- Tracer, get starting position
	if (sprite:IsPlaying("Idle") and sprite:GetFrame() == 30) or (sprite:IsPlaying("IdleQuick") and sprite:GetFrame() == 15) then
		effect.TargetPosition = (target.Position - effect.Position):Normalized()
		
		local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, effect.Position + Vector(0, 20), Vector.Zero, entity):ToEffect()
		tracer.LifeSpan = 15
		tracer.Timeout = 1
		tracer.TargetPosition = effect.TargetPosition
		tracer:GetSprite().Color = Color(1,0,0, 0.25)
		tracer.SpriteScale = Vector(2, 0)
	end

	-- Shoot laser
	if sprite:IsEventTriggered("Shoot") then
		effect.Velocity = Vector.Zero
		sprite.PlaybackSpeed = 1

		local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, effect.Position, effect.TargetPosition:GetAngleDegrees(), 15, Vector.Zero, spawner), spawner}
		data.brim = laser_ent_pair.laser
		data.brim.DisableFollowParent = true

		-- Rotating laser
		if effect.SubType == 1 then
			local rotateDir = 1
			if (target.Position - effect.Position):GetAngleDegrees() <= effect.TargetPosition:GetAngleDegrees() then
				rotateDir = -1
			end

			data.brim:SetActiveRotation(0, rotateDir * 45, rotateDir * 1.1, false)
		end
	end

	if sprite:IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.singleBrimstoneSwirlUpdate, IRFentities.brimstoneSwirl)