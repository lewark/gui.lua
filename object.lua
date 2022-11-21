local expect = require "cc.expect"

-- Call new() to create an instance of any class.
-- It will call the class's init() with the provided arguments.
local function new(self, ...)
    local instance = setmetatable({},{__index=self})
    instance.class = self
    instance:init(...)
    return instance
end

-- Implements basic inheritance features.
local Object = {}

setmetatable(Object, {__call=new})

-- Call subclass() to create a subclass of an existing class.
function Object:subclass()
    return setmetatable({superClass=self},{__index=self,__call=new})
end

-- Returns true if the Object is an instance of the provided class or a subclass.
function Object:instanceof(class)
    expect(1, class, "table")
    local c = self.class
    while c ~= nil do
        if c == class then
            return true
        end
        c = c.superClass
    end
    return false
end

-- The object's constructor. Override this method to initialize an Object subclass.
-- To create an instance of an object, use Object(args), which will then call this constructor method to set up the instance.
-- An object's init() method may also call its super class's init() if desired (use ClassName.superClass.init(self,...))
function Object:init(...) end

return Object