local mod = ReworkedFoes



-- [[ Pin / Scolex / Frail ]]--
function mod:PinAppearInit(entity)
	if mod.Config.AppearPins == true and entity.Variant < 3 -- Only if it's not Wormwood
	and not entity.Parent and not entity.SpawnerEntity -- Only head
	and (not FiendFolio or entity.SubType ~= 2) -- Not Fiend Folio Technopin
	and (not GBMd or entity.Variant > 0) then -- Not the Greed Mode skin for Pin (it fucks with the animations for some reason)
		local sprite = entity:GetSprite()

		sprite:Play("Attack1", true)
		entity.State = NpcState.STATE_APPEAR_CUSTOM
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		local frame = 80
		if entity.Variant == 1 then
			frame = 46
		end
		sprite:SetFrame(frame)

		-- Black Frail fix
		if entity.Variant == 2 and entity.SubType == 1 then
			entity.I2 = 1
			sprite:ReplaceSpritesheet(0, "gfx/bosses/afterbirth/boss_thefrail2_black.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.PinAppearInit, EntityType.ENTITY_PIN)

function mod:PinAppearUpdate(entity)
	local sprite = entity:GetSprite()

	-- Appear animation
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		if sprite:IsFinished() then
			entity.State = NpcState.STATE_APPEAR

			-- Black Frail fix
			if entity.Variant == 2 and entity.SubType == 1 then
				entity.I2 = 0
			end
		end

		return true
	end


	-- Dirt effect
	if mod.Config.NoHiddenPins == true and entity.Variant < 3 -- Only if it's not Wormwood
	and not entity.Parent and entity.Visible == false -- Only the head while its underground
	and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.PinAppearUpdate, EntityType.ENTITY_PIN)



--[[ Mom's Hands ]]--
function mod:MomsHandAppearInit(entity)
	if mod.Config.AppearMomsHands == true then
		entity:GetSprite():Play("JumpUp", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end

	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MomsHandAppearInit, EntityType.ENTITY_MOMS_HAND)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MomsHandAppearInit, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:MomsHandAppearUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished() then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.MomsHandAppearUpdate, EntityType.ENTITY_MOMS_HAND)
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.MomsHandAppearUpdate, EntityType.ENTITY_MOMS_DEAD_HAND)



-- [[ Polycephalus / The Stain ]]--
function mod:PolycephalusDirt(entity)
	if mod.Config.NoHiddenPoly == true
	and ((entity.Variant == 0 and entity.State == NpcState.STATE_MOVE and entity.I1 == 2) -- Polycephalus
	or (entity.Variant == 1 and entity.State == NpcState.STATE_JUMP and entity.I1 ~= 0)) -- The Pile
	and entity:IsFrame(entity.Variant == 1 and 4 or 6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PolycephalusDirt, EntityType.ENTITY_POLYCEPHALUS)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PolycephalusDirt, EntityType.ENTITY_STAIN)



--[[ Needle / Pasty ]]--
function mod:NeedleAppearInit(entity)
	if mod.Config.AppearNeedles == true then
		entity:GetSprite():Play("Appear", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.NeedleAppearInit, EntityType.ENTITY_NEEDLE)

function mod:NeedleAppearUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("Appear") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.NeedleAppearUpdate, EntityType.ENTITY_NEEDLE)



--[[ Dust ]]--
function mod:DustParticles(entity)
	if mod.Config.NoHiddenDust == true
	and entity.V1.X < 0.1 -- Only when fully invisible
	and entity:IsFrame(16, 0) then
		for i = 1, 3 do
			local dust = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, entity.Position + Vector(0, -24) + mod:RandomVector(10), Vector.Zero, entity)
			dust:GetSprite().Color = mod.Colors.DustTrail
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.DustParticles, EntityType.ENTITY_DUST)