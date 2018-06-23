local ICONSIZE, CHECKSIZE, GAP = 16, 16, 8
local FIXEDWIDTH = ICONSIZE + CHECKSIZE + GAP*4 - 4

local TourGuide = TourGuide
local ww = WidgetWarlock

local f = CreateFrame("Button", nil, UIParent)
TourGuide.statusframe = f
f:SetPoint("BOTTOMRIGHT", QuestWatchFrame, "TOPRIGHT", -60, -15)
f:SetHeight(24)
f:SetFrameStrata("LOW")
f:EnableMouse(true)
f:RegisterForClicks("LeftButtonUp","RightButtonUp")
f:SetBackdrop(ww.TooltipBorderBG)
f:SetBackdropColor(0.09, 0.09, 0.19, 0.5)
f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)

local check = ww.SummonCheckBox(CHECKSIZE, f, "LEFT", GAP, 0)
local icon = ww.SummonTexture(f, "ARTWORK", ICONSIZE, ICONSIZE, nil, "LEFT", check, "RIGHT", GAP-4, 0)
local text = ww.SummonFontString(f, "OVERLAY", "GameFontNormalSmall", nil, "RIGHT", -GAP-4, 0)
text:SetPoint("LEFT", icon, "RIGHT", GAP-4, 0)

local item = CreateFrame("Button", nil, UIParent)
item:SetFrameStrata("LOW")
item:SetHeight(36)
item:SetWidth(36)
item:SetPoint("BOTTOMRIGHT", QuestWatchFrame, "TOPRIGHT", -62, 10)
item:RegisterForClicks("LeftButtonUp","RightButtonUp")
local itemicon = ww.SummonTexture(item, "ARTWORK", 24, 24, "Interface\\Icons\\INV_Misc_Bag_08")
itemicon:SetAllPoints(item)
item:Hide()

local f2 = CreateFrame("Frame", nil, UIParent)
local f2anchor = "RIGHT"
f2:SetHeight(32)
f2:SetWidth(100)
local text2 = ww.SummonFontString(f2, "OVERLAY", "GameFontNormalSmall", nil, "RIGHT", -GAP-4, 0)
local icon2 = ww.SummonTexture(f2, "ARTWORK", ICONSIZE, ICONSIZE, nil, "RIGHT", text2, "LEFT", -GAP+4, 0)
local check2 = ww.SummonCheckBox(CHECKSIZE, f2, "RIGHT", icon2, "LEFT", -GAP+4, 0)
check2:SetChecked(true)
f2:Hide()


local elapsed, oldsize, newsize
f2:SetScript("OnUpdate", function()
	local self, el = this, arg1
	elapsed = elapsed + el
	if elapsed > 1 then
		self:Hide()
		icon:SetAlpha(1)
		text:SetAlpha(1)
		f:SetWidth(newsize)
	else
		self:SetPoint(f2anchor, f, f2anchor, 0, elapsed*40)
		self:SetAlpha(1 - elapsed)
		text:SetAlpha(elapsed)
		icon:SetAlpha(elapsed)
		f:SetWidth(oldsize + (newsize-oldsize)*elapsed)
	end
end)

function TourGuide:HideStatusFrameChildren()
	if TourGuide.objectiveframe:IsVisible() then HideUIPanel(TourGuide.objectiveframe) end
	if TourGuide.optionsframe:IsVisible() then HideUIPanel(TourGuide.optionsframe) end
	if TourGuide.guidelistframe:IsVisible() then HideUIPanel(TourGuide.guidelistframe) end	
end

function TourGuide:PositionStatusFrame()
	if self.db.profile.statusframepoint then
		f:ClearAllPoints()
		f:SetPoint(self.db.profile.statusframepoint, self.db.profile.statusframex, self.db.profile.statusframey)
	end

	if self.db.profile.itemframepoint then
		item:ClearAllPoints()
		item:SetPoint(self.db.profile.itemframepoint, self.db.profile.itemframex, self.db.profile.itemframey)
	end
