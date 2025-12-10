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

function chatbot.isValid(cO)
  return (getmetatable(cO) == metaChatbot)
end

function chatbot.getType(cO)
  if(not cO) then return metaChatbot.__type end
  local tM = getmetatable(cO)
  return ((tM and tM.__type) and tostring(tM.__type) or type(cO))
end

function chatbot.getNew()
  local self = {}; setmetatable(self, metaChatbot)
  local JSON, URL, KEY = nil, "", ""
  local reqest, response = nil, {P = {}, B = {}}
  function self:JSON(sN) JSON = require(tostring(sN)) end
  function self:getAPI() return URL, KEY end
  function self:getResult() return response.R end
  function self:getStatus() return response.S end
  function self:getHeader() return response.H end
  function self:getBody(bJ) return (bJ and response.J or response.B) end
  function self:Dump()
    common.logTable(reqest  , "REQUEST")
    common.logTable(response, "RESPONCE")
  end
  function self:Remote(sU, sK)
    local evr = metaChatbot.__envvr
    local evk = metaChatbot.__envky
    URL, KEY = tostring(sU or ""), tostring(sK or "")
    if(KEY:sub(1, 2) == evr[1] and KEY:sub(-1, -1) == evr[2]) then
      KEY = os.getenv(KEY:sub(3, -2)) else
      KEY = ((KEY:len() > 0) and KEY or os.getenv(evk))
    end; return self
  end
  function self:Request(tR)
    reqest = {R = tS, J = JSON.encode(tR)}
    return reqest
  end
  function self:Response(tR)
    common.tableDry(response.B)
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
  local u = tostring(oB:getAPI())
  return "["..metaChatbot.__type.."]["..u.."]"
end

return chatbot
