local mod = ReworkedFoes

local Settings = {
	-- 1st phase
	NewHealth = {540, 675},
	Cooldown = {40, 80},
	WanderSpeed = 2.5,
	MaxSpawns = 1,

	-- 2nd phase
	SwingSpeed = 50,
	SwingDamage = 20,

	-- Scythes
	ScytheHealth = {20, 60},
	ScytheDelay = {10, 25},
	ScytheDelayHourglassBonus = 15,
	MinScytheDistance = 2 * 40,
}



function mod:DeathInit(entity)
	-- Horse collision size
	if entity.Variant == 20 then
		entity:SetSize(13, Vector(2, 1), 0)

	-- Death 1st and 2nd phase
	elseif (entity.Variant == 0 or entity.Variant == 30) then
		entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])

		-- Buff his health
		local newHealth = Settings.NewHealth[entity.SubType + 1]
		mod:ChangeMaxHealth(entity, newHealth)

		-- Stupid grid collision size fix
		local oldSize = entity.Size
		entity:SetSize(entity.Size + 1, entity.SizeMulti, 12)
		entity:SetSize(oldSize, entity.SizeMulti, 12)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.DeathInit, EntityType.ENTITY_DEATH)

function mod:DeathUpdate(entity)
	--[[ Death (on horse) ]]--
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local room = Game():GetRoom()

		-- Get off his horse when below half health
		if entity.HitPoints <= entity.MaxHitPoints / 2 and entity.State ~= NpcState.STATE_JUMP then
			entity.State = NpcState.STATE_JUMP
			sprite:Play("DashStart", true)
			mod:FlipTowardsTarget(entity, sprite)
		end


		--[[ Idle ]]--
		if entity.State == NpcState.STATE_MOVE then
			mod:WanderAround(entity, Settings.WanderSpeed)
			mod:LoopingAnim(sprite, "Walk")
			mod:FlipTowardsMovement(entity, sprite)

			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
				local spawnCount = 0

				-- Black champion Leeches
				if entity.SubType == 1 then
					spawnCount = Isaac.CountEntities(nil, EntityType.ENTITY_LEECH, 1)

				-- Homing scythes
				else
					for i, scythe in pairs(Isaac.FindByType(entity.Type, 10)) do
						if scythe:ToNPC().I1 == 0 then
							spawnCount = spawnCount + 1
						end
					end
				end

				-- Summon
				if spawnCount <= Settings.MaxSpawns and mod:Random(1) == 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Attack01", true)

				-- Scythe attack
				else
					entity.State = NpcState.STATE_SUMMON2
					sprite:Play("Attack04", true)

					if entity.SubType ~= 1 and mod:Random(1, 10) <= 6 - spawnCount then
						entity.I2 = 1
					else
						entity.I2 = 0
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Summon ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local spawnType = entity.Type
				local spawnVariant = 10

				-- Black champion Leeches
				if entity.SubType == 1 then
					spawnType = EntityType.ENTITY_LEECH
					spawnVariant = 1
				end

				for i = -1, 1, 2 do
					local pos = entity.Position + Vector(i * 40, 15)
					pos = Game():GetRoom():FindFreeTilePosition(pos, 0)
					local spawn = Isaac.Spawn(spawnType, spawnVariant, entity.SubType, pos, Vector.Zero, entity)
					spawn.Parent = entity
				end

				-- Effects
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_5, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Scythe attack ]]--
		elseif entity.State == NpcState.STATE_SUMMON2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local target = entity:GetPlayerTarget()
				local positions = {}

				-- Make sure that the added positions aren't too close to any players
				local function addPosition(pos)
					local nearestPlayer = Game():GetNearestPlayer(pos).Position

					if nearestPlayer:Distance(pos) > Settings.MinScytheDistance then
						table.insert(positions, pos)
					end
				end

				-- Get the spawn positions
				local pattern = 1

				-- Only do one of the patterns if there are multiple Deaths
				if Isaac.CountEntities(nil, entity.Type, entity.Variant) <= 1 then
					pattern = mod:Random(1, 3)
				end


				-- At each door
				if pattern == 1 then
					local centerPos = room:GetCenterPos()

					for i = 1, 4 do
						local offset = Vector.FromAngle(i * 90):Resized(room:GetGridWidth() * 40)
						local pos = room:GetClampedPosition(centerPos + offset, entity.Size)
						addPosition(pos)
					end


				-- In opposite corners
				elseif pattern == 2 then
					local inRightQuadrant = target.Position.X > room:GetCenterPos().X
					local inBottomQuadrant = target.Position.Y > room:GetCenterPos().Y

					for i = -1, 1, 2 do
						local basePos

						-- Don't spawn them in the corners the player is in
						if inRightQuadrant == inBottomQuadrant then
							-- Bottom left
							basePos = Vector(room:GetTopLeftPos().X, room:GetBottomRightPos().Y) + Vector(entity.Size, -entity.Size)

							-- Top right
							if i == 1 then
								basePos = Vector(room:GetBottomRightPos().X, room:GetTopLeftPos().Y) + Vector(-entity.Size, entity.Size)
							end

						else
							-- Top left
							basePos = room:GetBottomRightPos() - (Vector.One * entity.Size)

							-- Bottom right
							if i == 1 then
								basePos = room:GetTopLeftPos() + (Vector.One * entity.Size)
							end
						end

						for j = 0, 1 do
							local pos = basePos + (j * i * Vector(0, 1.5 * 40))
							addPosition(pos)
						end
					end


				-- In one side of the room
				elseif pattern == 3 then
					local xPos = room:GetTopLeftPos().X + entity.Size

					-- Always spawn on the opposite side of the room to the player
					if target.Position.X < room:GetCenterPos().X then
						xPos = room:GetBottomRightPos().X - entity.Size
					end

					local basePos = Vector(xPos, room:GetCenterPos().Y)

					for i = -3, 3, 2 do
						local pos = basePos + Vector(0, i * 40)
						addPosition(pos)
					end
				end


				-- Spawn the scythes
				for i, pos in pairs(positions) do
					local spawn = Isaac.Spawn(entity.Type, 10, entity.SubType, pos, Vector.Zero, entity):ToNPC()
					spawn.Parent = entity
					spawn.I1 = 1
					spawn.I2 = entity.I2
					spawn:Update()
				end

				-- Effects
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_0, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				if entity.I2 == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack02", true)
					mod:FlipTowardsTarget(entity, sprite)
				else
					entity.State = NpcState.STATE_MOVE
				end
			end



		--[[ Hourglass attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Start") then
				entity.StateFrame = 0
				entity.ProjectileDelay = 0
				entity.I2 = mod:RandomSign()

				-- Effects
				mod:PlaySound(nil, SoundEffect.SOUND_MENU_FLIP_DARK, 2)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 0, entity.Position, Vector.Zero, entity):ToEffect()
				effect:FollowParent(entity)
				effect.DepthOffset = entity.DepthOffset + 10

				local effectSprite = effect:GetSprite()
				effectSprite.Color = Color(0,0,0, 0.666, 0.7,0.6,0.4)
				effectSprite.Offset = Vector(-mod:GetSign(sprite.FlipX) * 24, -33)
				effectSprite.Scale = Vector.One * 0.666
			end

			-- Projectiles
			if sprite:WasEventTriggered("Start") and not sprite:WasEventTriggered("Stop") then
				if entity.ProjectileDelay <= 0 then
					local pos = entity.Position + Vector(-mod:GetSign(sprite.FlipX) * 28, 0)

					local params = ProjectileParams()
					params.Variant = mod.Entities.SandProjectile
					params.HeightModifier = -12
					params.CircleAngle = mod:DegreesToRadians(90 + entity.StateFrame * (entity.I2 * 18))
					entity:FireProjectiles(pos, Vector(11, 2), 9, params)

					entity.StateFrame = entity.StateFrame + 1
					entity.ProjectileDelay = 1
				else
					entity.ProjectileDelay = entity.ProjectileDelay - 1
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Transition to the 2nd phase ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsFinished() then
				-- Turn into the 2nd phase variant
				local maxHP = entity.MaxHitPoints
				entity:Morph(entity.Type, 30, entity.SubType, -1)
				entity.MaxHitPoints = maxHP

				entity.State = NpcState.STATE_STOMP
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
				sprite:Play("Appear", true)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 1.25)

				-- Stupid grid collision size fix
				local oldSize = entity.Size
				entity:SetSize(entity.Size + 1, entity.SizeMulti, 12)
				entity:SetSize(oldSize, entity.SizeMulti, 12)

				-- Spawn the horse
				local horse = Isaac.Spawn(entity.Type, 20, entity.SubType, entity.Position, Vector.Zero, entity)
				horse:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				horse:GetSprite().FlipX = sprite.FlipX
				horse:Update()
			end
		end

		if entity.FrameCount > 1 then
			return true
		end





	--[[ Death (without horse) ]]--
	elseif entity.Variant == 30 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		--[[ Getting off the horse ]]--
		if entity.State == NpcState.STATE_STOMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Idle ]]--
		elseif entity.State == NpcState.STATE_MOVE then
			mod:WanderAround(entity, Settings.WanderSpeed)
			mod:LoopingAnim(sprite, "Walk")
			mod:FlipTowardsMovement(entity, sprite)

			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])

				-- Get the spawn count
				local spawnType = entity.SubType == 1 and EntityType.ENTITY_DEATHS_HEAD or EntityType.ENTITY_KNIGHT
				local spawnCount = Isaac.CountEntities(nil, spawnType)

				-- Summon
				if spawnCount <= Settings.MaxSpawns + entity.SubType
				and ((entity.SubType == 1 and spawnCount <= 0) or mod:Random(1) == 1) then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Attack", true)

				-- Scythe attack
				else
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Slash", true)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Summon ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local spawnType = entity.SubType == 1 and EntityType.ENTITY_DEATHS_HEAD or EntityType.ENTITY_KNIGHT

				for i = -1, 1, 2 do
					local pos = entity.Position + Vector(i * 40, 15)
					pos = Game():GetRoom():FindFreeTilePosition(pos, 0)
					local spawn = Isaac.Spawn(spawnType, 0, 0, pos, Vector.Zero, entity)
					spawn.Parent = entity

					-- Load the custom Death's Head sprites
					if entity.SubType == 1 then
						local spawnSprite = spawn:GetSprite()
						spawnSprite:ReplaceSpritesheet(0, "gfx/monsters/rebirth/monster_211_deathshead_black.png")
						spawnSprite:LoadGraphics()
					end
				end

				-- Effects
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_5, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end



		--[[ Scythe attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if entity.SubType ~= 1 then
				-- Face the target
				if not sprite:WasEventTriggered("GetPos") then
					mod:FlipTowardsTarget(entity, sprite)
				end

				-- Damage everything caught in the swing
				if sprite:IsEventTriggered("Shoot")
				or (sprite:WasEventTriggered("Shoot") and not sprite:WasEventTriggered("Stop")) then
					-- Get the position to check from
					local pos = entity.Position

					if not sprite:IsEventTriggered("Shoot") then
						pos = pos + entity.Velocity:Resized(entity.Size * 2)
					end

					-- Deal damage
					local colliders = Isaac.FindInRadius(pos, 60, EntityPartition.ENEMY)

					for i, collider in pairs(colliders) do
						if collider.Type ~= entity.Type then
							collider:TakeDamage(Settings.SwingDamage, DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(entity), 0)

							-- Shoot on death
							if collider:HasMortalDamage() and not collider:IsDead() then
								local params = ProjectileParams()
								params.Variant = mod.Entities.SandProjectile
								entity:FireProjectiles(collider.Position, Vector(11, 8), 8, params)
							end
						end
					end
				end
			end


			-- Prepare
			if sprite:IsEventTriggered("Sound") then
				mod:PlaySound(nil, SoundEffect.SOUND_SIREN_SING_STAB, 0.8)

				-- Get the victims
				if entity.SubType == 1 then
					data.Victims = {}
					data.Beams = {}

					for i, knight in pairs( Isaac.FindByType(EntityType.ENTITY_DEATHS_HEAD) ) do
						local beam = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.KINETI_BEAM, 0, entity.Position, Vector.Zero, entity):ToEffect()
						beam.Parent = entity
						beam:FollowParent(beam.Parent)
						beam.Color = mod:ColorEx({1,1,1, 1, 0,0,0}, {1,0,0, 1})
						beam.Target = knight
						beam.DepthOffset = knight.DepthOffset - 10

						beam:Update()
						table.insert(data.Victims, knight)
						table.insert(data.Beams, beam)
					end
				end


			elseif sprite:IsEventTriggered("GetPos") then
				-- Slash effects
				if entity.SubType == 1 then
					for i, victim in pairs(data.Victims) do
						if victim:Exists() then
							local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CLEAVER_SLASH, 0, victim.Position, Vector.Zero, entity):ToEffect()
							effect:FollowParent(victim)
							effect.Color = mod:ColorEx({1,1,1, 1, 0,0,0}, {0.75,0,0, 1})
							effect.DepthOffset = victim.DepthOffset + 10
						end
					end

				-- Get the slash direction
				else
					entity.TargetPosition = mod:GetTargetVector(entity)
					sprite.FlipX = entity.TargetPosition.X < 0
				end


			-- Swoosh
			elseif sprite:IsEventTriggered("Shoot") then
				if entity.SubType == 1 then
					-- Kill the victims
					for i, victim in pairs(data.Victims) do
						if victim:Exists() then
							victim:Kill()

							-- Shoot out bones
							local params = ProjectileParams()
							params.Variant = ProjectileVariant.PROJECTILE_BONE
							params.Color = mod.Colors.BlackBony
							params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)
							entity:FireProjectiles(victim.Position, Vector(11, 6), 9, params)
						end
					end

					-- Remove the beams
					for i, beam in pairs(data.Beams) do
						if beam:Exists() then
							beam:Remove()
						end
					end

					data.Victims = nil
					data.Beams = nil

				-- Propel himself forward
				else
					entity.Velocity = entity.TargetPosition:Resized(Settings.SwingSpeed)
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					entity.V1 = Vector(entity.Mass, 0)
					entity.Mass = 1
				end

				-- Effects
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 1.25)
				mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 0.8, 0.95)


			-- Stop swooshing
			elseif sprite:IsEventTriggered("Stop") and entity.SubType ~= 1 then
				entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.Mass = entity.V1.X
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.DeathUpdate, EntityType.ENTITY_DEATH)

