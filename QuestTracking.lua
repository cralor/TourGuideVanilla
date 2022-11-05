

local TourGuide = TourGuide
local L = TourGuide.Locale
local hadquest


TourGuide.TrackEvents = {"UI_INFO_MESSAGE", "CHAT_MSG_LOOT", "CHAT_MSG_SYSTEM", "QUEST_WATCH_UPDATE", "QUEST_LOG_UPDATE", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
	"MINIMAP_ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_LEVEL_UP", "ADDON_LOADED", "CRAFT_SHOW", "PLAYER_DEAD"}


function TourGuide:ADDON_LOADED(event, addon)
	if addon ~= "Blizzard_TrainerUI" then return end

	self:UnregisterEvent("ADDON_LOADED")

	local f = CreateFrame("Frame", nil, ClassTrainerFrame)
	f:SetScript("OnShow", function() if self:GetObjectiveInfo() == "TRAIN" then self:SetTurnedIn() end end)
end


function TourGuide:PLAYER_LEVEL_UP(event, newlevel)
	local level = tonumber((self:GetObjectiveTag("LV")))
	self:Debug( "PLAYER_LEVEL_UP", newlevel, level)
	if level and newlevel >= level then self:SetTurnedIn() end
end


function TourGuide:ZONE_CHANGED(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
	local zonetext, subzonetext, subzonetag, action, quest = GetZoneText(), GetSubZoneText(), self:GetObjectiveTag("SZ"), self:GetObjectiveInfo()
	if (action == "RUN" or action == "FLY" or action == "HEARTH" or action == "BOAT") and (subzonetext == quest or subzonetext == subzonetag or zonetext == quest or zonetext == subzonetag) then
		self:Debug( string.format("Detected zone change %q - %q", action, quest))
		self:SetTurnedIn()
	end
end
TourGuide.ZONE_CHANGED_INDOORS = TourGuide.ZONE_CHANGED
TourGuide.MINIMAP_ZONE_CHANGED = TourGuide.ZONE_CHANGED
TourGuide.ZONE_CHANGED_NEW_AREA = TourGuide.ZONE_CHANGED


function TourGuide:CHAT_MSG_SYSTEM(msg)
	local action, quest = self:GetObjectiveInfo()

	local _, _, loc = string.find(msg,L["(.*) is now your home."])
	if loc then
		self:Debug( string.format("Detected setting hearth to %q", loc))
		self.db.char.hearth = loc
		return action == "SETHEARTH" and loc == quest and self:SetTurnedIn()
	end

	if action == "ACCEPT" then
		local _, _, text = string.find(msg,L["Quest accepted: (.*)"])
		if text and string.gsub(quest,L.PART_GSUB, "") == text then
			self:Debug( string.format("Detected quest accept %q", quest))
			return self:UpdateStatusFrame()
		end
	end

	if action == "PET" then
		local _, _, text = string.find(msg,L["You have learned a new spell: (.*)."])
		local nextEntry = table.getn(self.db.char.petskills) + 1
		self.db.char.petskills[nextEntry] = text
		if text and quest == text then
			self:Debug( string.format("Detected pet skill train %q", quest))
			return self:SetTurnedIn()
		end
	end
end


function TourGuide:QUEST_WATCH_UPDATE(event)
	if self:GetObjectiveInfo() == "COMPLETE" then self:UpdateStatusFrame() end
end


function TourGuide:QUEST_LOG_UPDATE(event)
	local action = self:GetObjectiveInfo()
	local _, logi, complete = self:GetObjectiveStatus()

	self:Debug( "QUEST_LOG_UPDATE", action, logi, complete)

	if (self.updatedelay and not logi) or action == "ACCEPT" or action == "COMPLETE" and complete then self:UpdateStatusFrame() end

	if action == "KILL" or action == "NOTE" then
		local quest, questtext = self:GetObjectiveTag("Q"), self:GetObjectiveTag("QO")
		if not quest or not questtext then return end

		local qi = self:GetQuestLogIndexByName(quest)
		for i=1,GetNumQuestLeaderBoards(qi) do
			if GetQuestLogLeaderBoard(i, qi) == questtext then self:SetTurnedIn() end
		end
	elseif action == "COMPLETE" then
		local skipNext = self:GetObjectiveTag("S")
		if self.db.char.skipfollowups and skipNext and QuestFrame:IsVisible() then
			CloseQuest()
			TourGuide:Print(L["Automatically skipping the follow-up"])
		end
	end
end


function TourGuide:CHAT_MSG_LOOT(event, msg)
	local action, quest = self:GetObjectiveInfo()
	local lootitem, lootqty = self:GetObjectiveTag("L")
	local _, _, itemid, name = string.find(msg,L["^You .*Hitem:(%d+).*(%[.+%])"])
	self:Debug( event, action, quest, lootitem, lootqty, itemid, name)

	if action == "BUY" and name and name == quest
	or (action == "BUY" or action == "KILL" or action == "NOTE") and lootitem and itemid == lootitem and (self.GetItemCount(lootitem) + 1) >= lootqty then
		return self:SetTurnedIn()
	end
end


function TourGuide:PLAYER_DEAD()
	if self:GetObjectiveInfo() == "DIE" then
		self:Debug( "Player has died")
		self:SetTurnedIn()
	end
end


function TourGuide:UI_INFO_MESSAGE(event, msg)
	if msg == ERR_NEWTAXIPATH and self:GetObjectiveInfo() == "GETFLIGHTPOINT" then
		self:Debug( "Discovered flight point")
		self:SetTurnedIn()
	end
end


function TourGuide:CRAFT_SHOW()
	if not GetCraftName() == "Beast Training" then return end
	for i=1,GetNumCrafts() do
		local name, rank = GetCraftInfo(i)
		self.db.char.petskills[name.. (rank == "" and "" or (" (" .. rank .. ")"))] = true
	end
	if self:GetObjectiveInfo() == "PET" then self:UpdateStatusFrame() end
end


local orig = GetQuestReward
GetQuestReward = function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
	local quest = string.gsub(GetTitleText(), "%[[0-9%+%-]+]%s", "")
	
	TourGuide:Debug( "GetQuestReward", quest)
	TourGuide:CompleteQuest(quest, true)

	return orig(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20)
end
