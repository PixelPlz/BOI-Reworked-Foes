local mod = ReworkedFoes



--[[ Mom's Hand ]]--
function mod:MomsHandUpdate(entity)
	-- Go to previous room if Isaac is grabbed
	if entity.State == NpcState.STATE_SPECIAL and entity.I1 == 1 then
		if entity.StateFrame == 1 then
			mod:PlaySound(entity, SoundEffect.SOUND_MOM_VOX_EVILLAUGH)

		elseif entity.StateFrame == 25 then
			local previousRoom = Game():GetLevel():GetPreviousRoomIndex()
			Game():StartRoomTransition(previousRoom, -1, RoomTransitionAnim.FADE, nil, -1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MomsHandUpdate, EntityType.ENTITY_MOMS_HAND)



--[[ Mom's Dead Hand ]]--
function mod:MomsDeadHandUpdate(entity)
	local sprite = entity:GetSprite()

	-- Replace appear sound
	if SFXManager():IsPlaying(SoundEffect.SOUND_MOM_VOX_EVILLAUGH) then
		SFXManager():Stop(SoundEffect.SOUND_MOM_VOX_EVILLAUGH)
		mod:PlaySound(entity, SoundEffect.SOUND_MOTHERSHADOW_APPEAR)
	end


	if sprite:IsEventTriggered("Land") then
		-- Remove default rock waves
		for i, rockWave in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.CRACKWAVE, -1, false, false)) do
			if rockWave.SpawnerEntity and rockWave.SpawnerEntity.Index == entity.Index then
				rockWave:Remove()
			end
		end

		-- New rock waves
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SHOCKWAVE, 0, entity.Position, Vector.Zero, entity):ToEffect().Timeout = 10


		-- Projectiles
		local params = ProjectileParams()
		params.Scale = 1.35

		-- Get fitting projectile
		local bg = Game():GetRoom():GetBackdropType()

		if bg == BackdropType.CORPSE or bg == BackdropType.CORPSE2 then
			params.Color = mod.Colors.CorpseGreen
		elseif bg ~= BackdropType.WOMB and bg ~= BackdropType.UTERO and bg ~= BackdropType.SCARRED_WOMB and bg ~= BackdropType.CORPSE3 then
			params.Variant = ProjectileVariant.PROJECTILE_ROCK
		end

		entity:FireProjectiles(entity.Position, Vector(11, 8), 8, params)


		-- Effects
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 2, entity.Position, Vector.Zero, entity):GetSprite().Color = mod.Colors.DustPoof
		mod:PlaySound(nil, SoundEffect.SOUND_HELLBOSS_GROUNDPOUND)
		Game():ShakeScreen(6)
		Game():MakeShockwave(entity.Position, 0.035, 0.025, 10)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MomsDeadHandUpdate, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:MomsDeadHandDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if (damageFlags & DamageFlag.DAMAGE_CRUSH > 0) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.MomsDeadHandDMG, EntityType.ENTITY_MOMS_DEAD_HAND)

function mod:MomsDeadHandDeath(entity, target, bool)
	-- Remove the spiders
	for i, spider in pairs(Isaac.FindByType(EntityType.ENTITY_SPIDER, -1, -1, false, false)) do
		if spider.SpawnerType == EntityType.ENTITY_MOMS_DEAD_HAND then
			spider:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.MomsDeadHandDeath, EntityType.ENTITY_MOMS_DEAD_HAND)