Class PKWeapon : Weapon abstract {
	mixin PK_Math;
	sound emptysound;
	property emptysound : emptysound;
	protected bool hasDexterity;
	protected vector2 targOfs;
	protected vector2 shiftOfs;
	protected bool alwaysbob;
	property alwaysbob : alwaysbob;
	Default {
		PKWeapon.alwaysbob true;
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
	enum PK_WeaponLayers {
		PSP_UNDERGUN 	= -1,
		PSP_OVERGUN 	= 2,
		PSP_SCOPE1		= 3,
		PSP_SCOPE2		= 4,
		PSP_SCOPE3		= 5,
		PSP_PFLASH 	= -100,
		PSP_HIGHLIGHTS = 100,
		
		RIFLE_PILOT	= -6,
		RIFLE_STRAP 	= -3,
		RIFLE_BARREL 	= -2,
		RLIGHT_BARREL	= -1,
		RLIGHT_WEAPON	= 2,
		RIFLE_BOLT		= 3,
		RLIGHT_BOLT	= 4,
		RIFLE_STOCK	= 5,
		RLIGHT_STOCK	= 6	
	}	
	override void DoEffect() {
		Super.DoEffect();
		if (!owner)
			return;
		let weap = owner.player.readyweapon;
		if (!weap)
			return;
		if (alwaysbob && weap == self)
			owner.player.WeaponState |= WF_WEAPONBOBBING;
		hasDexterity = owner.FindInventory("PowerDoubleFiringSpeed",true);
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		let icon = Spawn("PK_WeaponIcon",pos + (0,0,18));
		if (icon)  {
			icon.master = self;
		}
	}
	action actor PK_FireArchingProjectile(class<Actor> missiletype, double angle = 0, bool useammo = true, double spawnofs_xy = 0, double spawnheight = 0, int flags = 0, double pitch = 0) {
		if (!self || !self.player) 
			return null;
		double pitchOfs = pitch;
		if (pitch != 0 && self.pitch < 0)
			pitchOfs = invoker.LinearMap(self.pitch, 0, -90, pitchOfs, 0);
		return A_FireProjectile(missiletype, angle, useammo, spawnofs_xy, spawnheight, flags, pitchOfs);
	}
	action void DampedRandomOffset(double rangeX, double rangeY, double rate = 1) {
		let psp = Player.FindPSprite(PSP_WEAPON);			
		if (!psp)
			return;
		if (abs(psp.x) >= abs(invoker.targOfs.x) || abs(psp.y) >= abs(invoker.targOfs.y)) {
			invoker.targOfs = (frandom[sfx](0,rangeX),frandom[sfx](0,rangeY)+32);
			vector2 shift = (rangeX * rate, rangeY * rate);
			shift = (shift.x == 0 ? 1 : shift.x, shift.y == 0 ? 1 : shift.y);
			invoker.shiftOfs = ((invoker.targOfs.x - psp.x) / shift.x, (invoker.targOfs.y - psp.y) / shift.y);
		}
		A_WeaponOffset(invoker.shiftOfs.x, invoker.shiftOfs.y, WOF_ADD);
	}
	action void PK_WeaponReady(int flags = 0) {
		if ((player.cmd.buttons & BT_ATTACK) && (!invoker.ammo1 || invoker.ammo1.amount < invoker.ammouse1)) {
			A_ClearRefire();
			if (!(player.oldbuttons & BT_ATTACK))
				A_StartSound(invoker.emptysound);
			return;
		}
		if ((player.cmd.buttons & BT_ALTATTACK) && (!invoker.ammo2 || invoker.ammo2.amount < invoker.ammouse2)) {
			A_ClearRefire();
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

Class PK_BulletPuff : PKPuff {
	Default {
		decal "BulletChip";
		scale 0.032;
		renderstyle 'add';
		alpha 0.6;
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay {
			if (random[sfx](0,10) > 7) {
				//A_StartSound("weapons/bullet/ricochet",attenuation:3);
				A_SpawnItemEx("PK_RicochetBullet",xvel:30,zvel:frandom[sfx](-10,10),angle:random[sfx](0,359));
			}
			A_SpawnItemEx("PK_RandomDebris",xvel:frandom[sfx](-4,4),yvel:frandom[sfx](-4,4),zvel:frandom[sfx](3,5));
			for (int i = 3; i > 0; i--) {
				let smk = Spawn("PK_BulletPuffSmoke",pos+(frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](-2,2)));
				if (smk) {
					smk.vel = (frandom[sfx](-0.4,0.4),frandom[sfx](-0.4,0.4),frandom[sfx](0.1,0.5));
				}
			}
		}
		FLAR B 1 bright A_FadeOut(0.1);
		wait;
	}
}

class PK_BulletPuffSmoke : PK_BlackSmoke {
	Default {
		alpha 0.3;
		scale 0.12;
	}
	states	{
	Spawn:
		SMOK ABCDEFGHIJKLMNOPQR 1 NoDelay {
			A_FadeOut(0.02);
			scale *= 0.9;
		}
		wait;
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

Class PK_Projectile : PK_BaseActor abstract {
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
	/*
	For whatever reason the fancy pitch offset calculation used in arching projectiles like grenades (see PK_FireArchingProjectile) screws up the projectiles' collision, so that it'll collide with the player if it fell 
	down on them after being fired directly upwards.
	I had to add this override to circumvent that.
	*/
	override bool CanCollideWith(Actor other, bool passive) {
		if (!other)
			return false;
		if (!passive && target && other == target)
			return false;
		return super.CanCollideWith(other, passive);
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
		+BRIGHT
		damage 0;
		radius 4;
		height 4;
		speed 180;
		renderstyle 'add';
		alpha 2;
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
		alpha 1;
		scale 0.52;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		double rs = scale.x * frandom[sfx](0.8,1.1)*randompick[sfx](-1,1);
		A_SetScale(rs);
		roll = random[sfx](0,359);
		for (int i = random[sfx](10,15); i > 0; i--) {
			let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
			if (debris) {
				double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
				debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
				debris.A_SetScale(0.5);
			}
		}
		for (int i = random[sfx](10,15); i > 0; i--) {
			let debris = Spawn("PK_ExplosiveDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
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
		let smk = Spawn("PK_BlackSmoke",pos+(frandom[smk](-9,9),frandom[smk](-9,9),frandom[smk](-9,9)));
		if (smk) {
			smk.A_SetScale(0.25);
			smk.alpha = alpha*0.3;
			smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
		}
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / 4; //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );		
		for( int i = 0; i < steps; i++ )  {
			let trl = Spawn("PK_DebrisFlame",oldPos);
			if (trl)
				trl.alpha = alpha*0.75;
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
		alpha 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = random[sfx](0,359);
		wrot = frandom[sfx](5,10)+randompick[sfx](-1,1);
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,1,3);
		BOM4 IJKLMNOPQ 1 {
			A_FadeOut(0.05);
			roll += wrot;
			scale *= 1.1;
		}
		wait;
	}
}

//// AMMO

Class PK_Shells : Ammo {
	Default {
		inventory.pickupmessage "Picked up shotgun shells.";
		inventory.pickupsound "pickups/ammo/shells";
		inventory.icon "pkhshell";
		inventory.amount 18;
		inventory.maxamount 100;
		ammo.backpackamount 18;
		ammo.backpackmaxamount 100;
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
		inventory.pickupmessage "Picked up freezer ammo.";
		inventory.pickupsound "pickups/ammo/freezerammo";
		inventory.icon "pkhfreez";
		inventory.amount 15;
		inventory.maxamount 100;
		ammo.backpackamount 15;
		ammo.backpackmaxamount 100;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMFR A -1;
		stop;
	}
}


Class PK_StakeAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of stakes.";
		inventory.pickupsound "pickups/ammo/stakes";
		inventory.icon "pkhstake";
		inventory.amount 15;
		inventory.maxamount 100;
		ammo.backpackamount 15;
		ammo.backpackmaxamount 100;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMST A -1;
		stop;
	}
}

Class PK_GrenadeAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of grenades.";
		inventory.pickupsound "pickups/ammo/grenades";
		inventory.icon "pkhrock";
		inventory.amount 7;
		inventory.maxamount 100;
		ammo.backpackamount 7;
		ammo.backpackmaxamount 100;
		scale 0.4;
	}
	states	{
	spawn:
		AMRO A -1;
		stop;
	}
}

Class PK_BulletAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of bullets.";
		inventory.pickupsound "pickups/ammo/bullets";
		inventory.icon "pkhbull";
		inventory.amount 50;
		inventory.maxamount 500;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 500;
		scale 0.4;
	}
	states	{
	spawn:
		AMBE A -1;
		stop;
	}
}


Class PK_ShurikenAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of shurikens.";
		inventory.pickupsound "pickups/ammo/stars";
		inventory.icon "pkhstars";
		inventory.amount 20;
		inventory.maxamount 250;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 250;
		xscale 0.3;
		yscale 0.25;
	}
	states {
	spawn:
		AMSU A -1;
		stop;
	}
}

Class PK_CellAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a cell battery.";
		inventory.pickupsound "pickups/ammo/battery";
		inventory.icon "pkhshock";
		inventory.amount 40;
		inventory.maxamount 500;
		ammo.backpackamount 80;
		ammo.backpackmaxamount 500;
		scale 0.4;
	}
	states	{
	spawn:
		AMEL A -1;
		stop;
	}
}


Class PK_BoltAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of steel bolts.";
		inventory.pickupsound "pickups/ammo/bolts";
		inventory.icon "pkhbolts";
		inventory.amount 30;
		inventory.maxamount 500;
		ammo.backpackamount 30;
		ammo.backpackmaxamount 500;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMBL A -1;
		stop;
	}
}

Class PK_BombAmmo : Ammo {
	Default {
		inventory.pickupmessage "Picked up a box of bombs.";
		inventory.pickupsound "pickups/ammo/bombs";
		inventory.icon "pkhbombs";
		inventory.amount 20;
		inventory.maxamount 250;
		ammo.backpackamount 20;
		ammo.backpackmaxamount 250;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMBM A -1;
		stop;
	}
}
