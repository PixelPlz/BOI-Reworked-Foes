local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 4.5,
	RunSpeed = 7.5,
	JumpSpeed = 13,
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



function mod:gishReplace(entity)
	if entity.Variant == 1 then
		entity:Remove()
		Isaac.Spawn(200, 4043, entity.SubType, entity.Position, Vector.Zero, entity.SpawnerEntity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.gishReplace, EntityType.ENTITY_MONSTRO2)

function mod:gishUpdate(entity)
	if entity.Variant == 4043 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()
		
		
		-- Function for facing towards target
		local function spriteFlipX()
			if target.Position.X > entity.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end
		end


		if not data.state then
			data.state = States.Appear

		elseif data.state == States.Appear then
			data.state = States.Moving
			entity.Velocity = Vector.Zero
			entity.ProjectileCooldown = Settings.MoveTime
			entity.SplatColor = tarBulletColor


		elseif data.state == States.Moving or data.state == States.Running then
			local speed = Settings.MoveSpeed
			local anim = "Walk"
			if data.state == States.Running then
				speed = Settings.RunSpeed
				anim = "Run"
			end
			if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
				speed = -speed
			end

			-- Movement
			if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
				entity.Pathfinder:MoveRandomly(false)
			else
				if entity.Pathfinder:HasPathToPos(target.Position) then
					if game:GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false) then
						entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * speed - entity.Velocity) * 0.25)
					else
						entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
					end
				
				else
					--entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
					data.state = States.BigJump
				end
			end
			-- Creep
			if entity:IsFrame(4, 0) then
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.75
			end

			-- Animation
			if not sprite:IsPlaying(anim) then
				sprite:Play(anim, true)
			end
			spriteFlipX()

			-- Decide attack
			if entity.ProjectileCooldown <= 0 then
				if data.state == States.Moving then
					if math.random(0, 1) == 1 then
						data.state = States.BigJump
					else
						data.state = States.Running
						entity.ProjectileCooldown = Settings.RunTime
						entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_1, 0.8, 0, false, 1)
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
				SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS, 1.25)
				entity:PlaySound(SoundEffect.SOUND_BOSS_LITE_ROAR, 0.8, 0, false, 1)

			elseif sprite:IsEventTriggered("Land") then
				entity.I2 = 0
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):ToEffect()
				effect:GetSprite().Color = tarBulletColor
				effect.DepthOffset = entity.DepthOffset + 10
				if data.state == States.Land then
					effect.Scale = 1.5
				end

				-- Creep
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.6
				for i = 0, 8 do
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_BLACK, 0, entity.Position + (Vector.FromAngle(i * 45) * 40), Vector.Zero, entity):ToEffect().Scale = 1.6
				end
			
			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Color = tarBulletColor
				params.Scale = 1.5
				entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 0), 8, params)
				
				if data.state == States.Land then
					params.CircleAngle = 90
					params.Scale = 1.75
					entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed - 5, 8), 9, params)
				end
			end


			-- Regular jump
			if data.state == States.Jump then
				if entity.I2 == 1 then
					entity.Velocity = (entity.Velocity + (entity.V1 * Settings.JumpSpeed - entity.Velocity) * 0.25)
				else
					entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
				end
				if not sprite:IsPlaying("Attack") then
					sprite:Play("Attack", true)
				end

				if sprite:IsEventTriggered("Jump") then
					entity.V1 = (target.Position - entity.Position):Normalized()
				elseif sprite:IsEventTriggered("Land") then
					SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 0.6)
				end

				if sprite:GetFrame() == 43 then
					entity.I1 = entity.I1 + 1
					-- Do 3 jumps
					if entity.I1 >= Settings.JumpCount then
						entity.I1 = 0
						data.state = States.Moving
						entity.ProjectileCooldown = Settings.MoveTime
					end
				end


			-- Big jump
			elseif data.state == States.BigJump then
				entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
				if not sprite:IsPlaying("JumpUp") then
					sprite:Play("JumpUp", true)
				end

				if sprite:GetFrame() == 14 then
					data.state = States.Land
				end

			-- Land
			elseif data.state == States.Land then
				if entity.I2 == 1 and sprite:GetFrame() < 24 then
					entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * Settings.AirSpeed - entity.Velocity) * 0.25)
				else
					local multiplier = 0.25
					if entity.I2 == 1 then
						multiplier = 0.1
					end
					entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * multiplier)
				end
				if not sprite:IsPlaying("JumpDown") then
					sprite:Play("JumpDown", true)
				end

				if sprite:IsEventTriggered("Land") then
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position + Vector(12, -32), Vector.Zero, entity):GetSprite().Color = tarBulletColor
					SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.2)
				end

				if sprite:GetFrame() == 61 then
					entity.I1 = entity.I1 + 1
					-- Do 2 jumps
					if entity.I1 >= Settings.BigJumpCount then
						entity.I1 = 0
						-- Spawn clots if there are less than the max amount
						if Isaac.CountEntities(entity, EntityType.ENTITY_CLOTTY, 1, -1) < Settings.MaxClots then
							data.state = States.Attacking
						else
							data.state = States.Moving
							entity.ProjectileCooldown = Settings.MoveTime
						end

					else
						data.state = States.BigJump
					end
				end
			end


		-- Spit attack
		elseif data.state == States.Attacking then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
			if not sprite:IsPlaying("Taunt") then
				sprite:Play("Taunt", true)
			end
			spriteFlipX()

			if sprite:IsEventTriggered("Shoot") then
				Isaac.Spawn(EntityType.ENTITY_CLOTTY, 1, 0, entity.Position, (target.Position - entity.Position):Normalized() * 10, entity):ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				entity:PlaySound(SoundEffect.SOUND_BOSS_SPIT_BLOB_BARF, 0.8, 0, false, 1)

				local params = ProjectileParams()
				params.Color = tarBulletColor
				params.Scale = 1.35
				entity:FireBossProjectiles(8, target.Position, 2.5, params)
			end
			if sprite:GetFrame() == 51 then
				data.state = States.Moving
				entity.ProjectileCooldown = Settings.MoveTime
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gishUpdate, 200)

function mod:gishCollide(entity, target, bool)
	if entity.Variant == 4043 and target.Type == EntityType.ENTITY_CLOTTY and target.Variant == 1 then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.gishCollide, 200)