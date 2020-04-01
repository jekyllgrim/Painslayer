#!BPY

""" Registration info for Blender menus:
Name: 'Painkiller animations (.ani)...'
Blender: 244
Group: 'Export'
Tip: 'Export Painkiller animation file'
"""

__author__ = "Boksha"
__version__ = "1"

import Blender
import struct
import BPyMesh

class FileError(Exception):
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return repr(self.value)

class PKAnimBone:
	pass

class PKBoneFrame:
	pass

ctm = Blender.Mathutils.Matrix([1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1])
ictm = Blender.Mathutils.Matrix([1,0,0,0],[0,0,1,0],[0,-1,0,0],[0,0,0,1]).invert()

def export_anim(filename):
	print "Trying to export anim file now. " + filename
	try:
		editmode = Blender.Window.EditMode()
		if editmode: Blender.Window.EditMode(0)
		scn = Blender.Scene.GetCurrent()
		armatureobj = scn.objects.active
		armaturedata = armatureobj.getData()
		restbones = armatureobj.getData().bones
		action = armatureobj.getAction()
		iposdict = action.getAllChannelIpos()
		#animlength = Blender.Draw.PupIntInput("Last frame", 30, 1, 2000)
		firstframe = min(action.getFrameNumbers())
		lastframe = max(action.getFrameNumbers())
		animlength = lastframe - firstframe + 1
		animbonesdict = {}
		for restbone in restbones.values():
			animbonesdict[restbone.name]=PKAnimBone()
			if restbone.hasParent():
				animbonesdict[restbone.name].restmatrix = restbone.matrix['ARMATURESPACE'] * Blender.Mathutils.Matrix(restbone.parent.matrix['ARMATURESPACE']).invert()
			else:
				animbonesdict[restbone.name].restmatrix = restbone.matrix['ARMATURESPACE']
		numbones = 0
		for bonename in animbonesdict:
			if bonename in iposdict:
				numbones += 1
		
		file = open(filename, "wb")
		file.write("skel")
		file.write(struct.pack("<fI",animlength/24.0,numbones))
		for bonename in animbonesdict:
			if bonename in iposdict:
				file.write(struct.pack("<I", len(bonename)))
				file.write(bonename)
				file.write(struct.pack("<I", animlength))
				curvedict = {}
				for curve in iposdict[bonename]:
					curvedict[curve.name] = curve
				for curframenum in xrange(firstframe, lastframe + 1):
					time = curframenum - firstframe + 1
					file.write(struct.pack("<f", curframenum/24.0))
					rotquat = Blender.Mathutils.Quaternion([curvedict['QuatW'][time],curvedict['QuatX'][time],curvedict['QuatY'][time],curvedict['QuatZ'][time]])
					loc =  ctm * animbonesdict[bonename].restmatrix.rotationPart().invert().resize4x4() * Blender.Mathutils.Vector([curvedict['LocX'][time],curvedict['LocY'][time],curvedict['LocZ'][time],0])
					outmatrix = ctm * rotquat.toMatrix().resize4x4() * animbonesdict[bonename].restmatrix * ictm
					outmatrix[3] = outmatrix[3] + loc
					for i in xrange(0,4):
						for j in xrange(0,4):
							file.write(struct.pack("<f", outmatrix[i][j]))
		
		
		if editmode: Blender.Window.EditMode(1)
	except:
		print "Oh no!"
	else:
		print "Everything seems to be OK!"
	file.close()

def main():
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	if not armatureobj or armatureobj.type!='Armature' or not armatureobj.getAction():
		Blender.Draw.PupMenu('Select an armature with an action before exporting an animation.')
		return
	Blender.Window.FileSelector(export_anim, "Export")
	Blender.Redraw()

if __name__=='__main__':
	main()