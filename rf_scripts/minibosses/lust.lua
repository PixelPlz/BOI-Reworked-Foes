local mod = ReworkedFoes

local Settings = {
	ChaseSpeed = 11,
	CreepTime = 100,
	TouchHeal = 10,

	-- Item effects
	LargerScale = 1.15,
	FasterSpeed = 12.5,
	HealthUpMulti = {1.15, 1.3},

	LemonPartyCount = 3,
	LemonPartySize = 3,
	LemonPartyTime = 240,
}



-- Add's the effect to the specified variant and subtype's pool of effects
-- 'OnUseScript' is ran once when the item is used. Can be left as nil.
-- 'UpdateScript' is ran every update frame after the item is used. Can be left as nil.
-- 'UseSound' is the announcer line played alongside the pill/card sound
-- 'Anim' is the custom animation it should play when using the item. Can be left as nil.
-- 'Sprite' is the 32x32 spritesheet of the item that gets loaded. Can be left as nil. Not needed if a custom animation is defined.
function mod:AddLustEffect(Variant, Subtype, OnUseScript, UpdateScript, UseSound, Anim, Sprite)
	local typeData = {
		Activate = OnUseScript,
		Passive  = UpdateScript,
		SFX 	 = UseSound,
		Anim 	 = Anim,
		Sprite   = Sprite,
	}

	if not mod.LustEffects[Variant] then
		mod.LustEffects[Variant] = {}
	end
	if not mod.LustEffects[Variant][Subtype] then
		mod.LustEffects[Variant][Subtype] = {}
	end
	table.insert(mod.LustEffects[Variant][Subtype], typeData)
end



--[[ Effect functions ]]--
-- One makes you larger
function mod:LustOneMakesYouLarger(entity)
	entity.Scale = entity.Scale * Settings.LargerScale
	entity:GetData().tryGoOverObstacles = true
	entity.Pathfinder:SetCanCrushRocks(true)

	-- Ignore knockback
	if entity.Variant == 1 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end

function mod:LustCrushRocks(entity)
	local room = Game():GetRoom()
	local vector = entity.Velocity:Resized(entity.Scale * entity.Size) + entity.Velocity:Resized(15)

	for i = -1, 1 do
		local pos = entity.Position + vector:Rotated(i * 20)
		room:DestroyGrid(room:GetGridIndex(pos), true)
	end
end


-- Pretty fly
function mod:LustPrettyFly(entity)
	for i = 1, 1 + entity.Variant do
		Isaac.Spawn(EntityType.ENTITY_ETERNALFLY, 0, 0, entity.Position, Vector.Zero, entity).Parent = entity
	end
end


-- Speed up
function mod:LustSpeedUp(entity)
	entity:GetData().speedUp = true

	-- Set color
	local color = mod:ColorEx({1,1,1, 1},   {1,1,0, 0.4})
	entity:SetColor(color, -1, 0, false, false)
end


-- Health up
function mod:LustHealthUp(entity)
	local multi = Settings.HealthUpMulti[entity.Variant + 1]
	entity.MaxHitPoints = entity.MaxHitPoints * multi
	entity.HitPoints = entity.HitPoints * multi

	-- Set color
	local color = mod:ColorEx({1,1,1, 1},   {1,0.5,0, 0.4})
	entity:SetColor(color, -1, 0, false, false)
end


-- Lemon party
function mod:LustLemonParty(entity)
	if entity.HitPoints <= entity.MaxHitPoints - (entity.MaxHitPoints / (Settings.LemonPartyCount + 1)) * (entity.I2 + 1)
	and not entity:IsDead() then
		entity.I2 = entity.I2 + 1

		-- Super
		if entity.Variant == 1 then
			local offset = mod:Random(359)
			for i = -1, 1, 2 do
				local pos = entity.Position + Vector.FromAngle(offset + i * 90):Resized(25)
				mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, pos, Settings.LemonPartySize, Settings.LemonPartyTime)
			end

		-- Regular
		else
			mod:QuickCreep(EffectVariant.CREEP_YELLOW, entity, entity.Position, Settings.LemonPartySize, Settings.LemonPartyTime)
		end

		-- Effects
		mod:PlaySound(nil, SoundEffect.SOUND_GASCAN_POUR, 0.9)
		mod:PlaySound(nil, SoundEffect.SOUND_SINK_DRAIN_GURGLE)
		mod:ShootEffect(entity, 3, Vector.Zero, Color(0,0,0, 1, 1,1,0), entity.Scale, true)
	end
end



--[[ Define the effects ]]--
mod.LustEffects = {
	-- Regular
	[0] = { -- Variant
		[0] = { -- Subtype
			{ SFX = SoundEffect.SOUND_LARGER, 	   Anim = "OneMakesYouLarger", Activate = mod.LustOneMakesYouLarger, Passive = mod.LustCrushRocks },
			{ SFX = SoundEffect.SOUND_PRETTY_FLY,  Anim = "PrettyFly", 		   Activate = mod.LustPrettyFly },
			{ SFX = SoundEffect.SOUND_SPEED_UP,    Anim = "SpeedUp", 		   Activate = mod.LustSpeedUp },
			{ SFX = SoundEffect.SOUND_HP_UP, 	   Anim = "HealthUp", 		   Activate = mod.LustHealthUp },
			{ SFX = SoundEffect.SOUND_LEMON_PARTY, Anim = "LemonParty", 	   Passive  = mod.LustLemonParty },
		},
	},

	-- Super Lust
	[1] = { -- Variant
		[0] = { -- Subtype
			{ SFX = SoundEffect.SOUND_MEGA_ONE_MAKES_YOU_LARGER, Anim = "OneMakesYouLarger", Activate = mod.LustOneMakesYouLarger, Passive = mod.LustCrushRocks },
			{ SFX = SoundEffect.SOUND_MEGA_PRETTY_FLY, 			 Anim = "PrettyFly", 		 Activate = mod.LustPrettyFly },
			{ SFX = SoundEffect.SOUND_MEGA_SPEED_UP, 			 Anim = "SpeedUp", 			 Activate = mod.LustSpeedUp },
			{ SFX = SoundEffect.SOUND_MEGA_HEALTH_UP, 			 Anim = "HealthUp", 		 Activate = mod.LustHealthUp },
			{ SFX = SoundEffect.SOUND_MEGA_LEMON_PARTY, 		 Anim = "LemonParty", 		 Passive  = mod.LustLemonParty },
		},
	},
}



