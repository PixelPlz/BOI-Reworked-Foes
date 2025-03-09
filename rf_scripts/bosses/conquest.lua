local mod = ReworkedFoes

local Settings = {
	Cooldown = {30, 90},

	-- Horse
	WallDistance = 10,
	AlignSpeed = 16,
	HorseCooldown = {30, 60},

	ChargeSpeedSlow = 14.4,
	ChargeSpeedFast = 18,
	TurnAroundMargin = 200,

	-- Champion
	CloneCount = 5,
	MaxGlobins = 3,
	MinGlobinDistance = 100,
}



function mod:ConquestInit(entity)
	--[[ Red Conquest clones ]]--
	if entity.Variant == 1 and entity.SpawnerEntity and mod:IsRFChampion(entity.SpawnerEntity, "Conquest") then
		-- Only 5 of them can spawn
		if Isaac.CountEntities(entity.SpawnerEntity, EntityType.ENTITY_WAR, 1, -1) >= Settings.CloneCount then
			entity:Remove()
		-- Appear horizontally to the target
		else
			local target = entity.SpawnerEntity:ToNPC():GetPlayerTarget()
			entity.Position = Vector(entity.Position.X, target.Position.Y)
		end



	--[[ Horse ]]--
	elseif entity.Variant == 20 then
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y

		entity.State = NpcState.STATE_ATTACK
		entity.ProjectileCooldown = mod:Random(Settings.HorseCooldown[1], Settings.HorseCooldown[2])

		-- Load the proper champion data
		if mod:IsRFChampion(entity.SpawnerEntity, "Conquest") then
			entity:GetSprite():ReplaceSpritesheet(0, "gfx/bosses/classic/boss_066_conquest_bloody.png", true)
			entity.Scale = 1.15
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ConquestInit, EntityType.ENTITY_WAR)

