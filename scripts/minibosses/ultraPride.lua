local mod = BetterMonsters

local Settings = {
	Cooldown = 90,

	-- Edmund
	EdmundSpeed = 3.75,
	MaxSpawns = 2, -- +1 without Florian

	-- Florian
	FlorianHealthMulti = 1.5,
	FlorianMaxDistance = 80,
	FlorianSpeed = 4, -- x0.5 while following Ed
	MinSketchLifeTime = 120,
	TeleportCooldown = {60, 240},
}

IRFultraPrideSketches = {
	{EntityType.ENTITY_CLOTTY,  IRFentities.ClottySketch},
	{EntityType.ENTITY_CHARGER, IRFentities.ChargerSketch},
	{EntityType.ENTITY_GLOBIN,  IRFentities.GlobinSketch},
	{EntityType.ENTITY_MAW, 	IRFentities.MawSketch},
}



--[[ Edmund ]]--
function mod:edmundInit(entity)
	if entity.Variant == 2 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown / 2, Settings.Cooldown)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.edmundInit, EntityType.ENTITY_SLOTH)

function mod:edmundUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Chillin'
		if entity.State == NpcState.STATE_MOVE then
			mod:MoveRandomGridAligned(entity, Settings.EdmundSpeed)
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

			if entity.ProjectileCooldown <= 0 then
				-- Count spawns
				local count = 0
				for i, entry in pairs(IRFultraPrideSketches) do
					count = count + #Isaac.FindByType(entry[1], entry[2], -1, false, true)
					count = count + #Isaac.FindByType(entry[1], 0, 		  -1, false, true)
				end

				-- Max spawns depend on if Florian is alive and if there are multiple Edmunds
				local maxSpawns = Settings.MaxSpawns
				if not entity.Child and Isaac.CountEntities(nil, entity.Type, entity.Variant, entity.SubType) <= 1 then
					maxSpawns = maxSpawns + 1
				end


				-- Summon a sketch monster
				if count < maxSpawns -- Don't have more than 2 / 3 spawns active
				and ((entity.Child and count <= 0 and mod:Random(2) ~= 0) -- More likely to choose this if there are none spawned and Florian is alive
				or mod:Random(1) == 1) then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Summon", true)

				-- Shoot
				elseif entity.Position:Distance(target.Position) <= 320 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Shoot
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Face the target before shooting
			if not sprite:WasEventTriggered("Shoot") then
				mod:FlipTowardsTarget(entity, sprite)
			end


			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(entity, SoundEffect.SOUND_ANGRY_GURGLE, 1, 0.9)

			-- Start shooting
			elseif sprite:IsEventTriggered("Shoot") then
				entity.I1 = 0
				entity.I2 = 1
				entity.TargetPosition = (target.Position - entity.Position):Normalized()

				mod:ShootEffect(entity, 2, Vector(mod:GetSign(sprite.FlipX) * -12, -14), IRFcolors.GreenCreep)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 0.75)
			end


			-- Creep + projectiles
			if entity.I2 == 1 and entity:IsFrame(2, 0) then
				-- Projectile
				local params = ProjectileParams()
				params.Color = IRFcolors.Ipecac
				params.Scale = 1 + (entity.I1 / 15) + (mod:Random(50) / 100)

				params.FallingAccelModifier = mod:Random(100, 125) / 100
				params.FallingSpeedModifier = mod:Random(-16, -10) + entity.I1 / 2
				entity:FireProjectiles(entity.Position, entity.TargetPosition:Rotated(mod:Random(-12, 12)):Resized(11 - entity.I1), 0, params)

				local position = entity.Position + entity.TargetPosition:Resized((entity.I1 + 2) * 22)

				-- Don't spawn the creep outside of the room
				if Game():GetRoom():IsPositionInRoom(position, 0) then
					mod:QuickCreep(EffectVariant.CREEP_GREEN, entity, position, 2 - (entity.I1 * 0.2))

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 4 - math.ceil(entity.I1 / 3), position, Vector.Zero, entity):GetSprite()
					effect.Color = IRFcolors.GreenCreep
					effect.Scale = Vector(0.85, 0.85)
				end

				-- Stop after 8 shots
				if entity.I1 >= 7 then
					entity.I2 = 0
				else
					entity.I1 = entity.I1 + 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end


		-- Summon
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Sound
			if sprite:IsEventTriggered("Sound") then
				local sound = SoundEffect.SOUND_PAPER_OUT
				if sprite:WasEventTriggered("Shoot") == true then
					sound = SoundEffect.SOUND_PAPER_IN
				end
				mod:PlaySound(nil, sound, 0.9)

			-- Spawn the sketch
			elseif sprite:IsEventTriggered("Shoot") then
				local selectedSpawn = mod:RandomIndex(IRFultraPrideSketches)

				local dir = mod:ClampVector((target.Position - entity.Position):Normalized(), 90)
				local pos = entity.Position + dir:Resized(30)

				Isaac.Spawn(selectedSpawn[1], selectedSpawn[2], 0, Game():GetRoom():FindFreeTilePosition(pos, 0), Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.edmundUpdate, EntityType.ENTITY_SLOTH)

