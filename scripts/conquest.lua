local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 6,
	AttackCount = 3,

	DashSpeed = 26,
	DashCooldown = 30,

	MaxGlobins = 5,
	MinGlobins = 2,
	CloneCount = 5,

	ShotSpeed = 10,
	ShotDelay = 4
}



function mod:conquestUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()

		-- Go to 2nd phase
		if not entity.SpawnerEntity and entity.HitPoints <= entity.MaxHitPoints / 2 and entity.State ~= NpcState.STATE_ATTACK2 and game:GetRoom():GetBossID() ~= 70 then
			-- Conquest without horse
			local conquest = Isaac.Spawn(EntityType.ENTITY_WAR, 11, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
			conquest.State = NpcState.STATE_APPEAR_CUSTOM
			conquest.MaxHitPoints = entity.MaxHitPoints
			conquest.HitPoints = entity.MaxHitPoints / 2

			local conquestSprite = conquest:GetSprite()
			conquestSprite:Play("Appear", true)
			conquestSprite.FlipX = sprite.FlipX


			-- Horse
			local horse = Isaac.Spawn(EntityType.ENTITY_WAR, 20, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
			horse.State = NpcState.STATE_MOVE

			local horseSprite = horse:GetSprite()
			horseSprite:Play("DashStart", true)
			horseSprite.FlipX = sprite.FlipX


			-- Set up champions properly
			if entity.SubType == 1 then
				for i = 0, conquestSprite:GetLayerCount() do
					conquestSprite:ReplaceSpritesheet(i, "gfx/bosses/better/boss_066_conquest 2_red.png")
				end
				conquestSprite:LoadGraphics()
				conquest.Scale = 1.15

				horseSprite:ReplaceSpritesheet(0, "gfx/bosses/better/boss_066_conquest 2_red.png")
				horseSprite:LoadGraphics()
				horse.Scale = 1.15
			end

			-- Damage all globins
			for _,v in pairs(Isaac.GetRoomEntities()) do
				if v.Type == EntityType.ENTITY_GLOBIN and v.SpawnerType == EntityType.ENTITY_WAR and v.SpawnerVariant == 1 and v:ToNPC().State ~= NpcState.STATE_IDLE then
					v:TakeDamage(40, 0, EntityRef(entity), 30)
				end
			end

			entity:Remove()
		end


		-- Red champion
		if entity.SubType == 1 then
			if entity.State == NpcState.STATE_JUMP and sprite:GetFrame() == 0 then
				if Isaac.CountEntities(entity, EntityType.ENTITY_GLOBIN, -1, -1) > Settings.MinGlobins then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack1", true)
				end
			
			elseif entity.State == NpcState.STATE_ATTACK then
				entity.State = NpcState.STATE_ATTACK3
			
			elseif entity.State == NpcState.STATE_ATTACK3 then
				if sprite:GetFrame() == 5 then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)

					local params = ProjectileParams()
					params.Scale = 1.435
					params.FallingAccelModifier = 1.25
					params.FallingSpeedModifier = math.random(-20, -10)
					params.BulletFlags = ProjectileFlags.EXPLODE

					for i = 0, 1 do
						entity:FireProjectiles(entity.Position, Vector.FromAngle(math.random(0, 359)) * 7, 0, params)
					end
					
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):ToEffect()
					effect:GetSprite().Offset = Vector(0, -44)
					effect.DepthOffset = entity.DepthOffset + 10
					effect.SpriteScale = Vector(1.25, 1.25)
				end
				
				if sprite:IsFinished("Attack1") then
					entity.State = NpcState.STATE_MOVE
				end
			end
		end


		-- Red champion clones charge horizontally to their target instead of randomly and only 5 of them spawn
		if entity.SpawnerEntity and entity.SpawnerType == EntityType.ENTITY_WAR and entity.SpawnerVariant == 1
		and entity.SpawnerEntity.SubType == 1 and entity.State == NpcState.STATE_ATTACK2 and entity.FrameCount == 0 then
			if Isaac.CountEntities(entity.SpawnerEntity, EntityType.ENTITY_WAR, 1, -1) >= Settings.CloneCount then
				entity:Remove()
			else
				entity.Position = Vector(entity.Position.X, entity:GetPlayerTarget().Position.Y)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.conquestUpdate, EntityType.ENTITY_WAR)

function mod:conquestDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_WAR or damageSource.SpawnerType == EntityType.ENTITY_WAR or (target.Variant == 1 and (target.HitPoints <= target.MaxHitPoints / 2
	or (target.Variant == 1 and target.SpawnerEntity and target.SpawnerType == EntityType.ENTITY_WAR and target.SpawnerVariant == 1 and target.SpawnerEntity.HitPoints <= target.SpawnerEntity.MaxHitPoints / 2))) then
		return false
	end
	
	-- Do attack if below 75%, 50% and 25% health
	if target.Variant == 11 and target.HitPoints <= (target.MaxHitPoints / 2) - (((target.MaxHitPoints / 2) / (Settings.AttackCount + 1)) * (target:ToNPC().I1 + 1)) and target:ToNPC().State == NpcState.STATE_MOVE then
		target:ToNPC().I1 = target:ToNPC().I1 + 1
		target:ToNPC().State = NpcState.STATE_ATTACK
		target:GetSprite():Play("Attack", true)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.conquestDMG, EntityType.ENTITY_WAR)



function mod:conquestCollide(entity, target, bool)
	if target.Type == EntityType.ENTITY_WAR or target.Type == EntityType.ENTITY_GLOBIN then
		-- Damage globins if charging
		if target.Type == EntityType.ENTITY_GLOBIN and target:ToNPC().State ~= NpcState.STATE_IDLE
		and ((entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK2) or (entity.Variant == 20 and entity.State == NpcState.STATE_MOVE)) then
			target:TakeDamage(40, 0, EntityRef(entity), 30)
		end

		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.conquestCollide, EntityType.ENTITY_WAR)

