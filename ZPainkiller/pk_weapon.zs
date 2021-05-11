Class PKWeapon : Weapon abstract {
	mixin PK_Math;
	sound emptysound;
	property emptysound : emptysound;
	protected bool hasDexterity;
	protected bool hasWmod;
	protected vector2 targOfs;
	protected vector2 shiftOfs;
	protected bool alwaysbob;
	property alwaysbob : alwaysbob;
	protected double spitch;
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
	override void PostBeginPlay() {
		super.PostBeginPlay();
		let icon = Spawn("PK_WeaponIcon",pos);
		if (icon)  {
			icon.master = self;
		}
		spitch = frandompick[sfx](-0.1,0.1);
	}
	override void Tick() {
		super.Tick();
		if (owner || isFrozen())
			return;
		A_SetAngle(angle+1.5,SPF_INTERPOLATE);
		A_SetPitch(pitch+spitch,SPF_INTERPOLATE);
		if (abs(pitch) > 8)
			spitch *= -1;
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
		hasWmod = owner.CountInv("PK_WeaponModifier");
	}
	
	action bool CheckInfiniteAmmo() {
		return (sv_infiniteammo || FindInventory("PowerInfiniteAmmo",true) );
	}
	
	//plays a sound and also a WeaponModifier sound if Weaponmodifier is in inventory:
	action void PK_AttackSound(sound snd = "", int channel = CHAN_AUTO, int flags = 0) {
		if (snd)
			A_StartSound(snd,channel,flags);
		//will play it only once for repeating weapons (important):
		if (CountInv("PK_WeaponModifier") && player && !player.refire) {
			A_StartSound("pickups/wmod/use",CH_WMOD);
		}
	}
	
	//a wrapper function that automatically plays either vanilla or enhanced weapon sound, and fires tracers with A_FireProjectile so that they don't break on portals and such:
	action void PK_FireBullets(double spread_horz = 0, double spread_vert = 0, int numbullets = 1, int damage = 1, sound snd = "", Class<Actor> pufftype = "PK_BulletPuff", double spawnheight = 0, double spawnofs = 0) {
		if (numbullets == 0) numbullets = 1;
		let weapon = player.ReadyWeapon;
		//deplete the appropriate ammo
		if (!weapon || !weapon.DepleteAmmo(weapon.bAltFire, true))
			return;
		//play only if non-null
		if (snd)
			A_StartSound(snd,CHAN_WEAPON);
		//emulate perfect accuracy on first bullet: it'll happen if there's only 1 bullet, player isn't in refire (holding attack button), and numbullets is positive
		bool held = (numbullets != 1 || player.refire);
		//make sure numbullets is positive, now that the check is finished
		numbullets = abs(numbullets);
		//fire bullets with explicit angle and simply pass the offsets to the projectiles instead of using AimBulletMissile at puffs (because puffs don't always spawn!)
		for (int i = 0; i < numbullets; i++) {			
			double hspread = held ? frandom(-spread_horz,spread_horz) : 0;
			double vspread = held ? frandom(-spread_vert,spread_vert) : 0;	
			A_FireProjectile("PK_BulletTracer",hspread,useammo:false,spawnofs_xy:spawnofs,spawnheight:spawnheight,pitch:vspread);
			A_FireBullets (hspread, vspread, -1, damage, pufftype,flags:FBF_NORANDOMPUFFZ|FBF_EXPLICITANGLE|FBF_NORANDOM);
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
	mixin PK_Math;
	Default {
		+NOBLOCKMAP
		+NOGRAVITY
		+FORCEXYBILLBOARD
		+PUFFGETSOWNER
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
	protected Vector3 hitnormal;			//vector normal of the hit 
	protected FLineTraceData puffdata;
	double debrisOfz;
	Default {
		decal "BulletChip";
		scale 0.032;
		renderstyle 'add';
		alpha 0.6;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
	}
	void FindLineNormal() {
		LineTrace(angle,128,pitch,TRF_THRUACTORS|TRF_NOSKY,data:puffdata);
		hitnormal = -puffdata.HitDir;
		if (puffdata.HitType == TRACE_HitFloor) {
			debrisOfz = 1;
			if (puffdata.Hit3DFloor) 
				hitnormal = -puffdata.Hit3DFloor.top.Normal;
			else 
				hitnormal = puffdata.HitSector.floorplane.Normal;
		}
		else if (puffdata.HitType == TRACE_HitCeiling)	{
			debrisOfz = -1;
			if (puffdata.Hit3DFloor) 
				hitnormal = -puffdata.Hit3DFloor.bottom.Normal;
			else 
				hitnormal = puffdata.HitSector.ceilingplane.Normal;
		}
		else if (puffdata.HitType == TRACE_HitWall) {
			hitnormal = (-puffdata.HitLine.delta.y,puffdata.HitLine.delta.x,0).unit();
			if (!puffdata.LineSide) 
				hitnormal *= -1;
		}
	}
	states {
	Crash:
		TNT1 A 0 {
			if (target) {
				angle = target.angle;
				pitch = target.pitch;
			}
			FindLineNormal();
			let smok = PK_WhiteSmoke(Spawn("PK_WhiteSmoke",puffdata.Hitlocation + (0,0,debrisOfz)));
			if (smok) {
				smok.vel = (hitnormal + (frandom[sfx](-0.05,0.05),frandom[sfx](-0.05,0.05),frandom[sfx](-0.05,0.05))) * frandom[sfx](0.8,1.3);
				smok.A_SetScale(0.085);
				smok.alpha = 0.85;
				smok.fade = 0.025;
			}
			let deb = Spawn("PK_RandomDebris",puffdata.Hitlocation + (0,0,debrisOfz));
			if (deb)
				deb.vel = (hitnormal + (frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](3,5)));
			bool mod = (target && target.CountInv("PK_WeaponModifier"));
			name lit = mod ? 'PK_BulletPuffMod' : 'PK_BulletPuff';
			A_AttachLightDef('puf',lit);
			if (mod || (random[sfx](0,10) > 7)) {
				let bull = PK_RicochetBullet(Spawn("PK_RicochetBullet",pos));
				if (bull) {
					bull.vel = (hitnormal + (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](-3,3)) * frandom[sfx](2,6));
					bull.A_FaceMovementDirection();
					if (mod) {
						bull.A_SetRenderstyle(bull.alpha,Style_AddShaded);
						bull.SetShade("FF2000");
						//bull.scale *= 2;
					}
				}
			}
		}
		FLAR B 1 bright A_FadeOut(0.1);
		wait;
	}
}

//unused
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
	//state mspawn;
	PKWeapon weap;
	Default {
		+BRIGHT
		xscale 0.14;
		yscale 0.1162;
		+NOINTERACTION
		+FLOATBOB
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (master)
			weap = PKWeapon(master);
		if (!weap) {
			destroy();
			return;
		}
		FloatBobStrength = weap.FloatBobStrength;
		FloatBobPhase = weap.FloatBobPhase;
		if (weap.GetClassName() == "PK_Shotgun")
			frame = 0;
		else if (weap.GetClassName() == "PK_Stakegun")
			frame = 1;
	}
	override void Tick () {
		if (!weap || weap.owner) {
			destroy();
			return;
		}
		SetOrigin(weap.pos + (0,0,30),true);
	}
	states {
		Spawn:
			PWIC # -1;
			stop;
	}
}