function mod:edmundCollide(entity, target, bool)
	if entity.Variant == 2 and ((target.SpawnerType == entity.Type and target.SpawnerVariant == entity.Variant) or (target.Type == EntityType.ENTITY_BABY and target.Variant == 2)) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.edmundCollide, EntityType.ENTITY_SLOTH)





--[[ Florian ]]--
function mod:florianInit(entity)
	if entity.Variant == 2 then
		entity.MaxHitPoints = entity.MaxHitPoints * Settings.FlorianHealthMulti
		entity.HitPoints = entity.MaxHitPoints
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown, Settings.Cooldown * 2)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.florianInit, EntityType.ENTITY_BABY)

function mod:florianUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Check if a sketch can be transformed or not
		local function isValidSketch(sketch)
			if sketch.FrameCount >= Settings.MinSketchLifeTime and not sketch:HasMortalDamage() and not sketch:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
				return true
			end
			return false
		end

		-- Effect for teleporting
		local function teleportEffect()
			local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, entity.Position, Vector.Zero, entity):GetSprite()
			effect.Color = Color(0,0,0, 0.5)
			effect.Offset = Vector(0, -18)
			effect.Scale = Vector(1, 0.75)
		end


		-- Chillin'
		if entity.State == NpcState.STATE_MOVE then
			-- Follow Ed if he's alive
			if entity.Parent then
				if entity.Position:Distance(entity.Parent.Position) <= Settings.FlorianMaxDistance then
					entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.15)
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Parent.Position - entity.Position):Resized(Settings.FlorianSpeed), 0.15)
				end

			-- Go after the player otherwise
			else
				mod:ChasePlayer(entity, Settings.FlorianSpeed / 2, true)
			end

			mod:LoopingAnim(sprite, "Move")


			if entity.ProjectileCooldown <= 0 then
				-- Choose a sketch to transform
				local sketches = {}

				for i, entry in pairs(IRFultraPrideSketches) do
					for j, sketch in pairs(Isaac.FindByType(entry[1], entry[2], -1, false, true)) do
						if isValidSketch(sketch) == true then
							table.insert(sketches, sketch)
						end
					end
				end

				-- Transform a sketch
				if #sketches > 0 and mod:Random(1) == 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Transform", true)
					data.chosenSketch = mod:RandomIndex(sketches)

				-- Shoot
				elseif entity.Position:Distance(target.Position) <= 240 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


			-- Teleport if Ed is dead
			if not entity.Parent then
				if entity.StateFrame <= 0 then
					entity.StateFrame = mod:Random(Settings.TeleportCooldown[1], Settings.TeleportCooldown[2])
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Vanish", true)

				else
					entity.StateFrame = entity.StateFrame - 1
				end
			end


		-- Shoot
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.SMART
				params.Scale = 1.25
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(10), 0, params)
				mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)

				-- Effect
				local c = IRFcolors.RagManPurple
				local color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
				mod:ShootEffect(entity, 5, Vector(0, -18), color, 0.9)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE

				-- Attack faster if Ed is dead
				if not entity.Parent then
					entity.ProjectileCooldown = Settings.Cooldown / 4
					entity.StateFrame = entity.StateFrame - 30

				else
					entity.ProjectileCooldown = Settings.Cooldown
				end
			end


		-- Transform a sketch
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get rid of the connector beam if the sketch doesn't exist anymore
			if data.beam and data.chosenSketch and (not data.chosenSketch:Exists() or data.chosenSketch:HasMortalDamage()) then
				data.beam:Remove()
				data.beam = nil
				data.chosenSketch = nil

				-- Cancel the attack entirely if it dies before the laser
				if not sprite:WasEventTriggered("Shoot") then
					sprite:Play("TransformCancel", true)
				end
			end


			if data.chosenSketch then
				-- Connector beam
				if sprite:IsEventTriggered("Jump") then
					local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.KINETI_BEAM, 0, entity.Position, Vector.Zero, entity):ToEffect()
					data.beam = beam

					beam.Parent = entity
					beam:FollowParent(beam.Parent)
					beam.Target = data.chosenSketch
					beam.DepthOffset = entity.DepthOffset + data.chosenSketch.DepthOffset


				-- Laser
				elseif sprite:IsEventTriggered("Shoot") then
					local pos = data.chosenSketch.Position

					-- Create laser
					local laser_ent_pair = {laser = EntityLaser.ShootAngle(2, entity.Position, (pos - entity.Position):GetAngleDegrees(), 3, Vector(0, entity.SpriteScale.Y * -30), entity), entity}
					local laser = laser_ent_pair.laser

					-- Set up parameters
					laser:SetMaxDistance(entity.Position:Distance(pos))
					laser.Mass = 0
					laser.DepthOffset = entity.DepthOffset - 10
					laser.OneHit = true
					laser.CollisionDamage = 0
					laser:SetColor(Color(1,1,1, 1, 0.2,0.1,0.8), 0, 1, false, false)

					mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end


		-- Teleport away
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Jump") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.Visible = false
				mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL2, 0.75)
				teleportEffect()
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end

		-- Find a good spot to teleport to
		elseif entity.State == NpcState.STATE_IDLE then
			entity.TargetPosition = target.Position + mod:RandomVector(mod:Random(160, 280))
			entity.TargetPosition = Game():GetRoom():GetClampedPosition(entity.TargetPosition, 20)

			-- Check if this spot far enough away from any players
			local nearestPlayerPos = Game():GetNearestPlayer(entity.TargetPosition).Position
			local minDistance = 160

			local shape = Game():GetRoom():GetRoomShape()
			if shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
				minDistance = 100
			end

			if entity.TargetPosition:Distance(nearestPlayerPos) >= minDistance then
				entity.Position = entity.TargetPosition
				entity.State = NpcState.STATE_STOMP
				sprite:Play("Vanish2", true)
				entity.Visible = true
				teleportEffect()

				-- Gain an eternal fly if he doesn't have one
				if entity.Child == nil then
					local fly = Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, entity)
					fly.Parent = entity
					entity.Child = fly
				end
			end

		-- Teleport back
		elseif entity.State == NpcState.STATE_STOMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Land") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL1, 0.75)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end


		if entity.FrameCount > 1 then
			return true

		-- Find Eddy boy
		elseif entity.Parent == nil then
			for i, ed in pairs(Isaac.FindByType(EntityType.ENTITY_SLOTH, 2, -1, false, true)) do
				if ed.Child == nil then
					entity.Parent = ed
					ed.Child = entity
					break
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.florianUpdate, EntityType.ENTITY_BABY)

