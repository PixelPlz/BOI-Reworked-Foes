IRFcompatFF = RegisterMod("Reworked Foes + Fiend Folio Champions Compatibility", 1)
local mod = IRFcompatFF


function mod:updateKrampusChampionId(isContinue)
    if IRFkrampusChampID then
		IRFkrampusChampID = 2
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.updateKrampusChampionId)