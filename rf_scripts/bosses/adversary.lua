local mod = ReworkedFoes

local Settings = {
	HomingStrength = 4,
	MinDistance = 100,
}



function mod:AdversaryUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()
	local target = entity:GetPlayerTarget()


	--[[ Jump attack ]]--
	if entity.State == NpcState.STATE_JUMP then
		-- Fix him having removing his hitbox too early before jumping
		if sprite:IsPlaying("FlyUp") then
			if sprite:WasEventTriggered("Fly") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			else
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end

		else
			-- Stop him from sliding around after landing
			if sprite:IsEventTriggered("Land") then
				entity.Velocity = Vector.Zero
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

				-- Extra effects
				mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, 0.9)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity)
				effect:GetSprite().Color = mod.Colors.DustPoof
			end

			-- Disable ground collision again
			if sprite:GetFrame() >= 26 then
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			end
		end



	--[[ Extra summon effects ]]--
	elseif entity.State == NpcState.STATE_SUMMON and sprite:IsEventTriggered("Skin Pull") then
		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 5, entity.Position, Vector.Zero, entity):ToEffect()
		effect:FollowParent(entity)
		effect.DepthOffset = entity.DepthOffset + 10

		local effectSprite = effect:GetSprite()
		effectSprite.Offset = Vector(0, -20)
		effectSprite.Color = Color(0,0,0, 0.4, 0.4,0.38,0.34)
		effectSprite.Scale = Vector.One * 0.666



	--[[ Laser attack ]]--
	elseif entity.State == NpcState.STATE_ATTACK then
		local canLaser = true

		for i, entry in pairs(Isaac.FindByType(entity.Type, entity.Variant)) do
			if entry.Index ~= entity.Index and entry:ToNPC().State == NpcState.STATE_ATTACK2 then
				canLaser = false
				break
			end
		end

		-- Replace it with the new version
		if canLaser then
			entity.State = NpcState.STATE_ATTACK2
			local vector = target.Position - entity.Position
			entity.TargetPosition = mod:ClampVector(vector, 90)

			data.laserDirection = mod:GetDirectionString(entity.TargetPosition:GetAngleDegrees())
			sprite:Play("Attack2" .. data.laserDirection, true)

		-- Only let him peform it if there aren't any other Adversaries doing it
		else
			entity.State = NpcState.STATE_MOVE
			SFXManager():Stop(SoundEffect.SOUND_MONSTER_ROAR_3)
		end


	-- Custom laser attack
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if sprite:IsEventTriggered("Shoot") then
			local xOffset = 0
			local yOffset = -25
			local depthOffset = 0

			-- Get the position and depth offsets
			if data.laserDirection == "Down" then
				yOffset = -20
				depthOffset = entity.DepthOffset + 20
			elseif data.laserDirection ~= "Up" then
				xOffset = mod:GetSign(entity.TargetPosition.X > 0) * 25
			end

			local angle = entity.TargetPosition:GetAngleDegrees()
			local laser = EntityLaser.ShootAngle(LaserVariant.THICK_RED, entity.Position, angle, 14, Vector(0, -25), entity)
			laser.ParentOffset = Vector(xOffset, yOffset)
			laser.DepthOffset = depthOffset

			-- Set up the homing
			laser:AddTearFlags(TearFlags.TEAR_OCCULT)
			data.homingLaser = laser

			-- Set the initial target position
			local distance = math.max(Settings.MinDistance, target.Position:Distance(entity.Position) / 2)
			local pos = laser.Position + laser.ParentOffset + Vector.FromAngle(angle):Resized(distance)
			laser.TargetPosition = Game():GetRoom():GetClampedPosition(pos, 0)
		end


		-- Move the target position towards the target
		if data.homingLaser and data.homingLaser.Timeout >= 0 then
			local laser = data.homingLaser

			local strength = math.min(Settings.HomingStrength, laser.Timeout)
			local vector = (target.Position - laser.TargetPosition):Resized(strength)
			laser.TargetPosition = laser.TargetPosition + vector

			-- Make sure the target position is at least 100 units away
			vector = laser.TargetPosition - laser.Position
			local distance = math.max(Settings.MinDistance, vector:Length())
			laser.TargetPosition = laser.Position + vector:Resized(distance)
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
			data.homingLaser = nil
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.AdversaryUpdate, EntityType.ENTITY_ADVERSARY)