-- Red champion globins
function mod:conquestLightBeamUpdate(effect)
	if effect.SpawnerEntity and effect.SpawnerType == EntityType.ENTITY_WAR and effect.SpawnerEntity.SubType == 1 then
		if Isaac.CountEntities(effect.SpawnerEntity, EntityType.ENTITY_GLOBIN, -1, -1) < Settings.MaxGlobins and effect.Position:Distance(game:GetNearestPlayer(effect.Position).Position) >= 80 then
			Isaac.Spawn(EntityType.ENTITY_GLOBIN, 0, 0, effect.Position, Vector.Zero, effect.SpawnerEntity)
			SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND, 0.75)
		end
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.conquestLightBeamUpdate, EffectVariant.CRACK_THE_SKY)



-- 2nd phase
function mod:conquestPreUpdate(entity)
	if entity.Variant == 11 or entity.Variant == 20 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Conquest without horse
		if entity.Variant == 11 then
			if sprite:IsEventTriggered("Flap") then
				SFXManager():Play(SoundEffect.SOUND_ANGEL_WING, 0.6)
			end

			-- Appear
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 0.9, 0, false, 1)
				end
				if sprite:IsFinished("Appear") then
					entity.State = NpcState.STATE_MOVE
				end


			-- Idle
			elseif entity.State == NpcState.STATE_MOVE then
				entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * (Settings.MoveSpeed - entity.SubType) - entity.Velocity) * 0.25)
				if not sprite:IsPlaying("Walk") then
					sprite:Play("Walk", true)
				end

				if entity.Velocity.X < 0 then
					sprite.FlipX = true
				elseif entity.Velocity.X > 0 then
					sprite.FlipX = false
				end


			-- Attack
			elseif entity.State == NpcState.STATE_ATTACK then
				entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 0.9, 0, false, 1)

					-- Lasers
					if entity.SubType == 0 then
						for i = 0, 3 do
							local laser_ent_pair = {laser = EntityLaser.ShootAngle(5, entity.Position, i * 90, 15, Vector(0, -30), entity), entity}
							local laser = laser_ent_pair.laser
							laser.DepthOffset = entity.DepthOffset - 10
							laser.Mass = 0
						end
					
					-- Projectiles
					elseif entity.SubType == 1 then
						entity.I2 = 1
						entity.ProjectileDelay = 0
						entity.StateFrame = 0
						SFXManager():Play(SoundEffect.SOUND_BLOOD_LASER, 0.9, 0, false, 1)
					end

				elseif sprite:IsEventTriggered("Flap") then
					entity.I2 = 0
				end

				if sprite:IsFinished("Attack") then
					entity.State = NpcState.STATE_MOVE
				end


				-- Red champion projetiles
				if entity.I2 == 1 then
					if entity.ProjectileDelay <= 0 then
						entity.ProjectileDelay = Settings.ShotDelay
						entity.StateFrame = entity.StateFrame + 1

						local params = ProjectileParams()
						params.CircleAngle = entity.StateFrame * 225
						params.FallingSpeedModifier = -1
						entity:FireProjectiles(entity.Position, Vector(Settings.ShotSpeed, 8), 9, params)

					else
						entity.ProjectileDelay = entity.ProjectileDelay - 1
					end
				end
			end


		-- Horse
		elseif entity.Variant == 20 then
			-- Wait
			if entity.State == NpcState.STATE_IDLE then
				entity.TargetPosition = Vector(entity.V2.X, target.Position.Y)
				entity.Position = (entity.Position + (entity.TargetPosition - entity.Position) * 0.25)

				entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
				if not sprite:IsPlaying("Dash") then
					sprite:Play("Dash", true)
				end

				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_MOVE
					sprite:Play("DashStart", true)
					entity.I1 = 0
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Dash
			elseif entity.State == NpcState.STATE_MOVE then
				if sprite:IsEventTriggered("Dash") then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 0.75, 0, false, 1)
					entity.I1 = 1
					entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
					entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
					entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
					entity.Mass = 0.1

					if sprite.FlipX == false then
						entity.V1 = Vector(1, 0)
					elseif sprite.FlipX == true then
						entity.V1 = Vector(-1, 0)
					end
				end

				if entity.I1 == 0 then
					entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

				elseif entity.I1 == 1 then
					entity.Velocity = entity.V1 * Settings.DashSpeed
					if not sprite:IsPlaying("Dash") then
						sprite:Play("Dash", true)
					end

					-- Turn around
					local room = game:GetRoom()
					if (sprite.FlipX == false and entity.Position.X > room:GetBottomRightPos().X + 200) or (sprite.FlipX == true and entity.Position.X < room:GetTopLeftPos().X - 200) then
						entity.State = NpcState.STATE_IDLE
						entity.Position = Vector(entity.Position.X, target.Position.Y)
						entity.Velocity = Vector.Zero
						entity.ProjectileCooldown = Settings.DashCooldown

						if sprite.FlipX == false then
							sprite.FlipX = true
							entity.V2 = Vector(room:GetBottomRightPos().X + 20, 0)
						else
							sprite.FlipX = false
							entity.V2 = Vector(room:GetTopLeftPos().X - 20, 0)
						end
					end
				end
			end
		end

		if entity.FrameCount > 1 and not (entity:HasMortalDamage() or entity:IsDead()) then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.conquestPreUpdate, EntityType.ENTITY_WAR)