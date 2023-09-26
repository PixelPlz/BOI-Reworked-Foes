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
		if entity.State == NpcState.STATE_ATTACK and entity.I1 == 1 then
			entity.State = NpcState.STATE_ATTACK4
			sprite:Play("Attack1Begin", true)
			mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)

		elseif entity.State == NpcState.STATE_ATTACK4 then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Shoot") then
				mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND)
			end

			if sprite:IsFinished("Attack1Begin") then
				entity.State = NpcState.STATE_ATTACK5
				entity.ProjectileCooldown = 10
				entity.StateFrame = 0

			elseif sprite:IsFinished("Attack1End") then
				entity.State = 3
			end


		elseif entity.State == NpcState.STATE_ATTACK5 then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Attack1Loop")

			-- Spawn tentacles
			if entity.StateFrame < 3 then
				if entity.ProjectileCooldown <= 0 then
					local directions = {0, 90, 180, 270}

					for i = 0, 1 do
						local choice = math.random(1, #directions)
						local direction = directions[choice]
						table.remove(directions, choice)

						local pos = Game():GetRoom():FindFreePickupSpawnPosition(target.Position + Vector.FromAngle(direction):Resized(100), 40, true, false)
						local tentacle = Isaac.Spawn(EntityType.ENTITY_STAIN, 10, entity.SubType, pos, Vector.Zero, entity)
						tentacle.Parent = entity

						for i = 0, 5 do
							local rocks = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 6, tentacle.Position, mod:RandomVector(3), entity):ToEffect()
							rocks:GetSprite():Play("rubble", true)
							rocks.State = 2
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
				local angleDegrees = (target.Position - entity.Position):GetAngleDegrees()
				local facing = mod:GetDirectionString(angleDegrees)
				sprite:Play("Swing" .. facing, true)

			-- Remove self after burrowing
			elseif sprite:IsFinished("Burrow") then
				entity:Remove()

			-- Burrow after whipping
			elseif sprite:IsFinished() then
				sprite:Play("Burrow", true)
			end


			if sprite:IsEventTriggered("Start") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				mod:PlaySound(nil, SoundEffect.SOUND_SKIN_PULL)

			elseif sprite:IsEventTriggered("Stop") then
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

			elseif sprite:IsEventTriggered("Sound") then
				mod:PlaySound(nil, SoundEffect.SOUND_WHIP)

			elseif sprite:IsEventTriggered("Hit") then
				local hurt = false

				-- Check if it hit the target
				if Game():GetRoom():CheckLine(entity.Position, target.Position, 3, 0, false, false) then
					if sprite:IsPlaying("SwingLeft") or sprite:IsPlaying("SwingRight") then
						if entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange then
							if sprite:IsPlaying("SwingLeft") and target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X
							or sprite:IsPlaying("SwingRight") and target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X then
								hurt = true
							end
						end

					elseif sprite:IsPlaying("SwingUp") or sprite:IsPlaying("SwingDown") then
						if entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange then
							if sprite:IsPlaying("SwingUp") and target.Position.Y > (entity.Position.Y - Settings.FrontRange) and target.Position.Y < entity.Position.Y
							or sprite:IsPlaying("SwingDown") and target.Position.Y < (entity.Position.Y + Settings.FrontRange) and target.Position.Y > entity.Position.Y then
								hurt = true
							end
						end
					end
				end

				-- On succesful hit
				if hurt == true then
					target:TakeDamage(2, 0, EntityRef(entity.Parent), 0)
					target.Velocity = target.Velocity + (target.Position - entity.Position):Resized(Settings.WhipStrength)
					mod:PlaySound(nil, SoundEffect.SOUND_WHIP_HIT)
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
		local reduction = onePercent * Settings.LegDamageReduction

		entity.Parent:TakeDamage(damageAmount - reduction, damageFlags + DamageFlag.DAMAGE_COUNTDOWN, damageSource, 1)
		entity:SetColor(mod.Colors.DamageFlash, 2, 0, false, true)
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.StainTentacleDMG, EntityType.ENTITY_STAIN)