Class PK_Projectile : PK_BaseActor abstract {
	protected bool mod; //affteced by Weapon Modifier
	mixin PK_Math;
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
		height 6;
		radius 6;
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
		if (target && target.CountInv("PK_WeaponModifier"))
			mod = true;
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

/*	A base projectile class that can stick into walls and planes.
	It'll move with the sector if it hit a moving one (e.g. door/platform).
	Base for stakes, bolts and shurikens.
*/
Class PK_StakeProjectile : PK_Projectile {
	protected int hitplane; //0: none, 1: floor, 2: ceiling
	protected actor stickobject; //a non-monster object that was hit
	protected SecPlane stickplane; //a plane to stick to
	protected vector2 sticklocation; //the point at the line the stake collided with
	protected double stickoffset; //how far the stake is from the nearest ceiling or floor (depending on whether it hit top or bottom part of the line)
	protected double topz; //ZAtPoint below stake
	protected double botz; //ZAtPoint above stake
	actor pinvictim; //The fake corpse that will be pinned to a wall
	protected double victimofz; //the offset from the center of the stake to the victim's corpse center
	protected state sspawn; //pointer to Spawn label
	Default {
		+MOVEWITHSECTOR
		+NOEXTREMEDEATH
	}
	
	//this function is called when the projectile dies and checks if it hit something
	virtual void StickToWall() {
		string myclass = GetClassName();
		bTHRUACTORS = true;
		bNOGRAVITY = true;
		A_Stop();
		
		if (stickobject) {
			stickoffset = pos.z - stickobject.pos.z;
			if (pk_debugmessages > 2)
				console.printf("%s hit %s at at %d,%d,%d",myclass,stickobject.GetClassName(),pos.x,pos.y,pos.z);
			return;
		}
		
		//use linetrace to get information about what we hit
		FLineTraceData trac;
		LineTrace(angle,radius+64,pitch,TRF_NOSKY|TRF_THRUACTORS|TRF_BLOCKSELF,data:trac);
		sticklocation = trac.HitLocation.xy;
		topz = CurSector.ceilingplane.ZatPoint(sticklocation);
		botz = CurSector.floorplane.ZatPoint(sticklocation);
		
		//if hit floor/ceiling, we'll attach to them:
		if (trac.HitLocation.z >= topz) {
			hitplane = 2;
			if (pk_debugmessages > 2)
				console.printf("%s hit ceiling at at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
		}
		else if (trac.HitLocation.z <= botz) {
			hitplane = 1;
			if (pk_debugmessages > 2)
				console.printf("%s hit floor at at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
		}
		if (hitplane > 0)
			return;
			
		//3D floor is easiest, so we start with it:
		if (trac.Hit3DFloor) {
			//we simply attach the stake to the 3D floor's top plane, nothing else
			F3DFloor flr = trac.Hit3DFloor;
			stickplane = flr.top;
			stickoffset = stickplane.ZAtPoint(sticklocation) - pos.z;
			if (pk_debugmessages > 2)
				console.printf("%s hit a 3D floor at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
			return;
		}
		//otherwise see if we hit a line:
		if (trac.HitLine) {
			//check if the line is two-sided first:
			let tline = trac.HitLine;
			//if it's one-sided, it can't be a door/lift, so don't do anything else:
			if (!tline.backsector) {
				if (pk_debugmessages > 2)
					console.printf("%s hit one-sided line, not doing anything else",myclass);
				return;
			}
			//if it's two-sided:
			//check which side we're on:
			int lside = PointOnLineSide(pos.xy,tline);
			string sside = (lside == 0) ? "front" : "back";
			//we'll attack the stake to the sector on the other side:
			let targetsector = (lside == 0 && tline.backsector) ? tline.backsector : tline.frontsector;
			let floorHitZ = targetsector.floorplane.ZatPoint (sticklocation);
			let ceilHitZ = targetsector.ceilingplane.ZatPoint (sticklocation);
			string secpart = "middle";
			//check if we hit top or bottom floor (i.e. door or lift):
			if (pos.z <= floorHitZ) {
				secpart = "lower";
				stickplane = targetsector.floorplane;
				stickoffset = floorHitZ - pos.z;
			}
			else if (pos.z >= ceilHitZ) {
				secpart = "top";
				stickplane = targetsector.ceilingplane;
				stickoffset = ceilHitZ - pos.z;
			}
			if (pk_debugmessages > 2)
				console.printf("%s hit the %s %s part of the line at %d,%d,%d",myclass,secpart,sside,pos.x,pos.y,pos.z);
		}
	}
	//record a non-monster solid object the stake runs into if there is one:
	override int SpecialMissileHit (Actor victim) {
		if (!victim.bISMONSTER && victim.bSOLID) {
			stickobject = victim;
		}
		return -1;
	}
	//virtual for breaking; child actors override it to add debris spawning and such:
	virtual void StakeBreak() {
		if (pk_debugmessages > 2)
			console.printf("%s destroyed",GetClassName());
		if (self)
			destroy();
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		sspawn = FindState("Spawn");
	}
	override void Tick () {
		super.Tick();
		//all stake-like projectiles need to face their movement direction while in Spawn sequence:
		if (!isFrozen() && sspawn && InStateSequence(curstate,sspawn))
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
		//otherwise stake is dead, so we'll move it alongside the object/plane it's supposed to be attached to:
		if (bTHRUACTORS) {
			//topz = CurSector.ceilingplane.ZAtPoint(pos.xy);
			//botz = CurSector.floorplane.ZAtPoint(pos.xy);
			//destroy the stake if it's run into ceiling/floor by a moving sector (e.g. a door opened, pulled the stake up and pushed it into the ceiling):
			if (pos.z >= ceilingz-height || pos.z <= floorz) {
				StakeBreak();
				return;
			}
			//attached to floor/ceiling:
			if (hitplane > 0) {
				if (hitplane > 1)
					SetZ(ceilingz);
				else
					SetZ(floorz);
			}
			//attached to a plane (hit a door/lift earlier)
			else if (stickplane) {
				SetZ(stickplane.ZAtPoint(sticklocation) - stickoffset);
			}
			//otherwise attach it to the solid object it hit earlier:
			else if (stickobject)
				SetZ(stickobject.pos.z + stickoffset);
			//and if there's a decorative corpse on the stake, move it as well:
			if (pinvictim)
				pinvictim.SetZ(pos.z + victimofz);
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
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (target && target.CountInv("PK_WeaponModifier")) {
			A_SetRenderstyle(5,Style_AddShaded);
			SetShade("FF2000");
			scale *= 2;
		}
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
		+BOUNCEONWALLS
		+BOUNCEONFLOORS
		gravity 0.7;
		bouncefactor 0.55;
		bouncecount 1;
	}
	states {
	Spawn:
		MODL A 1 A_FadeOut(0.035);
		loop;
	}
}

Class PK_GenericExplosion : PK_SmallDebris {
	int randomdebris;
	int explosivedebris;
	int smokingdebris;
	int quakeintensity;
	int quakeduration;
	int quakeradius;
	property randomdebris : randomdebris;
	property explosivedebris : explosivedebris;
	property smokingdebris : smokingdebris;
	property quakeintensity : quakeintensity;
	property quakeduration : quakeduration;
	property quakeradius : quakeradius;
	Default {
		PK_GenericExplosion.randomdebris 16;
		PK_GenericExplosion.smokingdebris 12;
		PK_GenericExplosion.explosivedebris 0;
		PK_GenericExplosion.quakeintensity 3;
		PK_GenericExplosion.quakeduration 12;
		PK_GenericExplosion.quakeradius 220;
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
		A_Quake(quakeintensity,quakeduration,0,quakeradius,"");
		if (randomdebris > 0) {
			for (int i = randomdebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
					debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
					debris.A_SetScale(0.5);
				}
			}
		}
		if (smokingdebris > 0) {
			for (int i = smokingdebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_SmokingDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,10) : frandom[sfx](5,15);
					debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10),zvel);
				}
			}
		}
		if (explosivedebris > 0) {
			for (int i = explosivedebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_ExplosiveDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,10) : frandom[sfx](5,15);
					debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10),zvel);
				}
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
		gravity 0.3;
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
		A_FadeOut(0.022);
	}
}

