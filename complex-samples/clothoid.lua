local turtle  = require("turtle")
local complex = require("complex")
local common  = require("common")
local col     = require("colormap")
local crt     = require("chartmap")

local dX,dY = 1,1
local W , H = 800, 600
local minX, maxX = -2, 30
local minY, maxY = -2, 30
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clB = colr(col.getColorBlueRGB())
local clR = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local scOpe = crt.New("scope"):setInterval(intX, intY):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setDelta(dX, dY)

local tS = complex.getEulerSpiral(5, 50, 20)

if(tS) then
  common.logStatus("The distance between every grey line on X is: "..tostring(dX))
  common.logStatus("The distance between every grey line on Y is: "..tostring(dY))
  
  local function drawComplexLine(S, E, Cl)
    local x1 = intX:Convert(S:getReal()):getValue()
    local y1 = intY:Convert(S:getImag()):getValue()
    local x2 = intX:Convert(E:getReal()):getValue()
    local y2 = intY:Convert(E:getImag()):getValue()
    pncl(Cl); line(x1, y1, x2, y2)
  end; complex.setAction("ab", drawComplexLine)

  open("Complex Bezier curve")
  size(W,H); zero(0, 0); updt(false) -- disable auto updates

  scOpe:Draw(false, false, true, true)
  
  for iD = 1, (#tS-1) do
    tS[iD]:Action("ab", tS[iD+1], clR)
    scOpe:drawComplexPoint(tS[iD])
    updt(); wait(0.01)
  end
  
  updt()
  
  wait()
else
  common.logStatus("Your curve parameters are invalid !")
end
