-- Copyright (C) 2017-2018 Deyan Dobromirov
-- A chart mapping functionalities library

local common       = require("common")
local type         = type
local tonumber     = tonumber
local tostring     = tostring
local setmetatable = setmetatable
local math         = math
local logStatus    = common.logStatus
local isNil        = common.isNil
local chartmap     = {}

if not debug.getinfo(3) then
  print("This is a module to load with `local chartmap = require('chartmap')`.")
  os.exit(1)
end

--[[
 * newInterval: Class that maps one interval onto another
 * sName > A proper name to be identified as
 * nL1   > Lower  value first border
 * nH1   > Higher value first border
 * nL2   > Lower  value second border
 * nH2   > Higher value second border
]]--
local metaInterval = {}
      metaInterval.__index = metaInterval
      metaInterval.__type  = "chartmap.interval"
      metaInterval.__tostring = function(oInterval) return oInterval:getString() end
local function newInterval(sName, nL1, nH1, nL2, nH2)
  local self, mVal, mNm = {}, 0, tostring(sName or "")
  local mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0)
  local mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0)
  if(mL1 == mH1) then
    return logStatus("newInterval("..mNm.."): Bad input bounds", self) end
  if(mL2 == mH2) then
    return logStatus("newInterval("..mNm.."): Bad output bounds", self) end
  setmetatable(self, metaInterval)
  function self:getName() return mNm end
  function self:setName(sName) mNm = tostring(sName or "N/A") end
  function self:getValue() return mVal end
  function self:getBorderIn() return mL1, mH1 end
  function self:setBorderIn(nL1, nH1) mL1, mH1 = (tonumber(nL1) or 0), (tonumber(nH1) or 0) end
  function self:getBorderOut() return mL2, mH2 end
  function self:setBorderOut(nL2, nH2) mL2, mH2 = (tonumber(nL2) or 0), (tonumber(nH2) or 0) end
  function self:getString() return "["..metaInterval.__type.."] "..mNm.." {"..mL1..","..mH1.."} >> {"..mL2..","..mH2.."}" end
  function self:Convert(nVal, bRev)
    local val = tonumber(nVal); if(not val) then
      return logStatus("newInterval.Convert("..mNm.."): Source <"..tostring(nVal).."> NaN", self) end
    if(bRev) then local kf = ((val - mL2) / (mH2 - mL2)); mVal = (kf * (mH1 - mL1) + mL1)
    else          local kf = ((val - mL1) / (mH1 - mL1)); mVal = (kf * (mH2 - mL2) + mL2) end
    return self
  end

  return self
end

--[[
 * newTracer: Class that plots a process variable
 * sName > A proper name to be identified as
]]--
local metaTracer = {}
      metaTracer.__index = metaTracer
      metaTracer.__type  = "chartmap.tracer"
      metaTracer.__tostring = function(oTracer) return oTracer:getString() end
local function newTracer(sName)
  local self = {}; setmetatable(self, metaTracer)
  local mName = tostring(sName or "")
  local mValO, mValN = 0, 0
  local mTimO, mTimN = 0, 0
  local mPntN = {x=0,y=0}
  local mPntO = {x=0,y=0}
  local mMatX, mMatY
  local enDraw = false
  function self:getString() return "["..metaTracer.__type.."] "..mName end
  function self:getValue() return mTimN, mValN end
  function self:getChart() return mPntN.x, mPntN.y end
  function self:setInterval(oIntX, oIntY)
    mMatX, mMatY = oIntX, oIntY
    return self
  end
  function self:Reset()
    mPntN.x, mPntN.y, mPntO.x, mPntO.y = 0,0,0,0
    enDraw, mValO, mValN = false,0,0
    return self
  end
  function self:putValue(nTime, nVal)
    mValO, mValN = mValN, nVal
    mTimO, mTimN = mTimN, nTime
    mPntO.x, mPntO.y = mPntN.x, mPntN.y
    if(mMatX) then mPntN.x = mMatX:Convert(nTime):getValue()
    else mPntN.x = nTime end;
    if(mMatY) then mPntN.y = mMatY:Convert(mValN):getValue()
    else mPntN.y = mValN end; return self
  end

  function self:Draw(cCol, vSz)
    if(enDraw) then
      local nSz = (tonumber(vSz) or 2)
            nSz = (nSz < 2) and 2 or nSz
      local nsE = ((2 * nSz) + 1); pncl(cCol)
      line(mPntO.x,mPntO.y,mPntN.x,mPntN.y)
      rect(mPntO.x-nSz,mPntO.y-nSz,nsE,nsE)
    else enDraw = true end; return self
  end

  return self
end

--[[
 * CoordSys: Class that plots coordinate axises by scale
 * sName > A proper name to be identified as
]]--
local metaCoordSys = {}
      metaCoordSys.__index = metaCoordSys
      metaCoordSys.__type  = "chartmap.coordsys"
      metaCoordSys.__tostring = function(oCoordSys) return CoordSys:getString() end
