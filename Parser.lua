
local actiontypes = {
	A = "ACCEPT",
	C = "COMPLETE",
	T = "TURNIN",
	K = "KILL",
	R = "RUN",
	H = "HEARTH",
	h = "SETHEARTH",
	G = "GRIND",
	F = "FLY",
	f = "GETFLIGHTPOINT",
	N = "NOTE",
	B = "BUY",
	b = "BOAT",
	U = "USE",
	P = "PET",
	D = "DIE",
}


function TourGuide:GetObjectiveTag(tag, i)
	--self:Debug( "GetObjectiveTag", tag, i)
	i = i or self.current
	local tags = self.tags[i]
	if not tags then return end

	if tag == "O" then return string.find(tags,"|O|")
	elseif tag == "T" then return string.find(tags,"|T|")
	elseif tag == "S" then return string.find(tags,"|S|")
	elseif tag == "QID" then return self.select(3, string.find(tags, "|QID|(%d+)|"))
	elseif tag == "L" then
		local _, _, lootitem, lootqty = string.find(tags,"|L|(%d+)%s?(%d*)|")
		lootqty = tonumber(lootqty) or 1

		return lootitem, lootqty
	end

	return self.select(3, string.find(tags,"|"..tag.."|([^|]*)|?"))
end


local function DumpQuestDebug(accepts, turnins, completes)
	for quest in pairs(accepts) do if not turnins[quest] then TourGuide:Debug( string.format("Quest has no 'turnin' objective: %s", quest)) end end
	for quest in pairs(turnins) do if not accepts[quest] then TourGuide:Debug( string.format("Quest has no 'accept' objective: %s", quest)) end end
	for quest in pairs(completes) do if not accepts[quest] and not turnins[quest] then TourGuide:Debug( string.format("Quest has no 'accept' and 'turnin' objectives: %s", quest)) end end
end


local titlematches = {"For", "A", "The", "Or", "In", "Then", "From", "To"}
local function DebugQuestObjective(text, action, quest, accepts, turnins, completes)
	local haserrors

	if (action == "A" and accepts[quest] or action == "T" and turnins[quest] or action == "C" and completes[quest]) and not string.find(text, "|NODEBUG|") then
		TourGuide:Debug( string.format("%s %s -- Duplicate objective", action, quest))
		haserrors = true
	end

	if action == "A" then accepts[quest] = true
	elseif action == "T" then turnins[quest] = true
	elseif action == "C" then completes[quest] = true end

	if string.find(text, "|NODEBUG|") then return haserrors end

	if action == "A" or action == "C" or action == "T" then
		-- Catch bad Title Case
		for _,word in pairs(titlematches) do
			if string.find(quest,"[^:]%s"..word.."%s") or string.find(quest,"[^:]%s"..word.."$") or string.find(quest,"[^:]%s"..word.."@") then
				TourGuide:Debug( string.format("%s %s -- Contains bad title case", action, quest))
				haserrors = true
			end
		end
	end

	if string.find(text,"[���]") then
		TourGuide:Debug( string.format("%s %s -- Contains bad char", action, quest))
		haserrors = true
	end

	local _, _, comment = string.find(text, "(|[NLUC]V?|[^|]+)$") or string.find(text, "(|[NLUC]V?|[^|]+) |[NLUC]V?|")
	if comment then
		TourGuide:Debug( "Unclosed comment: ".. comment)
		haserrors = true
	end

	return haserrors
end


local myclass, myrace = UnitClass("player"), UnitRace("player")
local function StepParse(guide)
	local accepts, turnins, completes = {}, {}, {}
	local uniqueid = 1
	local actions, quests, tags = {}, {}, {}
	local i, haserrors = 1, false
	local guidet = TourGuide.split("\r\n", guide)

	for _,text in pairs(guidet) do
		local _, _, class = string.find(text,"|C|([^|]+)|")
		local _, _, race = string.find(text,"|R|([^|]+)|")
		if text ~= "" and (not class or string.find(class, myclass)) and (not race or string.find(race,myrace)) then
			local _, _, action, quest, tag = string.find(text,"^(%a) ([^|]*)(.*)")
			assert(actiontypes[action], "Unknown action: "..text)
			quest = TourGuide.trim(quest)
			if not (action == "A" or action =="C" or action =="T") then
				quest = quest.."@"..uniqueid.."@"
				uniqueid = uniqueid + 1
			end
			actions[i], quests[i], tags[i] = actiontypes[action], quest, tag
			i = i + 1
			haserrors = DebugQuestObjective(text, action, quest, accepts, turnins, completes) or haserrors
		end
	end
	DumpQuestDebug(accepts, turnins, completes)
	if haserrors and TourGuide:IsDebugging() then TourGuide:Print("This guide contains errors") end

	return actions, quests, tags
end


function TourGuide:LoadGuide(name, complete)
	if not name then return end
	if complete then self.db.char.completion[self.db.char.currentguide] = 1
	elseif self.actions then self.db.char.completion[self.db.char.currentguide] = (self.current-1)/table.getn(self.actions) end

	self.db.char.currentguide = self.guides[name] and name or self.guidelist[1]

	self:Debug( string.format("Loading guide: %s", name))
	self.guidechanged = true
	local _, _, zonename = string.find(name,"^(.*) %(.*%)$")
	self.zonename = zonename
	self.actions, self.quests, self.tags = StepParse(self.guides[self.db.char.currentguide]())

	if not self.db.char.turnins[name] then self.db.char.turnins[name] = {} end
	self.turnedin = self.db.char.turnins[name]
end


function TourGuide:DebugGuideSequence(dumpquests)
	local accepts, turnins, completes = {}, {}, {}
	local function DebugParse(guide)
		local uniqueid, haserrors = 1
		local guidet = TourGuide.split("\n", guide)
		for _,text in pairs(guidet) do
			if text ~= "" then
				local _, _, action, quest, tag = string.find(text,"^(%a) ([^|]*)(.*)")
				if not actiontypes[action] then TourGuide:Debug( "Unknown action: "..text) end
				quest = TourGuide.trim(quest)
				if not (action == "A" or action =="C" or action =="T") then
					quest = quest.."@"..uniqueid.."@"
					uniqueid = uniqueid + 1
				end
				haserrors = DebugQuestObjective(text, action, quest, accepts, turnins, completes) or haserrors
			end
		end

		return haserrors
	end

	self:Debug( "------ Begin Full Debug ------")

	local name, lastzone = self.db.char.currentguide
	repeat
		if not self.guides[name] then
			self:Debug( string.format("Cannot find guide %q", name))
			name, lastzone = nil, name
		elseif DebugParse(self.guides[name]()) then
			self:Debug( string.format("Errors in guide: %s", name))
			self:Debug( "---------------------------")
		end
		name, lastzone = self.nextzones[name], name
	until not name

	if dumpquests then
		self:Debug( "------ Quest Continuity Debug ------")
		DumpQuestDebug(accepts, turnins, completes)
	end
	self:Debug( "Last zone loaded:", lastzone)
	self:Debug( "------ End Full Debug ------")
end
