#!BPY

""" Registration info for Blender menus:
Name: 'Clean Action Copy'
Blender: 244
Group: 'Misc'
Tip: 'Make a copy of an action for the cleaned up armature'
"""

__author__ = "Boksha"
__version__ = "1"

import Blender
import struct

#this really should be the standard quaternion product
def quatmult(q1, q2):
	return Blender.Mathutils.Quaternion([ q1[0] * q2[0] - q1[1] * q2[1] - q1[2] * q2[2] - q1[3] * q2[3], q1[0] * q2[1] + q1[1] * q2[0] + q1[2] * q2[3] - q1[3] * q2[2], q1[0] * q2[2] - q1[1] * q2[3] + q1[2] * q2[0] + q1[3] * q2[1], q1[0] * q2[3] + q1[1] * q2[2] - q1[2] * q2[1] + q1[3] * q2[0] ] )

def quatrotaxis(q1, q2):
	return Blender.Mathutils.Quaternion(q2 * q1.axis, q1.angle)


def getobjectfromscene(objname, scene):
	for object in scene.getChildren():
		if object.name == objname:
			return object
	return None

def newmain(armatureobj, cleanarmatureobj, newactionname):
	restbones = armatureobj.getData().bones
	pose = armatureobj.getPose()
	posebones = pose.bones
	clrestbones = cleanarmatureobj.getData().bones
	clpose = cleanarmatureobj.getPose()
	clposebones = clpose.bones
	action = armatureobj.getAction()
	acdic = Blender.Armature.NLA.GetActions()
	claction = 0
	for duhhh, dictaction in acdic.iteritems():
		if dictaction.getName() == newactionname:
			claction = dictaction
			for chname in claction.getChannelNames():
				claction.removeChannel(chname)
			claction.setActive(cleanarmatureobj)
	if not claction:
		#print "Actionnotfoundlol"
		claction = Blender.Armature.NLA.NewAction(newactionname)
		claction.setName(newactionname)
		claction.setActive(cleanarmatureobj)
	transformdict = {}
	for restbone in restbones.values():
		try:
			clrestbone = clrestbones[restbone.name]
		except:
			print "Bone " + restbone.name + " not found!"
		else:
			transform = quatmult(clrestbone.matrix['ARMATURESPACE'].toQuat().conjugate(), restbone.matrix['ARMATURESPACE'].toQuat())
			transformdict[restbone.name] = transform
	iposdict = action.getAllChannelIpos()
	cliposdict = claction.getAllChannelIpos()
	for channelname in iposdict:
		if channelname in transformdict:
			curvedict = {}
			quatframes = []
			locframes = []
			clposebone = clposebones[channelname]
			for curve in iposdict[channelname]:
				curvedict[curve.name] = curve
			for points in curvedict['QuatW'].bezierPoints:
				quatframes.append(points.pt[0])
			for points in curvedict['LocX'].bezierPoints:
				locframes.append(points.pt[0])
			for time in locframes:
				inttime = int(time)
				clposebone.loc = transformdict[channelname] * Blender.Mathutils.Vector([curvedict['LocX'][time],curvedict['LocY'][time],curvedict['LocZ'][time]])
				clposebone.insertKey(cleanarmatureobj, inttime, [Blender.Object.Pose.LOC], True)
			for time in quatframes:
				inttime = int(time)
				clposebone.quat = quatrotaxis(Blender.Mathutils.Quaternion([curvedict['QuatW'][time],curvedict['QuatX'][time],curvedict['QuatY'][time],curvedict['QuatZ'][time]]), transformdict[channelname])
				clposebone.insertKey(cleanarmatureobj, inttime, [Blender.Object.Pose.ROT], True)