end


function TourGuide:SetStatusText(i)
	self.current = i
	local action, quest = self:GetObjectiveInfo(i)
	local note = self:GetObjectiveTag("N")
	local newtext = (quest or"???")..(note and " [?]" or "")

	if text:GetText() ~= newtext or icon:GetTexture() ~= self.icons[action] then
		oldsize = f:GetWidth()
		icon:SetAlpha(0)
		text:SetAlpha(0)
		elapsed = 0
		f2:SetWidth(f:GetWidth())
		f2anchor = self.select(3, self.GetQuadrant(f))
		f2:ClearAllPoints()
		f2:SetPoint(f2anchor, f, f2anchor, 0, 0)
		f2:SetAlpha(1)
		icon2:SetTexture(icon:GetTexture())
		icon2:SetTexCoord(4/48, 44/48, 4/48, 44/48)
		text2:SetText(text:GetText())
		f2:Show()
	end

	icon:SetTexture(self.icons[action])
	if action ~= "ACCEPT" and action ~= "TURNIN" then icon:SetTexCoord(4/48, 44/48, 4/48, 44/48) end
	if self:GetObjectiveTag("T") then f:SetBackdropColor(0.09, 0.5, 0.19, 0.5) else f:SetBackdropColor(0.09, 0.09, 0.19, 0.5) end
	text:SetText(newtext)
	check:SetChecked(false)
	check:SetButtonState("NORMAL")
	if self.db.char.currentguide == "No Guide" then check:Disable() else check:Enable() end
	if i == 1 then f:SetWidth(FIXEDWIDTH + text:GetWidth()) end
	newsize = FIXEDWIDTH + text:GetWidth()

	if self.UpdateFubarPlugin then self.UpdateFubarPlugin(quest, self.icons[action], note) end
end


