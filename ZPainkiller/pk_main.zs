Mixin class PK_Math {	
	
	int Sign (double i) {
		if (i >= 0)
			return 1;
		return -1;
	}
	
	clearscope double LinearMap(double val, double o_min, double o_max, double n_min, double n_max) {
		return (val - o_min) * (n_max - n_min) / (o_max - o_min) + n_min;
	}

	clearscope vector2 GetLineNormal(vector2 ppos, Line lline) {
		vector2 linenormal;
		linenormal = (-lline.delta.y, lline.delta.x).unit();
		if (!PointOnLineSide(ppos, lline))
			linenormal *= -1;
		
		return linenormal;
	}
	
	//Utility functions by Marisa Kirisame
	
	//Checks which side of a lindef the actor is on:
	clearscope int PointOnLineSide( Vector2 p, Line l ) {
		if ( !l ) return 0;
		return (((p.y-l.v1.p.y)*l.delta.x+(l.v1.p.x-p.x)*l.delta.y) > double.epsilon);
    }
	
	//Returns -1 if the box (normally an actor's radius) intersects a linedef:
    int BoxOnLineSide( double top, double bottom, double left, double right, Line l ) {
		if ( !l ) return 0;
		int p1, p2;
		if ( l.delta.x == 0 ) {
			// ST_VERTICAL:
			p1 = (right < l.v1.p.x);
			p2 = (left < l.v1.p.x);
			if ( l.delta.y < 0 ) {
				p1 ^= 1;
				p2 ^= 1;
			}
		}
		else if ( l.delta.y == 0 )	{
			// ST_HORIZONTAL:
			p1 = (top > l.v1.p.y);
			p2 = (bottom > l.v1.p.y);
			if ( l.delta.x < 0 )		{
				p1 ^= 1;
				p2 ^= 1;
			}
		}
		else if ( (l.delta.x*l.delta.y) >= 0 )	{
			// ST_POSITIVE:
			p1 = PointOnLineSide((left,top),l);
			p2 = PointOnLineSide((right,bottom),l);
		}
		else {
			// ST_NEGATIVE:
			p1 = PointOnLineSide((right,top),l);
			p2 = PointOnLineSide((left,bottom),l);
		}
		return (p1==p2)?p1:-1;
	}
	
    bool CheckClippingLines(double size) {
		BlockLinesIterator it = BlockLinesIterator.Create(self, size);
		double tbox[4];
		// top, bottom, left, right
		tbox[0] = pos.y+size;
		tbox[1] = pos.y-size;
		tbox[2] = pos.x-size;
		tbox[3] = pos.x+size;
		while (it.Next()) {
		    let l = it.CurLine;
		    if ( !l ) continue;
		    if ( tbox[2] > l.bbox[3] ) continue;
		    if ( tbox[3] < l.bbox[2] ) continue;
		    if ( tbox[0] < l.bbox[1] ) continue;
		    if ( tbox[1] > l.bbox[0] ) continue;
		    if (BoxOnLineSide(tbox[0],tbox[1],tbox[2],tbox[3],l) == -1 ) 
				return true;
		}
		return false;
    }
	
	// Find a random position around the specified position within the specified radius
	// (backported from Alice)
	vector3 FindRandomPosAround(vector3 actorpos, double rad = 512, double mindist = 16, double fovlimit = 0, double viewangle = 0, bool checkheight = false)
	{
		if (!level.IsPointInLevel(actorpos))
			return actorpos;
		
		vector3 finalpos = actorpos;
		double ofs = rad * 0.5;
		// 64 iterations should be enough...
		for (int i = 64; i > 0; i--)
		{
			// Pick a random position:
			vector3 ppos = actorpos + (frandom[frpa](-ofs, ofs), frandom[frpa](-ofs, ofs), 0);
			// Get the sector and distance to the point:
			let sec = Level.PointinSector(ppos.xy);
			double secfz = sec.NextLowestFloorAt(ppos.x, ppos.y, ppos.z);
			let diff = LevelLocals.Vec2Diff(actorpos.xy, ppos.xy);
			
			// Check FOV, if necessary:
			bool inFOV = true;
			if (fovlimit > 0)
			{
				double ang = atan2(diff.y, diff.x);
				if (AbsAngle(viewangle, ang) > fovlimit)
					inFOV = false;
			}			
			
			// We found suitable position if it's in the map,
			// in view (optionally), on the same elevation
			// (optionally) and not closer than necessary
			// (optionally):
			if (inFOV && Level.IsPointInLevel(ppos) && (!checkheight || secfz == actorpos.z) && (mindist <= 0 || diff.Length() >= mindist))
			{
				finalpos = ppos;
				//console.printf("Final pos: %.1f,%.1f,%.1f", finalpos.x,finalpos.y,finalpos.z);
				break;
			}
		}
		return finalpos;
	}
	
	// This is an over-optimized version, no longer in use. Finding a random position
	// is most of the time more efficient than iterating through a grid.
	
	/*vector3 FindRandomPosAround(vector3 actorpos, double gridrad = 128, double step = 16) {
		if (!level.IsPointInLevel(actorpos))
			return actorpos;
		//because zscript doesn't support vector3 arrays I have to do this
		//UGH
		array <double> tposX;
		array <double> tposY;
		array <double> tposZ;
		//establish grid corners (top left and bottom right)
		vector3 startpos = actorpos - (gridrad, gridrad, 0);
		vector3 endpos = actorpos + (gridrad, gridrad, 0);
		//get sector of the actorpos:
		Sector actorsector = Level.PointInSector(actorpos.xy);
		//start at top left:
		vector3 curpos = startpos;
		while (true) {
			//save the coordinates if they're not in void and within this sector:
			if (Level.IsPointInLevel(curpos) && Level.PointInSector(curpos.xy) == actorsector) {
				//let itr = BlockLinesIterator.Create(self,
				tposX.Push(curpos.x);
				tposY.Push(curpos.y);
				tposZ.Push(curpos.z);
			}
			//move one step horizontally:
			curpos.x += step;
			//if we're too far, reset horizontal and move one step down:
			if (curpos.x > endpos.x) {
				curpos.x = startpos.x;
				curpos.y += step;
			}
			//if we're too far down too, stop iterating:
			if (curpos.y > endpos.y)
				break;
		}
		//in case array sizes are not equal for some reason:
		int foo = min(tposX.Size(), tposY.Size(), tposZ.Size()) - 1;
		//return a random position:
		int i = random[findpos](0,foo);
		vector3 finalpos = (tposX[i], tposY[i], tposZ[i]);
		return finalpos;
	}*/
	
	void CopyAppearance(Actor to, Actor from, bool style = true, bool size = false) {
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
}

mixin class PK_PlayerSightCheck {
	protected bool canSeePlayer;
	//a simple check that returns true if the actor is in any player's LOS:
	bool CheckPlayerSights() {
		for ( int i=0; i<MAXPLAYERS; i++ ) 	{
			if ( playeringame[i] && players[i].mo && CheckSight(players[i].mo) )
				return true;
		}
		return false;
	}
}

class PK_NullActor : Actor {
	Default {
		+NOINTERACTION
		+SYNCHRONIZED
		+DONTBLAST
		radius 1;
		height 1;
		FloatBobPhase 0;
	}
	override void PostBeginPlay() {
		Destroy();
	}
}

//A class that returns the name of a key bound to a specific action (thanks to 3saster):
class PK_Keybinds {
    static string getKeyboard(string keybind) {
        Array<int> keyInts;
        Bindings.GetAllKeysForCommand(keyInts, keybind);
		if (keyInts.Size() == 0)
			return Stringtable.Localize("$PKC_NOTBOUND");
        return Bindings.NameAllKeys(keyInts);
    }
}

mixin class PK_ParticleLevelCheck {
	protected transient CVar s_particles;
	
	enum ParticleLevels {
		PL_None,
		PL_Reduced,
		PL_Full,
	}
	
	int GetParticlesLevel() {
		if (!s_particles)
			s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
		
		return s_particles.GetInt();
	}
}

Class PK_BaseActor : Actor abstract {
	protected double pi;
	protected name bcolor;
	protected int age;
	mixin PK_Math;
	mixin PK_PlayerSightCheck;
	mixin PK_ParticleLevelCheck;

	static const string whiteSmokeTextures[] = {
		"SMO2A0",
		"SMO2B0",
		"SMO2C0",
		"SMO2D0",
		"SMO2E0",
		"SMO2F0"
	};

	static string GetRandomWhiteSmoke() {
		return PK_BaseActor.whiteSmokeTextures[random[smksfx](0, PK_BaseActor.whiteSmokeTextures.Size() -1)];
	}
	
	bool CheckLandingSize (double cradius = 0, bool checkceiling = false) {
		if (checkceiling) {
			double ceilingHeight = GetZAt (flags: GZF_CEILING);
			for (int i = 0; i < 360; i += 45) {
				double curHeight = GetZAt (cradius, 0, i, GZF_ABSOLUTEANG | GZF_CEILING);
				if (curHeight > ceilingz)
					return true;
			}
		}
		else {
			double floorHeight = GetZAt ();
			for (int i = 0; i < 360; i += 45) {
				double curHeight = GetZAt (cradius, 0, i, GZF_ABSOLUTEANG);
				if (curHeight < floorz)
					return true;
			}
		}
		return false;
	}

	static state GetFinalStateInSequence(class<Actor> type, stateLabel label) {
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
	
	static const string PK_LiquidFlats[] = { 
		"BLOOD", "LAVA", "NUKAGE", "SLIME01", "SLIME02", "SLIME03", "SLIME04", "SLIME05", "SLIME06", "SLIME07", "SLIME08", "BDT_"
	};
	
	//water check by Boondorl
	double GetWaterTop()
	{
		if (CurSector.MoreFlags & Sector.SECMF_UNDERWATER)
			return CurSector.ceilingPlane.ZAtPoint(pos.xy);
		else
		{
			let hsec = CurSector.GetHeightSec();
			if (hsec)
			{
				double top = hsec.floorPlane.ZAtPoint(pos.xy);
				if ((hsec.MoreFlags & Sector.SECMF_UNDERWATERMASK)
					&& (pos.z < top
					|| (!(hsec.MoreFlags & Sector.SECMF_FAKEFLOORONLY) && pos.z > hsec.ceilingPlane.ZAtPoint(pos.xy))))
				{
					return top;
				}
			}
			else
			{
				for (int i = 0; i < CurSector.Get3DFloorCount(); ++i)
				{
					let ffloor = CurSector.Get3DFloor(i);
					if (!(ffloor.flags & F3DFloor.FF_EXISTS)
						|| (ffloor.flags & F3DFloor.FF_SOLID)
						|| !(ffloor.flags & F3DFloor.FF_SWIMMABLE))
					{
						continue;
					}
						
					double top = ffloor.top.ZAtPoint(pos.xy);
					if (top > pos.z && ffloor.bottom.ZAtPoint(pos.xy) <= pos.z)
						return top;
				}
			}
		}			
		return 0;
	}	
	
	bool CheckLiquidFlat() {
		if (!self)
			return false;
		if (GetFloorTerrain().isLiquid == true)
			return true;
		string tex = TexMan.GetName(floorpic);
		for (int i = 0; i < PK_LiquidFlats.Size(); i++) {
			if (tex.IndexOf(PK_LiquidFlats[i]) >= 0 )
				return true;
		}
		return false;
	}	
	
	override void BeginPlay() {
		super.BeginPlay();
		pi = 3.141592653589793;
	}	
	
	override void Tick() {
		super.Tick();
		if (!isFrozen())
			age++;
	}
	
	/*	Make the given actor invisible, have it drop its items
		and call A_BossDeath if necessary.
		If 'remove' is true, also destroy it; otherwise it's implied
		that it's queued for destruction to be handled later by
		the caller.
	*/	
	static void KillActorSilent(actor victim, bool remove = true) {
		if (!victim)
			return;
		//hide the corpse
		victim.A_SetRenderstyle(victim.alpha, Style_None);
		//drop the items
		victim.A_NoBlocking();
		//call A_BossDeath if necessary
		if (victim.bBOSS || victim.bBOSSDEATH)
			victim.A_BossDeath();
		if (pk_debugmessages) {
			console.printf("%s silent-killed | renderstyle %d | pos (%.1f, %.1f, %.1f)", victim.GetTag(), victim.GetRenderstyle(), victim.pos.x, victim.pos.y, victim.pos.z);
		}
		if (remove && !victim.player) {			
			victim.Destroy();
		}
	}
	
	States {
	Loadsprites:
		LENR A 0;
		LENB A 0;
		LENG A 0;
		LENY A 0;
		LENC A 0;
		LENS AB 0;
		SPRK ABC 0;
		SMO2 ABCDEF 0;
		stop;
	}
}
	
Class PK_SmallDebris : PK_BaseActor abstract {
	protected bool landed;			//true if object landed on the floor (or ceiling, if can stick to ceiling)
	protected bool moving; 		//marks actor as moving; sets to true automatically if actor spawns with non-zero vel
	protected bool onceiling;		//true if object is stuck on ceiling (must be combined with landed)
	protected bool onliquid;
	protected int bounces;
	protected double Voffset;		//small randomized plane offset to reduce z-fighting for blood pools and such
	double wrot;					//gets added to roll to imitate rotation during flying
	double dbrake; 				//how quickly to reduce horizontal speed of "landed" particles to simulate sliding along the floor
	property dbrake : dbrake;	
	protected bool removeonfall;	//if true, object is removed when reaching the floor
	property removeonfall : removeonfall;
	protected bool removeonliquid;
	property removeonliquid : removeonliquid;
	protected double liquidheight;
	property liquidheight : liquidheight;
	protected bool hitceiling;		//if true, react to reaching the ceiling (otherwise ignore)
	property hitceiling : hitceiling;
	
	protected vector2 wallnormal;
	protected vector3 wallpos;
	protected line wall;
	
	protected state d_spawn;
	protected state d_death;
	protected state d_ceiling;
	protected state d_wall;
	protected state d_liquid;
	
	protected sound liquidsound;
	property liquidsound : liquidsound;
	
	Default {
		+MOVEWITHSECTOR
		+NOBLOCKMAP
		+SYNCHRONIZED
		+DONTBLAST
		FloatBobPhase 0;
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		+INTERPOLATEANGLES
		-ALLOWPARTICLES
		renderstyle 'Translucent';
		alpha 1.0;
		radius 1;
		height 1;
		mass 1;
		gravity 0.8;
		PK_SmallDebris.liquidsound "";
		PK_SmallDebris.removeonfall false;
		PK_SmallDebris.removeonliquid true;
		PK_SmallDebris.dbrake 0;
		PK_SmallDebris.hitceiling false;
		bouncecount 8;
	}
	
	override void BeginPlay() {
		super.BeginPlay();		
		ChangeStatnum(110);
		d_spawn = FindState("Spawn");
		d_death = FindState("Death");
		d_ceiling = FindState("HitCeiling");
		d_wall = FindState("HitWall");
		d_liquid = FindState("DeathLiquid");
	}

	//a cheaper version of SetOrigin that also doesn't update floorz/ceilingz (because they're updated manually in Tick) - thanks phantombeta
    void PK_SetOrigin (Vector3 newPos) {
        LinkContext ctx;
        UnlinkFromWorld (ctx);
        SetXYZ (newPos);
        LinkToWorld (ctx);
    }

	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!level.IsPointInLevel(pos)) {
			destroy();
			return;
		}
		if (vel.length() != 0 || gravity != 0) //mark as movable if given any non-zero velocity or gravity
			moving = true;
	}

	//a chad tick override that skips Actor's super.tick!
	override void Tick() {
		if (alpha < 0){
			destroy();
			return;
		}
		if (isFrozen())
			return;
		//animation:
		if (tics != -1) {
			if (tics > 0) 
				tics--;
			while (!tics) {
				if (!SetState (CurState.NextState)) // mobj was removed
					return;
			}
		}
		/*
		Perform collision for the objects that don't have NOINTERACTION and are older than 1 tic.
		The latter helps to avoid collision at the moment of spawning.
		*/
		if (!bNOINTERACTION && GetAge() > 1) {
			UpdateWaterLevel(); //manually update waterlevel
			FindFloorCeiling(); //manually update floorz/ceilingz
			if (d_spawn && InStateSequence(curstate,d_spawn)) {
				//check if hit ceiling: (if hitceiling is true)
				if (hitceiling && pos.z >= ceilingz - 10 && vel.z > 0) {
					PK_Hitceiling();
					if (!self)
						return;
				}
				//check if hit wall:
				else if (pos.z > floorz+Voffset) {
					A_FaceMovementDirection(flags:FMDF_NOPITCH);
					FLineTraceData hit;
					LineTrace(angle,radius+16,1,flags:TRF_THRUACTORS|TRF_NOSKY,data:hit);
					if (hit.HitLine && hit.hittype == TRACE_HITWALL) {
						wall = hit.HitLine;
						wallnormal = GetLineNormal(pos.xy, wall);
						wallpos = hit.HitLocation;
						//if the actor can bounce off walls and isn't too close to the floor, it'll bounce:
						if (bBOUNCEONWALLS){		
							if (wallbouncesound)
								A_StartSound(wallbouncesound);
							else if (bouncesound)
								A_StartSound(bouncesound);								
							wrot *= -1;
							vel = vel - (wallnormal,0) * 2 * (vel dot (wallnormal,0));
							if (wallbouncefactor)
								vel *= wallbouncefactor;
							else
								vel *= bouncefactor;
							A_FaceMovementDirection();
						}
						//otherwise stop and call hitwall
						else if (vel.x != 0 || vel.y != 0) {
							SetOrigin(wallpos + wallnormal * radius,true);
							A_Stop();
							//console.printf("%s sticking to wall at %d:%d:%d",GetClassName(),pos.x,pos.y,pos.z);
							PK_HitWall();
						}
					}
					if (!self)
						return;
				}
			}
			//stick to surface if already landed:
			if (landed) {
				//stick to ceiling if on ceiling
				if (onceiling)
					SetZ(ceilingz-Voffset);
				//otherwise stick to floor (and, if necessary, slide on it)
				else {
					double i = floorz+Voffset;
					if (pos.z > i)
						landed = false;
					else {
						SetZ(i);
						//do the slide if friction allows it (as defined by dbrake property)
						if (dbrake > 0) {
							if (!(vel.x ~== 0) || !(vel.y ~== 0)) {
								vel.xy *= dbrake;
								A_FaceMovementDirection(flags:FMDF_NOPITCH);
								FLineTraceData hit;
								LineTrace(angle,12,0,flags:TRF_THRUACTORS|TRF_NOSKY,offsetz:1,data:hit);
								if (hit.HitLine && hit.hittype == TRACE_HITWALL /*&& (!hit.HitLine || hit.HitLine.flags & hit.Hitline.ML_BLOCKING || hit.LinePart == Side.Bottom)*/) {
									//console.printf("%s hit wall at %d:%d:%f | pitch: %f",GetClassName(),hit.HitLocation.x,hit.HitLocation.y,hit.HitLocation.z,pitch);
									wallpos = hit.HitLocation;
									wallnormal = GetLineNormal(wallpos.xy, hit.Hitline);
									vel = vel - (wallnormal,0) * 2 * (vel dot (wallnormal,0));
									vel *= bouncefactor * 0.5;
									A_FaceMovementDirection(flags:FMDF_NOPITCH);
								}
							}
						}
						else
							vel.xy = (0,0);
					}
				}
			}
			//simulate falling if not yet landed:
			else {
				if (pos.z <= floorz+Voffset) {
					bool liquid = CheckLiquidFlat();
					if (bounces >= bouncecount || !bBOUNCEONFLOORS || liquid || abs(vel.z) <= 2) {
						if (liquid)
							onliquid = true;
						PK_HitFloor();	
					}
					else {
						SetZ(floorz+Voffset);
						vel.z *= -bouncefactor;
						bounces++;
						if (bouncesound)
							A_StartSound(bouncesound);
					}
					if (!self)
						return;
				}
				else if (!bNOGRAVITY) 
					vel.z -= gravity;				
				
				if (waterlevel >= 2) {
					vel.z = Clamp(vel.z * 0.8, -gravity / 2., abs(vel.z));
					vel.xy *= 0.85;
				}
			}
		}
		//finally, manually move the object:
		if (moving) {
			//this cheaper version won't automatically update floorz/ceilingz, which is good for objects like smoke that don't interact with geometry
			PK_SetOrigin(level.vec3offset(pos, vel));
		}
	}

	virtual void PK_HitFloor() {			//hit floor if close enough
		if (removeonfall) {
			destroy();
			return;
		}
		if (floorpic == skyflatnum) { 
			destroy();
			return;
		}
		landed = true;
		vel.z = 0;
		if (Voffset < 0)
			Voffset = 0;
		//landed on liquid:
		if (onliquid) {
			A_Stop();
			A_StartSound(liquidsound,slot:CHAN_AUTO,flags:CHANF_DEFAULT,1.0,attenuation:3);
			if (removeonliquid) {
				destroy();
				return;
			}
			/*
			if it's a flat (non-3d-floor) liquid, we'll visually sink the object into it a bit
			either by 50% of its height or by the value of its liquidheight property
			*/
			floorclip = (liquidheight == 0) ? (height * 0.5) : liquidheight;
			//enter "DeathLiquid" state if present, otherwise enter "Death"
			if (d_liquid)
				SetState(d_liquid);
			else if (d_death)
				SetState(d_death);
		}
		//otherwise enter "Death" state if present
		else if (d_death)
			SetState(d_death);
		SetZ(floorz+Voffset);
	}

	//stick to ceiling and enter "HitCeiling" state if present:
	virtual void PK_Hitceiling() {
		if (ceilingpic == skyflatnum) {
			destroy();
			return;
		}
		SetZ(ceilingz-Voffset);
		if (d_ceiling)
			SetState(d_ceiling);
	}
	//enter "HitWall" state if present:
	virtual void PK_HitWall() {
		if (d_wall)
			SetState(d_wall);	
	}

	states {
	Spawn:
		#### # -1;
		stop;
	}
}

