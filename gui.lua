-- gui.lua: simple GUI toolkit for ComputerCraft

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

-- WIDGET CLASSES

local Widget = Object:subclass()

function Widget:init(root)
	self.size = {0,0}
	self.pos = {1,1}
	self.layout = {}
	self.dirty = true
	self.parent = nil
	self.root = root
end

function Widget:containsPoint(x,y)
	return (
		x >= self.pos[1] and 
		x < self.pos[1]+self.size[1] and 
		y >= self.pos[2] and 
		y < self.pos[2]+self.size[2]
	)
end

function Widget:onRedraw()
	if self.dirty then
		self:render()
		self.dirty = false
	end
end

function Widget:onLayout()
	self.dirty = true
end

function Widget:getPreferredSize()
	return {0, 0}
end

-- Widget render callbacks. Override these to draw a widget.
function Widget:render() end
-- Post-render callback for focused widget. Used to position text field cursor.
function Widget:focusPostRender() end

-- Widget event handlers. Override these to provide custom behavior
function Widget:onKeyDown(key,held) end
function Widget:onKeyUp(key) end
function Widget:onCharTyped(chr) end
function Widget:onPaste(text) end
function Widget:onMouseDown(btn,x,y) end
function Widget:onMouseUp(btn,x,y) end
function Widget:onMouseScroll(dir,x,y) end
function Widget:onMouseDrag(btn,x,y) end
function Widget:onFocus(focused) end

function Widget:onEvent(evt)
	if contains(mouse_events,evt[1]) then
		if (not self.root) or (self.root.focus == self) then
			if evt[1] == "mouse_drag" then
				self:onMouseDrag(evt[2],evt[3],evt[4])
			elseif evt[1] == "mouse_up" then
				self:onMouseUp(evt[2],evt[3],evt[4])
			end
		end
		
		if not self:containsPoint(evt[3],evt[4]) then
			return
		end
		
		if evt[1] == "mouse_click" then
			if self.root then
				self.root.focus = self
			end
			self:onMouseDown(evt[2],evt[3],evt[4])
		elseif evt[1] == "mouse_scroll" then
			self:onMouseScroll(evt[2],evt[3],evt[4])
		end
	elseif (not self.root) or ((self.root.focus == self) and contains(keybd_events,evt[1])) then
		if evt[1] == "char" then
			self:onCharTyped(evt[2])
		elseif evt[1] == "key" then
			self:onKeyDown(evt[2],evt[3])
		elseif evt[1] == "key_up" then
			self:onKeyUp(evt[2])
		elseif evt[1] == "paste" then
			self:onPaste(evt[2])
		end
	end
end

-- CONTAINER CLASSES

-- Container: Base class for all widgets that can contain other widgets
local Container = Widget:subclass()

function Container:init(root)
	Container.superClass.init(self,root)
	self.children = {}
end

function Container:addChild(child,...)
	table.insert(self.children,child)
end

function Container:onRedraw()
	Container.superClass.onRedraw(self)
	for _,widget in pairs(self.children) do
		widget:onRedraw()
	end
end

-- TODO: Change event system to respect layering
function Container:onEvent(evt)
	Container.superClass.onEvent(self,evt)
	for _,widget in pairs(self.children) do
		widget:onEvent(evt)
	end
end

function Container:onLayout()
	Container.superClass.onLayout(self)
	self:layoutChildren()
	for _,widget in pairs(self.children) do
		widget:onLayout()
	end
end

function Container:layoutChildren() end

-- Root: The root widget of the user interface. Handles focus, resizing, and other events.
local Root = Container:subclass()

function Root:init()
	Root.superClass.init(self,nil)
	self.focus = nil
	self.size = {term.getSize()}
	self.backgroundColor = colors.lightGray
end

function Root:show()
	self:onLayout()
	self:onRedraw()
end

function Root:onRedraw()
	Root.superClass.onRedraw(self)
	if self.focus then
		self.focus:focusPostRender()
	end
end

function Root:onEvent(evt)
	local focus = self.focus
	Root.superClass.onEvent(self,evt)
	if evt[1] == "term_resize" then
		self.size = {term.getSize()}
		self:onLayout()
	end
	if self.focus ~= focus then
		if focus then
			focus:onFocus(false)
		end
		if self.focus then
			self.focus:onFocus(true)
		end
	end
	self:onRedraw()
end

function Root:layoutChildren()
	for _,widget in pairs(self.children) do
		widget.pos = {1,1}
		widget.size = {self.size[1],self.size[2]}
	end
end

function Root:render()
	term.setBackgroundColor(self.backgroundColor)
	term.clear()
end

-- LinearContainer: Arranges child widgets in a horizontal or vertical line.
--   Padding at the edges and spacing between widgets can be specified.
--   Child widgets may be set to fill the major and/or minor axes of the container.
--   If multiple widgets are set to fill the major axis
--     then the free space will be evenly distributed between them.
local LinearContainer = Container:subclass()

