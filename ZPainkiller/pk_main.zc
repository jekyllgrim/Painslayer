Class PKWeapon : Weapon abstract {
	Default {
		weapon.BobRangeX 0.31;
		weapon.BobRangeY 0.15;
		weapon.BobStyle "InverseSmooth";
		weapon.BobSpeed 1.7;
		weapon.upsound "weapons/select";
		+FLOATBOB
		FloatBobStrength  0.3;
	}
	override void DoEffect()
		{
		Super.DoEffect();
		if (!owner)
			return;
		if (owner.player.readyweapon)
			owner.player.WeaponState |= WF_WEAPONBOBBING;
	}
	states {
		Ready:
			TNT1 A 1;
			loop;
		Fire:
			TNT1 A 1;
			loop;
		Deselect:
			TNT1 A 0 A_Lower();
			wait;
		Select:
			TNT1 A 0 A_Raise();
			wait;
		LoadSprites:
			PSGT AHIJK 0;
			stop;
	}
}
	
Class PK_WeaponIcon : Actor {
	state mspawn;
	Default {
		+BRIGHT
		scale 0.1;
		+NOINTERACTION
		+FLOATBOB
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master) {
			destroy();
			return;
		}
		mspawn = master.FindState("Spawn");
		SetOrigin((master.pos.x,master.pos.y,master.pos.z+18),false);
		FloatBobStrength = master.FloatBobStrength;
		FloatBobPhase = master.FloatBobPhase;
	}
	override void Tick () {
		super.Tick();
		if (!master || (master && !master.InStateSequence(master.curstate,mspawn))) {
			destroy();
			return;
		}
	}
	states {
		Spawn:
			PSHT X -1;
			stop;
	}
}

	
Class PKPuff : Actor abstract {
	Default {
		+NOBLOCKMAP
		+NOGRAVITY
		+FORCEXYBILLBOARD
		-ALLOWPARTICLES
		+DONTSPLASH
		-FLOORCLIP
	}
}

Class PK_NullPuff : Actor {
	Default {
		decal "none";
		+NODECAL
		+NOINTERACTION
		+BLOODLESSIMPACT
		+PAINLESS
		+PUFFONACTORS
		+NODAMAGETHRUST
	}
	states {
		Spawn:
			TNT1 A 1;
			stop;
	}
}
	
