-- gui.lua
-- TODO: standardize, don't use both lowerCamelCase and snake_case

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
function Widget:focus_postrender() end

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

-- TODO: Change event system to respect layering
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
	self.backgroundColor = colors.lightGray
end

function Root:show()
	self:on_layout()
	self:on_redraw()
end

function Root:on_redraw()
	Root.superClass.on_redraw(self)
	if self.focus then
		self.focus:focus_postrender()
	end
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
	term.setBackgroundColor(self.backgroundColor)
	term.clear()
end

local LinearContainer = Container:subclass()

function LinearContainer:constructor(root,axis,spacing,padding)
	LinearContainer.superClass.constructor(self,root)
	self.axis = axis
	self.spacing = spacing
	self.padding = padding
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
	
	local pref_size = {self.padding * 2,self.padding * 2}
	for i=1,#self.children do
		local child = self.children[i]
		local c_pref_size = child:get_preferred_size()
		pref_size[axis2] = math.max(pref_size[axis2],c_pref_size[axis2] + self.padding * 2)
		pref_size[self.axis] = pref_size[self.axis] + c_pref_size[self.axis]
		if i ~= #self.children then
			pref_size[self.axis] = pref_size[self.axis] + self.spacing
		end
	end
	
	return pref_size
end

function LinearContainer:layout_children()
	local axis2 = self:get_minor_axis()
	
	local space_free = self.size[self.axis] - self.padding * 2
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
	
	local current_pos = self.pos[self.axis] + self.padding
	local fill_count = 0
	
	for i=1,#self.children do
		local child = self.children[i]
		local size = 0
		local pref_size = preferred_sizes[i]
		
		if child.layout.fill_major then
			fill_count = fill_count + 1
			
			size = math.max((math.floor(space_free * fill_count / children_fill)
				- math.floor(space_free * (fill_count-1) / children_fill)),0)
		else
			size = pref_size[self.axis]
		end
		
		child.pos[self.axis] = current_pos
		child.size[self.axis] = size
		
		local cell_size = self.size[axis2] - self.padding * 2
		
		if child.layout.fill_minor then
			child.size[axis2] = cell_size
		else
			child.size[axis2] = math.min(pref_size[axis2],cell_size)
		end
		
		if child.layout.align == LinearAlign.CENTER then
			child.pos[axis2] = self.pos[axis2]+self.padding+math.floor((cell_size-child.size[axis2])/2)
		elseif child.layout.align == LinearAlign.START then
			child.pos[axis2] = self.pos[axis2]+self.padding
		elseif child.layout.align == LinearAlign.END then
			child.pos[axis2] = self.pos[axis2]+self.size[axis2]-self.padding-child.size[axis2]
		end
		
		current_pos = current_pos + size + self.spacing
	end
end

-- RENDERED WIDGET CLASSES

-- A label. Can display custom text.
local Label = Widget:subclass()

function Label:constructor(root,text)
	Label.superClass.constructor(self,root)
	self.text = text
	self.backgroundColor = colors.lightGray
	self.textColor = colors.black
end