Class PK_SmokingDebris : PK_RandomDebris {	
	Default {
		scale 0.5;
		gravity 0.25;
	}
	override void Tick () {
		super.Tick();	
		if (isFrozen())
			return;
		let smk = Spawn("PK_WhiteSmoke",pos+(frandom[smk](-4,4),frandom[smk](-4,4),frandom[smk](-4,4)));
		if (smk) {
			smk.alpha = alpha*0.4;
			smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
		}
		A_FadeOut(0.03);
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
		inventory.pickupmessage "$PKI_SHELLS";
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
		inventory.pickupmessage "$PKI_FREEZEAMMO";
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
		inventory.pickupmessage "$PKI_STAKEAMMO";
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
		inventory.pickupmessage "$PKI_GRENADEAMMO";
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
		inventory.pickupmessage "$PKI_MINIGUNAMMO";
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
		inventory.pickupmessage "$PKI_STARAMMO";
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
		inventory.pickupmessage "$PKI_ELECTROAMMO";
		inventory.pickupsound "pickups/ammo/battery";
		inventory.icon "pkhshock";
		inventory.amount 40;
		inventory.maxamount 500;
		ammo.backpackamount 80;
		ammo.backpackmaxamount 500;
		scale 0.4;
		yscale 0.34;
	}
	states	{
	spawn:
		AMEL A -1;
		stop;
	}
}

