import sys
import re

# TODO: Add dynamic links in text
# TODO: Grab types from expect calls

SHOW_UNDOC_OVERRIDES = False
ALWAYS_SHOW = ["init"]

#LINK_REM_RE = re.compile("[:,]+")
PARAM_RE = re.compile("[, ]+")

def format_block(block):
    return "\n".join(block)

def get_by_name(name, arr):
    for item in arr:
        if item.name == name:
            return item

def write_contents(stream, classes):
    stream.write("## Contents\n\n")
    for c in classes:
        stream.write("- [{0}]({1})\n".format(c.get_heading(), c.get_link()))
    stream.write("\n")

class LuaConstruct:
    def __init__(self, name, description):
        self.name = name
        self.description = description

    def get_heading(self):
        return self.name

    def get_link(self):
        x = self.get_heading().lower()
        x = x.replace(":","")
        x = x.replace(",","")
        x = x.replace(" ","-")
        return "#" + x

class LuaMethod(LuaConstruct):
    def __init__(self, name, description, parent_class, params):
        super().__init__(name, description)
        #if name == "init":
        #    name = "new"
        self.params = params
        self.parent_class = parent_class
        if self.parent_class:
            self.parent_class.methods.append(self)

    def get_description(self):
        if self.description:
            return self.description
        c = self.parent_class
        while c:
            m = get_by_name(self.name,c.methods)
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
                if get_by_name(self.name, c.methods):
                    return
                c = c.super_class
        stream.write("### "+self.get_heading()+"\n\n")
        desc = self.get_description()
        if desc:
            stream.write(desc+"\n\n")

class LuaClass(LuaConstruct):
    def __init__(self, name, description, super_class):
        super().__init__(name, description)
        self.methods = []
        self.super_class = super_class

    def write_hierarchy(self, stream):
        stream.write("Inheritance: ");
        hierarchy = []
        c = self
        while c:
            hierarchy.append(c.name)
            c = c.super_class
        stream.write(" > ".join(hierarchy))
        stream.write("\n\n")

    def write(self, stream):
        stream.write("## "+self.name+"\n\n")
        if self.super_class:
            self.write_hierarchy(stream)
        if self.description:
            stream.write(self.description+"\n\n")
        for m in self.methods:
            m.write(stream)


def read_file(filename, classes):
    block = []
    infile = open(filename,"r",encoding="utf-8")
    for line in infile.readlines():
        if line.startswith("--"):
            block.append(line[2:].strip())
        elif line.startswith("local") and "= {" in line:
            class_name = line.split()[1]
            if class_name[0].isupper():
                c = LuaClass(class_name, format_block(block), None)
                classes.append(c)
                block.clear()
        elif line.startswith("local") and ":subclass" in line:
            tokens = line.split("=")
            class_name = tokens[0]
            
            #if class_name.startswith("local "):
            class_name = class_name[5:].strip()
            #else:
            #    print("WARNING: class " + class_name + " not declared local")
            
            super_name = tokens[1].strip().split(":")[0]
            c = LuaClass(class_name, format_block(block), get_by_name(super_name, classes))
            classes.append(c)
            block.clear()
        elif line.startswith("function "):
            full_name = line.split()[1]
            if "(" in full_name:
                full_name = full_name[:full_name.index("(")]
            params = PARAM_RE.split(line[line.index("(")+1:line.index(")")])
            name = full_name[full_name.index(":")+1:]
            class_name = full_name[:full_name.index(":")]
            c = get_by_name(class_name, classes)
            m = LuaMethod(name, format_block(block), c, params)
            block.clear()
        elif not line:
            pass
        else:
            block.clear()

classes = []
read_file("object.lua", classes)
read_file("gui.lua", classes)
#outfile = open("docs.md","w",encoding="utf-8")
outfile = sys.stdout
outfile.write("# gui.lua\n\n")
write_contents(outfile, classes)
for c in classes:
    c.write(outfile)
#outfile.close()