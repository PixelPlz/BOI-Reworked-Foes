local mod = BetterMonsters

IRFblackBonyTypes = {
	{effect = TearFlags.TEAR_CROSS_BOMB,   sprite = "1", hasSpark = false},
	{effect = TearFlags.TEAR_SCATTER_BOMB, sprite = "2"},
	{effect = TearFlags.TEAR_POISON, 	   sprite = "3"},
	{effect = TearFlags.TEAR_BURN, 		   sprite = "4", hasSpark = false},
	{effect = TearFlags.TEAR_SAD_BOMB, 	   sprite = "5"},
}

-- effect can be either a function or a tear flag (if it's a function it won't explode by default to allow for more flexible behaviour)
-- sprite format: gfx/monsters/better/black boney/277.000_blackboney head_YourCustomSpriteName.png
-- hasSpark is true by default, can be left out
function mod:AddBlackBonyType(effect, sprite, hasSpark)
	local typeData = {
		effect = effect,
		sprite = sprite,
		hasSpark = hasSpark
	}
	table.insert(IRFblackBonyTypes, typeData)
end



function mod:blackBonyInit(entity)
	-- Get random bomb type
	if IRFConfig.blackBonyBombs == true and entity.SubType == 0 then
		entity.SubType = mod:Random(1, #IRFblackBonyTypes)
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

			-- Remove bomb spark for some variants
			if IRFblackBonyTypes[entity.SubType].hasSpark == false then
				sprite:ReplaceSpritesheet(2, "")
			end

			sprite:ReplaceSpritesheet(1, "gfx/monsters/better/black boney/277.000_blackboney head_" .. IRFblackBonyTypes[entity.SubType].sprite .. suffix .. ".png")
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
	-- Special variants
	if entity.SubType > 0 then
		local effect = IRFblackBonyTypes[entity.SubType].effect

		-- Custom effect
		if type(effect) == "function" then
			effect(entity)

		-- Bomb effect
		else
			local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
			bomb.Visible = false
			bomb:AddTearFlags(effect)
			bomb:SetExplosionCountdown(0)
		end

	-- Default
	else
		local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_NORMAL, 0, entity.Position, Vector.Zero, entity):ToBomb()
		bomb.Visible = false
		bomb:SetExplosionCountdown(0)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackBonyDeath, EntityType.ENTITY_BLACK_BONY)