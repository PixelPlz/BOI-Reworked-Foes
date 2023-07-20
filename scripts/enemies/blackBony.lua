local mod = BetterMonsters



local path = "reworked/monsters/afterbirth/black boney/277.000_blackboney head_"

IRFblackBonyTypes = {
	{effect = TearFlags.TEAR_CROSS_BOMB,   sprite = {spriteType = "sprite", spriteFile = path .. "1"}, hasSpark = false},
	{effect = TearFlags.TEAR_SCATTER_BOMB, sprite = {spriteType = "sprite", spriteFile = path .. "2"}},
	{effect = TearFlags.TEAR_POISON, 	   sprite = {spriteType = "sprite", spriteFile = path .. "3"}},
	{effect = TearFlags.TEAR_BURN, 		   sprite = {spriteType = "sprite", spriteFile = path .. "4"}, hasSpark = false},
	{effect = TearFlags.TEAR_SAD_BOMB, 	   sprite = {spriteType = "sprite", spriteFile = path .. "5"}},
}


-- effect can be either a function or a tear flag (if it's a function it won't explode by default to allow for more flexible behaviour)
-- sprite should be a table with the first value determening if it's a head sprite or anm2 replacement ("sprite" or "anm2"), and the second value being the actual file (the 'gfx/' and '.png' / '.anm2' are included by default)
-- hasSpark is true by default, it can be left out
function mod:AddBlackBonyType(effect, sprite, hasSpark)
	local typeData = {
		effect = effect,
		sprite = {spriteType = sprite[1], spriteFile = sprite[2]},
		hasSpark = hasSpark
	}
	table.insert(IRFblackBonyTypes, typeData)
end



function mod:blackBonyInit(entity)
	-- Get random bomb type
	if entity.SubType == 0 then
		entity.SubType = mod:Random(1, #IRFblackBonyTypes)
	end
end
mod:AddOptionalCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackBonyInit, EntityType.ENTITY_BLACK_BONY, "enemies.blackBony", true)

function mod:blackBonyUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.FrameCount <= 1 then
		-- No bomb effects for friendly ones
		if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			entity.SubType = 0


		-- Bomb costumes
		elseif entity.SubType > 0 then
			local newSprite = IRFblackBonyTypes[entity.SubType].sprite

			-- Animation replacement
			if newSprite.spriteType == "anm2" then
				sprite:Load("gfx/" .. newSprite.spriteFile .. ".anm2", true)

			-- Head sprite replacement
			else
				local suffix = ""
				if entity:IsChampion() then
					suffix = "_champion"
				end

				sprite:ReplaceSpritesheet(1, "gfx/" .. newSprite.spriteFile .. suffix .. ".png")
				sprite:LoadGraphics()
			end

			-- Remove bomb spark for some variants
			if IRFblackBonyTypes[entity.SubType].hasSpark == false then
				sprite:ReplaceSpritesheet(2, "")
			end
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
mod:AddOptionalCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackBonyUpdate, EntityType.ENTITY_BLACK_BONY, "enemies.blackBony")

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
mod:AddOptionalCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackBonyDeath, EntityType.ENTITY_BLACK_BONY, "enemies.blackBony")