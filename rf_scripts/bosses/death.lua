local mod = ReworkedFoes

local Settings = {
	-- On horse
	NewHealth = {540, 675},
	Cooldown = {40, 80},
	WanderSpeed = 2.5,
	MaxSpawns = 1,

	-- Scythes
	ScytheHealth = {20, 60},
	ScytheDelay = {10, 25},
	ScytheDelayHourglassBonus = 15,
	MinScytheDistance = 2 * 40,
}



function mod:DeathInit(entity, dontChangeHealth)
	if (entity.Variant == 0 or entity.Variant == 30) then
		-- Buff his health
		if not dontChangeHealth then
			local newHealth = Settings.NewHealth[entity.SubType + 1]
			mod:ChangeMaxHealth(entity, newHealth)
		end

		entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
	end

	-- Stupid grid collision size fix
	local oldSize = entity.Size
	entity:SetSize(entity.Size + 1, entity.SizeMulti, 12)
	entity:SetSize(oldSize, entity.SizeMulti, 12)
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
					local spawn = Isaac.Spawn(spawnType, spawnVariant, entity.SubType, pos, Vector.Zero, entity):ToNPC()
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


				-- Cardinally aligned with him
				if pattern == 1 then
					for i = 1, 4 do
						local offset = Vector.FromAngle(i * 90):Resized(room:GetGridWidth() * 40)
						local pos = room:GetClampedPosition(entity.Position + offset, entity.Size)
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
				effectSprite.Offset = Vector(-mod:GetSign(sprite.FlipX) * 18, -26)
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
				mod:DeathInit(entity, true)

				entity.State = NpcState.STATE_STOMP
				sprite:Play("Appear", true)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 1.25)

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
	elseif entity.Variant == 300 then
		local sprite = entity:GetSprite()

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

				local spawnCount = 0
				local spawnType = EntityType.ENTITY_KNIGHT
				local spawnVariant = 0

				-- Black champion Red Maws
				if entity.SubType == 1 then
					spawnType = EntityType.ENTITY_MAW
					spawnVariant = 1
				end

				spawnCount = Isaac.CountEntities(nil, spawnType, spawnVariant)

				-- Summon
				if spawnCount <= Settings.MaxSpawns and mod:Random(1) == 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Attack", true)

				-- Scythe attack
				else
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
					entity.TargetPosition = mod:GetTargetVector(entity)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Summon ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local spawnType = EntityType.ENTITY_KNIGHT
				local spawnVariant = 0

				-- Black champion Red Maws
				if entity.SubType == 1 then
					spawnType = EntityType.ENTITY_MAW
					spawnVariant = 1
				end

				for i = -1, 1, 2 do
					local pos = entity.Position + Vector(i * 40, 15)
					local spawn = Isaac.Spawn(spawnType, spawnVariant, entity.SubType, pos, Vector.Zero, entity):ToNPC()
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
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if not sprite:WasEventTriggered("Shoot") then
				sprite.FlipX = entity.TargetPosition.X < 0
			end

			if sprite:IsEventTriggered("Shoot") then
				entity.Velocity = entity.TargetPosition:Resized(50)
				mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 1, 0.95)
				entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.V1 = Vector(entity.Mass, 0)
				entity.Mass = 1
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
				entity.Mass = entity.V1.X
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
		if target.Type ~= entity.Type and entity.Variant == 30
		and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():WasEventTriggered("Shoot") then
			target:Kill()
		end

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

		-- Gibs
		for i = 1, 4 do
			local vector = mod:RandomVector(math.random(2, 4))
			local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, BackdropType.BASEMENT, entity.Position, vector, entity):ToEffect()
			rocks:Update()
			rocks:GetSprite():SetAnimation("rubble_alt", false)
		end

		-- Smoke
		for i = 1, 3 do
			local smoke = mod:SmokeParticles(entity, Vector(0, -12), 0, Vector(120, 140))
			smoke.Velocity = smoke.Velocity:Resized(math.random(2, 4))
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.ScytheDeath, EntityType.ENTITY_DEATH)