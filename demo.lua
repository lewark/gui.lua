local Root = require 'gui.Root'
local LinearContainer = require 'gui.LinearContainer'
local Label = require 'gui.Label'
local Button = require 'gui.Button'
local TextField = require 'gui.TextField'
local ListBox = require 'gui.ListBox'
local ScrollBar = require 'gui.ScrollBar'
local Constants = require 'gui.Constants'

local root = Root()

local box = LinearContainer(root,Constants.LinearAxis.VERTICAL,1,1)
local box2 = LinearContainer(root,Constants.LinearAxis.HORIZONTAL,0,0)

local lbl = Label(root,"Hello!")
local btn1 = Button(root,"Button 1")
local btn2 = Button(root,"Button 2")
local btn3 = Button(root,"Big Btn.")
local field = TextField(root,5,"TextField")
local area = ListBox(root,10,10,{})
local sb = ScrollBar(root,area)

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

box2:addChild(area,true,true,Constants.LinearAlign.START)
box2:addChild(sb,false,true,Constants.LinearAlign.START)
box2:addChild(box,false,true,Constants.LinearAlign.START)

box:addChild(lbl,false,false,Constants.LinearAlign.START)
box:addChild(btn1,false,false,Constants.LinearAlign.START)
box:addChild(btn2,false,false,Constants.LinearAlign.START)
box:addChild(field,false,true,Constants.LinearAlign.START)
box:addChild(btn3,true,true,Constants.LinearAlign.START)

root:mainLoop()
