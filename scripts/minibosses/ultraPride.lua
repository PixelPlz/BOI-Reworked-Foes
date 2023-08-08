local mod = BetterMonsters

local Settings = {
	Cooldown = 80,

	-- Florian
	FlorianHealthMulti = 1.5,
	MinSketchLifeTime = 100,
	TeleportCooldown = {60, 240},
}

IRFultraPrideSketches = {
	EntityType.ENTITY_CLOTTY,
	EntityType.ENTITY_CHARGER,
	EntityType.ENTITY_GLOBIN,
	EntityType.ENTITY_MAW,
}



--[[ Edmund ]]--
function mod:edmundInit(entity)
	if entity.Variant == 2 then
		entity.ProjectileCooldown = Settings.Cooldown / 2
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.edmundInit, EntityType.ENTITY_SLOTH)

function mod:edmundUpdate(entity)
	if entity.Variant == 2 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Chillin'
		if entity.State == NpcState.STATE_MOVE then
			mod:MoveRandomGridAligned(entity, 3.75)
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)

			if entity.ProjectileCooldown <= 0 then
				-- Count spawns
				local count = 0
				for i, entry in pairs(IRFultraPrideSketches) do
					count = count + #Isaac.FindByType(entry, 0, IRFentities.UltraPrideSketches, false, true)
					count = count + #Isaac.FindByType(entry, 0, 0, 								false, true)
				end

				-- Max spawns depend on if Florian is alive and the room shape
				local maxSpawns = 2

				if not entity.Child and Isaac.CountEntities(nil, entity.Type, entity.Variant, entity.SubType) <= 1 then
					maxSpawns = maxSpawns + 1
				end

				local shape = Game():GetRoom():GetRoomShape()
				if shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_2x1 or shape >= 8 then
					maxSpawns = maxSpawns + 1
				end

				-- Summon a sketch monster
				if count < maxSpawns -- Don't have more than 3 spawns active
				and ((entity.Child and count <= 0 and mod:Random(2) ~= 0) -- More likely to choose this if there are none spawned and Florian is alive
				or mod:Random(1) == 1) then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Attack", true)

				-- Shoot
				elseif entity.Position:Distance(target.Position) <= 320 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("AttackOld", true)
					mod:PlaySound(entity, SoundEffect.SOUND_ANGRY_GURGLE, 1, 0.95)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Shoot
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if not sprite:WasEventTriggered("Shoot") then
				mod:FlipTowardsTarget(entity, sprite)
			end

			if sprite:IsEventTriggered("Shoot") then
				entity.I1 = 0
				entity.I2 = 1
				entity.TargetPosition = (target.Position - entity.Position):Normalized()

				mod:ShootEffect(entity, 2, Vector(mod:GetSign(sprite.FlipX) * -14, -16), IRFcolors.GreenCreep)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 0.75)
			end

			-- Creep + projectiles
			if entity.I2 == 1 and entity:IsFrame(entity.I1 % 2 + 1, 0) then
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

			if sprite:IsEventTriggered("Shoot") then
				local selectedSpawn = mod:RandomIndex(IRFultraPrideSketches)
				Isaac.Spawn(selectedSpawn, 0, IRFentities.UltraPrideSketches, entity.Position + Vector(0, 20), Vector.Zero, entity)
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
		entity.MaxHitPoints = entity.MaxHitPoints * 1.5
		entity.HitPoints = entity.MaxHitPoints
		entity.ProjectileCooldown = Settings.Cooldown
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


		-- Chillin'
		if entity.State == NpcState.STATE_MOVE then
			-- Follow Ed if he's alive
			if entity.Parent then
				if entity.Position:Distance(entity.Parent.Position) <= 80 then
					entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, 0.15)
				else
					entity.Velocity = mod:Lerp(entity.Velocity, (entity.Parent.Position - entity.Position):Resized(4), 0.15)
				end

			-- Go after the player otherwise
			else
				mod:ChasePlayer(entity, 2, true)
			end

			mod:LoopingAnim(sprite, "Move")


			if entity.ProjectileCooldown <= 0 then
				-- Choose a sketch to transform
				local sketches = {}

				for i, entry in pairs(IRFultraPrideSketches) do
					for j, sketch in pairs(Isaac.FindByType(entry, 0, IRFentities.UltraPrideSketches, false, true)) do
						if isValidSketch(sketch) == true then
							table.insert(sketches, sketch)
						end
					end
				end

				-- Transform a sketch
				if #sketches > 0 and mod:Random(1) == 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Attack", true)
					data.chosenSketch = mod:RandomIndex(sketches)

					-- Connector beam
					local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.KINETI_BEAM, 0, entity.Position, Vector.Zero, entity):ToEffect()
					beam.Parent = entity
					beam:FollowParent(beam.Parent)
					beam.Target = data.chosenSketch
					entity.Child = beam
					beam.DepthOffset = entity.DepthOffset + data.chosenSketch.DepthOffset


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
				if entity.I1 <= 0 then
					entity.I1 = mod:Random(Settings.TeleportCooldown[1], Settings.TeleportCooldown[2])
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Vanish", true)
					entity.StateFrame = 0

				else
					entity.I1 = entity.I1 - 1
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
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end


		-- Transform a sketch
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Get rid of the connector beam
			if entity.Child and data.chosenSketch and (not data.chosenSketch:Exists() or data.chosenSketch:HasMortalDamage()) then
				entity.Child:Remove()
				data.chosenSketch = nil
			end

			-- Only shoot if the sketch is still alive
			if sprite:IsEventTriggered("Shoot") and data.chosenSketch then
				local pos = data.chosenSketch.Position

				-- Create laser
				local laser_ent_pair = {laser = EntityLaser.ShootAngle(2, entity.Position, (pos - entity.Position):GetAngleDegrees(), 3, Vector(0, entity.SpriteScale.Y * -34), entity), entity}
				local laser = laser_ent_pair.laser

				-- Set up parameters
				laser:SetMaxDistance(entity.Position:Distance(pos))
				laser.Mass = 0
				laser.DepthOffset = entity.DepthOffset + 10
				laser.OneHit = true
				laser.CollisionDamage = 0
				laser:SetColor(Color(1,1,1, 1, 0.2,0.1,0.8), 0, 1, false, false)

				mod:PlaySound(entity, SoundEffect.SOUND_CUTE_GRUNT)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end


		-- Teleport away
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if entity.StateFrame == 0 then
				if sprite:IsEventTriggered("Jump") then
					entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					entity.Visible = false
					mod:PlaySound(nil, SoundEffect.SOUND_HELL_PORTAL2, 0.75)

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Color = Color(0,0,0, 0.5)
					effect.Offset = Vector(0, -18)
					effect.Scale = Vector(1, 0.75)
				end

				if sprite:IsFinished() then
					entity.StateFrame = 1
				end

			elseif entity.StateFrame == 1 then
				entity.V1 = target.Position + mod:RandomVector(mod:Random(160, 280))
				entity.V1 = Game():GetRoom():GetClampedPosition(entity.V1, 20)

				local minDistance = 160
				if room:GetRoomShape() == RoomShape.ROOMSHAPE_IV then
					minDistance = 120
				end

				if entity.V1:Distance(Game():GetNearestPlayer(entity.Position).Position) >= minDistance then
					entity.Position = entity.V1
					entity.State = NpcState.STATE_STOMP
					sprite:Play("Vanish2", true)
					entity.Visible = true

					-- Effect
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 5, entity.Position, Vector.Zero, entity):GetSprite()
					effect.Color = Color(0,0,0, 0.5)
					effect.Offset = Vector(0, -18)
					effect.Scale = Vector(1, 0.75)
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
local function isSketch(entity)
	if entity.Variant == 0 and entity.SubType == IRFentities.UltraPrideSketches then
		return true
	end
	return false