Class PK_RicochetSpark : PK_SmallDebris {
	Default {
		PK_SmallDebris.dbrake 0.8;
		alpha 1.5;
		radius 3;
		height 3;
		scale 0.035;
		+BRIGHT
	}
	override Void PostBeginPlay() {
		if (waterlevel > 1) {
			destroy();
			return;
		}
		super.PostbeginPlay();
	}
	states {
	Spawn:
		SPRK # 1 {
			A_FadeOut(0.03);
			scale *= 0.95;
		}
		loop;
	}
}

Class PK_RandomDebris : PK_SmallDebris {
	name spritename;
	double rotstep;
	property rotation : wrot;
	property spritename : spritename;
	bool randomroll;
	property randomroll : randomroll;
	Default {
		PK_RandomDebris.spritename 'PDEB';
		PK_SmallDebris.removeonliquid true;
		PK_SmallDebris.dbrake 0.8;
		PK_RandomDebris.rotation 17;
		PK_RandomDebris.randomroll true;
		+BOUNCEONWALLS
		+ROLLCENTER
		wallbouncefactor 0.5;
		height 8;
		stencilcolor "101010";
		scale 0.2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();		
		if (randomroll)
			roll = random[sfx](0,359);
		wrot = (wrot * frandom[sfx](0.8,1.2))*randompick[sfx](-1,1);
		scale *= frandom[sfx](0.75,1.2);
		bSPRITEFLIP = randompick[sfx](0,1);
		sprite = GetSpriteIndex(spritename);
		if (spritename == 'PDEB')
			frame = random[sfx](0,5);
	}
	states {
	spawn:
		#### # 1 {			
			roll+=wrot;
			wrot *= 0.99;
		}
		loop;
	Death:
		#### # 0 { 
			roll = 180 * randompick[sfx](-1,1) + frandom[sfx](-3,3);
		}
		#### # 1 {
			A_FadeOut(0.03);
			scale *= 0.95;
		}
		wait;
	cache:
		PDEB ABCDEF 0;
		PFLD ABCDEF 0;
	}
}
		