function mod:ConquestUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	if entity.Variant == 1 then
		--[[ 1st phase ]]--
		if not data.Phase2 then
			--[[ Champion ]]--
			if mod:IsRFChampion(entity, "Conquest") then
				-- Replace the default projectile attack
				if entity.State == NpcState.STATE_ATTACK then
					entity.State = NpcState.STATE_ATTACK3

				-- Custom projectile attack
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:GetFrame() == 8 then
						local params = ProjectileParams()
						params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(30)
						entity:FireProjectiles(entity.Position, Vector(12, 6), 9, params)
						mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end
				end
			end



			--[[ Go to the 2nd phase when below half health ]]--
			-- Transitioning
			if entity.State == NpcState.STATE_SPECIAL then
				if sprite:IsFinished() then
					data.Phase2 = true
					sprite:Load("gfx/065.011_conquest without horse.anm2", true)
					entity:SetSize(20, Vector.One, 12)

					entity.State = NpcState.STATE_APPEAR_CUSTOM
					sprite:Play("Appear", true)
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)

					-- Load the proper champion spritesheets
					if mod:IsRFChampion(entity, "Conquest") then
						for i = 0, sprite:GetLayerCount() do
							sprite:ReplaceSpritesheet(i, "gfx/bosses/classic/boss_066_conquest_bloody.png")
						end
						sprite:LoadGraphics()
					end

					-- Horse
					local horse = Isaac.Spawn(EntityType.ENTITY_WAR, 20, entity.SubType, entity.Position, Vector.Zero, entity)
					horse:GetSprite().FlipX = sprite.FlipX
				end


			-- Don't transition when off-screen
			elseif entity.HitPoints <= entity.MaxHitPoints / 2
			and entity.State ~= NpcState.STATE_JUMP and room:IsPositionInRoom(entity.Position, entity.Size)
			and not entity.SpawnerEntity and not entity:GetData().wasDelirium then
				entity.State = NpcState.STATE_SPECIAL
				sprite:Play("GetOff", true)
			end





		--[[ 2nd phase ]]--
		else
			--[[ Appear ]]--
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
					mod:PlaySound(nil, SoundEffect.SOUND_MEAT_IMPACTS)
				end
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
				end



			--[[ Chasing ]]--
			elseif entity.State == NpcState.STATE_MOVE then
				local speed = mod:IsRFChampion(entity, "Conquest") and 4 or 5
				mod:ChasePlayer(entity, speed)

				-- Animation
				mod:LoopingAnim(sprite, "WalkHori")
				sprite.PlaybackSpeed = entity.Velocity:Length() / 5.2

				if entity.Velocity:Length() <= 0.1 then
					sprite:SetFrame(0)
				else
					mod:FlipTowardsMovement(entity, sprite)
				end

				-- Attack
				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Cry", true)
					entity.ProjectileCooldown = mod:Random(Settings.Cooldown[1], Settings.Cooldown[2])
					sprite.PlaybackSpeed = 1
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end



			--[[ Attack ]]--
			elseif entity.State == NpcState.STATE_ATTACK then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()

					-- Champion
					if mod:IsRFChampion(entity, "Conquest") then
						params.CircleAngle = mod:Random(1) * mod:DegreesToRadians(22.5)
						entity:FireProjectiles(entity.Position, Vector(12, 8), 9, params)

					-- Regular
					else
						params.Scale = 1.5
						params.BulletFlags = ProjectileFlags.SMART
						params.FallingSpeedModifier = 5
						params.HeightModifier = -30
						params.CircleAngle = 0
						entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)
					end

					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4, 0.9)
				end

				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end
			end

			if entity.FrameCount > 1 then
				return true
			end
		end





	--[[ Horse ]]--
	elseif entity.Variant == 20 then
		--[[ Chilling ]]--
		if entity.State == NpcState.STATE_MOVE then
			-- Get the position to stay at
			local xPos = sprite.FlipX and room:GetBottomRightPos().X or room:GetTopLeftPos().X
			xPos = xPos + -mod:GetSign(sprite.FlipX) * Settings.WallDistance
			entity.TargetPosition = Vector(xPos, target.Position.Y)

			local distance = entity.Position:Distance(entity.TargetPosition)
			local speed = math.min(distance / 8, Settings.AlignSpeed)
			entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(speed), 0.25)

			mod:LoopingAnim(sprite, "Idle")

			-- Start the charge
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_JUMP
				sprite:Play("DashStart", true)
				entity.ProjectileCooldown = mod:Random(Settings.HorseCooldown[1], Settings.HorseCooldown[2])
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end



		--[[ Start the charge ]]--
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Dash") then
				entity.State = NpcState.STATE_ATTACK
				entity.I1 = 0
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A)

				local chargeSign = -mod:GetSign(sprite.FlipX)
				local speed = mod:IsHardMode() and Settings.ChargeSpeedFast or Settings.ChargeSpeedSlow
				entity.Velocity = Vector(chargeSign * speed, 0)
			end


		--[[ Charging ]]--
		elseif entity.State == NpcState.STATE_ATTACK then
			local chargeSign = -mod:GetSign(sprite.FlipX)
			local speed = mod:IsHardMode() and Settings.ChargeSpeedFast or Settings.ChargeSpeedSlow
			local newY = mod:Lerp(entity.Velocity.Y, 0, 0.5)
			entity.Velocity = Vector(chargeSign * speed, newY)

			if not sprite:IsPlaying("DashStart") then
				mod:LoopingAnim(sprite, "Dash")
			end

			-- Turn around when fully off-screen
			if not room:IsPositionInRoom(entity.Position, -Settings.TurnAroundMargin) then
				entity.State = NpcState.STATE_MOVE
				sprite.FlipX = not sprite.FlipX

				entity.Position = Vector(entity.Position.X, target.Position.Y)
				entity.Velocity = Vector.Zero
			end


			-- Red champion bullets
			if mod:IsRFChampion(entity, "Conquest") and room:IsPositionInRoom(entity.Position, 0) then
				if entity.I1 <= 0 then
					local params = ProjectileParams()
					params.Scale = 1.5
					params.HeightModifier = 5
					mod:FireProjectiles(entity, entity.Position, Vector.Zero, 0, params):GetData().RFLingering = 60
					entity.I1 = 2
				else
					entity.I1 = entity.I1 - 1
				end
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ConquestUpdate, EntityType.ENTITY_WAR)

function mod:ConquestCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_WAR or target.Type == EntityType.ENTITY_GLOBIN then
		-- Damage Globins they charge into
		if ((entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK2) -- Conquest
		or (entity.Variant == 20 and entity.State == NpcState.STATE_ATTACK)) -- Horse
		and target.Type == EntityType.ENTITY_GLOBIN and target:ToNPC().State ~= NpcState.STATE_IDLE then
			target:TakeDamage(40, 0, EntityRef(entity), 30)
		end

		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.ConquestCollision, EntityType.ENTITY_WAR)



-- Red champion globins
function mod:ConquestLightBeamReplace(effect)
	if effect.SpawnerType == EntityType.ENTITY_WAR and effect.SpawnerEntity and mod:IsRFChampion(effect.SpawnerEntity, "Conquest") then
		local nearestPlayer = Game():GetNearestPlayer(effect.Position)

		if Isaac.CountEntities(nil, EntityType.ENTITY_GLOBIN, -1, -1) < Settings.MaxGlobins -- Less than the max amount
		and effect.Position:Distance(nearestPlayer.Position) >= Settings.MinGlobinDistance then -- Far enough away from any players
			Isaac.Spawn(EntityType.ENTITY_GLOBIN, 0, 0, effect.Position, Vector.Zero, effect.SpawnerEntity)
			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND, 0.75)
		end

		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ConquestLightBeamReplace, EffectVariant.CRACK_THE_SKY)