function mod:DeathCollision(entity, target, bool)
	if entity.Variant ~= 10 and target.SpawnerType == entity.Type then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.DeathCollision, EntityType.ENTITY_DEATH)



--[[ Scythes ]]--
function mod:ScytheUpdate(entity)
	if entity.Variant == 10 then
		if entity.FrameCount <= 1 then
			entity:AddEntityFlags(EntityFlag.FLAG_NO_BLOOD_SPLASH)
			mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 0.6, 0.95, 2)

			-- Buff their health
			local newHealth = Settings.ScytheHealth[entity.I1 + 1]
			mod:ChangeMaxHealth(entity, newHealth)

			-- Black champion sprites
			if entity.SubType == 1 then
				entity:GetSprite():ReplaceSpritesheet(0, "gfx/monsters/classic/death_scythe_black.png")
				entity:GetSprite():LoadGraphics()
			end


			-- Homing
			if entity.I1 == 0 then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL

			-- The other ones
			else
				entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.Mass = 1

				-- Start moving faster
				entity.StateFrame = mod:Random(Settings.ScytheDelay[1], Settings.ScytheDelay[2])
				if entity.I2 == 1 then
					entity.StateFrame = entity.StateFrame + Settings.ScytheDelayHourglassBonus
				end
			end


		-- Homing scythe effects
		elseif entity.State == NpcState.STATE_MOVE and entity.I1 == 0 then
			mod:SmokeParticles(entity, Vector(0, -12), 0, Vector(120, 140), nil, nil, "effects/effect_088_darksmoke_black")
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ScytheUpdate, EntityType.ENTITY_DEATH)

function mod:ScytheDeath(entity)
	if entity.Variant == 10 then
		mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)

		-- Rock particles
		for i = 1, 4 do
			local velocity = mod:RandomVector(math.random(2, 4))
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 65537, entity.Position, velocity, entity):ToEffect()
		end

		-- Smoke
		for i = 1, 3 do
			local smoke = mod:SmokeParticles(entity, Vector(0, -12), 0, Vector(120, 140))
			smoke.Velocity = smoke.Velocity:Resized(math.random(2, 4))
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ScytheDeath, EntityType.ENTITY_DEATH)