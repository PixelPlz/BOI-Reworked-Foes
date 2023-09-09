local mod = BetterMonsters



function mod:bluePinInit(entity)
	if entity.Variant == 0 and entity.SubType == IRFentities.PinChampion and not entity.Parent and not entity.SpawnerEntity then
		local data = entity:GetData()
		data.siblings = {}

		-- Count all the other Pin spawns in this room
		local otherPinCount = 0
		for i, pin in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if pin.Index ~= entity.Index and not pin.Parent then
				otherPinCount = otherPinCount + 1
			end
		end


		-- First one to spawn creates the extra siblings
		if otherPinCount < 3 then
			for i = 1, 2 do
				local sibling = Isaac.Spawn(entity.Type, entity.Variant, entity.SubType, entity.Position + mod:RandomVector(mod:Random(20, 40)), Vector.Zero, entity):ToNPC()

				-- Appear animation
				if entity.State == NpcState.STATE_APPEAR_CUSTOM then
					sibling:GetSprite():Play("Attack1", true)
					sibling:GetSprite():SetFrame(entity:GetSprite():GetFrame() - i * 10)
					sibling.State = NpcState.STATE_APPEAR_CUSTOM
					sibling.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				end

				table.insert(data.siblings, sibling)
			end

			data.siblings[1]:GetData().siblings = {entity, data.siblings[2]}
			data.siblings[2]:GetData().siblings = {entity, data.siblings[1]}


		-- Subsequent ones get added as siblings to the first ones instead
		else
			for i, pin in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
				if pin.Index ~= entity.Index and not pin.Parent then
					table.insert(data.siblings, pin)
					table.insert(pin:GetData().siblings, entity)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.bluePinInit, EntityType.ENTITY_PIN)

function mod:bluePinUpdate(entity)
	if entity.Variant == 0 and entity.SubType == IRFentities.PinChampion then
		-- Check if it did the default attack and remove its projectiles
		local function doNewAttackInstead()
			local shot = false

			for i, projectile in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE, -1, -1, false, false)) do
				if projectile.FrameCount <= 0 and projectile.SpawnerEntity and projectile.SpawnerEntity.Index == entity.Index then
					shot = true
					projectile:Remove()
				end
			end

			return shot
		end


		-- Head
		if not entity.Parent then
			local sprite = entity:GetSprite()
			local target = entity:GetPlayerTarget()
			local data = entity:GetData()


			if data.siblings then
				-- Get the highest number of siblings it had
				if data.maxSiblings then
					data.maxSiblings = math.max(data.maxSiblings, #data.siblings)
				else
					data.maxSiblings = #data.siblings
				end

				-- Remove dead siblings from the list
				for i, sibling in pairs(data.siblings) do
					if not sibling:Exists() or sibling:IsDead() then
						table.remove(data.siblings, i)
					end
				end

				-- Get sibling count (this is dumb)
				data.siblingCount = math.floor(#data.siblings / (data.maxSiblings / 3))
				data.siblingCount = math.max(0, data.siblingCount)


				-- Pop up
				if entity.State == NpcState.STATE_ATTACK then
					-- Change animation
					if sprite:IsPlaying("Attack1") then
						sprite:Play("Attack1Alt", true)
					end


					-- Shoot
					doNewAttackInstead()

					if (data.siblingCount <= 1 and sprite:IsEventTriggered("Shoot1")) or (data.siblingCount <= 0 and sprite:IsEventTriggered("Shoot2")) then
						local params = ProjectileParams()
						params.GridCollision = false
						params.FallingAccelModifier = 1.5
						params.FallingSpeedModifier = -15
						params.HeightModifier = -40

						local speed = entity.Position:Distance(target.Position) / 18
						speed = math.min(12, speed)
						entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Resized(speed), 0, params)
						mod:ShootEffect(entity, 2, Vector(-2, -40), Color.Default, 0.85)
					end


					-- Stop the default sound
					if SFXManager():IsPlaying(SoundEffect.SOUND_CUTE_GRUNT) then
						SFXManager():Stop(SoundEffect.SOUND_CUTE_GRUNT)
					end

					-- Do the roar
					if sprite:WasEventTriggered("Scream") and not sprite:WasEventTriggered("Burrow")
					and not SFXManager():IsPlaying(IRFsounds.LarryScreamLoop) then
						mod:PlaySound(entity, IRFsounds.LarryScreamLoop, 1.1, 1.05, 0, true)
					end

					-- STFU!!!
					if sprite:IsEventTriggered("Burrow") then
						mod:PlaySound(nil, SoundEffect.SOUND_MAGGOT_ENTER_GROUND, 0.9)
						SFXManager():StopLoopingSounds()
					end
				end
			end

			-- Dead worms can't scream, silly
			if entity:HasMortalDamage() then
				SFXManager():StopLoopingSounds()
			end


		-- "Tail" (it's not actually the last segment that shoots when jumping out for some reason)
		elseif doNewAttackInstead() == true then
			local siblingCount = nil
			if entity.SpawnerEntity:GetData().siblings then
				siblingCount = entity.SpawnerEntity:GetData().siblingCount
			end

			if siblingCount then
				-- 6-way shots
				if siblingCount == 0 then
					entity:FireProjectiles(entity.Position, Vector(8, 6), 9, ProjectileParams())

				-- + / X shots
				elseif siblingCount == 1 then
					entity:FireProjectiles(entity.Position, Vector(8, 4), mod:Random(6, 7), ProjectileParams())
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.bluePinUpdate, EntityType.ENTITY_PIN)