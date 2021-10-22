local gui = require('gui')

local root = gui.Root:new()

local box = gui.LinearContainer:new(root,2,1,1)
local box2 = gui.LinearContainer:new(root,1,0,0)

local lbl = gui.Label:new(root,"Hello!")
local btn1 = gui.Button:new(root,"Button 1")
local btn2 = gui.Button:new(root,"Button 2")
local area = gui.ListBox:new(root,10,10,{})
local sb = gui.ScrollBar:new(root,area)

for i=1,64 do
    table.insert(area.items,"Item "..tostring(i))
end
btn1.enabled = false

function btn1:onPressed()
    lbl.text = "Button pressed"
    root:onLayout() -- redraw entire screen
end
function btn2:onPressed()
    btn1.enabled = true
    btn1.dirty = true
end

root:addChild(box2)

box2:addChild(area,true,true,gui.LinearAlign.START)
box2:addChild(sb,false,true,gui.LinearAlign.START)
box2:addChild(box,false,true,gui.LinearAlign.START)

box:addChild(lbl,false,false,gui.LinearAlign.START)
box:addChild(btn1,true,false,gui.LinearAlign.START)
box:addChild(btn2,true,false,gui.LinearAlign.START)

root:mainLoop()
