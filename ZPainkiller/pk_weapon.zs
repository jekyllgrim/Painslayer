Class PKWeapon : Weapon abstract {
	sound emptysound;
	property emptysound : emptysound;
	Default {
		weapon.BobRangeX 0.31;
		weapon.BobRangeY 0.15;
		weapon.BobStyle "InverseSmooth";
		weapon.BobSpeed 1.7;
		weapon.upsound "weapons/select";
		+FLOATBOB;
		+WEAPON.AMMO_OPTIONAL;
		+WEAPON.ALT_AMMO_OPTIONAL;
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
	action void PK_WeaponReady(int flags = 0) {
		if (player.cmd.buttons & BT_ATTACK && invoker.ammo1 && invoker.ammo1.amount < 1) {
			if (!(player.oldbuttons & BT_ATTACK))
				A_StartSound(invoker.emptysound);
			return;
		}
		if (player.cmd.buttons & BT_ALTATTACK && invoker.ammo2 && invoker.ammo2.amount < 1) {
			if (!(player.oldbuttons & BT_ALTATTACK))
				A_StartSound(invoker.emptysound);
			return;
		}
		A_WeaponReady(flags);
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
	protected vector3 spawnpos;
	protected bool farenough;
	
	color flarecolor;
	double flarescale;
	double flarealpha;
	color trailcolor;
	double trailscale;
	double trailalpha;
	double trailfade;
	double trailvel;
	double trailz;
	double trailshrink;
	
	class<PK_BaseFlare> trailactor;
	property trailactor : trailactor;
	class<PK_ProjFlare> flareactor;	
	property flareactor : flareactor;
	property flarecolor : flarecolor;
	property flarescale : flarescale;
	property flarealpha : flarealpha;
	property trailcolor : trailcolor;
	property trailalpha : trailalpha;
	property trailscale : trailscale;
	property trailfade : trailfade;
	property trailshrink : trailshrink;
	property trailvel : trailvel;
	property trailz : trailz;
	Default {
		projectile;
		PK_Projectile.flarescale 0.065;
		PK_Projectile.flarealpha 0.7;
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailalpha 0.4;
		PK_Projectile.trailfade 0.1;
		PK_Projectile.flareactor "PK_ProjFlare";
		PK_Projectile.trailactor "PK_BaseFlare";
	}
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (trailcolor)
			spawnpos = pos;
		if (!flarecolor)
			return;
		let fl = PK_ProjFlare( Spawn(flareactor,pos) );
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
			let trl = PK_BaseFlare( Spawn(trailactor,oldPos+(0,0,trailz)) );
			if (trl) {
				trl.master = self;
				trl.fcolor = trailcolor;
				trl.fscale = trailscale;
				trl.falpha = trailalpha;
				if (trailactor.GetClassName() == "PK_BaseFlare")
					trl.A_SetRenderstyle(alpha,Style_Shaded);
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

Class PK_BulletTracer : FastProjectile {
	Default {
		-ACTIVATEIMPACT;
		-ACTIVATEPCROSS;
		+BLOODLESSIMPACT;
		damage 0;
		radius 4;
		height 4;
		speed 180;
		renderstyle 'add';
		alpha 0.85;
		scale 0.3;
	}    
	states {
	Spawn:
		MODL A -1;
		stop;
	Death:
		TNT1 A 1;
		stop;
	}
}

Class PK_RicochetBullet : PK_SmallDebris {
	Default {
		renderstyle 'Add';
		alpha 0.8;
		scale 0.4;
		+BRIGHT
	}
	states {
	Spawn:
		MODL A 3;
		stop;
	}
}

Class PK_GenericExplosion : PK_SmallDebris {
	Default {
		+NOINTERACTION;
		renderstyle 'add';
		+BRIGHT;
		alpha 0.6;
		scale 0.4;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		double rs = scale.x * frandom[sfx](0.8,1.1)*randompick[sfx](-1,1);
		A_SetScale(rs);
		A_SetRoll(random(0,359));
		for (int i = random[sfx](10,15); i > 0; i--) {
			let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
			if (debris) {
				double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
				debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
				debris.A_SetScale(0.5);
			}
		}
		for (int i = random[sfx](10,15); i > 0; i--) {
			let debris = Spawn("PK_ExplosiveDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
			if (debris) {
				double zvel = (pos.z > floorz) ? frandom[sfx](-5,10) : frandom[sfx](5,15);
				debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10),zvel);
			}
		}
	}
	states {
	Spawn:
		BOM6 ABCDEFGHIJKLMNOPQRST 1;
		stop;
	}
}
		

Class PK_ExplosiveDebris : PK_RandomDebris {	
	Default {
		scale 0.5;
		gravity 0.25;
		//PK_SmallDebris.removeonfall true;
	}
	override void Tick () {
		Vector3 oldPos = self.pos;		
		Super.Tick();	
		if (isFrozen())
			return;
		let smk = Spawn("PK_BlackSmoke",pos+(frandom[smk](-4,4),frandom[smk](-4,4),frandom[smk](-4,4)));
		if (smk) {
			smk.A_SetScale(0.25);
			smk.alpha = alpha*0.18;
			smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
		}
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / 4; //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );		
		for( int i = 0; i < steps; i++ )  {
			let trl = Spawn("PK_DebrisFlame",oldPos);
			if (trl)
				trl.alpha = alpha*0.4;
			oldPos = level.vec3Offset( oldPos, direction );
		}
	}
	states {
	spawn:
		PDEB # 1 {			
			roll+=wrot;
			wrot *= 0.99;
			A_FadeOut(0.03);
		}
		loop;
	}
}

Class PK_DebrisFlame : PK_BaseFlare {
	Default {
		scale 0.05;
		renderstyle 'translucent';
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = random[sfx](0,359);
		wrot = frandom[sfx](5,10)+randompick[sfx](-1,1);
	}
	states {
	Spawn:
		BOM6 IJKLMNOP 1 {
			A_FadeOut(0.05);
			roll += wrot;
			scale *= 1.05;
		}
		stop;
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