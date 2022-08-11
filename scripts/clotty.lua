local mod = BetterMonsters
local game = Game()



--[[ Clotty ]]--
function mod:clottyUpdate(entity)
	local sprite = entity:GetSprite()

	if entity.Variant ~= 3 and entity.State == NpcState.STATE_ATTACK and sprite:GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end

	-- I.Blob
	if entity.Variant == 2 then
		entity.Variant = 400

	elseif entity.Variant == 400 then
		if entity:HasMortalDamage() then
			entity.SplatColor = Color(1,1,1, 1, 0,0,0)
		elseif sprite:GetFrame() == 9 then
			entity.SplatColor = Color(0.2,0.8,0.8, 0.5, 0.4,0.8,1)
		else
			entity.SplatColor = Color(1,1,1, 0, 0,0,0)
		end

		-- Shoot tear bullets instead
		if sprite:IsEventTriggered("Shoot") then
			local params = ProjectileParams()
			params.Variant = ProjectileVariant.PROJECTILE_TEAR
			entity:FireProjectiles(entity.Position, Vector(10, 0), 8, params)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.clottyUpdate, EntityType.ENTITY_CLOTTY)

--[[ Cloggy ]]--
function mod:cloggyUpdate(entity)
	if entity.State == NpcState.STATE_ATTACK and entity:GetSprite():GetFrame() > 2 then
		entity.Velocity = Vector.Zero
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.cloggyUpdate, EntityType.ENTITY_CLOGGY)