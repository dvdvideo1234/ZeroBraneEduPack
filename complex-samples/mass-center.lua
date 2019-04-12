require("turtle")
local crt = require("chartmap")
local cmp = require("complex")
local col = require("colormap")

local v1 = cmp.getNew(5,0)
local v2 = cmp.getNew(-2,0)

local M = {10, 25}

local V0 = cmp.getNew(200,200):getCenterMass(v1,v2,M)

print("The center of mass is:", V0)