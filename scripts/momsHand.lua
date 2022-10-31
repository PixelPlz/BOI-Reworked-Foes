local mod = BetterMonsters
local game = Game()



-- Mom's Hand --
function mod:momsHandInit(entity)
	if IRFconfig.hiddenAppearAnims == true then
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

function mod:momsHandUpdate(entity)
	-- Go to previous room if Isaac is grabbed
	if entity.State == NpcState.STATE_SPECIAL and entity.I1 == 1 then
		if entity.StateFrame == 1 then
			entity:PlaySound(SoundEffect.SOUND_MOM_VOX_EVILLAUGH, 1, 0, false, 1)
		elseif entity.StateFrame == 25 then
			game:StartRoomTransition(game:GetLevel():GetPreviousRoomIndex(), -1, RoomTransitionAnim.FADE, nil, -1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.momsHandUpdate, EntityType.ENTITY_MOMS_HAND)



-- Mom's Dead Hand --
function mod:momsDeadHandInit(entity)
	if IRFconfig.hiddenAppearAnims == true then
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

function mod:momsDeadHandUpdate(entity)
	local sprite = entity:GetSprite()

	if sprite:IsEventTriggered("Land") then
		-- Remove default rock waves
		for i, rockWave in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, -1, false, false)) do
			if rockWave.SpawnerType == EntityType.ENTITY_MOMS_DEAD_HAND and rockWave.SpawnerEntity and rockWave.SpawnerEntity.Index == entity.Index then
				rockWave:Remove()
			end
		end


		local params = ProjectileParams()
		local bg = game:GetRoom():GetBackdropType()

		if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
			params.Color = corpseGreenBulletColor
		elseif not (bg == BackdropType.WOMB or bg == BackdropType.UTERO or bg == BackdropType.SCARRED_WOMB or bg == BackdropType.CORPSE3) then
			params.Variant = ProjectileVariant.PROJECTILE_ROCK
		end
		params.Scale = 1.35

		entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, entity.Position, Vector.Zero, entity):ToEffect().Timeout = 10
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.momsDeadHandUpdate, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:momsDeadHandDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if damageFlags & DamageFlag.DAMAGE_CRUSH > 0 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.momsDeadHandDMG, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:momsDeadHandDeath(entity, target, bool)
	-- Remove spiders
	for i, spider in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
		if spider.SpawnerType == EntityType.ENTITY_MOMS_DEAD_HAND then
			spider:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.momsDeadHandDeath, EntityType.ENTITY_MOMS_DEAD_HAND)