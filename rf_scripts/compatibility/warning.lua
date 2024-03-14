local mod = ReworkedFoes

mod.IncompatibleMods = {
	{ Variable = bpattern, 		Name = "Hardmode Major Boss Patterns" },
	{ Variable = SCROTOMODPLUS, Name = "SCROTO MOD +"},
}



function mod:CompatibilityWarning()
	local level = Game():GetLevel()

	-- Only check in the starting room
	if level:GetCurrentRoomIndex() == level:GetStartingRoomIndex() then
		-- Check for incompatible mods
		local foundIncompatibleMods = {}

		for i, stinky in pairs(mod.IncompatibleMods) do
			if stinky.Variable then
				table.insert(foundIncompatibleMods, stinky.Name)
			end
		end


		-- Incompatible mods found
		if #foundIncompatibleMods > 0 then
			local textX = Isaac.GetScreenWidth() / 3 - 15
			local textY = Isaac.GetScreenHeight() / 3 - 15
			local textScale = 0.5
			local textNewLineY = 8

			-- Create the text
			local text = {
				"WARNING from " .. mod.Name .. "! Incompatible mods detected:",
				"",
				"These mods WILL BREAK certain things in Reworked Foes!",
				"It is highly recommended that you disable them.",
			}
			for i, name in pairs(foundIncompatibleMods) do
				local textName = " - " .. name
				table.insert(text, 2, textName)
			end

			-- Render it
			for i, line in pairs(text) do
				Isaac.RenderScaledText(line, textX, textY + i * textNewLineY, textScale, textScale, 255,255,255,1)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.CompatibilityWarning)