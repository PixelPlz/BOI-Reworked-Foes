local mod = ReworkedFoes

local Settings = {
	SideRange = 25,
	FrontRange = 100,
	WhipStrength = 5,
	TentacleDamageReduction = 20,
}



function mod:StainInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	-- Tentacle
	if entity.Variant == 10 then
		local sprite = entity:GetSprite()
		sprite:Play("Appear", true)

		entity.State = NpcState.STATE_SPECIAL
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.SpawnerEntity and entity.SpawnerEntity:GetData().wasDelirium then
			sprite:ReplaceSpritesheet(1, "gfx/bosses/afterbirthplus/deliriumforms/afterbirth/thestain.png")
			sprite:LoadGraphics()

		elseif entity.SubType == 1 then
			sprite:ReplaceSpritesheet(1, "gfx/bosses/afterbirth/thestain_grey.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.StainInit, EntityType.ENTITY_STAIN)

function mod:StainUpdate(entity)
	if entity.Variant == 0 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Tentacle attack
		-- Replace default one
		if entity.State == NpcState.STATE_ATTACK and entity.I1 == 1 then
			entity.State = NpcState.STATE_ATTACK4
			sprite:Play("Attack1Begin", true)
			mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)


		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			-- Start
			if sprite:IsFinished("Attack1Begin") then
				entity.State = NpcState.STATE_ATTACK5
				entity.ProjectileCooldown = 10
				entity.StateFrame = 0

			-- Stop
			elseif sprite:IsFinished("Attack1End") then
				entity.State = NpcState.STATE_IDLE
			end


		-- Loop
		elseif entity.State == NpcState.STATE_ATTACK5 then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Attack1Loop")

			-- Spawn tentacles
			if entity.StateFrame < 2 + entity.SubType then
				if entity.ProjectileCooldown <= 0 then
					local directions = {0, 90, 180, 270}

					for i = 1, 2 do
						local choice = math.random(1, #directions)
						local direction = directions[choice]
						table.remove(directions, choice)

						local pos = Game():GetRoom():FindFreePickupSpawnPosition(target.Position + Vector.FromAngle(direction):Resized(100), 40, true, false)
						local tentacle = Isaac.Spawn(EntityType.ENTITY_STAIN, 10, entity.SubType, pos, Vector.Zero, entity)
						tentacle.Parent = entity

						-- Rock particles
						local rockSubType = Game():GetRoom():GetBackdropType()

						for j = 1, 4 do
							local velocity = mod:RandomVector(math.random(2, 4))
							local rock = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, rockSubType, tentacle.Position, velocity, entity):ToEffect()
							rock:Update()
							rock.State = 2
						end
					end
					mod:PlaySound(nil, SoundEffect.SOUND_ROCK_CRUMBLE)

					entity.ProjectileCooldown = 40
					entity.StateFrame = entity.StateFrame + 1

				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end

			-- Stop after 3 pairs
			elseif Isaac.CountEntities(entity, EntityType.ENTITY_STAIN, 10, -1) < 1 then
				entity.State = NpcState.STATE_ATTACK4
				sprite:Play("Attack1End", true)
			end



		-- Extra sounds
		-- For bullet hell attack
		elseif entity.State == NpcState.STATE_ATTACK2 then
			if (entity.I1 == 1 or entity.I1 == 4) and entity.StateFrame == 0 then
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_B)

			elseif sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1, 1, 5)
			end

		-- For summoning
		elseif entity.State == NpcState.STATE_SUMMON and sprite:IsEventTriggered("Summon") then
			mod:PlaySound(entity, SoundEffect.SOUND_WEIRD_WORM_SPIT)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.StainUpdate, EntityType.ENTITY_STAIN)

function mod:StainCollision(entity, target, bool)
	if target.SpawnerType == EntityType.ENTITY_STAIN then
		return true -- Ignore collision
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.StainCollision, EntityType.ENTITY_STAIN)



-- Tentacle
function mod:StainTentacleUpdate(entity)
	if entity.Variant == 10 then
		if entity.Parent then
			local sprite = entity:GetSprite()
			local target = entity.Parent:ToNPC():GetPlayerTarget()

			entity.Velocity = Vector.Zero
			entity.MaxHitPoints = entity.Parent.MaxHitPoints
			entity.HitPoints = entity.Parent.HitPoints


			-- Get whip direction
			if sprite:IsFinished("Appear") then
				local angle = mod:ClampVector((target.Position - entity.Position), 90):GetAngleDegrees()
				entity.V1 = Vector(angle, 0)
				sprite:Play("Swing" .. mod:GetDirectionString(angle), true)

			-- Remove self after burrowing
			elseif sprite:IsFinished("Burrow") then
				entity:Remove()

			-- Burrow after whipping
			elseif sprite:IsFinished() then
				sprite:Play("Burrow", true)
			end


			-- Toggle collision
			if sprite:IsEventTriggered("Start") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)

			elseif sprite:IsEventTriggered("Stop") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

			-- Sound
			elseif sprite:IsEventTriggered("Sound") then
				mod:PlaySound(nil, SoundEffect.SOUND_WHIP)


			-- Check if it hit the target
			elseif sprite:IsEventTriggered("Hit") then
				local hurtCheck = mod:CheckCardinalAlignment(entity, Settings.SideRange, Settings.FrontRange, 3, 1, entity.V1.X)

				-- On succesful hit
				if hurtCheck ~= false then
					target:TakeDamage(2, 0, EntityRef(entity), 0)
					target.Velocity = target.Velocity + Vector.FromAngle(hurtCheck):Resized(Settings.WhipStrength)
					mod:PlaySound(nil, SoundEffect.SOUND_WHIP_HIT, 1, 1, 5)
				end
			end


		else
			entity:Kill()
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.StainTentacleUpdate, EntityType.ENTITY_STAIN)

function mod:StainTentacleDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if entity.Variant == 10 and entity.Parent then
		local onePercent = damageAmount / 100
		local reduction = onePercent * Settings.TentacleDamageReduction

		entity.Parent:TakeDamage(damageAmount - reduction, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
		entity.Parent:SetColor(mod.Colors.ArmorFlash, 2, 0, false, false)
		entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.StainTentacleDMG, EntityType.ENTITY_STAIN)