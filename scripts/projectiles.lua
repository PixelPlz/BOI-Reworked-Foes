local mod = BetterMonsters



function mod:ChangeProjectile(projectile, variant, color, anm2, newSheet)
	local sprite = projectile:GetSprite()
	local oldAnim = sprite:GetAnimation()

	projectile.Variant = variant
	sprite.Color = color or Color.Default


	-- Get animation file from variant
	local variantToANM2 = {}
	variantToANM2[ProjectileVariant.PROJECTILE_NORMAL] = "009.000_projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_BONE]   = "009.001_bone projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_FIRE]   = "009.002_fire projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_PUKE]   = "009.003_puke projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_TEAR]   = "009.004_tear projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_CORN]   = "009.005_corn projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_HUSH]   = "009.006_hush projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_COIN]   = "009.007_coin projectile"
	--variantToANM2[ProjectileVariant.PROJECTILE_GRID] = ""
	variantToANM2[ProjectileVariant.PROJECTILE_ROCK]   = "009.009_rock projectile"
	--variantToANM2[ProjectileVariant.PROJECTILE_RING] = ""
	variantToANM2[ProjectileVariant.PROJECTILE_MEAT]   = "009.011_meat projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_FCUK]   = "009.012_steven projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_WING]   = "009.013_static feather projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_LAVA]   = "009.014_lava projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_HEAD]   = "009.015_head projectile"
	variantToANM2[ProjectileVariant.PROJECTILE_PEEP]   = "009.016_eyeball projectile"
	variantToANM2[IRFentities.FeatherProjectile] 	   = "feather projectile"
	variantToANM2[IRFentities.SuckerProjectile] 	   = "sucker projectile"

	local anim = anm2 or variantToANM2[variant]
	sprite:Load("gfx/" .. anim .. ".anm2", true)
	sprite:Play(oldAnim, true)


	if newSheet then
		sprite:ReplaceSpritesheet(0, "gfx/" .. newSheet .. ".png")
		sprite:LoadGraphics()
	end
end



-- Get projectiles for BetterMonsters:FireProjectiles()
function mod:projectileInit(projectile)
	if IRF_RecordProjectiles then
        table.insert(IRF_RecordedProjectiles, projectile)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.projectileInit)