end

-- Transform sketches, don't hurt the player with the laser
function mod:florianLaser(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_BABY and damageSource.Variant == 2 and damageFlags & DamageFlag.DAMAGE_LASER > 0 then
		for i, entry in pairs(IRFultraPrideSketches) do
			if target.Type == entry and isSketch(target) == true then
				target:Remove()
				Isaac.Spawn(target.Type, target.Variant, 0, target.Position, Vector.Zero, target.SpawnerEntity)
			end
		end

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.florianLaser)

-- Proper blood color
function mod:sketchInit(entity)
	if isSketch(entity) == true then
		entity.SplatColor = IRFcolors.Sketch
	end
end



-- Clotty
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sketchInit, EntityType.ENTITY_CLOTTY)

function mod:clottySketchUpdate(entity)
	if isSketch(entity) == true and entity:GetSprite():IsEventTriggered("Shoot") then
		-- Remove default projectiles
		for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, false)) do
			if projectile.FrameCount <= 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.Index == entity.Index and not projectile:GetData().newProjectile then
				projectile:Remove()
			end
		end


		-- Shoot 3 shots with one of them being aimed in the closest cardinal direction to the player
		local baseVector = (entity:GetPlayerTarget().Position - entity.Position):Normalized()
		baseVector = mod:ClampVector(baseVector, 90)

		for i = 0, 2 do
			local projectile = mod:FireProjectiles(entity, entity.Position, baseVector:Rotated(i * 120):Resized(9), 0, ProjectileParams())
			projectile:GetData().newProjectile = true

			local sprite = projectile:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/sketch projectile.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottySketchUpdate, EntityType.ENTITY_CLOTTY)



