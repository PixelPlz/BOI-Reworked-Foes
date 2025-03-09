local mod = ReworkedFoes

local Settings = {
	NewHealth = 360,
	Cooldown = {30, 90},
	WanderSpeed = 2.5,

	ChargeSpeedSlow = 12,
	ChargeSpeedFast = 16,
	WrapAroundMargin = 200,
}



function mod:PestilenceInit(entity)
	mod:ChangeMaxHealth(entity, Settings.NewHealth)
	entity.SplatColor = mod.Colors.GreenBlood

	-- Stupid grid collision size fix
	-- (It doesn't do grid collision point changes if the size doesn't change...)
	local oldSize = entity.Size
	entity:SetSize(entity.Size + 1, entity.SizeMulti, 12)
	entity:SetSize(oldSize, entity.SizeMulti, 12)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PestilenceInit, EntityType.ENTITY_PESTILENCE)

function mod:PestilenceUpdate(entity)
	if entity.I1 >= 1 then
		local sprite = entity:GetSprite()

		-- Cancel all attacks when transitioning from the 1st phase
		if entity:GetData().wasFirstPhase then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
			entity:GetData().wasFirstPhase = nil

			-- Champion spiders
			if entity.SubType == 1 then
				local offset = mod:Random(359)

				for i = 1, 3 do
					local vector = Vector.FromAngle(offset + i * 120)
					local pos = vector:Resized(mod:Random(60, 120))
					EntityNPC.ThrowSpider(entity.Position, entity, entity.Position + pos, false, -10)
				end
			end
		end


		-- Re-implement the creep trail
		local creepInterval = entity.SubType == 1 and 7 or 9

		if entity:IsFrame(creepInterval, 0) then
			local type = entity.SubType == 1 and EffectVariant.CREEP_WHITE or EffectVariant.CREEP_GREEN
			mod:QuickCreep(type, entity, entity.Position, 1.5)
		end



		--[[ Idle ]]--
		if entity.State == NpcState.STATE_MOVE then
			mod:WanderAround(entity, Settings.WanderSpeed)
			mod:LoopingAnim(sprite, "Walk")
			mod:FlipTowardsMovement(entity, sprite)

			if entity.ProjectileCooldown <= 0 then
				entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])

				-- Summon
				if #entity:QueryNPCsSpawnerType(entity.Type, EntityType.ENTITY_NULL, true) < 3 and mod:Random(1) == 1 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("HeadlessAttack2", true)

				-- Charge attack
				else
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("DashStart", true)
					entity.StateFrame = 0
					entity.TargetPosition = entity.Position
					sprite.FlipX = mod:Random(1) == 1
					entity.I2 = 0
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Charge attack ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Start the charge
			if entity.StateFrame == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Sound") then
					mod:PlaySound(nil, SoundEffect.SOUND_CLAP, 0.9, 0.95)
					mod:PlaySound(entity, SoundEffect.SOUND_ANGRY_GURGLE, 1, 0.95)

				elseif sprite:IsEventTriggered("Shoot") then
					entity.StateFrame = 1
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y

					local chargeSign = -mod:GetSign(sprite.FlipX)
					local speed = mod:IsHardMode() and Settings.ChargeSpeedFast or Settings.ChargeSpeedSlow
					entity.Velocity = Vector(chargeSign * speed, 0)
				end


			-- Charging
			elseif entity.StateFrame >= 1 then
				local chargeSign = -mod:GetSign(sprite.FlipX)
				local speed = mod:IsHardMode() and Settings.ChargeSpeedFast or Settings.ChargeSpeedSlow
				local newY = mod:Lerp(entity.Velocity.Y, 0, 0.5)
				entity.Velocity = Vector(chargeSign * speed, newY)

				if not sprite:IsPlaying("DashStart") then
					mod:LoopingAnim(sprite, "Dash")
				end


				-- Projectiles
				if entity.I2 <= 0 then
					local params = ProjectileParams()
					params.Scale = 1 + (mod:Random(40) / 100)
					params.FallingAccelModifier = 1.25
					params.FallingSpeedModifier = -mod:Random(15, 20)
					params.Color = entity.SubType == 1 and mod.Colors.WhiteShot or mod.Colors.Ipecac
					local projectile = mod:FireProjectiles(entity, entity.Position, mod:RandomVector(mod:Random(3, 6)), 0, params)

					-- Set the projectile types
					if entity.SubType == 1 then
						projectile:GetData().RFLeaveCreep = { Type = EffectVariant.CREEP_WHITE, }
						entity.I2 = 2
					else
						projectile:GetData().pestilenceChargeExplosive = true
						entity.I2 = 8
					end

				else
					entity.I2 = entity.I2 - 1
				end

				-- Effects
				if entity:IsFrame(6, 0) then
					mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1, 0.95)

					local color = entity.SubType == 1 and mod.Colors.WhiteShot or mod.Colors.GreenCreep
					mod:ShootEffect(entity, 2, Vector(0, -28), color, 0.75)
				end


				-- Stop charging when he reaches the starting point again
				local room = Game():GetRoom()

				if entity.StateFrame >= 2 then
					local checkPos = Vector(entity.Position.X, 0)
					local targetPos = Vector(entity.TargetPosition.X, 0)

					if checkPos:Distance(targetPos) <= entity.Size then
						entity.State = NpcState.STATE_MOVE
						entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					end

				-- Wrap around and mirror the vertical position
				elseif not room:IsPositionInRoom(entity.Position, -Settings.WrapAroundMargin) then
					local pos = room:ScreenWrapPosition(entity.Position, -Settings.WrapAroundMargin)
					entity.Position = Vector(pos.X, room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - entity.Position.Y))
					entity.StateFrame = 2
				end
			end



		--[[ Summon ]]--
		elseif entity.State == NpcState.STATE_SUMMON then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				local vector = Vector(-mod:GetSign(sprite.FlipX), 0)
				local pos = entity.Position + vector:Resized(40)

				for i = -1, 1, 2 do
					local spawnVector = vector:Rotated(i * mod:Random(10, 45))

					-- Spiders
					if entity.SubType == 1 then
						local targetPos = spawnVector:Resized(mod:Random(60, 120))
						EntityNPC.ThrowSpider(pos, entity, pos + targetPos, false, -10)
					-- Flies
					else
						local velocity = mod:Random(4, 8)
						Isaac.Spawn(EntityType.ENTITY_ATTACKFLY, 0, 0, pos, spawnVector:Resized(velocity), entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					end
				end

				-- Effects
				entity:AddVelocity(-vector:Resized(10))
				mod:ShootEffect(entity, 5, vector:Resized(35), Color(0,0,0, 0.75, 0.2,0.25,0.2))
				mod:PlaySound(entity, SoundEffect.SOUND_WHEEZY_COUGH)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true


	-- 1st phase
	else
		entity:GetData().wasFirstPhase = true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.PestilenceUpdate, EntityType.ENTITY_PESTILENCE)