-- Default projectile
function mod:editNormalProjectiles(projectile)
	local sprite = projectile:GetSprite()
	local data = projectile:GetData()

	-- Clotty variants
	if projectile.SpawnerType == EntityType.ENTITY_CLOTTY then
		-- I. Blob
		if projectile.SpawnerVariant == 2 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)

		-- Grilled Clotty
		elseif projectile.SpawnerVariant == 3 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, IRFcolors.CrispyMeat)
		end


	-- Dead Meat
	elseif projectile.SpawnerType == EntityType.ENTITY_MEMBRAIN and projectile.SpawnerVariant == 2 then
		sprite.Color = IRFcolors.CorpseGreen
		mod:QuickTrail(projectile, 0.1, IRFcolors.CorpseGreenTrail, projectile.Scale * 1.6)


	-- The Frail
	elseif projectile.SpawnerType == EntityType.ENTITY_PIN and projectile.SpawnerVariant == 2 and projectile.SpawnerEntity then
		-- 1st phase
		if projectile.SpawnerEntity:ToNPC().I2 == 0 then
			if not projectile.SpawnerEntity:GetData().wasDelirium then
				sprite.Color = IRFcolors.CorpseGreen
			end
			if projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) then
				projectile:AddProjectileFlags(ProjectileFlags.ACID_GREEN)
			end

		-- 2nd phase
		elseif projectile.SpawnerEntity:ToNPC().I2 == 1 and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
			-- Black champion (this is dumb)
			if projectile.SpawnerEntity.SpawnerEntity and projectile.SpawnerEntity.SpawnerEntity.SubType == 1 then
				if projectile.FrameCount <= 1 and projectile.Velocity:GetAngleDegrees() ~= 45 then
					projectile:Remove()

				else
					projectile.Position = projectile.SpawnerEntity.Position
					projectile.Velocity = Vector.Zero

					projectile.Scale = 2
					sprite.Color = IRFcolors.BlueFireShot

					projectile:ClearProjectileFlags(ProjectileFlags.BURST)
					projectile:AddProjectileFlags(ProjectileFlags.FIRE | ProjectileFlags.FIRE_WAVE_X)
					projectile:AddFallingSpeed(2)
				end

			-- Default
			else
				projectile.Scale = 1.5
				data.trailColor = Color.Default
			end
		end


	-- Blue Peep
	elseif projectile.SpawnerType == EntityType.ENTITY_PEEP and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


	-- Blastocyst
	elseif projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_BIG or projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_MEDIUM or projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_SMALL then
		sprite:ReplaceSpritesheet(0, "gfx/blastocyst projectile.png")
		sprite:LoadGraphics()


	-- Tube Worm
	elseif projectile.SpawnerType == EntityType.ENTITY_ROUND_WORM and projectile.SpawnerVariant == 1 then
		local bg = Game():GetRoom():GetBackdropType()

		if bg == BackdropType.FLOODED_CAVES or bg == BackdropType.DOWNPOUR then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)
		elseif bg == BackdropType.DROSS then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_PUKE)
		end


	-- Mega Maw
	elseif projectile.SpawnerType == EntityType.ENTITY_MEGA_MAW and projectile.SpawnerEntity and not projectile.SpawnerEntity:GetData().wasDelirium then
		-- Red champion
		if projectile.SpawnerEntity.SubType == 1 then
			projectile.CollisionDamage = 1
		else
			projectile:AddProjectileFlags(ProjectileFlags.SMART)
		end


	-- The Gate
	elseif projectile.SpawnerType == EntityType.ENTITY_GATE and projectile.SpawnerEntity and not projectile:GetData().dontChange and not projectile.SpawnerEntity:GetData().wasDelirium then
		-- Red champion
		if projectile.SpawnerEntity.SubType == 1 then
			projectile.CollisionDamage = 1

		-- Fire projectiles for regular and black champion
		else
			local color = Color.Default
			-- Blue fires for black champion
			if projectile.SpawnerEntity.SubType == 2 then
				color = IRFcolors.BlueFire
			end

			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_FIRE, color)
			projectile:AddProjectileFlags(ProjectileFlags.FIRE)
			projectile:ClearProjectileFlags(ProjectileFlags.HIT_ENEMIES)
			sprite.Offset = Vector(0, 15)
		end


	-- Black champion Dark One
	elseif projectile.SpawnerType == EntityType.ENTITY_DARK_ONE and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 then
		sprite.Color = IRFcolors.ShadyRed


	-- Angels
	elseif ((projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerEntity and not projectile.SpawnerEntity:GetData().wasDelirium)
	or (projectile.SpawnerType == EntityType.ENTITY_BABY and projectile.SpawnerVariant == 1 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1) then
		mod:ChangeProjectile(projectile, IRFentities.FeatherProjectile)
		-- Black feather
		if (projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerVariant == 1 then
			projectile.SubType = 1
		end


	-- Blue boil / Blue conjoined fatty
	elseif projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL or (projectile.SpawnerType == EntityType.ENTITY_CONJOINED_FATTY and projectile.SpawnerVariant == 1) then
		local color = nil
		if projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL then
			color = IRFcolors.HushDarkBlue
		end
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH, color)
	
	
	-- Mr. Mine
	elseif projectile.SpawnerType == EntityType.ENTITY_MR_MINE and (not TheFuture or TheFuture.Stage:IsStage() == false) then
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


	-- Black Rag Man
	elseif projectile.SpawnerType == EntityType.ENTITY_RAG_MAN and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 and not projectile:HasProjectileFlags(ProjectileFlags.SMART) then
		projectile:AddProjectileFlags(ProjectileFlags.SMART)


	-- Adult Leech
	elseif projectile.SpawnerType == EntityType.ENTITY_ADULT_LEECH then
		local bg = Game():GetRoom():GetBackdropType()

		if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
			sprite.Color = IRFcolors.CorpseGreen
		elseif bg ~= BackdropType.WOMB and bg ~= BackdropType.UTERO and bg ~= BackdropType.SCARRED_WOMB and bg ~= BackdropType.CORPSE3 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_ROCK)
			projectile.Scale = 0.9
		end


	-- Cyst
	elseif projectile.SpawnerType == EntityType.ENTITY_CYST then
		sprite.Color = IRFcolors.CorpseYellow
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.editNormalProjectiles, ProjectileVariant.PROJECTILE_NORMAL)



