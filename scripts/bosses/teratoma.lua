local mod = BetterMonsters

local Settings = {
	MoveSpeed = 3.5,
	Cooldown = 90,
	ShotSpeed = 10,
}



--[[ Big ]]--
function mod:bigTeratomaUpdate(entity)
	if entity.Variant == 1 and entity:IsDead() then
		local center = Isaac.Spawn(200, IRFentities.teratomar, 0, entity.Position, Vector.Zero, entity):ToNPC()
		local data = center:GetData()
		
		-- Orbiting chunks
		data.chunks = {}
		for i = 1, 3 do
			local chunk = Isaac.Spawn(EntityType.ENTITY_FISTULA_MEDIUM, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
			data.chunks[i] = chunk
			chunk.Parent = center
			chunk:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			chunk.V2 = Vector(2, 80) -- Rotation speed / Distance from parent

			mod:QuickCord(center, chunk, "teratomar")
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.bigTeratomaUpdate, EntityType.ENTITY_FISTULA_BIG)

--[[ Medium ]]--
function mod:mediumTeratomaUpdate(entity)
	if entity.Variant == 1 and entity.Parent then
		if entity.Parent:IsDead() then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		else
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		end
		

		-- Get offset
		local siblingCount = 0
		for i, sibling in pairs(Isaac.FindByType(entity.Type, entity.Variant, -1, false, true)) do
			if sibling:HasCommonParentWithEntity(entity) then
				sibling:ToNPC().I2 = i
				siblingCount = siblingCount + 1
			end
		end

		-- Orbit parent
		entity.V1 = Vector(((360 / siblingCount) * entity.I2), entity.V1.Y + entity.V2.X) -- Rotation offset / Current rotation
		if entity.V1.Y >= 360 then
			entity.V1 = Vector(entity.V1.X, entity.V1.Y - 360)
		end
		entity.Position = mod:Lerp(entity.Position, entity.Parent.Position + (Vector.FromAngle(entity.V1.X + entity.V1.Y) * entity.V2.Y), 0.1)
		entity.Velocity = entity.Parent.Velocity
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.mediumTeratomaUpdate, EntityType.ENTITY_FISTULA_MEDIUM)



--[[ Look Teratomar it's you! ]]--
function mod:teratomarInit(entity)
	if entity.Variant == IRFentities.teratomar then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.ProjectileCooldown = Settings.Cooldown
		entity.State = NpcState.STATE_MOVE
		entity.SplatColor = Color(0.15,0,0, 1, 0.13,0.13,0.13)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.teratomarInit, 200)

function mod:teratomarUpdate(entity)
	if entity.Variant == IRFentities.teratomar then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()


		-- Move diagonally
		local xV = Settings.MoveSpeed
		local yV = Settings.MoveSpeed
		if entity.Velocity.X < 0 then
			xV = xV * -1
		end
		if entity.Velocity.Y < 0 then
			yV = yV * -1
		end
		entity.Velocity = mod:Lerp(entity.Velocity, Vector(xV, yV), 0.1)


		if entity.State == NpcState.STATE_MOVE then
			mod:LoopingAnim(sprite, "Idle")
			
			if entity.ProjectileCooldown <= 0 then
				entity.State = NpcState.STATE_ATTACK
				sprite:Play("Attack", true)
			else
				entity.ProjectileCooldown = entity.ProjectileCooldown - 1
			end

		-- Shoot
		elseif entity.State == NpcState.STATE_ATTACK then
			if sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = ProjectileVariant.PROJECTILE_BONE
				entity:FireProjectiles(entity.Position, (target.Position - entity.Position):Normalized() * Settings.ShotSpeed, 4, params)
				entity:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_2, 1.1, 0, false, 1)
			end
			
			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		-- Remove chunks from the list if they don't exist
		for i = 1, #data.chunks do
			local chunk = data.chunks[i]
			if chunk and (not chunk:Exists() or chunk:IsDead()) then
				if chunk.Child then
					chunk.Child:Remove()
				end

				table.remove(data.chunks, i)
			end
		end


		-- Gradually increase orbit distance
		if #data.chunks > 0 then
			for i = 1, #data.chunks do
				data.chunks[i]:ToNPC().V2 = Vector(2, 80 + (entity.MaxHitPoints - entity.HitPoints))
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.teratomarUpdate, 200)