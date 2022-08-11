local mod = BetterMonsters
local game = Game()



function mod:chubberInit(entity)
	if entity.Variant == 22 then
		entity.Mass = 0
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS)
		entity:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		entity.MaxHitPoints = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.chubberInit, EntityType.ENTITY_VIS)

function mod:chubberUpdate(entity)
	if entity.Variant == 2 or (entity.Variant == 22 and entity.SpawnerType == EntityType.ENTITY_VIS) then
		local sprite = entity:GetSprite()

		-- Alt skin
		if entity.FrameCount <= 20 then
			local level = game:GetLevel()
			
			-- Which file to use
			local ischamp = ""
			if entity:IsChampion() == true then
				ischamp = "_champion"
			end
			local skin = "chubberworm_ashpit"
			if entity.Variant == 2 then
				skin = "monster_181_chubber_ashpit" .. ischamp
			end

			if ((level:GetStage() == LevelStage.STAGE3_1 or level:GetStage() == LevelStage.STAGE3_2) and level:GetStageType() == StageType.STAGETYPE_WOTL)
			or ((level:GetStage() == LevelStage.STAGE2_1 or level:GetStage() == LevelStage.STAGE2_2) and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B) then
				for i = 0, sprite:GetLayerCount() - 1 do
					sprite:ReplaceSpritesheet(i, "gfx/monsters/classic/" .. skin .. ".png")
				end
				sprite:LoadGraphics()
			end
		end

		-- Sounds + extra effects
		if entity.Variant == 2 then
			if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 62 then
				entity:PlaySound(SoundEffect.SOUND_MEAT_JUMPS, 0.9, 0, false, 1)
				
				-- Blood effect
				if sprite:IsEventTriggered("Shoot") then
					local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_EXPLOSION, 2, entity.Position, Vector.Zero, entity):ToEffect()
					effect:GetSprite().Offset = Vector(0, -12)
					effect.SpriteScale = Vector(0.85, 0.85)
					effect.DepthOffset = entity.DepthOffset - 10
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.chubberUpdate, EntityType.ENTITY_VIS)