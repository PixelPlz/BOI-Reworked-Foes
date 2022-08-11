local mod = BetterMonsters
local game = Game()

local Settings = {
	PopTime = 180,
	BubbleShotSpeed = 9,
	MaxBubbles = 1,
}



--[[ Bubble ]]--
function mod:bubbleUpdate(entity)
	if entity.Variant == 440 then
		if entity:HasMortalDamage() or entity.ProjectileCooldown >= Settings.PopTime then
			entity.I2 = 1

			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_TEAR
			params.FallingAccelModifier = 0.18
			entity:FireProjectiles(entity.Position, Vector(Settings.BubbleShotSpeed, 0), 6, params)
		end
		
		if entity.I2 == 1 then
			entity:Remove()
			Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):ToNPC().State = NpcState.STATE_MOVE
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, entity.Position, Vector.Zero, entity):GetSprite().Offset = Vector(0, -16)
			entity:PlaySound(SoundEffect.SOUND_PLOP, 1, 0, false, 1)

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.bubbleUpdate, EntityType.ENTITY_FLY)

function mod:bubbleCollide(entity, target, bool)
	if entity.Variant == 440 then
		if target.Type == EntityType.ENTITY_PLAYER then
			entity:ToNPC().I2 = 1 -- Pop
		elseif target.Type == EntityType.ENTITY_HIVE then
			return true -- Ignore collision
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.bubbleCollide, EntityType.ENTITY_FLY)


--[[ Drowned Hive ]]--
function mod:drownedHiveUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		
		if sprite:IsOverlayPlaying("HeadAttack") and sprite:GetOverlayFrame() > 5 and sprite:GetOverlayFrame() < 14 then
			-- Spawn a bubble fly if there aren't any alive spawned by this hive
			if sprite:GetOverlayFrame() == 6 and Isaac.CountEntities(entity, EntityType.ENTITY_FLY, 440, -1) < Settings.MaxBubbles then
				entity:PlaySound(SoundEffect.SOUND_WHEEZY_COUGH, 1, 0, false, 1)
				Isaac.Spawn(EntityType.ENTITY_FLY, 440, 0, entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Normalized() * 8, entity):ToNPC().State = NpcState.STATE_MOVE

			elseif sprite:GetOverlayFrame() % 2 == 0 then
				local params = ProjectileParams()
				params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 75

				params.Acceleration = 1.09
				params.FallingSpeedModifier = 1
				params.FallingAccelModifier = -0.2
				params.Scale = 1 + (math.random(25, 40) * 0.01)
				params.Variant = ProjectileVariant.PROJECTILE_TEAR

				entity:FireProjectiles(entity.Position, Vector.FromAngle((entity:GetPlayerTarget().Position - entity.Position):GetAngleDegrees() + math.random(-45, 45)) * math.random(4, 8), 0, params)
				entity:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 0.9, 0, false, 1)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.drownedHiveUpdate, EntityType.ENTITY_HIVE)

function mod:drownedHiveDeath(entity, target, bool)
	if entity.Variant == 1 then
		for i, maggot in ipairs(Isaac.GetRoomEntities()) do
			if maggot.SpawnerType == EntityType.ENTITY_HIVE and maggot.Type == EntityType.ENTITY_CHARGER and maggot.Variant == 1 then
				maggot:Remove()
				Isaac.Spawn(EntityType.ENTITY_FLY, 440, 0, entity.Position, Vector.Zero, entity):ToNPC().State = NpcState.STATE_MOVE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.drownedHiveDeath, EntityType.ENTITY_HIVE)