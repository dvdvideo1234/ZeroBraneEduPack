local keymap = {}

local metaKeymap = {
  ID = {}, CH = {},
  WX = {}, EP = 5e-4
}

setmetatable(keymap, metaKeymap)

for iD = 1, 255 do
  metaKeymap.ID[iD] = string.char(iD)
  metaKeymap.CH[string.char(iD)] = iD
end

for k, v in pairs(wx) do
  local iD = tonumber(v)
  if(iD and (k:upper() == k)) then
    local ky = k:gsub("^[wW][xX]", "")
    if(ky:find("K_", 1, true)) then
      metaKeymap.WX[ky] = v
    end
  end
end
  
function keymap.isKey(iD, sK)
  if(not sK) then return false end
  if(metaKeymap.WX[sK]) then
    return (iD == metaKeymap.WX[sK])
  else
    return (iD == metaKeymap.CH[sK:sub(1,1)])
  end
end

function keymap.inCircle(mX, mY, cX, cY, cR)
  local mX, mY = tonumber(mX), tonumber(mY)
  if(not (mX and mY)) then return false end
  local cX = (tonumber(cX) or 0)
  local cY = (tonumber(cY) or 0)
  local cR = (tonumber(cR) or 0)
  return (((mX - cX)^2 + (mY - cY)^2) <= (cR + metaKeymap.EP))
end

return keymap