Class PK_RifleBullets : Ammo {
	Default {
		inventory.pickupmessage "$PKI_RIFLEAMMO";
		inventory.pickupsound "pickups/ammo/riflebullets";
		inventory.icon "pkhmag";
		inventory.amount 50;
		inventory.maxamount 250;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 250;
		scale 0.4;
	}
	states	{
	spawn:
		AMRB A -1;
		stop;
	}
}

Class PK_FuelAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_FUELAMMO";
		inventory.pickupsound "pickups/ammo/fuel";
		inventory.icon "pkhfuel";
		inventory.amount 50;
		inventory.maxamount 500;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 500;
		xscale 0.3;
		yscale 0.24;
	}
	states	{
	spawn:
		AMFU B -1;
		stop;
	}
}


Class PK_BoltAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_BOLTAMMO";
		inventory.pickupsound "pickups/ammo/bolts";
		inventory.icon "pkhbolts";
		inventory.amount 30;
		inventory.maxamount 500;
		ammo.backpackamount 30;
		ammo.backpackmaxamount 500;
		xscale 0.4;
		yscale 0.3;
	}
	states	{
	spawn:
		AMBO A -1;
		stop;
	}
}

Class PK_BombAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_HEATERAMMO";
		inventory.pickupsound "pickups/ammo/bombs";
		inventory.icon "pkhbombs";
		inventory.amount 50;
		inventory.maxamount 250;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 250;
		xscale 0.5;
		yscale 0.42;
	}
	states	{
	spawn:
		AMBM B -1;
		stop;
	}
}

