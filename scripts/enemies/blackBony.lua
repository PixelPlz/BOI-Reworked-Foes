local mod = BetterMonsters



function mod:blackBonyInit(entity)
	-- Get random bomb type
	if entity.SubType == 0 then
		if Isaac.CountEntities(nil, EntityType.ENTITY_BLACK_BONY, -1, 6) == 0 and math.random(1, 100) <= 10 then
			entity.SubType = 6
		else
			entity.SubType = math.random(1, 5)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackBonyInit, EntityType.ENTITY_BLACK_BONY)

function mod:blackBonyUpdate(entity)
	local sprite = entity:GetSprite()
	
	if entity.FrameCount <= 1 then
		if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			entity.SubType = 0
		end
		
		-- Bomb costume
		if entity.SubType > 0 then
			local suffix = ""
			if entity:IsChampion() then
				suffix = "_champion"
			end
			-- No spark for cross and brimstone variants
			if entity.SubType == 1 or entity.SubType == 6 then
				sprite:ReplaceSpritesheet(2, "")
			end

			sprite:ReplaceSpritesheet(1, "gfx/monsters/better/black boney/277.000_blackboney head_" .. entity.SubType .. suffix .. ".png")
			sprite:LoadGraphics()
		end
	end


	-- Only attack once
	if entity.State == NpcState.STATE_ATTACK then
		entity.StateFrame = 2
	end


	-- Death animation
	if entity:HasMortalDamage() then
		sprite:Play("Death", true)
		entity.State = NpcState.STATE_DEATH
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackBonyUpdate, EntityType.ENTITY_BLACK_BONY)

function mod:blackBonyDeath(entity)
	local flags = TearFlags.TEAR_NORMAL

	if entity.SubType == 1 then
		flags = TearFlags.TEAR_CROSS_BOMB
	elseif entity.SubType == 2 then
		flags = TearFlags.TEAR_SCATTER_BOMB
	elseif entity.SubType == 3 then
		flags = TearFlags.TEAR_POISON
	elseif entity.SubType == 4 then
		flags = TearFlags.TEAR_BURN
	elseif entity.SubType == 5 then
		flags = TearFlags.TEAR_SAD_BOMB
	elseif entity.SubType == 6 then
		flags = TearFlags.TEAR_BRIMSTONE_BOMB
	end

	local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
	bomb.Visible = false
	bomb:AddTearFlags(flags)
	bomb:SetExplosionCountdown(0)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackBonyDeath, EntityType.ENTITY_BLACK_BONY)