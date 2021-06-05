ZZCompanion = ZZCompanion or {}

ZZCompanion.name = "ZZCompanion"

-- EVENT_COMPANION_RAPPORT_UPDATE (
--      *integer* _companionId_
--    , *integer* _previousRapport_
--    , *integer* _currentRapport_)
function ZZCompanion.OnRapportUpdate(event, companion_id, prev_rapport, curr_rapport)
    local delta = curr_rapport - prev_rapport
    ZZCompanion.log:Info("Rapport %+d -> %d", delta, curr_rapport)
end


function ZZCompanion.OnAddOnLoaded(event, addon_name)
    if addon_name ~= ZZCompanion.name then return end

    ZZCompanion.log = LibDebugLogger.Create(ZZCompanion.name)
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( ZZCompanion.name
                              , EVENT_ADD_ON_LOADED
                              , ZZCompanion.OnAddOnLoaded
                              )

EVENT_MANAGER:RegisterForEvent( ZZCompanion.name
                              , EVENT_COMPANION_RAPPORT_UPDATE
                              , ZZCompanion.OnRapportUpdate
                              )