function LinearContainer:init(root,axis,spacing,padding)
	LinearContainer.superClass.init(self,root)
	self.axis = axis
	self.spacing = spacing
	self.padding = padding
end

function LinearContainer:addChild(child,fillMajor,fillMinor,align)
	LinearContainer.superClass.addChild(self,child)
	child.layout.fillMajor = fillMajor
	child.layout.fillMinor = fillMinor
	child.layout.align = align
end

function LinearContainer:getMinorAxis()
	if self.axis == 1 then
		return 2
	end
	return 1
end

function LinearContainer:getPreferredSize()
	local axis2 = self:getMinorAxis()
	
	local prefSize = {self.padding * 2,self.padding * 2}
	for i=1,#self.children do
		local child = self.children[i]
		local c_prefSize = child:getPreferredSize()
		prefSize[axis2] = math.max(prefSize[axis2],c_prefSize[axis2] + self.padding * 2)
		prefSize[self.axis] = prefSize[self.axis] + c_prefSize[self.axis]
		if i ~= #self.children then
			prefSize[self.axis] = prefSize[self.axis] + self.spacing
		end
	end
	
	return prefSize
end

function LinearContainer:layoutChildren()
	local axis2 = self:getMinorAxis()
	
	local space_free = self.size[self.axis] - self.padding * 2
	local childrenFill = 0
	local preferred_sizes = {}
	
	for i=1,#self.children do
		local child = self.children[i]
		local prefSize = child:getPreferredSize()
		table.insert(preferred_sizes, prefSize)
		
		if child.layout.fillMajor then
			childrenFill = childrenFill + 1
		else
			space_free = space_free - prefSize[self.axis]
		end
		if i ~= #self.children then
			space_free = space_free - self.spacing
		end
	end
	
	local currentPos = self.pos[self.axis] + self.padding
	local fillCount = 0
	
	for i=1,#self.children do
		local child = self.children[i]
		local size = 0
		local prefSize = preferred_sizes[i]
		
		if child.layout.fillMajor then
			fillCount = fillCount + 1
			
			size = math.max((math.floor(space_free * fillCount / childrenFill)
				- math.floor(space_free * (fillCount-1) / childrenFill)),0)
		else
			size = prefSize[self.axis]
		end
		
		child.pos[self.axis] = currentPos
		child.size[self.axis] = size
		
		local cell_size = self.size[axis2] - self.padding * 2
		
		if child.layout.fillMinor then
			child.size[axis2] = cell_size
		else
			child.size[axis2] = math.min(prefSize[axis2],cell_size)
		end
		
		if child.layout.align == LinearAlign.CENTER then
			child.pos[axis2] = self.pos[axis2]+self.padding+math.floor((cell_size-child.size[axis2])/2)
		elseif child.layout.align == LinearAlign.START then
			child.pos[axis2] = self.pos[axis2]+self.padding
		elseif child.layout.align == LinearAlign.END then
			child.pos[axis2] = self.pos[axis2]+self.size[axis2]-self.padding-child.size[axis2]
		end
		
		currentPos = currentPos + size + self.spacing
	end
end

-- RENDERED WIDGET CLASSES

-- A label. Can display custom text.
local Label = Widget:subclass()

function Label:init(root,text)
	Label.superClass.init(self,root)
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

