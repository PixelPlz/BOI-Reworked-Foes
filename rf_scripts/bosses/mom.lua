local mod = ReworkedFoes



function mod:MomInit(entity)
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	-- Red champion eye fix for door sprite mods
	if entity.Variant == 0 and entity.SubType == 2 then
		entity:GetSprite():ReplaceSpritesheet(0, "gfx/bosses/classic/boss_054_mom_red_eye.png")
		entity:GetSprite():LoadGraphics()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.MomInit, EntityType.ENTITY_MOM)

-- Red champion eye shot
function mod:MomUpdate(entity)
	if entity.Variant == 0 and entity.SubType == 2 then
		local sprite = entity:GetSprite()

		-- Replace default attack
		if entity.State == NpcState.STATE_ATTACK then
			entity.State = NpcState.STATE_ATTACK5
			sprite:Play("EyeLaser", true)
			entity.I2 = 0

		elseif entity.State == NpcState.STATE_ATTACK5 then
			if sprite:IsEventTriggered("Shoot") or sprite:GetFrame() == 55 or sprite:GetFrame() == 65 then
				local params = ProjectileParams()
				params.Scale = 1.4 - (entity.I2 * 0.1)
				entity:FireProjectiles(entity.Position + Vector(0, 20), (entity:GetPlayerTarget().Position - (entity.Position + Vector(0, 20))):Resized(10), 0 + entity.I2, params)
				mod:ShootEffect(entity, 2)

				entity.I2 = entity.I2 + 1
				mod:PlaySound(nil, SoundEffect.SOUND_BLOODSHOOT, 1.4)
			end

			if sprite:IsFinished("EyeLaser") then
				entity.State = NpcState.STATE_IDLE
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.MomUpdate, EntityType.ENTITY_MOM)



-- Alt-path spawn replacements
mod.MomSpawnReplacements = {
	-- Mausoleum
	[ StageType.STAGETYPE_REPENTANCE ] = {
		[ EntityType.ENTITY_ATTACKFLY .. 0 ] = { Type = EntityType.ENTITY_BONY, },
		[ EntityType.ENTITY_GLOBIN .. 3 ] 	 = { Type = EntityType.ENTITY_KNIGHT, Variant = 2, },
		[ EntityType.ENTITY_PSY_HORF .. 0 ]  = { Type = EntityType.ENTITY_WHIPPER, },
	},
	-- Gehenna
	[ StageType.STAGETYPE_REPENTANCE_B ] = {
		[ EntityType.ENTITY_ATTACKFLY .. 0 ] = { Type = EntityType.ENTITY_BONY, },
		[ EntityType.ENTITY_GLOBIN .. 3 ] 	 = { Type = EntityType.ENTITY_KNIGHT, Variant = 4, },
		[ EntityType.ENTITY_RAGLING .. 1 ] 	 = { Type = EntityType.ENTITY_GOAT, },
		[ EntityType.ENTITY_PSY_HORF .. 0 ]  = { Type = EntityType.ENTITY_WHIPPER, },
	},
}

-- Replace the specified spawns
function mod:ReplaceMomSpawn(type, variant, subtype, position, velocity, spawner, seed)
	if type >= 10 and type < 1000 and type ~= EntityType.ENTITY_MOM
	and spawner and spawner.Type == EntityType.ENTITY_MOM and spawner.Variant == 0 and spawner.SubType == 3 then
		local spawnGroup = Game():GetLevel():GetStageType()
		local spawnData = mod.MomSpawnReplacements[spawnGroup][type .. variant]

		if spawnData then
			local newVariant = spawnData.Variant or 0
			local newSubType = spawnData.SubType or 0
			return { spawnData.Type, newVariant, newSubType, seed, }
		end
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.ReplaceMomSpawn)