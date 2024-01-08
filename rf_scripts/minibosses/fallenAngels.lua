local mod = ReworkedFoes



-- Uriel
function mod:FallenUrielInit(entity)
	if entity.Variant == 1 then
		entity:GetSprite():Load("gfx/271.001_fallen uriel.anm2", true)
		entity.MaxHitPoints = 500
		entity.HitPoints = entity.MaxHitPoints
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FallenUrielInit, EntityType.ENTITY_URIEL)

function mod:FallenUrielUpdate(entity)
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
					entity:FireProjectiles(entity.Position, (entity.V2 - entity.Position):Resized(7.5), 4, ProjectileParams())
					mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
				end
			end


		-- Custom laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
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
				params.Color = mod.Colors.BrimShot
				params.Scale = 1.25
				params.CircleAngle = 0
				mod:FireProjectiles(entity, Vector(entity.Position.X, Game():GetRoom():GetBottomRightPos().Y - 1), Vector(11, 16), 9, params, Color.Default)
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
					entity:FireProjectiles(entity.Position, (entity.V2 - (entity.Position - Vector(0, 40))):Resized(9), 5, params)
					mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
				end

				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

			if sprite:IsFinished("LaserShot") and entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
				entity.I2 = 0
			end
		end


		-- Delirium skin
		if data.wasDelirium and sprite:GetFilename() ~= "gfx/272.001_fallen uriel.anm2" then
			sprite:Load("gfx/272.001_fallen uriel.anm2", true)

			for i = 0, 5 do
				sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/rebirth/angelblack.png")
			end
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FallenUrielUpdate, EntityType.ENTITY_URIEL)



-- Gabriel
function mod:GabrielInit(entity)
	local newHp = 520
	if entity.Variant == 1 then
		entity:GetSprite():Load("gfx/272.001_fallen gabriel.anm2", true)
		newHp = 666
	end

	entity.MaxHitPoints = newHp
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GabrielInit, EntityType.ENTITY_GABRIEL)

function mod:FallenGabrielUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Spread attack
		if entity.State == NpcState.STATE_ATTACK then
			if sprite:IsPlaying("SpreadShot") and sprite:GetFrame() == 10 then
				entity:FireProjectiles(entity.Position, Vector(8, 12), 9, ProjectileParams())
				mod:PlaySound(nil, SoundEffect.SOUND_THUMBS_DOWN, 0.6)
			end


		-- Custom laser attacks
		elseif (entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3) then
			if sprite:IsPlaying("LaserShot") then
				entity.State = entity.State + 2
			end
			if entity.State == NpcState.STATE_ATTACK3 and sprite:GetFrame() == 5 and not sprite:IsPlaying("Float") then
				entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 10, 1, true, false)
				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
			end


		-- Laser swirl attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			-- Laser swirls
			if sprite:IsEventTriggered("Shoot") then
				for i = 0, 2, 2 do
					local swirl = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.BrimstoneSwirl, 0, entity.Position - Vector(0, 40) + Vector.FromAngle(i * 90):Resized(10), Vector.FromAngle(i * 90):Resized(8), entity)
					swirl.Parent = entity
					swirl:GetSprite():Play("IdleQuick", true)
					data.brim = swirl
				end

				mod:PlaySound(nil, SoundEffect.SOUND_LIGHTBOLT_CHARGE, 2)
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
					entity:FireProjectiles(entity.Position - Vector(0, 20), Vector.FromAngle(i * 90):Resized(10), 2, params)
				end
			end

			if sprite:IsFinished("LaserShot") and (not data.brim or not data.brim:Exists()) then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 0
			end
		end


		-- Delirium skin
		if data.wasDelirium and sprite:GetFilename() ~= "gfx/272.001_fallen gabriel.anm2" then
			sprite:Load("gfx/272.001_fallen gabriel.anm2", true)

			for i = 0, 5 do
				sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirthplus/deliriumforms/rebirth/angel2black.png")
			end
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.FallenGabrielUpdate, EntityType.ENTITY_GABRIEL)

function mod:GabrielCollision(entity, target, cock)
	if target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.GabrielCollision, EntityType.ENTITY_GABRIEL)



--[[ Single Laser Brimstone Swirl ]]--
function mod:SingleBrimstoneSwirlUpdate(effect)
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
		mod:QuickTracer(effect, effect.TargetPosition:GetAngleDegrees(), Vector.Zero, 15, 1, 2)
	end

	-- Shoot laser
	if sprite:IsEventTriggered("Shoot") then
		effect.Velocity = Vector.Zero
		sprite.PlaybackSpeed = 1

		local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, effect.Position, effect.TargetPosition:GetAngleDegrees(), 15, Vector.Zero, spawner), spawner}
		data.brim = laser_ent_pair.laser
		data.brim.DisableFollowParent = true
	end

	if sprite:IsFinished() then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.SingleBrimstoneSwirlUpdate, mod.Entities.BrimstoneSwirl)