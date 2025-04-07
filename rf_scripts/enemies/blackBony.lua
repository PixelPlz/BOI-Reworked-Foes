local mod = ReworkedFoes

local path = "gfx/monsters/better/black boney/277.000_blackboney head_"

mod.BlackBonyTypes = {
	{ Effect = TearFlags.TEAR_CROSS_BOMB, 	SpriteFile = path .. "1", HasSpark = false },
	{ Effect = TearFlags.TEAR_SCATTER_BOMB, SpriteFile = path .. "2" },
	{ Effect = TearFlags.TEAR_POISON, 		SpriteFile = path .. "3" },
	{ Effect = TearFlags.TEAR_BURN, 		SpriteFile = path .. "4", HasSpark = false },
	{ Effect = TearFlags.TEAR_SAD_BOMB, 	SpriteFile = path .. "5" },
}



-- 'Effect' can be either a function or a tear flag (if it's a function it won't explode by default to allow for more flexible behaviour)
-- If 'SpriteType' is set to ".anm2" then the specified 'SpriteFile' will be loaded as an animation file, otherwise it will be loaded as a spritesheet.
	-- The file type should be left out from 'SpriteFile' so the proper champion spritesheets can be loaded!
-- 'HasSpark' is true by default and can be left out (it also doesn't do anything for anm2 replacements)
function mod:AddBlackBonyType(Effect, SpriteType, SpriteFile, HasSpark)
	local typeData = {
		Effect 	   = Effect,
		SpriteType = SpriteType,
		SpriteFile = SpriteFile,
		HasSpark   = HasSpark,
	}
	table.insert(mod.BlackBonyTypes, typeData)
end



function mod:BlackBonyInit(entity)
	-- Set a random bomb type
	if mod.Config.BlackBonyBombs and entity.SubType == 0 then
		local rng = RNG()
		rng:SetSeed(entity.InitSeed, 35)
		entity.SubType = mod:Random(1, #mod.BlackBonyTypes, rng)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.BlackBonyInit, EntityType.ENTITY_BLACK_BONY)

function mod:BlackBonyUpdate(entity)
	local sprite = entity:GetSprite()

	-- Prevent friendly ones from having bomb effects
	if entity.FrameCount <= 1 and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		entity.SubType = 0
	end


	local entry = mod.BlackBonyTypes[entity.SubType]

	if entry then
		-- Bomb costumes
		if entity.FrameCount <= 1 then
			-- Animation replacement
			if entry.SpriteType and entry.SpriteType == "anm2" then
				sprite:Load(entry.SpriteFile .. "anm2", true)


			-- Head sprite replacement
			else
				local suffix = ""

				if entity:IsChampion() then
					suffix = "_champion"
				end
				sprite:ReplaceSpritesheet(1, entry.SpriteFile .. suffix .. ".png")

				-- Remove bomb spark for some variants
				if entry.HasSpark == false then
					sprite:ReplaceSpritesheet(2, "")
				end
				sprite:LoadGraphics()
			end
		end


		-- Fire effects for Hot Bombs variant
		if entry.Effect == TearFlags.TEAR_BURN then
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
	end


	-- Only shoot once
	if entity.State == NpcState.STATE_ATTACK then
		entity.StateFrame = 2
	end


	-- Death effects
	if entity.State == NpcState.STATE_SPECIAL then
		entity.Velocity = Vector.Zero

		if sprite:IsFinished() then
			-- Special variants
			if entry then
				local effect = entry.Effect

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

			entity:Kill()
			return true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.BlackBonyUpdate, EntityType.ENTITY_BLACK_BONY)

-- Start the death animation
function mod:BlackBonyRender(entity, offset)
	if mod:ShouldDoRenderEffects()
	and entity:HasMortalDamage() and entity.State ~= NpcState.STATE_SPECIAL then
		entity.State = NpcState.STATE_SPECIAL
		entity:GetSprite():Play("Death", true)

		entity.HitPoints = 1000
		entity.MaxHitPoints = 0
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		entity.Visible = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.BlackBonyRender, EntityType.ENTITY_BLACK_BONY)