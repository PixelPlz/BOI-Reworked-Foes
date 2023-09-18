local mod = BetterMonsters

local Settings = {
	MaxEnemyScore = 3,
	SpawnHP = 20,

	-- Lobbed small Blastocyst
	LandHeight = 8,
	JumpSpeed = 9,
	Gravity = 0.8
}



--[[ Big ]]--
function mod:blastocystBigUpdate(entity)
	local sprite = entity:GetSprite()

	-- Get the number of every Blastocyst entity and give the bigger ones more "value"
	local enemyScore = Isaac.CountEntities(nil, EntityType.ENTITY_EMBRYO, -1, -1)
	enemyScore = enemyScore + Isaac.CountEntities(nil, EntityType.ENTITY_BLASTOCYST_SMALL, -1, -1) * 2
	enemyScore = enemyScore + Isaac.CountEntities(nil, EntityType.ENTITY_BLASTOCYST_MEDIUM, -1, -1) * 4


	-- Spawn a small Blastocyst
	if entity.State == NpcState.STATE_JUMP and sprite:GetFrame() == 0 and enemyScore <= Settings.MaxEnemyScore and entity.HitPoints > Settings.SpawnHP and mod:Random(1) == 1 then
		entity.State = NpcState.STATE_SUMMON
		sprite:Play("Summon", true)

	elseif entity.State == NpcState.STATE_SUMMON then
		entity.Velocity = mod:StopLerp(entity.Velocity)

		if sprite:IsEventTriggered("Land") then
			local vector = mod:RandomVector()

			-- Lobbed small Blastocyst
			local small = Isaac.Spawn(EntityType.ENTITY_BLASTOCYST_SMALL, 0, entity.SubType, entity.Position + vector * 20, vector * 4, entity):ToNPC()
			small.MaxHitPoints = Settings.SpawnHP
			small.HitPoints = small.MaxHitPoints

			small.State = NpcState.STATE_APPEAR_CUSTOM
			small.PositionOffset = Vector(0, Settings.LandHeight - 10)
			small.V2 = Vector(0, Settings.JumpSpeed)
			small:GetSprite():Play("Midair", true)


			-- Lose health when spawning
			entity:TakeDamage(Settings.SpawnHP / 2, DamageFlag.DAMAGE_NOKILL, EntityRef(entity), 0)

			-- Effects
			mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 1, 0.9)
			mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS)

			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity):ToEffect()
			effect:FollowParent(entity)
			effect.ParentOffset = Vector(12, entity.Scale * -24)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
		end


	-- Leap
	elseif entity.State == NpcState.STATE_STOMP and (sprite:IsEventTriggered("Land") or sprite:IsEventTriggered("Shoot")) then
		-- Remove default projectiles
		if sprite:IsEventTriggered("Land") then
			for i, p in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, true)) do
				if p.FrameCount == 0 and p.SpawnerEntity.Index == entity.Index then
					p:Remove()
				end
			end

			entity.Velocity = Vector.Zero
			entity.I1 = 0
		end

		-- Shoot new projectiles
		local params = ProjectileParams()
		params.Scale = 1 + entity.I1 * 0.25
		entity:FireProjectiles(entity.Position, Vector(11 - entity.I1 * 1.5, 8), 8, params)

		entity.I1 = entity.I1 + 1


	-- Triple hop
	elseif entity.State == NpcState.STATE_ATTACK then
		-- How does this not get triggered when I set the StateFrame to 1 later on?
		if entity.StateFrame == 1 then
			entity.I1 = 0
		end

		-- Jump further
		if sprite:IsEventTriggered("Jump") then
			entity.V1 = (entity:GetPlayerTarget().Position - entity.Position):Resized(2.5)

		-- Projectiles
		elseif sprite:IsEventTriggered("Land") then
			-- Remove default projectiles
			for i, p in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, true)) do
				if p.FrameCount == 0 and p.SpawnerEntity.Index == entity.Index then
					p:Remove()
				end
			end

			-- Shoot new projectiles
			local params = ProjectileParams()
			params.Scale = 1 + entity.I1 * 0.25
			params.CircleAngle = 0
			entity:FireProjectiles(entity.Position, Vector(11, 4 + entity.I1 * 2), 9, params)

			entity.Velocity = Vector.Zero
			entity.I1 = entity.I1 + 1

		-- Repeat 2 times
		elseif sprite:IsEventTriggered("Shoot") then
			if entity.I1 <= 2 then
				sprite:SetFrame(1)
				entity.StateFrame = 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blastocystBigUpdate, EntityType.ENTITY_BLASTOCYST_BIG)



--[[ Small ]]--
function mod:blastocystSmallUpdate(entity)
	if entity.State == NpcState.STATE_APPEAR_CUSTOM and not entity:HasMortalDamage() then
		local sprite = entity:GetSprite()
		mod:LoopingAnim(sprite, "Midair")

		-- Update height
		entity.V2 = Vector(0, entity.V2.Y - Settings.Gravity)
		entity.PositionOffset = Vector(0, entity.PositionOffset.Y - entity.V2.Y)

		-- Land and attack
		if entity.PositionOffset.Y > Settings.LandHeight then
			entity.PositionOffset = Vector.Zero
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack", true)
			sprite:SetFrame(16)
			entity.StateFrame = 16
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blastocystSmallUpdate, EntityType.ENTITY_BLASTOCYST_SMALL)

function mod:blastocystSmallCollision(entity, target, cock)
	if target.Type == EntityType.ENTITY_BLASTOCYST_BIG then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.blastocystSmallCollision, EntityType.ENTITY_BLASTOCYST_SMALL)