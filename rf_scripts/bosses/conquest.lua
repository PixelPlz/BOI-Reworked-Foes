local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 6,
	Cooldown = 60,

	WallDistance = 20,
	DashSpeed = 26,
	DashCooldown = 30,
	SideChangeDistance = 200,

	MaxGlobins = 4,
	MinGlobins = 2,
	CloneCount = 5,
}



function mod:ConquestInit(entity)
	--[[ Red Conquest clones ]]--
	if entity.Variant == 1 and entity.SpawnerEntity and mod:IsRFChampion(entity.SpawnerEntity, "Conquest") then
		-- Only 5 of them can spawn
		if Isaac.CountEntities(entity.SpawnerEntity, EntityType.ENTITY_WAR, 1, -1) >= Settings.CloneCount then
			entity:Remove()

		-- Appear horizontally to the target
		else
			entity.Position = Vector(entity.Position.X, entity.SpawnerEntity:ToNPC():GetPlayerTarget().Position.Y)
		end



	--[[ Horse ]]--
	elseif entity.Variant == 20 then
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.State = NpcState.STATE_MOVE
		entity:GetSprite():Play("Appear", true)

		-- Load the proper champion data
		if mod:IsRFChampion(entity.SpawnerEntity, "Conquest") then
			entity.Scale = 1.15

			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_066_conquest 2_bloody.png")
			sprite:LoadGraphics()
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
			-- Champion
			if mod:IsRFChampion(entity, "Conquest") then
				-- Don't go off-screen if there are too many Globins
				if entity.State == NpcState.STATE_JUMP and sprite:GetFrame() == 0 then
					if Isaac.CountEntities(entity, EntityType.ENTITY_GLOBIN, -1, -1) > Settings.MinGlobins then
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("Attack1", true)
					end


				-- Replace default projectile attack
				elseif entity.State == NpcState.STATE_ATTACK then
					entity.State = NpcState.STATE_ATTACK3

				-- Custom projectile attack
				elseif entity.State == NpcState.STATE_ATTACK3 then
					if sprite:GetFrame() == 5 then
						local params = ProjectileParams()
						params.Scale = 1.35
						entity:FireProjectiles(entity.Position, Vector(12, 6), 9, params)
						mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_4)
					end

					if sprite:IsFinished() then
						entity.State = NpcState.STATE_MOVE
					end
				end
			end


			-- Go to 2nd phase
			if entity.HitPoints <= entity.MaxHitPoints / 2 and entity.State ~= NpcState.STATE_ATTACK2
			and not entity.SpawnerEntity and not entity:GetData().wasDelirium then
				data.Phase2 = true
				sprite:Load("gfx/065.011_conquest without horse.anm2", true)

				entity.State = NpcState.STATE_APPEAR_CUSTOM
				sprite:Play("Appear", true)
				entity.ProjectileCooldown = Settings.Cooldown

				-- Load the proper champion spritesheets
				if mod:IsRFChampion(entity, "Conquest") then
					for i = 0, sprite:GetLayerCount() do
						sprite:ReplaceSpritesheet(i, "gfx/bosses/classic/boss_066_conquest 2_bloody.png")
					end
					sprite:LoadGraphics()
				end

				-- Horse
				local horse = Isaac.Spawn(EntityType.ENTITY_WAR, 20, entity.SubType, entity.Position, Vector.Zero, entity)
				horse:GetSprite().FlipX = sprite.FlipX
			end



		--[[ 2nd phase ]]--
		else
			if sprite:IsEventTriggered("Flap") then
				mod:PlaySound(nil, SoundEffect.SOUND_ANGEL_WING, 0.6)
			end

			-- Appear
			if entity.State == NpcState.STATE_APPEAR_CUSTOM then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0, 0.9)
				end
				if sprite:IsFinished() then
					entity.State = NpcState.STATE_MOVE
				end


			-- Idle
			elseif entity.State == NpcState.STATE_MOVE then
				mod:ChasePlayer(entity, Settings.MoveSpeed, true)
				mod:LoopingAnim(sprite, "Walk")
				mod:FlipTowardsMovement(entity, sprite)

				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack", true)
					entity.ProjectileCooldown = Settings.Cooldown
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end


			-- Attack
			elseif entity.State == NpcState.STATE_ATTACK then
				entity.Velocity = mod:StopLerp(entity.Velocity)

				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.Scale = 1.35

					-- Champion
					if mod:IsRFChampion(entity, "Conquest") then
						entity:FireProjectiles(entity.Position, Vector(12, 9), 9, params)
					-- Regular
					else
						params.BulletFlags = ProjectileFlags.SMART
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
				entity.I1 = 1
				entity.V1 = Vector(mod:GetSign(not sprite.FlipX), 0)
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 0.9)
			end

			-- Stopped
			if entity.I1 == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)

			-- Moving
			elseif entity.I1 == 1 then
				entity.Velocity = entity.V1 * Settings.DashSpeed
				mod:LoopingAnim(sprite, "Dash")

				-- Red champion bullets
				if mod:IsRFChampion(entity, "Conquest")
				and room:IsPositionInRoom(entity.Position, 0) == true and entity:IsFrame(2, 0) then
					local params = ProjectileParams()
					params.BulletFlags = (ProjectileFlags.NO_WALL_COLLIDE | ProjectileFlags.CHANGE_FLAGS_AFTER_TIMEOUT)
					params.ChangeTimeout = 60
					params.ChangeFlags = ProjectileFlags.ANTI_GRAVITY

					params.Scale = 1.35
					params.FallingSpeedModifier = 1
					params.FallingAccelModifier = -0.2
					params.HeightModifier = 10
					entity:FireProjectiles(entity.Position, Vector.Zero, 0, params)
				end

				-- Turn around
				if (sprite.FlipX == false and entity.Position.X > room:GetBottomRightPos().X + Settings.SideChangeDistance)
				or (sprite.FlipX == true  and entity.Position.X < room:GetTopLeftPos().X - Settings.SideChangeDistance) then
					entity.State = NpcState.STATE_IDLE
					entity.Position = Vector(entity.Position.X, target.Position.Y)
					entity.Velocity = Vector.Zero
					entity.ProjectileCooldown = Settings.DashCooldown

					if sprite.FlipX == false then
						sprite.FlipX = true
						entity.V2 = Vector(room:GetBottomRightPos().X + Settings.WallDistance, 0)
					else
						sprite.FlipX = false
						entity.V2 = Vector(room:GetTopLeftPos().X - Settings.WallDistance, 0)
					end
				end
			end
		end

		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.ConquestUpdate, EntityType.ENTITY_WAR)