/////////////////////////
// AMMO SPAWN CONTROL
/////////////////////////

/*	This object is designed to replace each ammo pickupmessage
	and spawn either primary or alternative ammo for 2 weapons.
	With a small chance it'll also spawn alternative ammo
	next to the primary.
*/

Class PK_BaseAmmoSpawner : Actor {
	Class<Ammo> primary1; //primary ammo type for the 1st weapon
	Class<Ammo> secondary1; //secondary ammo type for the 1st weapon
	Class<Ammo> primary2; //primary ammo type for the 2nd weapon
	Class<Ammo> secondary2; //secondary ammo type for the 2nd weapon
	Class<Weapon> weapon1; //1st weapon class to spawn ammo for
	property weapon1 : weapon1;
	Class<Weapon> weapon2; //2nd weapon class to spawn ammo for
	property weapon2 : weapon2;
	double altSetChance; //chance of spawning ammo for weapon2 instead of weapon1
	double secondaryChance; //chance of spawning ammotype2 instead of ammotype1
	double secondaryChance2; //chance of spawning ammotype2 instead of ammotype1 for weapon2 (optional)
	double twoPickupsChance;	//chance of spawning the second ammotype next to the one chosen to be spawned
	double dropChance; //chance that this will be obtainable if dropped by an enemy
	property altSetChance : altSetChance;
	property secondaryChance : secondaryChance;
	property secondaryChance2 : secondaryChance2;
	property twoPickupsChance : twoPickupsChance;
	property dropChance : dropChance;
	Default {
		+NOBLOCKMAP
		//+INVENTORY.NEVERRESPAWN
		PK_BaseAmmoSpawner.altSetChance 50;
		PK_BaseAmmoSpawner.secondaryChance 35;
		PK_BaseAmmoSpawner.twoPickupsChance 25;
		PK_BaseAmmoSpawner.dropChance 50;
	}
	
	void SpawnAmmoPickup(vector3 spawnpos, Class<Ammo> ammopickup) {
		let am = Ammo(Spawn(ammopickup,spawnpos));
		if (am) {
			am.vel = vel;
			if (bDROPPED) {
				am.bDROPPED = true;
				am.amount /= 2;
				//console.printf("Spawner bDROPPED: %d | ammo bDROPPED: %d",bDROPPED,am.bDROPPED);
			}
		}		
	}
	
	const ammoSpawnOfs = 16;
	static const double AmmoSpawnPos[] = {
		ammoSpawnOfs,
		-ammoSpawnOfs,
		-ammoSpawnOfs,
		ammoSpawnOfs,
		ammoSpawnOfs
	};	
	vector3 FindSpawnPosition() {
		vector3 spawnpos = (0,0,0);
		for (int i = 0; i < AmmoSpawnPos.Size()-1; i++) {
			let ppos = pos + (AmmoSpawnPos[i],AmmoSpawnPos[i+1],pos.z);
			//Spawn("AmmoPosTest",ppos);
			if (!Level.IsPointInLevel(ppos))
				continue;
			sector psector = Level.PointInSector(ppos.xy);
			if (curSector && curSector == psector) {
				spawnpos = ppos;
				break;
			}
			double ofsFloor = psector.NextLowestFloorAt(ppos.x,ppos.y,ppos.z);
			if (abs(floorz - ofsFloor) <= 16) {
				spawnpos = (ppos.xy,ofsFloor);
				break;
			}
		}
		return spawnpos;
	}
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		//weapon1 is obligatory; if for whatever reason it's empty, destroy it:
		if (!weapon1) {
			destroy();
			return;
		}
		if (bDROPPED && dropChance < frandom[ammoSpawn](1,100)) {
			destroy();
			return;
		}
		//get ammo classes for weapon1 and weapon2:
		primary1 = GetDefaultByType(weapon1).ammotype1;
		secondary1 = GetDefaultByType(weapon1).ammotype2;			
		if (weapon2) {
			primary2 = GetDefaultByType(weapon2).ammotype1;
			secondary2 = GetDefaultByType(weapon2).ammotype2;	
			//if none of the players have weapon1, increase the chance of spawning ammo for weapon2:
			if (!PK_MainHandler.CheckPlayersHave(weapon1))
				altSetChance *= 1.5;
			//if none of the players have weapon2, decreate the chance of spawning ammo for weapon2:
			if (!PK_MainHandler.CheckPlayersHave(weapon2))
				altSetChance /= 1.5;
			//if players have neither, both calculations will happen, ultimately leaving the chance unchanged!
		}
		//define two possible ammo pickups to spawn:
		class<Ammo> ammo1toSpawn = primary1;
		class<Ammo> ammo2toSpawn = secondary1;
		//with a chance they'll be replaced with ammo for weapon2:
		if (weapon2 && altSetChance >= frandom[ammoSpawn](1,100)) {
			ammo1toSpawn = primary2;
			ammo2toSpawn = secondary2;
			if (secondaryChance2)
				secondaryChance = secondaryChance2;
		}
		//finally, decide whether we need to spawn primary or secondary ammo:
		class<Ammo> tospawn = (secondaryChance >= frandom[ammoSpawn](1,100)) ? ammo2toSpawn : ammo1toSpawn;
		SpawnAmmoPickup(pos,tospawn);
		//console.printf("Spawning %s at %d,%d,%d",tospawn.GetClassName(),pos.x,pos.y,pos.z);
		//if the chance for two pickups is high enough, spawn the other type of ammo:
		if (twoPickupsChance >= frandom[ammoSpawn](1,100)) {
			class<Ammo> tospawn2 = (tospawn == ammo1toSpawn) ? ammo2toSpawn : ammo1toSpawn;
			let spawnpos = FindSpawnPosition();
			//console.printf("Spawning %s at %d,%d,%d",tospawn2.GetClassName(),spawnpos.x	,spawnpos.y,spawnpos.z);
			if (spawnpos != (0,0,0))
				SpawnAmmoPickup(spawnpos,tospawn2);
		}
	}
}

