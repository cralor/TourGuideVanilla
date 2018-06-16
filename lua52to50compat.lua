--[[
  Some shims for Lua and WoW API not available in 1.12.x
  -- Roadblock & rsheep
]]
local _G = getfenv(0)

if not _G.GetItemCount then
  GetItemCount = function(itemID)
    local itemInfoTexture = select(9, GetItemInfo(itemID))
    if itemInfoTexture == nil then return 0 end
    local totalItemCount = 0
    for i=0,4 do
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
  print = function(str) DEFAULT_CHAT_FRAME:AddMessage(str) end
  _G.print = print
end