function mod:ConquestDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	-- Take less damage while charging when he's low enough for the 2nd phase
	if entity.Variant == 1 and not entity:GetData().Phase2 and not (damageFlags & DamageFlag.DAMAGE_CLONES > 0)
	and (entity.HitPoints <= entity.MaxHitPoints / 2 -- Main Conquest
	or (entity.SpawnerEntity and entity.SpawnerEntity.HitPoints <= entity.SpawnerEntity.MaxHitPoints / 2)) then -- Clones
		entity:TakeDamage(damageAmount / 4, damageFlags + DamageFlag.DAMAGE_CLONES, damageSource, damageCountdownFrames)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.ConquestDMG, EntityType.ENTITY_WAR)

function mod:ConquestCollision(entity, target, bool)
	if target.Type == EntityType.ENTITY_WAR or target.Type == EntityType.ENTITY_GLOBIN then
		-- Damage Globins it charges into
		if ((entity.Variant == 1 and entity.State == NpcState.STATE_ATTACK2) or (entity.Variant == 20 and entity.State == NpcState.STATE_MOVE))
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
		if Isaac.CountEntities(nil, EntityType.ENTITY_GLOBIN, -1, -1) < Settings.MaxGlobins -- Less than the max amount
		and effect.Position:Distance(Game():GetNearestPlayer(effect.Position).Position) >= 100 then -- Far enough away from any players
			Isaac.Spawn(EntityType.ENTITY_GLOBIN, 0, 0, effect.Position, Vector.Zero, effect.SpawnerEntity)
			mod:PlaySound(nil, SoundEffect.SOUND_SUMMONSOUND, 0.75)
		end

		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ConquestLightBeamReplace, EffectVariant.CRACK_THE_SKY)