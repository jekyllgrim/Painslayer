#!BPY

""" Registration info for Blender menus:
Name: 'Painkiller (.pkmdl)...'
Blender: 244
Group: 'Export'
Tip: 'Export ye a PKMDL file'
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

def getobjectfromscene(objname, scene):
	for object in scene.objects:
		if object.name == objname:
			return object
	return None

#recursive function
def appendbone(pkbones, bone):
	pkbones.append(PKBone())
	pkbones[-1].realbone = bone
	if bone.hasChildren():
		for child in bone.children:
			appendbone(pkbones, child)

def getboneindex(pkbones, bonename):
	for i in range(len(pkbones)):
		if pkbones[i].realbone.name == bonename:
			return i
	return -1

def writestring(file, string):
	file.write(struct.pack("<I",len(string) + 1))
	file.write(string)
	file.write(struct.pack("<b",0))

def export_pkmdl(filename):
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	if not armatureobj or armatureobj.type!='Armature' or not Blender.Text.Get(armatureobj.getName()):
		Blender.Draw.PupMenu('Select an armature with corresponding text before exporting a model.')
		return
	armaturedata = armatureobj.getData()
	try:
		writefilename = filename.rpartition("\\")[2]
		writepathname = filename.rpartition("\\")[0]
		print "Trying to export model " + writefilename
		pkbones = []
		try:
			appendbone(pkbones, armaturedata.bones["ROOOT"])
		except:
			raise FileError, "No bone called ROOOT."
		txt = Blender.Text.Get(armatureobj.getName())
		polysurfaces = []
		for line in txt.asLines():
			if len(line) == 0:
				continue
			if line[0] != "\t":
				if line.count(" = ") != 0:
					splitted = line.split(" = ")
					polysurfobj = getobjectfromscene(splitted[0], scn)
					if polysurfobj != None and polysurfobj.type == 'Mesh':
						polysurfaces.append(PolySurf())
						polysurfaces[-1].object = polysurfobj
						polysurfaces[-1].name = splitted[1]
						polysurfaces[-1].data = polysurfobj.getData(False,True)
						polysurfaces[-1].texes = []
					else:
						raise FileError, "Object from text file not found or not a mesh object"
				else:
					raise FileError, "Broken line in text file"
			elif len(polysurfaces) != 0:
				polysurfaces[-1].texes.append({"name":line[1:]})
			else:
				raise FileError, "Text file starts with a texture line!"
		if len(polysurfaces) == 0:
			raise FileError, "No surfaces to export!"
		for surface in polysurfaces:
			if len(surface.texes) == 0:
				raise FileError, "Surface with no textures applied!"

		for surf in polysurfaces:
			if len(surf.data.materials) > len(surf.texes):
				raise FileError, ("Not enough materials applied to object " + polysurfobj.name)
			for i in range(len(surf.data.materials)):
				numfaceswithmaterial = 0
				for face in surf.data.faces:
					if face.mat == i:
						if len(face.verts) == 4:
							numfaceswithmaterial += 2
						else:
							numfaceswithmaterial += 1
				surf.texes[i]["numfaces"] = numfaceswithmaterial
			surf.vertbinds = []
			for vert in surf.data.verts:
				surf.vertbinds.append([])
			# variable naming wise, the next section is a bit messy
			# bonetovertbind is a vertex index and a weight, meaning how hard the bone it belongs to moves a vertex
			# vertbind is a bone index and a weight, meaning how hard a vertex it belongs to moves for that bone
			for groupname in surf.data.getVertGroupNames():
				boneindex = getboneindex(pkbones, groupname)
				if boneindex != -1:
					for bonetovertbind in surf.data.getVertsFromGroup(groupname, 1):
						surf.vertbinds[bonetovertbind [0]].append([boneindex, bonetovertbind[1]])
			for vertbind in surf.vertbinds:
				localabs = 0
				for bonebind in vertbind:
					localabs += bonebind[1]
				for bonebind in vertbind:
					bonebind[1] /= localabs
		#============ File operations! ============
		file = open(filename, "wb")
		file.write(struct.pack("<I",3))
		writestring(file, writefilename)
		writestring(file, writepathname)
		writestring(file, "AnimatedMesh")
		file.write(struct.pack("<4I",1,0,2,1)) # I have no idea what this means
		file.write(struct.pack("<I",0)) # oh dear; how big is this file going to be?
		file.flush() 
		pos = file.tell()
		file.write(struct.pack("<I",pos + 4))
		writestring(file, writepathname)
		file.write(struct.pack("<H",1))
		file.write(struct.pack("<I",len(pkbones)))
		for bone in pkbones:
			writestring(file, bone.realbone.name)
			localmatrix = 0
			if bone.realbone.hasParent():
				localmatrix = bone.realbone.matrix['ARMATURESPACE'] * Blender.Mathutils.Matrix(bone.realbone.parent.matrix['ARMATURESPACE']).invert()
			else:
				localmatrix = bone.realbone.matrix['ARMATURESPACE']
			localmatrix = ctm * localmatrix * ictm #coordinate transformation
			for i in xrange(0,4):
				for j in xrange(0,4):
					file.write(struct.pack("<f", localmatrix[i][j]))
			if bone.realbone.hasChildren():
				file.write(struct.pack("<b",len(bone.realbone.children)))
			else:
				file.write(struct.pack("<b",0))
		file.write(struct.pack("<I",len(polysurfaces)))
		for surf in polysurfaces:
			writestring(file, surf.name)
			file.write(struct.pack("<3I",0,0,0))
			file.write(struct.pack("<I",len(surf.texes)))
			offset = 0
			for tex in surf.texes[:len(surf.data.materials)]:  # we don't want more texture files than materials
				writestring(file, tex["name"])
				file.write(struct.pack("<I",offset))
				file.write(struct.pack("<I",tex["numfaces"]))
				offset += 3 * tex["numfaces"]
			file.write(struct.pack("<I",offset)) #obviously this will be the number of indices here
			uvs = {}  #dictionary so we can start adding keys wherever
			if surf.data.vertexUV:
				for vert in surf.data.verts:
					uvs[vert.index] = vert.uvco
			for i in range(len(surf.data.materials)):
				for face in surf.data.faces:
					if face.mat == i:
						if len(face.verts) == 3:
							file.write(struct.pack("<3H",face.verts[0].index,face.verts[1].index,face.verts[2].index))
						else:
							file.write(struct.pack("<3H",face.verts[0].index,face.verts[1].index,face.verts[2].index))
							file.write(struct.pack("<3H",face.verts[2].index,face.verts[3].index,face.verts[0].index))
						if surf.data.faceUV:
							for j in range(len(face.verts)):
								uvs[face.verts[j].index] = face.uv[j]
			file.write(struct.pack("<2I",0,len(surf.data.verts)))
			if len(uvs.keys()) > len(surf.data.verts):
				raise FileError, "Faces use more vertices than there are?!"
			no_uv_vertexwarning = True # do this only once
			for vert in surf.data.verts:
				file.write(struct.pack("<3f",vert.co[0],vert.co[2],-vert.co[1]))
				file.write(struct.pack("<3f",vert.no[0],vert.no[2],-vert.no[1]))
				if vert.index in uvs:
					file.write(struct.pack("<2f",uvs[vert.index][0],1 - uvs[vert.index][1]))
				elif no_uv_vertexwarning:
					print "Warning: one or more UVless vertices in " + surf.name
					no_uv_vertexwarning = False
					file.write(struct.pack("<2f",0,0))
			file.write(struct.pack("<3I",0,0,len(surf.data.verts)))
			for vertbind in surf.vertbinds:
				file.write(struct.pack("<I",len(vertbind)))
				for vertbonebind in vertbind:
					file.write(struct.pack("<Hf",vertbonebind[0],vertbonebind[1]))
		file.flush()
		endoffile = file.tell()
		file.seek(pos - 4)
		file.write(struct.pack("<I",endoffile - pos - 4))
	except FileError, e:
		print "Error: " + e.value
	else:
		print "Everything seems to be OK!"
	try:
		file.close()
	except:
		print "Error occurred before creating file."

def main():
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	if not armatureobj or armatureobj.type!='Armature' or not Blender.Text.Get(armatureobj.getName()):
		Blender.Draw.PupMenu('Select an armature with corresponding text before exporting a model.')
		return
	Blender.Window.FileSelector(export_pkmdl, "Export")
	Blender.Redraw()

if __name__=='__main__':
	main()