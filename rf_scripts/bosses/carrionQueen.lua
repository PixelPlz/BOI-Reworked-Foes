local mod = ReworkedFoes

local Settings = {
	NewChampionHP = 525,

	ChargeCooldown = 60,
	MaxDistance = 240,
}


function mod:CarrionQueenInit(entity)
	if entity.Variant == 2 and entity.I1 == 0 then
		entity.ProjectileCooldown = Settings.ChargeCooldown / 2

		-- Nerf champion HP
		if entity.SubType == 1 then
			mod:ChangeMaxHealth(entity, Settings.NewChampionHP)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CarrionQueenInit, EntityType.ENTITY_CHUB)

function mod:CarrionQueenUpdate(entity)
	if entity.Variant == 2 and entity.I1 == 0 then
		local room = Game():GetRoom()

		-- Charge diagonally
		if entity.State == NpcState.STATE_MOVE and ((entity.HitPoints > entity.MaxHitPoints * 0.3) or entity.SubType == 1)
		and not mod:IsFeared(entity) and not mod:IsConfused(entity) then
			entity.StateFrame = 1

			if entity.ProjectileCooldown <= 0 then
				local target = entity:GetPlayerTarget()
				local angle = (target.Position - entity.Position):GetAngleDegrees()
				if angle < 0 then
					angle = angle + 360
				end

				-- Check for the target diagonally
				for i = -1, 1 do
					local chargeAngle = entity.Velocity:GetAngleDegrees() + (i * 45)

					if angle > (chargeAngle - 15) and angle < (chargeAngle + 15) -- Lined up
					and target.Position:Distance(entity.Position) <= Settings.MaxDistance -- Not too far away
					and room:CheckLine(target.Position, entity.Position, 0, 0, false, false) then -- Line of sight is not blocked
						entity.State = NpcState.STATE_ATTACK
						entity.V1 = Vector.FromAngle(chargeAngle)
						entity.ProjectileCooldown = Settings.ChargeCooldown
						mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_ROAR_0)
					end
				end

			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end


		-- Make her eat shit
		elseif entity.State == NpcState.STATE_ATTACK then
			local pos = entity.Position + entity.Velocity:Resized(entity.Size * entity.Scale) + entity.Velocity:Resized(15)
			local grid = room:GetGridEntityFromPos(pos)

			if grid and grid:GetType() == GridEntityType.GRID_POOP then
				grid:Hurt(10)
			end


		-- Make the tail not glitch out when shitting
		elseif entity.State == NpcState.STATE_SUMMON then
			if entity.StateFrame == 0 then
				entity.Child.Child.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			elseif entity.StateFrame == 30 then
				entity.Child.Child.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CarrionQueenUpdate, EntityType.ENTITY_CHUB)

-- Make the pink champion able to eat her hearts when charging
function mod:CarrionQueenCollision(entity, target, bool)
	if entity.Variant == 2 and entity:ToNPC().I1 == 0 and entity:ToNPC().State == NpcState.STATE_ATTACK
	and target.Type == EntityType.ENTITY_HEART then
		target:Kill()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.CarrionQueenCollision, EntityType.ENTITY_CHUB)

-- Turn red poops into regular ones on death
function mod:CarrionQueenDeath(entity)
	if entity.Variant == 2 and entity.SubType == 0
	and Isaac.CountEntities(nil, entity.Type, entity.Variant, entity.SubType) <= 1 then
		mod:RemoveRedPoops()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.CarrionQueenDeath, EntityType.ENTITY_CHUB)