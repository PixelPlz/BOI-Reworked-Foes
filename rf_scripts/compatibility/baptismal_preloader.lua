local loadPreloader = not BaptismalPreloader
BaptismalPreloader = Retribution or BaptismalPreloader or {Queue = {}}
local mod = BaptismalPreloader

--[[
	Adds access for the following functions:

	BaptismalPreloader.GenerateEntityDataset
	BaptismalPreloader.GenerateTransformationDataset
	BaptismalPreloader.AddBaptismalData
	BaptismalPreloader.AddAntibaptismalData
	BaptismalPreloader.ToggleAntibaptismalSpawnerBlacklist
]]

local functionsList = {
	"AddBaptismalData",
	"AddAntibaptismalData",
	"ToggleAntibaptismalSpawnerBlacklist"
}

if loadPreloader then
	local backdropLookup = {
		-- None
		none = -1,

		-- Floors
		basement				= BackdropType.BASEMENT,
		celler					= BackdropType.CELLAR,
		["burning basement"]	= BackdropType.BURNT_BASEMENT,
		caves					= BackdropType.CAVES,
		catacombs				= BackdropType.CATACOMBS,
		["flooded caves"]		= BackdropType.FLOODED_CAVES,
		depths					= BackdropType.DEPTHS,
		necropolis				= BackdropType.NECROPOLIS,
		["dank depths"]			= BackdropType.DANK_DEPTHS,
		womb					= BackdropType.WOMB,
		utero					= BackdropType.UTERO,
		["scarred womb"]		= BackdropType.SCARRED_WOMB,
		["blue womb"]			= BackdropType.BLUE_WOMB,
		cathedral				= BackdropType.CATHEDRAL,
		chest					= BackdropType.CHEST,
		sheol					= BackdropType.SHEOL,
		["dark room"]			= BackdropType.DARKROOM,
		downpour				= BackdropType.DOWNPOUR,
		dross					= BackdropType.DROSS,
		mines					= BackdropType.MINES,
		ashpit					= BackdropType.ASHPIT,
		mausoleum				= BackdropType.MAUSOLEUM,
		gehenna					= BackdropType.GEHENNA,
		corpse					= BackdropType.CORPSE,
		--mortis				= BackdropType.MORTIS,

		-- Special
		["mega satan"]			= BackdropType.MEGA_SATAN,
		library					= BackdropType.LIBRARY,
		shop					= BackdropType.SHOP,
		["isaac's bedroom"]		= BackdropType.ISAAC,
		["barren bedroom"]		= BackdropType.BARREN,
		secret					= BackdropType.SECRET,
		dice					= BackdropType.DICE,
		arcade					= BackdropType.ARCADE,
		error					= BackdropType.ERROR_ROOM,
		["greed shop"]			= BackdropType.GREED_SHOP,
		crawlspace				= BackdropType.DUNGEON,
		sacrifice				= BackdropType.SACRIFICE,
		planetarium				= BackdropType.PLANETARIUM,
	}

	function mod.GenerateEntityDataset(arg1, arg2, arg3)
		if type(arg1) == "string" then -- Entity name and optional subtype passed
			if Isaac.GetEntityTypeByName(arg1) <= 0 then
				error("Invalid entity name passed to BaptismalPreloader.GenerateEntityDataset at position #1: " .. arg1, 2)
			end

			if arg2 and type(arg2) ~= "number" then
				error("Incorrect argument passed to BaptismalPreloader.GenerateEntityDataset at position #2, expected nil or number, got " .. type(arg2), 2)
			end

			return {
				Type	= Isaac.GetEntityTypeByName(arg1),
				Variant = Isaac.GetEntityVariantByName(arg1),
				SubType = arg2 or -1,
			}
		elseif type(arg1) == "number" then -- Raw entity data passed
			if arg2 and type(arg2) ~= "number" then
				error("Incorrect argument passed to BaptismalPreloader.GenerateEntityDataset at position #2, expected nil or number, got " .. type(arg2), 2)
			elseif arg3 and type(arg3) ~= "number" then
				error("Incorrect argument passed to BaptismalPreloader.GenerateEntityDataset at position #3, expected nil or number, got " .. type(arg2), 2)
			end

			return {
				Type	= arg1,
				Variant = arg2 or -1,
				SubType = arg3 or -1,
			}
		else
			error("Incorrect argument passed to BaptismalPreloader.GenerateEntityDataset at position #1, expected number or string, got " .. type(arg1), 2)
		end
	end

	function mod.GenerateTransformationDataset(entityData, backdrop, weight, voidOnly, ascentOnly, grub)
		if type(entityData) ~= "table" or not entityData.Type then
			error("Incomplete dataset passed to Retribution.GenerateTransformationDataset at position #1, argument expects a table with at minimum a Type entry", 2)
		end

		if backdrop and type(backdrop) ~= "string" and backdrop ~= -1 then
			print(backdrop)
			error("Incorrect argument passed to Retribution.GenerateTransformationDataset at position #2, nil, string, or -1 expected, got " .. type(backdrop) .. ": " .. backdrop, 2)
		end

		if not backdrop or backdrop == -1 then backdrop = "none" end
		backdrop = backdropLookup[string.lower(backdrop)]

		weight = weight or 1

		return {
			Data		= entityData,
			Backdrop	= backdrop,
			Weight 		= weight,
			Void 		= voidOnly,
			Ascent 		= ascentOnly,
			Grub 		= grub,
		}
	end

	for _, key in pairs(functionsList) do
		mod[key] = function(...)
			table.insert(mod.Queue, {Key = key, Args = {...}})
		end
	end
end