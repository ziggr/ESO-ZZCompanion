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
   [134] = true -- Shadowfen  / Sanguine's Demesne
,  [400] = true -- Auridon    / Mehrunes' Spite
,  [291] = true -- Stonefalls / Sheogorath's Tongue
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
    [5176] -- Daemon Chicken
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

------------------------------------------------------------------------------

ZZCompanion.LikeKillGoblins = Like:New({ name = "kill goblin", amount = 1
                                      , cooldown_secs = 4*MINUTE
                                      })

ZZCompanion.LikeKillGoblins.NAMES = { "Stonechewer Witch"
                                    , "Stonechewer Skirmisher"
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

local function ZZCompanion.LikeSingleLocation.New(args)
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

ZZCompanion.NElsweyrMural = ZZCompanion.LikeSingleLocation.New(
        { name          = "n elsweyr mural"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1086
        })

ZZCompanion.SElsweyrMural = ZZCompanion.LikeSingleLocation.New(
        { name          = "s elsweyr mural"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1133
        })

ZZCompanion.Moawita = ZZCompanion.LikeSingleLocation.New(
        { name          = "moawita"
        , amount        = 5
        , cooldown_secs = 20*HOUR
        , location      = 1027
        })

