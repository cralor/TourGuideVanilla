
local localized
local loc = GetLocale()


-----------------------
--      Engrish      --
-----------------------

local engrish = {
	PART_GSUB = "%s%(Part %d+%)",
	PART_FIND = "(.+)%s%(Part %d+%)",

	-- Mapping.lua
	COORD_MATCH = "%(([%d.]+),%s?([%d.]+)%)",
}


----------------------
--      German      --
----------------------

if loc == "deDE" then localized = {
	PART_GSUB = "%s%(Teil %d+%)",
	PART_FIND = "(.+)%s%(Teil %d+%)",
	["(.*) is now your home."] = "(.*) ist jetzt Euer Zuhause.",
	["Quest accepted: (.*)"] = "Quest angenommen: (.*)",
	["^You .*Hitem:(%d+).*(%[.+%])"] = "^Ihr .*Hitem:(%d+).*(%[.+%])",
	["|cffff4500This quest is not listed in your current guide"] = "|cffff4500Diese Quest ist nicht in deinem Guide",
} end


----------------------
--      French      --
----------------------

if loc == "frFR" then localized = {
	PART_GSUB = "%s%(Partie %d+%)",
	PART_FIND = "(.+)%s%(Partie %d+%)",
	["(.*) is now your home."] = "(.*) est maintenant votre foyer.",
	["Quest accepted: (.*)"] = "Quête acceptée: (.*)",
	["^You .*Hitem:(%d+).*(%[.+%])"] = "^Vous .*Hitem:(%d+).*(%[.+%])",
	["|cffff4500This quest is not listed in your current guide"] = "|cffff4500Cette quête n'est pas listé dans votre guide actuel",
} end


-- Metatable majicks... makes localized table fallback to engrish, or fallback to the index requested.
-- This ensures we ALWAYS get a value back, even if it's the index we requested originally
TOURGUIDE_LOCALE = localized and setmetatable(localized, {__index = function(t,i) return engrish[i] or i end})
	or setmetatable(engrish, {__index = function(t,i) return i end})
