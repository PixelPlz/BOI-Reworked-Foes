BetterMonsters = RegisterMod("Improved and Reworked Foes", 1)
local mod = BetterMonsters



IRFstartupStrings = {
	"The reworkening",
	"Look Teratomar, it's you!",
	"Eternal edition",
	"Thank you for playing :)",
	"Delirium rework coming out in 202X",
	"No, there will not be options to toggle everything.",
	"I should get a job",
	"All oiled up",
	"Let me be clear Color(1,1,1, 0)",
	"Monstro rework when??",
	"Follow the turning coin",
	"Today's lucky numbers:\n"
	.. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)) .. " " .. tostring(math.random(99)),
	"Can't stop rewriting code",
	"Now 10% funnier!",
	"Conragulations, you are the 100th visitor! > Click here to redeem your free prize <",
	"The rat is coming.",
	"Julian style",
	"Not for baby gamers",
	"Try the grapefruit technique!",
	"01101000 01101001 00100000 00111010 00101001",
	"AudioJungle",
	"Reworked Foes? More like STINKY Foes xddd",
	"As seen on TV!",
	"Hi YouTube!",
	"+rep :steamhappy:",
	"For educational purposes only",
	"!FatManArrive",
	"Welcome to compatibility hell",
}

local StartupString = "Improved and Reworked Foes v3.0.0 Loaded"
Isaac.DebugString(StartupString)
print(StartupString .. " - " .. IRFstartupStrings[math.random(#IRFstartupStrings)])





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
	"bossHealthBars",
	--"dss",
	"configMenu", -- REMOVE
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
	--"ultraPride",
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
	--"itLives",
	"steven",
	"blightedOvum",
	--"fallen",
	--"headlessHorseman",
	"satan",
	"maskInfamy",
	--"wretched",
	"daddyLongLegs",
	"blueBaby",
	"hushBaby",
	--"turdlings",
	--"dangle",
	"gate",
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