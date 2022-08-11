local mod = BetterMonsters
local game = Game()



-- Replace gluttony chubber with regular one
function mod:gluttonyInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity.MaxHitPoints = 0
		entity:Morph(EntityType.ENTITY_VIS, 22, 0, entity:GetChampionColorIdx())
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gluttonyInit, EntityType.ENTITY_GLUTTONY)

function mod:gluttonyUpdate(entity)
	local sprite = entity:GetSprite()


	-- Custom fat attack for super gluttony
	if (entity.Variant == 1 or entity.SubType == 1) and entity.State == NpcState.STATE_ATTACK then
		entity.State = NpcState.STATE_ATTACK4
		sprite:Play("FatAttack", true)
	end

	-- Custom attack for champion gluttony
	if entity.SubType == 1 and entity.State == NpcState.STATE_ATTACK2 then
		entity.State = NpcState.STATE_ATTACK3
	end

	if (entity.State == NpcState.STATE_ATTACK4 and sprite:IsFinished("FatAttack")) or (entity.State == NpcState.STATE_ATTACK5 and sprite:IsFinished(sprite:GetAnimation())) then
		entity.State = NpcState.STATE_MOVE
	end


	if sprite:IsEventTriggered("Shoot") or (entity.SubType == 1 and sprite:GetFrame() == 72) then
		-- Fat attack
		if entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK4 then
			entity:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1.1, 0, false, 1)
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):ToEffect()
			effect:GetSprite().Offset = Vector(0, -12)
			effect.DepthOffset = entity.DepthOffset + 10


			if entity.State == NpcState.STATE_ATTACK4 then
				local params = ProjectileParams()

				-- Super Gluttony
				if entity.Variant == 1 then
					entity:FireProjectiles(entity.Position, Vector(11, 0), 8, params)
					params.BulletFlags = ProjectileFlags.ACID_RED
					params.Scale = 1.65

				-- Champion Gluttony
				elseif entity.SubType == 1 then
					params.BulletFlags = ProjectileFlags.ACID_GREEN
					params.Color = greenBulletColor
					params.Scale = 1.5
					effect.Color = Color(0.4,0.8,0.4, 1, 0,0.4,0)
				end

				params.FallingAccelModifier = 1.25
				params.FallingSpeedModifier = math.random(-20, -10)
				params.BulletFlags = params.BulletFlags + ProjectileFlags.EXPLODE

				for i = 0, 1 do
					entity:FireProjectiles(entity.Position, Vector.FromAngle(math.random(0, 359)) * 7, 0, params)
				end
			end


		-- Creep from brimstone attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			for i = 0, 40 do
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position + (entity.V1 * (i * 30)), Vector.Zero, entity):ToEffect().Scale = 1.15
			end

			-- Super Gluttony back laser
			if entity.Variant == 1 then
				for i = 1, 40 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position + (-entity.V1 * (i * 30)), Vector.Zero, entity):ToEffect().Scale = 1.15
				end
			end


		-- Chubber attack for champion gluttony
		elseif entity.State == NpcState.STATE_ATTACK3 then
			entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 0.9, 0, false, 1)
				
			-- Blood effect
			if sprite:IsEventTriggered("Shoot") then
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):ToEffect()
				effect:GetSprite().Offset = Vector(0, -12)
				effect.SpriteScale = Vector(0.85, 0.85)
				effect.DepthOffset = entity.DepthOffset - 10
				effect.Color = Color(0.4,0.8,0.4, 1, 0,0.4,0)
				
				for i = -1, 1, 2 do
					local speed = 20
					if entity.V1.Y ~= 0 then
						speed = 14
					end
					Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position, Vector.FromAngle(entity.V1:GetAngleDegrees() + (30 * i)) * speed, entity).Parent = entity
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gluttonyUpdate, EntityType.ENTITY_GLUTTONY)

function mod:gluttonyDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.SpawnerType == EntityType.ENTITY_GLUTTONY and (damageFlags & DamageFlag.DAMAGE_EXPLOSION > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.gluttonyDMG, EntityType.ENTITY_GLUTTONY)