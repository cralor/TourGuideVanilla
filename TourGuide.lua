local L = TOURGUIDE_LOCALE
TOURGUIDE_LOCALE = nil

TourGuide = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceDebug-2.0", "AceEvent-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
local D = AceLibrary("Dewdrop-2.0")
local DF = AceLibrary("Deformat-2.0")
local T = AceLibrary("Tablet-2.0")
local gratuity = AceLibrary("Gratuity-2.0")

TourGuide.guides = {}
TourGuide.guidelist = {}
TourGuide.nextzones = {}
TourGuide.Locale = L
TourGuide.myfaction = UnitFactionGroup("player")

TourGuide.icons = setmetatable({
	ACCEPT = "Interface\\GossipFrame\\AvailableQuestIcon",
	COMPLETE = "Interface\\Icons\\Ability_DualWield",
	TURNIN = "Interface\\GossipFrame\\ActiveQuestIcon",
	KILL = "Interface\\Icons\\Ability_Creature_Cursed_02",
	RUN = "Interface\\Icons\\Ability_Tracking",
	MAP = "Interface\\Icons\\Ability_Spy",
	FLY = "Interface\\Icons\\Ability_Rogue_Sprint",
	SETHEARTH = "Interface\\AddOns\\TourGuideVanilla\\media\\resting.tga",
	HEARTH = "Interface\\Icons\\INV_Misc_Rune_01",
	NOTE = "Interface\\Icons\\INV_Misc_Note_01",
	GRIND = "Interface\\Icons\\INV_Stone_GrindingStone_05",
	USE = "Interface\\Icons\\INV_Misc_Bag_08",
	BUY = "Interface\\Icons\\INV_Misc_Coin_01",
	BOAT = "Interface\\Icons\\Ability_Druid_AquaticForm",
	GETFLIGHTPOINT = "Interface\\Icons\\Ability_Hunter_EagleEye",
	PET = "Interface\\Icons\\Ability_Hunter_BeastCall02",
	DIE = "Interface\\AddOns\\TourGuideVanilla\\media\\dead.tga",
}, {__index = function() return "Interface\\Icons\\INV_Misc_QuestionMark" end})

local defaults = {
	debug = false,
	hearth = UNKNOWN,
	turnins = {},
	cachedturnins = {},
	trackquests = true,
	completion = {},
	currentguide = "No Guide",
	mapquestgivers = true,
	mapnotecoords = true,
	showstatusframe = true,
	showuseitem = true,
	showuseitemcomplete = true,
	skipfollowups = true,
	petskills = {},
}

local options = {
  type = "group",
  handler = TourGuide,
  args =
	{
    TrackQuests =
    {
      name = "Auto Track",
      desc = L["Automatically Track Quests"],
      type = "toggle",
      get  = function() return TourGuide.db.char.trackquests end,
      set  = function(newValue)
        TourGuide.db.char.trackquests = newValue
        TourGuide.optionsframe.qtrack:SetChecked(TourGuide.db.char.trackquests)
      end,
      order = 1,
    },
    SkipFollowUps =
    {
      name = "Auto Skip Followups",
      desc = L["Automatically skip suggested follow-ups"],
      type = "toggle",
      get = function() return TourGuide.db.char.skipfollowups end,
      set = function(newValue)
        TourGuide.db.char.skipfollowups = newValue
        TourGuide.optionsframe.qskipfollowups:SetChecked(TourGuide.db.char.skipfollowups)
      end,
      order = 2,
    },
    StatusFrame =
    {
      name = "Toggle Status",
      desc = "Show/Hide Status Frame",
      type = "toggle",
      get = function() return TourGuide.statusframe:IsVisible() end,
      set = "OnClick",
      order = 3,
    },
  },
}

---------
-- FuBar
---------
TourGuide.hasIcon = [[Interface\QuestFrame\UI-QuestLog-BookIcon]]
TourGuide.title = "TourGuide"
TourGuide.defaultMinimapPosition = 215
TourGuide.defaultPosition = "CENTER"
TourGuide.cannotDetachTooltip = true
TourGuide.tooltipHiddenWhenEmpty = false
TourGuide.hideWithoutStandby = true
TourGuide.independentProfile = true