function mod:LustUpdate(entity)
	if mod:CheckValidMiniboss(entity) then
		local sprite = entity:GetSprite()
		local target = entity:GetPlayerTarget()
		local data = entity:GetData()


		-- Chasing
		if entity.State == NpcState.STATE_MOVE then
			-- This sucks
			local speed = Settings.ChaseSpeed
			if data.speedUp then
				speed = Settings.FasterSpeed
			end

			-- Reverse movement if feared
			if mod:IsFeared(entity) then
				speed = -speed
			end

			-- Move randomly if confused
			if mod:IsConfused(entity) then
				mod:WanderAround(entity, speed / 2)

			else
				-- If there is a path to the player
				if entity.Pathfinder:HasPathToPos(target.Position) or data.tryGoOverObstacles then
					local checkLineMode = data.tryGoOverObstacles and 2 or 1

					-- If there is a direct line to the player
					if Game():GetRoom():CheckLine(entity.Position, target.Position, checkLineMode, 0, false, false) then
						entity.Velocity = mod:Lerp(entity.Velocity, (target.Position - entity.Position):Resized(speed), 0.06)
					else
						entity.Pathfinder:FindGridPath(target.Position, speed / 13, 500, false)
					end

				-- Otherwise stay still
				else
					entity.Velocity = mod:StopLerp(entity.Velocity, 0.05)
				end
			end

			-- Hanged Man effect
			if data.hanged then
				mod:LoopingAnim(sprite, "Float")
				mod:FlipTowardsMovement(entity, sprite)

				if entity:IsFrame(10, 0) then
					entity:MakeSplat(0.75)
				end

			else
				entity:AnimWalkFrame("WalkHori", "WalkVert", 0.1)
			end


		-- Using item
		elseif entity.State == NpcState.STATE_ATTACK then
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if sprite:IsEventTriggered("Use") then
				local array = mod.LustEffects[entity.Variant][entity.SubType][entity.I1]
				data.passiveEffect = array.Passive

				-- SFX
				if array.SFX then
					mod:PlaySound(nil, array.SFX, 1.1)
				end

				-- On-use effect
				if array.Activate then
					array.Activate(_, entity)
				end


				-- Additional effects
				-- Champion
				if mod:IsRFChampion(entity, "Lust") then
					mod:PlaySound(nil, SoundEffect.SOUND_BOOK_PAGE_TURN_12)
				-- Super
				elseif entity.Variant == 1 then
					mod:PlaySound(nil, SoundEffect.SOUND_POWERUP_SPEWER_AMPLIFIED)
				-- Regular
				else
					mod:PlaySound(nil, SoundEffect.SOUND_POWERUP_SPEWER)
				end
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
			end


		-- Use an item at the beginning of the fight
		elseif entity.FrameCount > 1 and entity.State == NpcState.STATE_INIT then
			entity.State = NpcState.STATE_ATTACK

			entity.I1 = mod:Random(1, #mod.LustEffects[entity.Variant][entity.SubType])
			local array = mod.LustEffects[entity.Variant][entity.SubType][entity.I1]
			local anim = "UseCustom"

			-- Custom animation
			if array.Anim then
				anim = "Use" .. array.Anim
			end

			-- Default animation with different sprite
			if array.Sprite then
				sprite:ReplaceSpritesheet(2, array.Sprite)
				sprite:LoadGraphics()
			end

			sprite:Play(anim, true)
		end


		-- Super Lust creep
		if entity.Variant == 1 and entity:IsFrame(4, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, entity.Scale, Settings.CreepTime)
		end


		-- Run passive effect code
		if data.passiveEffect then
			data.passiveEffect(_, entity)
		end


		-- Disable default AI (has to be disabled from frame 0 otherwise FindGridPath doesn't work for her)
		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.LustUpdate, EntityType.ENTITY_LUST)



-- Hermit effect
function mod:LustHit(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_LUST and damageSource.Entity and damageSource.Entity:GetData().greedy then
		local player = entity:ToPlayer()

		-- Remove coins
		local amount = math.min(player:GetNumCoins(), mod:Random(2, 4))
		player:AddCoins(-amount)

		if amount > 1 then
			local dropAmount = mod:Random(amount - 2)
			for i = 0, dropAmount do
				Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, player.Position, mod:RandomVector(mod:Random(4, 6)), player)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.LustHit, EntityType.ENTITY_PLAYER)



function mod:ChampionLustReward(pickup)
	if mod:CheckMinibossDropReplacement(pickup, EntityType.ENTITY_LUST, "Lust") then
		-- Card Reading
		if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and pickup.SubType ~= CollectibleType.COLLECTIBLE_CARD_READING then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_CARD_READING, false, true, false)

		-- Cards
		elseif pickup.Variant == PickupVariant.PICKUP_PILL then
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, 0, false, true, false)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.ChampionLustReward)