local expect = require "cc.expect"

-- OBJECT CLASS
-- Implements basic inheritance features.

local Object = {}

-- Call new() to create an instance of any class.
-- Do not override this method. It will call the class's init() for you.
function Object:new(...)
    local instance = setmetatable({},{__index=self})
    instance.class = self
    instance:init(...)
    return instance
end

-- Call subclass() to create a subclass of an existing class.
function Object:subclass()
    return setmetatable({superClass=self},{__index=self})
end

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
-- init() parameters will be passed in from new().
-- An object's init() may also call its super class's init() if desired.
--   Use ClassName.superClass.init(self,...)
-- This method should only be called from within new() or a subclass's init().
function Object:init(...) end