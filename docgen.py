import sys
import re
import argparse
import os

# TODO: Add dynamic links in text
# TODO: Grab types from expect calls

SHOW_UNDOC_OVERRIDES = False
ALWAYS_SHOW = ["init"]

ALPHA = "[a-zA-Z_]+"
TABLE = "{.*}"

PARAM_RE = re.compile("[, ]+")
SIMPLE_RE = re.compile("local +("+ALPHA+") += +"+TABLE)
FIELD_RE = re.compile("("+ALPHA+")\.("+ALPHA+") += +")
METHOD_RE = re.compile("function +("+ALPHA+"):("+ALPHA+") *\(([a-zA-Z_,. ]*)\)")
SUBCLASS_RE = re.compile("local +("+ALPHA+") += +("+ALPHA+"):subclass")

FILES = ["gui/"+x+".lua" for x in [
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
]]

def format_block(block):
    return "\n".join(block)

def get_by_name(name, arr):
    for item in arr:
        if item.name == name:
            return item

class LuaConstruct:
    def __init__(self, name, description):
        self.name = name
        self.description = description
        self.level = 2

    def get_heading(self):
        return self.name

    def get_link_target(self):
        x = self.get_heading().lower()
        for c in ":,()":
            x = x.replace(c,"")
        x = x.replace(" ","-")
        return "#" + x

    def get_description(self):
        return self.description
    
    def get_link(self):
        return "[{0}]({1})".format(self.get_heading(), self.get_link_target())

    def write_heading(self, stream):
        stream.write("#" * self.level + " " + self.get_heading() + "\n\n")

    def write_description(self, stream):
        desc = self.get_description()
        if desc:
            stream.write(desc+"\n\n")

    def write(self, stream):
        self.write_heading(stream)
        self.write_description(stream)

class LuaMember(LuaConstruct):
    def __init__(self, name, description, parent_class):
        super().__init__(name, description)
        self.parent_class = parent_class
        if self.parent_class:
            self.parent_class.members.append(self)
        self.level = 3

    def get_heading(self):
        return self.parent_class.name + "." + self.name

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
        super().write(stream)

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
        self.write_heading(stream)
        if self.super_class:
            self.write_hierarchy(stream)
        self.write_description(stream)
        for m in self.members:
            m.write(stream)

class Document:
    def __init__(self, name):
        self.name = name
        self.classes = []

    def read_file(self, filename):
        block = []
        infile = open(filename, "r", encoding="utf-8")
        for line in infile.readlines():
            match = None
            if not line:
                pass
            elif line.startswith("--"):
                block.append(line[2:].strip())
            elif match := SIMPLE_RE.match(line):
                class_name = match.group(1)
                c = LuaClass(class_name, format_block(block), None)
                self.classes.append(c)
                block.clear()
            elif match := FIELD_RE.match(line):
                class_name = match.group(1)
                field_name = match.group(2)
                c = get_by_name(class_name, self.classes)
                f = LuaMember(field_name, format_block(block), c)
                block.clear()
            elif match := SUBCLASS_RE.match(line):
                class_name = match.group(1)
                super_name = match.group(2)
                c = LuaClass(class_name, format_block(block), get_by_name(super_name, self.classes))
                self.classes.append(c)
                block.clear()
            elif match := METHOD_RE.match(line):
                class_name = match.group(1)
                name = match.group(2)
                params = PARAM_RE.split(match.group(3))
                c = get_by_name(class_name, self.classes)
                m = LuaMethod(name, format_block(block), c, params)
                block.clear()
            else:
                block.clear()
        infile.close()

    def write_contents(self, stream):
        stream.write("## Contents\n\n")
        for c in self.classes:
            stream.write("- " + c.get_link() + "\n")
        stream.write("\n")

    def write(self, stream):
        stream.write("# " + self.name + "\n\n")
        self.write_contents(stream)
        for c in self.classes:
            c.write(stream)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Markdown documentation for Lua modules")
    parser.add_argument('files', metavar='FILE', nargs="+", help="Lua files to read from")
    parser.add_argument('--out', metavar='OUT_FILE', help="File to write Markdown output into")
    parser.add_argument('--title', metavar='TITLE', help="Title of the documentation file", default=os.path.basename(os.getcwd()))
    args = parser.parse_args()

    doc = Document(args.title)
    for file in args.files:
        doc.read_file(os.path.normpath(file))

    out = sys.stdout
    if args.out:
        out = open(args.out, "w", encoding="utf-8")

    doc.write(out)

    if out != sys.stdout:
        out.close()
