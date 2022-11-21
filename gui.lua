-- gui.lua: GUI toolkit for ComputerCraft

local Constants = require "gui.Constants"
local Object = require "gui.Object"
local Widget = require "gui.Widget"
local Container = require "gui.Container"
local Root = require "gui.Root"
local LinearContainer = require "gui.LinearContainer"
local Label = require "gui.Label"
local Button = require "gui.Button"
local TextField = require "gui.TextField"
local TextArea = require "gui.TextArea"
local ScrollWidget = require "gui.ScrollWidget"
local ListBox = require "gui.ListBox"
local ScrollBar = require "gui.ScrollBar"

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
