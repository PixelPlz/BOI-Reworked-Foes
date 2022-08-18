local mod = BetterMonsters
local game = Game()

local bubbleVariant = Isaac.GetEntityVariantByName("Bubble")

local Settings = {
	PopTime = 180,
	BubbleShotSpeed = 9,
	MaxBubbles = 1,
	ProjectileCount = 5
}



--[[ Bubble ]]--
function mod:bubbleUpdate(entity)
	if entity.Variant == bubbleVariant then
		if entity:HasMortalDamage() or entity.ProjectileCooldown >= Settings.PopTime then
			entity.I2 = 1

			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_TEAR
			params.FallingAccelModifier = 0.18
			entity:FireProjectiles(entity.Position, Vector(Settings.BubbleShotSpeed, 0), 6, params)
		end
		
		if entity.I2 == 1 then
			entity:Remove()

			if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
				Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, 0, entity.Position, Vector.Zero, entity.SpawnerEntity)
			else
				Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, entity.Position, Vector.Zero, entity.SpawnerEntity):ToNPC().State = NpcState.STATE_MOVE
			end

			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, entity.Position, Vector.Zero, entity):GetSprite().Offset = Vector(0, -16)
			entity:PlaySound(SoundEffect.SOUND_PLOP, 1, 0, false, 1)

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.bubbleUpdate, EntityType.ENTITY_FLY)

function mod:bubbleCollide(entity, target, bool)
	if entity.Variant == bubbleVariant then
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


		if entity.State == NpcState.STATE_ATTACK then
			if sprite:GetOverlayFrame() == 4 or sprite:GetOverlayFrame() == 5 then -- Fuck you Bassya for changing their animation timing (JK your mod is great)
				-- Remove drowned chargers
				for i, maggot in pairs(Isaac.FindByType(EntityType.ENTITY_CHARGER, 1, -1, false, false)) do
					if maggot.SpawnerType == EntityType.ENTITY_HIVE then
						maggot:Remove()
					end
				end
				
				-- Spawn a bubble fly if it has none spanwed
				if sprite:GetOverlayFrame() == 5 then
					if Isaac.CountEntities(entity, EntityType.ENTITY_FLY, bubbleVariant, -1) < Settings.MaxBubbles then
						Isaac.Spawn(EntityType.ENTITY_FLY, bubbleVariant, 0, entity.Position, (entity:GetPlayerTarget().Position - entity.Position):Normalized() * 8, entity):ToNPC().State = NpcState.STATE_MOVE
					else
						entity.I2 = 1
					end
				end
			end


			-- Shoot projectiles if it has a bubble fly spawned
			if entity.I2 == 1 then
				if entity.StateFrame < Settings.ProjectileCount then
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
					entity.StateFrame = entity.StateFrame + 1
				end
			end
		end

		-- Reset projectile values
		if sprite:IsOverlayFinished("HeadAttack") then
			entity.StateFrame = 0
			entity.I2 = 0
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.drownedHiveUpdate, EntityType.ENTITY_HIVE)

function mod:drownedHiveDeath(entity, target, bool)
	if entity.Variant == 1 then
		for i, maggot in pairs(Isaac.FindByType(EntityType.ENTITY_CHARGER, 1, -1, false, false)) do
			if maggot.SpawnerType == EntityType.ENTITY_HIVE then
				maggot:Remove()

				local fly = Isaac.Spawn(EntityType.ENTITY_FLY, bubbleVariant, 0, entity.Position, Vector.Zero, entity):ToNPC()
				fly.State = NpcState.STATE_MOVE
				
				if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
					fly:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.drownedHiveDeath, EntityType.ENTITY_HIVE)