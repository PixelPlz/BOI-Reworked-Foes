local mod = ReworkedFoes



--[[ Tumor ]]--
function mod:TumorUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()

	if sprite:IsPlaying("ShootDown") or sprite:IsPlaying("ShootUp") then
		-- Prevent them from shooting if they're on cooldown
		if entity.ProjectileCooldown > 0 and not sprite:WasEventTriggered("Shoot") then
			sprite:Play(data.previousAnim[1], true)
			sprite:SetFrame(data.previousAnim[2])

		-- Give them the cooldown
		elseif sprite:IsEventTriggered("Shoot") then
			entity.ProjectileCooldown = 15
		end

	else
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		data.previousAnim = {sprite:GetAnimation(), sprite:GetFrame()}
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TumorUpdate, EntityType.ENTITY_TUMOR)



--[[ Camillo Jr. ]]--
function mod:CamilloJrInit(entity)
	entity.ProjectileCooldown = mod:Random(120, 180)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CamilloJrInit, EntityType.ENTITY_CAMILLO_JR)

-- It's easier to remake these fuckers from scratch then to try to fix them...
function mod:CamilloJrUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()

	-- Move diagonally
	mod:MoveDiagonally(entity, 1.5, 0.3)


	-- Idle
	if entity.State == NpcState.STATE_MOVE then
		local moveSuffix = "Down"
		if entity.Velocity.Y < 0 then
			moveSuffix = "Up"
		end
		mod:LoopingAnim(sprite, "Float" .. moveSuffix)
		mod:FlipTowardsMovement(entity, sprite)


		-- Cooldown
		if entity.ProjectileDelay > 0 then
			entity.ProjectileDelay = entity.ProjectileDelay - 1
		end

		-- Attack if damaged or not damaged for long enough
		if entity.ProjectileCooldown <= 0 and (entity.I1 == 1 or entity.Position:Distance(target.Position) <= 240) then
			entity.State = NpcState.STATE_ATTACK

			local shootSuffix = "Down"
			if target.Position.Y < entity.Position.Y then
				shootSuffix = "Up"
			end
			sprite:Play("Shoot" .. shootSuffix, true)

		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end


	-- Shoot
	elseif entity.State == NpcState.STATE_ATTACK then
		-- Face the target before shooting
		if not sprite:WasEventTriggered("Shoot") then
			mod:FlipTowardsTarget(entity, sprite)
		end

		-- Get laser angle
		if sprite:IsEventTriggered("GetPos") then
			local angle = (target.Position - entity.Position):GetAngleDegrees()
			entity.TargetPosition = Vector(angle, 0)
			mod:QuickTracer(entity, angle, Vector(0, -30), 8)
			mod:PlaySound(nil, SoundEffect.SOUND_LASERRING_WEAK, 0.9, 1.1)

		-- Shoot
		elseif sprite:IsEventTriggered("Shoot") then
			local laser = EntityLaser.ShootAngle(LaserVariant.THIN_RED, entity.Position, entity.TargetPosition.X, 3, Vector(0, entity.SpriteScale.Y * -35), entity)
			laser.Mass = 0
			laser.OneHit = true

			if sprite:IsPlaying("ShootUp") then
				laser.DepthOffset = entity.DepthOffset - 10
			else
				laser.DepthOffset = entity.DepthOffset + 10
			end
		end

		if sprite:IsFinished() then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = mod:Random(120, 180)
			entity.ProjectileDelay = 15
			entity.I1 = 0
		end
	end

	if entity.FrameCount > 1 then
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.CamilloJrUpdate, EntityType.ENTITY_CAMILLO_JR)

function mod:CamilloJrDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	local entity = entity:ToNPC()

	if entity.State == NpcState.STATE_MOVE and entity.ProjectileDelay <= 0 then
		entity.ProjectileCooldown = 0
		entity.I1 = 1
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.CamilloJrDMG, EntityType.ENTITY_CAMILLO_JR)



--[[ Psy Tumor ]]--
function mod:PsyTumorUpdate(entity)
	local sprite = entity:GetSprite()
	local data = entity:GetData()

	if sprite:IsPlaying("ShootDown") or sprite:IsPlaying("ShootUp") then
		-- Prevent them from shooting if they're on cooldown
		if entity.ProjectileCooldown > 0 and not sprite:WasEventTriggered("NewShoot") then
			sprite:Play(data.previousAnim[1], true)
			sprite:SetFrame(data.previousAnim[2])

		-- Less projectiles + give them the cooldown
		elseif sprite:IsEventTriggered("NewShoot") then
			entity.ProjectileCooldown = 15
			mod:PlaySound(entity, SoundEffect.SOUND_WHEEZY_COUGH, 1.1)

			local params = ProjectileParams()
			params.BulletFlags = ProjectileFlags.SMART
			entity:FireProjectiles(entity.Position, Vector(9, 3), 9, params)
		end

	else
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		data.previousAnim = {sprite:GetAnimation(), sprite:GetFrame()}
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PsyTumorUpdate, EntityType.ENTITY_PSY_TUMOR)