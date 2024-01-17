local mod = ReworkedFoes



--[[ Edit vanilla projectiles ]]--
-- Easily change a projectile's variant
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
	variantToANM2[mod.Entities.FeatherProjectile] 	   = "feather projectile"
	variantToANM2[mod.Entities.SuckerProjectile] 	   = "sucker projectile"

	local anim = anm2 or variantToANM2[variant]
	sprite:Load("gfx/" .. anim .. ".anm2", true)
	sprite:Play(oldAnim, true)


	if newSheet then
		sprite:ReplaceSpritesheet(0, "gfx/" .. newSheet .. ".png")
		sprite:LoadGraphics()
	end
end



-- Get projectiles for the better shoot function
function mod:ProjectileTracker(projectile)
	if mod.RecordProjectiles then
        table.insert(mod.RecordedProjectiles, projectile)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.ProjectileTracker)



-- Default projectile
function mod:EditNormalProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local sprite = projectile:GetSprite()
		local data = projectile:GetData()

		-- Tainted Pooter backsplit shots
		if projectile.SpawnerType == EntityType.ENTITY_POOTER and projectile.SpawnerVariant == 2 and projectile:HasProjectileFlags(ProjectileFlags.BACKSPLIT) then
			data.trailColor = Color.Default


		-- Clotty variants
		elseif projectile.SpawnerType == EntityType.ENTITY_CLOTTY then
			-- I. Blob (+ Retribution Curdle)
			if projectile.SpawnerVariant == 2
			or (Retribution and projectile.SpawnerEntity and projectile.SpawnerVariant == 1873 and projectile.SpawnerEntity.SubType == 0) then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)

			-- Grilled Clotty
			elseif projectile.SpawnerVariant == 3 then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, mod.Colors.CrispyMeat)
			end


		-- Retribution Drowned Spitties
		elseif Retribution and (projectile.SpawnerType == EntityType.ENTITY_SPITTY or projectile.SpawnerType == EntityType.ENTITY_CONJOINED_SPITTY) and projectile.SpawnerVariant == 1873 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)

			projectile:AddProjectileFlags(ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.DECELERATE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
			projectile:AddChangeFlags(ProjectileFlags.ANTI_GRAVITY)
			projectile.ChangeTimeout = 60

			projectile.Acceleration = 1.09
			projectile:AddFallingSpeed(1)
			projectile:AddFallingAccel(-0.1)


		-- Dead Meat
		elseif projectile.SpawnerType == EntityType.ENTITY_MEMBRAIN and projectile.SpawnerVariant == 2 then
			sprite.Color = mod.Colors.CorpseGreen
			mod:QuickTrail(projectile, 0.1, mod.Colors.CorpseGreenTrail, projectile.Scale * 1.6)


		-- The Frail
		elseif projectile.SpawnerType == EntityType.ENTITY_PIN and projectile.SpawnerVariant == 2 and projectile.SpawnerEntity then
			-- 1st phase
			if projectile.SpawnerEntity:ToNPC().I2 == 0 then
				if not projectile.SpawnerEntity:GetData().wasDelirium then
					sprite.Color = mod.Colors.CorpseGreen
				end
				if projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) then
					projectile:AddProjectileFlags(ProjectileFlags.ACID_GREEN)
				end

			-- 2nd phase
			elseif projectile.SpawnerEntity:ToNPC().I2 == 1 and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
				-- Black champion (this is dumb)
				if projectile.SpawnerEntity.SpawnerEntity and projectile.SpawnerEntity.SpawnerEntity.SubType == 1 then
					if projectile.Velocity:GetAngleDegrees() ~= 45 then
						projectile:Remove()

					else
						projectile.Position = projectile.SpawnerEntity.Position
						projectile.Velocity = Vector.Zero

						projectile.Scale = 2
						sprite.Color = mod.Colors.BlueFireShot

						projectile:ClearProjectileFlags(ProjectileFlags.BURST)
						projectile:AddProjectileFlags(ProjectileFlags.FIRE)
						data.customFireWave = {X = true, Type = 3}
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
			sprite:ReplaceSpritesheet(0, "gfx/projectiles/blastocyst_projectile.png")
			sprite:LoadGraphics()


		-- Retribution Drowned Grub
		elseif Retribution and projectile.SpawnerType == EntityType.ENTITY_GRUB and projectile.SpawnerVariant == 0 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


		-- Tube Worm
		elseif projectile.SpawnerType == EntityType.ENTITY_ROUND_WORM and projectile.SpawnerVariant == 1 then
			local bg = Game():GetRoom():GetBackdropType()

			-- Boiler water
			if FFGRACE and FFGRACE.STAGE.Boiler:IsStage() then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR, FFGRACE.ColorBoilerWater)
			-- Regular water
			elseif bg == BackdropType.FLOODED_CAVES or bg == BackdropType.DOWNPOUR then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)
			-- Shit water
			elseif bg == BackdropType.DROSS then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_PUKE)
			end


		-- Night Crawler
		elseif projectile.SpawnerType == EntityType.ENTITY_NIGHT_CRAWLER then
			sprite.Color = Color(0.5,0,0.5, 1) -- Same color as vanilla Ragling shots


		-- Blue Conjoined Fatty
		elseif projectile.SpawnerType == EntityType.ENTITY_CONJOINED_FATTY and projectile.SpawnerVariant == 1 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH)


		-- The Haunt / Lil Haunts
		elseif projectile.SpawnerType == EntityType.ENTITY_THE_HAUNT and not projectile:HasProjectileFlags(ProjectileFlags.GHOST) then
			projectile:AddProjectileFlags(ProjectileFlags.GHOST)


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
					color = mod.Colors.BlueFire
				end

				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_FIRE, color)
				projectile:AddProjectileFlags(ProjectileFlags.FIRE)
				projectile:ClearProjectileFlags(ProjectileFlags.HIT_ENEMIES)
				sprite.Offset = Vector(0, 15)
			end


		-- Black champion Dark One
		elseif projectile.SpawnerType == EntityType.ENTITY_DARK_ONE and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 then
			sprite.Color = mod.Colors.ShadyRed


		-- Angels
		elseif (projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL) and projectile.SpawnerEntity and not projectile.SpawnerEntity:GetData().wasDelirium then
			mod:ChangeProjectile(projectile, mod.Entities.FeatherProjectile)
			-- Black feather
			if projectile.SpawnerVariant == 1 then
				projectile.SubType = 1
			end


		-- Blue boil (+ Retribution variants)
		elseif projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL
		or (Retribution and projectile.SpawnerType == EntityType.ENTITY_WALKINGBOIL and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity
		and (projectile.SpawnerEntity.SubType == 184 or projectile.SpawnerEntity.SubType == 185)) then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH, mod.Colors.HushDarkBlue)


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
				sprite.Color = mod.Colors.CorpseGreen
			elseif bg ~= BackdropType.WOMB and bg ~= BackdropType.UTERO and bg ~= BackdropType.SCARRED_WOMB and bg ~= BackdropType.CORPSE3 then
				mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_ROCK)
				projectile.Scale = 0.9
			end


		-- Cohort burst shots
		elseif projectile.SpawnerType == EntityType.ENTITY_COHORT and projectile:HasProjectileFlags(ProjectileFlags.BURST8) then
			data.trailColor = Color.Default


		-- Cyst
		elseif projectile.SpawnerType == EntityType.ENTITY_CYST then
			sprite.Color = mod.Colors.CorpseYellow


		-- Visage
		elseif projectile.SpawnerType == EntityType.ENTITY_VISAGE then
			sprite.Color = mod.Colors.RedFireShot
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditNormalProjectiles, ProjectileVariant.PROJECTILE_NORMAL)