def main():
	scn = Blender.Scene.GetCurrent()
	armatureobj = scn.objects.active
	cleanarmatureobj = getobjectfromscene("cl_" + armatureobj.name, scn)
	
	if not armatureobj or armatureobj.type!='Armature' or not cleanarmatureobj or cleanarmatureobj.type!='Armature':
		Blender.Draw.PupMenu('Select an armature with a clean copy before doing this.')
		return
	
	restbones = armatureobj.getData().bones
	pose = armatureobj.getPose()
	posebones = pose.bones
	clrestbones = cleanarmatureobj.getData().bones
	clpose = cleanarmatureobj.getPose()
	clposebones = clpose.bones
	action = armatureobj.getAction()
	claction = Blender.Armature.NLA.NewAction("cl_" + action.getName())
	claction.setName("cl_" + action.getName())
	claction.setActive(cleanarmatureobj)
	transformdict = {}
	for restbone in restbones.values():
		clrestbone = clrestbones[restbone.name]
		transform = quatmult(clrestbone.matrix['ARMATURESPACE'].toQuat().conjugate(), restbone.matrix['ARMATURESPACE'].toQuat())
		transformdict[restbone.name] = transform
	iposdict = action.getAllChannelIpos()
	cliposdict = claction.getAllChannelIpos()
	for channelname in iposdict:
		curvedict = {}
		quatframes = []
		locframes = []
		clposebone = clposebones[channelname]
		for curve in iposdict[channelname]:
			curvedict[curve.name] = curve
		for points in curvedict['QuatW'].bezierPoints:
			quatframes.append(points.pt[0])
		for points in curvedict['LocX'].bezierPoints:
			locframes.append(points.pt[0])
		for time in locframes:
			inttime = int(time)
			clposebone.loc = transformdict[channelname] * Blender.Mathutils.Vector([curvedict['LocX'][time],curvedict['LocY'][time],curvedict['LocZ'][time]])
			clposebone.insertKey(cleanarmatureobj, inttime, [Blender.Object.Pose.LOC], True)
		for time in quatframes:
			inttime = int(time)
			clposebone.quat = quatrotaxis(Blender.Mathutils.Quaternion([curvedict['QuatW'][time],curvedict['QuatX'][time],curvedict['QuatY'][time],curvedict['QuatZ'][time]]), transformdict[channelname])
			clposebone.insertKey(cleanarmatureobj, inttime, [Blender.Object.Pose.ROT], True)

#sooooooo basically we've got like, an action, which has channels for every bone, an Ipo is associated with
#the channel, the Ipo has IpoCurves which determine the value of a bone at a certain point, the IpoCurve
#has bezierPoints

g_armtargetcontrol = Blender.Draw.Create("")
g_armtargetanimcontrol = Blender.Draw.Create("cleananim")

def buttonevent(buttonid):
	if buttonid == 2:
		Blender.Draw.Exit()
	if buttonid == 3:
		global g_armtargetcontrol, g_armtargetanimcontrol
		scn = Blender.Scene.GetCurrent()
		t_armatureobj = scn.objects.active
		t_cleanarmatureobj = getobjectfromscene(g_armtargetcontrol.val, scn)
		
		if not t_armatureobj or t_armatureobj.type!='Armature' or not t_cleanarmatureobj or t_cleanarmatureobj.type!='Armature':
			Blender.Draw.PupMenu('Select an armature with a clean copy before doing this.')
		else:
			newmain(t_armatureobj, t_cleanarmatureobj, g_armtargetanimcontrol.val)

def inputevent(event, val):
    if event == Blender.Draw.ESCKEY:
        Blender.Draw.Exit()

def guidraw():
	global g_armtargetcontrol, g_armtargetanimcontrol
	y = 4
	g_armtargetcontrol = Blender.Draw.String("Target arm: ", 1, 24, y, 240, 20, g_armtargetcontrol.val, 31, "Enter the name of the armature the new animation will be for.")
	y += 24
	g_armtargetanimcontrol = Blender.Draw.String("Anim name: ", 1, 24, y, 240, 20, g_armtargetanimcontrol.val, 31, "Enter the name the new animation should have.")
	y += 24
	Blender.Draw.PushButton("Go", 3, 4, y, 60, 20, "Create anim now.")
	y += 24
	Blender.Draw.PushButton("Quit", 2, 4, y, 60, 20, "Quit!")

if __name__=='__main__':
	global g_armtargetcontrol
	scn = Blender.Scene.GetCurrent()
	t_armatureobj = scn.objects.active
	if t_armatureobj and t_armatureobj.name[0:3] == "cl_":
		g_armtargetcontrol.val = t_armatureobj.name[3:]
	elif t_armatureobj:
		g_armtargetcontrol.val = "cl_" + t_armatureobj.name

	Blender.Draw.Register(guidraw, inputevent, buttonevent)
	#main()