Class PK_Tracer : FastProjectile {
	Default {
		-ACTIVATEIMPACT;
		-ACTIVATEPCROSS;
		+NOTELEPORT;
		+BLOODLESSIMPACT;
		alpha 0.75;
		renderstyle "add";
		speed 64;
		radius 4;
		height 4;
		seesound "null";
		deathsound "null";
	}    
	//whizz sound snippet by phantombeta
	override void Tick () {
		Super.Tick ();
		if (level.isFrozen())
			return;
		if (!playeringame [consolePlayer])
			return;		
		let curCamera = players [consolePlayer].camera;
		if (!curCamera) // If the player's "camera" variable is null, set it to their PlayerPawn
			curCamera = players [consolePlayer].mo;
		if (!curCamera) // If the player's PlayerPawn is null too, just stop trying
			return;
		if (CheckIfCloser (curCamera, 192))
			A_StartSound("weapons/tracerwhizz",CHAN_AUTO,attenuation:8);
	}
	states {
		Spawn:
			TNT1 A 2 NoDelay {
				vel = vel.unit() * 256;
			}
			M000 A 1 bright;
			wait;
		Xdeath:
			TNT1 A 1;
			stop;
		Death:
			TNT1 A 1 {
				//if (frandom(0.0,1.0) > 0.8)
				//	A_SpawnProjectile("RicochetBullet",0,0,random(0,360),2,random(-40,40));
			}
			stop;
	}
}
	
