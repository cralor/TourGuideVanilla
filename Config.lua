

local TourGuide = TourGuide
local L = TourGuide.Locale
local ww = WidgetWarlock


function TourGuide:CreateConfigPanel()
	local self = TourGuide
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("DIALOG")

	local qtrack = ww.SummonCheckBox(22, frame, "TOPLEFT", 5, -5)
	ww.SummonFontString(qtrack, "OVERLAY", "GameFontNormalSmall", "Automatically track quests", "LEFT", qtrack, "RIGHT", 5, 0)
	qtrack:SetScript("OnClick", function() self.db.char.trackquests = not self.db.char.trackquests end)


	local function OnShow(f)
		f = f or this
		qtrack:SetChecked(self.db.char.trackquests)

		f:SetAlpha(0)
		f:SetScript("OnUpdate", ww.FadeIn)
	end

	frame:SetScript("OnShow", OnShow)
	ww.SetFadeTime(frame, 0.5)
	OnShow(frame)
	return frame
end



