local mod = BetterMonsters
local game = Game()



--[[ Scarred Guts ]]--
function mod:scarredGutsDeath(entity)
	if entity.Variant == 1 then
		local flesh = Isaac.Spawn(EntityType.ENTITY_LEPER, 1, 0, entity.Position, entity.Velocity * 0.6, entity):ToNPC()
		flesh.State = NpcState.STATE_INIT
		if entity:IsChampion() then
			flesh:MakeChampion(1, entity:GetChampionColorIdx(), true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.scarredGutsDeath, EntityType.ENTITY_GUTS)



--[[ Fistula Scarred Womb skin ]]--
local function fistulaScarredSkin(entity)
	if entity.Variant == 0 then
		if entity.SubType == 0 and game:GetRoom():GetBackdropType() == BackdropType.SCARRED_WOMB then
			entity.SubType = 1000 -- The subtype that Matriarch fistula pieces use
		end

		if entity.SubType == 1000 then
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_025_fistula_scarred.png")
			sprite:LoadGraphics()
		end
	end
end

function mod:fistulaBigInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaBigInit, EntityType.ENTITY_FISTULA_BIG)

function mod:fistulaMediumInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaMediumInit, EntityType.ENTITY_FISTULA_MEDIUM)

function mod:fistulaSmallInit(entity)
	fistulaScarredSkin(entity)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fistulaSmallInit, EntityType.ENTITY_FISTULA_SMALL)



--[[ Gurglings ]]--
function mod:gurglingsUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.gurglingsUpdate, EntityType.ENTITY_GURGLING)