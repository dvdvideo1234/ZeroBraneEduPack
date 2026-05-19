local common   = require("common")
local chatbot  = require("chatbot")

local api_key = "$API_KEY"

local chat = chatbot.getNew("GROQ")
chat:setKey(api_key)
chat:setJSON("dkjson")
chat:setAPI("https://api.groq.com/openai/v1/chat/completions")
chat:Request({
  model = "llama-3.3-70b-versatile",
  messages = {{
    role = "user",
    content = "If I am born in 19 may 1988 how old am I"
  }},
  temperature = 0.7
})
chat:Response()
local tB = chat:getBody(true)
if(tB and tB.choices and tB.choices[1]) then
  common.logTable(tB.choices[1], "BODY")
end
