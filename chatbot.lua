-- Copyright (C) 2025 Deyan Dobromirov
-- A chatbot interface library

if not debug.getinfo(3) then
  print("This is a module to load with `local chatbot = require('chatbot')`.")
  os.exit(1)
end

local common        = require("common")
local https         = require("ssl.https")
local http          = require("socket.http")
local ltn12         = require("ltn12")
local chatbot       = {}
local metaChatbot   = {}
metaChatbot.__type  = "chatbot.chatbot"
metaChatbot.__index = metaChatbot
metaChatbot.__envky = "CHATBOT_API_KEY"
metaChatbot.__erkey = "error"
metaChatbot.__envvr = "$"
metaChatbot.__noava = "N/A"

function chatbot.isValid(cO)
  return (getmetatable(cO) == metaChatbot)
end

function chatbot.getType(cO)
  if(not cO) then return metaChatbot.__type end
  local tM = getmetatable(cO)
  return ((tM and tM.__type) and tostring(tM.__type) or type(cO))
end

function chatbot.getNew(sB)
  local self = {}; setmetatable(self, metaChatbot)
  local JSON, URL, KEY, RPM = nil, "", "", {0, 0, 0}
  local NAM = tostring(sB or metaChatbot.__noava)
  local REQEST, RESPONSE = nil, {P = {}, B = {}}
  function self:setJSON(sN) JSON = require(tostring(sN)); return self end
  ----- KEY -----
  function self:getKey() return KEY end
  function self:setKey(...)
    local tK, iK = {...}, 1
    local envvr = metaChatbot.__envvr
    local envky = metaChatbot.__envky
    while(tK[iK]) do
      KEY = tostring(tK[iK] or "")
      if(KEY ~= "") then -- Key parameter is not empty
        if(KEY:sub(1, 1) == envvr) then -- Stored in the ENV
          KEY = (os.getenv(KEY:sub(2, -1)) or "") -- Read custom variable
        end -- In case the key is in the varargs
      end; iK = iK + 1 -- Process parameters one by one
    end; KEY = ((KEY ~= "") and KEY or os.getenv(envky))
    return self -- Make it code effective
  end
  ----- NAME -----
  function self:getName() return NAM end
  function self:setName(sN)
    local noava = metaChatbot.__noava
    NAM = tostring(sN or NAM); return self
  end
  ----- API -----
  function self:getAPI() return URL end
  function self:setAPI(sU)
    URL = tostring(sU or ""); return self
  end
  ----- TIMER -----
  function self:getTimer(cC)
    local cC = tostring(cC or ""):sub(1,1)
    if(cC == "") then return unpack(RPM) end
    return "{"..table.concat(RPM, cC).."}"
  end
  function self:setTimer(iR, nT)
    RPM[1] = math.max((tonumber(iR) or 0), 0)
    RPM[2] = 0 -- Start at zero requests
    RPM[3] = (tonumber(nT) or 60)
    RPM[4] =  (os.clock() + RPM[3]) -- Next
    return self
  end
  function self:isTimer()
    if(RPM[1] > 0) then
      if(os.clock() <= RPM[3]) then
        if(RPM[2] < RPM[1]) then
          return true
        else
          return false
        end
      else
        self:setTimer(RPM[1], RPM[3])
        return true
      end
    end; return true
  end
  ----- General -----
  function self:getResult() return RESPONSE.R end
  function self:getStatus() return RESPONSE.S end
  function self:getHeader() return RESPONSE.H end
  function self:getBody(bJ) return (bJ and RESPONSE.J or RESPONSE.B) end
  function self:Dump()
    common.logTable(REQEST  , "REQUEST")
    common.logTable(RESPONSE, "RESPONCE")
    return self
  end
  function self:isValid()
    if(not URL) then return common.logStatus("API url not provided!", false) end
    if(not KEY) then return common.logStatus("API key not provided!", false) end
    if(not JSON) then return common.logStatus("JSON library not provided!", false) end
    return true
  end
  function self:Request(tR)
    if(not self:isTimer()) then
      common.logStatus("Timer mismatch {"..RPM[1].."|"..RPM[2].."|"..RPM[3].."}")
      return self
    end
    REQEST = {R = tR, J = JSON.encode(tR)}
    return self
  end
  function self:Response(tR, bM)
    if(RPM[1] > 0) then RPM[2] = RPM[2] + 1 end
    if(not bM) then
      common.tableDry(RESPONSE.B)
    end
    RESPONSE.P = {
      url = URL, method = "POST",
      headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer "..KEY,
        ["Content-Length"]  = tostring(REQEST.J:len())
      },
      source = ltn12.source.string(REQEST.J),
      sink = ltn12.sink.table(RESPONSE.B)
    } -- Result status and header
    common.tableMerge(RESPONSE.P, tR)
    RESPONSE.R, RESPONSE.S, RESPONSE.H = https.request(RESPONSE.P)
    RESPONSE.J = JSON.decode(table.concat(RESPONSE.B))
    return self
  end
  function self:Error(sM, bP, sK)
    local tE = RESPONSE.J
    local sE = metaChatbot.__erkey
    if(not tE) then return nil end
    local tE = tE[sK or sE]
    if(not tE) then return nil end
    if(not bP) then return tE else
      common.logStatus("Error: "..tostring(sM))
      local tK = common.getKeys(tE); table.sort(tE)
      for iK = 1, #tK do
        local s = tK[iK]
        local k, v = s, tE[s]
        common.logStatus("  ["..k.."]: "..tostring(v))
      end
    end; return nil
  end
  return self
end

function metaChatbot.__tostring(oB)
  local n, u =  oB:getName(), oB:getAPI()
        n, u = tostring(n), tostring(u)
  return "["..metaChatbot.__type.."]["..n.."]["..u.."]"
end

return chatbot