-- Bone projectile
function mod:EditBoneProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local sprite = projectile:GetSprite()

		-- Black Bony
		if projectile.SpawnerType == EntityType.ENTITY_BLACK_BONY then
			sprite.Color = mod.Colors.BlackBony
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditBoneProjectiles, ProjectileVariant.PROJECTILE_BONE)



-- Fire projectile
function mod:EditFireProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local sprite = projectile:GetSprite()

		-- Mega Maw
		if projectile.SpawnerType == EntityType.ENTITY_MEGA_MAW then
			projectile:AddProjectileFlags(ProjectileFlags.FIRE)
			sprite.Offset = Vector(0, 15)


		-- Forsaken
		elseif projectile.SpawnerType == EntityType.ENTITY_FORSAKEN then
			sprite.Offset = Vector(0, 15)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditFireProjectiles, ProjectileVariant.PROJECTILE_FIRE)



-- Puke projectile
function mod:EditPukeProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local sprite = projectile:GetSprite()

		-- Black champion Dingle
		if projectile.SpawnerType == EntityType.ENTITY_DINGLE and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
			sprite.Color = mod.Colors.Tar


		-- Red champion Mega Fatty poop attack
		elseif projectile.SpawnerType == EntityType.ENTITY_MEGA_FATTY and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_NORMAL)


		-- Cage
		elseif projectile.SpawnerType == EntityType.ENTITY_CAGE and projectile.SpawnerEntity then
			-- Green champion
			if projectile.SpawnerEntity.SubType == 1 then
				sprite.Color = mod.Colors.CageGreenShot

			-- Pink champion
			elseif projectile.SpawnerEntity.SubType == 2 then
				sprite.Color = mod.Colors.CagePinkShot
			end


		-- Cloggy
		elseif projectile.SpawnerType == EntityType.ENTITY_CLOGGY then
			sprite.Color = mod.Colors.DrossPoop


		-- Clog
		elseif projectile.SpawnerType == EntityType.ENTITY_CLOG then
			sprite.Color = mod.Colors.DrossPoop
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditPukeProjectiles, ProjectileVariant.PROJECTILE_PUKE)



