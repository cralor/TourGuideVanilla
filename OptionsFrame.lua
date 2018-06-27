
local TourGuide = TourGuide
local L = TourGuide.Locale
local ww = WidgetWarlock

function TourGuide:CreateConfigPanel()
	local frame = CreateFrame("Frame", "TourGuideOptions", UIParent)
	TourGuide.optionsframe = frame
	frame:SetFrameStrata("DIALOG")
	frame:SetWidth(300) frame:SetHeight(16+28*2)
	frame:SetPoint("TOPRIGHT", TourGuide.statusframe, "BOTTOMRIGHT")
	frame:SetBackdrop(ww.TooltipBorderBG)
	frame:SetBackdropColor(0.09, 0.09, 0.19, 1)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
	frame:Hide()

	local closebutton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closebutton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

	local title = ww.SummonFontString(frame, nil, "SubZoneTextFont", nil, "BOTTOMLEFT", frame, "TOPLEFT", 5, 0)
	local fontname, fontheight, fontflags = title:GetFont()
	title:SetFont(fontname, 18, fontflags)
	title:SetText("Options")

	local qtrack = ww.SummonCheckBox(22, frame, "TOPLEFT", 5, -5)
	ww.SummonFontString(qtrack, "OVERLAY", "GameFontNormalSmall", L["Automatically track quests"], "LEFT", qtrack, "RIGHT", 5, 0)
	qtrack:SetScript("OnClick", function() self.db.char.trackquests = not self.db.char.trackquests end)

	local qskipfollowups = ww.SummonCheckBox(22, qtrack, "TOPLEFT", 0, -20)
	ww.SummonFontString(qskipfollowups, "OVERLAY", "GameFontNormalSmall", L["Automatically skip suggested follow-ups"], "LEFT", qskipfollowups, "RIGHT", 5, 0)
	qskipfollowups:SetScript("OnClick", function() self.db.char.skipfollowups = not self.db.char.skipfollowups end)
	frame.qtrack = qtrack
	frame.qskipfollowups = qskipfollowups

	local function OnShow(f)
		f = f or this
		local quad, vhalf, hhalf = self.GetQuadrant(self.statusframe)
		local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
		f:ClearAllPoints()
		f:SetPoint(quad, self.statusframe, anchpoint)
		local title_point,title_anchor,title_x,title_y
		if quad == "TOPLEFT" then
			title_point,title_anchor,title_x,title_y = "BOTTOMRIGHT", "TOPRIGHT", -5, 0
		else
			title_point,title_anchor,title_x,title_y = "BOTTOMLEFT", "TOPLEFT", 5, 0
		end
		title:ClearAllPoints()
		title:SetPoint(title_point,f,title_anchor,title_x,title_y)

		f.qtrack:SetChecked(self.db.char.trackquests)
		f.qskipfollowups:SetChecked(self.db.char.skipfollowups)
		f:SetAlpha(0)
		f:SetScript("OnUpdate", ww.FadeIn)
	end

	frame:SetScript("OnShow", OnShow)
	ww.SetFadeTime(frame, 0.5)
	OnShow(frame)
end

table.insert(UISpecialFrames, "TourGuideOptions")
