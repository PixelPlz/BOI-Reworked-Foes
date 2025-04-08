local mod = ReworkedFoes



-- Get projectiles for the better shoot function
function mod:ProjectileTracker(projectile)
	if mod.RecordProjectiles then
        table.insert(mod.RecordedProjectiles, projectile)
    end
end
if not REPENTOGON then
	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.ProjectileTracker)
end





--[[ Edit vanilla projectiles ]]--
mod.ProjectileVariantToANM2 = {
	[ProjectileVariant.PROJECTILE_NORMAL] = "009.000_projectile",
	[ProjectileVariant.PROJECTILE_BONE]   = "009.001_bone projectile",
	[ProjectileVariant.PROJECTILE_FIRE]   = "009.002_fire projectile",
	[ProjectileVariant.PROJECTILE_PUKE]   = "009.003_puke projectile",
	[ProjectileVariant.PROJECTILE_TEAR]   = "009.004_tear projectile",
	[ProjectileVariant.PROJECTILE_CORN]   = "009.005_corn projectile",
	[ProjectileVariant.PROJECTILE_HUSH]   = "009.006_hush projectile",
	[ProjectileVariant.PROJECTILE_COIN]   = "009.007_coin projectile",
	--[ProjectileVariant.PROJECTILE_GRID] = "",
	[ProjectileVariant.PROJECTILE_ROCK]   = "009.009_rock projectile",
	--[ProjectileVariant.PROJECTILE_RING] = "",
	[ProjectileVariant.PROJECTILE_MEAT]   = "009.011_meat projectile",
	[ProjectileVariant.PROJECTILE_FCUK]   = "009.012_steven projectile",
	[ProjectileVariant.PROJECTILE_WING]   = "009.013_static feather projectile",
	[ProjectileVariant.PROJECTILE_LAVA]   = "009.014_lava projectile",
	[ProjectileVariant.PROJECTILE_HEAD]   = "009.015_head projectile",
	[ProjectileVariant.PROJECTILE_PEEP]   = "009.016_eyeball projectile",
	[mod.Entities.FeatherProjectile] 	  = "feather projectile",
	[mod.Entities.SuckerProjectile] 	  = "sucker projectile",
}

-- Change a projectile's variant.
---@param projectile EntityProjectile
---@param variant ProjectileVariant
---@param color Color?
function mod:ChangeProjectile(projectile, variant, color)
	projectile.Variant = variant

	-- Load the new animation file for the variant
	local sprite = projectile:GetSprite()
	local oldAnim = sprite:GetAnimation()

	sprite:Load("gfx/" .. mod.ProjectileVariantToANM2[variant] .. ".anm2", true)
	sprite:Play(oldAnim, true)

	-- Set the new color
	if color then
		sprite.Color = color
	end
end



-- Default projectile
function mod:EditNormalProjectilesInit(projectile)
	-- The Haunt / Lil Haunts
	if projectile.SpawnerType == EntityType.ENTITY_THE_HAUNT and not projectile:HasProjectileFlags(ProjectileFlags.GHOST) then
		projectile:AddProjectileFlags(ProjectileFlags.GHOST)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, mod.EditNormalProjectilesInit, ProjectileVariant.PROJECTILE_NORMAL)