-- Charger
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sketchInit, EntityType.ENTITY_CHARGER)

function mod:chargerSketchUpdate(entity)
	if isSketch(entity) == true then
		-- Recover after charging
		if entity.State == NpcState.STATE_MOVE and entity.I1 > 0 then
			entity.State = NpcState.STATE_SPECIAL
			entity.I1 = 0
			entity.Velocity = Vector.Zero

			local dir = mod:GetDirectionString(entity.V1:GetAngleDegrees(), true)
			entity:GetSprite():Play("Recover " .. dir, true)


		-- Keep track of when he charges
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.I1 = entity.I1 + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.chargerSketchUpdate, EntityType.ENTITY_CHARGER)



-- Globin
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sketchInit, EntityType.ENTITY_GLOBIN)

function mod:globinSketchUpdate(entity)
	if isSketch(entity) == true and entity.State == NpcState.STATE_MOVE then
		-- Slower move speed
		entity.Velocity = entity.Velocity * 0.95
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.globinSketchUpdate, EntityType.ENTITY_GLOBIN)



-- Maw
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.sketchInit, EntityType.ENTITY_MAW)

function mod:mawSketchUpdate(entity)
	if isSketch(entity) == true then
		-- Slower move speed
		entity.Velocity = entity.Velocity * 0.95

		-- Make their shots inaccurate
		if entity:GetSprite():IsEventTriggered("Shoot") then
			for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, false)) do
				if projectile.FrameCount <= 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.Index == entity.Index then
					projectile.Velocity = projectile.Velocity:Rotated(mod:Random(-20, 20))

					local sprite = projectile:GetSprite()
					sprite:ReplaceSpritesheet(0, "gfx/sketch projectile.png")
					sprite:LoadGraphics()
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.mawSketchUpdate, EntityType.ENTITY_MAW)

function mod:mawSketchEffects(effect)
	-- Blood trail
	if effect.Variant == EffectVariant.BLOOD_SPLAT and effect.FrameCount <= 1
	and effect.SpawnerType == EntityType.ENTITY_MAW and effect.SpawnerEntity and isSketch(effect.SpawnerEntity) == true then
		effect:GetSprite().Color = IRFcolors.Sketch

	-- Shoot effect
	elseif effect.Variant == EffectVariant.BLOOD_EXPLOSION and effect.FrameCount <= 1 then
		for i, maw in pairs(Isaac.FindByType(EntityType.ENTITY_MAW, 0, IRFentities.UltraPrideSketches, false, false)) do
			if maw:ToNPC().State == NpcState.STATE_ATTACK and maw.Position:Distance(effect.Position) <= 0 then -- Of course they don't have a spawner entity set...
				local c = IRFcolors.Sketch
				effect:GetSprite().Color = Color(c.R,c.G,c.B, 0.8, c.RO,c.GO,c.BO)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.mawSketchEffects)