function Label:render()
	if self.size[2] > 0 then
		term.setBackgroundColor(self.backgroundColor)
		term.setTextColor(self.textColor)
		term.setCursorPos(self.pos[1],self.pos[2])
		term.write(string.sub(self.text,1,math.min(#self.text,self.size[1])))
	end
end

function Label:get_preferred_size()
	return {#self.text,1}
end

-- Button. Can be pushed, and will trigger a custom on_pressed() callback.
local Button = Widget:subclass()

function Button:constructor(root,text)
	Button.superClass.constructor(self,root)
	self.text = text
	self.color = colors.blue
	self.pushedColor = colors.cyan
	self.textColor = colors.white
	self.disabledColor = colors.gray
	self.held = false
	self.enabled = true
end

-- ***Override this method on a Button instance to set behavior***
function Button:on_pressed() end

function Button:get_preferred_size()
	return {#self.text+2,1}
end

function Button:render()
	--getSuper(Button).render(self)
	-- TODO: render outline when focused
	if not self.enabled then
		term.setBackgroundColor(self.disabledColor)
	elseif self.held then --self.root.focus == self then
		term.setBackgroundColor(self.pushedColor)
	else
		term.setBackgroundColor(self.color)
	end
	term.setTextColor(self.textColor)
	local myX,myY = self.pos[1], self.pos[2]
	
	for y=1,self.size[2] do
		term.setCursorPos(myX,myY+y-1)
		term.write(string.rep(" ",self.size[1]))
	end
	
	if self.size[2] > 0 then
		local text_x = myX + math.max(math.floor((self.size[1]-#self.text)/2),0)
		local text_y = myY + math.max(math.floor((self.size[2]-1)/2),0)
		term.setCursorPos(text_x,text_y)
		term.write(string.sub(self.text,1,math.min(#self.text,self.size[1])))
	end
end

function Button:on_mouse_down(btn,x,y)
	if self.enabled then
		self.held = true
		self.dirty = true
	end
end

function Button:on_mouse_up(btn,x,y)
	if self.enabled then
		self.held = false
		self.dirty = true
		if self:contains_point(x,y) then
			self:on_pressed()
		end
	end
end

function Button:on_key_down(key,held)
	if self.enabled and (not held) and (key == keys.space or key == keys.enter) then
		self.held = true
		self.dirty = true
	end
end

function Button:on_key_up(key)
	if self.enabled and (key == keys.space or key == keys.enter) then
		self.held = false
		self.dirty = true
		self:on_pressed()
	end
end

function Button:on_focus(focused)
	if self.enabled then
		self.dirty = true
	end
end

-- A text field. You can type text in it.
TextField = Widget:subclass()

-- TODO: Add auto-completion
function TextField:constructor(root,length,text)
	TextField.superClass.constructor(self,root)
	
	self.text = text
	self.color = colors.white
	self.textColor = colors.black
	self.cursorColor = colors.lightGray
	self.cursor_screen_pos = {0,0}
	self.char = #self.text
	self.length = length
	self.scroll = 0
end

function TextField:get_preferred_size()
	return {self.length,1}
end

function TextField:is_cursor_visible()
	return (self.root.focus == self and self:contains_point(unpack(self.cursor_screen_pos)))
end

function TextField:render()
	term.setTextColor(self.textColor)
	term.setBackgroundColor(self.color)
	
	local myX,myY = self.pos[1], self.pos[2]
	
	for y=1,self.size[2] do
		term.setCursorPos(myX,myY+y-1)
		term.write(string.rep(" ",self.size[1]))
	end
	
	term.setCursorPos(myX,myY)
	term.write(string.sub(self.text,self.scroll+1,math.min(#self.text,self.scroll+self.size[1])))
	
	self.cursor_screen_pos = {myX+self.char-1-self.scroll,myY}
	
	if self:is_cursor_visible() then
		term.setCursorPos(unpack(self.cursor_screen_pos))
		term.setBackgroundColor(self.cursorColor)
		local chr = " "
		if self.char <= #self.text then
			chr = string.sub(self.text,self.char,self.char)
		end
		term.write(chr)
	end
end

function TextField:move_cursor(new_pos)
	self.char = math.min(math.max(new_pos,1),#self.text+1)
	if self.char-self.scroll > self.size[1] then
		self.scroll = self.char - self.size[1]
	elseif self.char-self.scroll < 1 then
		self.scroll = self.char - 1
	end
end

function TextField:on_key_down(key,held)
	if self.root.focus == self then
		if key == keys.backspace then
			self.text = string.sub(self.text,1,math.max(self.char-2,0)) .. string.sub(self.text,self.char,#self.text)
			self:move_cursor(self.char-1)
		elseif key == keys.delete then
			self.text = string.sub(self.text,1,math.max(self.char-1,0)) .. string.sub(self.text,self.char+1,#self.text)
		elseif key == keys.home then
			self:move_cursor(1)
		elseif key == keys['end'] then
			self:move_cursor(#self.text+1)
		elseif key == keys.left then
			self:move_cursor(self.char-1)
		elseif key == keys.right then
			self:move_cursor(self.char+1)
		end
		self.dirty = true
	end
end

function TextField:on_focus(focused)
	term.setCursorBlink(focused)
	self.dirty = true
end

function TextField:focus_postrender()
	if self:is_cursor_visible() then
		term.setCursorPos(unpack(self.cursor_screen_pos))
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end
end

function TextField:on_char(chr)
	if self.root.focus == self then
		self.text = string.sub(self.text,1,self.char-1) .. chr .. string.sub(self.text,self.char,#self.text)
		self:move_cursor(self.char + 1)
		self.dirty = true
	end
end

function TextField:on_paste(text)
	if self.root.focus == self then
		self.text = string.sub(self.text,1,self.char-1) .. text .. string.sub(self.text,self.char,#self.text)
		self:move_cursor(self.char + #text)
		self.dirty = true
	end
end

function TextField:on_mouse_down(button, x, y)
	self:select(x,y)
end

function TextField:on_mouse_drag(button, x, y)
	self:select(x,y)
end

-- TODO: Add area selection
function TextField:select(x, y)
	self:move_cursor(x - self.pos[1] + 1 + self.scroll)
	self.dirty = true
end

-- A text area for editing multi-line text. Very buggy.
-- TODO: rewrite, use virtual lines for text wrapping
--		also allow wrapping to be disabled
TextArea = Widget:subclass()

function TextArea:constructor(root,rows,cols,text)
	TextArea.superClass.constructor(self,root)
	
	self:setText(text)
	self.color = colors.white
	self.textColor = colors.black
	self.rows = rows
	self.cols = cols
	self.cursor_screen_pos = {0,0}
	self.charX,self.charY = #self.text,1
end

function TextArea:get_preferred_size()
	return {self.cols, self.rows}
end

-- BUG: double newlines are combined
function TextArea:setText(text)
	self.text = {}
	for line in text:gmatch("[^\r?\n]+") do
		table.insert(self.text,line)
	end
end

function TextArea:getText()
	return table.concat(self.text,"\n")
end

-- TODO: add scrolling
-- BUG: cursor does not render at width
function TextArea:render()
	term.setTextColor(self.textColor)
	term.setBackgroundColor(self.color)
	
	local myX,myY = self.pos[1], self.pos[2]
	
	for y=1,self.size[2] do
		term.setCursorPos(myX,myY+y-1)
		term.write(string.rep(" ",self.size[1]))
	end
	
	local y = 0
	local lY = 0
	for i=1,#self.text do
		local text = self.text[i]
		--if self.root.focus == self and i == self.charY then
		--	term.setBackgroundColor(colors.lightGray)
		--else
		--	term.setBackgroundColor(self.color)
		--end
		while (text ~= "") and (y < self.size[2]) do
			local chr = self.size[1]
			local substr = string.sub(text,1,chr)
			text = string.sub(text,chr+1,#text)
			term.setCursorPos(myX,myY+y+i-1)
			term.write(substr)
			if text ~= "" then
				y = y + 1
				if i < self.charY then
					lY = lY + 1
				end
			end
		end
	end
	--term.write(string.sub(self.text,1,math.min(#self.text,self.size[1])))
	if self.root.focus == self then
		self.cursor_screen_pos = {myX+(self.charX%self.size[1]-1),myY+lY+math.floor(self.charX/self.size[1])+self.charY-1}
		term.setCursorPos(unpack(self.cursor_screen_pos))
		term.setBackgroundColor(colors.lightGray)
		local chr = " "
		if self.charX <= #self.text[self.charY] then
			chr = string.sub(self.text[self.charY],self.charX,self.charX)
		end
		term.write(chr)
		--	term.write("I")
	end
end

-- TODO: Add DELETE key, fix up/down behavior with wrapped strings
function TextArea:on_key_down(key,held)
	if self.root.focus == self then
		if key == keys.backspace then
			if (self.charY > 1) and (self.charX == 1) then
				local text = table.remove(self.text,self.charY)
				self.charY = self.charY - 1
				local text2 = self.text[self.charY]
				self.charX = #self.text[self.charY]+1
				self.text[self.charY] = text2 .. text
			elseif self.charX > 1 then
				local text = self.text[self.charY]
				self.text[self.charY] = string.sub(text,1,self.charX-2) .. string.sub(text,self.charX,#text)
				self.charX = math.max(1,self.charX-1)
			end
		elseif key == keys.left then
			if (self.charX == 1) and (self.charY > 1) then
				self.charY = self.charY - 1
				self.charX = #self.text[self.charY]+1
			else
				self.charX = math.max(1,self.charX-1)
			end
		elseif key == keys.right then
			local text = self.text[self.charY]
			if (self.charX == #text+1) and (self.charY < #self.text) then
				self.charX = 1
				self.charY = self.charY + 1
			else
				self.charX = math.min(#text+1,self.charX+1)
			end
		elseif key == keys.down then
			if self.charX + self.size[1] <= #self.text[self.charY]+1 then
				self.charX = self.charX + self.size[1]
			elseif self.charY < #self.text then
				self.charY = self.charY+1
				self.charX = math.min(self.charX,#self.text[self.charY]+1)
			else
				self.charX = #self.text[self.charY]
			end
		elseif key == keys.up then
			if self.charX - self.size[1] >= 1 then
				self.charX = self.charX - self.size[1]
			elseif self.charY > 1 then
				self.charY = self.charY-1
				self.charX = math.min(self.charX,#self.text[self.charY]+1)
			else
				self.charX = 1
			end
		elseif key == keys.enter then
			local text = self.text[self.charY]
			local newline = string.sub(text,self.charX,#text)
			self.text[self.charY] = string.sub(text,1,self.charX-1)
			self.charX = 1
			self.charY = self.charY + 1
			table.insert(self.text,self.charY,newline)
		end
		self.dirty = true
	end
end

function TextArea:on_focus(focused)
	term.setCursorBlink(focused)
	self.dirty = true
end

function TextArea:focus_postrender()
	term.setCursorPos(unpack(self.cursor_screen_pos)) 
end

function TextArea:on_char(chr)
	if self.root.focus == self then
		local text = self.text[self.charY]
		self.text[self.charY] = string.sub(text,1,self.charX-1) .. chr .. string.sub(text,self.charX,#text)
		self.charX = self.charX + 1
		self.dirty = true
	end
end

function TextArea:on_paste(text)
	if self.root.focus == self then
		local text_line = self.text[self.charY]
		self.text[self.charY] = string.sub(text_line,1,self.charX-1) .. text .. string.sub(text_line,self.charX,#text_line)
		self.charX = self.charX + #text
		self.dirty = true
	end
end

function TextArea:on_mouse_down(button, x, y)
	self:select(x,y)
end

function TextArea:on_mouse_drag(button, x, y)
	self:select(x,y)
end

-- TODO: Add area selection
-- BUG: Off-by-one error, behaves wrongly when a line is exactly the widget width
function TextArea:select(x, y)
	local myX,myY = self.pos[1],self.pos[2]
	local t_y = 1
	self.charY = 0
	for i=1,#self.text do
		for j=1,math.floor(#self.text[i]/self.size[1])+1 do
			if t_y == y - myY + 1 then
				self.charY = i
				self.charX = math.min(x+(j-1)*self.size[1],#self.text[i]+1)
			end
			t_y = t_y + 1
		end
		if self.charY ~= 0 then break end
	end
	if self.charY == 0 then
		self.charY = #self.text
		self.charX = #self.text[self.charY]+1
	end
	self.dirty = true
end

-- TODO: Add CheckBox, ListBox, ComboBox, ScrollBar, Slider, ScrollContainer, Image, TabContainer, MenuBar

local root = Root:new()
local box = LinearContainer:new(root,2,1,1)
local box2 = LinearContainer:new(root,1,0,0)
local lbl = Label:new(root,"Hello!")
local btn1 = Button:new(root,"Button 1")
local btn2 = Button:new(root,"Button 2")
local area = TextArea:new(root,10,10,"Type text here")

btn1.enabled = false

--btn3.color = colors.cyan
--btn3.pushedColor = colors.green
-- function btn1:on_pressed()
	-- shell.run("worm")
-- end
-- function btn2:on_pressed()
	-- btn1.enabled = true
	-- btn1.dirty = true
--end

root:add_child(box2)
box2:add_child(area,true,true,LinearAlign.START)
box2:add_child(box,false,true,LinearAlign.START)
box:add_child(lbl,false,false,LinearAlign.START)
box:add_child(btn1,true,false,LinearAlign.START)
box:add_child(btn2,true,false,LinearAlign.START)

root:show()
--print(box.size[1],box.size[2])
--print(btn.size[1],btn.size[2])
--read()
while true do
	evt = {os.pullEvent()}
	root:on_event(evt)
end