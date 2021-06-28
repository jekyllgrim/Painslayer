/*
	Painkiller weapons
	for ammo and weapon/ammo spawners see pk_ammo.zs
*/

Class PKWeapon : Weapon abstract {
	mixin PK_Math;
	protected int PKWflags;
	FlagDef NOAUTOPRIMARY : PKWflags, 0;
	FlagDef NOAUTOSECONDARY : PKWflags, 1;
	sound emptysound;
	property emptysound : emptysound;
	protected bool hasDexterity;
	protected bool hasWmod;
	protected vector2 targOfs;
	protected vector2 shiftOfs;
	protected bool alwaysbob;
	property alwaysbob : alwaysbob;
	protected double spitch;
	protected bool holdFireOnSelect; //a version of NOAUTOFIRE but for one attack only. It also only prevents firing in select and doesn't affect the refire function. See Chaingun and Boltgun
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
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		let icon = Spawn("PK_WeaponIcon",pos);
		if (icon)  {
			icon.master = self;
		}
		spitch = frandompick[sfx](-0.1,0.1);
	}
	/*override void Tick() {
		super.Tick();
		if (owner || isFrozen())
			return;
		A_SetAngle(angle+1.5,SPF_INTERPOLATE);
		A_SetPitch(pitch+spitch,SPF_INTERPOLATE);
		if (abs(pitch) > 8)
			spitch *= -1;
	}*/
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
		hasWmod = owner.FindInventory("PK_WeaponModifier",subclass:true);
	}
	
	action bool CheckInfiniteAmmo() {
		return (sv_infiniteammo || FindInventory("PowerInfiniteAmmo",true) );
	}
	static bool CheckWmod(actor checker) {
		if (!checker || !checker.player || !checker.player.readyweapon)
			return false;
		let weap = PKWeapon(checker.player.readyweapon);
		if (!weap || !weap.hasWmod)
			return false;
		return true;
	}
	//plays a sound and also a WeaponModifier sound if Weaponmodifier is in inventory:
	action void PK_AttackSound(sound snd = "", int channel = CHAN_AUTO, int flags = 0) {
		if (snd)
			A_StartSound(snd,channel,flags);
		//will play it only once for repeating weapons (important):
		if (invoker.hasWmod && player && !player.refire) {
			A_StartSound("pickups/wmod/use",CH_WMOD);
		}
	}
	
	//a wrapper function that fires tracers with A_FireProjectile so that they don't break on portals and such:
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
	
	/*	if a gravity-affected projectile is fired via the regular A_FireProjectile directly upwards,
		it won't actually fly upwards, it'll get a curve out of nowhere
		this function sets the pitch correctly to circumvent that
	*/
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
			//console.printf("%s out of %s: have %d, needed %d",invoker.GetClassName(),invoker.ammo1.GetClassName(),invoker.ammo1.amount,invoker.ammouse1);
			if (!(player.oldbuttons & BT_ATTACK))
				A_StartSound(invoker.emptysound);
			flags |= WRF_NOPRIMARY;
		}
		else if (invoker.bNOAUTOPRIMARY) {
			if (!(player.oldbuttons & BT_ATTACK))
				invoker.holdFireOnSelect = false;
			if (invoker.holdFireOnSelect)
				flags |= WRF_NOPRIMARY;
		}
		if ((player.cmd.buttons & BT_ALTATTACK) && (!invoker.ammo2 || invoker.ammo2.amount < invoker.ammouse2)) {
			A_ClearRefire();
			//console.printf("%s out of %s: have %d, needed %d",invoker.GetClassName(),invoker.ammo2.GetClassName(),invoker.ammo2.amount,invoker.ammouse2);
			if (!(player.oldbuttons & BT_ALTATTACK))
				A_StartSound(invoker.emptysound);
			flags |= WRF_NOSECONDARY;
		}
		else if (invoker.bNOAUTOSECONDARY) {
			if (!(player.oldbuttons & BT_ALTATTACK))
				invoker.holdFireOnSelect = false;
			if (invoker.holdFireOnSelect)
				flags |= WRF_NOSECONDARY;
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
		TNT1 A 0 {
			A_StopSound(CH_LOOP);
			A_RemoveLight('PKWeaponlight');
		}
		TNT1 A 0 A_Lower();
		wait;
	Select:
		TNT1 A 0 {
			if ((invoker.bNOAUTOPRIMARY && player.cmd.buttons & BT_ATTACK && player.oldbuttons & BT_ATTACK) ||
				(invoker.bNOAUTOSECONDARY && player.cmd.buttons & BT_ALTATTACK && player.oldbuttons & BT_ALTATTACK))
				invoker.holdFireOnSelect = true;
		}
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
			bool mod = target && PKWeapon.CheckWmod(target);
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
			Destroy();
			return;
		}
		FloatBobStrength = weap.FloatBobStrength;
		FloatBobPhase = weap.FloatBobPhase;
		name weapcls = weap.GetClassName();
		switch (weapcls) {
		case 'PK_Shotgun':
			frame = 0;
			break;
		case 'PK_Stakegun':
			frame = 1;
			break;
		case 'PK_Chaingun':
			frame = 2;
			break;
		case 'PK_ElectroDriver':
			frame = 3;
			break;
		case 'PK_Rifle':
			frame = 4;
			break;
		case 'PK_Boltgun':
			frame = 5;
			break;
		}
	}
	override void Tick () {
		if (!weap || weap.owner) {
			Destroy();
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
	static bool CheckVulnerable(actor victim, actor missile = null) {
		if (!victim)
			return false;
		/*if (missile) {
			if (missile.bMTHRUSPECIES && missile.target && missile.target.species == victim.species)
				return true;
			if (victim.bSPECTRAL && !missile.bSPECTRAL)
				return true;
		}*/
		return (victim.bSHOOTABLE && !victim.bNONSHOOTABLE && !victim.bNOCLIP && !victim.bNOINTERACTION && !victim.bINVULNERABLE && !victim.bDORMANT && !victim.bNODAMAGE  && !victim.bSPECTRAL);
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		mod = target && PKWeapon.CheckWmod(target);
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
			console.printf("%s Destroyed",GetClassName());
		if (self)
			Destroy();
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
			topz = CurSector.ceilingplane.ZAtPoint(pos.xy);
			botz = CurSector.floorplane.ZAtPoint(pos.xy);
			//Destroy the stake if it's run into ceiling/floor by a moving sector (e.g. a door opened, pulled the stake up and pushed it into the ceiling). Only do this if the stake didn't actually hit a plane before that:
			if (!hitplane && (pos.z >= topz-height || pos.z <= botz)) {
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
		if (target && PKWeapon.CheckWmod(target)) {
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
	override void Tick() {
		super.Tick();
		if (!isFrozen())
			scale.x = default.scale.x * 0.1 * vel.length(); //faster trails will be longer
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