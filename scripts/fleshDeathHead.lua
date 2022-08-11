local mod = BetterMonsters
local game = Game()

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

	if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		for i = 0, game:GetNumPlayers() do
			local player = Isaac.GetPlayer(i)
			
			if entity.Position:Distance(player.Position) <= Settings.Range and not player:HasFullHearts() then
				player:AddHearts(playerHeal)
				SFXManager():Play(sound)
				data.playerHeals = data.playerHeals + 1
				
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, player.Position, Vector.Zero, entity)
				effect:ToEffect():FollowParent(player)
				effect:GetSprite().Offset = Vector(0, -40)
				effect.DepthOffset = player.DepthOffset + 1
			end
		end

	else
		for _,v in pairs(Isaac.GetRoomEntities()) do
			if v.Type > 9 and v.Type < 1000 and entity.Position:Distance(v.Position) <= Settings.Range and not (v.Type == 212 and v.Variant == 1 and v.SubType == 4286)
			and v.HitPoints < v.MaxHitPoints and v.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
				v:AddHealth(Settings.HealAmount * multiplier)
				SFXManager():Play(sound)
				v:SetColor(Color(1,1,1, 1, 0.65,0,0), 15, 1, true, false)
				
				local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEART, 0, v.Position, Vector.Zero, entity)
				effect:ToEffect():FollowParent(v)
				effect:GetSprite().Offset = Vector(0, -40)
				effect.DepthOffset = v.DepthOffset + 1
			end
		end
	end
end



function mod:fleshDeathHeadReplace(entity)
	entity:Morph(EntityType.ENTITY_DEATHS_HEAD, 1, 4286, entity:GetChampionColorIdx())
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.fleshDeathHeadReplace, EntityType.ENTITY_FLESH_DEATHS_HEAD)

function mod:fleshDeathHeadUpdate(entity)
	if entity.Variant == 1 and entity.SubType == 4286 then
		local data = entity:GetData()

		entity.SplatColor = Color(1,0,0, 1) -- Has to be in the update callback to work for some reason

		-- Healing aura
		if not data.aura or (data.aura and not data.aura:Exists()) then
			data.aura = Isaac.Spawn(EntityType.ENTITY_EFFECT, 868, 0, entity.Position, Vector.Zero, entity):ToEffect()
			data.aura.Parent = entity
			data.aura:GetSprite():Play("FadeIn", true)
			data.aura.DepthOffset = -1000
		end

		if entity.ProjectileCooldown <= 0 then
			fleshDeathHeadHeal(entity)
			entity.ProjectileCooldown = Settings.Cooldown
		
		else
			entity.ProjectileCooldown = entity.ProjectileCooldown - 1
		end

		-- Make them not heal players infinitely if friendly
		if not data.playerHeals then
			data.playerHeals = 0
		elseif data.playerHeals >= Settings.MaxPlayerHeals then
			entity:Die()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fleshDeathHeadUpdate, EntityType.ENTITY_DEATHS_HEAD)

function mod:fleshDeathHeadDeath(entity)
	if entity.Variant == 1 and entity.SubType == 4286 then
		fleshDeathHeadHeal(entity, true)
		
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 3, entity.Position, Vector.Zero, nil)
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4, entity.Position, Vector.Zero, nil)
		SFXManager():Play(SoundEffect.SOUND_MEATY_DEATHS, 0.9)
		SFXManager():Play(SoundEffect.SOUND_EXPLOSION_WEAK, 1.1)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.fleshDeathHeadDeath, EntityType.ENTITY_DEATHS_HEAD)



-- Healing aura
function mod:healingAuraUpdate(effect)
	if effect.Parent ~= nil then
		local sprite = effect:GetSprite()

		effect:FollowParent(effect.Parent)

		if sprite:IsPlaying("FadeIn") and sprite:GetFrame() == 11 then
			sprite:Play("Idle", true)
		end

		if effect.Parent:HasMortalDamage() then
			if not sprite:IsPlaying("FadeOut") then
				sprite:Play("FadeOut", true)
			end
			if sprite:GetFrame() == 9 then
				effect:Remove()
			end
		end

	else
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.healingAuraUpdate, 868)