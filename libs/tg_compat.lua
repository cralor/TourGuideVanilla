--[[
  Some shims for Lua and WoW API not available in 1.12.x
  -- Roadblock & rsheep
]]
local _G = getfenv(0)

TG = {}

TG.select = function(index,...)
  assert(tonumber(index) or index=="#","Invalid argument #1 to select(). Usage: select(\"#\"|int,...)")
  if index == "#" then
    return tonumber(arg.n) or 0
  end
  for i=1,index-1 do
    table.remove(arg,1)
  end
  return unpack(arg)
end

TG.join = function(delimiter, list)
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

TG.trim = function(s)
  return (string.gsub(s,"^%s*(.-)%s*$", "%1"))
end

TG.split = function(...) -- separator, string
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

TG.modf = function(f)
  if f > 0 then
    return math.floor(f), math.mod(f,1)
  end
  return math.ceil(f), math.mod(f,1)
end

if not _G.GetItemCount then
  GetItemCount = function(itemID)
    local itemInfoTexture = TG.select(9, GetItemInfo(itemID))
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
  _G.GetItemCount = GetItemCount
end

if not _G.print then
  print = function(str) DEFAULT_CHAT_FRAME:AddMessage(tostring(str)) end
  _G.print = print
end