-- Tear projectile
function mod:EditTearProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local data = projectile:GetData()

		-- Isaac burst shots
		if projectile.SpawnerType == EntityType.ENTITY_ISAAC and projectile.SpawnerVariant == 0 and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
			data.trailColor = mod.Colors.TearEffect
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditTearProjectiles, ProjectileVariant.PROJECTILE_TEAR)





--[[ Custom projectiles ]]--
-- Template for custom projectile behaviour
function mod:AddCustomProjectile(variant, initScript, updateScript, popScript)
	local function init(projectile)
		projectile:GetData().spawnerSubType = projectile.SpawnerEntity and projectile.SpawnerEntity.SubType or -1
		if initScript then
			initScript(projectile)
		end
		projectile:GetData().customProjectileInitialized = true
	end

	local function pop(projectile)
		if popScript then
			popScript(projectile)
		end
		projectile:Remove()
	end


	-- Callbacks
	-- Init
	local function customProjectileInit(_, projectile)
		init(projectile)
	end
	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, customProjectileInit, variant)

	local function customProjectileUpdate(_, projectile)
		-- Late init (for things like angel feather projectiles since the init callback gets triggered before their projectile changes)
		if projectile.FrameCount <= 2 and not projectile:GetData().customProjectileInitialized then
			init(projectile)

		-- Landed
		elseif projectile:IsDead() then
			pop(projectile)

		-- Midair
		elseif updateScript then
			updateScript(projectile)
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, customProjectileUpdate, variant)

	-- Hit an entity
	local function customProjectileCollision(_, projectile, collider, bool)
		if collider.Type == EntityType.ENTITY_PLAYER or (collider:ToNPC() and collider.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL) then
			pop(projectile)
		end
	end
	mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, customProjectileCollision, variant)
end



-- Feather projectile
local function FeatherProjectileInit(projectile)
	-- Black variant
	if projectile.SubType == 1 then
		local sprite = projectile:GetSprite()
		sprite:ReplaceSpritesheet(0, "gfx/projectiles/feather_projectile_black.png")
		sprite:LoadGraphics()

		projectile.SplatColor = mod.Colors.Tar

	-- White variant
	else
		projectile.SplatColor = mod.Colors.WhiteShot
	end
end

local function FeatherProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Move")

	local pos = projectile.Position + projectile.PositionOffset
	sprite.Rotation = (pos + projectile.Velocity + Vector(0, projectile.FallingSpeed) - pos):GetAngleDegrees()

	sprite.Scale = Vector(projectile.Scale, projectile.Scale)
