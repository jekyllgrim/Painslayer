#!BPY

""" Registration info for Blender menus:
Name: 'Clean Armature Copy'
Blender: 244
Group: 'Misc'
Tip: 'Make a clean animatable copy of an armature'
"""

__author__ = "Boksha"
__version__ = "1"

import Blender
import struct

def duparm(armatureobj):
	editmode = Blender.Window.EditMode()
	if editmode: Blender.Window.EditMode(0)
	scn = Blender.Scene.GetCurrent()
	armaturename = "cl_" + armatureobj.getName()
	origarmdata = armatureobj.getData()
	newarmaturedata = Blender.Armature.Armature(armaturename + "_data")
	newarmaturedata.makeEditable()
	for origbone in origarmdata.bones.values():
		newbone = Blender.Armature.Editbone()
		newbone.name = origbone.name
		newbone.head = origbone.head['ARMATURESPACE']
		if len(origbone.children) == 1:
			newbone.tail = origbone.children[0].head['ARMATURESPACE']
		elif len(origbone.children) == 0:
			if origbone.hasParent():
				dir = origbone.head['ARMATURESPACE'] - origbone.parent.head['ARMATURESPACE']
				if dir.length > 2:
					dir = dir / dir.length * 2
				newbone.tail = origbone.head['ARMATURESPACE'] + dir
			else: # Who'd want to simplify this?
				newbone.tail = origbone.tail['ARMATURESPACE']
		else:
			newbone.tail = Blender.Mathutils.Vector(0,0,0)
			numchildren = len(origbone.children)
			for child in origbone.children:
				newbone.tail = newbone.tail + child.head['ARMATURESPACE'] * (1.0 / numchildren)
		newarmaturedata.bones[newbone.name] = newbone
	for origbone in origarmdata.bones.values():
		newbone = newarmaturedata.bones[origbone.name]
		newbone.options = []
		if origbone.hasParent():
			newbone.parent = newarmaturedata.bones[origbone.parent.name]
			if len(origbone.parent.children) == 1 and newbone.name != "root":
				newbone.options = [Blender.Armature.CONNECTED]
	scn.objects.new(newarmaturedata)
	newarmaturedata.update()
	
	
	if editmode: Blender.Window.EditMode(1)
	scn.update(0)
	Blender.Window.RedrawAll()

def main():
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	
	if not armatureobj or armatureobj.type!='Armature':
		Blender.Draw.PupMenu('Select an armature before importing an animation.')
		return
	duparm(armatureobj)

if __name__=='__main__':
	main()