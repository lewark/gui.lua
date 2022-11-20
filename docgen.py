import sys
import re

def format_block(block):
    return "\n".join(block)

def get_by_name(name, arr):
    for item in arr:
        if item.name == name:
            return item
            
class LuaMethod:
    def __init__(self, name, parent_class, params, description):
        #if name == "init":
        #    name = "new"
        self.name = name
        self.params = params
        self.parent_class = parent_class
        self.description = description
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
    def write(self, stream):
        stream.write("### "+self.parent_class.name+":"+self.name+"("+", ".join(self.params)+")\n\n")
        desc = self.get_description()
        if desc:
            stream.write(desc+"\n\n")

class LuaClass:
    def __init__(self, name, super_class, description):
        self.name = name
        self.description = description
        self.methods = []
        self.super_class = super_class
    def write(self, stream):
        stream.write("## "+self.name+"\n\n")
        if self.super_class:
            stream.write("Inherits from "+self.super_class.name+"\n\n")
        if self.description:
            stream.write(self.description+"\n\n")
        for m in self.methods:
            m.write(stream)


def read_file(filename, classes):
    block = []
    infile = open(filename,"r",encoding="utf-8")
    param_delimeter = re.compile("[, ]+")
    for line in infile.readlines():
        if line.startswith("--"):
            block.append(line[2:].strip())
        elif line.startswith("local") and "= {" in line:
            class_name = line.split()[1]
            if class_name[0].isupper():
                c = LuaClass(class_name, None, format_block(block))
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
            c = LuaClass(class_name, get_by_name(super_name, classes), format_block(block))
            classes.append(c)
            block.clear()
        elif line.startswith("function "):
            full_name = line.split()[1]
            if "(" in full_name:
                full_name = full_name[:full_name.index("(")]
            params = param_delimeter.split(line[line.index("(")+1:line.index(")")])
            name = full_name[full_name.index(":")+1:]
            class_name = full_name[:full_name.index(":")]
            c = get_by_name(class_name, classes)
            m = LuaMethod(name, c, params, format_block(block))
            block.clear()
        elif not line:
            pass
        else:
            block.clear()
            
classes = []
read_file("object.lua",classes)
read_file("gui.lua",classes)
#outfile = open("docs.md","w",encoding="utf-8")
outfile = sys.stdout
outfile.write("# gui.lua\n\n")
for c in classes:
    c.write(outfile)
#outfile.close()