end

local function FeatherProjectilePop(projectile)
	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	effect.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
	effect.Scale = Vector(0.75, 0.75)
	effect.Color = projectile.SplatColor
end

mod:AddCustomProjectile(mod.Entities.FeatherProjectile, FeatherProjectileInit, FeatherProjectileUpdate, FeatherProjectilePop)



-- Sucker projectile
local function SuckerProjectileInit(projectile)
	projectile:GetData().trailColor = Color.Default
end

local function SuckerProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Fly")

	local pos = projectile.Position + projectile.PositionOffset
	sprite.Rotation = (pos + projectile.Velocity + Vector(0, projectile.FallingSpeed) - pos):GetAngleDegrees() + 90
end

local function SuckerProjectilePop(projectile)
	local sucker = Isaac.Spawn(EntityType.ENTITY_SUCKER, 0, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ToNPC()
	sucker:FireProjectiles(projectile.Position, Vector(11, 4), 7, ProjectileParams())
	mod:QuickCreep(EffectVariant.CREEP_RED, projectile.SpawnerEntity, projectile.Position, 1.5, 90)

	mod:PlaySound(nil, SoundEffect.SOUND_PLOP, 0.9)

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	effect.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
end

mod:AddCustomProjectile(mod.Entities.SuckerProjectile, SuckerProjectileInit, SuckerProjectileUpdate, SuckerProjectilePop)



-- Egg sack projectile
local function EggSackProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Sack")
	mod:FlipTowardsMovement(projectile, sprite)
	sprite.PlaybackSpeed = projectile.Velocity:Length() * 0.1

	-- On bounce
	if projectile:HasProjectileFlags(ProjectileFlags.BOUNCE_FLOOR) and projectile.Height >= -5 then
		-- Stop bouncing
		if projectile.FallingSpeed >= -12 then
			projectile.FallingSpeed = 0

		-- Reduce bounce height
		else
			projectile:AddFallingSpeed(5)
			mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position, 1.5, 90)
			mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS, -projectile.FallingSpeed / 20)
		end
	end
end

local function EggSackProjectilePop(projectile)
	local blister = Isaac.Spawn(EntityType.ENTITY_BLISTER, 0, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity)
	blister.MaxHitPoints = blister.MaxHitPoints / 2
	blister.HitPoints = blister.MaxHitPoints

	Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, Game():GetRoom():FindFreeTilePosition(projectile.Position, 0), false)
	mod:QuickCreep(EffectVariant.CREEP_WHITE, projectile.SpawnerEntity, projectile.Position, 2.5, 90)

	mod:PlaySound(nil, SoundEffect.SOUND_BOIL_HATCH)

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPIDER_EXPLOSION, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	effect.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
	effect.Scale = Vector(1.4, 1.4)
	effect.Color = mod.Colors.WhiteShot
end

mod:AddCustomProjectile(mod.Entities.EggSackProjectile, nil, EggSackProjectileUpdate, EggSackProjectilePop)





--[[ Projectile trails ]]--
function mod:ProjectileTrail(projectile)
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
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.ProjectileTrail)





--[[ Custom fire wave projectile ]]--
local function FireWaveProjectilePop(projectile)
	local data = projectile:GetData().customFireWave

	for i = 0, 3 do
		local angle = (data.X == true and 45 or 0) + i * 90
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_WAVE, data.Type, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ToEffect().Rotation = angle
	end
	mod:PlaySound(nil, SoundEffect.SOUND_FLAME_BURST)
end

-- Landed
function mod:fireWaveProjectileUpdate(projectile)
	if projectile:GetData().customFireWave and projectile:IsDead() then
		FireWaveProjectilePop(projectile)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.fireWaveProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)

-- Hit an entity
function mod:fireWaveProjectileCollision(projectile, collider, bool)
	if projectile:GetData().customFireWave and (collider.Type == EntityType.ENTITY_PLAYER or (collider:ToNPC() and collider.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL)) then
		FireWaveProjectilePop(projectile)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, mod.fireWaveProjectileCollision, ProjectileVariant.PROJECTILE_NORMAL)