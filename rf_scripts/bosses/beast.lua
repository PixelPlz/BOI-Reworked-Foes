local mod = ReworkedFoes

local stalactiteRNG = RNG()



function mod:BeastUpdate(entity)
	local sprite = entity:GetSprite()

	--[[ Background Beast ]]--
	if entity.Variant == 100 then
		-- Check if any players died
		if entity.State == NpcState.STATE_IDLE then
			for i = 0, Game():GetNumPlayers() do
				local player = Game():GetPlayer(i)

				-- Laugh at their misery
				if player:IsDead() and not player:GetData().BeastLaughedAt then
					entity.State = NpcState.STATE_ATTACK
					sprite:Play("Laugh", true)
					break
				end
			end

		-- LOLing
		elseif entity.State == NpcState.STATE_ATTACK then
            if sprite:IsFinished() then
                entity.State = NpcState.STATE_IDLE
				sprite:Play("Idle", true)
            end
            return true
		end



	--[[ Mrs. Beast!!! ]]--
	-- (Yes, I rewrote most of this. No, I don't care. Yes, I will still credit DeadInfinity.)
	elseif entity.Variant == 0 then
		local data = entity:GetData()

		if entity.I2 <= 1 then
			-- First charge
			if not data.DoneFirstMove then
				if entity.State == NpcState.STATE_MOVE then
					data.DoneFirstMove = true
				end

			-- First suck attack
			elseif not data.DoneFirstAttack then
				if entity.State == NpcState.STATE_ATTACK4 then
                    data.DoneFirstAttack = true
                    data.DidLaserLast = true

				-- What is this for?
                elseif entity.State == NpcState.STATE_STOMP then
                    data.DoneFirstAttack = true
                    data.DidLaserLast = false
                end


			-- Finished both
			else
				-- Less idle time
				if entity.State == NpcState.STATE_IDLE then
					local newStateFrame = 20

					-- After double shot or lava ball attack
					if data.LastState == NpcState.STATE_ATTACK3 or data.LastState == NpcState.STATE_STOMP then
						newStateFrame = 60 -- 61 goes to the next state

					-- After switching sides
					elseif data.LastState == NpcState.STATE_ATTACK4 then
						newStateFrame = 40
					end

					-- Set new idle timer
					if not sprite:IsPlaying("BlastEnd") and entity.StateFrame < newStateFrame then
						entity.StateFrame = newStateFrame
					end

					if data.OverrideAttack then
						data.OverrideAttack = nil
					end


				-- Moving
				elseif entity.State == NpcState.STATE_MOVE then
					data.Moving = true
					if entity.StateFrame < 300 then
						entity.StateFrame = 300
					end


				-- Lava ball attack
				elseif entity.State == NpcState.STATE_STOMP then
					-- Check if this is the first one or not
					if not data.DoneFirstLava then
						data.DoneFirstLava = true
						data.IsFirstLava = true
					end

					-- Subsequent ones are faster
					if not data.IsFirstLava and entity.V1.Y < 12 and entity.V1.Y ~= -1 then
						entity.V1 = Vector(entity.V1.X, 12) -- Keeps track of how many have been launched
					end

					-- Surfacing
					if sprite:IsEventTriggered("Shoot") then
						-- Finished the first one
						if data.IsFirstLava then
							data.IsFirstLava = nil
						end

						-- Destroy all stalactites when emerging (otherwise they jarringly disappear when she starts moving)
						for i, stalactie in pairs(Isaac.FindByType(entity.Type, 1, -1, false, false)) do
							stalactie:Kill()
						end
					end


				-- Allow all attacks in all phases
				elseif (entity.State == NpcState.STATE_ATTACK or entity.State == NpcState.STATE_ATTACK3 or entity.State == NpcState.STATE_SUMMON)
				and not data.OverrideAttack then
					data.OverrideAttack = true

					if data.DidLaserLast then
						-- Double shot attack
						if not data.LastNonLaserAttack or data.LastNonLaserAttack == NpcState.STATE_SUMMON then
							entity.State = NpcState.STATE_ATTACK3
							sprite:Play("DoubleShot", true)

						-- Soul attack
						else
							entity.State = NpcState.STATE_SUMMON
							sprite:Play("SoulCall", true)
						end

						data.LastNonLaserAttack = entity.State

					-- Suck attack
					else
						entity.State = NpcState.STATE_ATTACK
						sprite:Play("SuckStart", true)
					end

					data.DidLaserLast = not data.DidLaserLast


				-- Dive for 1st phase non-laser attacks
				elseif entity.State == NpcState.STATE_ATTACK4 and not data.DidLaserLast then
					entity.State = NpcState.STATE_JUMP
					sprite:Play("Dive", true)

				-- Don't dive for 2nd phase laser attack
				elseif entity.State == NpcState.STATE_JUMP and data.DidLaserLast then
					entity.State = NpcState.STATE_ATTACK4
					sprite:Play("MoveStart", true)
				end

				data.LastState = entity.State
			end
		end



	--[[ Falling stalactite hitbox fix ]]--
	elseif entity.Variant == 1 and entity.SubType == 4 and entity.FrameCount <= 0 then
		entity.SizeMulti = Vector(0.1, 0.35)
		entity.PositionOffset = Vector(0, -130)
		entity.Position = entity.Position + Vector(0, 10)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BeastUpdate, EntityType.ENTITY_BEAST)



-- Spawn falling stalactites after the first charge
function mod:StalactiteReplace(type, variant, subtype, position, velocity, spawner, seed)
	if type == EntityType.ENTITY_BEAST and variant == 1 and (subtype == 0 or subtype == 2) and position.Y >= 80 then
		local beast = Isaac.FindByType(EntityType.ENTITY_BEAST, 0)[1]

		if beast:GetData().DoneFirstAttack then
			local beastHP = beast.HitPoints / beast.MaxHitPoints

            local minChance, maxChance = 0.2, 0.8
            local percent = (1 - beastHP) ^ 2
            local chance = mod:Lerp(minChance, maxChance, percent)

            stalactiteRNG:SetSeed(seed, 0)
            if mod:Random(nil, nil, stalactiteRNG) <= chance then
                return {type, variant, 2, seed}
            end
        end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.StalactiteReplace)