local lastmapped, lastmappedaction, tex, uitem
function TourGuide:UpdateStatusFrame()
	self:Debug( "UpdateStatusFrame", self.current)

	if self.updatedelay then
		local _, logi = self:GetObjectiveStatus(self.updatedelay)
		self:Debug( "Delayed update", self.updatedelay, logi)
		if logi then return end
	end

	local nextstep
	self.updatedelay = nil

	for i in ipairs(self.actions) do
		local name = self.quests[i]
		if not self.turnedin[name] and not nextstep then
			local action, name, quest = self:GetObjectiveInfo(i)
			local turnedin, logi, complete = self:GetObjectiveStatus(i)
			local note, useitem, optional, prereq, lootitem, lootqty = self:GetObjectiveTag("N", i), self:GetObjectiveTag("U", i), self:GetObjectiveTag("O", i), self:GetObjectiveTag("PRE", i), self:GetObjectiveTag("L", i)
			self:Debug( "UpdateStatusFrame", i, action, name, note, logi, complete, turnedin, quest, useitem, optional, lootitem, lootqty, lootitem and self.GetItemCount(lootitem) or 0)
			local level = tonumber((self:GetObjectiveTag("LV", i)))
			local needlevel = level and level > UnitLevel("player")
			local hasuseitem = useitem and self:FindBagSlot(useitem)
			local haslootitem = lootitem and self.GetItemCount(lootitem) >= lootqty
			local prereqturnedin = prereq and self.turnedin[prereq]

			-- Test for completed objectives and mark them done
			if action == "SETHEARTH" and self.db.char.hearth == name then return self:SetTurnedIn(i, true) end

			local zonetext, subzonetext, subzonetag = GetZoneText(), GetSubZoneText(), self:GetObjectiveTag("SZ")
			if (action == "RUN" or action == "FLY" or action == "HEARTH" or action == "BOAT") and (subzonetext == name or subzonetext == subzonetag or zonetext == name or zonetext == subzonetag) then return self:SetTurnedIn(i, true) end

			if action == "KILL" or action == "NOTE" then
				if not optional and haslootitem then return self:SetTurnedIn(i, true) end

				local quest, questtext = self:GetObjectiveTag("Q", i), self:GetObjectiveTag("QO", i)
				if quest and questtext then
					local qi = self:GetQuestLogIndexByName(quest)
					for lbi=1,GetNumQuestLeaderBoards(qi) do
						self:Debug( quest, questtext, qi, GetQuestLogLeaderBoard(lbi, qi))
						if GetQuestLogLeaderBoard(lbi, qi) == questtext then return self:SetTurnedIn(i, true) end
					end
				end
			end

			if action == "PET" and self.db.char.petskills[name] then return self:SetTurnedIn(i, true) end

			local incomplete
			if action == "ACCEPT" then incomplete = (not optional or hasuseitem or haslootitem or prereqturnedin) and not logi
			elseif action == "TURNIN" then incomplete = not optional or logi
			elseif action == "COMPLETE" then incomplete = not complete and (not optional or logi)
			elseif action == "NOTE" or action == "KILL" then incomplete = not optional or haslootitem
			elseif action == "GRIND" then incomplete = needlevel
			else incomplete = not logi end

			if incomplete then nextstep = i end

			if action == "COMPLETE" and logi and self.db.char.trackquests then
				local j = i
				repeat
					action = self:GetObjectiveInfo(j)
					turnedin, logi, complete = self:GetObjectiveStatus(j)
					if action == "COMPLETE" and logi and not complete then if not IsQuestWatched(logi) then AddQuestWatch(logi) end-- Watch if we're in a 'COMPLETE' block
					elseif action == "COMPLETE" and logi then RemoveQuestWatch(logi) end -- or unwatch if done
					j = j + 1
				until action ~= "COMPLETE"
			end
		end
	end
	QuestLog_Update()
	QuestWatch_Update()

	if not nextstep and self:LoadNextGuide() then return self:UpdateStatusFrame() end

	if not nextstep then return end

	self:SetStatusText(nextstep)
	self.current = nextstep
	local action, quest, fullquest = self:GetObjectiveInfo(nextstep)
	local turnedin, logi, complete = self:GetObjectiveStatus(nextstep)
	local note, useitem, optional, qid = self:GetObjectiveTag("N", nextstep), self:GetObjectiveTag("U", nextstep), self:GetObjectiveTag("O", nextstep), self:GetObjectiveTag("QID", nextstep)
	local zonename = self:GetObjectiveTag("Z", nextstep) or self.zonename
	self:Debug( string.format("Progressing to objective \"%s %s\"", action, quest))

	-- Mapping
	if (TomTom or Cartographer_Waypoints) and (lastmapped ~= quest or lastmappedaction ~= action) then
		lastmappedaction, lastmapped = action, quest
		self:ParseAndMapCoords(qid, action, note, quest, zonename) --, zone)
	end


	local newtext = (quest or "???")..(note and " [?]" or "")

	if text:GetText() ~= newtext or icon:GetTexture() ~= self.icons[action] then
		oldsize = f:GetWidth()
		icon:SetAlpha(0)
		text:SetAlpha(0)
		elapsed = 0
		f2:SetWidth(f:GetWidth())
		f2anchor = self.select(3, self.GetQuadrant(f))
		f2:ClearAllPoints()
		f2:SetPoint(f2anchor, f, f2anchor, 0, 0)
		f2:SetAlpha(1)
		icon2:SetTexture(icon:GetTexture())
		text2:SetText(text:GetText())
		f2:Show()
	end

	icon:SetTexture(self.icons[action])
	text:SetText(newtext)
	check:SetChecked(false)
	if not f2:IsVisible() then f:SetWidth(FIXEDWIDTH + text:GetWidth()) end
	newsize = FIXEDWIDTH + text:GetWidth()

	tex = useitem and self.select(9, GetItemInfo(tonumber(useitem)))
	uitem = useitem
	item.uitem = tex and uitem or nil
	if UnitAffectingCombat("player") then self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else self:PLAYER_REGEN_ENABLED() end

	self:UpdateOHPanel()
