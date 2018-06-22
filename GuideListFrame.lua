
local TourGuide = TourGuide
local ww = WidgetWarlock
--WidgetWarlock = nil

local title

local NUMROWS, COLWIDTH = 16, 210
local ROWHEIGHT = 305/NUMROWS

local offset = 0
local rows = {}

local function HideTooltip()
	if GameTooltip:IsOwned(this) then
		GameTooltip:Hide()
	end
end

local function ShowTooltip()
	local f = this
	if TourGuide.db.char.completion[f.guide] ~= 1 then return end

	GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
	GameTooltip:SetText("This guide has been completed. Shift-click to reset it.", nil, nil, nil, nil, true)
end

local function OnClick()
	local f = this
	if IsShiftKeyDown() then
		TourGuide.db.char.completion[f.guide] = nil
		TourGuide.db.char.turnins[f.guide] = {}
		TourGuide:UpdateGuideListPanel()
		GameTooltip:Hide()
	else
		local text = f.guide
		if not text then f:SetChecked(false)
		else
			TourGuide:LoadGuide(text)
			TourGuide:UpdateStatusFrame()
			TourGuide:UpdateGuideListPanel()
		end
	end
end

local frame = CreateFrame("Frame", "TourGuideGuideList", TourGuide.statusframe)
TourGuide.guidelistframe = frame
frame:SetFrameStrata("DIALOG")
frame:SetWidth(660) frame:SetHeight(320+28)
frame:SetPoint("TOPRIGHT", TourGuide.statusframe, "BOTTOMRIGHT")
frame:SetBackdrop(ww.TooltipBorderBG)
frame:SetBackdropColor(0.09, 0.09, 0.19, 1)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
frame:Hide()

local closebutton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closebutton:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
frame.closebutton = closebutton

local title = ww.SummonFontString(frame, nil, "SubZoneTextFont", nil, "BOTTOM", frame, "TOP")
local fontname, fontheight, fontflags = title:GetFont()
title:SetFont(fontname, 18, fontflags)
title:SetText("Guide List")
frame.title = title

-- Fill in the frame with "guides' CheckButtons"
	for i=1,NUMROWS*3 do
		local anchor, point = rows[i-1], "BOTTOMLEFT"
		if i == 1 then anchor, point = frame, "TOPLEFT"
		elseif i == (NUMROWS + 1) then anchor, point = rows[1], "TOPRIGHT"
		elseif i == (NUMROWS*2 + 1) then anchor, point = rows[NUMROWS + 1], "TOPRIGHT" end

		local row = CreateFrame("CheckButton", nil, frame)
		if i == 1 then row:SetPoint("TOPLEFT", anchor, point, 15, -30)
		else row:SetPoint("TOPLEFT", anchor, point) end
		row:SetHeight(ROWHEIGHT)
		row:SetWidth(COLWIDTH)

		local highlight = ww.SummonTexture(row, nil, nil, nil, "Interface\\HelpFrame\\HelpFrameButton-Highlight")
		highlight:SetTexCoord(0, 1, 0, 0.578125)
		highlight:SetAllPoints()
		row:SetHighlightTexture(highlight)
		row:SetCheckedTexture(highlight)

		local text = ww.SummonFontString(row, nil, "GameFontWhite", nil, "LEFT", 6, 0)
		local fontname, fontheight, fontflags = title:GetFont()
		text:SetFont(fontname, 11, fontflags)
		text:SetTextColor(.79, .79, .79, 1)

		row:SetScript("OnClick", OnClick)
		row:SetScript("OnEnter", ShowTooltip)
		row:SetScript("OnLeave", HideTooltip)

		row.text = text
		rows[i] = row
	end

frame:SetScript("OnShow", function()
	local quad, vhalf, hhalf = TourGuide.GetQuadrant(TourGuide.statusframe)
	local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	this:ClearAllPoints()
	this:SetPoint(quad, TourGuide.statusframe, anchpoint)
	TourGuide:UpdateGuideListPanel()
	this:SetAlpha(0)
	this:SetScript("OnUpdate", ww.FadeIn)
end)

frame:EnableMouseWheel()
frame:SetScript("OnMouseWheel", function()
	local f,val = this,arg1
	offset = offset - val*NUMROWS
	if (offset + NUMROWS*2) > table.getn(TourGuide.guidelist) then offset = offset - NUMROWS end
	if offset < 0 then offset = 0 end
	TourGuide:UpdateGuideListPanel()
end)

ww.SetFadeTime(frame, 0.7)

table.insert(UISpecialFrames, "TourGuideGuideList")

function TourGuide:UpdateGuideListPanel()
	if not frame or not frame:IsVisible() then return end
	for i,row in ipairs(rows) do
		row.i = i + offset + 1

		local name = self.guidelist[i + offset + 1]
		local complete = self.db.char.currentguide == name and (self.current-1)/table.getn(self.actions) or self.db.char.completion[name]
		row.guide = name

		local r,g,b = self.ColorGradient(complete or 0)
		local text = complete and complete ~= 0 and string.format("|cff%02x%02x%02x%s", r*255, g*255, b*255, name) or name
		row.text:SetText(text)
		row:SetChecked(self.db.char.currentguide == name)
	end
end
