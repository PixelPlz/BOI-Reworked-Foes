local mod = BetterMonsters
local game = Game()

dustColor = Color(0.8,0.8,0.8, 0.8, 0.05,0.025,0)
dustColor:SetColorize(1, 1, 1, 1)



--[[ Wizoob ]]--
function mod:wizoobUpdate(entity)
	if entity.StateFrame > 30 then
		entity.StateFrame = 30
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.wizoobUpdate, EntityType.ENTITY_WIZOOB)



--[[ Red Ghost ]]--
function mod:redGhostUpdate(entity)
	local sprite = entity:GetSprite()
	if entity.StateFrame > 50 then
		entity.StateFrame = 50
	end
	
	if entity.State == 8 and sprite:GetFrame() == 0 then
		local vector = 0
		if sprite:GetAnimation() == "ShootDown" then
			vector = 90
		elseif sprite:GetAnimation() == "ShootLeft" then
			vector = 180
		elseif sprite:GetAnimation() == "ShootUp" then
			vector = 270
		end

		local tracer = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.GENERIC_TRACER, 0, entity.Position + Vector(0, entity.SpriteScale.Y * -8), Vector.Zero, entity):ToEffect()
		tracer.LifeSpan = 15
		tracer.Timeout = 1
		tracer.TargetPosition = Vector.FromAngle(vector)
		tracer:GetSprite().Color = Color(1,0,0, 0.25)
		tracer.SpriteScale = Vector(2, 0)
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.redGhostUpdate, EntityType.ENTITY_RED_GHOST)



--[[ Dust ]]--
function mod:dustUpdate(entity)
	if entity.V1.X < 0.1 and entity:IsFrame(16, 0) then
		for i = 1, 3 do
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, entity.Position + Vector(0, -24) + (Vector.FromAngle(math.random(0, 359)) * 10), Vector.Zero, entity):GetSprite().Color = dustColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.dustUpdate, EntityType.ENTITY_DUST)