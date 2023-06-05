local mod = BetterMonsters

local Settings = {
	Range = 100,
	HealAmount = 10,
	Cooldown = 30,
	MaxPlayerHeals = 10
}



function fleshDeathHeadHeal(entity, big)
	local data = entity:GetData()

	local multiplier = 1
	local playerHeal = 1
	local sound = SoundEffect.SOUND_VAMP_GULP

	if big == true then
		multiplier = 5
		playerHeal = 2
		sound = SoundEffect.SOUND_VAMP_DOUBLE
	end


	-- Heal effects
	local function healEffect(owner)
		mod:PlaySound(nil, sound)

		local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, owner.Position, Vector.Zero, entity)
		effect:ToEffect():FollowParent(owner)
		effect:GetSprite().Offset = Vector(0, -40)
		effect.DepthOffset = owner.DepthOffset + 1
	end


	-- Heal enemies on the same "team"
	for _,v in pairs(Isaac.GetRoomEntities()) do
		if v.Type > 9 and v.Type < 1000 and entity.Position:Distance(v.Position) <= Settings.Range and v.Type ~= EntityType.ENTITY_FLESH_DEATHS_HEAD and v.HitPoints < v.MaxHitPoints
		and v.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE and v:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			v:AddHealth(Settings.HealAmount * multiplier)
			v:SetColor(Color(1,1,1, 1, 0.65,0,0), 15, 1, true, false)
			healEffect(v)
		end
	end

	-- Heal players if friendly
	if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		for i = 0, Game():GetNumPlayers() do
			local player = Isaac.GetPlayer(i)

			if entity.Position:Distance(player.Position) <= Settings.Range and not player:HasFullHearts() then
				player:AddHearts(playerHeal)
				data.playerHeals = data.playerHeals + 1
				healEffect(player)
			end
		end
	end
end



function mod:fleshDeathHeadInit(entity)
	entity.CanShutDoors = true
	entity:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fleshDeathHeadInit, EntityType.ENTITY_FLESH_DEATHS_HEAD)

function mod:fleshDeathHeadUpdate(entity)
	local data = entity:GetData()

	-- Healing aura
	if not data.aura or (data.aura and not data.aura:Exists()) then
		data.aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.HealingAura, 0, entity.Position, Vector.Zero, entity):ToEffect()
		data.aura:FollowParent(entity)
		data.aura.Parent = entity
		data.aura:GetSprite():Play("FadeIn", true)
		data.aura.DepthOffset = -1000
	end


	-- Make them not heal players infinitely if friendly
	if not data.playerHeals then
		data.playerHeals = 0
	elseif data.playerHeals >= Settings.MaxPlayerHeals then
		entity:Die()
	end

	-- Heal
	if entity.ProjectileCooldown <= 0 then
		fleshDeathHeadHeal(entity)
		entity.ProjectileCooldown = Settings.Cooldown
	else
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end


	-- Don't shoot projectiles on death
	if entity:IsDead() then
		fleshDeathHeadHeal(entity, true)

		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, nil)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, nil)
		mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS, 0.9)
		mod:PlaySound(nil, SoundEffect.SOUND_EXPLOSION_WEAK)

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.fleshDeathHeadUpdate, EntityType.ENTITY_FLESH_DEATHS_HEAD)



-- Healing aura
function mod:healingAuraUpdate(effect)
	local sprite = effect:GetSprite()

	if effect.State == 0 then
		if sprite:IsFinished("FadeIn") then
			effect.State = 1
		end

	elseif effect.State == 1 then
		mod:LoopingAnim(sprite, "Idle")

		if not effect.Parent or effect.Parent:HasMortalDamage() then
			effect.State = 2
			sprite:Play("FadeOut", true)
		end

	elseif effect.State == 2 then
		if sprite:IsFinished("FadeOut") then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.healingAuraUpdate, IRFentities.HealingAura)