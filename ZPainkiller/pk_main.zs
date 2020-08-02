Class PK_BaseActor : Actor abstract {
	protected double pi;
	protected name bcolor;
	protected int age;
	
	bool CheckLandingSize (double cradius = 0, bool checkceiling = false) {
		bool ret = false;
		if (checkceiling) {
			double ceilingHeight = GetZAt (flags: GZF_CEILING);
			for (int i = 0; i < 360; i += 45) {
				double curHeight = GetZAt (cradius, 0, i, GZF_ABSOLUTEANG | GZF_CEILING);
				ret = ret || (curHeight > ceilingHeight);
			}
		}
		else {
			double floorHeight = GetZAt ();
			for (int i = 0; i < 360; i += 45) {
				double curHeight = GetZAt (cradius, 0, i, GZF_ABSOLUTEANG);
				ret = ret || (curHeight < floorHeight);
			}
		}
		return ret;
	}
	
	int PK_Sign (int i) {
		if (i >= 0)
			return 1;
		else
			return -1;
	}
	
	static const string PK_LiquidFlats[] = { 
		"BLOOD", "LAVA", "NUKAGE", "SLIME01", "SLIME02", "SLIME03", "SLIME04", "SLIME05", "SLIME06", "SLIME07", "SLIME08", "BDT_"
	};
	
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
		PK_SmalLDebris.liquidsound "";
		PK_SmalLDebris.removeonfall false;
		PK_SmalLDebris.removeonliquid true;
		PK_SmalLDebris.dbrake 0;
		PK_SmalLDebris.hitceiling false;
		+MOVEWITHSECTOR
	}
	
	override void BeginPlay() {
		super.BeginPlay();		
		ChangeStatnum(110);
	}
	override void PostBeginPlay() {
		if (!level.IsPointInLevel(pos)) {
			destroy();
			return;
		}
		super.PostBeginPlay();
		if (vel.length() != 0 || gravity != 0) //mark as movable if given any non-zero velocity
			moving = true;
		d_spawn = FindState("Spawn");
		d_death = FindState("Death");
		d_ceiling = FindState("HitCeiling");
		d_wall = FindState("HitWall");
		d_liquid = FindState("DeathLiquid");
	}
	//a chad tick override that skips Actor's super.tick!
	override void Tick() {
		if (alpha < 0) {
			destroy();
			return;
		}
		//if (self)
			//console.printf("%s %d alpha %f",GetClassName(),GetAge(),alpha);
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
		if (!bNOINTERACTION) {
			UpdateWaterLevel();
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
					LineTrace(angle,16,0,flags:TRF_THRUACTORS|TRF_NOSKY,data:hit);
					if (hit.HitLine && hit.hittype == TRACE_HITWALL) {
						wall = hit.HitLine;
						wallnormal = (-hit.HitLine.delta.y,hit.HitLine.delta.x).unit();
						wallpos = hit.HitLocation;
						if (!hit.LineSide)
							wallnormal *= -1;						
						if (bBOUNCEONWALLS || pos.z <= floorz+Voffset){		
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
						else
							PK_HitWall();
					}
					if (!self)
						return;
				}
			}
			//stick to surface if already landed:
			if (landed) {
				if (onceiling)
					SetOrigin((pos.x,pos.y,ceilingz-Voffset),true);
				else {
					SetZ(floorz+Voffset);
					if (dbrake > 0) {
						if (!(vel.x ~== 0) || !(vel.y ~== 0)) {
							vel.xy *= dbrake;
							A_FaceMovementDirection(flags:FMDF_NOPITCH);
							FLineTraceData hit;
							LineTrace(angle,12,0,flags:TRF_THRUACTORS|TRF_NOSKY,data:hit);
							if (hit.HitLine && hit.hittype == TRACE_HITWALL) {
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
				}
			}
			//simulate falling if not yet landed:
			else {
				if (pos.z <= floorz+Voffset) {
					bool liquid = CheckLiquidFlat();
					if (liquid || !bBOUNCEONFLOORS || abs(vel.z) <= 2) {
						if (liquid)
							onliquid = true;
						PK_HitFloor();	
					}
					else {
						SetZ(floorz+Voffset);
						vel.z *= -bouncefactor;
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
		if (moving)
			SetOrigin(level.vec3offset(pos, vel),true);
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
		if (onliquid) {
			A_Stop();
			A_StartSound(liquidsound,slot:CHAN_AUTO,flags:CHANF_DEFAULT,1.0,attenuation:3);
			if (removeonliquid) {
				destroy();
				return;
			}
			Voffset = (liquidheight == 0) ? (-(height * 0.5)) : -liquidheight;
			if (d_liquid)
				SetState(d_liquid);
			else if (d_death)
				SetState(d_death);
		}
		else if (d_death)
			SetState(d_death);
		SetZ(floorz+Voffset);
	}
	virtual void PK_Hitceiling() {
		if (ceilingpic == skyflatnum) {
			destroy();
			return;
		}
		SetZ(ceilingz-Voffset);
		if (d_ceiling)
			SetState(d_ceiling);
	}
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
	Default {
		PK_SmallDebris.removeonliquid true;
		PK_SmallDebris.dbrake 0.8;
		+BOUNCEONWALLS
		+ROLLCENTER
		wallbouncefactor 0.5;
		height 8;
		renderstyle 'shaded';
		stencilcolor "101010";
		scale 0.2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		wrot = random[sfx](14,20)*randompick(-1,1);
		frame = random[sfx](0,5);
		roll = random[sfx](0,359);
		scale *= frandom[sfx](0.75,1.2) * randompick[sfx](-1,1);
		bSPRITEFLIP = randompick[sfx](0,1);
	}
	states {
	spawn:
		PDEB # 1 {			
			roll+=wrot;
			wrot *= 0.99;
		}
		loop;
	Death:
		PDEB # 1 {
			A_FadeOut(0.03);
			scale *= 0.95;
		}
		loop;
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
	double fscale;		//scale; used to when scale needs to be easily set externally from the spawner
	double falpha;		//alpha; used to when scale needs to be easily set externally from the spawner
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
			A_SetRenderstyle(1.0,Style_Stencil);
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
			A_FadeOut(0.01);
			scale *= 0.9;
		}
		wait;
	}
}

Class PK_EnemyDeathControl : Actor {
	KillerFlyTarget kft;
	private int restcounter;
	private int restlife;
	private int maxlife;
	private int age;
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master) {
			destroy();
			return;
		}
		restlife = random[cont](42,60);
		maxlife = int(35*frandom[cont](6,10));
		kft = KillerFlyTarget(Spawn("KillerFlyTarget",master.pos));
		if (kft) {
			kft.target = master;
			kft.A_SetSize(master.radius,master.default.height*0.5);
			kft.vel = master.vel;
		}
	}	
	override void Tick () {
		if (master) {	
			SetOrigin(master.pos,true);
			if (!master.isFrozen())
				age++;
			if (GetAge() == 1 && kft)
				kft.vel = master.vel;	
			if  (master.vel ~== (0,0,0))
				restcounter++;
			else
				restcounter = 0;
		}		
		double rad = 8;
		double smkz = 20;
		if (master) {
			rad = master.radius;
			smkz = master.height;
		}
		if (master && master.bKILLED && master.FindInventory("PK_SlowMoControl")) {
			for (int i = 40; i > 0; i--) {
				smkz = master.default.height;
				let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](0,smkz)));
				if (smk) {
					smk.vel = (frandom[part](-0.4,0.4),frandom[part](-0.4,0.4),frandom[part](0,1));
					smk.A_SetRenderstyle(1.0,Style_Stencil);
					smk.SetShade("FF00FF");
					smk.bBRIGHT = true;
				}
			}
			master.destroy();
		}	
		else if (restcounter >= restlife || age > maxlife || !master) {
			if (kft)
				kft.destroy();
			A_StartSound("world/bodypoof",CHAN_AUTO);
			for (int i = 26; i > 0; i--) {
				let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](0,smkz*1.5)));
				if (smk)
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
			}
			for (int i = 8; i > 0; i--) {
				let smk = Spawn("PK_WhiteSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](pos.z,smkz)));
				if (smk) {
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
					smk.A_SetScale(0.4);
					smk.alpha = 0.5;
				}
			}
			Class<Inventory> soul = (master && master.default.health >= 500) ? "PK_RedSoul" : "PK_Soul";			
			double pz = (pos.z ~== floorz) ? frandom[soul](8,14) : 0;
			Spawn(soul,pos+(0,0,pz));
			if (master)
				master.destroy();
			destroy();
			return;
		}
	}
}


//Shader.SetEnabled( players[consoleplayer], "DemonMode", true);