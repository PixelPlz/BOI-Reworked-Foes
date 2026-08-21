local mod = ReworkedFoes

local Settings = {
	MoveSpeed = 3.5,
	MoveSpeedFuzzy = 3,
	MoveSpeedCorny = 4,

	Cooldown = 90,
	ShotSpeed = 10,
}

-- Load the appropriate champion spritesheet
local function loadChampionSheet(entity, parent)
	parent = parent or entity
	local path = "gfx/bosses/classic/boss_068_teratomar_"

	-- Fuzzy champion
	if mod:IsFFChampion(parent, "FuzzyTeratomaBig") then
		entity:GetSprite():ReplaceSpritesheet(0, path .. "fuzzy.png", true)

	-- Corny champion
	elseif mod:IsFFChampion(parent, "CornyTeratomaBig") then
		local suffix = "corny"

		if FiendFolio:CheckStage("Corpse", {34, 43, 44}) then
			suffix = "corny_corpse"
		elseif FiendFolio:CheckStage("Dross", {45}) then
			suffix = "corny_dross"
		end

		local sheet = path .. suffix .. ".png"
		entity:GetSprite():ReplaceSpritesheet(0, sheet, true)
	end
end



--[[ Big ]]--
function mod:TeratomaBigUpdate(entity)
	if entity.Variant == 1 and entity:IsDead() then
		local center = Isaac.Spawn(mod.Entities.Type, mod.Entities.Teratomar, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
		local data = center:GetData()

		-- Orbiting chunks
		data.chunks = {}

		for i = 1, 3 do
			local chunk = Isaac.Spawn(EntityType.ENTITY_FISTULA_MEDIUM, 1, entity.SubType, entity.Position, Vector.Zero, entity):ToNPC()
			chunk.Parent = center
			chunk:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			table.insert(data.chunks, chunk)

			-- Create the cord
			local cord = Isaac.Spawn(EntityType.ENTITY_EVIS, 10, 0, center.Position, Vector.Zero, center):ToNPC()
			cord:GetData().DepthOffset = chunk.DepthOffset - 150
			cord:GetData().SplatColor = center.SplatColor
			cord:GetSprite():Load("gfx/teratomar.anm2", true)
			loadChampionSheet(cord, center)

			-- Set the connections
			cord.Parent = center
			cord.Target = chunk
			chunk.Child = cord
		end

		-- Fuzzy champion
		if mod:IsFFChampion(entity, "FuzzyTeratomaBig") then
			for i = -1, 1 do
				local xPos = entity.Position + Vector(i * 40, 0)
				Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, xPos, false)
				local yPos = entity.Position + Vector(0, i * 40)
				Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0, yPos, false)
			end

		-- Corny champion
		elseif mod:IsFFChampion(entity, "CornyTeratomaBig") then
			FiendFolio:softservesplatter(entity, 0)
		end

		return true
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.TeratomaBigUpdate, EntityType.ENTITY_FISTULA_BIG)



--[[ Medium ]]--
function mod:TeratomaMediumUpdate(entity)
	if entity.Variant == 1 and entity.Parent then
		if entity.Parent:IsDead() then
			entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		else
			mod:OrbitParent(entity, entity.Parent, 2, 90)
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
		entity.SplatColor = Color(0.15,0,0, 1, 0.13,0.13,0.13)

		entity.ProjectileCooldown = Settings.Cooldown
		entity.State = NpcState.STATE_MOVE

		-- Corny champion
		if mod:IsFFChampion(entity, "CornyTeratomaBig") then
			mod:ChangeMaxHealth(entity, entity.MaxHitPoints * 0.9)
			entity.Scale = 0.85
			entity.SplatColor = FiendFolio.ColorFadedBrowniePoop
		end

		loadChampionSheet(entity)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.TeratomarInit, mod.Entities.Type)

function mod:TeratomarUpdate(entity)
	if entity.Variant == mod.Entities.Teratomar then
		local sprite = entity:GetSprite()
		local data = entity:GetData()
		local target = entity:GetPlayerTarget()


		-- Move diagonally
		local speed = (mod:IsFFChampion(entity, "FuzzyTeratomaBig") and Settings.MoveSpeedFuzzy)
				   or (mod:IsFFChampion(entity, "CornyTeratomaBig") and Settings.MoveSpeedCorny)
				   or Settings.MoveSpeed

		mod:MoveDiagonally(entity, speed)

		if entity:CollidesWithGrid() and SoundEffect.SOUND_TERATOMA_BOUNCE_MEDIUM then
			mod:PlaySound(nil, SoundEffect.SOUND_TERATOMA_BOUNCE_MEDIUM, 1, 1, 30)
		end


		-- Idle
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
				params.Variant = mod:IsFFChampion(entity, "CornyTeratomaBig") and ProjectileVariant.PROJECTILE_CORN or ProjectileVariant.PROJECTILE_BONE

				local velocity = (target.Position - entity.Position):Resized(Settings.ShotSpeed)
				local projectiles = mod:FireProjectiles(entity, entity.Position, velocity, 4, params)

				-- Set the new sprites
				if not mod:IsFFChampion(entity, "CornyTeratomaBig") then
					for i, projectile in pairs(projectiles) do
						local projectileSprite = projectile:GetSprite()
						projectileSprite:Load("gfx/002.002_tooth tear.anm2", true)
						projectileSprite:Play("Tooth4Move", true)
						projectileSprite:ReplaceSpritesheet(0, "gfx/projectiles/tooth_shot_teratoma.png")
						projectileSprite:LoadGraphics()
					end
				end

				mod:PlaySound(entity, SoundEffect.SOUND_MONSTER_GRUNT_2, 1.1)
			end

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_MOVE
				entity.ProjectileCooldown = Settings.Cooldown
			end
		end


		-- Remove chunks from the list if they don't exist
		if data.chunks then
			for i, chunk in pairs(data.chunks) do
				if not chunk or not chunk:Exists() or chunk:IsDead() then
					if chunk.Child then
						chunk.Child:Kill()
					end
					table.remove(data.chunks, i)
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.TeratomarUpdate, mod.Entities.Type)