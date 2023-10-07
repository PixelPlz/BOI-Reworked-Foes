IRFcompatFF = RegisterMod("Reworked Foes + Fiend Folio Champions Compatibility", 1)
local mod = IRFcompatFF


function mod:UpdateKrampusChampionId(isContinue)
    if ReworkedFoes then
		ReworkedFoes.Entities.PinChampion = 2
		ReworkedFoes.Entities.KrampusChampion = 2
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.UpdateKrampusChampionId)