local mod = BetterMonsters

local Settings = {
	MoveSpeed = 5,
	RunSpeed = 7,
	JumpSpeed = 12,
	AirSpeed = 10,

	MoveTime = 90,
	RunTime = 45,
	
	ShotSpeed = 11,
	JumpCount = 3,
	BigJumpCount = 2,
	MaxClots = 3
}

local States = {
	Appear = 0,
	Moving = 1,

	Running = 2,
	Jump = 3,

	BigJump = 4,
	Land = 5,
	Attacking = 6
}



function mod:gishInit(entity)
	if entity.Variant == 1 then
		entity:GetData().state = States.Appear
		entity.ProjectileCooldown = (Settings.MoveTime / 3) * 2
		
		-- Hera's Whippers (kinky)
		if entity.SubType == 1 then
			for i = -1, 1, 2 do
				Isaac.Spawn(EntityType.ENTITY_WHIPPER, 0, 43, entity.Position + Vector(i * 50, 0), Vector.Zero, entity)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gishInit, EntityType.ENTITY_MONSTRO2)

function mod:gishUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()

		local creepType = EffectVariant.CREEP_BLACK
		if entity.SubType == 1 then
			creepType = EffectVariant.CREEP_WHITE
			sprite.PlaybackSpeed = 1.1
			entity.SplatColor = skyBulletColor
		end


		-- Function for facing towards target
		local function spriteFlipX()
			if target.Position.X > entity.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end
		end


		if not data.state or data.state == States.Appear then
			data.state = States.Moving

		elseif data.state == States.Moving or data.state == States.Running then
			local speed = Settings.MoveSpeed
			local anim = "Walk"

			if data.state == States.Running then
				speed = Settings.RunSpeed
				anim = "Run"
				
				-- Creep
				if entity:IsFrame(4, 0) then
					mod:QuickCreep(creepType, entity, entity.Position, 1.75)
				end
			end
			if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
				speed = -speed
			end

			-- Movement
			if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
				entity.Pathfinder:MoveRandomly(false)
			else
				if entity.Pathfinder:HasPathToPos(target.Position) then
					if Game():GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false) then
						entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * speed, 0.25)
					else
						entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
					end
				else
					data.state = States.BigJump
				end
			end

			mod:LoopingAnim(sprite, anim)
			spriteFlipX()

			-- Decide attack
			if entity.ProjectileCooldown <= 0 then
				if data.state == States.Moving then
					local decide = math.random(0, 2)
					entity.I1 = 0

					if decide == 0 and not data.wasDelirium then
						data.state = States.Running
						entity.ProjectileCooldown = Settings.RunTime
						entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_1, 0.8, 0, false, 1)

					-- Only spawn clots if there are less than the max amount
					elseif decide == 1 and (Isaac.CountEntities(entity, EntityType.ENTITY_CLOTTY, 1, -1) < Settings.MaxClots or entity.SubType == 1) then
						data.state = States.Attacking

					else
						data.state = States.BigJump
					end
				
				elseif data.state == States.Running then
					data.state = States.Jump
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Main attacks
		elseif data.state == States.Jump or data.state == States.BigJump or data.state == States.Land then
			if sprite:IsEventTriggered("Jump") then
				entity.I2 = 1
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

				spriteFlipX()
				SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS)
				entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8, 0, false, 1)

			elseif sprite:IsEventTriggered("Land") then
				entity.I2 = 0
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
				mod:QuickCreep(creepType, entity, entity.Position, 5 - entity.SubType)

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):ToEffect()
				effect:GetSprite().Color = entity.SplatColor
				effect.DepthOffset = entity.DepthOffset + 10
				if data.state == States.Land then
					effect.Scale = 1.5
					Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
				end

			
			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				
				if entity.SubType == 0 then
					params.Color = tarBulletColor
					params.Scale = 1.5
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 8, params)
					
					if data.state == States.Land then
						params.CircleAngle = 0.41
						params.Scale = 1.75
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 5, 8), 9, params)
					end
				
				elseif entity.SubType == 1 and data.state == States.Land then
					params.Color = skyBulletColor
					params.FallingAccelModifier = 0.05

					for i = 0, 2 do
						params.Scale = 2
						if i > 0 then
							params.Scale = 1.25
						end
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - (i * 2), 4), 6, params)
					end

					for i = 0, 2 do
						params.Scale = 1.75
						if i > 0 then
							params.Scale = 1
						end
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 3 - (i * 2), 4), 7, params)
					end
				end
			end


			-- Regular jump
			if data.state == States.Jump then
				if entity.I2 == 1 then
					entity.Velocity = mod:Lerp(entity.Velocity, entity.V1 * Settings.JumpSpeed, 0.25)
				else
					entity.Velocity = mod:StopLerp(entity.Velocity)
				end
				mod:LoopingAnim(sprite, "Attack")

				if sprite:IsEventTriggered("Jump") then
					entity.V1 = (target.Position - entity.Position):Normalized()
				elseif sprite:IsEventTriggered("Land") then
					SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.6)

					if entity.SubType == 1 then
						if entity.I1 + 1 < Settings.JumpCount then
							sprite:SetFrame(42)
						end

						local params = ProjectileParams()
						params.Color = skyBulletColor
						params.Scale = 1.5
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 6 + entity.I1, params)
					end
				end

				if sprite:GetFrame() == 43 then
					entity.I1 = entity.I1 + 1
					-- Do 3 jumps
					if entity.I1 >= Settings.JumpCount then
						data.state = States.Moving
						entity.ProjectileCooldown = Settings.MoveTime
					end
				end


			-- Big jump
			elseif data.state == States.BigJump then
				entity.Velocity = mod:StopLerp(entity.Velocity)
				mod:LoopingAnim(sprite, "JumpUp")

				if sprite:GetFrame() == 14 then
					data.state = States.Land
				end

			-- Land
			elseif data.state == States.Land then
				if entity.I2 == 1 and sprite:GetFrame() < 24 then
					entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * Settings.AirSpeed, 0.25)
				else
					local multiplier = 0.25
					if entity.I2 == 1 then
						multiplier = 0.1
					end
					entity.Velocity = mod:Lerp(entity.Velocity, Vector.Zero, multiplier)
				end
				mod:LoopingAnim(sprite, "JumpDown")

				if sprite:IsEventTriggered("Land") then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position + Vector(12, -32), Vector.Zero, entity):GetSprite().Color = entity.SplatColor
					SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.2)
				end

				if sprite:GetFrame() == 61 then
					entity.I1 = entity.I1 + 1
					-- Do 2 jumps
					if entity.I1 >= Settings.BigJumpCount then
						data.state = States.Moving
						entity.ProjectileCooldown = Settings.MoveTime
					else
						data.state = States.BigJump
					end
				end
			end


		-- Spit attack
		elseif data.state == States.Attacking then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Taunt")
			spriteFlipX()

			if sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8, 0, false, 1)

				local params = ProjectileParams()
				if entity.SubType == 0 then
					Isaac.Spawn(EntityType.ENTITY_CLOTTY, 1, 0, entity.Position, (target.Position - entity.Position):Normalized() * 10, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)

					params.Color = tarBulletColor
					params.Scale = 1.5
					entity:FireBossProjectiles(10, target.Position, 3, params)
				
				elseif entity.SubType == 1 then
					params.BulletFlags = (ProjectileFlags.DECELERATE | ProjectileFlags.BURST8)
					params.Scale = 2.25
					params.Acceleration = 1.075
					params.FallingAccelModifier = -0.175
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * (Settings.ShotSpeed + 2), 0, params)
					mod:shootEffect(entity, 3, Vector(0, -16), entity.SplatColor)
				end
			end

			if sprite:GetFrame() == 51 then
				data.state = States.Moving
				entity.ProjectileCooldown = Settings.MoveTime
			end
		end
		
		
		if entity.FrameCount > 1 then
			return true

		-- Remove Clots for Hera's boss rooms
		elseif entity.SubType == 1 then
			for i, stuff in pairs(Isaac.FindByType(EntityType.ENTITY_CLOTTY, -1, -1, false, false)) do
				stuff:Remove()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.gishUpdate, EntityType.ENTITY_MONSTRO2)

function mod:gishCollide(entity, target, bool)
	if entity.Variant == 1 and target.Type == EntityType.ENTITY_CLOTTY and target.Variant == 1 then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.gishCollide, EntityType.ENTITY_MONSTRO2)