local gui = require('gui')

local root = gui.Root()

local box = gui.LinearContainer(root,gui.LinearAxis.VERTICAL,1,1)
local box2 = gui.LinearContainer(root,gui.LinearAxis.HORIZONTAL,0,0)

local lbl = gui.Label(root,"Hello!")
local btn1 = gui.Button(root,"Button 1")
local btn2 = gui.Button(root,"Button 2")
local btn3 = gui.Button(root,"Big Btn.")
local field = gui.TextField(root,5,"TextField")
local area = gui.ListBox(root,10,10,{})
local sb = gui.ScrollBar(root,area)

for i=1,64 do
    table.insert(area.items,"Item "..tostring(i))
end
btn1.enabled = false

function btn1:onPressed()
    lbl.text = "Pressed"
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
box:addChild(btn1,false,false,gui.LinearAlign.START)
box:addChild(btn2,false,false,gui.LinearAlign.START)
box:addChild(field,false,true,gui.LinearAlign.START)
box:addChild(btn3,true,true,gui.LinearAlign.START)

root:mainLoop()
