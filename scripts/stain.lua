local mod = BetterMonsters
local game = Game()

local Settings = {
	SideRange = 25,
	FrontRange = 220,
	WhipStrength = 6
}



function mod:stainInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.ProjectileCooldown = 10
	
	if entity.Variant == 10 then
		local sprite = entity:GetSprite()

		entity.State = NpcState.STATE_SPECIAL
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		sprite:Play("Tentacle", true)
		
		if entity.SubType == 1 then
			sprite:ReplaceSpritesheet(3, "gfx/bosses/better/thestain_grey.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.stainInit, EntityType.ENTITY_STAIN)

function mod:stainUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local room = game:GetRoom()

	entity.Velocity = Vector.Zero


	if entity.Variant == 0 then
		if entity.State == NpcState.STATE_IDLE then
			mod:LoopingAnim(sprite, "Idle")

			if entity.ProjectileCooldown <= 0 then
				if entity.SubType == 1 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("Attack2Begin", true)
					entity.ProjectileCooldown = math.random(90, 120)
				else
					entity.State = NpcState.STATE_STOMP
					sprite:Play("GoUnder", true)
					entity.StateFrame = 30
				end
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

			-- Whip target if close enough
			if entity.SubType ~= 1 and entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange
			and ((target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X)
			or (target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X)) then
				entity.State = NpcState.STATE_ATTACK5
				sprite:Play("Attack3", true)
				entity:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1, 0, false, 1)
				entity.ProjectileCooldown = entity.ProjectileCooldown - 20
			end


		-- Go underground
		elseif entity.State == NpcState.STATE_STOMP then
			if sprite:IsFinished("GoUnder") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				entity.State = NpcState.STATE_MOVE
				sprite:Play("Dirt", true)
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1.25)
			end

		-- Go to position
		elseif entity.State == NpcState.STATE_MOVE then
			entity.V1 = target.Position + Vector.FromAngle(math.random(0, 359)) * math.random(160, 280)
			entity.V1 = room:FindFreePickupSpawnPosition(entity.V1, 40, true, false)

			if entity.StateFrame <= 0 and entity.V1:Distance(target.Position) >= 120 and entity.V1.X > room:GetTopLeftPos().X + 40 and entity.V1.X < room:GetBottomRightPos().X - 40 then
				entity.Position = entity.V1
				entity.State = NpcState.STATE_JUMP
				sprite:Play("Appear", true)
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_BURST_OUT)

			else
				entity.StateFrame = entity.StateFrame - 1
			end

		-- Popup
		elseif entity.State == NpcState.STATE_JUMP then
			if sprite:IsFinished("Appear") then
				entity.ProjectileCooldown = math.random(60, 90)

				-- Only spawn up to 3 chargers
				local attackCount = 3
				if Isaac.CountEntities(entity, EntityType.ENTITY_MAGGOT, -1, -1) >= 3 then
					attackCount = 2
				end

				-- Decide attack
				local attack = math.random(1, attackCount)
				if attack == 1 then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Attack1", true)

				elseif attack == 2 then
					entity.State = NpcState.STATE_ATTACK2
					sprite:Play("Attack2Begin", true)

				elseif attack == 3 then
					entity.State = NpcState.STATE_SUMMON
					sprite:Play("Summon", true)
				end
			end


		-- Attack
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Start") then
				entity:PlaySound(SoundEffect.SOUND_WEIRD_WORM_SPIT, 1, 0, false, 1)
				entity.I1 = 1
				entity.I2 = 0
				entity.StateFrame = 0
			elseif sprite:IsEventTriggered("Stop") then
				entity.I1 = 0
			end
			
			if entity.I1 == 1 then
				if entity.I2 <= 0 then
					entity.I2 = 3
					entity.StateFrame = entity.StateFrame + 1

					local params = ProjectileParams()
					params.CircleAngle = entity.StateFrame * 0.3
					params.FallingSpeedModifier = -1
					params.Scale = 1.5
					entity:FireProjectiles(entity.Position, Vector(9.5, 8), 9, params)

				else
					entity.I2 = entity.I2 - 1
				end
			end

			if sprite:IsFinished("Attack1") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Tentacle attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if sprite:IsEventTriggered("Shoot") then
				entity:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_0, 0.9, 0, false, 1)
			elseif sprite:IsEventTriggered("Start") then
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 1.1)

			elseif sprite:IsFinished("Attack2Begin") then
				entity.State = NpcState.STATE_ATTACK3
				entity.I1 = 10
				entity.I2 = 0
				entity.StateFrame = 0
			end

		elseif entity.State == NpcState.STATE_ATTACK3 or entity.State == NpcState.STATE_SUMMON2 then
			if entity.State == NpcState.STATE_ATTACK3 then
				mod:LoopingAnim(sprite, "Attack2Loop")

				if entity.SubType == 1 then
					if entity.ProjectileCooldown <= 0 then
						entity.State = NpcState.STATE_SUMMON2
						sprite:Play("Attack2Summon", true)
					else
						entity.ProjectileCooldown = entity.ProjectileCooldown - 1
					end
				end

			-- Champion attack
			elseif entity.State == NpcState.STATE_SUMMON2 then
				if sprite:IsEventTriggered("Shoot") then
					if Isaac.CountEntities(entity, EntityType.ENTITY_CHARGER, -1, -1) >= 2 or math.random(0, 1) == 1 then
						entity:PlaySound(SoundEffect.SOUND_MEATY_DEATHS, 0.9, 0, false, 1)
						entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 1.1, 0, false, 1)
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position + Vector(10, -28), Vector.Zero, entity).DepthOffset = entity.DepthOffset - 100

						for i = 0, 3 do
							Isaac.Spawn(EntityType.ENTITY_VIS, 22, 0, entity.Position, Vector.FromAngle(i * 90) * 18, entity).Parent = entity
						end

					else
						Isaac.Spawn(EntityType.ENTITY_CHARGER, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity):ToNPC()
						SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
					end
				end

				if sprite:IsFinished("Attack2Summon") then
					entity.State = NpcState.STATE_ATTACK3
					entity.ProjectileCooldown = 120
				end
			end

			-- Spawn tentacles
			if entity.I2 < 3 or entity.SubType == 1 then
				if entity.I1 <= 0 then
					local pos = target.Position
					if entity.StateFrame > 0 and entity.SubType ~= 1 then
						pos = room:GetClampedPosition(target.Position + (target.Velocity * 10), 0)
					end
					local tentacle = Isaac.Spawn(EntityType.ENTITY_STAIN, 10, entity.SubType, pos, Vector.Zero, entity)
					tentacle.Parent = entity

					for i = 0, 5 do
						local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, tentacle.Position, Vector.FromAngle(math.random(0, 359)) * 3, entity):ToEffect()
						rocks:GetSprite():Play("rubble", true)
						rocks.State = 2
					end
					SFXManager():Play(SoundEffect.SOUND_ROCK_CRUMBLE)

					-- Spawn them in pairs
					if entity.StateFrame >= 1 then
						entity.I1 = 35
						entity.I2 = entity.I2 + 1
						entity.StateFrame = 0
					else
						entity.I1 = 5
						entity.StateFrame = entity.StateFrame + 1
					end

				else
					entity.I1 = entity.I1 - 1
				end

			-- Stop after 3 pairs
			elseif Isaac.CountEntities(entity, EntityType.ENTITY_STAIN, 10, -1) < 1 then
				entity.State = NpcState.STATE_ATTACK4
				sprite:Play("Attack2End", true)
			end

		elseif entity.State == NpcState.STATE_ATTACK4 then
			if sprite:IsEventTriggered("Stop") then
				SFXManager():Play(SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			if sprite:IsFinished("Attack2End") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Whip attack
		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Start") then
				SFXManager():Play(SoundEffect.SOUND_WHIP)

			elseif sprite:IsEventTriggered("Shoot") then
				-- Check if it hit the target
				if entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange
				and ((target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X)
				or (target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X)) then
					target:TakeDamage(2, 0, EntityRef(entity), 0)
					target.Velocity = target.Velocity + (Vector.FromAngle((target.Position - entity.Position):GetAngleDegrees()) * Settings.WhipStrength)
					SFXManager():Play(SoundEffect.SOUND_WHIP_HIT)
				end
			end
			
			if sprite:IsFinished("Attack3") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Summon
		elseif entity.State == NpcState.STATE_SUMMON then
			if sprite:IsEventTriggered("Shoot") then
				Isaac.Spawn(EntityType.ENTITY_MAGGOT, 0, 0, entity.Position + Vector(0, 10), Vector.Zero, entity):ToNPC()
				SFXManager():Play(SoundEffect.SOUND_SUMMONSOUND)
			end
			
			if sprite:IsFinished("Summon") then
				entity.State = NpcState.STATE_IDLE
				entity.ProjectileCooldown = 60
			end
		end


	-- Tentacle
	elseif entity.Variant == 10 then
		if sprite:IsEventTriggered("Start") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity:PlaySound(SoundEffect.SOUND_SKIN_PULL, 1, 0, false, 1)

		elseif sprite:IsEventTriggered("Stop") then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			if entity.SubType ~= 1 then
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position)
			end
		end
		
		if sprite:IsFinished("Tentacle") then
			entity:Remove()
		end
	end


	if entity.FrameCount > 1 or entity.Variant == 10 then
		return true
	elseif entity.FrameCount == 2 then
		entity.State = NpcState.STATE_IDLE
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.stainUpdate, EntityType.ENTITY_STAIN)

function mod:stainCollision(entity, target, cock)
	if target.SpawnerType == EntityType.ENTITY_STAIN then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.stainCollision, EntityType.ENTITY_STAIN)

function mod:stainDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if target.Variant == 10 and target.SpawnerEntity then
		target.SpawnerEntity:TakeDamage(damageAmount / 2, damageFlags, damageSource, damageCountdownFrames)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.stainDMG, EntityType.ENTITY_STAIN)