-- Bone projectile
function mod:editBoneProjectiles(projectile)
	local sprite = projectile:GetSprite()

	-- Black Bony
	if projectile.SpawnerType == EntityType.ENTITY_BLACK_BONY then
		sprite.Color = IRFcolors.BlackBony
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.editBoneProjectiles, ProjectileVariant.PROJECTILE_BONE)



-- Fire projectile
function mod:editFireProjectiles(projectile)
	local sprite = projectile:GetSprite()

	-- Mega Maw
	if projectile.SpawnerType == EntityType.ENTITY_MEGA_MAW then
		projectile:AddProjectileFlags(ProjectileFlags.FIRE)
		sprite.Offset = Vector(0, 15)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.editFireProjectiles, ProjectileVariant.PROJECTILE_FIRE)



-- Puke projectile
function mod:editPukeProjectiles(projectile)
	local sprite = projectile:GetSprite()

	-- Black champion Dingle
	if projectile.SpawnerType == EntityType.ENTITY_DINGLE and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
		sprite.Color = IRFcolors.Tar


	-- Red champion Mega Fatty poop attack
	elseif projectile.SpawnerType == EntityType.ENTITY_MEGA_FATTY and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 then
		mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_NORMAL)


	-- Cage
	elseif projectile.SpawnerType == EntityType.ENTITY_CAGE and projectile.SpawnerEntity then
		-- Green champion
		if projectile.SpawnerEntity.SubType == 1 then
			sprite.Color = IRFcolors.CageGreenShot

		-- Pink champion
		elseif projectile.SpawnerEntity.SubType == 2 then
			sprite.Color = IRFcolors.CagePinkShot
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.editPukeProjectiles, ProjectileVariant.PROJECTILE_PUKE)



-- Feather projectile
function mod:angelicFeatherUpdate(projectile)
	local sprite = projectile:GetSprite()

	if projectile.FrameCount <= 2 then
		sprite:Play("Move")
		sprite.Scale = Vector(projectile.Scale, projectile.Scale)

		if projectile.SubType == 1 then
			sprite.Color = IRFcolors.BlackBony
			projectile.SplatColor = Color(0,0,0, 1)
		else
			projectile.SplatColor = Color(0,0,0, 1, 1,1,1)
		end
	end

	sprite.Rotation = projectile.Velocity:GetAngleDegrees()

	if projectile:IsDead() then
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
		effect.Scale = Vector(0.75, 0.75)
		effect.Color = projectile.SplatColor
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.angelicFeatherUpdate, IRFentities.FeatherProjectile)



-- Projectile trail
function mod:projectileTrail(projectile)
	local data = projectile:GetData()

	-- Haemo particle trail
	if data.trailColor and projectile:IsFrame(2, 0) then
		local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, projectile.Position, Vector.Zero, projectile):ToEffect()
		trail.DepthOffset = projectile.DepthOffset - 10

		-- Trail behind the projectile
		trail.Velocity = -projectile.Velocity:Resized(1.5)
		trail.SpriteOffset = Vector(projectile.PositionOffset.X, projectile.Height * 0.65)

		-- Scale
		local scaler = projectile.Scale * 0.55 + (math.random(-15, 15) / 100)
		trail.SpriteScale = Vector(scaler, scaler)

		-- Custom offset
		local c = data.trailColor
		local colorOffset = math.random(-1, 1) * 0.06
		trail:GetSprite().Color = Color(c.R,c.G,c.B, 1, c.RO + colorOffset, c.GO + colorOffset, c.BO + colorOffset)

		trail:Update()


	-- Sprite trail
	elseif data.spriteTrail then
		data.spriteTrail.Velocity = projectile.Position + projectile.PositionOffset - data.spriteTrail.Position
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.projectileTrail)