Class PK_BaseFlare : PK_SmallDebris {
	protected state mdeath;
	protected state mxdeath;
	color fcolor;
	property fcolor : fcolor;
	bool style;
	property style : style;
	double fscale;		//scale; used when it's set externally from the spawner
	double falpha;		//alpha; used when it's set externally from the spawner
	double fade;
	property fadefactor : fade;
	double shrink;
	property shrinkfactor : shrink;
	Default {
		+BRIGHT
		+NOINTERACTION
		renderstyle 'AddShaded';
		alpha 0.4;
		scale 0.4;
		gravity 0;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (master) {
			mdeath = master.FindState("Death");
			mxdeath = master.FindState("XDeath");
		}
		SetColor();
	}
	virtual void SetColor() { //fcolor is meant to be set by the actor that spawns the flare
		if (GetRenderstyle() == Style_AddShaded || GetRenderstyle() == Style_Shaded) {
			if (!fcolor) {
				destroy();
				return;
			}				
			else {
				SetShade(fcolor);
			}
		}
		//frame = style;
		if (fscale != 0)
			A_SetScale(fscale);
		if (falpha != 0)
			alpha = falpha;
	}
	states {
	Spawn:
		FLAR A 1 {
			if (fade != 0)
				A_FadeOut(fade);
			if (shrink != 0) {
				scale *= shrink;
			}
		}
		loop;
	}
}