function TourGuide:OnInitialize() -- ADDON_LOADED (1)
  self:RegisterDB("TourGuideAlphaDB")
  self:RegisterDefaults("char", defaults )
  self:RegisterChatCommand( { "/tg", "/tourguide" }, options )
  self.OnMenuRequest = options
  if not FuBar then
    self.OnMenuRequest.args.hide.guiName = L["Hide minimap icon"]
    self.OnMenuRequest.args.hide.desc = L["Hide minimap icon"]
  end
  self:MigrateDongle()
  self.cachedturnins = self.db.char.cachedturnins
	if self.myfaction == nil then
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
	self:PositionStatusFrame()
  self:CreateConfigPanel()
end

function TourGuide:OnEnable() -- PLAYER_LOGIN (2)
	local _, title = GetAddOnInfo("TourGuide")
	local author, version = GetAddOnMetadata("TourGuide", "Author"), GetAddOnMetadata("TourGuide", "Version")

	if self.db.char.debug then self:SetDebugging(true)
	else self:SetDebugging(false)	end

	if self.db.char.currentguide == "No Guide" and UnitLevel("player") == 1 and UnitXP("player") == 0 then
		local startguides = {Orc = "Durotar (1-12)", Troll = "Durotar (1-12)", Tauren = "Mulgore (1-12)", Undead = "Tirisfal Glades (1-12)",
			Dwarf = "Dun Morogh (1-11)", Gnome = "Dun Morogh (1-11)", Human = "Elwynn Forest (1-12)", NightElf = "Teldrassil (1-12)"}
		self.db.char.currentguide = startguides[self.select(2, UnitRace("player"))] or self.guidelist[1]
	end

	if self.myfaction == nil then
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	else
		self.db.char.currentguide = self.db.char.currentguide or self.guidelist[1]
		self:LoadGuide(self.db.char.currentguide)
		self.initializeDone = true
		for _,event in pairs(self.TrackEvents) do self:RegisterEvent(event) end
		self:RegisterEvent("QUEST_COMPLETE", "UpdateStatusFrame")
		self:RegisterEvent("QUEST_DETAIL", "UpdateStatusFrame")
		self.TrackEvents = nil
		self:UpdateStatusFrame()
		self.enableDone = true
	end
end

function TourGuide:MigrateDongle()
  if type(TourGuideAlphaDB.char)=="table" then
  	for name, data in pairs(TourGuideAlphaDB.char) do
  		local name = string.gsub(name,"-", "of")
  		TourGuideAlphaDB.chars = TourGuideAlphaDB.chars or {}
  		TourGuideAlphaDB.chars[name] = data
  	end
  	TourGuideAlphaDB.char = nil
	  if TourGuideAlphaDB.profiles then TourGuideAlphaDB.profiles = {} end
	  if TourGuideAlphaDB.profileKeys then TourGuideAlphaDB.profileKeys = nil end
  end
end

function TourGuide:OnDisable()
  self:UnregisterAllEvents()
end

function TourGuide:OnTooltipUpdate()
  local hint = "\nClick to show/hide the Status\nRight-click for Options"
  T:SetHint(hint)
end

function TourGuide:OnTextUpdate()
  self:SetText("TourGuide")
end

function TourGuide:OnClick()
	if TourGuide.statusframe:IsVisible() then
		HideUIPanel(TourGuide.statusframe)
	else
		ShowUIPanel(TourGuide.statusframe)
	end
end

