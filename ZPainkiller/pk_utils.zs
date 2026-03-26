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

		if (pk_debugmessages)
			console.printf("GetNormalFromPos: couldn't find a surface. Returning hitlocation.");
		return hitnormal, false;
	}

	// Obtains a normal vector from TraceResults
	// depending on what it hit:
	static clearscope Vector3 GetNormalFromTracer(TraceResults res) {
		Vector3 normal = -res.HitVector;
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
				normal.z = 0;
				break;
		}
		return normal;
	}

	static play double, bool GetWaterHeight(Sector sec, vector3 pos) {
		if (sec.MoreFlags & Sector.SECMF_UNDERWATER)
			return sec.ceilingPlane.ZAtPoint(pos.xy), true;
		else {
			let hsec = sec.GetHeightSec();
			if (hsec) {
				double top = hsec.floorPlane.ZAtPoint(pos.xy);
				if ((hsec.MoreFlags & Sector.SECMF_UNDERWATERMASK)
					&& (pos.z < top
					|| (!(hsec.MoreFlags & Sector.SECMF_FAKEFLOORONLY) && pos.z > hsec.ceilingPlane.ZAtPoint(pos.xy)))) {
					return top, true;
				}
			}
			else {
				for (int i = 0; i < sec.Get3DFloorCount(); ++i) {
					let ffloor = sec.Get3DFloor(i);
					if (!(ffloor.flags & F3DFloor.FF_EXISTS)
						|| (ffloor.flags & F3DFloor.FF_SOLID)
						|| !(ffloor.flags & F3DFloor.FF_SWIMMABLE)) {
						continue;
					}
						
					double top = ffloor.top.ZAtPoint(pos.xy);
					if (top > pos.z && ffloor.bottom.ZAtPoint(pos.xy) <= pos.z)
						return top, true;
				}
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
	static bool, Vector3, PK_CollisionTracer DetectFromTo(Vector3 start, Vector3 end, Actor source = null) {
		let tracer = new('PK_CollisionTracer');
		if (!tracer) {
			return false, (0,0,0), null;
		}

		Vector3 diff = level.Vec3Diff(start, end);
		tracer.Trace(start,
			sec: source? source.cursector : level.PointInSector(start.xy),
			direction: diff.Unit(),
			maxdist: diff.Length() + 1,
			traceFlags: TRACE_HitSky,
			wallmask: Line.ML_BLOCKEVERYTHING,
			ignore: source
		);

		let res = tracer.results;
		bool collided = res.HitType != TRACE_HitNone;
		Vector3 normal = PK_Utils.GetNormalFromTracer(res);

		return collided, normal, tracer;
	}

	static bool, Vector3, PK_CollisionTracer DetectAt(Vector3 start, Vector3 dir, Actor source = null) {
		let tracer = new('PK_CollisionTracer');
		if (!tracer) {
			return false, (0,0,0), null;
		}

		tracer.Trace(start,
			sec: source? source.cursector : level.PointInSector(start.xy),
			direction: dir.Unit(),
			maxdist: PLAYERMISSILERANGE,
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
		int res = TRACE_Skip;

		switch (results.HitType) {
		case TRACE_HitActor:
			if (results.HitActor && results.HitActor.bSolid) {
				res = TRACE_Stop;
			}
			break;
		case TRACE_HitWall:
		case TRACE_HasHitSky:
		case TRACE_HitFloor:
		case TRACE_HitCeiling:
			res = TRACE_Stop;
			break;
		}

		return res;
	}
}

class PK_Math abstract {
	int RoundInt(double value) {
		return int(round(value));
	}

	int CeilInt(double value) {
		return int(ceil(value));
	}

	int FloorInt(double value) {
		return int(floor(value));
	}
}