local function newCoordSys(sName)
  local mName = tostring(sName or "")
  local self = {}; setmetatable(self, metaCoordSys)
  local mdX, mdY, mnW, mnH, minX, maxX, minY, maxY, midX, midY, moiX, moiY
  local mclMid, mcldXY = colr(0,0,0), colr(200,200,200)
  local mclPos, mclOrg, mclDir = colr(255,0,0), colr(0,255,0), colr(0,0,255)
  function self:setDelta(nX, nY)
    mdX, mdY = (tonumber(nX) or 0), (tonumber(nY) or 0); return self end
  function self:setBorder(nX, xX, nY, xY)
    minX, maxX = (tonumber(nX) or 0), (tonumber(xX) or 0)
    minY, maxY = (tonumber(nY) or 0), (tonumber(xY) or 0)
    if(isNil(nX) and isNil(xX) and isNil(nY) and isNil(xY)) then
      minX, maxX = moiX:getBorderIn()
      minY, maxY = moiY:getBorderIn()
      logStatus("newCoordSys.setBorder: Using intervals")
    end
    midX, midY = (minX + ((maxX - minX) / 2)), (minY + ((maxY - minY) / 2))
    return self
  end
  function self:setSize(nW, nH)
    mnW, mnH = (tonumber(nW) or 0), (tonumber(nH) or 0)
    if(isNil(nW) and isNil(nH)) then
      mnW = math.max(moiX:getBorderOut())
      mnH = math.max(moiY:getBorderOut())
      logStatus("newCoordSys.setSize: Using intervals")
    end; return self
  end
  function self:setInterval(intX, intY)
    moiX = intX; if(getmetatable(moiX) ~= metaInterval) then
      return logStatus("newCoordSys.setInterval: X object invalid", self) end
    moiY = intY; if(getmetatable(moiY) ~= metaInterval) then
      return logStatus("newCoordSys.setInterval: Y object invalid", self) end
    return self
  end
  function self:setColor(clMid, clDXY, clPos, clOrg, clDir)
    mclMid, mcldXY = (clMid or colr(0,0,0)), (clDXY or colr(200,200,200))
    mclPos = (clPos or colr(255,0,0))
    mclOrg = (clOrg or colr(0,255,0))
    mclDir = (clDir or colr(0,0,255))
    return self
  end
  function self:Draw(bMx, bMy, bGrd)
    local xe = moiX:Convert(midX):getValue()
    local ye = moiY:Convert(midY):getValue()
    if(bGrd) then local nK
      nK = 0; for x = midX, maxX, mdX do
        local xp = moiX:Convert(midX + nK * mdX):getValue()
        local xm = moiX:Convert(midX - nK * mdX):getValue()
        nK = nK + 1; if(x ~= midX) then
          pncl(mcldXY); line(xp, 0, xp, mnH); line(xm, 0, xm, mnH) end
      end
      nK = 0; for y = midY, maxY, mdY do
        local yp = moiY:Convert(midY + nK * mdY):getValue()
        local ym = moiY:Convert(midY - nK * mdY):getValue()
        nK = nK + 1; if(y ~= midY) then
          pncl(mcldXY); line(0, yp, mnW, yp); line(0, ym, mnW, ym) end
      end
    end
    if(xe and bMx) then pncl(mclMid); line(xe, 0, xe, mnH) end
    if(ye and bMy) then pncl(mclMid); line(0, ye, mnW, ye) end
    return self
  end
  function self:drawComplex(xyP, xyO, bTx)
    local ox, oy, px, py, sz = 0, 0, 0, 0, 2
    if(xyO) then ox, oy = xyO:getParts() end
    px, py = xyP:getParts()
    ox = moiX:Convert(ox):getValue()
    oy = moiY:Convert(oy):getValue()
    px = moiX:Convert(px):getValue()
    py = moiY:Convert(py):getValue()
    pncl(mclPos); rect(px-sz,py-sz,2*sz+1,2*sz+1)
    pncl(mclOrg); rect(ox-sz,oy-sz,2*sz+1,2*sz+1)
    pncl(mclDir); line(px, py, ox, oy)
    if(bTx) then pncl(mclDir);
      local nA = xyP:getSub(xyO):getAngDeg()+90
      text(tostring(xyP:getRound(0.001)),nA,px,py)
    end
    return self;
  end
  function self:getString() return "["..metaCoordSys.__type.."] "..mName end
  return self
end

function chartmap.New(sType, ...)
  local sType = "chartmap."..tostring(sType or "")
  if(sType == metaInterval.__type) then return newInterval(...) end
  if(sType == metaTracer.__type) then return newTracer(...) end
  if(sType == metaCoordSys.__type) then return newCoordSys(...) end
  return logStatus("chartmap.New: Object invalid <"..sType..">",nil)
end

return chartmap