function mod:EditNormalProjectiles(projectile)
	if projectile.FrameCount <= 1 then
		local sprite = projectile:GetSprite()
		local data = projectile:GetData()

		-- Tainted Pooter backsplit shots
		if projectile.SpawnerType == EntityType.ENTITY_POOTER and projectile.SpawnerVariant == 2
		and projectile:HasProjectileFlags(ProjectileFlags.BACKSPLIT) then
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


		-- Retribution Drowned Maggot and Spitties
		elseif Retribution
		and (projectile.SpawnerType == EntityType.ENTITY_MAGGOT or projectile.SpawnerType == EntityType.ENTITY_SPITTY or projectile.SpawnerType == EntityType.ENTITY_CONJOINED_SPITTY)
		and projectile.SpawnerVariant == 1873 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


		-- Dead Meat
		elseif projectile.SpawnerType == EntityType.ENTITY_MEMBRAIN and projectile.SpawnerVariant == 2 then
			-- Mortis colors
			if LastJudgement and LastJudgement.STAGE.Mortis:IsStage() then
				mod:QuickTrail(projectile, 0.1, Color(0,0,0, 1, 0.48,0.24,0.32), projectile.Scale * 1.6)
			else
				sprite.Color = mod.Colors.CorpseYellow
				mod:QuickTrail(projectile, 0.1, mod.Colors.CorpseYellowTrail, projectile.Scale * 1.6)
			end


		-- The Frail
		elseif projectile.SpawnerType == EntityType.ENTITY_PIN and projectile.SpawnerVariant == 2 and projectile.SpawnerEntity then
			-- 1st phase
			if projectile.SpawnerEntity:ToNPC().I2 == 0 then
				if not projectile.SpawnerEntity:GetData().wasDelirium then
					sprite.Color = mod.Colors.CorpseGreen
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
						projectile:ClearProjectileFlags(ProjectileFlags.BURST)

						projectile.Scale = 2
						projectile:AddFallingSpeed(2)
						sprite.Color = mod.Colors.BlueFireShot

						projectile:AddProjectileFlags(ProjectileFlags.FIRE)
						data.customFireWave = {X = true, Type = 3}
					end

				-- Default
				else
					projectile.Scale = 1.5
					data.trailColor = Color.Default
				end
			end


		-- Blue Famine 1st phase shots
		elseif projectile.SpawnerType == EntityType.ENTITY_FAMINE and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1
		and projectile.SpawnerEntity:ToNPC().State == NpcState.STATE_SUMMON then
			projectile.Velocity = projectile.Velocity:Resized(11)


		-- White Pestilence 1st phase shots
		elseif projectile.SpawnerType == EntityType.ENTITY_PESTILENCE and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 1
		and projectile.SpawnerEntity:ToNPC().I1 <= 0 then
			projectile.Velocity = projectile.Velocity:Resized(11)


		-- Blue Peep
		elseif projectile.SpawnerType == EntityType.ENTITY_PEEP and projectile.SpawnerVariant == 0
		and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


		-- Blastocyst
		elseif projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_BIG
		or projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_MEDIUM
		or projectile.SpawnerType == EntityType.ENTITY_BLASTOCYST_SMALL then
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


		-- Blue Conjoined Fatty
		elseif projectile.SpawnerType == EntityType.ENTITY_CONJOINED_FATTY and projectile.SpawnerVariant == 1 then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH)


		-- Mega Maw
		elseif projectile.SpawnerType == EntityType.ENTITY_MEGA_MAW and projectile.SpawnerEntity
		and not projectile.SpawnerEntity:GetData().wasDelirium then
			-- Red champion
			if projectile.SpawnerEntity.SubType == 1 then
				projectile.CollisionDamage = 1
			else
				projectile:AddProjectileFlags(ProjectileFlags.SMART)
			end


		-- The Gate
		elseif projectile.SpawnerType == EntityType.ENTITY_GATE and projectile.SpawnerEntity
		and not projectile:GetData().dontChange and not projectile.SpawnerEntity:GetData().wasDelirium then
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


		-- Angels
		elseif (projectile.SpawnerType == EntityType.ENTITY_URIEL or projectile.SpawnerType == EntityType.ENTITY_GABRIEL)
		and projectile.SpawnerEntity and not projectile.SpawnerEntity:GetData().wasDelirium then
			mod:ChangeProjectile(projectile, mod.Entities.FeatherProjectile)
			projectile.SubType = projectile.SpawnerVariant -- Black feather for fallen variants


		-- Blue boil (+ Retribution variants)
		elseif projectile.SpawnerType == EntityType.ENTITY_HUSH_BOIL
		or (Retribution and projectile.SpawnerType == EntityType.ENTITY_WALKINGBOIL and projectile.SpawnerVariant == 0 and projectile.SpawnerEntity
		and (projectile.SpawnerEntity.SubType == 184 or projectile.SpawnerEntity.SubType == 185)) then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_HUSH, mod.Colors.HushDarkBlue)


		-- Mr. Mine
		elseif projectile.SpawnerType == EntityType.ENTITY_MR_MINE
		and (not TheFuture or TheFuture.Stage:IsStage() == false) then
			mod:ChangeProjectile(projectile, ProjectileVariant.PROJECTILE_TEAR)


		-- Black Rag Man
		elseif projectile.SpawnerType == EntityType.ENTITY_RAG_MAN and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2
		and not projectile:HasProjectileFlags(ProjectileFlags.SMART) then
			projectile:AddProjectileFlags(ProjectileFlags.SMART)


		-- Adult Leech
		elseif projectile.SpawnerType == EntityType.ENTITY_ADULT_LEECH then
			local bg = Game():GetRoom():GetBackdropType()

			-- Corpse
			if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
				sprite.Color = mod.Colors.CorpseGreen
			-- Outside chapter 4
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
		if projectile.SpawnerType == EntityType.ENTITY_DINGLE and projectile.SpawnerVariant == 0
		and projectile.SpawnerEntity and projectile.SpawnerEntity.SubType == 2 then
			sprite.Color = mod.Colors.Tar


		-- Red champion Mega Fatty poop attack
		elseif projectile.SpawnerType == EntityType.ENTITY_MEGA_FATTY and projectile.SpawnerEntity
		and projectile.SpawnerEntity.SubType == 1 then
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
		if projectile.SpawnerType == EntityType.ENTITY_ISAAC and projectile.SpawnerVariant == 0
		and projectile:HasProjectileFlags(ProjectileFlags.BURST) then
			data.trailColor = mod.Colors.TearEffect
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.EditTearProjectiles, ProjectileVariant.PROJECTILE_TEAR)





