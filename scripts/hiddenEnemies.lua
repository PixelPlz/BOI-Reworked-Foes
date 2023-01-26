local mod = BetterMonsters



-- [[ Pin / Scolex / Frail ]]--
function mod:pinInit(entity)
	if IRFconfig.appearPins == true and entity.Variant < 3 and (not FiendFolio or entity.SubType ~= 2) and (not GBMd or entity.Variant > 0) and not entity.Parent and not entity.SpawnerEntity then
		local sprite = entity:GetSprite()

		sprite:Play("Attack1", true)
		sprite:SetFrame(80)
		entity.State = NpcState.STATE_APPEAR_CUSTOM
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

		-- Black Frail fix
		if entity.Variant == 2 and entity.SubType == 1 then
			entity.I2 = 1
			sprite:ReplaceSpritesheet(0, "gfx/bosses/afterbirth/boss_thefrail2_black.png")
			sprite:LoadGraphics()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.pinInit, EntityType.ENTITY_PIN)

function mod:pinPreUpdate(entity)
	local sprite = entity:GetSprite()

	-- Appear animation
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		if sprite:IsFinished("Attack1") then
			entity.State = NpcState.STATE_APPEAR

			-- Black Frail fix
			if entity.Variant == 2 and entity.SubType == 1 then
				entity.I2 = 0
			end
		end

		return true
	end


	-- Dirt effect
	if IRFconfig.noHiddenPins == true and entity.Variant < 3 and entity:IsFrame(6, 0) and not entity.Parent and entity.Visible == false then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.pinPreUpdate, EntityType.ENTITY_PIN)



--[[ Mom's Hand ]]--
function mod:momsHandInit(entity)
	if IRFconfig.appearMomsHands == true then
		entity:GetSprite():Play("JumpUp", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end

	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.momsHandInit, EntityType.ENTITY_MOMS_HAND)

function mod:momsHandPreUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("JumpUp") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.momsHandPreUpdate, EntityType.ENTITY_MOMS_HAND)



--[[ Mom's Dead Hand ]]--
function mod:momsDeadHandInit(entity)
	if IRFconfig.appearMomsHands == true then
		entity:GetSprite():Play("JumpUp", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end

	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.SplatColor = Color(0.25,0.25,0.25, 1)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.momsDeadHandInit, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:momsDeadHandPreUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("JumpUp") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.momsDeadHandPreUpdate, EntityType.ENTITY_MOMS_DEAD_HAND)



-- [[ Polycephalus ]]--
function mod:polycephalusDirt(entity)
	if IRFconfig.noHiddenPoly == true and entity.Variant == 0 and entity.State == NpcState.STATE_MOVE and entity.I1 == 2 and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.polycephalusDirt, EntityType.ENTITY_POLYCEPHALUS)



-- [[ The Stain ]]--
function mod:stainDirt(entity)
	if IRFconfig.noHiddenStain == true and entity.State == NpcState.STATE_MOVE and entity.I1 == 2 and entity:IsFrame(6, 0) then
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DIRT_PILE, 0, entity.Position, Vector.Zero, entity).SpriteScale = Vector(1.2, 1.2)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.stainDirt, EntityType.ENTITY_STAIN)



--[[ Needle / Pasty ]]--
function mod:needleInit(entity)
	if IRFconfig.appearNeedles == true then
		entity:GetSprite():Play("Appear", true)
		entity:GetData().init = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.needleInit, EntityType.ENTITY_NEEDLE)

function mod:needleUpdate(entity)
	if entity:GetData().init == false then
		if entity:GetSprite():IsFinished("Appear") then
			entity:GetData().init = true
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.needleUpdate, EntityType.ENTITY_NEEDLE)



--[[ Dust ]]--
function mod:dustParticles(entity)
	if IRFconfig.noHiddenDust == true and entity.V1.X < 0.1 and entity:IsFrame(16, 0) then
		for i = 1, 3 do
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, entity.Position + Vector(0, -24) + (Vector.FromAngle(math.random(0, 359)) * 10), Vector.Zero, entity):GetSprite().Color = dustColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dustParticles, EntityType.ENTITY_DUST)