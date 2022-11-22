# gui

## Contents

- [Button](#button)
- [Constants](#constants)
- [Container](#container)
- [Label](#label)
- [LinearContainer](#linearcontainer)
- [ListBox](#listbox)
- [Object](#object)
- [Root](#root)
- [ScrollBar](#scrollbar)
- [ScrollWidget](#scrollwidget)
- [TextArea](#textarea)
- [TextField](#textfield)
- [Utility](#utility)
- [Widget](#widget)

## Button

Inheritance: [Button](#button) > [Widget](#widget) > [Object](#object)

Can be clicked using the mouse, triggering a custom onPressed() callback.

### Fields

#### Button.color

#### Button.disabledColor

#### Button.enabled

#### Button.held

#### Button.pushedColor

#### Button.text

#### Button.textColor

### Methods

#### Button(root, text)

Button constructor.

Parameters:
- root (Root): The root widget
- text (string): Text to display on the Button.

#### Button:onPressed()

Event handler called when a Button is pressed.
Override this method on a Button instance to set its behavior.

## Constants

### Fields

#### Constants.FOCUS_EVENTS

List of events that should be passed to the currently focused widget
(e.g. keyboard events)

#### Constants.LinearAlign

Enum used to specify layouts within LinearContainers.
- LinearAxis.CENTER: center the widget within its cell
- LinearAxis.START: align the widget to the top (HORIZONTAL container) or left (VERTICAL) of its cell
- LinearAxis.END: align the widget to the bottom (HORIZONTAL container) or right (VERTICAL) of its cell

#### Constants.LinearAxis

Enum used to specify layouts within LinearContainers.
- LinearAxis.HORIZONTAL: X axis
- LinearAxis.VERTICAL: Y axis

#### Constants.SpecialChars

Various special characters provided by ComputerCraft:

MINIMIZE, MAXIMIZE, STRIPES, TRI_RIGHT, TRI_LEFT, TRI_UP, TRI_DOWN,
ARROW_UP, ARROW_DOWN, ARROW_RIGHT, ARROW_LEFT, ARROW_LR, ARROW_UD

#### Constants.TOP_EVENTS

List of events that should only be passed to the topmost widget directly
under the mouse cursor (clicking, scrolling)

## Container

Inheritance: [Container](#container) > [Widget](#widget) > [Object](#object)

Base class for all widgets that can contain other gui widgets.

### Fields

#### Container.children

### Methods

#### Container(root)

Container constructor.

#### Container:addChild(child, ...)

Add a child widget to the Container.

#### Container:layoutChildren()

Updates the position and size of all widgets within the Container.
Specialized behavior is provided by subclasses of Container.

## Label

Inheritance: [Label](#label) > [Widget](#widget) > [Object](#object)

Displays custom text.

### Fields

#### Label.backgroundColor

#### Label.length

#### Label.text

#### Label.textColor

### Methods

#### Label(root, text)

Label constructor.

Parameters:
- root (Root): The root widget
- text (string): Text to display on the Label.

## LinearContainer

Inheritance: [LinearContainer](#linearcontainer) > [Container](#container) > [Widget](#widget) > [Object](#object)

Container that arranges child widgets in a horizontal or vertical line.
Padding at the edges and spacing between widgets can be specified.
Child widgets may be set to fill the primary and/or secondary axes of the container.
If multiple widgets are set to fill the primary axis, then the free space
will be evenly distributed between them.

### Fields

#### LinearContainer.axis

#### LinearContainer.padding

#### LinearContainer.spacing

### Methods

#### LinearContainer(root, axis, spacing, padding)

LinearContainer constructor.

Parameters:
- root (Root): The root widget
- axis (LinearAxis): The primary axis of this container (HORIZONAL or VERTICAL).
- spacing (int): Spacing between contained widgets.
- padding (int): Padding between the first/last widgets and the container's edge.

#### LinearContainer:addChild(child, fillPrimary, fillSecondary, align)

Adds a widget to the LinearContainer

Parameters:
- child (Widget): the widget to add
- fillPrimary (bool): whether the widget should fill the main axis specified in the constructor
- fillSecondary (bool): whether the widget should fill the other axis perpendicular to the primary one
- align (LinearAlign): whether the widget should be centered, left-aligned, or right-aligned

#### LinearContainer:getSecondaryAxis()

## ListBox

Inheritance: [ListBox](#listbox) > [ScrollWidget](#scrollwidget) > [Widget](#widget) > [Object](#object)

List box. Allows an array of choices to be displayed, one of which can be
selected at a time. Can be scrolled using the mouse wheel or a ScrollBar
widget, and is able to efficiently display large amounts of items.

### Fields

#### ListBox.bgColor

#### ListBox.cols

#### ListBox.items

#### ListBox.rows

#### ListBox.selBgColor

#### ListBox.selTextColor

#### ListBox.selected

#### ListBox.textColor

### Methods

#### ListBox(root, cols, rows, items)

ListBox constructor.

Parameters:
- root (Root): The root widget
- cols (int): The preferred width of the ListBox
- rows (int): The preferred height of the ListBox
- items (string[]): Items contained within the ListBox

#### ListBox:mouseSelect(x, y)

#### ListBox:onSelectionChanged()

Event handler called when the selected item is changed.
Override this method to receive selection events.

#### ListBox:setSelected(n)

## Object

Implements basic inheritance features.

### Methods

#### Object(...)

Object constructor.

To create an instance of an Object, call Object(args), which will instantiate
the class and then call the Object's constructor to set up the instance.
The process works the same way for subclasses: just replace Object with the
name of the class you are instantiating.

Internally, the constructor is named Object:init(...). Override this init
method to specify initialization behavior for an Object subclass. An object's
init() method may call its super class's init() if desired
(use ClassName.superClass.init(self,...))

#### Object:instanceof(class)

Returns true if the Object is an instance of the provided class or a subclass.

#### Object:subclass()

Creates a subclass of an existing class.

## Root

Inheritance: [Root](#root) > [Container](#container) > [Widget](#widget) > [Object](#object)

The root widget of the user interface. Handles focus, resizing, and other events.

### Fields

#### Root.backgroundColor

#### Root.focus

### Methods

#### Root()

Root constructor.

#### Root:mainLoop()

Shows the GUI and runs its event loop.

#### Root:show()

Called internally to render the root's first frame.

## ScrollBar

Inheritance: [ScrollBar](#scrollbar) > [Widget](#widget) > [Object](#object)

Scroll bar. Allows greater control over a scrolling widget such as a ListBox.

### Fields

#### ScrollBar.barColor

#### ScrollBar.bgColor

#### ScrollBar.bgPressedColor

#### ScrollBar.disabledColor

#### ScrollBar.drag

#### ScrollBar.dragOffset

#### ScrollBar.grab

#### ScrollBar.pressedColor

#### ScrollBar.scrollWidget

#### ScrollBar.textColor

### Methods

#### ScrollBar(root, scrollWidget)

ScrollBar constructor.

Parameters:
- root (Root): The root widget
- scrollWidget (ScrollWidget): The widget this ScrollBar should scroll

#### ScrollBar:canScroll()

#### ScrollBar:getBarHeight()

#### ScrollBar:getBarPos()

## ScrollWidget

Inheritance: [ScrollWidget](#scrollwidget) > [Widget](#widget) > [Object](#object)

Base class for scrollable widgets

### Fields

#### ScrollWidget.scroll

#### ScrollWidget.scrollSpeed

#### ScrollWidget.scrollbar

### Methods

#### ScrollWidget(root)

Widget constructor.

#### ScrollWidget:getMaxScroll()

Returns the scroll range of the widget

#### ScrollWidget:setScroll(scroll)

## TextArea

Inheritance: [TextArea](#textarea) > [Widget](#widget) > [Object](#object)

A text area for editing multi-line text. Unfinished.

### Fields

#### TextArea.charX

#### TextArea.charY

#### TextArea.color

#### TextArea.cols

#### TextArea.cursorScreenPos

#### TextArea.rows

#### TextArea.text

#### TextArea.textColor

### Methods

#### TextArea(root, cols, rows, text)

TextArea constructor.

Parameters:
- root (Root): The root widget
- cols (int): The preferred width of the text area
- rows (int): The preferred height of the text area
- text (string): Initial contents of the text area

#### TextArea:getText()

Gets the text within the text area.

#### TextArea:mouseSelect(x, y)

#### TextArea:setText(text)

Sets the text within the text area.

## TextField

Inheritance: [TextField](#textfield) > [Widget](#widget) > [Object](#object)

A text field that allows users to type text within it.

### Fields

#### TextField.char

#### TextField.color

#### TextField.cursorColor

#### TextField.cursorScreenPos

#### TextField.length

#### TextField.scroll

#### TextField.text

#### TextField.textColor

### Methods

#### TextField(root, length, text)

TextField constructor.

Parameters:
- root (Root): The root widget
- length (int): Width of the text field in characters.
- text (string): Initial contents of the TextField.

#### TextField:getText()

Gets the text within the TextField

#### TextField:isCursorVisible()

#### TextField:mouseSelect(x, y)

#### TextField:moveCursor(newPos)

#### TextField:onChanged()

Event handler called when the text in a TextField is edited.
Override this method on an instance to set custom behavior.

#### TextField:setText(text)

Sets the text within the TextField

## Utility

### Methods

#### Utility.contains(tbl, val)

#### Utility.startswith(str, substr)

## Widget

Inheritance: [Widget](#widget) > [Object](#object)

Base class for GUI elements.

### Fields

#### Widget.dirty

#### Widget.layout

#### Widget.parent

#### Widget.pos

#### Widget.root

#### Widget.size

### Methods

#### Widget(root)

Widget constructor.

#### Widget:containsPoint(x, y)

Returns true if the coordinates x, y are within the widget's bounding box.

#### Widget:focusPostRender()

Post-render callback for focused widget. Used to position text field cursor.

#### Widget:getPreferredSize()

Returns the widget's preferred minimum size.

#### Widget:onCharTyped(chr)

Event handler called when a character is typed and the widget is in focus.

#### Widget:onEvent(evt)

Handles any input events recieved by the widget and passes them to
the appropriate handler functions. Return true from an event handler
to consume the event and prevent it from being passed on to other widgets.
Event consumption is mainly useful for mouse_click and mouse_scroll.

#### Widget:onFocus(focused)

Event handler called when the widget enters or leaves focus.

#### Widget:onKeyDown(key, held)

Event handler called when a key is pressed or held and the widget is in focus.

#### Widget:onKeyUp(key)

Event handler called when a key is released and the widget is in focus.

#### Widget:onLayout()

Event handler called when the widget's layout is updated.

#### Widget:onMouseDown(btn, x, y)

Event handler called when a mouse button is released and the widget is in focus.

#### Widget:onMouseDrag(btn, x, y)

Event handler called when the widget is dragged.

#### Widget:onMouseScroll(dir, x, y)

Event handler called when the mouse wheel is scrolled over the widget.

#### Widget:onMouseUp(btn, x, y)

Event handler called when a mouse button is pressed over the widget.

#### Widget:onPaste(text)

Event handler called when text is pasted and the widget is in focus.

#### Widget:onRedraw()

Event handler called when the GUI is repainted.

#### Widget:render()

Widget render callbacks. Override these to draw a widget.