Class PK_BaseDebris : Actor abstract {
	bool landed;
	Default {
		+ROLLSPRITE
		+BLOODLESSIMPACT	//for debris that can bump into actors
		+NOTAUTOAIMED
		+MISSILE			//enters Death when it hits the floor
		+NOBLOCKMAP
		+NOGRAVITY
		+DROPOFF
		+NOTELEPORT
		+FORCEXYBILLBOARD
		+THRUACTORS
		+FLOORCLIP
		+INTERPOLATEANGLES
		-ALLOWPARTICLES
		renderstyle "Translucent";
		alpha 1.0;
		radius 1;
		height 1;
		mass 1;
		damage 0;
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
	int wrot;
	double dbrake; //how quickly to reduce horizontal speed of "landed" particles
	bool removeonfall; //whether to remove immediately as it reaches the floor
	property removeonfall : removeonfall;
	property dbrake : dbrake;
	Default {
		-MISSILE
		-RELATIVETOFLOOR
		-FLOORCLIP //this flag can screw up pos.z detection
		+NOINTERACTION
		+CLIENTSIDEONLY
		PK_SmallDebris.removeonfall true;
		PK_SmallDebris.dbrake 0;
		gravity 0.8;
	}
	override void Tick() {
		super.tick();
		if (level.isFrozen())
			return;
		if (pos.z > floorz)
			vel.z-=gravity;
		else if (removeonfall) {
			destroy();
			return;
		}
		else {
			if (!landed) {
				if (pos.z < floorz)
					SetOrigin((pos.x,pos.y,floorz),0);
				vel.z = 0;
				bMOVEWITHSECTOR = true;
				bRELATIVETOFLOOR = true;
				landed = true;
			}
			vel.x *= dbrake;
			vel.y *= dbrake;
		}		
	}
}

Class PK_RicochetTracer : PK_BaseDebris {
	Default {
		+NOINTERACTION
		+THRUACTORS
		+DONTSPLASH
		bouncetype "Hexen";
		speed 40;
		seesound "none";
		deathsound "none";
		renderstyle "Add";
		alpha 0.8;
	}
	states {
		Spawn:
			MODL A 2;
			stop;
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
			A_PlaySound("weapons/tracerwhizz",1,1.0,0,8);
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
	
Class PK_Flarebase : PK_BaseDebris {
	name fcolor;		//flare of the color; can be set as a property or externally
	double fscale;		//scale; used to when scale needs to be easily set externally from the spawner
	double falpha;		//alpha; used to when scale needs to be easily set externally from the spawner
	double fade;
	double shrink;
	property fcolor : fcolor;
	bool translucent;
	Default {
		PK_Flarebase.fcolor 'red';
		-MISSILE
		+RELATIVETOFLOOR
		+MOVEWITHSECTOR
		+NOINTERACTION
		+BRIGHT
		renderstyle "Add";
		alpha 0.4;
		scale 0.4;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		switch (fcolor) {
			case 'red'		: frame = 0; break;
			case 'green'	: frame = 1; break;
			case 'blue'		: frame = 2; break;
			case 'yellow'	: frame = 3; break;
			case 'white'	: frame = 4; break;
			case ''			: destroy(); return;
		}
		if (fscale != 0)
			A_SetScale(fscale);
		if (falpha != 0)
			alpha = falpha;			
	}
	states 	{
		Loadsprites:
			FLAR ABCDE 0;
			SPRK ABC 0;
		Spawn:
			FLAR # 1 {
				if (fade != 0)
					A_FadeOut(fade);
				if (shrink != 0)
					scale*=shrink;
			}
			loop;
	}
}

	
Class PK_ProjFlare : PK_Flarebase {
	state mdeath;
	state mxdeath;
	Default {
		alpha 0.8;
		scale 0.11;
		-RELATIVETOFLOOR
		-MOVEWITHSECTOR
	}
	virtual void SetPos() {
		if (master) {
			SetOrigin(master.pos,0);
			vel = master.vel;
		}
	}
	override void Tick() {
		super.Tick();
		if (level.isFrozen())
			return;
		if (master)
			SetOrigin(master.pos,true);
		else {
			Destroy();
			return;
		}
	}
	states
		{
		Spawn:
			FLAR # 1 NoDelay;
			loop;
	}
}

Class PK_Projectile : Actor abstract {
	Default {
		projectile;
		PK_Projectile.flarescale 0.065;
		PK_Projectile.flarealpha 0.7;
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailalpha 0.4;
		PK_Projectile.trailfade 0.1;
	}
	vector3 spawnpos;
	bool farenough;
	
	name flarecolor;
	double flarescale;
	double flarealpha;
	name trailcolor;
	double trailscale;
	double trailalpha;
	double trailfade;
	double trailvel;
	double trailshrink;
	bool TranslucentTrail;
	//class<Actor> trailactor;
	
	property flarecolor : flarecolor;
	property flarescale : flarescale;
	property flarealpha : flarealpha;
	property trailcolor : trailcolor;
	property trailalpha : trailalpha;
	property trailscale : trailscale;
	property trailfade : trailfade;
	property trailshrink : trailshrink;
	property trailvel : trailvel;
	property TranslucentTrail : TranslucentTrail;
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (trailcolor)
			spawnpos = pos;
		if (!flarecolor)
			return;
		let fl = PK_ProjFlare( Spawn("PK_ProjFlare",pos) );
		if (fl) {
			fl.master = self;
			fl.fcolor = flarecolor;
			fl.fscale = flarescale;
			fl.falpha = flarealpha;
		}
	}
	override void Tick () {
		Vector3 oldPos = self.pos;		
		Super.Tick();
		if (!trailcolor)
			return;			
		if (level.isFrozen())
			return;
		if (!farenough) {
			if (level.Vec3Diff(pos,spawnpos).length() < 80)
				return;
			farenough = true;
		}
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / clamp(int(trailscale * 50),1,8); //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );
		
		for( int i = 0; i < steps; i++ )  {
			//if (target && distance3d(target) > 128) { //give us some distance so that the smoke doesn't spawn right in the players face
				let trl = PK_Flarebase( Spawn("PK_Flarebase",oldPos) );
				if (trl) {
					trl.master = self;
					trl.fcolor = trailcolor;
					trl.fscale = trailscale;
					trl.falpha = trailalpha;
					if (TranslucentTrail)
						trl.A_SetRenderstyle(alpha,STYLE_Translucent);
					if (trailfade != 0)
						trl.fade = trailfade;
					if (trailshrink != 0)
						trl.shrink = trailshrink;
					if (trailvel != 0)
						trl.vel = (frandom(-trailvel,trailvel),frandom(-trailvel,trailvel),frandom(-trailvel,trailvel));
				}
			oldPos = level.vec3Offset( oldPos, direction );
		}
	}
}
	