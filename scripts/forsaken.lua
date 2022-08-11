local mod = BetterMonsters
local game = Game()

local Settings = {
	Cooldown = 80,
	TransparencyTimer = 10,
	SpiderCount = 3,

	BouncerCount = 4,
	BallCount = 3,

	ShotSpeed = 8,
	FlameShots = 10,
	FlameDelay = 5,

	BlueShotSpeed = 9,
	BlueFlameShots = 2,
	BlueFlameDelay = 20,
}

local States = {
	Appear = 0,
	Idle = 1,

	AttackStart = 2,
	Attacking = 3,
	AttackEnd = 4,

	Summoning = 5,
	Boner = 6,

	FadeOut = 7,
	Faded = 8,
	FadeIn = 9
}



function mod:forsakenReplace(entity)
	entity:Remove()
	Isaac.Spawn(200, 4403, entity.SubType, entity.Position, Vector.Zero, entity.SpawnerEntity)
	entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 1, 0, false, 1)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.forsakenReplace, EntityType.ENTITY_FORSAKEN)

function mod:forsakenUpdate(entity)
	if entity.Variant == 4403 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()


		if not data.state then
			data.state = States.Appear
			entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 1, 0, false, 1)
			
			-- Champion sprites
			if entity.SubType == 1 then
				for i = 0, sprite:GetLayerCount() do
					sprite:ReplaceSpritesheet(i, "gfx/bosses/afterbirth/theforsaken_black.png")
				end
				sprite:LoadGraphics()
				entity.SplatColor = Color(0.5,0.5,0.5, 1, 0,0,0)
			end

		elseif data.state == States.Appear then
			data.state = States.Idle
			entity.Velocity = Vector.Zero
			entity.ProjectileCooldown = Settings.Cooldown / 2


		elseif data.state == States.Idle then
			entity.Pathfinder:MoveRandomlyBoss(false)
			entity.Velocity = entity.Velocity * 0.925
			if not sprite:IsPlaying("Idle") then
				sprite:Play("Idle", true)
			end

			-- Decide attack
			if entity.ProjectileCooldown <= 0 then
				if data.lastAttack then
					if data.lastAttack == States.Summoning then
						data.state = States.AttackStart

					elseif data.lastAttack == States.AttackStart then
						data.state = States.Boner

					elseif data.lastAttack == States.Boner then
						data.state = States.Summoning
					end
					data.lastAttack = data.state
				else
					data.state = States.Summoning
					data.lastAttack = data.state
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Flame attack
		elseif data.state == States.AttackStart then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("BlastStart") then
				sprite:Play("BlastStart", true)
			end

			if sprite:GetFrame() == 11 then
				entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_SCREAM, 1.1, 0, false, 1)
				if entity.SubType == 0 then
					SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_START, 0.9)
				end
			end
			if sprite:IsEventTriggered("Blast") then
				data.state = States.Attacking
				entity.StateFrame = 0
				
				if entity.I2 == 0 then
					entity.I2 = 1
				elseif entity.I2 == 1 then
					entity.I2 = 0
				end
			end

		elseif data.state == States.Attacking then
			entity.Velocity = Vector.Zero
			if not sprite:IsPlaying("Blasting") then
				sprite:Play("Blasting", true)
			end

			local shotsCount = Settings.FlameShots
			if entity.ProjectileCooldown <= 0 then
				entity.StateFrame = entity.StateFrame + 1
				local params = ProjectileParams()

				-- Fire ring
				if entity.SubType == 0 then
					entity.ProjectileCooldown = Settings.FlameDelay

					-- Alternate between left and right
					if entity.I2 == 0 then
						params.BulletFlags = ProjectileFlags.CURVE_LEFT
					elseif entity.I2 == 1 then
						params.BulletFlags = ProjectileFlags.CURVE_RIGHT
					end
					params.BulletFlags = params.BulletFlags + (ProjectileFlags.FIRE | ProjectileFlags.NO_WALL_COLLIDE)
					
					params.Variant = ProjectileVariant.PROJECTILE_FIRE
					params.CircleAngle = entity.StateFrame * 30
					params.FallingSpeedModifier = -1
					params.Color = Color(1,0.25,0.25, 1)

					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 6), 9, params)

				-- Black champion blue fires
				elseif entity.SubType == 1 then
					shotsCount = Settings.BlueFlameShots
					entity.ProjectileCooldown = Settings.BlueFlameDelay

					params.Variant = ProjectileVariant.PROJECTILE_BONE
					params.FallingSpeedModifier = 1.5
					params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.BLUE_FIRE_SPAWN)
					params.Color = Color(0.25,0.25,0.25, 1)

					entity:FireProjectiles(entity.Position, Vector(Settings.BlueShotSpeed, 4), 6 + (entity.StateFrame % 2), params)
					entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 0.8, 0, false, 1)
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

			-- Stop if all projectiles have been shot
			if entity.StateFrame >= shotsCount then
				data.state = States.AttackEnd
				if entity.SubType == 0 then
					SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.9)
				end
			end

		elseif data.state == States.AttackEnd then
			entity.Velocity = Vector.Zero
			if not sprite:IsPlaying("BlastEnd") then
				sprite:Play("BlastEnd", true)
				sprite:SetFrame(3)
			end

			if sprite:GetFrame() == 10 then
				data.state = States.Idle
				entity.ProjectileCooldown = Settings.Cooldown
			end


		-- Summon enemies
		elseif data.state == States.Summoning or data.state == States.Boner then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("Summon") then
				sprite:Play("Summon", true)
				entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 1, 0, false, 1)
			end

			if sprite:IsEventTriggered("Summon") and sprite:GetFrame() < 10 then
				-- Bouncing boners / balls :flushed:
				if data.state == States.Boner then
					if entity.SubType == 0 then
						for i = 0, Settings.BouncerCount - 1 do
							Isaac.Spawn(EntityType.ENTITY_BIG_BONY, 10, 0, entity.Position, Vector.Zero, entity)
						end

					elseif entity.SubType == 1 then
						local offset = math.random(0, 359)
						for i = 0, Settings.BallCount - 1 do
							Isaac.Spawn(EntityType.ENTITY_LITTLE_HORN, 1, 1, entity.Position + (Vector.FromAngle(offset + (i * (360 / Settings.BallCount))) * 10),
							Vector.FromAngle(offset + (i * (360 / Settings.BallCount))), entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						end
					end

				else
					-- Bony
					if entity.SubType == 0 then
						Isaac.Spawn(EntityType.ENTITY_BONY, 0, 0, entity.Position + Vector(0, 20), Vector.Zero, entity)

					-- Spiders, darken room
					elseif entity.SubType == 1 then
						game:Darken(1, 210)

						local offset = math.random(0, 359)
						for i = 0, Settings.SpiderCount - 1 do
							local bigBool = false
							if i == 0 then
								bigBool = true
							end
							EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (Vector.FromAngle(offset + (i * (360 / Settings.SpiderCount))) * math.random(80, 120)), bigBool, -10)
						end
					end
				end
			end

			if sprite:GetFrame() == 22 then
				if data.state == States.Boner then
					data.state = States.FadeOut
				else
					data.state = States.Idle
					entity.ProjectileCooldown = Settings.Cooldown / 2
				end
			end


		-- Bouncing bones attack
		elseif data.state == States.FadeOut then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("FadeOut") then
				sprite:Play("FadeOut", true)
			end

			if sprite:GetFrame() == 19 then
				data.state = States.Faded
				entity.I1 = 1
			end

		elseif data.state == States.Faded then
			entity.Pathfinder:MoveRandomlyBoss(false)
			entity.Velocity = entity.Velocity * 0.9
			if not sprite:IsPlaying("Faded") then
				sprite:Play("Faded", true)
			end
			
			if data.transTimer ~= nil then -- trans rights
				if data.transTimer <= 0 then
					sprite.Color = Color(1,1,1, 1)
					data.transTimer = nil
				else
					sprite.Color = Color(1,1,1, 0.5)
					data.transTimer = data.transTimer - 1
				end
			end

			-- What entity to check for
			local checkFor = {EntityType.ENTITY_BIG_BONY, 10}
			if entity.SubType == 1 then
				checkFor = {EntityType.ENTITY_LITTLE_HORN, 1}
			end

			-- Fade in if the entities are gone
			if Isaac.CountEntities(entity, checkFor[1], checkFor[2], -1) <= 0 then
				data.state = States.FadeIn
				entity.I1 = 0
				sprite.Color = Color(1,1,1, 1)
				data.transTimer = nil
			end

		elseif data.state == States.FadeIn then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("FadeIn") then
				sprite:Play("FadeIn", true)
			end

			if sprite:GetFrame() == 10 then
				data.state = States.Idle
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.forsakenUpdate, 200)

function mod:forsakenDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 4403 then
		if target:ToNPC().I1 == 1 then
			target:GetData().transTimer = Settings.TransparencyTimer
			return false
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.forsakenDMG, 200)

function mod:forsakenCollide(entity, target, bool)
	if entity.Variant == 4403 and ((target.Type == EntityType.ENTITY_CLUTCH and target.Variant == 1)
	or target.Type == EntityType.ENTITY_BONY or (target.Type == EntityType.ENTITY_BIG_BONY and target.Variant == 10)
	or (target.Type == EntityType.ENTITY_LITTLE_HORN and target.Variant == 1) or target.Type == EntityType.ENTITY_SPIDER) then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.forsakenCollide, 200)