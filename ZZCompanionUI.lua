ZZCompanion = ZZCompanion or {}


function ZZCompanionUI_ToggleUI()
    local was_hidden = ZZCompanionUI:IsHidden()
    if was_hidden then
        ZZCompanion:InitUI()
    end
    ZZCompanionUI:SetHidden(not was_hidden)
end

function ZZCompanion:InitUI()

                        -- Create a controller for our list
    local LS = LibScroll
    local scroll_data = {
        name = "ZZCompanionScrollList"
    ,   parent = ZZCompanionUI
    ,   setupCallback = ZZCompanion.SetupRowData
    }

    self.scroll_list = LibScroll:CreateScrollList(scroll_data)
    local sl = self.scroll_list
    sl:SetAnchor(TOPLEFT,     ZZCompanionUI, TOPLEFT,     0, 20)
    sl:SetAnchor(BOTTOMRIGHT, ZZCompanionUI, BOTTOMRIGHT, 0,  0)

                        -- Fill the table with data
    self:UpdateScrollListData()
end

function ZZCompanion:UpdateScrollListData()
    local t = {}
    for i,like in ipairs(self.like_list) do
        local row_data = { name = like:GetUIName() }
        table.insert(t,row_data)
    end
    ZZCompanion.TT = t
    self.scroll_list:Update(t)
end

function ZZCompanion.SetupRowData(row_control, row_data, scroll_list)
    ZZCompanion.log:Debug("SetupRowData %s", row_data.name)
    row_control:SetText(row_data.name)

    ZZCompanion.ZZ = row_control
end
