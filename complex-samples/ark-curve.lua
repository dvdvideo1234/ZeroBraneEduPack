local turtle  = require("turtle")
local complex = require("complex")
local common  = require("common")
local col     = require("colormap")
local crt     = require("chartmap")

local cO = complex.getNew(3,3)
local nR = -3

local dX,dY = 1,1
local W , H = 800, 600
local minX, maxX = cO:getReal() - math.abs(2 * nR), cO:getReal() + math.abs(2 * nR)
local minY, maxY = cO:getImag() - math.abs(2 * nR), cO:getImag() + math.abs(2 * nR)
local greyLevel  = 200
local intX  = crt.New("interval","WinX", minX, maxX, 0, W)
local intY  = crt.New("interval","WinY", minY, maxY, H, 0)
local clGry = colr(greyLevel,greyLevel,greyLevel)
local clB = colr(col.getColorBlueRGB())
local clR = colr(col.getColorRedRGB())
local clBlk = colr(col.getColorBlackRGB())
local scOpe = crt.New("scope"):setInterval(intX, intY):setBorder(minX, maxX, minY, maxY)
      scOpe:setSize(W, H):setColor(clBlk, clGry):setDelta(dX, dY)

local cD, vR = complex.getNew(5,5), complex.getNew(-0.1, 0.01)
local tS, oB = complex.getCircleArc(cO, cD, nR, vR, 590, 50)

if(tS) then
  common.logStatus("The distance between every grey line on X is: "..tostring(dX))
  common.logStatus("The distance between every grey line on Y is: "..tostring(dY))
  
  local function drawComplexLine(S, E, Cl)
    if(not (S and E)) then return end 
    local x1 = intX:Convert(S:getReal()):getValue()
    local y1 = intY:Convert(S:getImag()):getValue()
    local x2 = intX:Convert(E:getReal()):getValue()
    local y2 = intY:Convert(E:getImag()):getValue()
    pncl(Cl); line(x1, y1, x2, y2)
  end; complex.setAction("ab", drawComplexLine)

  open("Complex Bezier curve")
  size(W,H); zero(0, 0); updt(false) -- disable auto updates

  scOpe:Draw(false, false, true, true)

  local x, y = oB:getParts()
  scOpe:drawCircle(x, y, nR)

  for iD = 1, #tS do
    tS[iD]:Action("ab", tS[iD+1], clR)
    scOpe:drawComplexPoint(tS[iD])
    updt(); wait(0.02)
  end
  
  wait()
else
  common.logStatus("Your curve parameters are invalid !")
end
