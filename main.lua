ReworkedFoes = RegisterMod("Improved & Reworked Foes", 1)
local mod = ReworkedFoes
mod.Version = "3.1.0"



--[[ Load scripts ]]--
function mod:LoadScripts(scripts, subfolder)
	subfolder = subfolder or ""
	for i, script in pairs(scripts) do
		include("rf_scripts." .. subfolder .. "." .. script)
	end
end


-- General
local generalScripts = {
	"constants",
	"library",
	"dss.dssmenu",
	"projectiles",
	"misc",
	"hiddenEnemies",
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
	"holyLeech",
	"lump",
	"membrain",
	"scarredParaBite",
	"eye",
	"giantSpike",
	"nest",
	"babyLongLegs",
	"flamingFatty",
	"dankDeathsHead",
	"momsHand",
	"codWorm",
	"skinny",
	"tumors",
	"nerveEnding2",
	"fatBat",
	"ragling",
	"dartFly",
	"blackBony",
	"blackGlobin",
	"megaClotty",
	"boneKnight",
	"fleshDeathHead",
	"ulcer",
	"blister",
	"portal",
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
	"fallenAngels",
}
mod:LoadScripts(minibossScripts, "minibosses")


-- Bosses
local bossScripts = {
	"chad",
	"carrionQueen",
	"gish",
	"mom",
	"scolex",
	"conquest",
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
	"mrFred",
	"stain",
	"forsaken",
	"ragMega",
	"sisterVis",
	"beast",
}
mod:LoadScripts(bossScripts, "bosses")


-- Champions
local championScripts = {
	"vanillaChanges",
	"pin",
	"fallen",
	"headlessHorseman",
	"darkOne",
}
mod:LoadScripts(championScripts, "champions")


-- Compatibility
local compatibilityScripts = {
	"baptismal_preloader",
	"compatibility",
	"retribution",
}
mod:LoadScripts(compatibilityScripts, "compatibility")





--[[ Startup text ]]--
local startupText = mod.Name .. " " .. mod.Version .. " Initialized"
Isaac.DebugString(startupText)

local flavorText = {
	"The reworkening",
	"Look Teratomar, it's you!",
	"Thank you for playing :)",
	"Delirium rework coming out in 202X",
	"All oiled up",
	"Monstro rework when?",
	"Now 11% funnier!",
	"Not for baby gamers",
	"01101000 01101001 00100000 00111010 00101001",
	"Reworked Foes? More like STINKY Foes",
	"Hi YouTube / Twitch!",
	"Also check out Improved Backdrops and Visuals!",
	"Ruining Tainted Lost runs since 2022!",
	"ratratrat was here!",
	"WARNING: Some reworks might require you to pay attention!",
	"It will even fix your marriage!",
	"The Husk was hiding the Forgotten this entire time",
	"We will rework your wife. We will rework your son. We will rework your infant daughter.",
	"Goonin' with the boys",
}
print(startupText .. " - " .. mod:RandomIndex(flavorText))