end


function TourGuide:PLAYER_REGEN_ENABLED()
	if tex then
		itemicon:SetTexture(tex)
		item:Show()
		tex = nil
	else item:Hide() end
	if self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end


f:SetScript("OnClick", function()
	local self, btn = this, arg1
	if TourGuide.db.char.currentguide == "No Guide" then
		TourGuide.guidelistframe:Show()
	else
		if btn == "RightButton" then
			if TourGuide.objectiveframe:IsVisible() then
				HideUIPanel(TourGuide.objectiveframe)
			else
				local quad, vhalf, hhalf = TourGuide.GetQuadrant(self)
				local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
				TourGuide.objectiveframe:ClearAllPoints()
				TourGuide.objectiveframe:SetPoint(quad, self, anchpoint)
				ShowUIPanel(TourGuide.objectiveframe)
			end
		else
			if QuestLogFrame:IsVisible() or (EQL3_QuestLogFrame and EQL3_QuestLogFrame:IsVisible()) then
				HideUIPanel(QuestLogFrame)
				HideUIPanel(EQL3_QuestLogFrame)
			else
				local i = TourGuide:GetQuestLogIndexByName()
				if i then SelectQuestLogEntry(i) end
				ShowUIPanel(QuestLogFrame)
			end
		end
	end
end)


check:SetScript("OnClick", function(self, btn) TourGuide:SetTurnedIn() end)


item:SetScript("OnClick", function()
	if TourGuide:GetObjectiveInfo() == "USE" then TourGuide:SetTurnedIn() end
	if item.uitem then
		local bag, slot = TourGuide:FindBagSlot(item.uitem)
		if bag and slot then UseContainerItem(bag, slot) else TourGuide:Print("Item not found") end
	end
end)


local function ShowTooltip()
	local self = this
	local tip = TourGuide:GetObjectiveTag("N")
	if not tip or tip == "" then return end
	tip = tostring(tip)
	local quad, vhalf, hhalf = TourGuide.GetQuadrant(self)
	--local anchpoint = (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
	local anchpoint = "ANCHOR_TOP"..hhalf
	TourGuide:Debug( "Setting tooltip anchor", anchpoint)
	GameTooltip:SetOwner(self, anchpoint)
	GameTooltip:SetText(tip,nil,nil,nil,nil,1)
	GameTooltip:Show()
end

local function HideTooltip()
 	if GameTooltip:IsOwned(this) then
 		GameTooltip:Hide()
 	end
end

f:SetScript("OnLeave", HideTooltip)
f:SetScript("OnEnter", ShowTooltip)

f:RegisterForDrag("LeftButton")
f:SetMovable(true)
f:SetClampedToScreen(true)
f:SetScript("OnDragStart", function()
	local frame = this
	TourGuide:HideStatusFrameChildren()
	GameTooltip:Hide()
	frame:StartMoving()
end)
f:SetScript("OnDragStop", function()
	local frame = this
	frame:StopMovingOrSizing()
	local _
	TourGuide.db.profile.statusframepoint, _, _, TourGuide.db.profile.statusframex, TourGuide.db.profile.statusframey = frame:GetPoint()
	frame:ClearAllPoints()
	frame:SetPoint(TourGuide.db.profile.statusframepoint, TourGuide.db.profile.statusframex, TourGuide.db.profile.statusframey)
	ShowTooltip(frame)
end)


item:RegisterForDrag("LeftButton")
item:SetMovable(true)
item:SetClampedToScreen(true)
item:SetScript("OnDragStart", function() local frame = this frame:StartMoving() end)
item:SetScript("OnDragStop", function()
	local frame = this
	frame:StopMovingOrSizing()
	local _
	TourGuide.db.profile.itemframepoint, _, _, TourGuide.db.profile.itemframex, TourGuide.db.profile.itemframey = frame:GetPoint()
end)

f:SetScript("OnHide", function()
	TourGuide:HideStatusFrameChildren()
end)
