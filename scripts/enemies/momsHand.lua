local mod = BetterMonsters



-- Mom's Hand --
function mod:momsHandUpdate(entity)
	-- Go to previous room if Isaac is grabbed
	if entity.State == NpcState.STATE_SPECIAL and entity.I1 == 1 then
		if entity.StateFrame == 1 then
			entity:PlaySound(SoundEffect.SOUND_MOM_VOX_EVILLAUGH, 1, 0, false, 1)
		elseif entity.StateFrame == 25 then
			Game():StartRoomTransition(Game():GetLevel():GetPreviousRoomIndex(), -1, RoomTransitionAnim.FADE, nil, -1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.momsHandUpdate, EntityType.ENTITY_MOMS_HAND)



-- Mom's Dead Hand --
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
		params.Scale = 1.35

		local bg = Game():GetRoom():GetBackdropType()
		if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
			params.Color = corpseGreenBulletColor
		elseif not (bg == BackdropType.WOMB or bg == BackdropType.UTERO or bg == BackdropType.SCARRED_WOMB or bg == BackdropType.CORPSE3) then
			params.Variant = ProjectileVariant.PROJECTILE_ROCK
		end

		entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, entity.Position, Vector.Zero, entity):ToEffect().Timeout = 10
		Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
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