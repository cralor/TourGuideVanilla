
local TourGuide = TourGuide
local ww = WidgetWarlock

local closebutton, title, trackquestcheck

local frame = CreateFrame("Frame", "TourGuideOptions", UIParent)
TourGuide.optionsframe = frame
frame:SetFrameStrata("DIALOG")
frame:SetWidth(300) frame:SetHeight(16+28)
frame:SetPoint("TOPRIGHT", TourGuide.statusframe, "BOTTOMRIGHT")
frame:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 16,
	insets = {left = 5, right = 5, top = 5, bottom = 5},
	tile = true, tileSize = 16,
})
frame:SetBackdropColor(0.09, 0.09, 0.19, 1)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
frame:Hide()

frame:SetScript("OnShow", function()
	local quad, vhalf, hhalf = TourGuide.GetQuadrant(TourGuide.statusframe)
	local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	this:ClearAllPoints()
	this:SetPoint(quad, TourGuide.statusframe, anchpoint)
	local title_point,title_anchor,title_x,title_y
	if quad == "TOPLEFT" then
		title_point,title_anchor,title_x,title_y = "BOTTOMRIGHT", "TOPRIGHT", -5, 0
	else
		title_point,title_anchor,title_x,title_y = "BOTTOMLEFT", "TOPLEFT", 5, 0
	end
	title:ClearAllPoints()
	title:SetPoint(title_point,this,title_anchor,title_x,title_y)
	this:SetAlpha(0)
	this:SetScript("OnUpdate", ww.FadeIn)
end)

closebutton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closebutton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")

title = ww.SummonFontString(frame, nil, "SubZoneTextFont", nil, "BOTTOMLEFT", frame, "TOPLEFT", 5, 0)
local fontname, fontheight, fontflags = title:GetFont()
title:SetFont(fontname, 18, fontflags)
title:SetText("Options")

trackquestcheck = CreateFrame("CheckButton", "TourGuideOptionsTrackQuestCheck", frame, "UICheckButtonTemplate")
trackquestcheck:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
trackquestcheck:SetWidth(24) trackquestcheck:SetHeight(24)
trackquestcheck.text = getglobal("TourGuideOptionsTrackQuestCheckText")
trackquestcheck.text:SetText("Automatically Track Quests")

ww.SetFadeTime(frame, 0.7)

trackquestcheck:SetScript("OnClick", function()
	TourGuide.db.char.trackquests = not TourGuide.db.char.trackquests
end)

trackquestcheck:SetScript("OnShow", function()
	f = f or this
	f:SetChecked(TourGuide.db.char.trackquests)
	f:SetAlpha(0)
	f:SetScript("OnUpdate", ww.FadeIn)
end)

table.insert(UISpecialFrames, "TourGuideOptions")
