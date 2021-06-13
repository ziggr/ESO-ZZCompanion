ZZCompanion      = ZZCompanion or {}
ZZCompanion.Like = {}
local Like = ZZCompanion.Like

-- A single cooldown for a companion like/dislike.

local SECOND =  1
local MINUTE = 60 * SECOND
local HOUR   = 60 * MINUTE
local DAY    = 24 * HOUR

Like.STATE = {
                        -- > cooldown_secs. Not in cooldown, can acquire.
    ["IDLE"       ]  = "idle"

                        -- < cooldown_secs. Recently acquired, waiting.
 ,  ["IN_COOLDOWN"]  = "in_cooldown"

                        -- cooldown_window.min < X < cooldown_window.max.
                        -- Might be in cooldown, might not, that's what
                        -- we're trying to figure out.
,   ["RANGING"    ]  = "ranging"
}

function Like:New(args)
    local o = {
        name            = args.name

                                    -- how much? +1, +5, +10 ...
    ,   amount          = args.amount or 0

                                    -- 5 min? 20h, nil = unknown
    ,   cooldown_secs   = args.cooldown_secs or 0

                                    -- if cooldown unknown, track min/max
    ,   cooldown_window = { min = 5*MINUTE, max = 2*DAY }

    ,   prev_timestamp  = 0         -- seconds since the epoch when last observed
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

function Like:GetUIName()
    return self.name
end

-- Return current cooldown value (counting down seconds) if cooling down/ranging,
-- or the static known or minimum cooldown if idle.
--
-- Also return cooldown state, since the work to figure that out is also the work
-- to calculate the seconds.
--
function Like:CalcCurrentCooldown()

                        -- Like has never triggered? Idle.
    if self.prev_timestamp == 0 then
        if self.cooldown_secs ~= 0 then
            return self.cooldown_secs,       Like.STATE.IDLE
        else
            return self.cooldown_window.min, Like.STATE.IDLE
        end
    end

    local current_timestamp = GetTimeStamp()
    local elapsed_secs = current_timestamp - self.prev_timestamp

    if self.cooldown_secs ~= 0 then
        if elapsed_secs < self.cooldown_secs then
            return self.cooldown_secs - elapsed_secs, Like.STATE.IN_COOLDOWN
        else
            return self.cooldown_secs,                Like.STATE.IDLE
        end
    else
        if elapsed_secs < self.cooldown_window.min then
            return self.cooldown_window.min - elapsed_secs, Like.STATE.IN_COOLDOWN
        elseif (self.cooldown_window.max == 0) then
            return elapsed_secs, Like.STATE.RANGING
        else
            return self.cooldown_window.max - elapsed_secs, Like.STATE.RANGING
        end
    end
end

function Like:RecordMatch(rapport_event)
    ZZCompanion.log:Debug("Like:RecordMatch")
                        -- First time we've seen this?
                        -- Record start of our first cooldown.
    if self.prev_timestamp == 0
        or rapport_event.timestamp <= self.prev_timestamp then
        self.prev_timestamp = rapport_event.timestamp
    else
                        -- Second-or-later time? Close our current cooldown.
                        -- Shrink max window to help figure out the still-unknowns.
        local duration_secs = rapport_event.timestamp - self.prev_timestamp
        self.cooldown_window.max = math.min(duration_secs, self.cooldown_window.max)
    end

                        -- Remember.
    self.prev_timestamp = rapport_event.timestamp
    ZZCompanion:SaveLike(self)
end

function Like:Save(sv)
    ZZCompanion.log:Debug( "Like:Save %s %s"
                         , self.name
                         , tostring(self.prev_timestamp)
                         )
    sv.prev_timestamp = self.prev_timestamp
    if self.cooldown_secs ~= 0 then
        sv.cooldown_window = nil
    else
        sv.cooldown_window = self.cooldown_window
    end
end

function Like:Load(sv)
    self.prev_timestamp = sv.prev_timestamp or 0
    if self.cooldown_secs ~= 0 then return end
    if sv.cooldown_window then
        self.cooldown_window = sv.cooldown_window
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeDelves = Like:New({ name="delves", amount = 10
                                  , cooldown_secs = 30*MINUTE
                                  })

function ZZCompanion.LikeDelves:ScanOne(event)
    if event.event_id == EVENT_PLAYER_ACTIVATED then
        local zone_id = ZO_ExplorationUtils_GetPlayerCurrentZoneId()
        return ZZCompanion.LikeDelves.LIST[zone_id]
    end
end

ZZCompanion.LikeDelves.LIST = {
   [134] = true -- Shadowfen   / Sanguine's Demesne
,  [400] = true -- Auridon     / Mehrunes' Spite
,  [291] = true -- Stonefalls  / Sheogorath's Tongue
,  [961] = true -- Vvardenfell / Ashalmawia
}

------------------------------------------------------------------------------

ZZCompanion.LikeBooks = Like:New({name="books", amount = 1})

function ZZCompanion.LikeBooks:ScanOne(event)
    return (event.event_id == EVENT_SHOW_BOOK)
end

------------------------------------------------------------------------------

ZZCompanion.LikeAntiquity = Like:New({name="antiquity", amount = 5})

function ZZCompanion.LikeAntiquity:ScanOne(event)
    return (event.event_id == EVENT_ANTIQUITY_DIGGING_ANTIQUITY_UNEARTHED)
end

------------------------------------------------------------------------------

ZZCompanion.LikePsijicPortals = Like:New({name="psijic portals", amount = 5})

function ZZCompanion.LikePsijicPortals:ScanOne(event)
    if      event.event_id == EVENT_CLIENT_INTERACT_RESULT
        and event.target_name == "Psijic Portal" then
        return true
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeDaemonPets = Like:New({name="daemon pets", amount = 1})

local DAEDRIC_PETS = {
    [5176] = true -- Daemon Chicken
}

function ZZCompanion.LikeDaemonPets:ScanOne(event)
    if      event.event_id == EVENT_COLLECTIBLE_UPDATED
        and DAEDRIC_PETS[event.collectible_id] then
        return true
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeAlcohol = Like:New({ name = "alcohol", amount = 1
                                   , cooldown_secs = 5*MINUTE
                                   })

function ZZCompanion.LikeAlcohol:ScanOne(event)
    if event.event_id == EVENT_CRAFT_COMPLETED then
        return event.craft_type == CRAFTING_TYPE_PROVISIONING
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeKillSnakes = Like:New({ name = "kill snake", amount = 1
                                      , cooldown_secs = 9*MINUTE + 45*SECOND
                                      })

ZZCompanion.LikeKillSnakes.NAMES = { "Snake"    -- critter
                                   , "Sand Serpent"
                                   }

function ZZCompanion.LikeKillSnakes:ScanOne(event)
    if event.event_id == EVENT_UNIT_DEATH_STATE_CHANGED and event.is_dead then
        local mob_name = event.unit_name
        for _,n in ipairs(ZZCompanion.LikeKillSnakes.NAMES) do
            if mob_name == n then return true end
        end

                        -- Might be helpful to list recent kills
                        -- so that snake and goblin kill scanners
                        -- can grow their lists of names.
                        --
                        -- Only do this logging call once, either
                        -- LikeKillSnakes or in LikeKillGoblins.
        ZZCompanion.log:Debug("Recent kill: %s", mob_name)
    end
end

------------------------------------------------------------------------------

ZZCompanion.LikeKillGoblins = Like:New({ name = "kill goblin", amount = 1
                                      , cooldown_secs = 4*MINUTE
                                      })

ZZCompanion.LikeKillGoblins.NAMES = {
                                      "Stonechewer Ravager"
                                    , "Stonechewer Skirmisher"
                                    , "Stonechewer Witch"
                                    }

function ZZCompanion.LikeKillGoblins:ScanOne(event)
    if event.event_id == EVENT_UNIT_DEATH_STATE_CHANGED and event.is_dead then
        local mob_name = event.unit_name
        for _,n in ipairs(ZZCompanion.LikeKillGoblins.NAMES) do
            if mob_name == n then return true end
        end
    end
end

-- ### WHAT ABOUT CRITTER KILLS? Reticule track? I hope not.

------------------------------------------------------------------------------

ZZCompanion.LikeSingleLocation = {}

function ZZCompanion.LikeSingleLocation.New(args)
    local o = Like:New(args)
    o.location = args.location
    o.ScanOne = ZZCompanion.LikeSingleLocation.ScanOne
    return o
end

function ZZCompanion.LikeSingleLocation:ScanOne(event)
    if event.event_id == EVENT_PLAYER_ACTIVATED then
        local zone_id = ZO_ExplorationUtils_GetPlayerCurrentZoneId()
        return zone_id == self.location
    end
end

ZZCompanion.LikeBrassFortress = ZZCompanion.LikeSingleLocation.New(
        { name          = "brass fortress"
        , amount        = 10
        , cooldown_secs = 20*HOUR
        , location      = 981
        })

ZZCompanion.LikeLibraryOfVivec = ZZCompanion.LikeSingleLocation.New(
        { name          = "library of vivec"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 849
        })

ZZCompanion.LikeOrsimerGlories = ZZCompanion.LikeSingleLocation.New(
        { name          = "orsimer glories"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 684
        })

ZZCompanion.LikeNElsweyrMural = ZZCompanion.LikeSingleLocation.New(
        { name          = "n elsweyr mural"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1086
        })

ZZCompanion.LikeSElsweyrMural = ZZCompanion.LikeSingleLocation.New(
        { name          = "s elsweyr mural"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1133
        })

ZZCompanion.LikeMoawita = ZZCompanion.LikeSingleLocation.New(
        { name          = "moawita"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1027
        })

ZZCompanion.LikeHitList = ZZCompanion.LikeSingleLocation.New(
        { name          = "hit list"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 821
        })

