ZZCompanion = ZZCompanion or {}

ZZCompanion.name = "ZZCompanion"
local Like = ZZCompanion.Like

function ZZCompanion.OnAddOnLoaded(event, addon_name)
    if addon_name ~= ZZCompanion.name then return end
    local self      = ZZCompanion
    self.log        = LibDebugLogger.Create(ZZCompanion.name)
    self.history    = ZZCompanion.Dequeue:New()
    self.like_list  = { ZZCompanion.LikeDelves
                      , ZZCompanion.LikeBooks
                      , ZZCompanion.LikeAlcohol
                      , ZZCompanion.LikeKillSnakes
                      }
    self.RegisterListeners()
end

EVENT_MANAGER:RegisterForEvent( ZZCompanion.name
                              , EVENT_ADD_ON_LOADED
                              , ZZCompanion.OnAddOnLoaded
                              )

local EVENT_NAMES = {
    [EVENT_COMPANION_RAPPORT_UPDATE              ] = "RAPPORT"
,   [EVENT_SHOW_BOOK                             ] = "SHOW_BOOK"
,   [EVENT_CRAFTING_STATION_INTERACT             ] = "CRAFTING_STATION"
,   [EVENT_INVENTORY_SINGLE_SLOT_UPDATE          ] = "INVENTORY"
,   [EVENT_CRAFT_COMPLETED                       ] = "CRAFT_COMPLETD"
,   [EVENT_PLAYER_ACTIVATED                      ] = "PLAYER_ACTIVATED"
,   [EVENT_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED ] = "ANTIQUITY"
,   [EVENT_CLIENT_INTERACT_RESULT                ] = "INTERACT"
,   [EVENT_UNIT_DEATH_STATE_CHANGED              ] = "DEATH_STATE"
}
function ZZCompanion.RegisterListeners()
    for event_id,name in pairs(EVENT_NAMES) do
        EVENT_MANAGER:RegisterForEvent( ZZCompanion.name
                                      , event_id
                                      , ZZCompanion.RecordEvent
                                      )
    end
end


function ZZCompanion.RecordEvent(event_id, ...)
    local self = ZZCompanion

    local event     = {}
    event.event_id  = event_id
    event.timestamp = GetTimeStamp()
    event.args      = arg

                        -- Identify interesting parts of RAPPORT event.
    if event.event_id == EVENT_COMPANION_RAPPORT_UPDATE then
        local function _extract_rapport(event, event_id, companion_id, prev_rapport, curr_rapport)
            event.prev_rapport = prev_rapport
            event.curr_rapport = curr_rapport
            event.diff_rapport = curr_rapport - prev_rapport
            ZZCompanion.log:Info("Rapport %+d -> %d", event.diff_rapport, event.curr_rapport)
        end
        _extract_rapport(event, event_id, ...)
    end
                        -- Capture inventory slot occupant NOW before things
                        -- slide around upon another later event.
    if event.event_id == EVENT_INVENTORY_SINGLE_SLOT_UPDATE then
        local function _extract_inventory( event, event_id, bag_id, slot_id, is_new
                                         , sound_category, update_reason, stack_count_change )
                        -- Ignore the MANY updates to weapon charge and armor durability.
            if update_reason ~= INVENTORY_UPDATE_REASON_DEFAULT then return false end

            event.item_link = GetItemLink(bag_id, slot_id)
            ZZCompanion.log:Debug( "inventory item_link: %s  reason:%d  ct_change:%+d"
                                 , event.item_link
                                 , update_reason
                                 , stack_count_change
                                 )


        end
        if not _extract_inventory(event, event_id, ...) then return end
    end

    if event.event_id == EVENT_UNIT_DEATH_STATE_CHANGED then
        local function _extract_death_state(event, event_id, unit_tag, is_dead)
            event.unit_name = GetUnitName(unit_tag)     -- "Sand Serpent"
            event.is_dead   = is_dead                   -- true
        end
        _extract_death_state(event, event_id, ...)
        ZZCompanion.log:Debug("death tag: %s   is_dead:%s", event.unit_name, tostring(event.is_dead))
    end

    self.history:Append(event)
    ZZCompanion.log:Debug("event recorded %s", EVENT_NAMES[event.event_id] or tostring(event.event_id))

                        -- And finally, if this was a rapport change, now
                        -- that the rapport event is sitting in our history,
                        -- see if we can match it up to a previous event
                        -- and deduce its cause. If not, ScanForRapportCause()
                        -- will zo_callLater() itself in a second to see if
                        -- the matching event comes in AFTER this rapport update.
    if event.event_id == EVENT_COMPANION_RAPPORT_UPDATE then
        self:ScanForRapportCause()
    end
end

-- Reverse-scan event history looking for the most recent RAPPORT event,
-- and surrounding events that clue us in to why the RAPPORT changed.
function ZZCompanion:ScanForRapportCause(is_retry)
                        -- Scan 1: for RAPPORT event.
    local rapport_event = nil
    for r in self.history:Iter() do
        if r.diff_rapport then
            rapport_event = r
            break
        end
    end
    if not (        rapport_event
            and     rapport_event.diff_rapport
            and not rapport_event.accounted_for) then
        self.log:Debug("no rapport event")
        return
    end

                        -- Scan 2..n: find a match
    local matching_like = nil
    for _,like in pairs(self.like_list) do
        if like:Scan(self.history) then
            matching_like = like
            break
        end
    end

    if matching_like then
        self.log:Info("Found one: %s", matching_like.name)
    elseif not is_retry then
        self.log:Info("No match, trying again later")
        zo_callLater(function () ZZCompanion:ScanForRapportCause(true) end, 500)
    else
        self.log:Info("No known like for rapport change.")
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

kill snake/goblin
* EVENT_UNIT_DEATH_STATE_CHANGED (
      *string* _unitTag_
    , *bool* _isDead_)

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