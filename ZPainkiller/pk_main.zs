Mixin class PK_Math {	
	int Sign (double i) {
		if (i >= 0)
			return 1;
		return -1;
	}
	clearscope double LinearMap(double val, double o_min, double o_max, double n_min, double n_max) {
		return (val - o_min) * (n_max - n_min) / (o_max - o_min) + n_min;
	}
	clearscope int PointOnLineSide( Vector2 p, Line l ) {
		if ( !l ) return 0;
		return (((p.y-l.v1.p.y)*l.delta.x+(l.v1.p.x-p.x)*l.delta.y) > double.epsilon);
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

Class PK_BaseActor : Actor abstract {
	protected double pi;
	protected name bcolor;
	protected int age;
	mixin PK_Math;
	
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
				for (uint i = 0; i < CurSector.Get3DFloorCount(); ++i)
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

Class PK_InventoryToken : Inventory abstract {
	protected int age;
	Default {
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
		+INVENTORY.PERSISTENTPOWER;
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void DoEffect() {
		super.DoEffect();
		if (owner && !owner.isFrozen())
			age++;
	}
	override void Tick() {}
}

Class PK_BaseDebris : PK_BaseActor abstract {
	protected bool landed;			//true if object landed on the floor (or ceiling, if can stick to ceiling)
	protected bool moving; 		//marks actor as moving; sets to true automatically if actor spawns with non-zero vel
	Default {
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		+INTERPOLATEANGLES
		-ALLOWPARTICLES
		renderstyle 'Translucent';
		alpha 1.0;
		radius 1;
		height 1;
		mass 1;
	}
	// thanks Gutawer for explaning the math and helping this function come to life
	virtual void FlyBack() {
		if (!target)
			return;
		SetZ(pos.z+5);
		moving = true;
		landed = false;
		bFLATSPRITE = false;
		bTHRUACTORS = true;
		bNOGRAVITY = false;
		gravity = 1.0;
		A_FaceTarget();
		
		double dist = Distance2D(target);							//horizontal distance to target
		double vdisp = target.pos.z - pos.z + frandom[sfx](8,32);		//height difference between gib and target + randomized height
		double ftime = 20;											//time of flight
		
		double vvel = (vdisp + 0.5 * ftime*ftime) / ftime;
		double hvel = dist / ftime;
		
		VelFromAngle(hvel,angle);
		vel.z = vvel;
	}
	override void PostBeginPlay() {
		if (!level.IsPointInLevel(pos)) {
			destroy();
			return;
		}
		super.PostBeginPlay();
	}
}
	
Class PK_SmallDebris : PK_BaseDebris abstract {
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
		gravity 0.8;
		PK_SmallDebris.liquidsound "";
		PK_SmallDebris.removeonfall false;
		PK_SmallDebris.removeonliquid true;
		PK_SmallDebris.dbrake 0;
		PK_SmallDebris.hitceiling false;
		bouncecount 8;
		+MOVEWITHSECTOR
		-NOBLOCKMAP
	}
	
	override void BeginPlay() {
		super.BeginPlay();		
		ChangeStatnum(110);
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
		if (vel.length() != 0 || gravity != 0) //mark as movable if given any non-zero velocity or gravity
			moving = true;
		d_spawn = FindState("Spawn");
		d_death = FindState("Death");
		d_ceiling = FindState("HitCeiling");
		d_wall = FindState("HitWall");
		d_liquid = FindState("DeathLiquid");
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
						wallnormal = (-hit.HitLine.delta.y,hit.HitLine.delta.x).unit();
						wallpos = hit.HitLocation;
						if (!hit.LineSide)
							wallnormal *= -1;
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
									wallnormal = (-hit.HitLine.delta.y,hit.HitLine.delta.x).unit();
									wallpos = hit.HitLocation;
									if (!hit.LineSide)
										wallnormal *= -1;
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
	property spritename : spritename;
	Default {
		PK_RandomDebris.spritename 'PDEB';
		PK_SmallDebris.removeonliquid true;
		PK_SmallDebris.dbrake 0.8;
		+BOUNCEONWALLS
		+ROLLCENTER
		wallbouncefactor 0.5;
		height 8;
		stencilcolor "101010";
		scale 0.2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		wrot = random[sfx](14,20)*randompick(-1,1);
		roll = random[sfx](0,359);
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
			roll = 90 * randompick[sfx](-1,1) + frandom[sfx](-3,3);
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
			MODL A 1 bright;
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
		if (!master /*|| !bdoom_debris*/) {
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


//Shader.SetEnabled( players[consoleplayer], "DemonMode", true);