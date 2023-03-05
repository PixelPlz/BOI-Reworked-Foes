local mod = BetterMonsters



function mod:ChangeProjectile(projectile, variant, anim, color)
	local sprite = projectile:GetSprite()
	local oldAnim = sprite:GetAnimation()

	projectile.Variant = variant
	sprite:Load("gfx/" .. anim .. ".anm2", true)
	sprite:Play(oldAnim, true)

	if color then
		sprite.Color = color
	end
end



function mod:replaceNormalProjectiles(projectile)
	local sprite = projectile:GetSprite()
	local data = projectile:GetData()

	-- Clotty variants
	if projectile.SpawnerType == EntityType.ENTITY_CLOTTY then
		if projectile.SpawnerVariant == 2 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, "009.004_tear projectile")
		elseif projectile.SpawnerVariant == 3 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, "009.004_tear projectile", charredMeatColor)
		end


	-- Dead Meat / Cyst
	elseif (projectile.SpawnerType == EntityType.ENTITY_MEMBRAIN and projectile.SpawnerVariant == 2) or projectile.SpawnerType == EntityType.ENTITY_CYST then
		sprite.Color = corpseGreenBulletColor
		if projectile.SpawnerType == EntityType.ENTITY_MEMBRAIN and projectile.SpawnerVariant == 2 then
			data.trailColor = corpseGreenBulletTrail
		end
	
	
	-- Frail
	elseif projectile.SpawnerType == EntityType.ENTITY_PIN and projectile.SpawnerVariant == 2 and projectile.SpawnerEntity then
		if projectile.SpawnerEntity:ToNPC().I2 == 0 and not projectile.SpawnerEntity:GetData().wasDelirium then
			sprite.Color = corpseGreenBulletColor
			if projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) then
				projectile:AddProjectileFlags(ProjectileFlags.ACID_GREEN)
			end

		elseif projectile.SpawnerEntity:ToNPC().I2 == 1 and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
			data.trailColor = Color.Default
			projectile.Scale = 1.5
			
			-- Black champion
			if projectile.SpawnerEntity.SubType == 1 then
				projectile:ClearProjectileFlags(ProjectileFlags.BURST)
				projectile:AddProjectileFlags(ProjectileFlags.EXPLODE)
			end
		end


	-- Tube Worm
	elseif projectile.SpawnerType == EntityType.ENTITY_ROUND_WORM and projectile.SpawnerVariant == 1 then
		local bg = Game():GetRoom():GetBackdropType()
		if bg == BackdropType.FLOODED_CAVES or bg == BackdropType.DOWNPOUR then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, "009.004_tear projectile")
		elseif bg == BackdropType.DROSS then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_PUKE, "009.003_puke projectile")
		end


	-- Red champion Mega Maw / Gate
	elseif (projectile.SpawnerType == EntityType.ENTITY_MEGA_MAW or projectile.SpawnerType == EntityType.ENTITY_GATE) and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 then
		projectile.CollisionDamage = 1


	-- Mr. Fred
	elseif projectile.SpawnerType == EntityType.ENTITY_MR_FRED and projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) then
		data.trailColor = Color.Default


	-- Angels
	elseif ((projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerEntity and not projectile.SpawnerEntity:GetData().wasDelirium)
	or (projectile.SpawnerType == EntityType.ENTITY_BABY and projectile.SpawnerVariant == 1 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1) then
		mod:ChangeProjectile(projectile, IRFentities.featherProjectile, "feather projectile")
		-- Black feather
		if (projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerVariant == 1 then
			projectile.SubType = 1
		end


	-- Blue boil / Blue conjoined fatty
	elseif projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL or (projectile.SpawnerType == EntityType.ENTITY_CONJOINED_FATTY and projectile.SpawnerVariant == 1) then
		local color = nil
		if projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL then
			color = Color(0.6,0.6,0.6, 1, 0,0,0.1)
		end
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH, "009.006_hush projectile", color)
	
	
	-- Mr. Mine
	elseif projectile.SpawnerType == EntityType.ENTITY_MR_MINE then
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, "009.004_tear projectile")
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replaceNormalProjectiles, ProjectileVariant.PROJECTILE_NORMAL)

