ZZCompanion = ZZCompanion or {}

ZZCompanion.name = "ZZCompanion"
local Like = ZZCompanion.Like

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
    local self      = ZZCompanion
    self.log        = LibDebugLogger.Create(ZZCompanion.name)
    self.history    = ZZCompanion.Dequeue:New()
    -- self.like_list  = { Like.Delves
    --                   , Like.Books
    --                   , Like.Alcohol
    --                   }
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


function ZZCompanion.RecordEvent(...)
    local self = ZZCompanion
    local event_id = arg[0]

    local event     = {}
    event.event_id  = arg[0]
    event.timestamp = GetTimeStamp()
    event.args      = arg
    self.history:Append(event)

    if event.event_id == EVENT_COMPANION_RAPPORT_UPDATE then
        event.prev_rapport = arg[3]
        event.curr_rapport = arg[4]
        event.diff_rapport = curr_rapport - diff_rapport
        self:ScanForRapportCause()
    end
end

-- Reverse-scan event history looking for the most recent RAPPORT event,
-- and surrounding events that clue us in to why the RAPPORT changed.
function ZZCompanion:ScanForRapportCause()
                        -- Scan 1: for RAPPORT event.
    local rapport_event = nil
    for i = self.q.head - 1, self.q.tail, -1 do
        rapport_event = self.q[i]
        if rapport_event.diff_rapport then break end
    end
    if not (        rapport_event
            and     rapport_event.diff_rapport
            and not rapport_event.accounted_for) then return end

                        -- Scan 2..n: find a match
    for _,like in pairs(self.like_list) do
        if like.Scan(self.q) then
            self.log:Info("Found one: %s", like.name)
            break
        end
    end
end

--[[

snake
book
     EVENT_SHOW_BOOK (
          number eventCode
        , string bookTitle  "Rajhin and the Stone Maiden, Pt. 1"
        , string body       "Many years ago..."
        , BookMedium medium 1
        , boolean showTitle true
        , number bookId     2018
        )                   MIRRI +1

alcohol
    EVENT_CRAFTING_STATION_INTERACT (
        *[TradeskillType|#TradeskillType]* _craftSkill_
      , *bool* _sameStation_
      )

      RAPPORT_UPDATE hits BEFORE inventory, crafte completed,

  EVENT_INVENTORY_SINGLE_SLOT_UPDATE (
        *[Bag|#Bag]* _bagId_                                                  1
      , *integer* _slotId_                                                    1
      , *bool* _isNewItem_                                                    true
      , *[ItemUISoundCategory|#ItemUISoundCategory]* _itemSoundCategory_      19
      , *integer* _inventoryUpdateReason_                                     0
      , *integer* _stackCountChange_                                          4
      , *string:nilable* _triggeredByCharacterName_                           nil
      , *string:nilable* _triggeredByDisplayName_                             nil
      , *bool* _isLastUpdateForMessage_                                       nil
      )
  EVENT_CRAFT_COMPLETED (
        *[TradeskillType|#TradeskillType]* _craftSkill_)                      5


enter zone
* EVENT_PLAYER_ACTIVATED (*bool* true)
  ZO_ExplorationUtils_GetPlayerCurrentZoneId()                                981   The Brass Fortress
                                                                                    https://wiki.esoui.com/Zones
excavate antiquity
  EVENT_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED (no args)
  then EVENT_COMPANION_RAPPORT_UPDATE

turn in numani-rasi some times

turn in fighter's guild

loot psijic portal
  reticule + looted?

  EVENT_CLIENT_INTERACT_RESULT (
      *[ClientInteractResult|#ClientInteractResult]* _result_   0
    , *string* _interactTargetName_                             "Psijic Portal"
    )

  EVENT_TUTORIAL_TRIGGER_COMPLETED (
    *[TutorialTrigger|#TutorialTrigger]* _tutorialTrigger_  81) TUTORIAL_TRIGGER_GAINED_BIND_ON_EQUIP_ITEM  NAH



Hrm:

EVENT_ACTIVE_COMPANION_STATE_CHANGED (
*[CompanionState|#CompanionState]* _newState_
, *[CompanionState|#CompanionState]* _oldState_
)

-- EVENT_COMPANION_RAPPORT_UPDATE (
--      *integer* _companionId_
--    , *integer* _previousRapport_
--    , *integer* _currentRapport_)





Event listeners just append to an event log dequeue

RAPPORT events trigger a scan for "why"
  --> if no clue in current dequeue, zo_callLater in 1 sec for a single retry to find clue

Scan is dequeue head back for up to a couple seconds

Integer indicies with head/tail index
delete [old tail, new tail) on prune


LIKES are the objects that comprehend likes
  +1 +5 +10 amount
  Known timeout
  Unknown timeout range min/max
  events that cause it : event ID, params
  overridable function to scan queue for "is mine"

Display UI table
  list of likes
  column of "how long until cooldown expires" in minutes or hours, sortable as integer time


]]