Class PK_BaseAmmoSpawner_Shell : PK_BaseAmmoSpawner {
	Default {
		PK_BaseAmmoSpawner.weapon1 "PK_Stakegun";
		PK_BaseAmmoSpawner.secondaryChance 25;
		PK_BaseAmmoSpawner.weapon2 "PK_Boltgun";
		PK_BaseAmmoSpawner.secondaryChance2 45;
	}
}

Class PK_BaseAmmoSpawner_ShellBox : PK_BaseAmmoSpawner_Shell {
	Default {
		PK_BaseAmmoSpawner.twoPickupsChance 40;
	}
}

Class PK_BaseAmmoSpawner_Clip : PK_BaseAmmoSpawner {
	Default {
		PK_BaseAmmoSpawner.weapon1 "PK_Shotgun";
		PK_BaseAmmoSpawner.weapon2 "PK_Chaingun";
		PK_BaseAmmoSpawner.secondaryChance2 80; //chaingun bullets should be much more common than rockets
	}
}

Class PK_BaseAmmoSpawner_ClipBox : PK_BaseAmmoSpawner_Clip {
	Default {
		PK_BaseAmmoSpawner.twoPickupsChance 40;
		PK_BaseAmmoSpawner.altSetChance 60; //since clip boxes are more often placed on the maps, chance for chaingun ammo should be higher for them
	}
}

