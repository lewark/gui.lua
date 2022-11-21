import sys
import re

# TODO: Add dynamic links in text
# TODO: Grab types from expect calls

SHOW_UNDOC_OVERRIDES = False
ALWAYS_SHOW = ["init"]

ALPHA = "[a-zA-Z_]+"
TABLE = "{.*}"

PARAM_RE = re.compile("[, ]+")
SIMPLE_RE = re.compile("local +("+ALPHA+") += +"+TABLE)
FIELD_RE = re.compile("("+ALPHA+")\.("+ALPHA+") += +")
METHOD_RE = re.compile("function +("+ALPHA+"):("+ALPHA+") *\(([a-zA-Z_, ]*)\)")
SUBCLASS_RE = re.compile("local +("+ALPHA+") += +("+ALPHA+"):subclass")

FILES = [
    "Constants",
    "Object",
    "Widget",
    "Container",
    "Root",
    "LinearContainer",
    "Label",
    "Button",
    "TextField",
    "TextArea",
    "ScrollWidget",
    "ListBox",
    "ScrollBar",
]

def format_block(block):
    return "\n".join(block)

def get_by_name(name, arr):
    for item in arr:
        if item.name == name:
            return item

def write_contents(stream, classes):
    stream.write("## Contents\n\n")
    for c in classes:
        stream.write("- " + c.get_link() + "\n")
    stream.write("\n")

class LuaConstruct:
    def __init__(self, name, description):
        self.name = name
        self.description = description

    def get_heading(self):
        return self.name

    def get_link_target(self):
        x = self.get_heading().lower()
        x = x.replace(":","")
        x = x.replace(",","")
        x = x.replace(" ","-")
        return "#" + x
    
    def get_link(self):
        return "[{0}]({1})".format(self.get_heading(), self.get_link_target())

class LuaMember(LuaConstruct):
    def __init__(self, name, description, parent_class):
        super().__init__(name, description)
        self.parent_class = parent_class
        if self.parent_class:
            self.parent_class.members.append(self)

    def write(self, stream):
        stream.write("### "+self.name+"\n\n")
        if self.description:
            stream.write(self.description+"\n\n")

class LuaMethod(LuaMember):
    def __init__(self, name, description, parent_class, params):
        super().__init__(name, description, parent_class)
        self.params = params

    def get_description(self):
        if self.description:
            return self.description
        c = self.parent_class
        while c:
            m = get_by_name(self.name,c.members)
            if m and m.description:
                return m.description
            c = c.super_class
    
    def get_heading(self):
        x = [self.parent_class.name]
        if self.name != "init":
            x.extend((":",self.name))
        p = ", ".join(self.params)
        x.extend(("(",p,")"))
        return "".join(x)

    def write(self, stream):
        if not SHOW_UNDOC_OVERRIDES and self.name not in ALWAYS_SHOW and not self.description:
            c = self.parent_class.super_class
            found = False
            while c:
                if get_by_name(self.name, c.members):
                    return
                c = c.super_class
        stream.write("### "+self.get_heading()+"\n\n")
        desc = self.get_description()
        if desc:
            stream.write(desc+"\n\n")

class LuaClass(LuaConstruct):
    def __init__(self, name, description, super_class):
        super().__init__(name, description)
        self.members = []
        self.super_class = super_class

    def write_hierarchy(self, stream):
        stream.write("Inheritance: ");
        hierarchy = []
        c = self
        while c:
            hierarchy.append(c.get_link())
            c = c.super_class
        stream.write(" > ".join(hierarchy))
        stream.write("\n\n")

    def write(self, stream):
        stream.write("## "+self.name+"\n\n")
        if self.super_class:
            self.write_hierarchy(stream)
        if self.description:
            stream.write(self.description+"\n\n")
        for m in self.members:
            m.write(stream)


def read_file(filename, classes):
    block = []
    infile = open(filename,"r",encoding="utf-8")
    for line in infile.readlines():
        match = None
        if not line:
            pass
        elif line.startswith("--"):
            block.append(line[2:].strip())
        elif match := SIMPLE_RE.match(line):
            class_name = match.group(1)
            c = LuaClass(class_name, format_block(block), None)
            classes.append(c)
            block.clear()
        elif match := FIELD_RE.match(line):
            class_name = match.group(1)
            field_name = match.group(2)
            c = get_by_name(class_name, classes)
            f = LuaMember(field_name, format_block(block), c)
            block.clear()
        elif match := SUBCLASS_RE.match(line):
            class_name = match.group(1)
            super_name = match.group(2)
            c = LuaClass(class_name, format_block(block), get_by_name(super_name, classes))
            classes.append(c)
            block.clear()
        elif match := METHOD_RE.match(line):
            class_name = match.group(1)
            name = match.group(2)
            params = PARAM_RE.split(match.group(3))
            c = get_by_name(class_name, classes)
            m = LuaMethod(name, format_block(block), c, params)
            block.clear()
        else:
            block.clear()

classes = []
for file in FILES:
    read_file(file + ".lua", classes)
#outfile = open("docs.md","w",encoding="utf-8")
outfile = sys.stdout
outfile.write("# gui.lua\n\n")
write_contents(outfile, classes)
for c in classes:
    c.write(outfile)
#outfile.close()
