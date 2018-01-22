local f = CreateFrame("ScrollingMessageFrame", nil, UIParent)
f:SetMaxLines(250)
f:SetFontObject(ChatFontNormal)
f:SetJustifyH("LEFT")
f:SetFading(false)
f:EnableMouseWheel(true)
f:SetScript("OnMouseWheel", function()
	if (arg1 > 0) then
		if IsShiftKeyDown() then
			self:ScrollToTop()
		else
			self:ScrollUp()
		end
	elseif (arg1 < 0) then
		if IsShiftKeyDown() then
			self:ScrollToBottom()
		else
			self:ScrollDown()
		end
	end
end)
f:SetScript("OnHide", f.ScrollToBottom)
--f:Hide()


local orig = f.AddMessage
f.AddMessage = function(self, txt, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
	local newtext = string.gsub(txt,"TourGuide|r:", date("%X").."|r", 1)
	return orig(self, newtext, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
end


TourGuideOHDebugFrame = f
