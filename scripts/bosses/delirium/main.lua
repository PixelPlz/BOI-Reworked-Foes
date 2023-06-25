local mod = BetterMonsters

local Settings = {
	--
}



IRFdelirium_Scripts = {
	{}, -- Phase 1
	{}, -- Phase 2
	{}, -- Phase 3
	{}, -- Phase 4
	{}, -- Phase 5
}

function mod:AddDeliriumForm(phase, bossType, bossVariant, bossScript)
	local bossData = {
		type 	= bossType,
		variant = bossVariant,
		script  = bossScript,
	}
	table.insert(IRFdelirium_Scripts[phase], bossData)
end



function mod:deliriumInit(entity)
	entity.State = NpcState.STATE_IDLE
	entity:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

	local data = entity:GetData()
	data.phase = 1
	data.transformed = false
	data.transformTimer = 60
	data.submerged = false
	data.shadowSize = 0
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, mod.deliriumInit, EntityType.ENTITY_DELIRIUM)

function mod:deliriumUpdate(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	--[[ Functions ]]--
	-- Reset variables for transformations
	local function resetVariables()
		entity.I1 = 0
		entity.I2 = 0
		entity.StateFrame = 0
		entity.ProjectileCooldown = 0
		entity.ProjectileDelay = -1
		entity.GroupIdx = -1

		entity.V1 = Vector.Zero
		entity.V2 = Vector.Zero
		entity.TargetPosition = Vector.Zero

		sprite.FlipX = false
		sprite.Color = Color.Default
	end


	-- Transform to a different form
	data.transform = function()
		entity.State = NpcState.STATE_APPEAR_CUSTOM
		data.transformed = true
		data.currentScript(entity, "init")

		resetVariables()
	end


	-- Transform back to the main form
	data.transformBack = function()
		sprite:Load("gfx/412.000_delirium.anm2", true)
		sprite:Play("Blink", true)

		entity:SetSize(40, Vector(1, 1), 40)
		data.shadowSize = 0

		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
		entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

		entity.State = NpcState.STATE_APPEAR_CUSTOM
		data.transformed = false
		data.transformTimer = 60

		resetVariables()
	end





	--[[ Always active ]]--
	--[[ Fake shadow
	if not data.shadow then
		data.shadow = Isaac.Spawn(EntityType.ENTITY_EFFECT, IRFentities.ShadowHelper, 0, entity.Position, Vector.Zero, entity):ToEffect()
		data.shadow:FollowParent(entity)
		data.shadow.SortingLayer = SortingLayer.SORTING_BACKGROUND
	else
		data.shadow:GetSprite():SetFrame(data.shadowSize)
	end ]]--


	-- Disable collision when submerged
	if sprite:IsEventTriggered("Submerge") then
		data.submerged = true
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

	elseif sprite:IsEventTriggered("Surface") then
		data.submerged = false
		entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
	end





	--[[ Main form ]]--
	if data.transformed == false then
		-- Idle
		if entity.State == NpcState.STATE_IDLE then
			entity.Velocity = Vector.Zero
			mod:LoopingAnim(sprite, "Idle")


			-- Transform
			if data.transformTimer <= 0 then
				local possibleTransformations = {}

				for i, entry in pairs(IRFdelirium_Scripts[data.phase]) do
					if Game():HasEncounteredBoss(entry.type, entry.variant) then
						table.insert(possibleTransformations, entry.script)
					end
				end

				-- If there aren't enough valid transformations then summon some valid bosses
				if #possibleTransformations > 0 then
					data.currentScript = mod:RandomIndex(possibleTransformations)
					entity.State = NpcState.STATE_SPECIAL
					sprite:Play("Blink", true)

				else
					print("No valid transformation!")
				end

			else
				data.transformTimer = data.transformTimer - 1
			end


		-- Transforming into another form
		elseif entity.State == NpcState.STATE_SPECIAL then
			entity.Velocity = Vector.Zero

			if sprite:IsFinished() then
				data.transform()
			end


		-- Transforming back from another form
		elseif entity.State == NpcState.STATE_APPEAR_CUSTOM then
			entity.Velocity = Vector.Zero

			if sprite:IsFinished() then
				entity.State = NpcState.STATE_IDLE
			end
		end





	--[[ Transformed ]]--
	elseif data.transformed == true then
		-- Execute transformation script
		data.currentScript(entity, "update")
    end


	return true
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, mod.deliriumUpdate, EntityType.ENTITY_DELIRIUM)

-- Don't take damage when submerged
function mod:deliriumDMG(target, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	local data = target:GetData()

	if data.transformed == true then
		local input = {
			damageAmount = damageAmount,
			damageFlags = damageFlags,
			damageSource = damageSource,
			damageCountdownFrames = damageCountdownFrames,
		}
		return data.currentScript(entity, "take DMG", input)
	end

	if target:GetData().submerged == true then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.deliriumDMG, EntityType.ENTITY_DELIRIUM)

function mod:deliriumCollide(entity, target, bool)
	if data.transformed == true then
		local input = {
			target = target,
			bool = bool,
		}
		return data.currentScript(entity, "collision", input)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, mod.deliriumCollide, EntityType.ENTITY_DELIRIUM)

-- Get rid of the shadow helper on death
function mod:deliriumDeath(entity)
	if entity:GetData().shadow then
		entity:GetData().shadow:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.deliriumDeath, EntityType.ENTITY_DELIRIUM)