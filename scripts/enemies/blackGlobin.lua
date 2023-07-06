local mod = BetterMonsters

local Settings = {
	RegenTime = 90,
	NewHealth = 20,
	SlideTime = 45,
	SlideSpeed = 15,
	CreepTime = 45
}



--[[ Black Globin ]]--
function mod:blackGlobinUpdate(entity)
	if entity:IsDead() or entity.State == NpcState.STATE_APPEAR_CUSTOM then
		-- Spawn from head
		if entity.State == NpcState.STATE_APPEAR_CUSTOM then	
			entity.Velocity = mod:StopLerp(entity.Velocity)

			if entity:GetSprite():IsEventTriggered("Regen") then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blackGlobinUpdate, EntityType.ENTITY_BLACK_GLOBIN)

function mod:blackGlobinDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	target:ToNPC().V2 = damageSource.Position
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blackGlobinDMG, EntityType.ENTITY_BLACK_GLOBIN)

function mod:blackGlobinDeath(entity)
	local head = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN_HEAD, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
	head.State = NpcState.STATE_STOMP
	head.I1 = 1
	head.I2 = Settings.SlideTime
	head.Velocity = (entity.Position - entity.V2):Resized(Settings.SlideSpeed)
	head:GetSprite():Play("KnockedOff", true)
	head.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS

	local body = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN_BODY, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
	body.State = NpcState.STATE_MOVE

	if entity:IsChampion() then
		head:ToNPC():MakeChampion(1, entity:GetChampionColorIdx(), true)
		body:MakeChampion(1, entity:GetChampionColorIdx(), true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.blackGlobinDeath, EntityType.ENTITY_BLACK_GLOBIN)



--[[ Black Globin Head ]]--
function mod:blackGlobinHeadUpdate(entity)
	local sprite = entity:GetSprite()

	-- Regen
	if entity.State == NpcState.STATE_MOVE then
		-- Only regen if spawned from a Black Globin
		if entity.I1 == 1 then
			if entity.I2 <= 0 then
				local spawn = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
				spawn.State = NpcState.STATE_APPEAR_CUSTOM
				spawn:GetSprite():Play("Appear", true)
				spawn:GetSprite().FlipX = sprite.FlipX
				spawn.HitPoints = Settings.NewHealth
				mod:PlaySound(entity, SoundEffect.SOUND_DEATH_REVERSE, 1.2)

				if entity:IsChampion() then
					spawn:MakeChampion(1, entity:GetChampionColorIdx(), true)
				end
				entity:Remove()

			else
				entity.I2 = entity.I2 - 1
			end
		end


	-- Sliding / Recovering
	elseif entity.State == NpcState.STATE_STOMP or entity.State == NpcState.STATE_JUMP then
		-- Creep
		if entity:IsFrame(3, 0) then
			mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 1, Settings.CreepTime)
		end

		-- Sliding
		if entity.State == NpcState.STATE_STOMP then
			if not sprite:IsPlaying("Sliding") and not sprite:IsPlaying("KnockedOff") then
				sprite:Play("Sliding", true)
				entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end

			if entity.I2 <= 0 then
				entity.State = NpcState.STATE_JUMP
			else
				entity.I2 = entity.I2 - 1
			end

			-- Impact with grids
			if entity:CollidesWithGrid() or sprite:IsEventTriggered("Splat") then
				mod:PlaySound(nil, SoundEffect.SOUND_MEAT_JUMPS)
				mod:QuickCreep(EffectVariant.CREEP_RED, entity, entity.Position, 1.5, Settings.CreepTime)
			end


		-- Recover
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = mod:StopLerp(entity.Velocity)
			mod:LoopingAnim(sprite, "Recover")

			if sprite:IsEventTriggered("Splat") then
				mod:PlaySound(nil, SoundEffect.SOUND_GOOATTACH0, 0.9)

			elseif sprite:IsEventTriggered("Recover") then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = Settings.RegenTime
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blackGlobinHeadUpdate, EntityType.ENTITY_BLACK_GLOBIN_HEAD)