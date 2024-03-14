local mod = ReworkedFoes



--[[ Monstro 2 and Gish ]]--
-- Reduce their HP
function mod:Monstro2Init(entity)
	local newHealth = 540
	if entity.SubType == 1 then
		newHealth = 460
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.Monstro2Init, EntityType.ENTITY_MONSTRO2)

-- Death effects
function mod:Monstro2Render(entity, offset)
	if mod:ShouldDoRenderEffects() then
        local sprite = entity:GetSprite()
		local data = entity:GetData()

        if sprite:IsPlaying("Death") and sprite:IsEventTriggered("Explosion")
		and not data.DeathEffects then
			data.DeathEffects = true

			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LARGE_BLOOD_EXPLOSION, 0, entity.Position, Vector.Zero, entity):GetSprite().Color = entity.SplatColor
			mod:PlaySound(nil, SoundEffect.SOUND_ROCKET_BLAST_DEATH)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.Monstro2Render, EntityType.ENTITY_MONSTRO2)



--[[ Increase Pestilence's HP ]]--
function mod:PestilenceInit(entity)
	entity.MaxHitPoints = 360
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PestilenceInit, EntityType.ENTITY_PESTILENCE)



--[[ Death ]]--
-- Better Scythes
function mod:ScytheInit(entity)
	if entity.Variant == 10 then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
		entity.Mass = 1
		mod:PlaySound(nil, SoundEffect.SOUND_TOOTH_AND_NAIL, 0.9)

		-- Get the parent's subtype
		if entity.SubType == 0 and entity.SpawnerEntity and entity.SpawnerEntity.SubType > 0 then
			entity.SubType = entity.SpawnerEntity.SubType
		end

		-- Black champion's scythes are bigger
		if entity.SubType == 1 then
			entity.Scale = 1.1
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ScytheInit, EntityType.ENTITY_DEATH)

-- Hourglass sound
function mod:DeathUpdate(entity)
	if entity.Variant == 0 and entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() == 21 then
		mod:PlaySound(nil, SoundEffect.SOUND_MENU_FLIP_DARK, 2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DeathUpdate, EntityType.ENTITY_DEATH)



--[[ Peep and Bloat ]]--
-- Decrease Peep's and increase The Bloat's HP
function mod:PeepInit(entity)
	if entity.Variant <= 1 then
		local newHealth = 390
		if entity.Variant == 1 then
			newHealth = 500
		elseif entity.SubType ~= 0 then
			newHealth = 350
		end

		entity.MaxHitPoints = newHealth
		entity.HitPoints = entity.MaxHitPoints
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PeepInit, EntityType.ENTITY_PEEP)

-- Make the eyes bounce off of them and each other
function mod:PeepEyeCollision(entity, target, bool)
	if (entity.Variant == 10 or entity.Variant == 11) and target.Type == entity.Type then
		entity.Velocity = (entity.Position - target.Position):Normalized()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.PeepEyeCollision, EntityType.ENTITY_PEEP)



--[[ Increase Loki and Lokii's HP ]]--
function mod:LokiInit(entity)
	entity.MaxHitPoints = 420
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.LokiInit, EntityType.ENTITY_LOKI)



--[[ Fistula Scarred Womb skin ]]--
function mod:FistulaScarredSkin(entity)
	if entity.Variant == 0 then
		if entity.SubType == 0 and Game():GetRoom():GetBackdropType() == BackdropType.SCARRED_WOMB then
			entity.SubType = 1000 -- The subtype that Matriarch Fistula pieces use
		end

		if entity.SubType == 1000 then
			local sprite = entity:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/bosses/classic/boss_025_fistula_scarred.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_BIG)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_MEDIUM)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FistulaScarredSkin, EntityType.ENTITY_FISTULA_SMALL)



--[[ Gurdy Jr. ]]--
function mod:GurdyJrInit(entity)
	local newHealth = 320
	if entity.SubType == 1 then
		newHealth = 176
	elseif entity.SubType == 2 then
		newHealth = 400
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GurdyJrInit, EntityType.ENTITY_GURDY_JR)

function mod:GurdyJrUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_ATTACK and sprite:IsPlaying("Attack03Start") and sprite:GetFrame() < 8 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GurdyJrUpdate, EntityType.ENTITY_GURDY_JR)



--[[ Gurglings ]]--
-- Different sprites for boss Gurglings
function mod:GurglingInit(entity)
	if entity.Variant == 1 and (entity.SubType == 0 or entity.SubType == 500) then
		local sprite = entity:GetSprite()
		sprite:ReplaceSpritesheet(1, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:ReplaceSpritesheet(2, "gfx/monsters/rebirth/monster_237_gurgling_boss.png")
		sprite:LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.GurglingInit, EntityType.ENTITY_GURGLING)

-- Make them immune to knockback while charging
function mod:GurglingUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK then
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	else
		entity:ClearEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.GurglingUpdate, EntityType.ENTITY_GURGLING)



--[[ Mega Maw ]]--
function mod:MegaMawUpdate(entity)
	local sprite = entity:GetSprite()
	local hopperCount = Isaac.CountEntities(nil, EntityType.ENTITY_HOPPER, -1, -1) + Isaac.CountEntities(nil, EntityType.ENTITY_FLAMINGHOPPER, -1, -1)

	-- Limit his Hopper count to 3
	if entity.State == NpcState.STATE_SUMMON and sprite:GetFrame() == 0 and hopperCount >= 3 then
		entity.State = NpcState.STATE_ATTACK2
		SFXManager():Stop(SoundEffect.SOUND_MOUTH_FULL)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MegaMawUpdate, EntityType.ENTITY_MEGA_MAW)

