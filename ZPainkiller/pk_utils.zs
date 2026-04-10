class PK_Utils abstract {

	static clearscope bool IsVoodooDoll(PlayerPawn mo) {
		return !mo.player || !mo.player.mo || mo.player.mo != mo;
	}
	
	static clearscope int Sign (double i) {
		if (i >= 0)
			return 1;
		return -1;
	}
	
	static clearscope double LinearMap(double val, double source_min, double source_max, double out_min, double out_max, bool clampIt = false) {
		double d = (val - source_min) * (out_max - out_min) / (source_max - source_min) + out_min;
		if (clampit) {
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	// rise and fall: lower = smoother, higher = more rapid
	static clearscope double CubicBezierPulse(double frequency = TICRATE, int time = -1, double startVal = 1.0, double rise = 0.2, double fall = 0.8, double endVal = 1.0) {
		if (time < 0) time = level.mapTime;

		// Normalize time:
		double t = (time / frequency) - floor(time / frequency);

		return (1 - t) * (1 - t) * (1 - t) * startVal + 3 * (1 - t) * (1 - t) * t * rise + 3 * (1 - t) * t * t * fall + t * t * t * endVal;
	}
	
	//Checks which side of a linedef the actor is on:
	static clearscope int PointOnLineSide( Vector2 p, Line l ) {
		if ( !l ) return 0;
		return LevelLocals.PointOnLineSide(p, l);
    }

	// startPos: original position to operate around
	// angles: (angle, pitch, roll) of the desired actor. viewAngle/viewPitch/viewRoll can be added or used instead.
	// offset: desired relative offset as (forward/back, right/left, up/down)
	// isPosition: if TRUE, adds startpos to the final result.
	static clearscope Vector3 RelativeToGlobalOffset(Vector3 startpos, Vector3 angles, Vector3 offset, bool isPosition = true) {
		Quat dir = Quat.FromAngles(angles.x, angles.y, angles.z);
		Vector3 ofs = dir * (offset.x, -offset.y, offset.z);
		return isPosition? Level.Vec3offset(startpos, ofs) : ofs;
	}

	static clearscope vector2 GetLineNormal(vector2 ppos, Line lline) {
		vector2 linenormal;
		linenormal = (-lline.delta.y, lline.delta.x).unit();
		if (!PointOnLineSide(ppos, lline)) {
			linenormal *= -1;
		}
		
		return linenormal;
	}

	static play vector3, bool GetNormalFromPos(Actor source, double dist, double angle, double pitch, FLineTraceData normcheck) {
		if (!source) {
			if (pk_debugmessages)
				console.printf("GetNormalFromPos: source pointer is invalid");
			return (0,0,0), false;
		}

		source.LineTrace(angle, dist, pitch, TRF_THRUACTORS|TRF_NOSKY, data:normcheck);
		vector3 hitnormal = normcheck.HitLocation;

		hitnormal = -normcheck.HitDir;
		if (normcheck.HitType == TRACE_HitFloor) {
			if (normcheck.Hit3DFloor) 
				hitnormal = -normcheck.Hit3DFloor.top.Normal;
			else 
				hitnormal = normcheck.HitSector.floorplane.Normal;
			return hitnormal, true;
		}
		else if (normcheck.HitType == TRACE_HitCeiling)	{
			if (normcheck.Hit3DFloor) 
				hitnormal = -normcheck.Hit3DFloor.bottom.Normal;
			else 
				hitnormal = normcheck.HitSector.ceilingplane.Normal;
			return hitnormal, true;
		}
		else if (normcheck.HitType == TRACE_HitWall && normcheck.HitLine) {
			hitnormal.xy = PK_Utils.GetLineNormal(source.pos.xy, normcheck.HitLine);
			hitnormal.z = 0;
			return hitnormal, true;
		}

		//if (pk_debugmessages)
		//	console.printf("GetNormalFromPos: couldn't find a surface. Returning hitlocation.");
		return hitnormal, false;
	}

	// Obtains a normal vector from TraceResults
	// depending on what it hit:
	static clearscope Vector3 GetNormalFromTracer(TraceResults res) {
		Vector3 normal = (0,0,0);
		bool hit3DFloor = res.ffloor != null;
		switch(res.HitType) {
			case TRACE_HitFloor:
				normal = hit3DFloor? res.ffloor.top.normal : res.HitSector.floorplane.normal;
				break;
			case TRACE_HitCeiling:
				normal = hit3DFloor? res.ffloor.bottom.normal : res.HitSector.ceilingplane.normal;
				break;
			case TRACE_HitWall:
				normal.xy = (-res.HitLine.delta.y, res.HitLine.delta.x).Unit();
				if (res.Side == Line.front) {
					normal.xy *= -1;
				}
				break;
			case TRACE_HitActor:
				normal = -res.HitVector.Unit();
				break;
		}
		return normal;
	}

	static clearscope vector3 GetNormalFromTrace(FLineTraceData data) {
		Vector3 normal = (0,0,0);
		bool hit3DFloor = data.Hit3DFloor != null;
		switch(data.HitType) {
			case TRACE_HitFloor:
				normal = hit3DFloor? data.Hit3DFloor.top.normal : data.HitSector.floorplane.normal;
				break;
			case TRACE_HitCeiling:
				normal = hit3DFloor? data.Hit3DFloor.bottom.normal : data.HitSector.ceilingplane.normal;
				break;
			case TRACE_HitWall:
				normal.xy = (-data.HitLine.delta.y, data.HitLine.delta.x).Unit();
				if (data.LineSide == Line.front) {
					normal.xy *= -1;
				}
				break;
			case TRACE_HitActor:
				normal = -data.HitDir.Unit();
				break;
		}
		return normal;
	}

	static play void OrientActorToNormal(Actor thing, Vector3 normal) {
		normal = normal.Unit();
		if (!(normal.x ~== 0 && normal.y ~== 0)) {
			thing.angle = normal.Angle();
		}
		thing.pitch = -atan2(normal.z, normal.xy.Length()) + 90;
	}

	// Checks if given position is inside a 3D floor and if so,
	// returns it, and its top and bottom points:
	static clearscope F3DFloor, double, double Get3DFloorAt(Vector3 pos, Sector sec = null, int requiredFlags = 0, int forbiddenflags = 0) {
		// If sector is null, obtain sector from position.
		// Otherwise, the given sector will be checked
		// explicitly:
		if (!sec) {
			sec = level.PointInSector(pos.xy);
		}
		if (!sec) return null, 0, 0;

		F3DFloor ffloor;
		double top, bottom;
		for (int i = sec.Get3DFloorCount() - 1; i >= 0; i--) {
			ffloor = sec.Get3DFloor(i);
			if (!ffloor || !(ffloor.flags & F3DFloor.FF_EXISTS|requiredFlags) || (ffloor.flags & forbiddenflags)) {
				continue;
			}

			top = ffloor.top.ZAtPoint(pos.xy);
			bottom = ffloor.bottom.ZAtPoint(pos.xy);
			if (top >= pos.z && bottom <= pos.z) {
				return ffloor, top, bottom;
			}
		}
		return null, 0, 0;
	}

	// Checks if given position is inside a swimmable 3D floor;
	// if so, returns true, its top and bottom:
	static clearscope bool, double, double IsPointUnderwater(Vector3 pos, Sector sec = null) {
		if (!sec) {
			sec = level.PointInSector(pos.xy);
		}
		if (!sec) return false, 0, 0;

		let [ffloor, top, bottom] = Get3DFloorAt(pos, sec, requiredflags: F3DFloor.FF_SWIMMABLE, forbiddenflags: F3DFloor.FF_SOLID);
		if (ffloor) {
			return true, top, bottom;
		}
		return false, 0, 0;
	}

	static clearscope double, bool GetWaterHeight(Sector sec, vector3 pos) {
		if (sec.MoreFlags & Sector.SECMF_UNDERWATER) {
			return sec.ceilingPlane.ZAtPoint(pos.xy), true;
		}
		let hsec = sec.GetHeightSec();
		if (hsec) {
			double top = hsec.floorPlane.ZAtPoint(pos.xy);
			if ((hsec.MoreFlags & Sector.SECMF_UNDERWATERMASK)
				&& (pos.z <= top
				|| (!(hsec.MoreFlags & Sector.SECMF_FAKEFLOORONLY) && pos.z > hsec.ceilingPlane.ZAtPoint(pos.xy)))) {
				return top, true;
			}
		}
		else {
			let [isunderwater, top, bottom] = IsPointUnderwater(pos, sec);
			if (isunderwater) {
				return top, true;
			}
		}	
		return 0, false;
	}	
	
	// Find a random position around the specified position within the specified radius
	// (backported from Alice)
	static play vector3 FindRandomPosAround(vector3 actorpos, double rad = 512, double mindist = 16, double fovlimit = 0, double viewangle = 0, bool checkheight = false) {
		if (!level.IsPointInLevel(actorpos))
			return actorpos;
		
		vector3 finalpos = actorpos;
		double ofs = rad * 0.5;
		// 64 iterations should be enough...
		for (int i = 64; i > 0; i--) {
			// Pick a random position:
			vector3 ppos = actorpos + (frandom[frpa](-ofs, ofs), frandom[frpa](-ofs, ofs), 0);
			// Get the sector and distance to the point:
			let sec = Level.PointinSector(ppos.xy);
			double secfz = sec.NextLowestFloorAt(ppos.x, ppos.y, ppos.z);
			let diff = LevelLocals.Vec2Diff(actorpos.xy, ppos.xy);
			
			// Check FOV, if necessary:
			bool inFOV = true;
			if (fovlimit > 0) {
				double ang = atan2(diff.y, diff.x);
				if (Actor.AbsAngle(viewangle, ang) > fovlimit)
					inFOV = false;
			}			
			
			// We found suitable position if it's in the map,
			// in view (optionally), on the same elevation
			// (optionally) and not closer than necessary
			// (optionally):
			if (inFOV && Level.IsPointInLevel(ppos) && (!checkheight || secfz == actorpos.z) && (mindist <= 0 || diff.Length() >= mindist)) {
				finalpos = ppos;
				//console.printf("Final pos: %.1f,%.1f,%.1f", finalpos.x,finalpos.y,finalpos.z);
				break;
			}
		}
		return finalpos;
	}
	
	static play void CopyAppearance(Actor to, Actor from, bool style = true, bool size = false) {
		if (!to || !from)
			return;
		to.sprite = from.sprite;
		to.frame = from.frame;
		to.scale = from.scale;
		to.bSPRITEFLIP = from.bSPRITEFLIP;
		to.bXFLIP = from.bXFLIP;
		to.bYFLIP = from.bYFLIP;
		if (size)
			to.A_SetSize(from.height, from.radius);
		if (style) {
			to.A_SetRenderstyle(from.alpha, from.GetRenderstyle());
			to.translation = from.translation;
		}
	}

	static play state GetFinalStateInSequence(class<Actor> type, stateLabel label) {
		if (!type)
			return null;
		
		let t = GetDefaultByType(type);
		if (!t)
			return null;
		
		state targetstate = t.ResolveState(label);
		if (!targetstate)
			return null;
		
		while (targetstate && targetstate.nextstate && targetstate.tics != -1) {
			targetstate = targetstate.nextstate;
		}

		return targetstate;
	}
}

class PK_ValueInterpolator : Object
{
	double pk_current;
	double pk_minStep;
	double pk_maxStep;
	double pk_stepFactor;
	bool pk_isDynamic;

	static PK_ValueInterpolator Create(double startval, double stepFactor, double minstep, double maxstep, bool dynamic = false) {
		let v = new('PK_ValueInterpolator');
		v.pk_current = startval;
		v.pk_stepFactor = stepFactor;
		v.pk_minStep = minstep;
		v.pk_maxStep = maxstep;
		v.pk_isDynamic = dynamic;
		return v;
	}

	void Reset(double value) {
		pk_current = value;
	}

	void Update(double destvalue, double delta = 1.0) {
		double diff = pk_isDynamic? clamp(abs(destvalue - pk_current) * pk_stepFactor, pk_minStep, pk_maxStep) : pk_maxStep;
		diff *= delta;
		if (pk_current > destvalue) {
			pk_current = max(destvalue, pk_current - diff);
		}
		else {
			pk_current = min(destvalue, pk_current + diff);
		}
	}

	double GetValue() {
		return pk_current;
	}
}

class PK_CollisionTracer : LineTracer
{
	bool hitWater;
	EActorCollisionFlags actorflags;
	enum EActorCollisionFlags {
		AC_SOLID = 2,
		AC_SHOOTABLE = 4,
		AC_SOLIDSHOOTABLE = AC_SOLID|AC_SHOOTABLE,
	}

	static bool, Vector3, PK_CollisionTracer Detect(Vector3 start, Vector3 dir, Actor source = null, double maxdist = PLAYERMISSILERANGE, EActorCollisionFlags actorflags = AC_SOLID) {
		let tracer = new('PK_CollisionTracer');
		tracer.actorflags = actorflags;
		tracer.Trace(start,
			sec: source? source.cursector : level.PointInSector(start.xy),
			direction: dir.Unit(),
			maxdist: maxdist,
			traceFlags: TRACE_HitSky,
			wallmask: Line.ML_BLOCKEVERYTHING,
			ignore: source
		);
		
		let res = tracer.results;
		bool collided = res.HitType != TRACE_HitNone;
		Vector3 normal = PK_Utils.GetNormalFromTracer(res);
		return collided, normal, tracer;
	}

	override ETraceStatus TraceCallback() {
		switch (results.HitType) {
			case TRACE_HitActor:
				let act = results.HitActor;
				if (act &&
					(!(actorflags & AC_SOLID) || act.bSolid) &&
					(!(actorflags & AC_SHOOTABLE) || act.bShootable) ) {
					return TRACE_Stop;
				}
				break;
			case TRACE_HitWall:
			case TRACE_HasHitSky:
			case TRACE_HitFloor:
			case TRACE_HitCeiling:
				return TRACE_Stop;
				break;
		}

		return TRACE_Skip;
	}
}

class PK_WaterCollisionTracer : LineTracer {
	bool hitWater;

	static bool, Vector3, PK_WaterCollisionTracer Detect(Vector3 start, Vector3 dir, Actor source = null) {
		let tracer = new('PK_WaterCollisionTracer');
		tracer.Trace(start,
			sec: source? source.cursector : level.PointInSector(start.xy),
			direction: dir.Unit(),
			maxdist: PLAYERMISSILERANGE,
			0,
			ignore: source
		);
		
		return tracer.HitWater, tracer.results.HitPos, tracer;
	}

	override ETraceStatus TraceCallback() {
		// this should detect top of water consistently:
		if (results.crossedWater || results.crossed3DWater) {
			hitWater = true;
			// record water position in HitPos:
			results.HitPos = results.crossedWater? results.crossedWaterPos : results.crossed3DWaterPos;
			// expressly record the 3D floor when hitting it:
			if (results.crossed3DWater) {
				let [ffloor, top, bottom] = PK_Utils.Get3DFloorAt(results.HitPos, requiredflags: F3DFloor.FF_SWIMMABLE, forbiddenflags: F3DFloor.FF_SOLID);
				if (ffloor) {
					results.ffloor = ffloor;
					results.HitType = (top - results.HitPos.z < results.HitPos.z - bottom)? TRACE_HitFloor : TRACE_HitCeiling;
				}
			}
			// TODO: handling for non-3d water (if anything special is needed?
			return TRACE_Stop;
		}

		else if (results.HitType == TRACE_HitActor) {
			return TRACE_Skip;
		}

		// detect side of water:
		else if (results.HitType == TRACE_HitWall) {
			Line hitline = results.HitLine;
			// null line? should not happen, but just in case:
			if (!hitline) return TRACE_Skip;
			// get Sector on the other side from the one we hit:
			Sector otherSideSec = results.Side == Line.Front? hitline.backsector : hitline.frontsector;
			// no other side - this is one-sided line, so stop here:
			if (!otherSideSec) return TRACE_Stop;
			// iterate over 3d floors associated with that sector:
			if (PK_Utils.IsPointUnderwater(results.HitPos, otherSideSec)) {
				hitwater = true;
				return TRACE_Stop;
			}
			return (hitline.flags & Line.ML_BLOCKEVERYTHING)? TRACE_Stop : TRACE_Skip;
		}

		return TRACE_Skip;
	}
}

class PK_Prop_Shootable : Actor
{
	Default
	{
		+SOLID
		height 56;
		radius 16;
		+SHOOTABLE
		+NOBLOOD
		+BUDDHA
		+DONTTHRUST
	}

	States {
	Spawn:
		COLU A -1;
		stop;
	}
}

class PK_Prop_Monster : PK_Prop_Shootable
{
	Default
	{
		+ISMONSTER
		Translation "0:255=#[255,128,128]";
		-NOBLOOD
	}

	States {
	Spawn:
		POSS A -1;
		stop;
	}
}

class PK_Prop_MonsterFlying : PK_Prop_Monster
{
	Default
	{
		+NOGRAVITY
	}

	States {
	Spawn:
		HEAD A -1;
		stop;
	}
}