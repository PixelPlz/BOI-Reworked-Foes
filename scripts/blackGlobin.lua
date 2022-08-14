local mod = BetterMonsters
local game = Game()

local Settings = {
	RegenTime = 90,
	BodySpeed = 3.75,
	SoundTimer = {90, 150},
	NewHealth = 20,

	HeadSpeed = 3.25,
	SlideTime = 45,
	SlideSpeed = 15,
	CreepTime = 45
}



function mod:blackGlobinUpdate(entity)
	if entity:IsDead() or entity.State == NpcState.STATE_APPEAR_CUSTOM then
		-- Spawn from head
		if entity.State == NpcState.STATE_APPEAR_CUSTOM then	
			entity.Velocity = Vector.Zero

			if entity:GetSprite():IsEventTriggered("Regen") then
				entity.State = NpcState.STATE_MOVE
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blackGlobinUpdate, EntityType.ENTITY_BLACK_GLOBIN)



function mod:blackGlobinHeadInit(entity)
	entity.I2 = Settings.RegenTime * 2.5 -- Make them start with a longer regen time if spawned through the room layout
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.blackGlobinHeadInit, EntityType.ENTITY_BLACK_GLOBIN_HEAD)

function mod:blackGlobinHeadUpdate(entity)
	local sprite = entity:GetSprite()

	-- Regen
	if entity.State == NpcState.STATE_MOVE then
		if entity.I2 <= 0 then
			local spawn = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN, 0, 0, entity.Position, Vector.Zero, entity):ToNPC()
			spawn.State = NpcState.STATE_APPEAR_CUSTOM
			spawn:GetSprite():Play("Appear", true)
			spawn:GetSprite().FlipX = sprite.FlipX
			spawn.HitPoints = Settings.NewHealth

			if entity:IsChampion() then
				spawn:ToNPC():MakeChampion(1, entity:GetChampionColorIdx(), true)
			end
			SFXManager():Play(SoundEffect.SOUND_DEATH_REVERSE, 1.2)
			entity:Remove()

		else
			entity.I2 = entity.I2 - 1
		end
	
	
	elseif entity.State == NpcState.STATE_STOMP or entity.State == NpcState.STATE_JUMP then
		-- Creep
		if entity:IsFrame(4, 0) then
			local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect()
			creep.Scale = 1
			creep:SetTimeout(Settings.CreepTime)
			creep:Update()
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

			if entity:CollidesWithGrid() or sprite:IsEventTriggered("Splat") then
				SFXManager():Play(SoundEffect.SOUND_MEAT_JUMPS)
				local impactCreep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_RED, 0, entity.Position, Vector.Zero, entity):ToEffect()
				impactCreep.Scale = 1.5
				impactCreep:SetTimeout(Settings.CreepTime)
			end


		-- Recover
		elseif entity.State == NpcState.STATE_JUMP then
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

			if not sprite:IsPlaying("Recover") then
				sprite:Play("Recover", true)
			end

			if sprite:IsEventTriggered("Splat") then
				SFXManager():Play(SoundEffect.SOUND_GOOATTACH0, 0.9)

			elseif sprite:IsEventTriggered("Recover") then
				entity.State = NpcState.STATE_MOVE
				entity.I2 = Settings.RegenTime
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.blackGlobinHeadUpdate, EntityType.ENTITY_BLACK_GLOBIN_HEAD)



function mod:blackGlobinDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	target:ToNPC().V2 = damageSource.Position
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.blackGlobinDMG, EntityType.ENTITY_BLACK_GLOBIN)

function mod:blackGlobinDeath(entity)
	local head = Isaac.Spawn(EntityType.ENTITY_BLACK_GLOBIN_HEAD, 4279, 0, entity.Position, Vector.Zero, entity):ToNPC()
	head.State = NpcState.STATE_STOMP
	head.I2 = Settings.SlideTime
	head.Velocity = (entity.Position - entity.V2):Normalized() * Settings.SlideSpeed
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