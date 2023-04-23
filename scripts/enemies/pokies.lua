local mod = BetterMonsters

local Settings = {
	MoveSpeed = 15,
	SideRange = 20,
	FrontRange = 220,
	Cooldown = 5
}



-- [[ Poky / Slide ]]--
function mod:pokyInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.Mass = 50

	if entity.Variant == 1 then
		entity:SetSize(16, Vector(1, 1), 12)

		local gridIndex = Game():GetRoom():GetGridIndex(entity.Position)
		entity.TargetPosition = Game():GetRoom():GetGridPosition(gridIndex)

		entity.ProjectileCooldown = 30
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.pokyInit, EntityType.ENTITY_POKY)

function mod:pokyUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.pokyUpdate, EntityType.ENTITY_POKY)

-- Slide
function mod:slideUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		-- Waiting
		if entity.State == NpcState.STATE_MOVE then
			entity.Velocity = Vector.Zero
			entity.Position = entity.TargetPosition

			-- Cooldown
			if entity.I2 == 0 then
				mod:LoopingAnim(sprite, "No-Spikes")

				if entity.ProjectileCooldown <= 0 then
					entity.I2 = 1
					sprite:Play("Wake", true)
				else
					entity.ProjectileCooldown = entity.ProjectileCooldown - 1
				end
			
			-- Ready
			elseif entity.I2 == 1 then
				if sprite:IsEventTriggered("Sound") then
					entity:PlaySound(SoundEffect.SOUND_GOOATTACH0, 0.6, 0, false, 1)
				end

				if not sprite:IsPlaying("Wake") then
					mod:LoopingAnim(sprite, "Spikes")

					-- Attack if in range
					if Game():GetRoom():CheckLine(entity.Position, target.Position, 0, 0, false, false) then
						-- Horizontal
						if entity.Position.Y <= target.Position.Y + Settings.SideRange and entity.Position.Y >= target.Position.Y - Settings.SideRange then
							if target.Position.X > (entity.Position.X - Settings.FrontRange) and target.Position.X < entity.Position.X then
								entity.V1 = Vector(-1, 0)
								entity.State = NpcState.STATE_ATTACK

							elseif target.Position.X < (entity.Position.X + Settings.FrontRange) and target.Position.X > entity.Position.X then
								entity.V1 = Vector(1, 0)
								entity.State = NpcState.STATE_ATTACK
							end

						-- Vertical
						elseif entity.Position.X <= target.Position.X + Settings.SideRange and entity.Position.X >= target.Position.X - Settings.SideRange then
							if target.Position.Y > (entity.Position.Y - Settings.FrontRange) and target.Position.Y < entity.Position.Y then
								entity.V1 = Vector(0, -1)
								entity.State = NpcState.STATE_ATTACK

							elseif target.Position.Y < (entity.Position.Y + Settings.FrontRange) and target.Position.Y > entity.Position.Y then
								entity.V1 = Vector(0, 1)
								entity.State = NpcState.STATE_ATTACK
							end
						end
					end
				end
			end


		-- Attacking
		elseif entity.State == NpcState.STATE_ATTACK then
			-- Better "collision" with othe Slides and Poky variants
			local entitiesInPath = Isaac.FindInRadius(entity.Position + entity.Velocity, entity.Size, EntityPartition.ENEMY)
			for i, other in pairs(entitiesInPath) do
				if (other.Type == entity.Type and other.Index ~= entity.Index) or other.Type == EntityType.ENTITY_WALL_HUGGER or other.Type == EntityType.ENTITY_GRUDGE then
					entity.I1 = 1
					SFXManager():Play(SoundEffect.SOUND_BONE_BOUNCE, 0.6, 0, false, 0.85)
				end
			end

			-- Grid collision
			if entity:CollidesWithGrid() then
				entity.I1 = 1
			end

			-- Stop
			if entity.I1 == 1 then
				entity.State = NpcState.STATE_STOMP
				sprite:Play("Sleep", true)
				SFXManager():Play(SoundEffect.SOUND_STONE_IMPACT, 0.75)

				entity.V2 = entity.Position
				entity.Velocity = Vector.Zero
				entity.I1 = 0

			else
				entity.Velocity = mod:Lerp(entity.Velocity, entity.V1 * Settings.MoveSpeed, 0.25)
			end


		-- Stopped
		elseif entity.State == NpcState.STATE_STOMP then
			entity.Velocity = Vector.Zero
			entity.Position = entity.V2

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_JUMP
			end


		-- Returning
		elseif entity.State == NpcState.STATE_JUMP then
			if entity.Position:Distance(entity.TargetPosition) > 6 then
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Normalized() * Settings.MoveSpeed / 2, 0.25)
				mod:LoopingAnim(sprite, "No-Spikes")

			else
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I2 = 0

				entity.Velocity = Vector.Zero
				entity.Position = entity.TargetPosition
			end
		end


		if entity.FrameCount > 1 and entity.State ~= 16 then 
			-- Disable if a player has Flat File or all pressure plates are pressed
			local hasFlatFile = false
			for i = 0, Game():GetNumPlayers() - 1 do
				if Isaac.GetPlayer(i):HasTrinket(TrinketType.TRINKET_FLAT_FILE, false) then
					hasFlatFile = true
					break
				end
			end

			if hasFlatFile == true or Game():GetLevel():GetCurrentRoomDesc().PressurePlatesTriggered == true then
				entity.State = NpcState.STATE_SPECIAL
			end

			-- Disable default AI
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.slideUpdate, EntityType.ENTITY_POKY)

function mod:slideCollision(entity, target, cock)
	if entity.Variant == 1 then
		-- Going back
		if entity:GetSprite():IsPlaying("No-Spikes") then
			return false

		-- Colliding with entities
		elseif entity.State == NpcState.STATE_ATTACK and ((target.Type >= 10 and target.Type < 1000) or target.Type == EntityType.ENTITY_PLAYER or target.Type == EntityType.ENTITY_BOMB) then
			entity.I1 = 1

			-- Hurt enemies (Horseman Head takes damage by default)
			if target.Type >= 10 and target.Type ~= EntityType.ENTITY_HORSEMAN_HEAD then
				target:TakeDamage(10, 0, EntityRef(entity), 0)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.slideCollision, EntityType.ENTITY_POKY)



-- [[ Wall huggers ]]--
function mod:wallHuggerInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.Mass = 50
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.wallHuggerInit, EntityType.ENTITY_WALL_HUGGER)

function mod:wallHuggerUpdate(entity)
	if entity:GetSprite():GetAnimation() == "No-Spikes" and entity.FrameCount > 30 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wallHuggerUpdate, EntityType.ENTITY_WALL_HUGGER)



-- [[ Grudge ]]--
function mod:grudgeUpdate(entity)
	if entity.State == NpcState.STATE_SPECIAL and entity.Variant == 0 then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.grudgeUpdate, EntityType.ENTITY_GRUDGE)