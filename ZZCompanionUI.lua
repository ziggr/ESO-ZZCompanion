ZZCompanion = ZZCompanion or {}


function ZZCompanionUI_ToggleUI()
	local was_hidden = ZZCompanionUI:IsHidden()
	if was_hidden then
		ZZCompanion:InitUI()
	end
	ZZCompanionUI:SetHidden(not was_hidden)
end

function ZZCompanion:InitUI()
						-- Data for our list is just a list of recognizers.
	for i,like in ipairs(self.like_list) do
		self.log:Debug(like:GetUIName())
	end

						-- Create a controller for our list
	local o = ZO_
end