-- Prevent him from taking damage from his Flaming Hoppers
function mod:MegaMawDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageSource.Type == EntityType.ENTITY_FLAMINGHOPPER or damageSource.SpawnerType == EntityType.ENTITY_FLAMINGHOPPER then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MegaMawDMG, EntityType.ENTITY_MEGA_MAW)



--[[ Mega Fatty suction effects ]]--
function mod:MegaFattyUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsPlaying("Sucking") then
		-- Sound
		if sprite:GetFrame() == 4 then
			mod:PlaySound(entity, SoundEffect.SOUND_LOW_INHALE)

		elseif sprite:WasEventTriggered("StartSucking") then
			-- Attract rings
			if sprite:GetFrame() <= 25 and entity:IsFrame(8, 0) then
				local ring = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_ATTRACT, 0, entity.Position, Vector.Zero, entity):ToEffect()
				ring:FollowParent(entity)
				ring.ParentOffset = Vector(0, entity.Scale * -90)
				ring:Update()
			end

			-- Attract trails
			if sprite:GetFrame() <= 35 and entity:IsFrame(6, 0) then
				local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_ATTRACT, 1, entity.Position, Vector.Zero, entity):ToEffect()
				trail:FollowParent(entity)
				trail.ParentOffset = Vector(0, entity.Scale * -90)
				trail:Update()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MegaFattyUpdate, EntityType.ENTITY_MEGA_FATTY)



--[[ The Cage ]]--
-- Reduce his ridiculous HP
function mod:CageInit(entity)
	local newHealth = 720
	if entity.SubType == 2 then
		newHealth = 360
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.CageInit, EntityType.ENTITY_CAGE)

function mod:CageUpdate(entity)
	-- Fix him having a hitbox before he lands
	if entity.State == NpcState.STATE_STOMP then
		if entity:GetSprite():GetFrame() < 4 then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		else
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		end

	-- Extra effects when bouncing off of walls
	elseif entity.State == NpcState.STATE_ATTACK and entity:CollidesWithGrid() then
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
		Game():ShakeScreen(math.floor(entity.Scale * 4))
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.CageUpdate, EntityType.ENTITY_CAGE)

-- Make them bounce off of each other
function mod:CageCollide(entity, target, bool)
	if entity.State == NpcState.STATE_ATTACK and (target.Type == entity.Type or target.Type == EntityType.ENTITY_SISTERS_VIS) then
		entity.Velocity = (entity.Position - target.Position):Normalized()
		mod:PlaySound(nil, SoundEffect.SOUND_FORESTBOSS_STOMPS, entity.Scale * 0.5, 1, 6)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.CageCollide, EntityType.ENTITY_CAGE)



-- [[ Polycephalus / The Stain ]]--
-- Increase Polycephalus's HP
function mod:PolycephalusInit(entity)
	local newHealth = 320
	if entity.SubType == 2 then
		newHealth = 140
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PolycephalusInit, EntityType.ENTITY_POLYCEPHALUS)

-- Burrowing indicator
function mod:PolycephalusDirt(entity)
	if mod.Config.NoHiddenPoly == true and (entity.Type == EntityType.ENTITY_STAIN or entity.Variant == 0) -- If it's not The Pile
	and entity.State == NpcState.STATE_MOVE and entity.I1 == 2 -- When fully underground
	and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PolycephalusDirt, EntityType.ENTITY_POLYCEPHALUS)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PolycephalusDirt, EntityType.ENTITY_STAIN)



--[[ Delirium helper ]]--
function mod:DeliriumHelper(entity)
	if not entity:GetData().wasDelirium then
		entity:GetData().wasDelirium = true
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DeliriumHelper, EntityType.ENTITY_DELIRIUM)



--[[ Decrease Reap Creep's HP ]]--
function mod:ReapCreepInit(entity)
	entity.MaxHitPoints = 600
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ReapCreepInit, EntityType.ENTITY_REAP_CREEP)



--[[ Decrease Clog's HP ]]
function mod:ClogInit(entity)
	local newHealth = 360
	if entity.SubType == 1 then -- For Repentance Boss Champions
		newHealth = 432
	end

	entity.MaxHitPoints = newHealth
	entity.HitPoints = entity.MaxHitPoints
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.ClogInit, EntityType.ENTITY_CLOG)



--[[ Bumbino make sticky nickel go boom!! ]]--
function mod:BumbinoUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.State == NpcState.STATE_MOVE then
		-- Find any sticky nickels nearby
		for _, pickup in pairs(Isaac.FindInRadius(entity.Position, 180, EntityPartition.PICKUP)) do
			if pickup.Variant == PickupVariant.PICKUP_COIN and pickup.SubType == CoinSubType.COIN_STICKYNICKEL and pickup:ToPickup():CanReroll() == true then
				entity.State = NpcState.STATE_ATTACK4
				sprite:Play("ButtBomb", true)
				entity.Target = pickup
				sprite.FlipX = entity.Position.X > pickup.Position.X
				break
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.BumbinoUpdate, EntityType.ENTITY_BUMBINO)

-- Change his Butt Bomb's velocity to target the sticky nickel
function mod:BumbinoBombInit(bomb)
	if bomb.SpawnerType == EntityType.ENTITY_BUMBINO and bomb.SpawnerEntity and bomb.SpawnerEntity.Target and bomb.SpawnerEntity.Target.Type == EntityType.ENTITY_PICKUP then
		local speed = bomb.Position:Distance(bomb.SpawnerEntity.Target.Position) / 11
		bomb.Velocity = (bomb.SpawnerEntity.Target.Position - bomb.Position):Resized(speed)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, mod.BumbinoBombInit, BombVariant.BOMB_BUTT)