local mod = ReworkedFoes

local Settings = {
	Cooldown = {60, 90},

	-- Edmund
	EdmundSpeed = 3.75,
	MaxSpawns = 2, -- +1 without Florian

	-- Florian
	FlorianHealthMulti = 2,
	FlorianMaxDistance = 80,
	FlorianSpeed = 4, -- x0.5 while following Ed
	MinSketchLifeTime = 90,
	TeleportCooldown = {60, 240},
}

local ultraPrideSketches = {
	{EntityType.ENTITY_CLOTTY,  mod.Entities.ClottySketch},
	{EntityType.ENTITY_CHARGER, mod.Entities.ChargerSketch},
	{EntityType.ENTITY_GLOBIN,  mod.Entities.GlobinSketch},
	{EntityType.ENTITY_MAW, 	mod.Entities.MawSketch},
}



--[[ Edmund ]]--
function mod:EdmundInit(entity)
	if entity.Variant == 2 then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.EdmundInit, EntityType.ENTITY_SLOTH)

function mod:EdmundUpdate(entity)
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
				for i, entry in pairs(ultraPrideSketches) do
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
				and (entity.StateFrame ~= 1 -- First attack is always a spawn
				or (entity.Child and count <= 0 and mod:Random(2) ~= 0) -- More likely to choose this if there are none spawned and Florian is alive
				or mod:Random(1) == 1) then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Summon", true)
					entity.StateFrame = 1

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

				mod:ShootEffect(entity, 2, Vector(mod:GetSign(sprite.FlipX) * -12, -14), mod.Colors.GreenCreep)
				mod:PlaySound(entity, SoundEffect.SOUND_BOSS_LITE_SLOPPY_ROAR)
				mod:PlaySound(nil, SoundEffect.SOUND_HEARTOUT, 0.75)
			end


			-- Creep + projectiles
			if entity.I2 == 1 and entity:IsFrame(2, 0) then
				-- Projectile
				local params = ProjectileParams()
				params.Color = mod.Colors.Ipecac
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
					effect.Color = mod.Colors.GreenCreep
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
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
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
				local selectedSpawn = mod:RandomIndex(ultraPrideSketches)

				local dir = mod:ClampVector((target.Position - entity.Position):Normalized(), 90)
				local pos = entity.Position + dir:Resized(30)

				Isaac.Spawn(selectedSpawn[1], selectedSpawn[2], 0, Game():GetRoom():FindFreeTilePosition(pos, 0), Vector.Zero, entity)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
			end
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.EdmundUpdate, EntityType.ENTITY_SLOTH)

function mod:EdmundCollision(entity, target, bool)
	if entity.Variant == 2 and ((target.SpawnerType == entity.Type and target.SpawnerVariant == entity.Variant) or (target.Type == EntityType.ENTITY_BABY and target.Variant == 2)) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.EdmundCollision, EntityType.ENTITY_SLOTH)





--[[ Florian ]]--
function mod:FlorianInit(entity)
	if entity.Variant == 2 then
		entity.MaxHitPoints = entity.MaxHitPoints * Settings.FlorianHealthMulti
		entity.HitPoints = entity.MaxHitPoints
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FlorianInit, EntityType.ENTITY_BABY)

function mod:FlorianUpdate(entity)
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

				for i, entry in pairs(ultraPrideSketches) do
					for j, sketch in pairs(Isaac.FindByType(entry[1], entry[2], -1, false, true)) do
						if isValidSketch(sketch) == true then
							table.insert(sketches, sketch)
						end
					end
				end

				-- Transform a sketch
				if #sketches > 0 and mod:Random(2) ~= 0 then
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
				local c = mod.Colors.RagManPurple
				local color = Color(c.R,c.G,c.B, 0.6, c.RO,c.GO,c.BO)
				mod:ShootEffect(entity, 5, Vector(0, -18), color, 0.9)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE

				-- Attack faster if Ed is dead
				if not entity.Parent then
					entity.ProjectileCooldown = Settings.Cooldown[1] / 2
					entity.StateFrame = entity.StateFrame - 30

				else
					entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
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

					-- Set up the parameters
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
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.FlorianUpdate, EntityType.ENTITY_BABY)

function mod:FlorianCollision(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_SLOTH and target.SpawnerVariant == 2 then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.FlorianCollision, EntityType.ENTITY_BABY)



-- Transform sketches
function mod:FlorianLaser(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_BABY and damageSource.Variant == 2 and damageFlags & DamageFlag.DAMAGE_LASER > 0 then
		if entity.Index == damageSource.Entity:GetData().chosenSketch.Index then
			local hp = entity.MaxHitPoints
			entity:Remove()

			-- Change entity
			local new = Isaac.Spawn(entity.Type, 0, entity.SubType, entity.Position, Vector.Zero, entity.SpawnerEntity)
			new.MaxHitPoints = hp
			new.HitPoints = new.MaxHitPoints
			new:SetColor(mod.Colors.PortalSpawn, 15, 1, true, false)

			-- Effects
			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND, 0.75)
			mod:PlaySound(nil, SoundEffect.SOUND_EDEN_GLITCH, 1, 0.9)
		end

		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.FlorianLaser)