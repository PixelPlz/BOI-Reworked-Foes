local mod = ReworkedFoes



-- Clotty
function mod:ClottySketchInit(entity)
	if entity.Variant == mod.Entities.ClottySketch then
		entity.SplatColor = mod.Colors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ClottySketchInit, EntityType.ENTITY_CLOTTY)

function mod:ClottySketchUpdate(entity)
	if entity.Variant == mod.Entities.ClottySketch and entity:GetSprite():IsEventTriggered("Shoot") then
		-- Shoot 3 shots with one of them being aimed in the closest cardinal direction to the player
		local baseVector = (entity:GetPlayerTarget().Position - entity.Position):Normalized()
		baseVector = mod:ClampVector(baseVector, 90)

		for i = 0, 2 do
			local projectile = mod:FireProjectiles(entity, entity.Position, baseVector:Rotated(i * 120):Resized(9), 0, ProjectileParams())
			projectile:GetData().sketchProjectile = true

			local sprite = projectile:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/projectiles/sketch_projectile.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ClottySketchUpdate, EntityType.ENTITY_CLOTTY)



-- Charger
function mod:ChargerSketchInit(entity)
	if entity.Variant == mod.Entities.ChargerSketch then
		entity.SplatColor = mod.Colors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ChargerSketchInit, EntityType.ENTITY_CHARGER)

function mod:ChargerSketchUpdate(entity)
	if entity.Variant == mod.Entities.ChargerSketch then
		-- Recover after charging
		if entity.State == NpcState.STATE_MOVE and entity.I1 > 0 then
			entity.State = NpcState.STATE_SPECIAL
			entity.I1 = 0
			entity.Velocity = Vector.Zero

			local dir = mod:GetDirectionString(entity.V1:GetAngleDegrees(), true)
			entity:GetSprite():Play("Tired " .. dir, true)


		-- Keep track of when he charges
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.I1 = entity.I1 + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ChargerSketchUpdate, EntityType.ENTITY_CHARGER)



-- Globin
function mod:GlobinSketchInit(entity)
	if entity.Variant == mod.Entities.GlobinSketch then
		entity.SplatColor = mod.Colors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GlobinSketchInit, EntityType.ENTITY_GLOBIN)

function mod:GlobinSketchUpdate(entity)
	if entity.Variant == mod.Entities.GlobinSketch and entity.State == NpcState.STATE_MOVE then
		-- Slower move speed
		entity.Velocity = entity.Velocity * 0.95
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GlobinSketchUpdate, EntityType.ENTITY_GLOBIN)



-- Maw
function mod:MawSketchInit(entity)
	if entity.Variant == mod.Entities.MawSketch then
		entity.SplatColor = mod.Colors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MawSketchInit, EntityType.ENTITY_MAW)

function mod:MawSketchUpdate(entity)
	if entity.Variant == mod.Entities.MawSketch then
		-- Slower move speed
		entity.Velocity = entity.Velocity * 0.95

		-- Make their shots inaccurate
		if entity:GetSprite():IsEventTriggered("Shoot") then
			for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, false)) do
				if projectile.FrameCount <= 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.Index == entity.Index and not projectile:GetData().sketchProjectile then
					projectile.Velocity = projectile.Velocity:Rotated(mod:Random(-20, 20))
					projectile:GetData().sketchProjectile = true

					local sprite = projectile:GetSprite()
					sprite:ReplaceSpritesheet(0, "gfx/projectiles/sketch_projectile.png")
					sprite:LoadGraphics()
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MawSketchUpdate, EntityType.ENTITY_MAW)

-- Blood trail
function mod:MawSketchTrail(effect)
	-- Blood trail
	if effect.FrameCount <= 1 and effect.SpawnerType == EntityType.ENTITY_MAW and effect.SpawnerVariant == mod.Entities.MawSketch then
		effect:GetSprite().Color = mod.Colors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.MawSketchTrail, EffectVariant.BLOOD_SPLAT)

-- Shoot effect
function mod:MawSketchShootEffect(effect)
	if effect.FrameCount <= 1 then
		for i, maw in pairs(Isaac.FindByType(EntityType.ENTITY_MAW, mod.Entities.MawSketch, -1, false, false)) do
			if maw:ToNPC().State == NpcState.STATE_ATTACK and maw.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
				local c = mod.Colors.Sketch
				effect:GetSprite().Color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.MawSketchShootEffect, EffectVariant.BLOOD_EXPLOSION)



-- Sketch projectile poof
function mod:SketchProjectilePoof(effect)
	for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, 0, -1, false, false)) do
		if projectile:GetData().sketchProjectile and projectile.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
			local sprite = effect:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/projectiles/sketch_projectile.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.SketchProjectilePoof, EffectVariant.BULLET_POOF)