--[[ Custom projectiles ]]--
-- Template for custom projectile behaviour
---@param variant integer
---@param initScript function The script to run when the projectile initializes.
---@param updateScript function The script to run when the projectile update.
---@param popScript function The script to run when the projectile lands or hits an entity / obstacle.
function mod:AddCustomProjectile(variant, initScript, updateScript, popScript)
	local function init(projectile)
		if initScript then
			initScript(nil, projectile)
		end
		projectile:GetData().customProjectileInitialized = true
		projectile:GetData().spawnerSubType = projectile.SpawnerEntity and projectile.SpawnerEntity.SubType or -1
	end


	-- Callbacks
	-- Init
	local function customProjectileInit(_, projectile)
		init(projectile)
	end
	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, customProjectileInit, variant)

	local function customProjectileUpdate(_, projectile)
		-- Late init
		if projectile.FrameCount <= 2 and not projectile:GetData().customProjectileInitialized then
			init(projectile)
		end

		-- Midair
		if updateScript then
			updateScript(_, projectile)
		end

		-- Landed
		if projectile:IsDead() and not REPENTOGON then
			popScript(_, projectile)
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, customProjectileUpdate, variant)


	-- Landed / hit an entity or obstacle
	if REPENTOGON then
		mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_DEATH, popScript, variant)

	else
		-- Hit an entity
		local function customProjectileCollision(_, projectile, collider, bool)
			if collider.Type == EntityType.ENTITY_PLAYER
			or (collider:ToNPC() and collider.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL) then
				popScript(_, projectile)
				projectile:Remove()
			end
		end
		mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, customProjectileCollision, variant)
	end
end



-- Feather projectile
function mod:FeatherProjectileInit(projectile)
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

function mod:FeatherProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Move")

	local pos = projectile.Position + projectile.PositionOffset
	sprite.Rotation = (pos + projectile.Velocity + Vector(0, projectile.FallingSpeed) - pos):GetAngleDegrees()

	sprite.Scale = Vector.One * projectile.Scale
end

function mod:FeatherProjectilePop(projectile)
	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	effect.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
	effect.Scale = Vector(0.75, 0.75)
	effect.Color = projectile.SplatColor
end

mod:AddCustomProjectile(mod.Entities.FeatherProjectile, mod.FeatherProjectileInit, mod.FeatherProjectileUpdate, mod.FeatherProjectilePop)



-- Sucker projectile
function mod:SuckerProjectileInit(projectile)
	projectile:GetData().trailColor = Color.Default
end

function mod:SuckerProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Fly")

	local pos = projectile.Position + projectile.PositionOffset
	sprite.Rotation = (pos + projectile.Velocity + Vector(0, projectile.FallingSpeed) - pos):GetAngleDegrees() + 90
