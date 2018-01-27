
local TourGuide = TourGuide
local ww = WidgetWarlock
WidgetWarlock = nil


local NUMROWS, COLWIDTH = 16, 210
local ROWHEIGHT = 305/NUMROWS


local offset = 0
local rows = {}
local frame


local function OnShow()
	local self = this
	TourGuide:UpdateGuidesPanel()

	self:SetAlpha(0)
	self:SetScript("OnUpdate", ww.FadeIn)
end


local function HideTooltip() GameTooltip:Hide() end


local function ShowTooltip()
	local f = this
	if TourGuide.db.char.completion[f.guide] ~= 1 then return end

	GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
	GameTooltip:SetText("This guide has been completed.  Shift-click to reset it.", nil, nil, nil, nil, true)
end


local function OnClick()
	local self = this
	if IsShiftKeyDown() then
		TourGuide.db.char.completion[self.guide] = nil
		TourGuide.db.char.turnins[self.guide] = {}
		TourGuide:UpdateGuidesPanel()
		GameTooltip:Hide()
	else
		local text = self.guide
		if not text then self:SetChecked(false)
		else
			TourGuide:LoadGuide(text)
			TourGuide:UpdateStatusFrame()
			TourGuide:UpdateGuidesPanel()
		end
	end
end


function TourGuide:CreateGuidesPanel()
	frame = CreateFrame("Frame", nil, UIParent)
	rows = {}
	for i=1,NUMROWS*3 do
		local anchor, point = rows[i-1], "BOTTOMLEFT"
		if i == 1 then anchor, point = frame, "TOPLEFT"
		elseif i == (NUMROWS + 1) then anchor, point = rows[1], "TOPRIGHT"
		elseif i == (NUMROWS*2 + 1) then anchor, point = rows[NUMROWS + 1], "TOPRIGHT" end

		local row = CreateFrame("CheckButton", nil, frame)
		row:SetPoint("TOPLEFT", anchor, point)
		row:SetHeight(ROWHEIGHT)
		row:SetWidth(COLWIDTH)

		local highlight = ww.SummonTexture(row, nil, nil, nil, "Interface\\HelpFrame\\HelpFrameButton-Highlight")
		highlight:SetTexCoord(0, 1, 0, 0.578125)
		highlight:SetAllPoints()
		row:SetHighlightTexture(highlight)
		row:SetCheckedTexture(highlight)

		local text = ww.SummonFontString(row, nil, "GameFontWhite", nil, "LEFT", 6, 0)

		row:SetScript("OnClick", OnClick)
		row:SetScript("OnEnter", ShowTooltip)
		row:SetScript("OnLeave", HideTooltip)

		row.text = text
		rows[i] = row
	end

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function()
		local f,val = this,arg1
		offset = offset - val*NUMROWS
		if (offset + NUMROWS*2) > table.getn(self.guidelist) then offset = offset - NUMROWS end
		if offset < 0 then offset = 0 end
		self:UpdateGuidesPanel()
	end)

	frame:SetScript("OnShow", OnShow)
	ww.SetFadeTime(frame, 0.5)
	OnShow(frame)
	return frame
end


function TourGuide:UpdateGuidesPanel()
	if not frame or not frame:IsVisible() then return end
	for i,row in ipairs(rows) do
		row.i = i + offset + 1

		local name = self.guidelist[i + offset + 1]
		local complete = self.db.char.currentguide == name and (self.current-1)/table.getn(self.actions) or self.db.char.completion[name]
		row.guide = name

		local r,g,b = self.ColorGradient(complete or 0)
		local text = complete and complete ~= 0 and string.format("%s |cff%02x%02x%02x[%d%%]", name, r*255, g*255, b*255, complete*100) or name
		row.text:SetText(text)
		row:SetChecked(self.db.char.currentguide == name)
	end
end
