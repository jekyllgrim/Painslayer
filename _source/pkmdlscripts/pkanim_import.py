#!BPY

""" Registration info for Blender menus:
Name: 'Painkiller animations (.ani)...'
Blender: 244
Group: 'Import'
Tip: 'Import Painkiller animation file'
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

def read(format, file):
	size = struct.calcsize(format)
	localstring = file.read(size)
	if size != len(localstring):
		raise FileError, "File too short."
	return struct.unpack(format, localstring)
	
def readstring(file):
	stringlengthstring = file.read(4)
	if len(stringlengthstring) != 4:
		raise FileError, "File too short."
	stringlength, = struct.unpack("<i",stringlengthstring)
	outstring = file.read(stringlength)
	if len(outstring) != stringlength:
		raise FileError, "File too short."
	return outstring

def import_anim(filename):
	print "Trying to import anim file " + filename + " now."
	try:
		if filename[-4:] != ".ani":
			raise FileError, "Wrong extension. If that's an animation file, better rename it."
		file = open(filename, "rb")
		file.seek(0,2)
		realfilesize = file.tell()
		file.seek(0,0)
		#=============Start reading operations=============
		identifier = file.read(4)
		if identifier != "skel":
			raise FileError, "Identifier wrong."
		animlength, = read("<f", file)
		numbones, = read("<i", file)
		animbones = []
		for i in xrange(numbones):
			animbones.append(PKAnimBone())
			animbones[i].bonename = readstring(file)
			animbones[i].numframes, = read("<i", file)
			animbones[i].frames = []
			for j in xrange(animbones[i].numframes):
				animbones[i].frames.append(PKBoneFrame())
				animbones[i].frames[j].timestamp, = read("<f", file)
				localtransmatrix = read("<16f", file)
				animbones[i].frames[j].blendertransmatrix = ictm * Blender.Mathutils.Matrix(localtransmatrix[0:4],localtransmatrix[4:8],localtransmatrix[8:12],localtransmatrix[12:16]) * ctm
		
		print "End of file:", file.tell()
		#==============End reading operations==============
		editmode = Blender.Window.EditMode()
		if editmode: Blender.Window.EditMode(0)
		scn = Blender.Scene.GetCurrent()
		
		armatureobj = scn.objects.active
		armaturedata = armatureobj.getData()
		armbones = armaturedata.bones
		pose = armatureobj.getPose()
		posebones = pose.bones
		
		newactionname = filename.rpartition("\\")[2].rpartition(".")[0]
		action = Blender.Armature.NLA.NewAction(newactionname) 
		action.setActive(armatureobj)
		
		animlength = 0
		
		for bone in animbones:
			if (len(bone.frames) > animlength):
				animlength = len(bone.frames)
			try:
				bone.posebone = posebones[bone.bonename]
				bone.armbone = armbones[bone.bonename]
			except:
				print "Bone " + bone.bonename + " not found!"
				bone.posebone = None
				bone.armbone = None
			else:
				if bone.armbone.hasParent(): #I have no idea why this returns a 4x4 matrix (including translation) while the above returns a 3x3 matrix (i.e. rotation only)
					bone.localmatrix = bone.armbone.matrix['ARMATURESPACE'] * Blender.Mathutils.Matrix(bone.armbone.parent.matrix['ARMATURESPACE']).invert()
				else:
					bone.localmatrix = bone.armbone.matrix['ARMATURESPACE']
				bone.invlocalmatrix = Blender.Mathutils.Matrix(bone.localmatrix).invert()
		
		
		for curframenum in xrange(animlength):
			for bone in animbones:
				if bone.posebone and bone.armbone:
					bone.posebone.quat = (bone.frames[curframenum].blendertransmatrix * bone.invlocalmatrix).toQuat()
					bone.posebone.loc = bone.armbone.matrix['ARMATURESPACE'].rotationPart() * (bone.frames[curframenum].blendertransmatrix.translationPart() - bone.localmatrix.translationPart())
					bone.posebone.insertKey(armatureobj, curframenum + 1, [Blender.Object.Pose.LOC, Blender.Object.Pose.ROT], True)
		
		
		if editmode: Blender.Window.EditMode(1)
		scn.update(0)
		Blender.Window.RedrawAll()
	except FileError, e:
		print "Broken file! " + e.value
	else:
		print "Everything seems to be OK!"
	file.close()

def main():
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	
	if not armatureobj or armatureobj.type!='Armature':
		Blender.Draw.PupMenu('Select an armature before importing an animation.')
		return
	Blender.Window.FileSelector(import_anim, "Import")
	Blender.Redraw()

if __name__=='__main__':
	main()