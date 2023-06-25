local mod = BetterMonsters

local Settings = {
	
}



-- Changed from main form
local function Init(entity)
	local sprite = entity:GetSprite()
	sprite:Load("gfx/" .. "cool animation" .. ".anm2", true)
	sprite:Play("Appear", true)

	entity:SetSize(40, Vector(1, 1), 40)
	entity:GetData().shadowSize = 10

	entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
	entity.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
end


-- Update
local function Update(entity)
	local sprite = entity:GetSprite()
	local target = entity:GetPlayerTarget()
	local data = entity:GetData()
	local room = Game():GetRoom()


	-- Transform animation
	if entity.State == NpcState.STATE_APPEAR_CUSTOM then
		entity.Velocity = Vector.Zero

		if sprite:IsFinished() then
			entity.State = insert state here
		end


	-- 
	elseif entity.State == insert state here then
		


	-- Change back to main form
	elseif entity.State == NpcState.STATE_SPECIAL then
		entity.Velocity = Vector.Zero

		if sprite:IsFinished() then
			data.transformBack()
		end
	end
end


-- Collision with something
local function Collide(entity, target, bool)
	
end


-- Taken damage from something
local function TakeDMG(entity, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	
end


-- Changed back to main form
local function ChangeBack(entity)
	
end



-- Callbacks (unnecessary ones can be removed)
local function Callbacks(entity, callback, input)
	if callback == "init" then
		Init(entity)

	elseif callback == "update" then
		Update(entity)

	elseif callback == "collision" then
		return Collide(entity, input.target, input.bool)

	elseif callback == "take DMG" then
		return TakeDMG(entity, input.damageAmount, input.damageFlags, input.damageSource, input.damageCountdownFrames)

	elseif callback == "change back" then
		ChangeBack(entity)
	end
end

-- Add boss to transformation list (for which Delirum phase, required boss ID, required boss variant, script to use)
mod:AddDeliriumForm(1, type, variant, Callbacks)