end

function mod:SuckerProjectilePop(projectile)
	local sucker = Isaac.Spawn(EntityType.ENTITY_SUCKER, 0, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ToNPC()
	sucker:FireProjectiles(projectile.Position, Vector(11, 4), 7, ProjectileParams())
	mod:QuickCreep(EffectVariant.CREEP_RED, projectile.SpawnerEntity, projectile.Position, 1.5, 90)

	mod:PlaySound(nil, SoundEffect.SOUND_PLOP, 0.9)

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BULLET_POOF, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	effect.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
end

mod:AddCustomProjectile(mod.Entities.SuckerProjectile, mod.SuckerProjectileInit, mod.SuckerProjectileUpdate, mod.SuckerProjectilePop)



-- Egg sack projectile
function mod:EggSackProjectileUpdate(projectile)
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

function mod:EggSackProjectilePop(projectile)
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

mod:AddCustomProjectile(mod.Entities.EggSackProjectile, nil, mod.EggSackProjectileUpdate, mod.EggSackProjectilePop)



-- Clot projectile
function mod:ClotProjectileInit(projectile)
	projectile:GetData().trailColor = mod.Colors.TarTrail
end

function mod:ClotProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Idle")
end

function mod:ClotProjectilePop(projectile)
	local clot = Isaac.Spawn(EntityType.ENTITY_CLOTTY, 1, 0, projectile.Position, Vector.Zero, projectile.SpawnerEntity)
	clot:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	mod:QuickCreep(EffectVariant.CREEP_BLACK, projectile.SpawnerEntity, projectile.Position, 2.5, 90)

	-- Effects
	mod:PlaySound(nil, SoundEffect.SOUND_PLOP)

	for i = 3, 4 do
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, i, projectile.Position, Vector.Zero, projectile):GetSprite()
		effect.Color = mod.Colors.Tar
		effect.Scale = Vector.One * 0.75
	end
end

mod:AddCustomProjectile(mod.Entities.ClotProjectile, mod.ClotProjectileInit, mod.ClotProjectileUpdate, mod.ClotProjectilePop)



-- Sand projectile
function mod:SandProjectileInit(projectile)
	projectile:GetSprite().Rotation = math.random(1, 4) * 90
end

function mod:SandProjectileUpdate(projectile)
	local sprite = projectile:GetSprite()
	mod:LoopingAnim(sprite, "Move")
	sprite.Scale = Vector.One * projectile.Scale
end

function mod:SandProjectilePop(projectile)
	mod:PlaySound(nil, SoundEffect.SOUND_SUMMON_POOF, 1.5, 0.95)

	local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, projectile.Position, Vector.Zero, projectile):GetSprite()
	poof:Load("gfx/sand projectile.anm2", true)
	poof:Play("Poof", true)
	poof.Offset = Vector(projectile.PositionOffset.X, projectile.PositionOffset.Y * 0.65)
	poof.Scale = projectile:GetSprite().Scale
	poof.Rotation = projectile:GetSprite().Rotation
	poof:Update()
end

mod:AddCustomProjectile(mod.Entities.SandProjectile, mod.SandProjectileInit, mod.SandProjectileUpdate, mod.SandProjectilePop)

function mod:SandProjectileHit(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_PROJECTILE and damageSource.Variant == mod.Entities.SandProjectile then
		local player = entity:ToPlayer()
		local effectColor = Color(1,1,1.3, 1, 0.16,0.16,0.16)

		-- Add the slowness
		local duration = 5 * 30
		local strength = 0.88
		player:AddSlowing(damageSource, duration, strength, effectColor)

		if REPENTOGON then
			player:SetSlowingCountdown(duration)
		end

		-- Effects
		mod:PlaySound(nil, SoundEffect.SOUND_BLACK_POOF)

		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector.Zero, player)
		effect:ToEffect():FollowParent(player)
		effect.DepthOffset = player.DepthOffset + 1
		effect:GetSprite().Color = effectColor
		effect:GetSprite().PlaybackSpeed = 1.25
		effect:Update()

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.SandProjectileHit, EntityType.ENTITY_PLAYER)