Class PK_ProjFlare : PK_BaseFlare {
	double xoffset;
	Default {
		PK_BaseFlare.fcolor "FF0000";
		alpha 0.8;
		scale 0.11;
	}
	override void Tick() {
		super.Tick();
		if (!master) {
			destroy();
			return;
		}
		if (isFrozen())
			return;
		Warp(master,xoffset,0,0,flags:WARPF_INTERPOLATE);
		/*if (master.InstateSequence(master.curstate,mdeath) || master.InstateSequence(master.curstate,mxdeath)) {
			Destroy();
			return;
		}*/
	}
}

Class PK_BaseSmoke : PK_SmallDebris abstract {
	Default {
		+NOINTERACTION
		gravity 0;
		renderstyle 'Translucent';
		alpha 0.3;
		scale 0.1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (waterlevel > 1) {
			self.destroy();
			return;
		}
		scale.x *= frandom[sfx](0.8,1.2);
		scale.y *= frandom[sfx](0.8,1.2);
		bSPRITEFLIP = randompick[sfx](0,1);
		roll = random[sfx](0,359);
	}
	states	{
	Spawn:
		#### # 1 {
			A_Fadeout(0.01);
		}
		loop;
	}
}

//medium-sized dark smoke that raises over burnt bodies
class PK_BlackSmoke : PK_BaseSmoke {
	Default {
		alpha 0.3;
		scale 0.3;
	}
	override void Tick() {
		if (isFrozen())
			return;
		vel *= 0.99;
		super.Tick();
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll += frandom[sfx](-40,40);
	}
	states	{
	Spawn:
		SMOK ABCDEFGHIJKLMNOPQ 2 NoDelay {
			A_FadeOut(0.01);
		}
		SMOK R 2 {
			A_FadeOut(0.005);
			scale *= 0.99;
		}
		wait;
	}
}

