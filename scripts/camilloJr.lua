local mod = BetterMonsters
local game = Game()

local Settings = {
	MoveSpeed = 2.5,
	Range = 200,
	Cooldown = 45
}



function mod:camilloJrReplace(entity)
	entity:Morph(EntityType.ENTITY_DEATHS_HEAD, 1, 4230, entity:GetChampionColorIdx())
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.camilloJrReplace, EntityType.ENTITY_CAMILLO_JR)

function mod:camilloJrUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 4230 then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()


		if entity.State == NpcState.STATE_MOVE then
			entity.Velocity = entity.Velocity:Normalized() * Settings.MoveSpeed

			if entity.ProjectileCooldown <= 0 then
				if entity.FrameCount > 20 and entity.Position:Distance(target.Position) <= Settings.Range then
					entity.State = NpcState.STATE_IDLE
					sprite:Play("Attack", true)
				end
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end
			
			-- Face towards the player
			if target.Position.X < entity.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end
		end


		-- Attack
		if sprite:IsEventTriggered("Worm") then
			local worm = Isaac.Spawn(EntityType.ENTITY_VIS, 22, 230, entity.Position, (target.Position - entity.Position):Normalized() * 20, entity)
			worm.Parent = entity
			worm.DepthOffset = entity.DepthOffset + 400

			if not (entity:HasEntityFlags(EntityFlag.FLAG_CHARM) or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then
				local cord = Isaac.Spawn(EntityType.ENTITY_EVIS, 10, 230, entity.Position, Vector.Zero, entity)
				cord.Parent = entity
				cord.Target = worm
				cord.DepthOffset = worm.DepthOffset - 100
				entity:GetData().eyecord = cord
			end

			entity:PlaySound(SoundEffect.SOUND_MEATHEADSHOOT, 1.2, 0, false, 1)

		elseif sprite:IsEventTriggered("Sound") then
			entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 1, 0, false, 1)
			if entity:GetData().eyecord then
				entity:GetData().eyecord:Remove()
			end
		end

		if sprite:GetFrame() == 56 then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.camilloJrUpdate, EntityType.ENTITY_DEATHS_HEAD)