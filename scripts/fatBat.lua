local mod = BetterMonsters
local game = Game()

local Settings = {
	MaxPoops = 3,
	PushBackSpeed = 5,
	Cooldown = 30,
	FartRadius = 80,
	GuanoVariant = 400
}

local function guanoUpdate(guano)
	local sprite = guano:GetSprite()
	sprite:ReplaceSpritesheet(0, "gfx/grid/grid_poop_guano.png")
	sprite:ReplaceSpritesheet(1, "gfx/effects/effect_poopspawn_white.png")
	sprite:LoadGraphics()
	guano:ToPoop():ReduceSpawnRate()
end



function mod:fatBatUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()


	-- Custom attacks
	if entity.State == NpcState.STATE_ATTACK then
		if entity.I2 < Settings.MaxPoops and math.random(1, 10) <= 4 and game:GetRoom():GetGridEntityFromPos(entity.Position) == nil then
			entity.State = NpcState.STATE_ATTACK3
		else
			entity.State = NpcState.STATE_ATTACK2
		end
		sprite:Play("Shooting", true)


	-- Shoot
	elseif entity.State == NpcState.STATE_ATTACK2 then
		if entity.I1 == 1 then
			entity.Velocity = -entity.V1 * Settings.PushBackSpeed
			SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 0.75)

			local params = ProjectileParams()
			params.FallingSpeedModifier = 5
			params.Variant = ProjectileVariant.PROJECTILE_PUKE
			entity:FireBossProjectiles(1, entity.Position + (entity.V1 * 10), 4, params)

		else
			entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)
		end


		if sprite:IsEventTriggered("Shoot") then
			entity.I1 = 1
			entity.V1 = (target.Position - entity.Position):Normalized()
			entity:PlaySound(SoundEffect.SOUND_SHAKEY_KID_ROAR, 1, 0, false, 0.9)

		elseif sprite:IsEventTriggered("Stop") or sprite:GetFrame() == 15 then
			entity.I1 = 0
		end

		if sprite:IsFinished("Shooting") then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown
		end


	-- Shit
	elseif entity.State == NpcState.STATE_ATTACK3 then
		entity.Velocity = (entity.Velocity + (Vector.Zero - entity.Velocity) * 0.25)

		if sprite:IsEventTriggered("Shoot") then
			game:ButterBeanFart(entity.Position, Settings.FartRadius, entity, true)
			entity:PlaySound(SoundEffect.SOUND_SHAKEY_KID_ROAR, 0.9, 0, false, 1)

			local guano = Isaac.GridSpawn(GridEntityType.GRID_POOP, Settings.GuanoVariant, entity.Position, false)
			if guano then
				guanoUpdate(guano)
				entity.I2 = entity.I2 + 1
			end
		end

		if sprite:IsFinished("Shooting") then
			entity.State = NpcState.STATE_MOVE
			entity.ProjectileCooldown = Settings.Cooldown / 2
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.fatBatUpdate, EntityType.ENTITY_FAT_BAT)



-- Keep the custom sprite for guano poops
function mod:guanoNewRoom()
	local room = game:GetRoom()

	for i = 0, (room:GetGridSize()) do
        local gent = room:GetGridEntity(i)

        if gent and gent:GetType() == GridEntityType.GRID_POOP and gent:GetSaveState().Variant == Settings.GuanoVariant then
			guanoUpdate(gent)
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.guanoNewRoom)

-- Proper guano gibs
function mod:poopGibUpdate(effect)
	if effect.FrameCount == 0 then
		if game:GetRoom():GetGridEntityFromPos(effect.Position) then
			local gent = game:GetRoom():GetGridEntityFromPos(effect.Position)
			if gent:GetType() == GridEntityType.GRID_POOP and gent:GetVariant() == Settings.GuanoVariant then
				local sprite = effect:GetSprite()
				sprite:ReplaceSpritesheet(0, "gfx/effects/effect_poopgibs_white.png")
				sprite:LoadGraphics()
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.poopGibUpdate, EffectVariant.POOP_PARTICLE)