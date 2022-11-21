# gui.lua

## Contents

- [Constants](#constants)
- [Object](#object)
- [Widget](#widget)
- [Container](#container)
- [Root](#root)
- [LinearContainer](#linearcontainer)
- [Label](#label)
- [Button](#button)
- [TextField](#textfield)
- [TextArea](#textarea)
- [ScrollWidget](#scrollwidget)
- [ListBox](#listbox)
- [ScrollBar](#scrollbar)

## Constants

### Constants.TOP_EVENTS

List of events that should only be passed to the topmost widget directly
under the mouse cursor (clicking, scrolling)

### Constants.FOCUS_EVENTS

List of events that should be passed to the currently focused widget
(e.g. keyboard events)

### Constants.SpecialChars

Various special characters provided by ComputerCraft:

MINIMIZE, MAXIMIZE, STRIPES, TRI_RIGHT, TRI_LEFT, TRI_UP, TRI_DOWN,
ARROW_UP, ARROW_DOWN, ARROW_RIGHT, ARROW_LEFT, ARROW_LR, ARROW_UD

### Constants.LinearAxis

Enum used to specify layouts within LinearContainers.
- LinearAxis.HORIZONTAL: X axis
- LinearAxis.VERTICAL: Y axis

### Constants.LinearAlign

Enum used to specify layouts within LinearContainers.
- LinearAxis.CENTER: center the widget within its cell
- LinearAxis.START: align the widget to the top (HORIZONTAL container) or left (VERTICAL) of its cell
- LinearAxis.END: align the widget to the bottom (HORIZONTAL container) or right (VERTICAL) of its cell

## Object

Implements basic inheritance features.

### Object:subclass()

Creates a subclass of an existing class.

### Object:instanceof(class)

Returns true if the Object is an instance of the provided class or a subclass.

## Widget

Inheritance: [Widget](#widget) > [Object](#object)

Base class for GUI elements.

### Widget(root)

Widget constructor.

### Widget:containsPoint(x, y)

Returns true if the coordinates x, y are within the widget's bounding box.

### Widget:onRedraw()

Event handler called when the GUI is repainted.

### Widget:onLayout()

Event handler called when the widget's layout is updated.

### Widget:getPreferredSize()

Returns the widget's preferred minimum size.

### Widget:render()

Widget render callbacks. Override these to draw a widget.

### Widget:focusPostRender()

Post-render callback for focused widget. Used to position text field cursor.

### Widget:onKeyDown(key, held)

Event handler called when a key is pressed or held and the widget is in focus.

### Widget:onKeyUp(key)

Event handler called when a key is released and the widget is in focus.

### Widget:onCharTyped(chr)

Event handler called when a character is typed and the widget is in focus.

### Widget:onPaste(text)

Event handler called when text is pasted and the widget is in focus.

### Widget:onMouseDown(btn, x, y)

Event handler called when a mouse button is released and the widget is in focus.

### Widget:onMouseUp(btn, x, y)

Event handler called when a mouse button is pressed over the widget.

### Widget:onMouseScroll(dir, x, y)

Event handler called when the mouse wheel is scrolled over the widget.

### Widget:onMouseDrag(btn, x, y)

Event handler called when the widget is dragged.

### Widget:onFocus(focused)

Event handler called when the widget enters or leaves focus.

### Widget:onEvent(evt)

Handles any input events recieved by the widget and passes them to
the appropriate handler functions. Return true from an event handler
to consume the event and prevent it from being passed on to other widgets.
Event consumption is mainly useful for mouse_click and mouse_scroll.

## Container

Inheritance: [Container](#container) > [Widget](#widget) > [Object](#object)

Base class for all widgets that can contain other widgets.

### Container(root)

Container constructor.

### Container:layoutChildren()

Lays out the container's children.
Specialized behavior is provided by subclasses of Container.

## Root

Inheritance: [Root](#root) > [Container](#container) > [Widget](#widget) > [Object](#object)

The root widget of the user interface. Handles focus, resizing, and other events.

### Root()

Root constructor.

### Root:show()

Called internally to render the root's first frame.

### Root:mainLoop()

Shows the GUI and runs its event loop.

## LinearContainer

Inheritance: [LinearContainer](#linearcontainer) > [Container](#container) > [Widget](#widget) > [Object](#object)

Container that arranges child widgets in a horizontal or vertical line.
Padding at the edges and spacing between widgets can be specified.
Child widgets may be set to fill the primary and/or secondary axes of the container.
If multiple widgets are set to fill the primary axis, then the free space
will be evenly distributed between them.

### LinearContainer(root, axis, spacing, padding)

LinearContainer constructor.

Parameters:
- root (Root): The root widget
- axis (LinearAxis): The primary axis of this container (HORIZONAL or VERTICAL).
- spacing (int): Spacing between contained widgets.
- padding (int): Padding between the first/last widgets and the container's edge.

### LinearContainer:addChild(child, fillPrimary, fillSecondary, align)

Adds a widget to the LinearContainer

Parameters:
- child (Widget): the widget to add
- fillPrimary (bool): whether the widget should fill the main axis specified in the constructor
- fillSecondary (bool): whether the widget should fill the other axis perpendicular to the primary one
- align (LinearAlign): whether the widget should be centered, left-aligned, or right-aligned

### LinearContainer:getSecondaryAxis()

## Label

Inheritance: [Label](#label) > [Widget](#widget) > [Object](#object)

A label. Can display custom text.

### Label(root, text)

Label constructor.

Parameters:
- root (Root): The root widget
- axis (string): Text to display on the Label.

## Button

Inheritance: [Button](#button) > [Widget](#widget) > [Object](#object)

Button. Can be pushed, and will trigger a custom onPressed() callback.

### Button(root, text)

Button constructor.

Parameters:
- root (Root): The root widget
- axis (string): Text to display on the Button.

### Button:onPressed()

Event handler called when a Button is pressed.
Override this method on a Button instance to set its behavior.

## TextField

Inheritance: [TextField](#textfield) > [Widget](#widget) > [Object](#object)

A text field that allows users to type text within it.

### TextField(root, length, text)

TextField constructor.

Parameters:
- root (Root): The root widget
- length (int): Width of the text field in characters.
- text (string): Initial contents of the TextField.

### TextField:onChanged()

Event handler called when the text in a TextField is edited.
Override this method on an instance to set custom behavior.

### TextField:setText(text)

Sets the text within the TextField

### TextField:getText()

Gets the text within the TextField

### TextField:isCursorVisible()

### TextField:moveCursor(newPos)

### TextField:mouseSelect(x, y)

## TextArea

Inheritance: [TextArea](#textarea) > [Widget](#widget) > [Object](#object)

A text area for editing multi-line text. Very buggy.
TODO: rewrite, use virtual lines for text wrapping
and allow wrapping to be disabled

### TextArea(root, cols, rows, text)

TextArea constructor.

Parameters:
- root: The root widget
- cols: The preferred width of the text area
- rows: The preferred height of the text area
- text: Initial contents of the text area

### TextArea:setText(text)

Sets the text within the text area.

### TextArea:getText()

Gets the text within the text area.

### TextArea:mouseSelect(x, y)

## ScrollWidget

Inheritance: [ScrollWidget](#scrollwidget) > [Widget](#widget) > [Object](#object)

Base class for scrollable widgets

### ScrollWidget(root)

Widget constructor.

### ScrollWidget:getMaxScroll()

Returns the scroll range of the widget

### ScrollWidget:setScroll(scroll)

## ListBox

Inheritance: [ListBox](#listbox) > [ScrollWidget](#scrollwidget) > [Widget](#widget) > [Object](#object)

List box. Allows an array of choices to be displayed, one of which can be
selected at a time. Can be scrolled using the mouse wheel or a ScrollBar
widget, and is able to efficiently display large amounts of items.

### ListBox(root, cols, rows, items)

ListBox constructor.

Parameters:
- root (Root): The root widget
- cols (int): The preferred width of the ListBox
- rows (int): The preferred height of the ListBox
- items (string[]): Items contained within the ListBox

### ListBox:onSelectionChanged()

Event handler called when the selected item is changed.
Override this method to receive selection events.

### ListBox:setSelected(n)

### ListBox:mouseSelect(x, y)

## ScrollBar

Inheritance: [ScrollBar](#scrollbar) > [Widget](#widget) > [Object](#object)

Scroll bar. Allows greater control over a scrolling widget such as a ListBox.

### ScrollBar(root, scrollWidget)

ScrollBar constructor.

Parameters:
- root (Root): The root widget
- scrollWidget (ScrollWidget): The widget this ScrollBar should scroll

### ScrollBar:canScroll()

### ScrollBar:getBarPos()

### ScrollBar:getBarHeight()

