local mod = ReworkedFoes

local path = "monsters/better/black boney/277.000_blackboney head_"

mod.BlackBonyTypes = {
	{effect = TearFlags.TEAR_CROSS_BOMB,   spriteFile = path .. "1", hasSpark = false},
	{effect = TearFlags.TEAR_SCATTER_BOMB, spriteFile = path .. "2"},
	{effect = TearFlags.TEAR_POISON, 	   spriteFile = path .. "3"},
	{effect = TearFlags.TEAR_BURN, 		   spriteFile = path .. "4", hasSpark = false},
	{effect = TearFlags.TEAR_SAD_BOMB, 	   spriteFile = path .. "5"},
}



-- effect can be either a function or a tear flag (if it's a function it won't explode by default to allow for more flexible behaviour)
-- sprite should be a table with the first value determening if it's a head sprite or anm2 replacement ("sprite" or "anm2"), and the second value being the actual file (the 'gfx/' and '.png' / '.anm2' are included by default)
-- hasSpark is true by default, it can be left out (it also doesn't do anything for anm2 replacements)
function mod:AddBlackBonyType(effect, spriteType, spriteFile, hasSpark)
	local typeData = {
		effect 	   = effect,
		spriteType = spriteType,
		spriteFile = spriteFile,
		hasSpark   = hasSpark
	}
	table.insert(mod.BlackBonyTypes, typeData)
end



function mod:BlackBonyInit(entity)
	-- Get random bomb type
	if mod.Config.BlackBonyBombs == true and entity.SubType == 0 then
		entity.SubType = mod:Random(1, #mod.BlackBonyTypes)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlackBonyInit, EntityType.ENTITY_BLACK_BONY)

function mod:BlackBonyUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.FrameCount <= 1 then
		-- No bomb effects for friendly ones
		if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			entity.SubType = 0


		-- Bomb costumes
		elseif entity.SubType > 0 then
			local entry = mod.BlackBonyTypes[entity.SubType]

			-- Animation replacement
			if entry.spriteType and entry.spriteType == "anm2" then
				sprite:Load("gfx/" .. entry.spriteFile .. ".anm2", true)


			-- Head sprite replacement
			else
				local suffix = ""
				if entity:IsChampion() then
					suffix = "_champion"
				end

				sprite:ReplaceSpritesheet(1, "gfx/" .. entry.spriteFile .. suffix .. ".png")

				-- Remove bomb spark for some variants
				if entry.hasSpark == false then
					sprite:ReplaceSpritesheet(2, "")
				end

				sprite:LoadGraphics()
			end
		end
	end


	-- Fire effects for Hot Bombs variant
	if entity.SubType > 0 and mod.BlackBonyTypes[entity.SubType].effect == TearFlags.TEAR_BURN then
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
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BlackBonyUpdate, EntityType.ENTITY_BLACK_BONY)

function mod:BlackBonyRender(entity, offset)
	if mod:ShouldDoRenderEffects() then
		local sprite = entity:GetSprite()
		local data = entity:GetData()


		-- Start the death animation
		if entity:IsDead() and entity.State ~= NpcState.STATE_UNIQUE_DEATH then
			sprite:Play("Death", true)
			entity:KillUnique()
			entity.Visible = true


		-- Death effects
		elseif sprite:IsFinished("Death") and not data.DeathEffects then
			data.DeathEffects = true

			-- Special variants
			if entity.SubType > 0 then
				local effect = mod.BlackBonyTypes[entity.SubType].effect

				-- Custom effect
				if type(effect) == "function" then
					effect(_, entity)

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
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.BlackBonyRender, EntityType.ENTITY_BLACK_BONY)