local mod = BetterMonsters



-- Changed from main form
local function Init(entity)
	local sprite = entity:GetSprite()
	sprite:Load("gfx/" .. "908.000_baby plum" .. ".anm2", true)
	sprite:Play("Appear", true)

	entity:SetSize(20, Vector(1, 1), 12)
	entity:GetData().shadowSize = 30

	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

	entity.V1 = Vector(3, 0)
end


-- Update
local function Update(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	-- Transform animation
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		entity.Velocity = Vector.Zero

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_ATTACK
			sprite:Play("Attack3", true)
		end


    -- Bounce around
    elseif entity.State == NpcState.STATE_ATTACK then
		-- Start
        if entity.StateFrame == 0 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				entity.StateFrame = 1
				entity.Velocity = Vector.FromAngle(135):Resized(3)
			end


		-- Bouncing
		elseif entity.StateFrame == 1 then
			entity.V1 = Vector(math.min(20, entity.V1.X + 0.1), 0)
			mod:MoveDiagonally(entity, entity.V1.X)


			-- Animation
			local prefix = ""
			local effectOffsetY = -36

			if entity.Velocity.Y > 0 then
				prefix = "Back"
				effectOffsetY = -22
			end

			if not sprite:IsPlaying("Attack3") then
				mod:LoopingAnim(sprite, "Attack3" .. prefix .. "Loop")
			end
			mod:FlipTowardsMovement(entity, sprite, otherWay)


			-- Projectiles
			if entity:IsFrame(4, 0) then
				local params = ProjectileParams()
				params.BulletFlags = ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT
				params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY
				params.ChangeTimeout = 90

				params.Color = IRFcolors.Delirium
				params.Scale = 1.5
				params.FallingAccelModifier = -0.2

				local vector = -entity.Velocity:Normalized():Rotated(mod:Random(-30, 30))
				entity:FireProjectiles(entity.Position, vector:Resized(2.5), 0, params)

				mod:ShootEffect(entity, 2, Vector(0, effectOffsetY) + vector:Resized(20), IRFcolors.Delirium, 0.5, entity.Velocity.Y > 0)
				mod:PlaySound(nil, SoundEffect.SOUND_BOSS2_BUBBLES, 0.75, 1.1)
			end

			-- When bouncing off of walls
			if entity:CollidesWithGrid() then
				local params = ProjectileParams()
				params.Color = IRFcolors.Delirium
				params.Scale = 1.5
				params.FallingAccelModifier = -0.08

				entity:FireProjectiles(entity.Position, Vector(entity.V1.X * 0.5, 12), 9, params)
				mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.V1.X * 0.05)
				Game():ShakeScreen(math.floor(entity.V1.X * 0.5))
			end


			-- Timer
			if entity.I1 >= 400 then
				entity.StateFrame = 2
				sprite:Play("Attack3End", true)
				sprite.FlipX = false
			else
				entity.I1 = entity.I1 + 1
			end


		-- Stop
		elseif entity.StateFrame == 2 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_SPECIAL
				sprite:Play("Leave", true)
			end
		end


	-- Change back to main form
	elseif entity.State == NpcState.STATE_SPECIAL then
		entity.Velocity = Vector.Zero

		if sprite:IsFinished() then
			data.transformBack()
		end
	end
end



-- Callbacks (unnecessary ones can be removed)
local function Callbacks(entity, callback, input)
	if callback == "init" then
		Init(entity)

	elseif callback == "update" then
		Update(entity)
	end
end

-- Add boss to transformation list (for which Delirium phase, required boss ID, required boss variant, script to use)
mod:AddDeliriumForm(1, EntityType.ENTITY_BABY_PLUM, 0, Callbacks)