function TourGuide:PLAYER_ENTERING_WORLD()
	self.myfaction = UnitFactionGroup("player")
	-- load static guides
	for i,t in ipairs(self.deferguides) do
		local name,nextzone,faction,sequencefunc = t[1], t[2], t[3], t[4]
		if faction == self.myfaction or faction == "Both" then
			self.guides[name] = sequencefunc
			self.nextzones[name] = nextzone
			table.insert(self.guidelist, name)
		end
	end
	self.deferguides = {}
	-- deferred Initialize (VARIABLES_LOADED)
	if not self.initializeDone then
		self.db.char.currentguide = self.db.char.currentguide or self.guidelist[1]
		self:LoadGuide(self.db.char.currentguide)
	end
	-- deferred Enable (PLAYER_LOGIN)
	if not self.enableDone then
		for _,event in pairs(self.TrackEvents) do self:RegisterEvent(event) end
		self:RegisterEvent("QUEST_COMPLETE", "UpdateStatusFrame")
		self:RegisterEvent("QUEST_DETAIL", "UpdateStatusFrame")
		self.TrackEvents = nil
		self:UpdateStatusFrame()
	end
	self.initializeDone = true
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end


function TourGuide:RegisterGuide(name, nextzone, faction, sequencefunc)
	if self.myfaction == nil then
		self.deferguides = self.deferguides or {}
		table.insert(self.deferguides,{name,nextzone,faction,sequencefunc})
	else
		if faction ~= "Both" then if faction ~= self.myfaction then return end end
		self.guides[name] = sequencefunc
		self.nextzones[name] = nextzone
		table.insert(self.guidelist, name)
	end
end


function TourGuide:LoadNextGuide()
	self:LoadGuide(self.nextzones[self.db.char.currentguide] or "No Guide", true)
	self:UpdateGuideListPanel()
	return true
end


function TourGuide:GetQuestLogIndexByName(name)
	name = name or self.quests[self.current]
	name = string.gsub(name,L.PART_GSUB, "")
	for i=1,GetNumQuestLogEntries() do
		local title, _, _, isHeader = GetQuestLogTitle(i)
		title = string.gsub(title, "%[[0-9%+%-]+]%s", "")
		if not isHeader and title == name then return i end
	end
end

function TourGuide:GetQuestDetails(name)
	if not name then return end
	local i = self:GetQuestLogIndexByName(name)
	if not i or i < 1 then return end
	local _, _, _, _, _, isComplete = GetQuestLogTitle(i)
	local complete = i and isComplete == 1

	return i, complete
end


function TourGuide:FindBagSlot(itemid)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local item = GetContainerItemLink(bag, slot)
			if item and string.find(item, "item:"..itemid) then return bag, slot end
		end
	end
	return false
end


function TourGuide:GetObjectiveInfo(i)
	local i = i or self.current
	if not self.actions[i] then return end

	return self.actions[i], string.gsub(self.quests[i],"@.*@", ""), self.quests[i] -- Action, display name, full name
end


function TourGuide:GetObjectiveStatus(i)
	local i = i or self.current
	if not self.actions[i] then return end

	return self.turnedin[self.quests[i]], self:GetQuestDetails(self.quests[i]) -- turnedin, logi, complete
end


function TourGuide:SetTurnedIn(i, value, noupdate)
	if not i then
		i = self.current
		value = true
	end

	if value then value = true else value = nil end -- Cleanup to minimize savedvar data

	self.turnedin[self.quests[i]] = value
	self:Debug( string.format("Set turned in %q = %s", self.quests[i], tostring(value)))
	if not noupdate then self:UpdateStatusFrame()
	else self.updatedelay = i end
end


function TourGuide:CompleteQuest(name, noupdate)
	if not self.current then
		self:Debug( string.format("Cannot complete %q, no guide loaded", name))
		return
	end

	local action, quest
	for i in ipairs(self.actions) do
		action, quest = self:GetObjectiveInfo(i)
		self:Debug( string.format("Action %q Quest %q",action,quest))
		if action == "TURNIN" and not self:GetObjectiveStatus(i) and name == string.gsub(quest,L.PART_GSUB, "") then
			self:Debug( string.format("Saving quest turnin %q", quest))
			return self:SetTurnedIn(i, true, noupdate)
		end
	end
	self:Debug( string.format("Quest %q not found!", name))
