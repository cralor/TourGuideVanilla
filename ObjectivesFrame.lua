
local TourGuide = TourGuide
local L = TourGuide.Locale
local ww = WidgetWarlock


local ROWHEIGHT = 30
local ROWOFFSET = 6
local NUMROWS = math.floor(305/ROWHEIGHT)


local offset = 0
local rows = {}
local scrollbar, upbutt, downbutt, title, completed


local frame = CreateFrame("Frame", "TourGuideObjectives", UIParent)
TourGuide.objectiveframe = frame
frame:SetFrameStrata("DIALOG")
frame:SetWidth(630) frame:SetHeight(305+28)
frame:SetPoint("TOPRIGHT", TourGuide.statusframe, "BOTTOMRIGHT")
frame:SetBackdrop(ww.TooltipBorderBG)
frame:SetBackdropColor(0.09, 0.09, 0.19, 1)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
frame:Hide()
frame:SetScript("OnShow", function() TourGuide:UpdateObjectivePanel() end)
table.insert(UISpecialFrames, "TourGuideObjectives")


local function ResetScrollbar()
	local f = this
	local newval = math.max(0, (TourGuide.current or 0) - NUMROWS/2 - 1)

	scrollbar:SetMinMaxValues(0, math.max(table.getn(TourGuide.actions) - NUMROWS, 1))
	scrollbar:SetValue(newval)

	TourGuide:UpdateOHPanel()
end

local function OnShow(f)
	local f = f or this
	ResetScrollbar()
	f:SetAlpha(0)
	f:SetScript("OnUpdate", ww.FadeIn)

	if TourGuide.optionsframe:IsVisible() then HideUIPanel(TourGuide.optionsframe) end
	if TourGuide.guidelistframe:IsVisible() then HideUIPanel(TourGuide.guidelistframe) end
end


local function HideTooltip()
	if GameTooltip:IsOwned(this) then
		GameTooltip:Hide()
	end
end

local function ShowTooltip()
	local f = this
	if f.text:GetStringWidth() <= f:GetWidth() then return end

	GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
	GameTooltip:SetText(f.text:GetText(), nil, nil, nil, nil, true)
end

local function CreateButton(parent, a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
	local b = CreateFrame("Button", nil, parent)
	if TourGuide.select("#", a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20) > 0 then b:SetPoint(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20) end
	b:SetWidth(80) b:SetHeight(22)

	-- Fonts --
	b:SetDisabledFontObject(GameFontDisable)
	b:SetHighlightFontObject(GameFontHighlight)
	b:SetTextFontObject(GameFontNormal)

	-- Textures --
	b:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
	b:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
	b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	b:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
	b:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	b:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	b:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	b:GetDisabledTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	b:GetHighlightTexture():SetBlendMode("ADD")

	return b
end


function TourGuide:UpdateObjectivePanel()
	frame:SetScript("OnShow", nil)
	local guidebutton = CreateButton(frame, "BOTTOMRIGHT", -6, 6)
	guidebutton:SetText("Guides")
	guidebutton:SetScript("OnClick", function() frame:Hide(); TourGuide.guidelistframe:Show() end)

	local configbutton = CreateButton(frame, "RIGHT", guidebutton, "LEFT")
	configbutton:SetText(L["Config"])
	configbutton:SetScript("OnClick", function() frame:Hide(); TourGuide.optionsframe:Show() end)

	if TourGuide.db.char.debug then
		local b = CreateButton(frame, "RIGHT", configbutton, "LEFT")
		b:SetText("Debug All")
		b:SetScript("OnClick", function() frame:Hide(); self:DebugGuideSequence(true) end)
	end

	title = ww.SummonFontString(frame, nil, "SubZoneTextFont", nil, "BOTTOM", frame, "TOP")
	local fontname, fontheight, fontflags = title:GetFont()
	title:SetFont(fontname, 18, fontflags)

	completed = ww.SummonFontString(frame, nil, "NumberFontNormalLarge", nil, "BOTTOMLEFT", 10, 10)

	scrollbar, upbutt, downbutt = ww.ConjureScrollBar(frame)
	scrollbar:SetPoint("TOPRIGHT", frame, -7, -21)
	scrollbar:SetPoint("BOTTOM", frame, 0, 22+22)
	scrollbar:SetScript("OnValueChanged", function() local f,val = this,arg1 self:UpdateOHPanel(val) end)

	upbutt:SetScript("OnClick", function()
		local f = this
		scrollbar:SetValue(offset - NUMROWS + 1)
		PlaySound("UChatScrollButton")
	end)

	downbutt:SetScript("OnClick", function()
		local f = this
		scrollbar:SetValue(offset + NUMROWS - 1)
		PlaySound("UChatScrollButton")
	end)

	local bg = {bgFile = "Interface/Tooltips/UI-Tooltip-Background"}
	for i=1,NUMROWS do
		local row = CreateFrame("Button", nil, frame)
		row:SetPoint("TOPLEFT", i == 1 and frame or rows[i-1], i == 1 and "TOPLEFT" or "BOTTOMLEFT", 0, i == 1 and -3 or 0)
		row:SetWidth(630-24)
		row:SetHeight(ROWHEIGHT)
		row:SetBackdrop(bg)

		local check = ww.SummonCheckBox(ROWHEIGHT-ROWOFFSET, row, "LEFT", ROWOFFSET, 0)
		local icon = ww.SummonTexture(row, nil, ROWHEIGHT-ROWOFFSET, ROWHEIGHT-ROWOFFSET, nil, "LEFT", check, "RIGHT", ROWOFFSET, 0)
		local text = ww.SummonFontString(row, nil, "GameFontNormal", nil, "LEFT", icon, "RIGHT", ROWOFFSET, 0)

		local detailhover = CreateFrame("Button", nil, row)
		detailhover:SetHeight(ROWHEIGHT-ROWOFFSET)
		detailhover:SetPoint("LEFT", text, "RIGHT", ROWOFFSET*3, 0)
		detailhover:SetPoint("RIGHT", scrollbar, "LEFT", -ROWOFFSET, 0)
		detailhover:SetScript("OnEnter", ShowTooltip)
		detailhover:SetScript("OnLeave", HideTooltip)

		local detail = ww.SummonFontString(detailhover, nil, "GameFontNormal", nil)
		detail:SetAllPoints(detailhover)
		detail:SetJustifyH("RIGHT")
		detail:SetTextColor(240/255, 121/255, 2/255)
		detailhover.text = detail

		check:SetScript("OnClick", function()
			local f = this
			self:SetTurnedIn(row.i, f:GetChecked())
		end)

		row.text = text
		row.detail = detail
		row.check = check
		row.icon = icon
		rows[i] = row
	end

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function()
		local f, val = this, arg1
		scrollbar:SetValue(offset - val)
	end)

	frame:SetScript("OnShow", OnShow)
	ww.SetFadeTime(frame, 0.5)
	OnShow(frame)
	return frame
