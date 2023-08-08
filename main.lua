BetterMonsters = RegisterMod("Improved & Reworked Foes", 1)
local mod = BetterMonsters



local startupText = mod.Name .. " v3.1.0 Initialized"
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
	for i = 1, #scripts do
		include("scripts." .. subfolder .. "." .. scripts[i])
	end
end


-- General
local generalScripts = {
	"constants",
	"utilities",
	"dss.dssmenu",
	"compatibility",
	"misc",
	"projectiles",
	"hiddenEnemies",
}
mod:LoadScripts(generalScripts)


-- Enemies
local enemyScripts = {
	"flamingGaper",
	"drownedCharger",
	"dankGlobin",
	"drownedBoomFly",
	"host",
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
	"camilloJr",
	"nerveEnding2",
	"psyTumor",
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
	--"wretched",
	"daddyLongLegs",
	"blueBaby",
	"hushBaby",
	--"turdlings",
	--"dangle",
	"gate",
	"mamaGurdy",
	"mrFred",
	--"lamb",
	"stain",
	"forsaken",
	"ragMega",
	--"sisterVis",
	--"delirium.main",
}
mod:LoadScripts(bossScripts, "bosses")


-- Champions
local championScripts = {
	"tweaks",
	"fallen",
	"headlessHorseman",
	"darkOne",
}
mod:LoadScripts(championScripts, "champions")


--[[
-- Delirium forms
local deliriumPhase1Scripts = {
	"famine",
	"babyPlum",
}
mod:LoadScripts(deliriumPhase1Scripts, "bosses.delirium.phase1")

local deliriumPhase2Scripts = {
	"pestilence",
}
mod:LoadScripts(deliriumPhase2Scripts, "bosses.delirium.phase2")

local deliriumPhase3Scripts = {
	"war",
}
mod:LoadScripts(deliriumPhase3Scripts, "bosses.delirium.phase3")

local deliriumPhase4Scripts = {
	"death",
}
mod:LoadScripts(deliriumPhase4Scripts, "bosses.delirium.phase4")

local deliriumPhase5Scripts = {
	"mom",
}
mod:LoadScripts(deliriumPhase5Scripts, "bosses.delirium.phase5")
]]--