function mod:replaceBoneProjectiles(projectile)
	local sprite = projectile:GetSprite()
	local data = projectile:GetData()

	if projectile.FrameCount <= 2 then
		sprite.Scale = Vector(projectile.Scale, projectile.Scale)
		if projectile.Scale >= 1.5 then
			sprite.Scale = Vector(projectile.Scale - 0.5, projectile.Scale - 0.5)
			sprite:Load("gfx/830.010_big bone.anm2", true)
			sprite:Play("Move", true)
		end
	end


	-- Teratomar
	if projectile.SpawnerType == 200 and projectile.SpawnerVariant == IRFentities.teratomar and projectile.FrameCount < 2 then
		mod:ChangeProjectile(projectile, projectile.Variant, "002.002_tooth tear", Color(0.45,0.45,0.45, 1))
		sprite:Play("Tooth4Move", true)


	-- Black Bony
	elseif projectile.SpawnerType == EntityType.ENTITY_BLACK_BONY then
		sprite.Color = Color(0.2,0.2,0.2, 1)


	-- Forsaken
	elseif projectile.SpawnerType == EntityType.ENTITY_FORSAKEN and not projectile:HasProjectileFlags(ProjectileFlags.BLUE_FIRE_SPAWN) then
		data.trailColor = Color(0,0,0, 0.6, 0.6,0.6,0.6)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replaceBoneProjectiles, ProjectileVariant.PROJECTILE_BONE)

function mod:replacePukeProjectiles(projectile)
	local sprite = projectile:GetSprite()

	-- Black champion Dingle
	if projectile.SpawnerType == EntityType.ENTITY_DINGLE and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
		sprite.Color = tarBulletColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replacePukeProjectiles, ProjectileVariant.PROJECTILE_PUKE)

function mod:replaceTearProjectiles(projectile)
	-- Fix these guys dealing a full heart of damage
	if ((projectile.SpawnerType == EntityType.ENTITY_CHARGER or projectile.SpawnerType == EntityType.ENTITY_HIVE) and projectile.SpawnerVariant == 1)
	or (projectile.SpawnerType == EntityType.ENTITY_BOOMFLY and projectile.SpawnerVariant == 2) then
		projectile.CollisionDamage = 1
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replaceTearProjectiles, ProjectileVariant.PROJECTILE_TEAR)

function mod:replaceHushProjectiles(projectile)
	local data = projectile:GetData()

	-- Lokii / Fallen Uriel / Satan
	if ((projectile.SpawnerType == EntityType.ENTITY_LOKI or projectile.SpawnerType == EntityType.ENTITY_URIEL) and projectile.SpawnerVariant == 1)
	or projectile.SpawnerType == EntityType.ENTITY_SATAN or projectile.SpawnerType == EntityType.ENTITY_FORSAKEN then
		data.trailColor = Color.Default


	-- Portal
	elseif projectile.SpawnerType == EntityType.ENTITY_PORTAL then
		data.trailColor = portalBulletTrail


	-- Rag Mega Plasma
	elseif projectile.SpawnerType == 200 and projectile.SpawnerVariant == IRFentities.ragPlasma then
		data.trailColor = ragManPsyColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.replaceHushProjectiles, ProjectileVariant.PROJECTILE_HUSH)



-- Feather projectile
function mod:angelicFeatherUpdate(projectile)
	local sprite = projectile:GetSprite()

	if projectile.FrameCount <= 2 then
		sprite:Play("Move")
		sprite.Scale = Vector(projectile.Scale, projectile.Scale)

		if projectile.SubType == 1 then
			sprite.Color = Color(0.25,0.25,0.25, 1)
			projectile.SplatColor = Color(0,0,0, 1)
		else
			projectile.SplatColor = Color(1,1,1, 1, 1,1,1)
		end
	end

	sprite.Rotation = projectile.Velocity:GetAngleDegrees()

	if projectile:IsDead() then
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
		effect.Scale = Vector(0.75, 0.75)
		effect.Color = projectile.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.angelicFeatherUpdate, IRFentities.featherProjectile)



-- Trailing projectile
function mod:trailingProjectileUpdate(projectile)
	local data = projectile:GetData()

	if data.trailColor and projectile:IsFrame(2, 0) then
		for i = 0, 1 do
			local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, projectile.Position, Vector.Zero, projectile):ToEffect()

			local scaler = projectile.Scale * 0.65
			-- Trail
			if i == 1 then
				scaler = projectile.Scale * (math.random(60, 70) / 100)
				trail.Velocity = -projectile.Velocity:Normalized() * 1.5
				trail.SpriteOffset = Vector(projectile.PositionOffset.X, projectile.Height * 0.65)

			-- Back
			else
				trail:FollowParent(projectile)
			end

			trail.SpriteScale = Vector(scaler, scaler)
			trail.DepthOffset = projectile.DepthOffset - 10

			-- Custom color
			local c = data.trailColor
			local colorOffset = math.random(-1, 1) * 0.06
			trail:GetSprite().Color = Color(c.R,c.G,c.B, 1, c.RO + colorOffset, c.GO + colorOffset, c.BO + colorOffset)

			trail:Update()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.trailingProjectileUpdate)