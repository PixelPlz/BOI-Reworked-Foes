local mod = ReworkedFoes



local function RenderWarning(name)
	local textX = Isaac.GetScreenWidth() / 5 - 10
	local textY = Isaac.GetScreenHeight() / 3
	local textScale = 1
	local textNewLineY = 16

	local text = {
		"WARNING from " .. mod.Name .. "!",
		name .. " is not enabled or did not load correctly!",
		"The mod will not function without it!",
	}

	for i, line in pairs(text) do
		Isaac.RenderScaledText(line, textX, textY + i * textNewLineY, textScale, textScale, 255,0,0,1)
	end
end

function mod:DependencyWarning()
	local level = Game():GetLevel()

	-- Only check in the starting room
	if level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() then
		-- Check for REPENTOGON
		if not REPENTOGON then
			RenderWarning("REPENTOGON")
			print(REPENTOGON.Version)

		-- Check for Reworked Foes
		elseif not ReworkedFoes then
			RenderWarning("Reworked Foes")
			print(ReworkedFoes.Version)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.DependencyWarning)