local mod = BetterMonsters
local game = Game()

local Settings = {
	NewHealth = 400,
	Cooldown = 60,
	TransparencyTimer = 10,
	SpiderCount = 3,

	BouncerCount = 3,
	BallCount = 3,

	ShotSpeed = 9,
	FlameShots = 10,
	FlameDelay = 6,

	BlueShotSpeed = 9,
	BlueFlameShots = 2,
	BlueFlameDelay = 20,
}



function mod:forsakenInit(entity)
	entity.MaxHitPoints = Settings.NewHealth
	entity.HitPoints = entity.MaxHitPoints
	entity.ProjectileCooldown = Settings.Cooldown / 2
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.forsakenInit, EntityType.ENTITY_FORSAKEN)

function mod:forsakenUpdate(entity)
	local sprite = entity:GetSprite()
	
	if entity.State == NpcState.STATE_SUMMON or entity.State == NpcState.STATE_IDLE then -- It starts with its state being 13 for some reason?
		entity.Pathfinder:MoveRandomlyBoss(false)
		entity.Velocity = entity.Velocity * 0.925
		mod:LoopingAnim(sprite, "Idle")
		
		-- Decide attack
		if entity.ProjectileCooldown <= 0 then
			if entity.I2 == 0 then
				entity.State = NpcState.STATE_SUMMON2
				entity.I2 = 1
			elseif entity.I2 == 1 then
				entity.State = NpcState.STATE_ATTACK
				entity.I2 = 2
			elseif entity.I2 == 2 then
				entity.State = NpcState.STATE_SUMMON3
				entity.I2 = 0
			end

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end
	
	
	-- Flame attack
	elseif entity.State == NpcState.STATE_ATTACK then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "BlastStart")

		if sprite:GetFrame() == 11 then
			entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_SCREAM, 1.1, 0, false, 1)
			if entity.SubType == 0 then
				SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_START, 0.9)
			end
		end
		if sprite:IsEventTriggered("Blast") then
			entity.State = NpcState.STATE_ATTACK2
			entity.StateFrame = 0
		end

	elseif entity.State == NpcState.STATE_ATTACK2 then
		entity.Velocity = Vector.Zero
		mod:LoopingAnim(sprite, "Blasting")

		local shotsCount = Settings.FlameShots
		if entity.ProjectileCooldown <= 0 then
			entity.StateFrame = entity.StateFrame + 1
			local params = ProjectileParams()

			-- Fire ring
			if entity.SubType == 0 then
				entity.ProjectileCooldown = Settings.FlameDelay

				params.BulletFlags = (ProjectileFlags.FIRE | ProjectileFlags.NO_WALL_COLLIDE)
				params.Variant = ProjectileVariant.PROJECTILE_FIRE
				params.CircleAngle = entity.StateFrame * 30
				params.Color = Color(1,0.25,0.25, 1)
				params.FallingSpeedModifier = -1

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
			entity.State = NpcState.STATE_ATTACK3
			if entity.SubType == 0 then
				SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 0.9)
			end
		end
	
	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = Vector.Zero
		if not sprite:IsPlaying("BlastEnd") then
			sprite:Play("BlastEnd", true)
			sprite:SetFrame(3)
		end

		if sprite:GetFrame() == 10 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = Settings.Cooldown
		end
	
	
	-- Summon enemies
	elseif entity.State == NpcState.STATE_SUMMON2 or entity.State == NpcState.STATE_SUMMON3 then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		if not sprite:IsPlaying("Summon") then
			sprite:Play("Summon", true)
			entity:PlaySound(SoundEffect.SOUND_THE_FORSAKEN_LAUGH, 1, 0, false, 1)
		end

		if sprite:IsEventTriggered("Summon") and sprite:GetFrame() < 10 then
			-- Bouncing boners / balls :flushed:
			if entity.State == NpcState.STATE_SUMMON3 then
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
					local offset = math.random(0, 359)
					for i = 0, Settings.SpiderCount - 1 do
						EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + (Vector.FromAngle(offset + (i * (360 / Settings.SpiderCount))) * math.random(80, 120)), false, -10)
					end
				end
			end
		end
		
		if sprite:GetFrame() == 22 then
			if entity.State == NpcState.STATE_SUMMON3 then
				entity.State = NpcState.STATE_JUMP
			else
				entity.State = NpcState.STATE_IDLE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end
	
	
	-- Bouncing bones attack
	elseif entity.State == NpcState.STATE_JUMP then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "FadeOut")

		if sprite:GetFrame() == 19 then
			entity.State = NpcState.STATE_MOVE
			entity.I1 = 1
		end
	
	elseif entity.State == NpcState.STATE_MOVE then
		entity.Pathfinder:MoveRandomlyBoss(false)
		entity.Velocity = entity.Velocity * 0.9
		mod:LoopingAnim(sprite, "Faded")
		
		-- Transparency
		if entity.StateFrame > 0 then
			sprite.Color = Color(1,1,1, 0.5)
			entity.StateFrame = entity.StateFrame - 1
		else
			sprite.Color = Color(1,1,1, 1)
		end


		-- What entity to check for
		local checkFor = {EntityType.ENTITY_BIG_BONY, 10}
		if entity.SubType == 1 then
			checkFor = {EntityType.ENTITY_LITTLE_HORN, 1}
		end

		-- Fade in if the entities are gone
		if Isaac.CountEntities(entity, checkFor[1], checkFor[2], -1) <= 0 then
			entity.State = NpcState.STATE_STOMP
			entity.I1 = 0
			entity.StateFrame = 0
			sprite.Color = Color(1,1,1, 1)
		end

	elseif entity.State == NpcState.STATE_STOMP then
		entity.Velocity = mod:StopLerp(entity.Velocity)
		mod:LoopingAnim(sprite, "FadeIn")

		if sprite:GetFrame() == 10 then
			entity.State = NpcState.STATE_IDLE
			entity.ProjectileCooldown = Settings.Cooldown
		end
	end


	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.forsakenUpdate, EntityType.ENTITY_FORSAKEN)

function mod:forsakenDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target:ToNPC().I1 == 1 then
		target:ToNPC().StateFrame = Settings.TransparencyTimer
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.forsakenDMG, EntityType.ENTITY_FORSAKEN)

function mod:forsakenCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_BONY or (target.Type == EntityType.ENTITY_BIG_BONY and target.Variant == 10)
	or target.Type == EntityType.ENTITY_SPIDER or (target.Type == EntityType.ENTITY_LITTLE_HORN and target.Variant == 1)  then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.forsakenCollide, EntityType.ENTITY_FORSAKEN)