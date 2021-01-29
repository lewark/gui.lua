-- gui.lua

local mouse_events = {"mouse_click","mouse_up","mouse_scroll","mouse_drag"}
local keybd_events = {"char","key","key_up","paste"}

local LinearAlign = {CENTER=0,START=1,END=2}
local BoxAlign = {CENTER=0,TOP=1,BOTTOM=2,LEFT=3,RIGHT=4}

local function startswith(str,substr)
	return string.sub(str,1,#substr) == substr
end

local function contains(tbl,val)
	for k,v in pairs(tbl) do
		if v == val then return true end
	end
	return false
end

-- OBJECT CLASS
-- Implements basic inheritance features

local Object = {}

function Object:new(...)
	local instance = setmetatable({},{__index=self})
	instance.class = self
	instance:constructor(...)
	return instance
end

function Object:subclass()
	return setmetatable({superClass=self},{__index=self})
end

--function Object:super(...)
--	return self.superClass.constructor(self, ...)
--end

function Object:instanceof(class)
	local c = self.class
	while c ~= nil do
		if c == class then
			return true
		end
		c = c.superClass
	end
	return false
end

function Object:constructor(...) end

-- WIDGET CLASSES

local Widget = Object:subclass()

function Widget:constructor(root)
	self.size = {0,0}
	self.pos = {1,1}
	self.layout = {}
	self.dirty = true
	self.parent = nil
	self.root = root
end

function Widget:contains_point(x,y)
	return (
		x >= self.pos[1] and 
		x < self.pos[1]+self.size[1] and 
		y >= self.pos[2] and 
		y < self.pos[2]+self.size[2]
	)
end

function Widget:on_redraw()
	if self.dirty then
		self:render()
		self.dirty = false
	end
end

function Widget:on_layout()
	self.dirty = true
end

function Widget:get_preferred_size()
	return {0, 0}
end

function Widget:render() end

function Widget:on_key_down(key,held) end
function Widget:on_key_up(key) end
function Widget:on_char(chr) end
function Widget:on_paste(text) end
function Widget:on_mouse_down(btn,x,y) end
function Widget:on_mouse_up(btn,x,y) end
function Widget:on_mouse_scroll(dir,x,y) end
function Widget:on_mouse_drag(btn,x,y) end
function Widget:on_focus(focused) end

function Widget:on_event(evt)
	if contains(mouse_events,evt[1]) then
		if (not self.root) or (self.root.focus == self) then
			if evt[1] == "mouse_drag" then
				self:on_mouse_drag(evt[2],evt[3],evt[4])
			elseif evt[1] == "mouse_up" then
				self:on_mouse_up(evt[2],evt[3],evt[4])
			end
		end
		
		if not self:contains_point(evt[3],evt[4]) then
			return
		end
		
		if evt[1] == "mouse_click" then
			if self.root then
				self.root.focus = self
			end
			self:on_mouse_down(evt[2],evt[3],evt[4])
		elseif evt[1] == "mouse_scroll" then
			self:on_mouse_scroll(evt[2],evt[3],evt[4])
		end
	elseif (not self.root) or ((self.root.focus == self) and contains(keybd_events,evt[1])) then
		if evt[1] == "char" then
			self:on_char(evt[2])
		elseif evt[1] == "key" then
			self:on_key_down(evt[2],evt[3])
		elseif evt[1] == "key_up" then
			self:on_key_up(evt[2])
		elseif evt[1] == "paste" then
			self:on_paste(evt[2])
		end
	end
end

-- CONTAINER CLASSES

local Container = Widget:subclass()

function Container:constructor(root)
	Container.superClass.constructor(self,root)
	self.children = {}
end

function Container:add_child(child,...)
	table.insert(self.children,child)
end

function Container:on_redraw()
	Container.superClass.on_redraw(self)
	for _,widget in pairs(self.children) do
		widget:on_redraw()
	end
end

function Container:on_event(evt)
	Container.superClass.on_event(self,evt)
	for _,widget in pairs(self.children) do
		widget:on_event(evt)
	end
end

function Container:on_layout()
	Container.superClass.on_layout(self)
	self:layout_children()
	for _,widget in pairs(self.children) do
		widget:on_layout()
	end
end

function Container:layout_children() end


local Root = Container:subclass()

function Root:constructor()
	Root.superClass.constructor(self,nil)
	self.focus = nil
	self.size = {term.getSize()}
end

function Root:on_event(evt)
	local focus = self.focus
	Root.superClass.on_event(self,evt)
	if evt[1] == "term_resize" then
		self.size = {term.getSize()}
		self:on_layout()
	end
	if self.focus ~= focus then
		if focus then
			focus:on_focus(false)
		end
		if self.focus then
			self.focus:on_focus(true)
		end
	end
	self:on_redraw()
end

function Root:layout_children()
	for _,widget in pairs(self.children) do
		widget.pos = {1,1}
		widget.size = {self.size[1],self.size[2]}
	end
end

function Root:render()
	term.setBackgroundColor(colors.lightGray)
	term.clear()
end

local LinearContainer = Container:subclass()

function LinearContainer:constructor(root,axis,spacing)
	LinearContainer.superClass.constructor(self,root)
	self.axis = axis
	self.spacing = spacing
end

function LinearContainer:add_child(child,fill_major,fill_minor,align)
	LinearContainer.superClass.add_child(self,child)
	child.layout.fill_major = fill_major
	child.layout.fill_minor = fill_minor
	child.layout.align = align
end

function LinearContainer:get_minor_axis()
	if self.axis == 1 then
		return 2
	end
	return 1
end

function LinearContainer:get_preferred_size()
	local axis2 = self:get_minor_axis()
	
	local pref_size = {0,0}
	for i=1,#self.children do
		local child = self.children[i]
		local c_pref_size = child:get_preferred_size()
		pref_size[axis2] = math.max(pref_size[axis2],c_pref_size[axis2])
		pref_size[self.axis] = pref_size[self.axis] + c_pref_size[self.axis]
		if i ~= #self.children then
			pref_size[self.axis] = pref_size[self.axis] + self.spacing
		end
	end
	
	return pref_size
end

function LinearContainer:layout_children()
	local axis2 = self:get_minor_axis()
	
	local space_free = self.size[self.axis]
	local children_fill = 0
	local preferred_sizes = {}
	
	for i=1,#self.children do
		local child = self.children[i]
		local pref_size = child:get_preferred_size()
		table.insert(preferred_sizes, pref_size)
		
		if child.layout.fill_major then
			children_fill = children_fill + 1
		else
			space_free = space_free - pref_size[self.axis]
		end
		if i ~= #self.children then
			space_free = space_free - self.spacing
		end
	end
	
	local current_pos = self.pos[self.axis]
	local fill_count = 0
	
	for i=1,#self.children do
		local child = self.children[i]
		local size = 0
		local pref_size = preferred_sizes[i]
		
		if child.layout.fill_major then
			fill_count = fill_count + 1
			-- TODO: fix rounding errors
			size = math.max((math.floor(space_free * fill_count / children_fill)
				- math.floor(space_free * (fill_count-1) / children_fill)),0)
		else
			size = pref_size[self.axis]
		end
		
		child.pos[self.axis] = current_pos
		child.size[self.axis] = size
		
		if child.layout.fill_minor then
			child.size[axis2] = self.size[axis2]
		else
			child.size[axis2] = math.min(pref_size[axis2],self.size[axis2])
		end
		
		if child.layout.align == LinearAlign.CENTER then
			child.pos[axis2] = self.pos[axis2]+math.floor((self.size[axis2]-child.size[axis2])/2)
		elseif child.layout.align == LinearAlign.START then
			child.pos[axis2] = self.pos[axis2]
		elseif child.layout.align == LinearAlign.END then
			child.pos[axis2] = self.pos[axis2]+self.size[axis2]-child.size[axis2]
		end
		
		current_pos = current_pos + size + self.spacing
	end
end

-- INTERACTIVE WIDGET CLASSES

local Button = Widget:subclass()

function Button:constructor(root,text)
	Button.superClass.constructor(self,root)
	self.text = text
	self.color = colors.blue
	self.pushedColor = colors.cyan
end

function Button:get_preferred_size()
	return {#self.text+2,1}
end

function Button:render()
	--getSuper(Button).render(self)
	if self.root.focus == self then
		term.setBackgroundColor(self.pushedColor)
	else
		term.setBackgroundColor(self.color)
	end
	term.setTextColor(colors.white)
	local myX,myY = self.pos[1], self.pos[2]
	
	for y=1,self.size[2] do
		term.setCursorPos(myX,myY+y-1)
		term.write(string.rep(" ",self.size[1]))
	end
	
	if self.size[2] > 0 then
		local text_x = myX + math.max(math.floor((self.size[1]-#self.text)/2),0)
		local text_y = myY + math.max(math.floor(self.size[2]/2),0)
		term.setCursorPos(text_x,text_y)
		term.write(string.sub(self.text,1,math.min(#self.text,self.size[1])))
	end
end

function Button:on_focus(focused)
	self.dirty = true
end

local root = Root:new()
local box = LinearContainer:new(root,2,1)
local box2 = LinearContainer:new(root,1,1)
local btn = Button:new(root,"Hello!")
local btn2 = Button:new(root,"Button 2")
local btn3 = Button:new(root,"Btn 3")
local btn4 = Button:new(root,"Btn 4")

root:add_child(box2)
box2:add_child(btn4,true,true,LinearAlign.START)
box2:add_child(box,false,true,LinearAlign.START)
box:add_child(btn,false,false,LinearAlign.START)
box:add_child(btn2,true,false,LinearAlign.START)
box:add_child(btn3,false,false,LinearAlign.START)

root:on_layout()
--print(box.size[1],box.size[2])
--print(btn.size[1],btn.size[2])
--read()
root:on_redraw()
while true do
	evt = {os.pullEvent()}
	root:on_event(evt)
end