local mod = BetterMonsters



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
		local room = Game():GetRoom()

		-- Child logic
		if entity.Child then
			data.child = entity.Child
		end
		if data.child then
			if not data.child:Exists() then
				data.child = nil
			end
			if entity:HasMortalDamage() and data.child then
				data.child:GetData().timer = data.timer
			end
		end


		-- Teleport
		local function stevenTeleport()
			local pos = Vector(room:GetBottomRightPos().X + (room:GetTopLeftPos().X - entity.Position.X), room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - entity.Position.Y))
			entity.Position = room:FindFreePickupSpawnPosition(pos, 0, true, false)
			entity:SetColor(Color(1,1,1, 1, 1,1,1), 5, 1, true, false)

			SFXManager():Play(SoundEffect.SOUND_STATIC)
			Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 2, entity.Position, Vector.Zero, entity).DepthOffset = entity.DepthOffset + 10
			mod:QuickCreep(EffectVariant.CREEP_STATIC, entity, entity.Position, 1.5)

			if data.child then
				local childPos = Vector(room:GetBottomRightPos().X + (room:GetTopLeftPos().X - data.child.Position.X), room:GetBottomRightPos().Y + (room:GetTopLeftPos().Y - data.child.Position.Y))
				data.child.Position = room:FindFreePickupSpawnPosition(childPos, 0, true, true)
				data.child:SetColor(Color(1,1,1, 1, 1,1,1), 5, 1, true, false)
				Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BIG_SPLASH, 2, data.child.Position, Vector.Zero, data.child).DepthOffset = data.child.DepthOffset + 10
				
				-- Prevent steven baby from shooting right after teleporting
				data.child:ToNPC().ProjectileCooldown = 30
				if data.child:ToNPC().State == NpcState.STATE_ATTACK then
					data.child:ToNPC().State = NpcState.STATE_MOVE
					data.child:GetSprite():Play("Walk01", true)
				end
			end
		end

		-- Teleport timer
		if data.timer then
			if data.timer <= 0 then
				stevenTeleport()
				data.timer = 240

			else
				if data.timer <= 30 then
					local num = (30 - data.timer) * 0.02
					entity:SetColor(Color(1,1,1, 1, num,num,num), 5, 1, true, false)
				end
				data.timer = data.timer - 1
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.stevenUpdate, EntityType.ENTITY_GEMINI)