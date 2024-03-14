ReworkedFoesChampions = RegisterMod("Reworked Foes Champions", 1)
local mod = ReworkedFoesChampions



--[[ Load scripts ]]--
function mod:LoadScripts(scripts)
	for i, script in pairs(scripts) do
		include("rf_scripts.champions" .. "." .. script)
	end
end

local championScripts = {
	"warning",
	"constants",
	"compatibility",
	"lust",
	"pin",
	"darkOne",
}
mod:LoadScripts(championScripts)



--[[ Startup text ]]--
local startupText = "Reworked Foes Champion Add-on Initialized"
Isaac.DebugString(startupText)
print(startupText)