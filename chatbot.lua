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
metaChatbot.__envvr = {"${", "}"}
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
  local JSON, URL, KEY = nil, "", ""
  local NAM = tostring(sB or metaChatbot.__noava)
  local reqest, response = nil, {P = {}, B = {}}
  function self:setJSON(sN) JSON = require(tostring(sN)); return self end
  ----- KEY -----
  function self:getKey() return KEY end
  function self:setKey(sK)
    local envvr = metaChatbot.__envvr
    local envky = metaChatbot.__envky
    KEY = tostring(sK or "")
    if(KEY:sub(1, 2) == envvr[1] and KEY:sub(-1, -1) == envvr[2]) then
      KEY = os.getenv(KEY:sub(3, -2)) -- Read custom variable
    else -- Use provided or default variabe
      KEY = ((KEY:len() > 0) and KEY or os.getenv(envky))
    end; return self
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
  ----- General -----
  function self:getResult() return response.R end
  function self:getStatus() return response.S end
  function self:getHeader() return response.H end
  function self:getBody(bJ) return (bJ and response.J or response.B) end
  function self:Dump()
    common.logTable(reqest  , "REQUEST")
    common.logTable(response, "RESPONCE")
    return self
  end
  function self:Request(tR)
    reqest = {R = tR, J = JSON.encode(tR)}
    return reqest
  end
  function self:Response(tR, bM)
    if(not bM) then
      common.tableDry(response.B)
    end
    response.P = {
      url = URL, method = "POST",
      headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer "..KEY,
        ["Content-Length"]  = tostring(reqest.J:len())
      },
      source = ltn12.source.string(reqest.J),
      sink = ltn12.sink.table(response.B)
    } -- Result status and header
    common.tableMerge(response.P, tR)
    response.R, response.S, response.H = https.request(response.P)
    response.J = JSON.decode(table.concat(response.B))
    return response
  end
  return self
end

function metaChatbot.__tostring(oB)
  local n, u =  oB:getName(), oB:getAPI()
        n, u = tostring(n), tostring(u)
  return "["..metaChatbot.__type.."]["..n.."]["..u.."]"
end

return chatbot
