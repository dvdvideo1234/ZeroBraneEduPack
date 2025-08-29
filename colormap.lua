-- Copyright (C) 2017 Deyan Dobromirov
-- A color mapping functionalities library

if not debug.getinfo(3) then
  print("This is a module to load with `local colormap = require('colormap')`.")
  os.exit(1)
end

local common    = require("common")
local math      = math
local colormap  = {}
local clMapping = {}
local clClamp   = {0, 255}
local metaColormap = {
  __KEYR = {1, "r", "R", "red"  , "Red"  , "RED"  },
  __KEYG = {2, "g", "G", "green", "Green", "GREEN"},
  __KEYB = {3, "b", "B", "blue" , "Blue" , "BLUE" }
}

local logStatus       = common.logStatus
local getValueKeys    = common.getValueKeys
local stringExplode   = common.stringExplode
local getRound        = common.getRound
local isNil           = common.isNil

--[[ https://en.wikipedia.org/wiki/HSL_and_HSV ]]
local function projectColorHC(h, c)
  local hp, hc = (h / 60), (h % 360)
  local x  = c * (1 - math.abs((hp % 2) - 1))
  if(hc >=   0 and hc <  60) then return c, x , 0 end
  if(hc >=  60 and hc < 120) then return x, c , 0 end
  if(hc >= 120 and hc < 180) then return 0, c , x end
  if(hc >= 180 and hc < 240) then return 0, x , c end
  if(hc >= 240 and hc < 300) then return x, 0 , c end
  if(hc >= 300 and hc < 360) then return c, 0 , x end
  return 0, 0, 0
end

function getHueMargin(mx,dt,r,g,b)
  local mh = 0
  mh = (mx == r) and (0 + ((g - b) / dt)) or mh
  mh = (mx == g) and (2 + ((b - r) / dt)) or mh
  mh = (mx == b) and (4 + ((r - g) / dt)) or mh
  return (((mh < 0) and (mh + 360) or mh) * 60)
end

function colormap.getColorBlackRGB () return 0  ,  0,  0 end
function colormap.getColorRedRGB   () return 255,  0,  0 end
function colormap.getColorGreenRGB () return 0  ,255,  0 end
function colormap.getColorBlueRGB  () return 0  ,  0,255 end
function colormap.getColorYellowRGB() return 255,255,  0 end
function colormap.getColorCyanRGB  () return 0  ,255,255 end
function colormap.getColorMagenRGB () return 255,  0,255 end
function colormap.getColorWhiteRGB () return 255,255,255 end
function colormap.getColorBrownRGB () return 150, 75,  0 end
function colormap.getColorOrangeRGB() return 255,128,  0 end
function colormap.getColorVioletRGB() return 150,  0,230 end
function colormap.getColorPinkRGB  () return 255, 80,255 end
function colormap.getColorPadRGB(pad) return pad,pad,pad end
function colormap.getColorNewRGB(r,g,b) return r, g, b end

function colormap.getColorRotateLeft(r, g, b) return g, b, r end
function colormap.getColorRotateRigh(r, g, b) return b, r, g end

function colormap.getClamp(vN)
  local nN = tonumber(vN); if(not nN) then
    return logStatus("colormap.getClamp: NAN {"..type(nN).."}<"..tostring(nN)..">") end
  return common.getClamp(getRound(nN, 1), clClamp[1], clClamp[2])
end

function colormap.getRatioRGB(r,g,b)
  local r = r / clClamp[2]
  local g = g / clClamp[2]
  local b = b / clClamp[2]
  return r, g, b
end

function colormap.getColorXYZ(x,y,z)
  -- Convert XYZ to linear RGB
  local r =  3.2406 * x - 1.5372 * y - 0.4986 * z
  local g = -0.9689 * x + 1.8758 * y + 0.0415 * z
  local b =  0.0557 * x - 0.2040 * y + 1.0570 * z
  -- Compand linear RGB to sRGB
  local function com(c)
      c = (c <= 0.0031308) and (12.92 * c) or (1.055 * c^(1/2.4) - 0.055)
      return math.max(0, math.min(255, math.floor(c * 255 + 0.5)))
  end
  return com(r), com(g), com(b)
end

function colormap.getColorToXYZ(r,g,b)
  -- Normalize and linearize RGB
  local function lin(c)
    local c = c / 255
    return (c <= 0.04045) and (c / 12.92) or ((c + 0.055) / 1.055)^2.4
  end
  local r, g, b = lin(r), lin(g), lin(b)
  -- Convert to XYZ (D65)
  local x = r * 0.4124 + g * 0.3576 + b * 0.1805
  local y = r * 0.2126 + g * 0.7152 + b * 0.0722
  local z = r * 0.0193 + g * 0.1192 + b * 0.9505
  return x, y, z
end

function colormap.getColorHEX(hex)
  local r = tonumber(hex:sub(1,2), 16)
  local g = tonumber(hex:sub(3,4), 16)
  local b = tonumber(hex:sub(5,6), 16)
  return r, g, b
end

function colormap.getColorToHEX(r,g,b)
  local hex, fmt = "", "%X"
  hex = hex..fmt:format(tonumber(r) or 0)
  hex = hex..fmt:format(tonumber(g) or 0)
  hex = hex..fmt:format(tonumber(b) or 0)
  return hex
end

-- H [0,360], S [0,1], V [0,1]
function colormap.getColorHSV(h,s,v)
  local c = v * s
  local m = v - c
  local r, g, b = projectColorHC(h,c)
  return colormap.getClamp(clClamp[2] * (r + m)),
         colormap.getClamp(clClamp[2] * (g + m)),
         colormap.getClamp(clClamp[2] * (b + m))
end

function colormap.getColorToHSV(r,g,b)
  local r, g, b = colormap.getRatioRGB(r,g,b)
  local vn = math.min(r, g, b)
  local vx = math.max(r, g, b)
  local mm, mh = (vx - vn), 0
  local ms = (vx == 0) and 0 or (mm / vx)
  local mh = getHueMargin(vx,mm,r,g,b)
  return mh, ms, vx
end

-- H [0,360], S [0,1], L [0,1]
function colormap.getColorHSL(h,s,l)
  local c = (1 - math.abs(2*l - 1)) * s
  local m = l - 0.5*c
  local r, g, b = projectColorHC(h,c)
  return colormap.getClamp(clClamp[2] * (r + m)),
         colormap.getClamp(clClamp[2] * (g + m)),
         colormap.getClamp(clClamp[2] * (b + m))
end

function colormap.getColorToHSL(r,g,b)
  local r, g, b = colormap.getRatioRGB(r,g,b)
  local vn = math.min(r, g, b)
  local vx = math.max(r, g, b)
  local mm, ml = (vx - vn), ((vx + vn) / 2)
  local ms = (vx ~= 0) and (mm / (1-math.abs(2 * ml - 1))) or 0
  local mh = getHueMargin(vx,mm,r,g,b)
  return mh, ms, ml
end

-- H [0,360], C [0,1], L [0,1]
function colormap.getColorHCL(h,c,l)
  -- Lab from HCL
  local a = c * math.cos(math.rad(h))
  local b = c * math.sin(math.rad(h))
  -- Lab to XYZ
  local fy = (l + 16) / 116
  local fx = a / 500 + fy
  local fz = fy - b / 200
  local function inv(t)
    return (t > 0.206893) and t^3 or (t - 16/116) / 7.787 end
  local Xn, Yn, Zn = 0.95047, 1.0, 1.08883
  local x = Xn * inv(fx)
  local y = Yn * inv(fy)
  local z = Zn * inv(fz)
  return colormap.getColorXYZ(x,y,z)
end

function colormap.getColorToHCL(r,g,b)
  local x, y, z = colormap.getColorToXYZ(r,g,b)
  -- XYZ to Lab
  local function map(t)
    return (t > 0.008856) and t^(1/3) or (7.787 * t + 16/116) end
  local fx = map(x / 0.95047)
  local fy = map(y / 1.00000)
  local fz = map(z / 1.08883)
  local L = 116 * fy - 16
  local a = 500 * (fx - fy)
  local b = 200 * (fy - fz)
  -- Lab to HCL
  local C = math.sqrt(a*a + b*b)
  local H = math.deg(math.atan2(b, a)) % 360
  return H, C, L
end

-- H [0,360], W [0,1], B [0,1]
function colormap.getColorHWB(h,w,b)
  local v = 1 - b
  local s = (1 - w / v)
  return colormap.getColorHSV(h,s,v)
end

function colormap.getColorToHWB(r,g,b)
  local h, s, v = colormap.getColorToHSV(r,g,b)
  local w, b = ((1 - s) * v), (1 - v)
  return h, w, b
end

function colormap.getStringRGB(r, g, b)
  return ("{"..tostring(r)..","..tostring(g)..","..tostring(b).."}")
end

function colormap.printColorRGB(...)
  logStatus(colormap.getStringRGB(...))
end

function colormap.printColorMap(vKey, ...)
  if(isNil(vKey)) then
    return logStatus("colormap.printColorMap: Key missing") end
  local tRgb = clMapping[vKey]; if(not tRgb) then
    return logStatus("colormap.printColorMap: Mapping missing ["..tostring(vKey).."]") end
  local tyRgb = type(tRgb); if(tyRgb ~= "table") then
    return logStatus("colormap.printColorMap: Internal structure is ["..tyRgb.."]<"..tostring(tRgb)..">") end
  local nRgb = #tRgb; if(nRgb == 0) then
    return logStatus("colormap.printColorMap: Mapping empty ["..tostring(tRgb).."]") end
  local fRgb, nSiz, vMis = "%"..tostring(nRgb):len().."d", tRgb.Size, tRgb.Miss
  vMis = ((vMis and type(vMis) == "table") and colormap.getStringRGB(unpack(vMis)) or "N/A")
  logStatus("Colormap ["..tostring(vKey).."]["..tostring(nSiz).."]: "..tostring(vMis))
  for ID = 1, nRgb do local tRow = tRgb[ID]
    local tyRow = type(tRow); if(tyRow == "table") then
      logStatus(fRgb:format(ID)..": "..colormap.getStringRGB(unpack(tRow)))
    else logStatus(fRgb:format(ID)..": ["..tyRow.."]<"..tostring(tRow)..">") end
  end
end

function colormap.setColorMap(vKey,tTable,bReplace)
  if(isNil(vKey)) then
    return logStatus("colormap.setColorMaps: Key missing") end
  local tyTable = type(tTable); if(tyTable ~= "table") then
    return logStatus("colormap.setColorMap: Missing table argument",nil) end
  local tRgb = clMapping[vKey]; if(tRgb and not bReplace) then
    return logStatus("colormap.setColorMap: Exists mapping for <"..tostring(vKey)..">",nil) end
  clMapping[vKey] = tTable; if(not tTable.Size) then tTable.Size = #tTable end
  return clMapping[vKey]
end

function colormap.getColorMap(vKey, iNdex)
  if(isNil(vKey)) then
    return logStatus("colormap.getColorMap: Key missing") end
  if(isNil(iNdex)) then return clMapping[vKey] end
  local iNdex, tCl = (tonumber(iNdex) or 0)
  local tRgb = clMapping[vKey]; if(not tRgb) then
    logStatus("colormap.getColorMap: Missing mapping for <"..tostring(vKey)..">")
    return colormap.getColorBlackRGB() -- Not mapped then return black
  end; local cID = (iNdex % tRgb.Size + 1); tCl = tRgb[cID]
  if(not tCl) then tCl = tRgb.Miss end
  if(not tCl) then return colormap.getColorBlackRGB() end
  return colormap.getClamp(tCl[1]), colormap.getClamp(tCl[2]), colormap.getClamp(tCl[3])
end

function colormap.getColorMapGradient(tMap, nStp)
  local tPal, nS, iP, nT = {}, (tonumber(nStp) or 0), 0, #tMap; if(nS <= 0) then
    return logStatus("colormap.getColorMapGradient: Mismatch <"..tostring(nStp)..">", nil) end
  for iD = 1, (#tMap-1) do iP = iP + 1; tPal[iP] = {}
    local dr = (tMap[iD+1][1]-tMap[iD][1]) / (nS + 1)
    local dg = (tMap[iD+1][2]-tMap[iD][2]) / (nS + 1)
    local db = (tMap[iD+1][3]-tMap[iD][3]) / (nS + 1)
    tPal[iP][1] = colormap.getClamp(tMap[iD][1])
    tPal[iP][2] = colormap.getClamp(tMap[iD][2])
    tPal[iP][3] = colormap.getClamp(tMap[iD][3])
    for iK = 1, nS do iP = iP + 1; tPal[iP] = {}
      tPal[iP][1] = colormap.getClamp(tPal[iP-1][1]+dr)
      tPal[iP][2] = colormap.getClamp(tPal[iP-1][2]+dg)
      tPal[iP][3] = colormap.getClamp(tPal[iP-1][3]+db)
    end
  end; iP = iP + 1; tPal[iP] = {}
  tPal[iP][1] = colormap.getClamp(tMap[nT][1])
  tPal[iP][2] = colormap.getClamp(tMap[nT][2])
  tPal[iP][3] = colormap.getClamp(tMap[nT][3])
  return tPal
end

--[[
  Colormap for fiery-red-yellow
  https://a4.pbase.com/o6/09/60809/1/79579853.u4uTlB2w.Elephantvalleyhistogramcolors.JPG
]]--
function colormap.getColorRegion(iDepth, maxDepth, iRegions)
  local sKey, iDepth = "getColorRegion", (tonumber(iDepth) or 0); if(iDepth <= 0) then
    logStatus("colormap.getColorRegion: Missing Region depth #"..iDepth,colormap.getColorBlackRGB()) end
  local maxDepth = (tonumber(maxDepth) or 0); if(maxDepth <= 0) then
    logStatus("colormap.getColorRegion: Missing Region max depth #"..maxDepth,colormap.getColorBlackRGB()) end
  local iRegions = (tonumber(iRegions) or 0); if(iRegions <= 0) then
    logStatus("colormap.getColorRegion: Missing Regions count #"..iRegions,colormap.getColorBlackRGB()) end
  if (iDepth == maxDepth) then return colormap.getColorBlackRGB() end
  -- Cache the damn thing as it is too heavy
  if(not clMapping[sKey]) then clMapping[sKey] = {} end
  if(not clMapping[sKey][iRegions]) then clMapping[sKey][iRegions] = {} end
  local arRegions = clMapping[sKey][iRegions][maxDepth]
  if(not arRegions) then
    clMapping[sKey][iRegions][maxDepth] = {{brd = (maxDepth / iRegions), foo = function(iTer) return iTer * 2, 0, 0 end}}
    local oneThird = math.ceil(0.33 * iRegions); arRegions = clMapping[sKey][iRegions][maxDepth]
    for regid = 2,iRegions do
      arRegions[regid] = {}
      arRegions[regid].brd = arRegions[regid - 1].brd + arRegions[1].brd
      if(regid <= oneThird and regid > 1) then
        arRegions[regid].foo = function(iTer)
          return colormap.getClamp((((iTer - arRegions[regid-1].brd) * arRegions[oneThird-regid+1].brd)
                 * arRegions[2].brd) + arRegions[2].brd), 0, 0
        end
      else
        arRegions[regid].foo = function(iTer)
          return clClamp[2], colormap.getClamp((((iTer - arRegions[regid-1].brd) * arRegions[1].brd)
                 / arRegions[regid-2].brd) + arRegions[regid-3].brd), clClamp[1]
        end
      end
    end
  end
  local lowBorder = 1
  for regid = 1, iRegions do
    local uppBorder = arRegions[regid].brd
    if(iDepth >= lowBorder and iDepth < uppBorder) then
      return arRegions[regid].foo(iDepth)
    end; lowBorder = arRegions[regid].brd
  end
end

function colormap.getColorComplexDomain(fF, vC, nA, bI)
  local bS, vF = pcall(fF, vC) -- Try dedicated call
  if(bS) then local mT = getmetatable(vF)
    if(mT and mT.__type == "complex.complex") then
      local nA = common.getClamp(tonumber(nA) or 0.5, 0, 1)
      local nM, nP = vF:getPolar() -- Read norm and phase
      local hslH = math.deg(nP) -- HSL needs degrees
            hslH = ((hslH < 0) and (hslH + 360) or hslH)
      local hslS, hslL = 1, (1 - nA ^ nM) -- Interpolate SL
      local r, g, b = colormap.getColorHSL(hslH, hslS, hslL)
      if(vF:isNan()) then -- Interpolate RGB as up-down-left-right
        if(bI) then -- Recursive interpolation is enabled
          local nD, nX, nY = common.getMargin(), vC:getParts()
          local vC1, vC2 = vC:getNew(nX-nD, nY), vC:getNew(nX+nD, nY)
          local vC3, vC4 = vC:getNew(nX, nY-nD), vC:getNew(nX, nY+nD)
          local r1, g1, b1 = colormap.getColorComplexDomain(fF, vC1, nA)
          local r2, g2, b2 = colormap.getColorComplexDomain(fF, vC2, nA)
          local r3, g3, b3 = colormap.getColorComplexDomain(fF, vC3, nA)
          local r4, g4, b4 = colormap.getColorComplexDomain(fF, vC4, nA)
          r = math.floor((r1 + r2 + r3 + r4) / 4) -- Average red   (R)
          g = math.floor((g1 + g2 + g3 + g4) / 4) -- Average green (G)
          b = math.floor((b1 + b2 + b3 + b4) / 4) -- Average blue  (B)
          return r, g, b, true
        else -- Return black to prevent stack overflow
          return clClamp[1], clClamp[1], clClamp[1], true
        end
      end
      return r, g, b, true
    else
      logStatus("colormap.getColorComplexDomain: Complex: "..tostring(vF))
      return clClamp[1], clClamp[1], clClamp[1], false -- If our complex is crap, return black
    end
  else
    logStatus("colormap.getColorComplexDomain: Error: "..tostring(vF))
    return clClamp[1], clClamp[1], clClamp[1], false -- If our function fails, return black
  end
end

local function tableToColorRGB(tTab, kR, kG, kB)
  if(not tTab) then return nil end
  local cR = tonumber(getValueKeys(tTab, metaColormap.__KEYR, kR))
  local cG = tonumber(getValueKeys(tTab, metaColormap.__KEYG, kG))
  local cB = tonumber(getValueKeys(tTab, metaColormap.__KEYB, kB))
  return colormap.getClamp(cR or clClamp[1]),
         colormap.getClamp(cG or clClamp[1]),
         colormap.getClamp(cB or clClamp[1])
end

function colormap.cnvColorRGB(aIn, ...)
  local tArg, tyIn, cR, cG, cB = {...}, type(aIn)
  if(tyIn == "boolean") then
    cR = (aIn     and clClamp[2] or clClamp[1])
    cG = (tArg[1] and clClamp[2] or clClamp[1])
    cB = (tArg[2] and clClamp[2] or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "string") then
    local sDe = (tArg[1] and tostring(tArg[1]) or ",")
    local tCol = stringExplode(aIn,sDe)
    cR = colormap.getClamp(tonumber(tCol[1]) or clClamp[1])
    cG = colormap.getClamp(tonumber(tCol[2]) or clClamp[1])
    cB = colormap.getClamp(tonumber(tCol[3]) or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "number") then
    cR = colormap.getClamp(tonumber(aIn    ) or clClamp[1])
    cG = colormap.getClamp(tonumber(tArg[1]) or clClamp[1])
    cB = colormap.getClamp(tonumber(tArg[2]) or clClamp[1]); return cR, cG, cB
  elseif(tyIn == "table") then return tableToColorRGB(aIn, tArg[1], tArg[2], tArg[3]) end
  return logStatus("colormap.cnvColorRGB: Type <"..tyIn.."> not supported",nil)
end

return colormap
