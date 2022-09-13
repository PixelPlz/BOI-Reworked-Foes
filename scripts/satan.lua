local mod = BetterMonsters
local game = Game()

local Settings = {
	DoubleStompCooldown = 240,
	HandShotSpeed = 8,
	LaserShotSpeed = 10,
}



function mod:satanInit(entity)
	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = Settings.DoubleStompCooldown
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.satanInit, EntityType.ENTITY_SATAN)

function mod:satanUpdate(entity)
	local sprite = entity:GetSprite()

	-- 1st phase
	if entity.Variant == 0 then
		-- Single brimstone
		if entity.State == NpcState.STATE_ATTACK2 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_HUSH
				params.Color = brimstoneBulletColor

				params.Scale = 1.25
				params.CircleAngle = 0
				entity:FireProjectiles(Vector(entity.Position.X, game:GetRoom():GetBottomRightPos().Y - 1), Vector(Settings.LaserShotSpeed, 16), 9, params)
				
				params.CircleAngle = 0.41
				params.Scale = 1.75
				entity:FireProjectiles(Vector(entity.Position.X, game:GetRoom():GetBottomRightPos().Y - 1), Vector(Settings.LaserShotSpeed - 5, 8), 9, params)
			end


		-- Custom hand laser attack
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity.State = NpcState.STATE_SUMMON
			entity:SetColor(Color(1,1,1, 1, 0.7,0,0), 15, 1, true, false)

		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:GetFrame() == 3 then
				entity.V2 = entity:GetPlayerTarget().Position
			end
			if sprite:IsEventTriggered("Shoot") then
				for i = -1, 1, 2 do
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(1, entity.Position, (entity.V2 - (entity.Position + Vector(i * 100, -60))):GetAngleDegrees(), 20, Vector.Zero, entity), entity}
					laser_ent_pair.laser.ParentOffset = Vector(i * 100, -60)
					laser_ent_pair.laser.DepthOffset = entity.DepthOffset + 100
				end
			end
			if sprite:IsFinished("Attack03") then
				entity.State = NpcState.STATE_MOVE
			end


		-- Custom hand bullet attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			if math.random(0, 2) == 1 then
				entity.State = NpcState.STATE_ATTACK3
				entity:PlaySound(SoundEffect.SOUND_SATAN_CHARGE_UP, 1, 0, false, 1)
			else
				entity.State = NpcState.STATE_ATTACK5
			end

		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_SATAN_BLAST, 1, 0, false, 1)

				local params = ProjectileParams()
				params.Scale = 1.5
				for i = -1, 1, 2 do
					entity:FireProjectiles(entity.Position + Vector(i * 90, -40), Vector.FromAngle((entity:GetPlayerTarget().Position - entity.Position):GetAngleDegrees() - i * 15) * Settings.HandShotSpeed, 5, params)
				end
			end
			if sprite:IsFinished("Attack03") then
				entity.State = NpcState.STATE_MOVE
			end
		end

		if sprite:IsPlaying("Death") and sprite:IsEventTriggered("Shoot") then
			entity:PlaySound(SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.9, 0, false, 1)
			entity:PlaySound(SoundEffect.SOUND_SATAN_HURT, 0.8, 0, false, 0.9)
		end


	-- 2nd phase
	elseif entity.Variant == 10 then
		-- Regular stomp
		if sprite:GetFrame() == 10 then
			entity:PlaySound(SoundEffect.SOUND_SATAN_STOMP, 0.9, 0, false, 1)
		end
		if sprite:IsEventTriggered("Stomp") then
			for i = 0, 3 do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 1, entity.Position + (Vector.FromAngle(i * 90) * 20), Vector.Zero, entity):ToEffect().Rotation = i * 90
			end
		end

		-- Double stomp
		if entity.Child then
			if entity.ProjectileCooldown <= 0 then
				if sprite:GetFrame() == 1 or entity.Child:GetSprite():GetFrame() == 1 then
					if entity.I2 == 0 then
						entity:PlaySound(SoundEffect.SOUND_SATAN_CHARGE_UP, 1, 0, false, 1)
						entity.I2 = 1
					end

					if sprite:GetFrame() == 1 then
						sprite.PlaybackSpeed = 0
					elseif entity.Child:GetSprite():GetFrame() == 1 then
						entity.Child:GetSprite().PlaybackSpeed = 0
					end
				end

				if sprite:GetFrame() == 1 and entity.Child:GetSprite():GetFrame() == 1 then
					entity.ProjectileCooldown = Settings.DoubleStompCooldown
					sprite.PlaybackSpeed = 1
					entity.Child:GetSprite().PlaybackSpeed = 1
					entity.I2 = 0
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
		end
		
		if entity:HasMortalDamage() then
			entity:PlaySound(SoundEffect.SOUND_SATAN_HURT, 1.2, 0, false, 1)
			sprite.PlaybackSpeed = 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.satanUpdate, EntityType.ENTITY_SATAN)

function mod:brimstoneProjectileUpdate(projectile)
	if ((projectile.SpawnerType == EntityType.ENTITY_LOKI or projectile.SpawnerType == EntityType.ENTITY_URIEL) and projectile.SpawnerVariant == 1) or projectile.SpawnerType == EntityType.ENTITY_SATAN then
		if projectile.FrameCount % 3 == 0 then
			local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, projectile.Position + projectile.Velocity, -projectile.Velocity:Normalized() * 2, projectile):ToEffect()
			local scaler = projectile.Scale * math.random(50, 70) / 100
			trail.SpriteScale = Vector(scaler, scaler)
			trail.SpriteOffset = Vector(0, projectile.Height + 7)
			trail.DepthOffset = -80
			trail:Update()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.brimstoneProjectileUpdate, ProjectileVariant.PROJECTILE_HUSH)

function mod:kLeechInit(entity)
	if entity.Variant == 1 and entity.SpawnerEntity and entity.SpawnerType == EntityType.ENTITY_SATAN then
		entity:Remove()

		-- 1st phase
		if entity.SpawnerVariant == 0 then
			Isaac.Spawn(EntityType.ENTITY_NULLS, 0, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)

		-- 2nd phase
		--elseif entity.SpawnerVariant == 10 and entity.SpawnerEntity:ToNPC().I2 == 0 then
			--Isaac.Spawn(EntityType.ENTITY_SUCKER, 0, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.kLeechInit, EntityType.ENTITY_LEECH)