function mod:florianCollide(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_SLOTH and target.SpawnerVariant == 2 then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.florianCollide, EntityType.ENTITY_BABY)





--[[ Monster sketches ]]--
-- Transform sketches
function mod:florianLaser(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_BABY and damageSource.Variant == 2 and damageFlags & DamageFlag.DAMAGE_LASER > 0 then
		if target.Index == damageSource.Entity:GetData().chosenSketch.Index then
			local hp = target.HitPoints
			target:Remove()
			Isaac.Spawn(target.Type, 0, target.SubType, target.Position, Vector.Zero, target.SpawnerEntity):SetColor(IRFcolors.PortalSpawn, 15, 1, true, false).HitPoints = hp

			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND, 0.75)
			mod:PlaySound(nil, SoundEffect.SOUND_EDEN_GLITCH, 1, 0.9)
		end

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.florianLaser)



-- Clotty
function mod:clottySketchInit(entity)
	if entity.Variant == IRFentities.ClottySketch then
		entity.SplatColor = IRFcolors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.clottySketchInit, EntityType.ENTITY_CLOTTY)

function mod:clottySketchUpdate(entity)
	if entity.Variant == IRFentities.ClottySketch and entity:GetSprite():IsEventTriggered("Shoot") then
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottySketchUpdate, EntityType.ENTITY_CLOTTY)



