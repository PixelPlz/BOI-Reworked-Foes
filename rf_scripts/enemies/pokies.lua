local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 15,
	SideRange = 20,
	FrontRange = 220,
	Cooldown = 5,
	CollisionDamage = 10
}



-- [[ Poky / Slide ]]--
function mod:PokyInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
	entity.Mass = 50

	-- Slide
	if entity.Variant == 1 then
		entity:SetSize(16, Vector.One, 12)

		local gridIndex = Game():GetRoom():GetGridIndex(entity.Position)
		entity.TargetPosition = Game():GetRoom():GetGridPosition(gridIndex)

		entity.ProjectileCooldown = 20
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PokyInit, EntityType.ENTITY_POKY)

function mod:PokyUpdate(entity)
	-- Deactivated
	if entity.State == NpcState.STATE_SPECIAL then
		if entity.StateFrame >= 30 then
			entity:Kill()

		else
			entity.StateFrame = entity.StateFrame + 1
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PokyUpdate, EntityType.ENTITY_POKY)



--[[ Slide ]]--
function mod:SlideUpdate(entity)
	if entity.Variant == 1 then
		local sprite = entity:GetSprite()


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
					mod:PlaySound(entity, SoundEffect.SOUND_GOOATTACH0, 0.6)
				end

				if not sprite:IsPlaying("Wake") then
					mod:LoopingAnim(sprite, "Spikes")

					-- Attack if in range
					local attackCheck = mod:CheckCardinalAlignment(entity, Settings.SideRange, Settings.FrontRange, 0)

					if attackCheck ~= false then
						entity.State = NpcState.STATE_ATTACK
						entity.V1 = Vector.FromAngle(attackCheck)
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
					mod:PlaySound(nil, SoundEffect.SOUND_BONE_BOUNCE, 0.6, 0.85)
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
				mod:PlaySound(nil, SoundEffect.SOUND_STONE_IMPACT, 0.75)

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
				entity.Velocity = mod:Lerp(entity.Velocity, (entity.TargetPosition - entity.Position):Resized(Settings.MoveSpeed / 2), 0.25)
				mod:LoopingAnim(sprite, "No-Spikes")

			else
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
				entity.I2 = 0

				entity.Velocity = Vector.Zero
				entity.Position = entity.TargetPosition
			end
		end


		if entity.FrameCount > 1 and entity.State ~= NpcState.STATE_SPECIAL then
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
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.SlideUpdate, EntityType.ENTITY_POKY)

function mod:SlideCollision(entity, target, bool)
	if entity.Variant == 1 then
		-- Going back
		if entity:GetSprite():IsPlaying("No-Spikes") then
			return false

		-- Colliding with entities
		elseif entity.State == NpcState.STATE_ATTACK and ((target.Type >= 10 and target.Type < 1000) or target.Type == EntityType.ENTITY_PLAYER or target.Type == EntityType.ENTITY_BOMB) then
			entity.I1 = 1

			-- Hurt enemies (except Horseman Heads since they take damage already)
			if target.Type >= 10 and target.Type ~= EntityType.ENTITY_HORSEMAN_HEAD then
				target:TakeDamage(Settings.CollisionDamage, 0, EntityRef(entity), 0)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.SlideCollision, EntityType.ENTITY_POKY)



-- [[ Wall huggers ]]--
function mod:WallHuggerInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_REWARD)
	entity.Mass = 50
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.WallHuggerInit, EntityType.ENTITY_WALL_HUGGER)

function mod:WallHuggerUpdate(entity)
	-- Deactivated
	if entity:GetSprite():GetAnimation() == "No-Spikes" and entity.FrameCount > 30 then
		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.WallHuggerUpdate, EntityType.ENTITY_WALL_HUGGER)



-- [[ Grudge ]]--
function mod:GrudgeInit(entity)
	if entity.Variant == 0 and entity.State == NpcState.STATE_SPECIAL then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_REWARD)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GrudgeInit, EntityType.ENTITY_GRUDGE)

function mod:GrudgeUpdate(entity)
	-- Deactivated
	if entity.Variant == 0 and entity.State == NpcState.STATE_SPECIAL then
		if entity.StateFrame >= 30 then
			entity:Kill()
		else
			entity.StateFrame = entity.StateFrame + 1
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GrudgeUpdate, EntityType.ENTITY_GRUDGE)