Class PK_BaseAmmoSpawner_RocketAmmo : PK_BaseAmmoSpawner {
	Default {
		PK_BaseAmmoSpawner.weapon1 "PK_Chaingun";
		PK_BaseAmmoSpawner.weapon2 "PK_Rifle";
		PK_BaseAmmoSpawner.secondaryChance 30; //rocket ammo spawns should provide rockets more commonly thab bullets
		PK_BaseAmmoSpawner.secondaryChance2 50;
		PK_BaseAmmoSpawner.altSetChance 25;
		PK_BaseAmmoSpawner.twoPickupsChance 60;
	}
}

Class PK_BaseAmmoSpawner_Cell : PK_BaseAmmoSpawner {
	Default {
		PK_BaseAmmoSpawner.weapon1 "PK_ElectroDriver";
		PK_BaseAmmoSpawner.weapon2 "PK_Rifle";
		PK_BaseAmmoSpawner.altSetChance 50;
	}
}

Class PK_BaseAmmoSpawner_CellPack : PK_BaseAmmoSpawner {
	Default {
		PK_BaseAmmoSpawner.weapon1 "PK_ElectroDriver";
		PK_BaseAmmoSpawner.weapon2 "PK_Rifle";
		PK_BaseAmmoSpawner.altSetChance 30; //cell packs are usually placed next to BFG, so it should provide Electrodriver more commonly
	}
}

/*	This special spawner is meant to replace Stimpack/Medikit
	(since the player is supposed to heal with enemy souls)
	and will randomly spawn any ammo for any weapon the player has.
*/

Class PK_AmmoSpawner_Stimpack : PK_BaseAmmoSpawner {
	override void PostBeginPlay() {
		array < Class<Weapon> > wweapons; //this will hold all weapons that at least one player has
		//iterate over a static array of all weapon classes in the mod (see pk_items.zs):
		for (int i = 0; i < PK_InvReplacementControl.pkWeapons.Size(); i++) {
			Class<Weapon> weap = PK_InvReplacementControl.pkWeapons[i];
			//if at least one player has that weapon class and that weapon uses ammo, push it in the wweapons array:
			if (GetDefaultByType(weap).ammotype1 && GetDefaultByType(weap).ammotype2 && PK_MainHandler.CheckPlayersHave(weap))
				wweapons.Push(weap);
		}
		//randomly choose a weapon to spawn ammo for:
		int toSpawn = random[ammoSpawn](0,wweapons.Size() - 1);
		weapon1 = wweapons[tospawn];
		super.PostBeginPlay();
	}
}

/*Class AmmoPosTest : Actor {
	Default {
		+BRIGHT
		+NOINTERACTION
	}
	states {
	Spawn:
		BAL1 A 35;
		stop;
	}
}*/