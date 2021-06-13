ZZCompanion = ZZCompanion or {}


function ZZCompanionUI_ToggleUI()
    local was_hidden = ZZCompanionUI:IsHidden()
    if was_hidden then
        ZZCompanion:InitUI()
    end
    ZZCompanionUI:SetHidden(not was_hidden)
end

function ZZCompanion:InitUI()
    if self.scroll_list then return end

                        -- Create a controller for our list
    local LS = LibScroll
    local scroll_data = {
        name            = "ZZCompanionScrollList"
    ,   parent          = ZZCompanionUI
    ,   setupCallback   = ZZCompanion.SetupRowData
    ,   rowTemplate     = "ZZCompanionUIRow"
    ,   rowHeight       = 23
    ,   width           = 200
    ,   height          = 400
    }

    self.scroll_list = LibScroll:CreateScrollList(scroll_data)
    local sl = self.scroll_list

    sl:SetAnchor(TOPLEFT,     ZZCompanionUI, TOPLEFT,      5, 35)
    sl:SetAnchor(BOTTOMRIGHT, ZZCompanionUI, BOTTOMRIGHT, -5, -5)

                        -- Fill the table with data
    self:UpdateScrollListData()
end

function ZZCompanion:UpdateScrollListData()
    local t = {}
    for i,like in ipairs(self.like_list) do
        local cooldown_secs, state = like:CalcCurrentCooldown()
        local row_data = { name          = like:GetUIName()
                         , cooldown_secs = cooldown_secs
                         , state         = state
                         }
        table.insert(t,row_data)
    end
    ZZCompanion.TT = t
    self.scroll_list:Update(t)
end


function ZZCompanion:ColorizeForState(label, state)
                        -- Lazy init of colors
    self.COLOR = self.COLOR or {}
    local s = ZZCompanion.Like.STATE -- for less typing
    if not self.COLOR[s.IDLE] then
        local function gi(x) return GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, x) end
        self.COLOR[s.IDLE       ] = { gi(INTERFACE_TEXT_COLOR_SUCCEEDED)} -- green
        self.COLOR[s.IN_COOLDOWN] = { gi(INTERFACE_TEXT_COLOR_DISABLED )} -- grey
        self.COLOR[s.RANGING    ] = { gi(INTERFACE_TEXT_COLOR_NORMAL   )} -- almost white
    end
    s = nil

    local color = self.COLOR[state]
    label:SetColor(unpack(color))
end

function ZZCompanion.SetupRowData(row_control, row_data, scroll_list)
    ZZCompanion.log:Debug("SetupRowData %s", row_data.name)

    local label = row_control:GetNamedChild("Name")
    label:SetText(row_data.name)
    ZZCompanion:ColorizeForState(label, row_data.state)

    label = row_control:GetNamedChild("Cooldown")
    local text = FormatTimeSeconds(row_data.cooldown_secs
                                  , TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT)
    label:SetText(text)
    ZZCompanion:ColorizeForState(label, row_data.state)
end
