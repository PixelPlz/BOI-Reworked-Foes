BetterMonsters = RegisterMod("Improved & Reworked Foes", 1)
local mod = BetterMonsters



local startupText = mod.Name .. " v3.0.7 Initialized"
Isaac.DebugString(startupText)

IRFflavorText = {
	"The reworkening",
	"Look Teratomar, it's you!",
	"Thank you for playing :)",
	"Delirium rework coming out in 202X",
	"All oiled up",
	"Monstro rework when?",
	"Follow the turning coin",
	"Today's lucky numbers:\n"
	.. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)),
	"Now 10% funnier!",
	"Not for baby gamers",
	"01101000 01101001 00100000 00111010 00101001",
	"Reworked Foes? More like STINKY Foes",
	"Hi YouTube / Twitch!",
	"Also check out Improved Backdrops and Visuals!",
	"Ruining Tainted Lost runs since 2022!",
	"ratratrat was here!",
	"WARNING: Some reworks might require you to pay attention!",
	"It will even fix your marriage!",
	"The bosses finally got some training",
	"The Husk was hiding the Forgotten this entire time",
}

local flavorText = IRFflavorText[math.random(#IRFflavorText)]
print(startupText .. " - " .. flavorText)





--[[ Load scripts ]]--
function mod:LoadScripts(scripts, subfolder)
	subfolder = subfolder or ""
	for i, script in pairs(scripts) do
		include("scripts." .. subfolder .. "." .. script)
	end
end


-- General
local generalScripts = {
	"constants",
	"utilities",
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
	"carrionQueen",
	"chad",
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
	"blueBaby",
	"hushBaby",
	"gate",
	"mamaGurdy",
	"mrFred",
	"stain",
	"forsaken",
	"ragMega",
}
mod:LoadScripts(bossScripts, "bosses")


-- Champions
local championScripts = {
	"vanillaChanges",
	"fallen",
	"headlessHorseman",
	"darkOne",
}
mod:LoadScripts(championScripts, "champions")


-- Compatibility
local compatibilityScripts = {
	"baptismal_preloader", -- This is retarded
	"compatibility",
	"retribution",
}
mod:LoadScripts(compatibilityScripts, "compatibility")