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
	override void PostBeginPlay() {
		super.PostBeginPlay();
		let icon = Spawn("PK_WeaponIcon",pos + (0,0,18));
		if (icon)  {
			icon.master = self;
		}
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
		xscale 0.14;
		yscale 0.1162;
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
		FloatBobStrength = master.FloatBobStrength;
		FloatBobPhase = master.FloatBobPhase;
		if (master.GetClassName() == "PK_Shotgun")
			frame = 0;
		else if (master.GetClassName() == "PK_Stakegun")
			frame = 1;
	}
	override void Tick () {
		super.Tick();
		if (!master || !master.InStateSequence(master.curstate,mspawn)) {
			destroy();
			return;
		}
	}
	states {
		Spawn:
			PWIC # -1;
			stop;
	}
}

Class PK_Projectile : Actor abstract {
	protected int age;
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
		if (isFrozen())
			return;
		age++;
		if (!trailcolor)
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
				let trl = PK_BaseFlare( Spawn("PK_BaseFlare",oldPos) );
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


//// AMMO

Class PK_Shells : Ammo {
	Default {
		inventory.pickupmessage "You picked up shotgun shells.";
		inventory.pickupsound "pickups/ammo/shells";
		inventory.amount 18;
		inventory.maxamount 100;
		ammo.backpackamount 15;
		ammo.backpackmaxamount 666;
		xscale 0.3;
		yscale 0.25;
	}
	states {
	spawn:
		AMSH A -1;
		stop;
	}
}

Class PK_FreezerAmmo : Ammo {
	Default {
		inventory.pickupmessage "You picked up freezer ammo.";
		inventory.pickupsound "pickups/ammo/freezerammo";
		inventory.amount 15;
		inventory.maxamount 100;
		ammo.backpackamount 6;
		ammo.backpackmaxamount 666;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMFR A -1;
		stop;
	}
}


Class PK_Stakes : Ammo {
	Default {
		inventory.pickupmessage "You picked up a box of stakes.";
		inventory.pickupsound "pickups/ammo/stakes";
		inventory.amount 15;
		inventory.maxamount 100;
		ammo.backpackamount 12;
		ammo.backpackmaxamount 666;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMST A -1;
		stop;
	}
}

Class PK_Bombs : Ammo {
	Default {
		inventory.pickupmessage "You picked up a box of bombs.";
		inventory.pickupsound "pickups/ammo/bombs";
		inventory.amount 7;
		inventory.maxamount 100;
		ammo.backpackamount 12;
		ammo.backpackmaxamount 666;
		scale 0.4;
	}
	states	{
	spawn:
		AMBO A -1;
		stop;
	}
}

Class PK_Bullets : Ammo {
	Default {
		inventory.pickupmessage "You picked up a box of bullets.";
		inventory.pickupsound "pickups/ammo/bullets";
		inventory.icon "BULSA0";
		inventory.amount 50;
		inventory.maxamount 500;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 666;
	}
	states	{
	spawn:
		BULS A -1;
		stop;
	}
}


Class PK_ShurikenBox : Ammo {
	Default {
		inventory.pickupmessage "You picked up a box of shurikens.";
		inventory.pickupsound "pickups/ammo/stars";
		inventory.amount 10;
		inventory.maxamount 100;
		ammo.backpackamount 40;
		ammo.backpackmaxamount 666;
		xscale 0.3;
		yscale 0.25;
	}
	states {
	spawn:
		AMSU A -1;
		stop;
	}
}

Class PK_Battery : Ammo {
	Default {
		inventory.pickupmessage "You picked up a cell battery.";
		inventory.pickupsound "pickups/ammo/battery";
		inventory.amount 20;
		inventory.maxamount 500;
		ammo.backpackamount 80;
		ammo.backpackmaxamount 666;
		scale 0.4;
	}
	states	{
	spawn:
		AMEL A -1;
		stop;
	}
}