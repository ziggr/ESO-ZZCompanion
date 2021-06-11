ZZCompanion         = ZZCompanion or {}
ZZCompanion.Dequeue = {}
local Dequeue = ZZCompanion.Dequeue

-- A simple double-ended queue with a size limit

function Dequeue:New()
    local o = {
        q       = {}
    ,   tail    = 1         -- existing oldest item to delete
    ,   head    = 1         -- non-existing next slot to append
    ,   max_ct  = 100
    }
    setmetatable(o,self)
    self.__index = self
    return o
end

function Dequeue:Append(item)
    self.q[self.head] = event
    self.head = self.head + 1
    self:PruneIfNeeded()
end

-- Limit dequeue growth
function Dequeue:PruneIfNeeded()
    if self.head - self.tail <= self.max_ct then return end

    for i = self.tail, self.head - self.max_ct - 1 do
        self.q[i] = nil
    end

    self:RenumberIfNeeded()
end

-- Limit indicies: left running long enough we'll overflow
-- sane integers and end up in big int land that's unnecessary.
function Dequeue:RenumberIfNeeded()
    if self.head < 1000000000 then return end

    for i = self.tail, self.head - 1 do
        self.q[i - self.tail + 1] = self.q[i]
        self.q[i] = nil
    end
end

function Dequeue:Iter()
    local tail = self.tail
    local head = self.head
    local i    = self.head

    return function ()
        i = i - 1
        if tail <= i then return self.q[i] end
    end
end

-- So that I can pass in a predicate functor that
-- says "anything older than 5 seconds since head event"
-- to discard old stuff instead of iterating over it pointlessly.
function Dequeue:RemoveIf(predicate)
    for i = self.tail, self.head - 1 do
        local item = self.q[i]
        if predicate(item) then
            self.q[i] = nil
        end
    end
end