--[[ Projectile presets ]]--
function mod:ProjectileUpdate(projectile)
	local data = projectile:GetData()

	-- Haemo particle trail
	if data.trailColor and projectile:IsFrame(3, 0) then
		local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, projectile.Position, Vector.Zero, projectile):ToEffect()
		trail.DepthOffset = projectile.DepthOffset - 10

		-- Trail behind the projectile
		trail.Velocity = -projectile.Velocity / 3
		trail.SpriteOffset = Vector(projectile.PositionOffset.X, projectile.Height * 0.65)

		-- Scale
		local scale = (projectile.Scale / 2) + (math.random(-20, 20) / 100)
		trail.SpriteScale = Vector.One * scale

		-- Varying color offset
		local c = data.trailColor
		local colorOffset = math.random(-1, 1) * 0.06
		trail:GetSprite().Color = Color(c.R,c.G,c.B, 1, c.RO + colorOffset, c.GO + colorOffset, c.BO + colorOffset)

		trail:Update()


	-- Sprite trail
	elseif data.spriteTrail then
		data.spriteTrail.Velocity = projectile.Position + projectile.PositionOffset - data.spriteTrail.Position
	end



	-- Custom creep projectiles
	if data.RFLeaveCreep and projectile:IsDead() then
		ReworkedFoes:QuickCreep(data.RFLeaveCreep.Type, projectile.SpawnerEntity, projectile.Position, projectile.Scale * 0.75, data.RFLeaveCreep.Timeout)
	end



	-- Custom lingering projectiles
	if data.RFLingering then
		-- Fall down if the timer runs out
		if data.RFLingering <= 0 then
			projectile.FallingAccel = 1
			data.RFLingering = nil


		-- Don't fall down
		else
			local back = -4
			local forth = 0
			local timer = 60
			local halfTimer = timer / 2

			-- Timer
			data.RFLingering = data.RFLingering - 1

			if not data.HeightOffsetTimer then
				data.HeightOffsetTimer = math.random(timer)
			elseif data.HeightOffsetTimer <= 0 then
				data.HeightOffsetTimer = timer
			else
				data.HeightOffsetTimer = data.HeightOffsetTimer - 1
			end

			-- Get the height offset
			if not data.HeightOffset then
				data.HeightOffset = 0
			end
			if data.HeightOffsetTimer < halfTimer then
				data.HeightOffset = mod:Lerp(back, forth, data.HeightOffsetTimer / halfTimer)
			else
				data.HeightOffset = mod:Lerp(forth, back, (data.HeightOffsetTimer - halfTimer) / halfTimer)
			end

			-- Set the height
			if not data.Height then
				data.Height = projectile.Height
			end
			projectile.Height = data.Height + data.HeightOffset

			-- Don't even TRY to fall down buddy
			projectile.FallingSpeed = 0
			projectile.FallingAccel = 0
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.ProjectileUpdate)



-- Custom fire wave projectiles
local function FireWaveProjectilePop(projectile)
	local data = projectile:GetData().customFireWave
	local baseAngle = data.X and 45 or 0

	for i = 0, 3 do
		local angle = baseAngle + i * 90
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_WAVE, data.Type, projectile.Position, Vector.Zero, projectile.SpawnerEntity):ToEffect().Rotation = angle
	end
	mod:PlaySound(nil, SoundEffect.SOUND_FLAME_BURST)
end

-- Landed
function mod:FireWaveProjectileUpdate(projectile)
	if projectile:GetData().customFireWave and projectile:IsDead() then
		FireWaveProjectilePop(projectile)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.FireWaveProjectileUpdate, ProjectileVariant.PROJECTILE_NORMAL)

-- Hit an entity
function mod:FireWaveProjectileCollision(projectile, collider, bool)
	if projectile:GetData().customFireWave and (collider.Type == EntityType.ENTITY_PLAYER or (collider:ToNPC() and collider.EntityCollisionClass == EntityCollisionClass.ENTCOLL_ALL)) then
		FireWaveProjectilePop(projectile)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PROJECTILE_COLLISION, mod.FireWaveProjectileCollision, ProjectileVariant.PROJECTILE_NORMAL)