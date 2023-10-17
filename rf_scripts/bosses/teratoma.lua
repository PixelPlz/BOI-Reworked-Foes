local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 3.5,
	Cooldown = 90,
	ShotSpeed = 10,
}



--[[ Big ]]--
function mod:TeratomaBigUpdate(entity)
	if entity.Variant == 1 and entity:IsDead() then
		local center = Isaac.Spawn(mod.Entities.Type, mod.Entities.Teratomar, 0, entity.Position, Vector.Zero, entity):ToNPC()
		local data = center:GetData()

		-- Orbiting chunks
		data.chunks = {}

		for i = 1, 3 do
			local chunk = Isaac.Spawn(EntityType.ENTITY_FISTULA_MEDIUM, 1, 0, entity.Position, Vector.Zero, entity):ToNPC()
			data.chunks[i] = chunk
			chunk.Parent = center
			chunk:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			chunk.V1 = Vector(70, 0)

			mod:QuickCord(center, chunk, "teratomar")
		end

		-- FF fuzzy champion cobwebs
		if FiendFolio and entity.SubType == 1 then
			for i = -1, 1 do
				local xPos = entity.Position + Vector(i * 40, 0)
				Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, xPos, false)
				local yPos = entity.Position + Vector(0, i * 40)
				Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, yPos, false)
			end
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.TeratomaBigUpdate, EntityType.ENTITY_FISTULA_BIG)



--[[ Medium ]]--
function mod:TeratomaMediumUpdate(entity)
	-- Orbit parent
	if entity.Variant == 1 and entity.Parent then
		if entity.Parent:IsDead() then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS

		else
			mod:OrbitParent(entity, entity.Parent, 2, entity.V1.X)

			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TeratomaMediumUpdate, EntityType.ENTITY_FISTULA_MEDIUM)



--[[ Teratomar ]]--
function mod:TeratomarInit(entity)
	if entity.Variant == mod.Entities.Teratomar then
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

		entity.ProjectileCooldown = Settings.Cooldown
		entity.State = NpcState.STATE_MOVE
		entity.SplatColor = Color(0.15,0,0, 1, 0.13,0.13,0.13)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.TeratomarInit, mod.Entities.Type)

function mod:TeratomarUpdate(entity)
	if entity.Variant == mod.Entities.Teratomar then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()


		-- Move diagonally
		mod:MoveDiagonally(entity, Settings.MoveSpeed)

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

				-- For FF fuzzy champion
				local fireMode = 4
				if FiendFolio and entity.SubType == 1 then
					fireMode = 2
				end

				for i,projectile in pairs(mod:FireProjectiles(entity, entity.Position, (target.Position - entity.Position):Resized(Settings.ShotSpeed), fireMode, params)) do
					local projectileSprite = projectile:GetSprite()
					projectileSprite:Load("gfx/002.002_tooth tear.anm2", true)
					projectileSprite:Play("Tooth4Move", true)

					projectileSprite:ReplaceSpritesheet(0, "gfx/projectiles/tooth_shot_teratoma.png")
					projectileSprite:LoadGraphics()
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_2, 1.1)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		if data.chunks then
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
					data.chunks[i]:ToNPC().V1 = Vector(70 + (entity.MaxHitPoints - entity.HitPoints) / 2, 0)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TeratomarUpdate, mod.Entities.Type)