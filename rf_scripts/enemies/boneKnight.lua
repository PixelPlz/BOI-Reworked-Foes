local mod = ReworkedFoes

local Settings = {
	SpeedMultiplier = 1.5,
	Cooldown = 15,
	ChargeTime = 45,
	CreepTime = 10,
}



function mod:BoneKnightInit(entity)
	entity:Morph(EntityType.ENTITY_KNIGHT, mod.Entities.BoneKnight, 0, entity:GetChampionColorIdx())

	-- Bestiary fix
	local sprite = entity:GetSprite()
	sprite:ReplaceSpritesheet(2, "")
	sprite:LoadGraphics()
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BoneKnightInit, EntityType.ENTITY_BONE_KNIGHT)

function mod:BoneKnightUpdate(entity)
	if entity.Variant == mod.Entities.BoneKnight then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()

		local anim = "Head"


		-- Reset charge timer
		if entity.State == NpcState.STATE_MOVE and entity.StateFrame > 0 then
			entity.StateFrame = 0
			entity.ProjectileCooldown = Settings.Cooldown


		-- Charging
		elseif entity.State == NpcState.STATE_ATTACK then
			if entity.StateFrame == 1 then
				-- Faster speed when charging
				entity.TargetPosition = entity.TargetPosition * Settings.SpeedMultiplier
				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_YELL_A, 0.8)

				-- Alert other knights
				for i, knight in pairs(Isaac.GetRoomEntities()) do
					if ((knight.Type == EntityType.ENTITY_KNIGHT and knight:ToNPC().Pathfinder:HasPathToPos(target.Position, false)) or knight.Type == EntityType.ENTITY_FLOATING_KNIGHT)
					and knight.Index ~= entity.Index and knight:ToNPC().State == NpcState.STATE_MOVE and knight:ToNPC().ProjectileCooldown <= 0 then
						knight:ToNPC().State = NpcState.STATE_ATTACK
						knight.TargetPosition = mod:ClampVector((target.Position - knight.Position):Normalized(), 90)

						-- Alert effect
						local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, knight.Position, Vector.Zero, entity):ToEffect()
						effect:FollowParent(knight)
						effect.DepthOffset = knight.DepthOffset + 1

						local effectSprite = effect:GetSprite()
						effectSprite.Offset = Vector(0, -40)
						effectSprite:Load("gfx/exclamation mark.anm2", true)
						effectSprite:Play("Default", true)
					end
				end


			-- Stop charging after a set amount of time
			elseif entity.StateFrame >= Settings.ChargeTime then
				entity.State = NpcState.STATE_MOVE
			end

			anim = "Angry"
			if entity:IsFrame(2, 0) then
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 0.5, Settings.CreepTime)
			end

			entity.StateFrame = entity.StateFrame + 1
		end


		-- Head animation
		mod:LoopingOverlay(sprite, anim .. "_" .. sprite:GetAnimation())
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BoneKnightUpdate, EntityType.ENTITY_KNIGHT)