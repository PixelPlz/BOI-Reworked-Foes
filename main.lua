ReworkedFoes = RegisterMod("Improved & Reworked Foes", 1)
local mod = ReworkedFoes
mod.Version = "3.x.x"



--[[ Load scripts ]]--
function mod:LoadScripts(scripts, subfolder)
	subfolder = subfolder and subfolder .. "." or ""

	for i, script in pairs(scripts) do
		include("rf_scripts." .. subfolder .. script)
	end
end


-- General
local generalScripts = {
	"constants",
	"library",
	"dss.dssmenu",
	"projectiles",
}
mod:LoadScripts(generalScripts)


-- Enemies
local enemyScripts = {
	"flamingGaper",
	"drownedCharger",
	"dankGlobin",
	"drownedBoomFly",
	"hostBreaking",
	"hoppers",
	"redMaw",
	"angelicBaby",
	"selflessKnight",
	"pokies",
	"sketches",
	"greedyEnemies",
	"lump",
	"membrain",
	"scarredParaBite",
	"eye",
	"eternalFly",
	"giantSpike",
	"nest",
	"babyLongLegs",
	"dankDeathsHead",
	"momsHand",
	"codWorm",
	"oob",
	"skinny",
	"homunculusBegotten",
	"tumors",
	"nerveEnding2",
	"ragling",
	"dartFly",
	"fatBat",
	"blackBony",
	"blackGlobin",
	"megaClotty",
	"boneKnight",
	"fleshDeathHead",
	"ulcer",
	"blister",
	"portal",
	"adultLeech",
	"misc",
	"champions",
}
mod:LoadScripts(enemyScripts, "enemies")


-- Minibosses
local minibossScripts = {
	"sloth",
	"ultraPride",
	"lust",
	"wrath",
	"gluttony",
	"greed",
	"envy",
	"pride",
	"angels",
}
mod:LoadScripts(minibossScripts, "minibosses")


-- Bosses
local bossScripts = {
	"chad",
	"carrionQueen",
	"gish",
	"mom",
	"pin",
	"scolex",
	"famine",
	"pestilence",
	"war",
	"conquest",
	"death",
	"husk",
	"lokii",
	"teratoma",
	"blastocyst",
	"itLives",
	"steven",
	"blightedOvum",
	"satan",
	"maskInfamy",
	"daddyLongLegs",
	"triachnid",
	"isaac",
	"blueBaby",
	"hushBaby",
	"gate",
	"mamaGurdy",
	"adversary",
	"mrFred",
	"stain",
	"forsaken",
	"hushFixes",
	"ragMega",
	"sisterVis",
	"siren",
	"beast",
	"misc",
	"champions",
}
mod:LoadScripts(bossScripts, "bosses")


-- Compatibility
local compatibilityScripts = {
	"baptismal_preloader",
	"loader",
	"warning",
}
mod:LoadScripts(compatibilityScripts, "compatibility")



--[[ Startup text ]]--
local startupText = mod.Name .. " " .. mod.Version .. " Initialized"
Isaac.DebugString(startupText)
print(startupText)