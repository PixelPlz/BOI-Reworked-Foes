local mod = BetterMonsters



function mod:blackBonyInit(entity)
	-- Get random bomb type
	if IRFConfig.blackBonyBombs == true and entity.SubType == 0 then
		entity.SubType = mod:Random(1, 5)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackBonyInit, EntityType.ENTITY_BLACK_BONY)

function mod:blackBonyUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.FrameCount <= 1 then
		-- No bomb effects for friendly ones
		if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			entity.SubType = 0

		-- Bomb costumes
		elseif entity.SubType > 0 then
			local suffix = ""
			if entity:IsChampion() then
				suffix = "_champion"
			end

			-- No spark for cross variant
			if entity.SubType == 1 then
				sprite:ReplaceSpritesheet(2, "")
			end

			sprite:ReplaceSpritesheet(1, "gfx/monsters/better/black boney/277.000_blackboney head_" .. entity.SubType .. suffix .. ".png")
			sprite:LoadGraphics()
		end
	end

	-- Fire effects for Hot Bombs variant
	if entity.SubType == 4 then
		if entity.I2 == 0 then
			mod:LoopingOverlay(sprite, "FireAppear", true)
			if sprite:GetOverlayFrame() == 11 then
				entity.I2 = 1
			end

		else
			mod:LoopingOverlay(sprite, "Fire", true)
			mod:EmberParticles(entity, Vector(0, -40))
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

	-- Bomber Boy
	if entity.SubType == 1 then
		flags = TearFlags.TEAR_CROSS_BOMB

	-- Scatter Bombs
	elseif entity.SubType == 2 then
		flags = TearFlags.TEAR_SCATTER_BOMB

	-- Bob's Curse
	elseif entity.SubType == 3 then
		flags = TearFlags.TEAR_POISON

	-- Hot Bombs
	elseif entity.SubType == 4 then
		flags = TearFlags.TEAR_BURN

	-- Sad Bombs
	elseif entity.SubType == 5 then
		flags = TearFlags.TEAR_SAD_BOMB
	end

	local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
	bomb.Visible = false
	bomb:AddTearFlags(flags)
	bomb:SetExplosionCountdown(0)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackBonyDeath, EntityType.ENTITY_BLACK_BONY)