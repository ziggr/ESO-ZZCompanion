ZZCompanion      = ZZCompanion or {}
ZZCompanion.Like = {}
local Like = ZZCompanion.Like

-- A single cooldown for a companion like/dislike.

local SECOND =  1
local MINUTE = 60 * SECOND
local HOUR   = 60 * MINUTE
local DAY    = 24 * HOUR

local COOLDOWN_UNKNOWN = nil

function Like:New(args)
    local o = {
        name            = args.name

                                    -- how much? +1, +5, +10 ...
    ,   amount          = args.amount or 0

                                    -- 5 min? 20h, nil = unknown
    ,   cooldown_secs   = args.cooldown_sec or 0

                                    -- if cooldown unknown, track min/max
    ,   cooldown_window = { min = 1000 * DAY, max = 0 }

    ,   prev_timestamp  = 0         -- when last observed
    }

    setmetatable(o,self)
    self.__index = self
    return o
end

function Like:Scan(q)
    for event in q:Iter() do
        if self:ScanOne(event) then return true end
    end
end

function Like:ScanOne(event)
    return false
end


------------------------------------------------------------------------------

ZZCompanion.LikeDelves = Like:New({ name="delves", amount = 10})

function ZZCompanion.LikeDelves:ScanOne(event)
    if event.event_id == EVENT_PLAYER_ACTIVATED then
        local zone_id = ZO_ExplorationUtils_GetPlayerCurrentZoneId()
        return ZZCompanion.LikeDelves.LIST[zone_id]
    end
end

ZZCompanion.LikeDelves.LIST = {
   [ 181] = true         -- some place
 }

------------------------------------------------------------------------------

ZZCompanion.LikeBooks = Like:New({name="books", amount = 1})

function ZZCompanion.LikeBooks:ScanOne(event)
    return (event.event_id == EVENT_SHOW_BOOK)
end

------------------------------------------------------------------------------

ZZCompanion.LikeAlcohol = Like:New({name = "alcohol", amount = 1})

function ZZCompanion.LikeAlcohol:ScanOne(event)
    if event.event_id == EVENT_CRAFTING_STATION_INTERACT then
        local craft_type = event.args[2]
        return craft_type == CRAFTING_TYPE_PROVISIONING
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeKillSnakes = Like:New({ name = "kill snake", amount = 1
                                      , cooldown_secs = 9*MINUTE + 45*SECOND
                                      })

ZZCompanion.LikeKillSnakes.NAMES = { "Sand Serpent" }

function ZZCompanion.LikeKillSnakes:ScanOne(event)
    if event.event_id == EVENT_UNIT_DEATH_STATE_CHANGED and event.is_dead then
        local mob_name = event.unit_name
        for _,n in ipairs(ZZCompanion.LikeKillSnakes.NAMES) do
            if mob_name == n then return true end
        end
    end
end

-- ### WHAT ABOUT CRITTER KILLS? Reticule track? I hope not.