-- Charger
function mod:chargerSketchInit(entity)
	if entity.Variant == IRFentities.ChargerSketch then
		entity.SplatColor = IRFcolors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chargerSketchInit, EntityType.ENTITY_CHARGER)

function mod:chargerSketchUpdate(entity)
	if entity.Variant == IRFentities.ChargerSketch then
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.chargerSketchUpdate, EntityType.ENTITY_CHARGER)



-- Globin
function mod:globinSketchInit(entity)
	if entity.Variant == IRFentities.GlobinSketch then
		entity.SplatColor = IRFcolors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.globinSketchInit, EntityType.ENTITY_GLOBIN)

function mod:globinSketchUpdate(entity)
	if entity.Variant == IRFentities.GlobinSketch and entity.State == NpcState.STATE_MOVE then
		-- Slower move speed
		entity.Velocity = entity.Velocity * 0.95
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.globinSketchUpdate, EntityType.ENTITY_GLOBIN)



-- Maw
function mod:mawSketchInit(entity)
	if entity.Variant == IRFentities.MawSketch then
		entity.SplatColor = IRFcolors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.mawSketchInit, EntityType.ENTITY_MAW)

function mod:mawSketchUpdate(entity)
	if entity.Variant == IRFentities.MawSketch then
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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.mawSketchUpdate, EntityType.ENTITY_MAW)

-- Blood trail
function mod:mawSketchTrail(effect)
	-- Blood trail
	if effect.FrameCount <= 1 and effect.SpawnerType == EntityType.ENTITY_MAW and effect.SpawnerVariant == IRFentities.MawSketch then
		effect:GetSprite().Color = IRFcolors.Sketch
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.mawSketchTrail, EffectVariant.BLOOD_SPLAT)

-- Shoot effect
function mod:mawSketchShootEffect(effect)
	if effect.FrameCount <= 1 then
		for i, maw in pairs(Isaac.FindByType(EntityType.ENTITY_MAW, IRFentities.MawSketch, -1, false, false)) do
			if maw:ToNPC().State == NpcState.STATE_ATTACK and maw.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
				local c = IRFcolors.Sketch
				effect:GetSprite().Color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.mawSketchShootEffect, EffectVariant.BLOOD_EXPLOSION)



-- Sketch projectile poof
function mod:sketchProjectilePoof(effect)
	for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, 0, -1, false, false)) do
		if projectile:GetData().sketchProjectile and projectile.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
			local sprite = effect:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/projectiles/sketch_projectile.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.sketchProjectilePoof, EffectVariant.BULLET_POOF)