local mod = BetterMonsters

local Settings = {
	NewHP = 250,
	Cooldown = 90,
	TransparencyTimer = 10,

	MoveSpeed = 5.25,
	ChaseSpeed = 6.5,
	AngrySpeed = 5.75,

	ChaseTime = 120,
	CreepTime = 100,
}



function mod:blightedOvumInit(entity)
	if entity.Variant == 2 or entity.Variant == 12 then
		entity.ProjectileCooldown = math.random(Settings.Cooldown / 2, Settings.Cooldown * 2)

		if entity.Variant == 2 then
			entity.MaxHitPoints = Settings.NewHP
			entity.HitPoints = entity.MaxHitPoints

		elseif entity.Variant == 12 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blightedOvumInit, EntityType.ENTITY_GEMINI)

function mod:blightedOvumUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local room = Game():GetRoom()


	-- Big guy
	if entity.Variant == 2 then
		if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK2 or entity.State == NpcState.STATE_ATTACK3 then
			local speed = Settings.MoveSpeed
			local anim = "IdleHead"


			-- 2nd phase
			if entity.I1 == 1 then
				speed = Settings.AngrySpeed

				-- Effect
				if entity:IsFrame(2, 0) then
					for i = 0, 2 do
						local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, entity.Position, Vector.FromAngle(math.random(240, 300)), entity):ToEffect()
						local scaler = math.random(70, 90) / 100
						trail.SpriteScale = Vector(scaler, scaler)
						trail.SpriteOffset = Vector(math.random(-9, 9), math.random(18, 26) * -1)
						trail.DepthOffset = entity.DepthOffset - 50
						trail:GetSprite().Color = ghostTrailColor
						trail:Update()
					end
				end

				-- Attack
				if entity.State == NpcState.STATE_ATTACK2 then
					anim = "Shoot"

					if sprite:IsOverlayPlaying("Shoot") then
						if sprite:GetOverlayFrame() == 16 then
							local params = ProjectileParams()
							params.BulletFlags = ProjectileFlags.GHOST
							entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 10, 3, params)
							mod:shootEffect(entity, 5, Vector(0, -30), Color(0,0,0, 0.5, 0.5,0.5,0.5))
							entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0, false, 0.9)

						elseif sprite:GetOverlayFrame() == 31 then
							entity.State = NpcState.STATE_MOVE
							entity.ProjectileCooldown = Settings.Cooldown
						end
					end

				-- Chase
				else
					anim = "HeadPossessed"
					if entity.State == NpcState.STATE_ATTACK3 then
						speed = Settings.ChaseSpeed
						entity:SetColor(Color(1,1,1, 0.5, 0.25,0.25,0.25), 10, 1, true, false)
					end
				end


			-- 1st phase chase
			elseif entity.State == NpcState.STATE_ATTACK then
				anim = "RageBody"
				speed = Settings.ChaseSpeed
				
				if entity:IsFrame(4, 0) then
					mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 1, Settings.CreepTime)
				end
			end


			-- Movement
			if entity:HasEntityFlags(EntityFlag.FLAG_FEAR) or entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) then
				speed = -speed
			end

			if entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) then
				entity.Pathfinder:MoveRandomly(false)
			else
				if entity.Pathfinder:HasPathToPos(target.Position) or entity.State == NpcState.STATE_ATTACK3 then
					if room:CheckLine(entity.Position, target.Position, 0, 0, false, false) or entity.State == NpcState.STATE_ATTACK3 then
						entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Normalized() * speed, 0.25)
					else
						entity.Pathfinder:FindGridPath(target.Position, speed / 6, 500, false)
					end
				else
					entity.Velocity = mod:StopLerp(entity.Velocity)
				end
			end

			-- Animations
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
			mod:LoopingOverlay(sprite, anim)


			-- Cooldown
			if entity.ProjectileCooldown <= 0 then
				if entity.State == NpcState.STATE_MOVE then
					-- 2nd phase
					if entity.I1 == 1 then
						if math.random(0, 1) == 1 then
							entity.State = NpcState.STATE_ATTACK2
						else
							entity.State = NpcState.STATE_ATTACK3
							entity.ProjectileCooldown = Settings.ChaseTime
							entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
							SFXManager():Play(SoundEffect.SOUND_BEAST_GHOST_DASH)
						end

					-- 1st phase
					else
						entity.State = NpcState.STATE_ATTACK
						entity.ProjectileCooldown = Settings.ChaseTime
						entity:PlaySound(SoundEffect.SOUND_MONSTER_YELL_B, 0.8, 0, false, 1)
					end
					
				-- Chase
				elseif entity.State == NpcState.STATE_ATTACK or (entity.State == NpcState.STATE_ATTACK3 and room:GetGridCollisionAtPos(entity.Position) == GridCollisionClass.COLLISION_NONE) then
					if entity.State == NpcState.STATE_ATTACK3 then
						entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
						SFXManager():Play(SoundEffect.SOUND_BEAST_GHOST_DASH, 0.75, 0, false, 0.9)
					end

					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = Settings.Cooldown
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


			-- Transition to 2nd phase
			if entity.I1 == 0 and entity.HitPoints <= (entity.MaxHitPoints / 2) then
				if entity:GetData().wasDelirium then
					entity.I1 = 1

				else
					entity.State = NpcState.STATE_SPECIAL
					sprite:PlayOverlay("Transition1", true)

					entity:BloodExplode()
					Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity)
					SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
					SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS)
				end
			end


		-- Transition
		elseif entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
			
			if sprite:IsOverlayFinished("Transition1") then
				entity.State = NpcState.STATE_IDLE
			elseif sprite:IsOverlayFinished("Transition2") then
				entity.State = NpcState.STATE_MOVE
				entity.I1 = 1
				entity.ProjectileCooldown = Settings.Cooldown
			end

		-- Run away
		elseif entity.State == NpcState.STATE_IDLE then
			local vector = room:FindFreePickupSpawnPosition(entity.Position + (Vector.FromAngle((entity.Position - target.Position):GetAngleDegrees() + math.random(-15, 15)) * 120), 40, true, false)

			if entity.Position:Distance(vector) > 40 and entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) == false then
				if room:CheckLine(entity.Position, vector, 0, 0, false, false) then
					entity.Velocity = mod:Lerp(entity.Velocity, (vector - entity.Position):Normalized() * Settings.MoveSpeed, 0.25)
				else
					entity.Pathfinder:FindGridPath(vector, Settings.MoveSpeed / 6, 500, false)
				end
			else
				entity.Pathfinder:MoveRandomly(false)
			end
			
			entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
			mod:LoopingOverlay(sprite, "HeadHalf")
		end


		if entity.FrameCount > 1 then
			return true
		end


	-- Baby
	elseif entity.Variant == 12 then
		-- Transparency
		if entity.I2 > 0 then
			sprite.Color = Color(1,1,1, 0.5)
			entity.I2 = entity.I2 - 1
		else
			sprite.Color = Color.Default
		end
		
		
		-- Die if it has no parent
		if not entity.Parent then
			entity.Visible = true
			entity.State = NpcState.STATE_DEATH
			sprite:Play("Death", true)
		end


		if entity.State == NpcState.STATE_MOVE or entity.State == NpcState.STATE_ATTACK then
			-- Haunt parent
			if entity.Parent:ToNPC().State == NpcState.STATE_IDLE then
				entity.State = NpcState.STATE_SPECIAL
				sprite:Play("Haunt", true)
			end


			-- Orbit parent
			entity.StateFrame = entity.StateFrame + 4
			if entity.StateFrame >= 360 then
				entity.StateFrame = entity.StateFrame - 360
			end
			entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (Vector.FromAngle(entity.StateFrame) * 40), 0.25)
			entity.Velocity = entity.Parent.Velocity
			
			-- Face towards the player
			if target.Position.X < entity.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end


			if entity.State == NpcState.STATE_MOVE then
				mod:LoopingAnim(sprite, "Walk01")

				if entity.ProjectileCooldown <= 0 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack01", true)
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end

			-- Attack
			elseif entity.State == NpcState.STATE_ATTACK then
				if sprite:IsEventTriggered("Shoot") then
					local params = ProjectileParams()
					params.BulletFlags = ProjectileFlags.GHOST
					entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * 13, 0, params)
					mod:shootEffect(entity, 5, Vector(0, -20), Color(0,0,0, 0.5, 0.5,0.5,0.5))
					entity:PlaySound(SoundEffect.SOUND_CUTE_GRUNT, 0.9, 0, false, 0.9)
				end

				if sprite:IsFinished("Attack01") then
					entity.State = NpcState.STATE_MOVE
					entity.ProjectileCooldown = Settings.Cooldown
				end
			end


		-- Haunt
		elseif entity.State == NpcState.STATE_SPECIAL then
			if entity.I1 == 0 then
				entity.Velocity = mod:StopLerp(entity.Velocity)
			elseif entity.I1 == 1 then
				entity.Position = entity.Parent.Position
				entity.Velocity = entity.Parent.Velocity
			end

			if sprite:IsEventTriggered("Shoot") then
				entity.I1 = 1
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				SFXManager():Play(SoundEffect.SOUND_BEAST_GHOST_DASH)
			end

			if sprite:IsFinished("Haunt") and entity.Parent then
				entity.Parent:ToNPC().State = NpcState.STATE_SPECIAL
				entity.Parent:GetSprite():PlayOverlay("Transition2", true)
				entity.Parent:SetColor(Color(1,1,1, 1, 0.4,0.4,0.4), 8, 1, true, false)

				entity.State = NpcState.STATE_IDLE
				SFXManager():Play(SoundEffect.SOUND_FLAMETHROWER_END, 1.1)
			end

		-- Haunting
		elseif entity.State == NpcState.STATE_IDLE then
			entity.Position = entity.Parent.Position
			entity.Velocity = entity.Parent.Velocity
			entity.Visible = false
		end


		if entity.FrameCount > 1 then
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blightedOvumUpdate, EntityType.ENTITY_GEMINI)

function mod:blightedOvumDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 12 then
		target:ToNPC().I2 = Settings.TransparencyTimer
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blightedOvumDMG, EntityType.ENTITY_GEMINI)

function mod:blightedOvumDeath(entity)
	if entity.Variant == 12 then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ENEMY_GHOST, 2, entity.Position, Vector.Zero, entity)
		SFXManager():Play(SoundEffect.SOUND_DEMON_HIT)

		for i, e in pairs(Isaac.FindInRadius(entity.Position, 60, EntityPartition.ENEMY)) do
			e:TakeDamage(40, 0, EntityRef(entity), 0)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blightedOvumDeath, EntityType.ENTITY_GEMINI)