end


---------------------------------
--      Utility Functions      --
---------------------------------

function TourGuide.select(index,...)
  assert(tonumber(index) or index=="#","Invalid argument #1 to select(). Usage: select(\"#\"|int,...)")
  if index == "#" then
    return tonumber(arg.n) or 0
  end
  for i=1,index-1 do
    table.remove(arg,1)
  end
  return unpack(arg)
end

function TourGuide.join(delimiter, list)
  assert(type(delimiter)=="string" and type(list)=="table", "Invalid arguments to join(). Usage: string.join(delimiter, list)")
  local len = getn(list)
  if len == 0 then
    return ""
  end
  local s = list[1]
  for i = 2, len do
    s = string.format("%s%s%s",s,delimiter,list[i])
  end
  return s
end

function TourGuide.trim(s)
  return (string.gsub(s,"^%s*(.-)%s*$", "%1"))
end

function TourGuide.split(...) -- separator, string
  assert(arg.n>0 and type(arg[1])=="string", "Invalid arguments to split(). Usage: string.split([separator], subject)")
  local sep, s = arg[1], arg[2]
  if s == nil then
    s, sep = sep, ":"
  end
  local fields = {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(s, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return fields
end

function TourGuide.modf(f)
  if f > 0 then
    return math.floor(f), math.mod(f,1)
  end
  return math.ceil(f), math.mod(f,1)
end

function TourGuide.GetItemCount(itemID)
  local itemInfoTexture = TourGuide.select(9, GetItemInfo(itemID))
  if itemInfoTexture == nil then return 0 end
  local totalItemCount = 0
  for i=0,NUM_BAG_FRAMES do
    local numSlots = GetContainerNumSlots(i)
    if numSlots > 0 then
      for k=1,numSlots do
        local itemTexture, itemCount = GetContainerItemInfo(i, k)
        if itemInfoTexture == itemTexture then
          totalItemCount = totalItemCount + itemCount
        end
      end
    end
  end
  return totalItemCount
end

function TourGuide.ColorGradient(perc)
	if perc >= 1 then return 0,1,0
	elseif perc <= 0 then return 1,0,0 end

	local segment, relperc = TourGuide.modf(perc*2)
	local r1, g1, b1, r2, g2, b2 = TourGuide.select((segment*3)+1, 1,0,0, 1,0.82,0, 0,1,0)
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

function TourGuide.GetQuadrant(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "BOTTOMLEFT", "BOTTOM", "LEFT" end
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, vhalf, hhalf
end

function TourGuide.GetUIParentAnchor(frame)
	local w, h, x, y = UIParent:GetWidth(), UIParent:GetHeight(), frame:GetCenter()
	local hhalf, vhalf = (x > w/2) and "RIGHT" or "LEFT", (y > h/2) and "TOP" or "BOTTOM"
	local dx = hhalf == "RIGHT" and math.floor(frame:GetRight() + 0.5) - w or math.floor(frame:GetLeft() + 0.5)
	local dy = vhalf == "TOP" and math.floor(frame:GetTop() + 0.5) - h or math.floor(frame:GetBottom() + 0.5)
	return vhalf..hhalf, dx, dy
end

function TourGuide:DumpLoc()
	if IsShiftKeyDown() then
		if not self.db.global.savedpoints then self:Print("No saved points")
		else for t in string.gfind(self.db.global.savedpoints, "([^\n]+)") do self:Print(t) end end
	elseif IsControlKeyDown() then
		self.db.global.savedpoints = nil
		self:Print("Saved points cleared")
	else
		local _, _, x, y = Astrolabe:GetCurrentPlayerPosition()
		local s = string.format("%s, %s, (%.2f, %.2f) -- %s %s", GetZoneText(), GetSubZoneText(), x*100, y*100, self:GetObjectiveInfo())
		self.db.global.savedpoints = (self.db.global.savedpoints or "") .. s .. "\n"
		self:Print(s)
	end
end
