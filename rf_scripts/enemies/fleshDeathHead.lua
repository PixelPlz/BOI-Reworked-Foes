local mod = ReworkedFoes

local Settings = {
	Range = 100,
	HealAmount = 10,
	Cooldown = 30,
	MaxPlayerHeals = 10
}



function mod:FleshDeathHeadHeal(entity, big)
	-- Get the amount to heal
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
		effect:GetSprite().Offset = Vector(0, owner.SpriteScale * -40)
		effect.DepthOffset = owner.DepthOffset + 1
	end


	for i, e in pairs(Isaac.FindInRadius(entity.Position, Settings.Range, 40)) do
		-- Heal players if friendly
		if e:ToPlayer() and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			local player = e:ToPlayer()

			if not player:HasFullHearts() then
				player:AddHearts(playerHeal)
				entity:GetData().playerHeals = entity:GetData().playerHeals + 1
				healEffect(player)
			end
		end

		-- Heal enemies on the same "team"
		if  e:ToNPC()
		and e.HitPoints < e.MaxHitPoints
		and e.Type ~= EntityType.ENTITY_FLESH_DEATHS_HEAD
		and e.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE
		and e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) == entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
			e:AddHealth(Settings.HealAmount * multiplier)
			e:SetColor(mod.Colors.Heal, 15, 1, true, false)
			healEffect(e)
		end
	end
end



function mod:FleshDeathHeadInit(entity)
	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
	entity.CanShutDoors = true
	entity:GetData().playerHeals = 0
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.FleshDeathHeadInit, EntityType.ENTITY_FLESH_DEATHS_HEAD)

function mod:FleshDeathHeadUpdate(entity)
	local data = entity:GetData()

	-- Create healing aura
	if not data.aura or not data.aura:Exists() then
		data.aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.Entities.HealingAura, 0, entity.Position, Vector.Zero, entity):ToEffect()
		data.aura:FollowParent(entity)
		data.aura.Parent = entity
	end


	-- Make them not heal players infinitely if friendly
	if data.playerHeals >= Settings.MaxPlayerHeals then
		entity:Die()
	end

	-- Heal
	if entity.ProjectileCooldown <= 0 then
		mod:FleshDeathHeadHeal(entity)
		entity.ProjectileCooldown = Settings.Cooldown
	else
		entity.ProjectileCooldown = entity.ProjectileCooldown - 1
	end


	-- Don't shoot projectiles on death
	if entity:IsDead() then
		mod:FleshDeathHeadHeal(entity)

		-- Effects
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, entity)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, entity)
		mod:PlaySound(nil, SoundEffect.SOUND_MEATY_DEATHS, 0.9)
		mod:PlaySound(nil, SoundEffect.SOUND_EXPLOSION_WEAK)

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.FleshDeathHeadUpdate, EntityType.ENTITY_FLESH_DEATHS_HEAD)



--[[ Healing aura ]]--
function mod:HealingAuraInit(effect)
	effect:GetSprite():Play("FadeIn", true)
	effect.DepthOffset = -1000
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.HealingAuraInit, mod.Entities.HealingAura)

function mod:HealingAuraUpdate(effect)
	local sprite = effect:GetSprite()

	-- Loop
	if effect.State == 0 then
		if not sprite:IsPlaying("FadeIn") then
			mod:LoopingAnim(sprite, "Idle")
		end

		-- Disappear without a parent
		if not effect.Parent or effect.Parent:HasMortalDamage() then
			effect.State = 1
			sprite:Play("FadeOut", true)
		end

	-- End
	elseif effect.State == 1 then
		if sprite:IsFinished() then
			effect:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.HealingAuraUpdate, mod.Entities.HealingAura)