class PK_WhiteSmoke : PK_BaseSmoke {
	double fade;
	Default {
		+ROLLCENTER
		scale 0.1;
		renderstyle 'Translucent';
		alpha 0.5;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		scale *= frandom[sfx](0.9,1.1);
		wrot = (random[sfx](2,5)*randompick[sfx](-1,1));
		frame = random[sfx](0,5);
		if (fade == 0)
			fade = 0.01;
	}	
	states {
	Spawn:
		SMO2 # 1 {
			if (GetAge() < 26) {
				wrot *= 0.98;
				scale *= 1.03;
				vel*=0.98;
				roll+=wrot;
				A_FadeOut(fade);
			}
			else {
				wrot *= 0.92;
				scale *= 1.01;
				vel*=0.93;
				roll+=wrot;
				A_FadeOut(fade);
			}
		}
		loop;
	}
}

class PK_WhiteDeathSmoke : PK_BaseSmoke {
	Default {
		alpha 0.5;
		scale 0.1;
		renderstyle 'add';
	}
	states	{
	Spawn:		
		SMOK ABCDEFGHIJKLMNOPQR 1 {
			A_FadeOut(0.05);
			scale *= 1.05;
		}
		stop;
	}
}

Class PK_DeathSmoke : PK_BaseSmoke {
	Default {
		alpha 0.3;
		scale 0.6;
	}
	override void Tick() {
		super.Tick();
		if (players[consoleplayer].mo.FindInventory("PK_DemonWeapon")) {	
			A_SetRenderstyle(alpha,Style_Stencil);
			SetShade("FF00FF");
			bBRIGHT = true;
		}
		else	{	
			A_SetRenderstyle(alpha,Style_Translucent);
			bBRIGHT = false;
		}
	}
	states	{
	Spawn:		
		BSMO ABCDEFGHIJKLMNOPQRSTU 2 {
			vel *= 0.97;
			A_FadeOut(0.03);
			scale *= 0.9;
		}
		wait;
	}
}

Class PK_DebugSpot : Actor {	
	Default {
		+NOINTERACTION
		+SYNCHRONIZED
		+DONTBLAST
		+BRIGHT
		+FORCEXYBILLBOARD
		xscale 0.35;
		yscale 0.292;
		FloatBobPhase 0;
		alpha 2;
		health 3;
		translation "1:255=%[0.00,1.01,0.00]:[1.02,2.00,0.00]";
	}
	
	override void Tick() {
		if (GetAge() > 35 * default.health)
			Destroy();
	}
	
	states {
	Spawn:
		AMRK A -1;
		stop;
	}
}