end


local accepted = {}
function TourGuide:UpdateOHPanel(value)
	if not frame or not frame:IsVisible() then return end
	title:SetText(self.db.char.currentguide or L["No Guide Loaded"])
	local r,g,b = self.ColorGradient((self.current-1)/table.getn(self.actions))
	completed:SetText(string.format(L["|cff%02x%02x%02x%d%% complete"], r*255, g*255, b*255, (self.current-1)/table.getn(self.actions)*100))

	if self.guidechanged then
		self.guidechanged = nil
		ResetScrollbar()
	end

	if value then offset = math.floor(value) end
	if (offset + NUMROWS) > table.getn(self.actions) then offset = table.getn(self.actions) - NUMROWS end
	if offset < 0 then offset = 0 end

	if offset == 0 then upbutt:Disable() else upbutt:Enable() end
	if offset == (table.getn(self.actions) - NUMROWS) then downbutt:Disable() else downbutt:Enable() end

	for i in pairs(accepted) do accepted[i] = nil end

	for i in pairs(self.actions) do
		local action, name = self:GetObjectiveInfo(i)
		--local _, _, quest, part = string.find(name,L.PART_FIND)
		local _, _, quest = string.find(name,L.PART_FIND)
		local _, _, part = string.find(name, ".*%(Part (%d+)%)")
		if quest and not accepted[quest] and not self:GetObjectiveStatus(i) then accepted[quest] = name end
	end

	for i,row in ipairs(rows) do
		row.i = i + offset
		local action, name = self:GetObjectiveInfo(i + offset)
		if not name then row:Hide()
		else
			local turnedin, logi, complete = self:GetObjectiveStatus(i + offset)
			local optional, intown = self:GetObjectiveTag("O", i + offset), self:GetObjectiveTag("T", i + offset)
			row:Show()

			if intown then row:SetBackdropColor(0,0.5,0,0.5) else row:SetBackdropColor(0,0,0,0) end

			local shortname = string.gsub(name,L.PART_GSUB, "")
			logi = not turnedin and (not accepted[shortname] or (accepted[shortname] == name)) and logi
			complete = not turnedin and (not accepted[shortname] or (accepted[shortname] == name)) and complete
			local checked = turnedin or action == "ACCEPT" and logi or action == "COMPLETE" and complete

			row.icon:SetTexture(self.icons[action])
			if action ~= "ACCEPT" and action ~= "TURNIN" then row.icon:SetTexCoord(4/48, 44/48, 4/48, 44/48) end
			row.text:SetText(name..(optional and L[" |cff808080(Optional)"] or ""))
			row.detail:SetText(self:GetObjectiveTag("N", i + offset))
			row.check:SetChecked(checked)

			if (TourGuide.current > (i + offset)) and optional and not checked then
				row.text:SetTextColor(0.5, 0.5, 0.5)
				row.check:Disable()
			else
				row.text:SetTextColor(1, 0.82, 0)
				row.check:Enable()
			end

			if self.db.char.currentguide == "No Guide" then row.check:Disable() end
		end
	end
end
