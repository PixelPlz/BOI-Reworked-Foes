local mod = BetterMonsters
local game = Game()

local stevenColors = {
	Color(1,1,1, 1, 0,0,0),
	Color(1,1,1, 1, 0.2,0,0),
	Color(1,1,1, 1, 0,0.15,0),
	Color(1,1,1, 1, 0,0,0.175),
	Color(1,1,1, 1, 0.175,0.125,0),
	Color(1,1,1, 1, 0.175,0,0.125),
	Color(1,1,1, 1, 0,0.15,0.15)
}



function mod:stevenInit(entity)
	if entity.Variant == 1 then
		entity:GetData().timer = 120
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.stevenInit, EntityType.ENTITY_GEMINI)

function mod:stevenUpdate(entity)
	if entity.Variant == 1 or entity.Variant == 11 then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local room = game:GetRoom()

		-- Child logic
		if entity.Child then
			data.child = entity.Child
		end
		if data.child then
			if not data.child:Exists() then
				data.child = nil
			end
			if entity:HasMortalDamage() then
				data.child:GetData().timer = data.timer
			end
		end


		-- Teleport
		local function stevenTeleport()
			entity.Position = Vector(room:GetBottomRightPos().X + (room:GetTopLeftPos().X - entity.Position.X), room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - entity.Position.Y))
			data.color = stevenColors[math.random(1, #stevenColors)]
			entity:SetColor(Color(1,1,1, 1, 1,1,1), 5, 1, true, false)

			SFXManager():Play(SoundEffect.SOUND_STATIC)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 2, entity.Position, Vector.Zero, entity).DepthOffset = entity.DepthOffset + 10
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CREEP_STATIC, 0, entity.Position, Vector.Zero, entity):ToEffect().Scale = 1.5

			if data.child then
				data.child.Position = Vector(room:GetBottomRightPos().X + (room:GetTopLeftPos().X - data.child.Position.X), room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - data.child.Position.Y))
				data.child:GetData().color = data.color
				data.child:SetColor(Color(1,1,1, 1, 1,1,1), 5, 1, true, false)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 2, data.child.Position, Vector.Zero, data.child).DepthOffset = data.child.DepthOffset + 10
			end
		end

		-- Teleport timer
		if data.timer then
			if data.timer <= 0 then
				stevenTeleport()
				data.timer = 240
			else
				data.timer = data.timer - 1
			end
		end


		-- Random color after teleporting
		if data.color then
			sprite.Color = data.color
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.stevenUpdate, EntityType.ENTITY_GEMINI)