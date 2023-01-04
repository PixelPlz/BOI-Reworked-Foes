local mod = BetterMonsters

local Settings = {
	MoveSpeed = 6,
	Cooldown = {90, 120},

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
		if not entity.SpawnerEntity and entity.HitPoints <= entity.MaxHitPoints / 2 and entity.State ~= NpcState.STATE_ATTACK2 and not entity:GetData().wasDelirium then
			-- Conquest without horse
			local conquest = Isaac.Spawn(EntityType.ENTITY_WAR, 11, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
			conquest.State = NpcState.STATE_APPEAR_CUSTOM
			conquest.MaxHitPoints = entity.MaxHitPoints
			conquest.HitPoints = entity.HitPoints
			conquest.ProjectileCooldown = Settings.Cooldown[1]

			local conquestSprite = conquest:GetSprite()
			conquestSprite:Play("Appear", true)
			conquestSprite.FlipX = sprite.FlipX


			-- Horse
			local horse = Isaac.Spawn(EntityType.ENTITY_WAR, 20, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
			horse.State = NpcState.STATE_MOVE

			local horseSprite = horse:GetSprite()
			horseSprite:Play("DashStart", true)
			horseSprite.FlipX = sprite.FlipX


			-- Champion specific
			if entity.SubType == 1 then
				-- Set up champions properly
				for i = 0, conquestSprite:GetLayerCount() do
					conquestSprite:ReplaceSpritesheet(i, "gfx/bosses/classic/boss_066_conquest 2_red.png")
				end
				conquestSprite:LoadGraphics()
				conquest.Scale = 1.15

				horseSprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_066_conquest 2_red.png")
				horseSprite:LoadGraphics()
				horse.Scale = 1.15

				-- Damage all globins
				for _,v in pairs(Isaac.GetRoomEntities()) do
					if v.Type == EntityType.ENTITY_GLOBIN and v.SpawnerType == EntityType.ENTITY_WAR and v.SpawnerVariant == 1 and v:ToNPC().State ~= NpcState.STATE_IDLE then
						v:TakeDamage(40, 0, EntityRef(entity), 30)
					end
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
					params.Scale = 1.45
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
	if damageSource.Type == EntityType.ENTITY_WAR or damageSource.SpawnerType == EntityType.ENTITY_WAR then
		return false
	end

	if target.Variant == 1 and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0)
	and ((target.HitPoints <= target.MaxHitPoints / 2) or (target.SpawnerEntity and target.SpawnerType == target.Type and target.SpawnerEntity.HitPoints <= target.SpawnerEntity.MaxHitPoints / 2)) then
		target:TakeDamage(damageAmount / 4, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		return false
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
		if Isaac.CountEntities(effect.SpawnerEntity, EntityType.ENTITY_GLOBIN, -1, -1) < Settings.MaxGlobins and effect.Position:Distance(Game():GetNearestPlayer(effect.Position).Position) >= 80 then
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
		local room = Game():GetRoom()


		-- Conquest without horse
		if entity.Variant == 11 then
			if sprite:IsEventTriggered("Flap") then
				SFXManager():Play(SoundEffect.SOUND_ANGEL_WING, 0.6)
			end

			-- Appear
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 0.9, 0, false, 1)
				end
				if sprite:IsFinished("Appear") then
					entity.State = NpcState.STATE_MOVE
				end


			-- Idle
			elseif entity.State == NpcState.STATE_MOVE then
				entity.Velocity = (entity.Velocity + ((target.Position - entity.Position):Normalized() * (Settings.MoveSpeed - entity.SubType) - entity.Velocity) * 0.25)
				mod:LoopingAnim(sprite, "Walk")

				if entity.Velocity.X < 0 then
					sprite.FlipX = true
				elseif entity.Velocity.X > 0 then
					sprite.FlipX = false
				end
				
				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Attack
			elseif entity.State == NpcState.STATE_ATTACK then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 0.9, 0, false, 1)
					local params = ProjectileParams()

					if entity.SubType == 0 then
						params.BulletFlags = ProjectileFlags.SMART
						params.Scale = 1.5
						entity:FireProjectiles(entity.Position, Vector(11, 6), 9, params)

					-- Red champion
					elseif entity.SubType == 1 then
						params.Scale = 1.45
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
				end

				if sprite:IsFinished("Attack") then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = math.random(Settings.Cooldown[1], Settings.Cooldown[2])
				end
			end


		-- Horse
		elseif entity.Variant == 20 then
			-- Wait
			if entity.State == NpcState.STATE_IDLE then
				entity.TargetPosition = Vector(entity.V2.X, target.Position.Y)
				entity.Position = (entity.Position + (entity.TargetPosition - entity.Position) * 0.25)

				entity.Velocity = mod:StopLerp(entity.Velocity)
				mod:LoopingAnim(sprite, "Dash")

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
					entity:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 0.9, 0, false, 1)
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
					entity.Velocity = mod:StopLerp(entity.Velocity)

				elseif entity.I1 == 1 then
					entity.Velocity = entity.V1 * (Settings.DashSpeed - entity.SubType)
					mod:LoopingAnim(sprite, "Dash")

					-- Red champion bullets
					if entity.SubType == 1 then
						if room:IsPositionInRoom(entity.Position, 0) == true and entity:IsFrame(2, 0) then
							entity.ProjectileDelay = room:GetGridIndex(entity.Position)

							local params = ProjectileParams()
							params.Scale = 1.4
							params.FallingSpeedModifier = 1
							entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
						end
					end

					-- Turn around
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