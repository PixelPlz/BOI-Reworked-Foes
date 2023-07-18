local mod = BetterMonsters

local Settings = {
	NewHealth = 800,
	DoubleStompCooldown = 240,
	HandShotSpeed = 7.5,
	LaserShotSpeed = 11,
}



function mod:satanInit(entity)
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints

	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.ProjectileCooldown = Settings.DoubleStompCooldown
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.satanInit, EntityType.ENTITY_SATAN)

function mod:satanUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	--[[ 1st phase ]]--
	if entity.Variant == 0 then
		-- Single brimstone
		if entity.State == NpcState.STATE_ATTACK2 and sprite:IsEventTriggered("Shoot") then
			local pos = Vector(entity.Position.X, Game():GetRoom():GetBottomRightPos().Y - 1)

			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_HUSH
			params.Color = IRFcolors.BrimShot

			params.Scale = 1.25
			params.CircleAngle = 0.2
			mod:FireProjectiles(entity, pos, Vector(Settings.LaserShotSpeed, 16), 9, params, Color.Default)

			params.CircleAngle = 0.4
			params.Scale = 1.75
			mod:FireProjectiles(entity, pos, Vector(Settings.LaserShotSpeed - 4.5, 8), 9, params, Color.Default)


		-- Custom hand bullet attack
		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.State = NpcState.STATE_ATTACK5

		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Scale = 1.5
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.09
				params.Spread = 1.2

				for i = -1, 1, 2 do
					local pos = entity.Position + Vector(i * 90, -40)
					entity:FireProjectiles(pos, (target.Position - pos):Resized(Settings.HandShotSpeed), 5, params)
				end

				mod:PlaySound(entity, SoundEffect.SOUND_SATAN_BLAST, 0.9)
			end

			if sprite:IsFinished("Attack03") then
				entity.State = NpcState.STATE_MOVE
			end
		end

		-- Extra death sounds
		if sprite:IsPlaying("Death") and sprite:IsEventTriggered("Shoot") then
			mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.9)
		end



	--[[ 2nd phase ]]--
	elseif entity.Variant == 10 then
		-- Regular stomp
		if sprite:GetFrame() == 10 then
			mod:PlaySound(nil, SoundEffect.SOUND_SATAN_STOMP, 0.9)
		end

		if sprite:IsEventTriggered("Stomp") then
			for i = 0, 3 do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, 1 + Game().Difficulty, entity.Position + Vector.FromAngle(i * 90):Resized(20), Vector.Zero, entity):ToEffect().Rotation = i * 90
			end
		end


		-- Double stomp
		if entity.Child then
			if entity.ProjectileCooldown <= 0 then
				-- Wait for both of them to be off-screen
				if sprite:GetFrame() == 1 or entity.Child:GetSprite():GetFrame() == 1 then
					if entity.I2 == 0 then
						mod:PlaySound(entity, SoundEffect.SOUND_SATAN_CHARGE_UP)
						entity.I2 = 1
					end

					-- Set animation speed to 0
					if sprite:GetFrame() == 1 then
						sprite.PlaybackSpeed = 0
					elseif entity.Child:GetSprite():GetFrame() == 1 then
						entity.Child:GetSprite().PlaybackSpeed = 0
					end
				end

				-- Stomp at the same time if both are off-screen
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

		-- Extra death sounds
		if entity:HasMortalDamage() then
			mod:PlaySound(entity, SoundEffect.SOUND_SATAN_HURT, 1.2)
			sprite.PlaybackSpeed = 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.satanUpdate, EntityType.ENTITY_SATAN)

-- Replace Kamikaze Leeches
function mod:kLeechInit(entity)
	if entity.Variant == 1 and entity.SpawnerType == EntityType.ENTITY_SATAN and ((entity.SpawnerVariant == 0 and Game().Difficulty > 0) or entity.SpawnerVariant == 10) then
		entity:Remove()

		-- Fallen phase Nulls
		if entity.SpawnerVariant == 0 then
			Isaac.Spawn(EntityType.ENTITY_NULLS, 0, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.kLeechInit, EntityType.ENTITY_LEECH)