local mod = BetterMonsters
local game = Game()



function mod:blackBonyInit(entity)
	-- Get random bomb type
	if entity.SubType == 0 then
		local canBrim = 5
		-- There can only be one brimstone one per room
		if Isaac.CountEntities(nil, EntityType.ENTITY_BLACK_BONY, -1, 6) == 0 then
			canBrim = 6
		end
		entity.SubType = math.random(1, canBrim)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackBonyInit, EntityType.ENTITY_BLACK_BONY)

function mod:blackBonyUpdate(entity)
	local sprite = entity:GetSprite()

	-- Custom attack
	if entity.State == NpcState.STATE_ATTACK then
		entity.State = NpcState.STATE_ATTACK2

	elseif entity.State == NpcState.STATE_ATTACK2 then
		entity.Velocity = Vector.Zero
		if sprite:IsEventTriggered("Shoot") then
			local vector = Vector.Zero
			local angleDegrees = (entity:GetPlayerTarget().Position - entity.Position):GetAngleDegrees()
			if angleDegrees > -45 and angleDegrees < 45 then
				vector = Vector(1, 0)
			elseif angleDegrees >= 45 and angleDegrees <= 135 then
				vector = Vector(0, 1)
			elseif angleDegrees < -45 and angleDegrees > -135 then
				vector = Vector(0, -1)
			else
				vector = Vector(-1, 0)
			end

			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_BONE
			params.Color = Color(0.25,0.25,0.25, 1)
			entity:FireProjectiles(entity.Position, vector * 10, 0, params)
			entity:PlaySound(SoundEffect.SOUND_SCAMPER, 1.3, 0, false, 1)
		end

		if sprite:IsFinished(sprite:GetAnimation()) then
			entity.State = NpcState.STATE_MOVE
		end
	end

	-- Bomb overlay
	if entity.SubType > 0 then
		local type = "Cross"
		if entity.SubType == 2 then
			type = "Scatter"
		elseif entity.SubType == 3 then
			type = "Poison"
		elseif entity.SubType == 4 then
			type = "Hot"
		elseif entity.SubType == 5 then
			type = "Sad"
		elseif entity.SubType == 6 then
			type = "Brimstone"
		end

		if IRFconfig.blackBonyCostumes == false then
			if not sprite:IsOverlayPlaying("Bomb" .. type) then
				entity:GetSprite():PlayOverlay("Bomb" .. type, true)
			end
		
		elseif entity.FrameCount <= 1 then
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

	-- Death animation
	if entity:HasMortalDamage() then
		entity.State = NpcState.STATE_DEATH
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.blackBonyUpdate, EntityType.ENTITY_BLACK_BONY)

function mod:blackBonyDeath(entity)
	local type = BombVariant.BOMB_NORMAL
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
		type = BombVariant.BOMB_BRIMSTONE
	end

	local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, type, 0, entity.Position, Vector.Zero, entity):ToBomb()
	bomb:AddTearFlags(flags)
	bomb:SetExplosionCountdown(0)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackBonyDeath, EntityType.ENTITY_BLACK_BONY)