function mod:PestilenceDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == entity.Type or (damageSource.Entity and damageSource.Entity.SpawnerType == entity.Type) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PestilenceDMG, EntityType.ENTITY_PESTILENCE)

function mod:PestilenceCollision(entity, target, bool)
	if entity.I1 >= 1 and entity.State == NpcState.STATE_ATTACK and target.SpawnerType == entity.Type then
		target:TakeDamage(10, 0, EntityRef(entity), 0)
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.PestilenceCollision, EntityType.ENTITY_PESTILENCE)



-- Remove his passive creep trail in his 1st phase
function mod:PestilenceCreepInit(effect)
	if effect.FrameCount <= 0 and effect.SpawnerType == EntityType.ENTITY_PESTILENCE and effect.SpawnerEntity
	and effect.SpawnerEntity:ToNPC() and effect.SpawnerEntity:ToNPC().I1 <= 0 then
		effect.Visible = false
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.PestilenceCreepInit, EffectVariant.CREEP_GREEN)



-- Small explosive projectiles
function mod:PestilenceSmallExplosiveProjectile(projectile)
	if projectile:GetData().pestilenceChargeExplosive and projectile:IsDead() then
		Game():BombExplosionEffects(projectile.Position, 20, TearFlags.TEAR_NORMAL, projectile.Color, projectile.SpawnerEntity, 0.65, true, true, DamageFlag.DAMAGE_EXPLOSION)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.PestilenceSmallExplosiveProjectile, ProjectileVariant.PROJECTILE_NORMAL)