function Label:getPreferredSize()
	return {#self.text,1}
end

-- Button. Can be pushed, and will trigger a custom onPressed() callback.
local Button = Widget:subclass()

function Button:init(root,text)
	Button.superClass.init(self,root)
	self.text = text
	self.color = colors.blue
	self.pushedColor = colors.cyan
	self.textColor = colors.white
	self.disabledColor = colors.gray
	self.held = false
	self.enabled = true
end

-- ***Override this method on a Button instance to set behavior***
function Button:onPressed() end

function Button:getPreferredSize()
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

function Button:onMouseDown(btn,x,y)
	if self.enabled then
		self.held = true
		self.dirty = true
	end
end

function Button:onMouseUp(btn,x,y)
	if self.enabled then
		self.held = false
		self.dirty = true
		if self:containsPoint(x,y) then
			self:onPressed()
		end
	end
end

function Button:onKeyDown(key,held)
	if self.enabled and (not held) and (key == keys.space or key == keys.enter) then
		self.held = true
		self.dirty = true
	end
end

function Button:onKeyUp(key)
	if self.enabled and (key == keys.space or key == keys.enter) then
		self.held = false
		self.dirty = true
		self:onPressed()
	end
end

function Button:onFocus(focused)
	if self.enabled then
		self.dirty = true
	end
end

-- A text field. You can type text in it.
TextField = Widget:subclass()

-- TODO: Add auto-completion
function TextField:init(root,length,text)
	TextField.superClass.init(self,root)
	
	self.text = text
	self.color = colors.white
	self.textColor = colors.black
	self.cursorColor = colors.lightGray
	self.cursorScreenPos = {0,0}
	self.char = #self.text
	self.length = length
	self.scroll = 0
end

function TextField:getPreferredSize()
	return {self.length,1}
end

function TextField:isCursorVisible()
	return (self.root.focus == self and self:containsPoint(unpack(self.cursorScreenPos)))
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
	
	self.cursorScreenPos = {myX+self.char-1-self.scroll,myY}
	
	if self:isCursorVisible() then
		term.setCursorPos(unpack(self.cursorScreenPos))
		term.setBackgroundColor(self.cursorColor)
		local chr = " "
		if self.char <= #self.text then
			chr = string.sub(self.text,self.char,self.char)
		end
		term.write(chr)
	end
end

function TextField:moveCursor(newPos)
	self.char = math.min(math.max(newPos,1),#self.text+1)
	if self.char-self.scroll > self.size[1] then
		self.scroll = self.char - self.size[1]
	elseif self.char-self.scroll < 1 then
		self.scroll = self.char - 1
	end
end

function TextField:onKeyDown(key,held)
	if self.root.focus == self then
		if key == keys.backspace then
			self.text = string.sub(self.text,1,math.max(self.char-2,0)) .. string.sub(self.text,self.char,#self.text)
			self:moveCursor(self.char-1)
		elseif key == keys.delete then
			self.text = string.sub(self.text,1,math.max(self.char-1,0)) .. string.sub(self.text,self.char+1,#self.text)
		elseif key == keys.home then
			self:moveCursor(1)
		elseif key == keys['end'] then
			self:moveCursor(#self.text+1)
		elseif key == keys.left then
			self:moveCursor(self.char-1)
		elseif key == keys.right then
			self:moveCursor(self.char+1)
		end
		self.dirty = true
	end
end

function TextField:onFocus(focused)
	term.setCursorBlink(focused)
	self.dirty = true
end

function TextField:focusPostRender()
	if self:isCursorVisible() then
		term.setCursorPos(unpack(self.cursorScreenPos))
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end
end

function TextField:onCharTyped(chr)
	if self.root.focus == self then
		self.text = string.sub(self.text,1,self.char-1) .. chr .. string.sub(self.text,self.char,#self.text)
		self:moveCursor(self.char + 1)
		self.dirty = true
	end
end

function TextField:onPaste(text)
	if self.root.focus == self then
		self.text = string.sub(self.text,1,self.char-1) .. text .. string.sub(self.text,self.char,#self.text)
		self:moveCursor(self.char + #text)
		self.dirty = true
	end
end

function TextField:onMouseDown(button, x, y)
	self:mouseSelect(x,y)
end

function TextField:onMouseDrag(button, x, y)
	self:mouseSelect(x,y)
end

-- TODO: Add area selection
function TextField:mouseSelect(x, y)
	self:moveCursor(x - self.pos[1] + 1 + self.scroll)
	self.dirty = true
end

-- A text area for editing multi-line text. Very buggy.
-- TODO: rewrite, use virtual lines for text wrapping
--		also allow wrapping to be disabled
TextArea = Widget:subclass()

function TextArea:init(root,cols,rows,text)
	TextArea.superClass.init(self,root)
	
	self:setText(text)
	self.color = colors.white
	self.textColor = colors.black
	self.rows = rows
	self.cols = cols
	self.cursorScreenPos = {0,0}
	self.charX,self.charY = #self.text,1
end

function TextArea:getPreferredSize()
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
		self.cursorScreenPos = {myX+(self.charX%self.size[1]-1),myY+lY+math.floor(self.charX/self.size[1])+self.charY-1}
		term.setCursorPos(unpack(self.cursorScreenPos))
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
function TextArea:onKeyDown(key,held)
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

function TextArea:onFocus(focused)
	term.setCursorBlink(focused)
	self.dirty = true
end

function TextArea:focusPostRender()
	term.setCursorPos(unpack(self.cursorScreenPos)) 
end

function TextArea:onCharTyped(chr)
	if self.root.focus == self then
		local text = self.text[self.charY]
		self.text[self.charY] = string.sub(text,1,self.charX-1) .. chr .. string.sub(text,self.charX,#text)
		self.charX = self.charX + 1
		self.dirty = true
	end
end

function TextArea:onPaste(text)
	if self.root.focus == self then
		local text_line = self.text[self.charY]
		self.text[self.charY] = string.sub(text_line,1,self.charX-1) .. text .. string.sub(text_line,self.charX,#text_line)
		self.charX = self.charX + #text
		self.dirty = true
	end
end

function TextArea:onMouseDown(button, x, y)
	self:mouseSelect(x,y)
end

function TextArea:onMouseDrag(button, x, y)
	self:mouseSelect(x,y)
end

-- TODO: Add area selection
-- BUG: Off-by-one error, behaves wrongly when a line is exactly the widget width
function TextArea:mouseSelect(x, y)
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

local ListBox = Widget:subclass()

function ListBox:init(root,cols,rows,items)
	ListBox.superClass.init(self,root)
	self.items = items
	self.cols = cols
	self.rows = rows
	self.scroll = 0
	self.bgColor = colors.white
	self.textColor = colors.black
	self.selBgColor = colors.cyan
	self.selTextColor = colors.white
	self.selected = 0
end

function ListBox:getPreferredSize()
	return {self.cols, self.rows}
end

function ListBox:render()
	for i=1,self.size[2] do
		term.setCursorPos(self.pos[1],self.pos[2]+i-1)
		local optText = ""
		local isOpt = false
		local idx = i+self.scroll
		
		if idx>=1 and idx<=#self.items then
			optText = string.sub(self.items[idx],1,self.size[1])
			isOpt = true
		end
		
		if isOpt and self.selected == idx then
			term.setBackgroundColor(self.selBgColor)
			term.setTextColor(self.selTextColor)
		else
			term.setBackgroundColor(self.bgColor)
			term.setTextColor(self.textColor)
		end
		
		term.write(optText..string.rep(" ",self.size[1]-#optText))
	end
end

function ListBox:onLayout()
	ListBox.superClass.onLayout(self)
	self:setScroll(self.scroll)
end

-- Override this method to receive selection events
function ListBox:on_selection_changed() end

function ListBox:setSelected(n)
	n = math.min(math.max(n,1),#self.items)
	if self.selected ~= n then
		self.selected = n
		if self.scroll >= self.selected then
			self:setScroll(self.selected - 1)
		elseif self.scroll + self.size[2] < self.selected then
			self:setScroll(self.selected - self.size[2])
		end
		self:on_selection_changed()
	end
end

function ListBox:setScroll(scroll)
	self.scroll = scroll
	if self.scroll + self.size[2] > #self.items then
		self.scroll = #self.items-self.size[2]
	end
	if self.scroll < 0 then
		self.scroll = 0
	end
	self.dirty = true
end

function ListBox:mouseSelect(x,y)
	self:setSelected(y-self.pos[2]+self.scroll+1)
	self.dirty = true
end

function ListBox:onMouseDown(button, x, y)
	self:mouseSelect(x,y)
end

function ListBox:onMouseScroll(dir, x, y)
	self:setScroll(self.scroll+dir)
end

function ListBox:onMouseDrag(button, x, y)
	self:mouseSelect(x,y)
end

function ListBox:onKeyDown(key,held)
	if self.root.focus == self then
		if key == keys.down then
			self:setSelected(self.selected+1)
		elseif key == keys.up then
			self:setSelected(self.selected-1)
		elseif key == keys.home then
			self:setSelected(1)
		elseif key == keys['end'] then
			self:setSelected(#self.items)
		elseif key == keys.pageUp then
			self:setSelected(self.selected-(self.size[2]-1))
		elseif key == keys.pageDown then
			self:setSelected(self.selected+(self.size[2]-1))
		end
		self.dirty = true
	end
end

-- TODO:
-- Decide whether scrollbars should be part of ScrollWidgets or a separate widget
-- Add BoxContainer, CheckBox, ComboBox, ScrollWidget, [ScrollBar,] Slider,
-- 	ScrollContainer, Image, TabContainer, MenuBar

local root = Root:new()
local box = LinearContainer:new(root,2,1,1)
local box2 = LinearContainer:new(root,1,0,0)
local lbl = Label:new(root,"Hello!")
local btn1 = Button:new(root,"Button 1")
local btn2 = Button:new(root,"Button 2")
local area = ListBox:new(root,10,10,{})
for i=1,15 do
	table.insert(area.items,"Item "..tostring(i))
end
btn1.enabled = false

--btn3.color = colors.cyan
--btn3.pushedColor = colors.green
-- function btn1:onPressed()
	-- shell.run("worm")
-- end
-- function btn2:onPressed()
	-- btn1.enabled = true
	-- btn1.dirty = true
--end

root:addChild(box2)
box2:addChild(area,true,true,LinearAlign.START)
box2:addChild(box,false,true,LinearAlign.START)
box:addChild(lbl,false,false,LinearAlign.START)
box:addChild(btn1,true,false,LinearAlign.START)
box:addChild(btn2,true,false,LinearAlign.START)

root:show()
--print(box.size[1],box.size[2])
--print(btn.size[1],btn.size[2])
--read()
while true do
	evt = {os.pullEvent()}
	root:onEvent(evt)
end