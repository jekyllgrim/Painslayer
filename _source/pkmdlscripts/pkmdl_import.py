#!BPY

""" Registration info for Blender menus:
Name: 'Painkiller (.pkmdl)...'
Blender: 244
Group: 'Import'
Tip: 'Import PKMDL file'
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

class PKBone:
	pass

class PolySurf:
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
	if outstring[-1] != "\x00":
		raise FileError, "Broken string"
	return outstring[:-1]

def import_pkmdl(filename):
	print "Trying to import PKMDL file " + filename + " now."
	try:
		if filename[-6:] != ".pkmdl":
			raise FileError, "Wrong extension. If that's a PKMDL file, better rename it."
		file = open(filename, "rb")
		file.seek(0,2)
		realfilesize = file.tell()
		file.seek(0,0)
		#=============Start reading operations=============
		identifier, = read("<i", file)
		if identifier != 3:
			raise FileError, "Identifier wrong."
		internalfilenamestring = readstring(file)
		internalpathstring = readstring(file)
		animatedmeshstring = readstring(file)
		if animatedmeshstring != "AnimatedMesh":
			raise FileError, "AnimatedMesh string not correct."
		unknowndata = read("<4i", file)
		restoffilesize, restoffilestart = read("<ii", file)
		if realfilesize != restoffilesize + restoffilestart:
			raise FileError, "Filesize wrong."
		file.seek(restoffilestart,0)
		anotherpathstring = readstring(file)
		unknowndatastring = file.read(2)
		numbones, = read("<i", file)
		pkbones = []
		for i in xrange(numbones):
			pkbones.append(PKBone())
			pkbones[i].bonename = readstring(file)
			pkbones[i].transmatrix = read("<16f", file)
			pkbones[i].blendertransmatrix = ictm * Blender.Mathutils.Matrix(pkbones[i].transmatrix[0:4],pkbones[i].transmatrix[4:8],pkbones[i].transmatrix[8:12],pkbones[i].transmatrix[12:16]) * ctm
			pkbones[i].numchildren, = read("<B", file)
			for j in xrange(i):
				if pkbones[i-j-1].numchildren > 0:
					pkbones[i-j-1].numchildren = pkbones[i-j-1].numchildren - 1
					pkbones[i].parent = i-j-1
					break
			else:
				pkbones[i].parent = -1
				if i != 0:
					raise FileError, "Orphan bone found."
		numpolysurfs, = read("<i", file)
		polysurfs = []
		for i in range(numpolysurfs):
			polysurfs.append(PolySurf())
			polysurfs[i].surfname = readstring(file)
			unknowndata = read("<3i", file)
			numtexes, = read("<i", file)
			polysurfs[i].textures = []
			numtris = 0
			for j in range(numtexes):
				localtexname = readstring(file)
				localoffset, localnumtris = read("<2i", file)
				polysurfs[i].textures.append({"texname":localtexname, "offset":localoffset, "numtris":localnumtris, "matnum":j})
				numtris = numtris + localnumtris
			numvertinds, = read("<i", file)
			if numtris * 3 != numvertinds:
				raise FileError, "numtris *3 != numvertinds."
			polysurfs[i].faces = []
			for j in range(numtris):
				newface = read("<3H", file)
				polysurfs[i].faces.append([newface[0],newface[1],newface[2]])
			unknowndata, = read("<i", file)
			numverts, = read("<i", file)
			polysurfs[i].verts = []
			polysurfs[i].vertnormals = []
			polysurfs[i].vertuvs = []
			for j in xrange(numverts):
				newvert = read("<8f", file)
				polysurfs[i].verts.append([newvert[0],-newvert[2],newvert[1]])
				polysurfs[i].vertnormals.append([newvert[3],-newvert[5],newvert[4]])
				polysurfs[i].vertuvs.append([newvert[6],1 - newvert[7],0.0])
			unknowndata = read("<2i", file)
			numverts2, = read("<i", file)
			if numverts != numverts2:
				raise FileError, "num bonebinds doesn't agree with num verts."
			polysurfs[i].vertbonebinds = []
			for j in xrange(numverts):
				polysurfs[i].vertbonebinds.append([])
				numvertbones, = read("<i", file)
				for k in xrange(numvertbones):
					polysurfs[i].vertbonebinds[j].append(read("<Hf", file)) # first is the index, second is weight
		print "End of file:", file.tell()
		#==============End reading operations==============
		editmode = Blender.Window.EditMode()
		if editmode: Blender.Window.EditMode(0)
		scn = Blender.Scene.GetCurrent()
		armaturename = filename.rpartition("\\")[2].rpartition(".")[0]
		newarmaturedata = Blender.Armature.Armature(armaturename + "_arm_data")
		newarmaturedata.makeEditable()
		for pkbone in pkbones:
			pkbone.realbone = Blender.Armature.Editbone()
			pkbone.realbone.head = Blender.Mathutils.Vector(0,0,0)
			pkbone.realbone.tail = Blender.Mathutils.Vector(1,0,0)
			pkbone.realbone.options = []
			pkbone.realbone.name = pkbone.bonename
			pkbone.armspaceblendertransmatrix = pkbone.blendertransmatrix
			pkbone.realbone.matrix = pkbone.armspaceblendertransmatrix
			if pkbone.parent != -1:
				pkbone.realbone.parent = pkbones[pkbone.parent].realbone
				pkbone.armspaceblendertransmatrix = pkbone.blendertransmatrix * pkbones[pkbone.parent].armspaceblendertransmatrix
				pkbone.realbone.matrix = pkbone.armspaceblendertransmatrix
			newarmaturedata.bones[pkbone.bonename] = pkbone.realbone
		newarmatureobj = scn.objects.new(newarmaturedata, armaturename)
		newarmaturedata.update()
		
		bonenamelist = []
		for pkbone in pkbones:
			bonenamelist.append(pkbone.bonename)
		
		for surface in polysurfs:
			newmesh = Blender.Mesh.New(surface.surfname)
			newmesh.verts.extend(surface.verts)
			newmesh.faces.extend(surface.faces)
			for i in xrange(len(newmesh.verts)):
				newmesh.verts[i].no = Blender.Mathutils.Vector(surface.vertnormals[i][0],surface.vertnormals[i][1],surface.vertnormals[i][2])
			newmesh.faceUV = 1
			for tex in surface.textures:
				newmesh.materials += [None]
				for facenum in xrange(tex["offset"]/3,tex["offset"]/3 + tex["numtris"]):
					newmesh.faces[facenum].mat = tex["matnum"]
			for f in newmesh.faces:
				f.smooth = 1
				f.uv = [Blender.Mathutils.Vector(surface.vertuvs[f.verts[i].index][0] , surface.vertuvs[f.verts[i].index][1]) for i in range(3)]
			weightdictlist = [dict() for i in xrange(len(newmesh.verts))]
			for i in xrange(len(newmesh.verts)):
				for vertbonebind in surface.vertbonebinds[i]:
					weightdictlist[i][bonenamelist[vertbonebind[0]]] = vertbonebind[1]
			newobject = scn.objects.new(newmesh, surface.surfname)
			surface.meshdata = newmesh
			surface.obj = newobject
			BPyMesh.dict2MeshWeight(newmesh, bonenamelist, weightdictlist)
			armmod = newobject.modifiers.append(Blender.Modifier.Types.ARMATURE)
			armmod[Blender.Modifier.Settings.OBJECT] = newarmatureobj
		if editmode: Blender.Window.EditMode(1)
		scn.update(0)
		Blender.Window.RedrawAll()
		#==============Text file==============
		txt = Blender.Text.New(armaturename)
		for surface in polysurfs:
			txt.write(surface.obj.getName())
			txt.write(" = ")
			txt.write(surface.surfname)
			txt.write("\n")
			for tex in surface.textures:
				txt.write("\t" + tex["texname"] + "\n")
	except FileError, e:
		print "Broken file! " + e.value
	else:
		print "Everything seems to be OK!"
	file.close()

if __name__=='__main__':
	Blender.Window.FileSelector(import_pkmdl, "Import")
	#import_pkmdl("C:\PKMeuk\Samuraj.pkmdl")
	Blender.Redraw()