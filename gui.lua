-- gui.lua: GUI toolkit for ComputerCraft

local Constants = require "Constants"
local Object = require "Object"
local Widget = require "Widget"
local Container = require "Container"
local Root = require "Root"
local LinearContainer = require "LinearContainer"
local Label = require "Label"
local Button = require "Button"
local TextField = require "TextField"
local TextArea = require "TextArea"
local ScrollWidget = require "ScrollWidget"
local ListBox = require "ListBox"
local ScrollBar = require "ScrollBar"

-- TODO:
-- Add BoxContainer, CheckBox, ComboBox, Slider,
--     ScrollContainer, Image, TabContainer, MenuBar

-- TODO: Improve this interface

return {
    SpecialChars=Constants.SpecialChars,
    LinearAxis=Constants.LinearAxis,
    LinearAlign=Constants.LinearAlign,
    Object=Object,
    Widget=Widget,
    Container=Container,
    Root=Root,
    LinearContainer=LinearContainer,
    Label=Label,Button=Button,
    TextField=TextField,
    TextArea=TextArea,
    ScrollWidget=ScrollWidget,
    ListBox=ListBox,
    ScrollBar=ScrollBar
}
