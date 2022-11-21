local expect = require "cc.expect"
local Widget = require "Widget"

-- A label. Can display custom text.
local Label = Widget:subclass()

-- Label constructor.
--
-- Parameters:
-- - root (Root): The root widget
-- - axis (string): Text to display on the Label.
function Label:init(root,text)
    expect(1, root, "table")
    expect(2, text, "string")
    Label.superClass.init(self,root)
    self.text = text
    self.backgroundColor = colors.lightGray
    self.textColor = colors.black
    self.length = 0
end

function Label:render()
    if self.size[2] > 0 then
        term.setBackgroundColor(self.backgroundColor)
        term.setTextColor(self.textColor)
        term.setCursorPos(self.pos[1],self.pos[2])
        term.write(string.sub(self.text,1,math.min(#self.text,self.size[1])))
    end
end

function Label:getPreferredSize()
    if self.length > 0 then
        return {self.length,1}
    else
        return {#self.text,1}
    end
end

return Label
