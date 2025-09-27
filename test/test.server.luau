local start = os.clock()
local class = require(script.Parent.object.class)
print("Loaded class module in", os.clock() - start, "seconds")

local start = os.clock()
class.register("dev.tort", script.Parent.OOP)
print("Registered classes in", os.clock() - start, "seconds")

local start = os.clock()
class.init()
print("Started class sequence in", os.clock() - start, "seconds")
