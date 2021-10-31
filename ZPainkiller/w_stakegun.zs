Class PK_Stakegun : PKWeapon {
	Default {
		+PKWeapon.NOAUTOSECONDARY
		PKWeapon.emptysound "weapons/empty/rifle";
		PKWeapon.ammoSwitchCVar 'pk_switch_StakeGrenade';
		weapon.slotnumber 3;
		weapon.ammotype1	"PK_StakeAmmo";
		weapon.ammouse1		1;
		weapon.ammogive1	10;
		weapon.ammotype2	"PK_GrenadeAmmo";
		weapon.ammogive2	2;
		weapon.ammouse2		1;
		inventory.pickupmessage "$PKI_STAKEGUN";
		inventory.pickupsound "pickups/weapons/stakegun";
		inventory.icon "PKWIB0";
		Tag "$PK_STAKEGUN_TAG";
	}
	states {
		Cache:
			PSGT AHIJKLMN 0;
		Spawn:
			PKWI B -1;
			stop;
		Ready:
			PSGN A 1 {
				PK_WeaponReady();
				if (!PK_CheckAmmo()) {
					let psp = player.FindPSprite(PSP_Weapon);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
			}
			loop;
		Fire:
			TNT1 A 0 {
				PK_AttackSound("weapons/stakegun/fire");
				A_WeaponOffset(11,9,WOF_ADD);
				double pofs = (invoker.hasWmod) ? 0 : -2.5;
				PK_FireArchingProjectile("PK_Stake",spawnofs_xy:2,spawnheight:5,flags:FPF_NOAUTOAIM,pitch:pofs);
				A_OverlayPivot(OverlayID(),0.2,1.0);
			}
			PSGN BBBBB 1 {
				A_WeaponOffset(1.44,1.2,WOF_ADD);
				PK_WeaponRotate(-0.6,WOF_ADD);
			}
			PSGN CDEF 3 {
				A_WeaponOffset(-0.8,-0.5,WOF_ADD);
				PK_WeaponRotate(-0.2,WOF_ADD);
			}
			PSGN GGGGGGG 2 {
				A_WeaponOffset(-0.12,-0.1,WOF_ADD);
				PK_WeaponRotate(0.2923,WOF_ADD);
			}
			PSGN A 0 {
				if (invoker.ammo1.amount < 1) {
					let psp = player.FindPSprite(PSP_Weapon);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
			}
			#### HIJKAA 3 {
				A_WeaponOffset(-2.35,-2.04,WOF_ADD);
				PK_WeaponRotate(0.2923,WOF_ADD);
			}
			TNT1 A 0 {
				A_WeaponOffset(0,32,WOF_INTERPOLATE);
				PK_WeaponRotate(0);
			}
			goto ready;
		AltFire:
			PSGN A 0 {
				PK_AttackSound("weapons/stakegun/grenade");
				A_WeaponOffset(6,2,WOF_ADD);
				PK_FireArchingProjectile("PK_Grenade",spawnofs_xy:1,spawnheight:-4,flags:FPF_NOAUTOAIM,pitch:-25);
				if (!PK_CheckAmmo()) {
					let psp = Player.FindPSprite(PSP_WEAPON);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
				A_OverlayPivot(OverlayID(),0.2,1.0);
			}
			#### AA 1 {
				A_WeaponOffset(5,3,WOF_ADD);
				A_OverlayRotate(OverlayID(),-2.1,WOF_ADD);
				A_OverlayScale(OverlayID(),0.04,0.04,WOF_ADD);
			}
			#### A 0 {
				if (invoker.ammo2.amount > 0)
					A_StartSound("weapons/grenade/load",CHAN_7);
			}
			#### AAA 1 {
				A_WeaponOffset(3.5,2.5,WOF_ADD);
				A_OverlayRotate(OverlayID(),-2.1,WOF_ADD);
				A_OverlayScale(OverlayID(),0.04,0.04,WOF_ADD);
			}
			#### AAAAAA 2 {
				A_WeaponOffset(-3.2,-2,WOF_ADD);				
				A_OverlayRotate(OverlayID(),1.75,WOF_ADD);
				A_OverlayScale(OverlayID(),-0.03,-0.03,WOF_ADD);
			}
			#### AA 2 {
				A_WeaponOffset(-0.64,-0.7,WOF_ADD);
				A_OverlayRotate(OverlayID(),0);
				A_OverlayScale(OverlayID(),1,1);
				if (invoker.ammo1.amount >= invoker.ammouse1)
					PK_WeaponReady(WRF_NOSECONDARY|WRF_NOSWITCH);
			}
			#### A 0 A_WeaponOffset(0,32,WOF_INTERPOLATE);
			goto ready;
	}
}
		


/* The stake can pierce a monster and pin them to a wall (or a solid actor)
but at the same time it's NOT a piercing projectile, i.e. it should only damage
only one victim and fly through others if they exist. For that we employ a few tricks.
*/
Class PK_Stake : PK_StakeProjectile {
	protected int basedmg;
	protected bool onFire;
	actor hitvictim; //Stores the first monster hit. Allows us to deal damage only once and to only one victim
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.012;
		PK_Projectile.trailfade 0.02;
		PK_Projectile.trailalpha 0.2;
		ProjectileKickBack 50;
		-NOGRAVITY
		+NOEXTREMEDEATH
		speed 60;
		gravity 0.45;
		radius 2;
		height 2;
		damage 0;
		decal "";
		obituary "$PKO_STAKE";
		deathsound "weapons/stakegun/stakewall";
		decal "Stakedecal";
	}
	override void StakeBreak() {		
		if (!s_particles)
			s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
		if (s_particles.GetInt() > 2) {			
			for (int i = random[sfx](3,5); i > 0; i--) {
				let deb = PK_RandomDebris(Spawn("PK_RandomDebris",(pos.x,pos.y,pos.z)));
				if (deb) {
					deb.spritename = "PSDE";
					deb.frame = i;
					deb.A_SetScale(0.15);
					double vz = frandom[sfx](-1,-4);
					if (pos.z <= botz)
						vz = frandom[sfx](3,6);
					deb.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),vz);
				}
			}
		}
		A_StartSound("weapons/stakegun/stakebreak",volume:0.8, attenuation:3);
		super.StakeBreak();
	}
	override void StickToWall() { 
		super.StickToWall();
		A_RemoveLight('PKBurningStake');
		onFire = true;
		if (pinvictim) {
			pinvictim.A_Stop();
			pinvictim.SetOrigin((pos.x,pos.y,pinvictim.pos.z),false);	//make sure the fake corpse is at the middle of the stake
			if (blockingline)	{		//if we hit an actual wall (not a solid obstacle actor), flatten the fake corpse against the wall
				pinvictim.bWALLSPRITE = true;
				pinvictim.angle = atan2(blockingline.delta.y, blockingline.delta.x) - 90;
			}
		}
		if (pinvictim && hitvictim && !blockingline && pos.z <= floorz+4) { //remove the pinned corpse completely if the stake is basically on the floor
			pinvictim.destroy();
			//hitvictim.TakeInventory("PK_PinToWall",1);
		}
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		basedmg = 160;
		if (target) {
			pitch = target.pitch; //In case it's fired at a floor or ceiling at point-blank range, the Spawn state won't be used and the stake won't receive proper pitch. So, we do this.
		}
		if (mod) {
			bNOGRAVITY = true;
			vel = vel.unit() * speed * 1.3;
		}
		sprite = GetSpriteIndex("STAK");
	}
	override void Tick () {
		super.Tick();
		if (!onFire && (mod || age >= 12)) {
			trailactor = "PK_StakeFlame";
			trailscale = 0.08;
			A_AttachLight('PKBurningStake', DynamicLight.RandomFlickerLight, "ffb30f", 40, 44, flags: DYNAMICLIGHT.LF_ATTENUATE);
			onFire = true;
		}
	}
	override int SpecialMissileHit (Actor victim) {
		if (victim && (victim.bisMonster || victim.player) && victim != target && !hitvictim) { //We only do the following block if the actor hit by the stake exists, isn't the shooter, and the stake has never hit anyone yet
			if (mod || (self.GetClassName() == "PK_Stake" && age >= 12))
				basedmg *= 1.5;
			victim.DamageMobj (self, target, basedmg, 'normal');
			deathsound = "";
			A_StartSound("weapons/stakegun/hit",volume:0.7,attenuation:3);
			hitvictim = victim; //store the victim hit; when this is non-null, stake won't deal damage to anyone else
			if (!victim.bBOSS && victim.health <= 0 && victim.mass <= 400) { //we do the "pin to the wall" effect only if the victim is dead, not a boss and not huge
				pinvictim = PK_PinVictim(Spawn("PK_PinVictim",victim.pos)); //spawn fake corpse and give it appearance identical to the monster
				if (pinvictim) {
					victimofz = pinvictim.pos.z - pos.z;
					pinvictim.target = victim;
					pinvictim.master = self;
					pinvictim.angle = victim.angle;
					//pinvictim.A_SetSize(victim.default.radius, victim.default.height);
					pinvictim.sprite = victim.sprite;
					pinvictim.frame = victim.frame;
					pinvictim.translation = victim.translation;
					pinvictim.scale = victim.scale;
					pinvictim.A_SetRenderstyle(victim.alpha,victim.GetRenderstyle());
				}
				//the dummy item that makes the ACTUAL killed monster follow the stake (so that the fake and real corpse are synced in position — this is important for item drops, Arch-Vile ressurrect and anything else that may interact with the monster's corpse):
				victim.GiveInventory("PK_PinToWall",1);	
				let pin = victim.FindInventory("PK_PinToWall");
				if (pin)
					pin.master = self;
				if (pinvictim) {
					// This item contains an array of all visual stakes stuck in the victim:
					let ct = PK_StakeStuckCounter(victim.FindInventory("PK_StakeStuckCounter"));
					// this is needed because we need to move those stakes to the pinvictim when it spawns:
					if (ct && ct.stuckstakes.Size() > 0) {
						for (int i = ct.stuckstakes.Size()-1; i >= 0; i--) {
							if (ct.stuckstakes[i])
								ct.stuckstakes[i].master = pinvictim;
						}
					}
				}
			}
			else { // If the victim is not dead and hit by a stake, spawn fake stake that gets "stuck" in it while it's alive
				let stuck = PK_StakeStuck(Spawn("PK_StakeStuck",victim.pos + (frandom(-5,5),frandom(-5,5),victim.height * 0.65 + frandom(-5,5))));
				if (stuck) {
					stuck.master = victim;
					stuck.tracer = self;
					stuck.pitch = pitch;
					stuck.angle = angle;
					stuck.stuckangle = DeltaAngle(angle,victim.angle);
					stuck.stuckpos = stuck.pos - victim.pos;
					stuck.sprite = sprite;
				}
				if (victim.CountInv("PK_StakeStuckCounter") < 1)
					victim.GiveInventory("PK_StakeStuckCounter",1);
				let ct = PK_StakeStuckCounter(victim.FindInventory("PK_StakeStuckCounter"));
				if (ct && stuck)
					ct.stuckstakes.Push(stuck);
				return -1;
			}
		}
		if (!victim.bISMONSTER && (victim.bSOLID || victim.bSHOOTABLE)) {
			victim.DamageMobj (self, target, basedmg, 'normal');
			stickobject = victim;
			return -1;
		}
		return 1;
	}
	states {
	Cache:
		STAK A 0;
		BOLT A 0;
		PSDE A 0;
	Spawn:
		#### A 1 {
			if (pinvictim) {
				pinvictim.angle = angle;			//if we already "grabbed" a fake corpse, the stake carries it with it
				pinvictim.vel = vel;
				//pinvictim.SetOrigin(pos - (0,0,pinvictim.height),true);
			}
		}
		loop;
	Death: 
		#### A 160 StickToWall();
		#### A 0 A_SetRenderStyle(1.0,Style_Translucent);
		#### A 1 A_FadeOut(0.03);
		wait;
	Crash:
		TNT1 A 1 {
			A_RemoveLight('PKBurningStake');
			onFire = true;
		}
		stop;
	XDeath:
		TNT1 A 1 {
			A_RemoveLight('PKBurningStake');
			onFire = true;
		}
		stop;
	}
}

Class PK_StakeFlame : PK_BaseFlare {
	Default {
		scale 0.05;
		renderstyle 'translucent';
		alpha 0.85;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = random[sfx](0,359);
	}
	states {
	Spawn:
		BOM4 JKLMNOPQ 1;
		BOM5 ABCDEFGHIJKLMN 1 {
			A_FadeOut(0.02);
			scale *= 1.06;
		}
		wait;
	}
}

//Decorative stake stuck in a living monster
Class PK_StakeStuck : PK_BaseActor {
	state mmissile;
	state mmelee;
	double stuckangle;
	vector3 stuckpos;
	Default {
		+INTERPOLATEANGLES
		+NOINTERACTION
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master)
			return;
		mmissile = master.FindState("Missile");
		mmelee = master.FindState("Melee");
	}
	override void Tick () {
		super.Tick();
		if (!isFrozen() && age > 160) {
			A_SetRenderStyle(alpha,Style_Translucent);
			A_FadeOut(0.05);
		}
	}
	states {
		Spawn:
			#### A 1 NoDelay {
				if (master) {
					SetOrigin(master.pos + stuckpos,true);
					angle = master.angle - stuckangle;
					if (master.bWALLSPRITE)
						angle -= 90;
					if (master.bISMONSTER) {
						if (master.health <= 0 && (master.bBOSS || master.mass > 400))
							SetStateLabel("Fall");
						/*else if (master.InStateSequence(master.curstate,mmissile) || master.InStateSequence(master.curstate,mmelee)) {
							angle += frandom(-5,5);
							SetOrigin(pos + (frandom(-0.4,0.4),frandom(-0.4,0.4),frandom(-0.4,0.4)),true);
						}*/
					}
				}
				else
					SetStateLabel("Fall");
			}
			loop;
		Fall:
			#### A 1 {
				vel.z -= gravity;
				if (pos.z <= floorz) {
					A_Stop();
					SetOrigin((pos.x,pos.y,floorz),true);
					pitch = 0;
					bRELATIVETOFLOOR = true;
					bMOVEWITHSECTOR = true;
					SetStateLabel("End");
				}
			}
			loop;
		End:
			#### A 1 A_FadeOut(0.03);
			loop;
	}
}

Class PK_StakeStuckCounter : Inventory {
	array <PK_StakeStuck> stuckstakes;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
		inventory.maxamount 1;
	}
}

// This dummy item handles what happens to the actual monster killed by a stake
Class PK_PinToWall : PK_InventoryToken {
	//private PlayerPawn CPlayer;
	private int PrevRenderstyle;
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		PrevRenderstyle = owner.GetRenderstyle();	//save existing renderstyle
		owner.A_SetRenderstyle(alpha,STYLE_None);	//make it invisible
		owner.bNOGRAVITY = true;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.bKILLED) {
			DepleteOrDestroy();
			return;
		}
		//if (!CPlayer)
			//CPlayer = players[consoleplayer].mo;
		if (master) {
			owner.SetOrigin(master.pos,true);
		}
		//if (owner.bWALLSPRITE)
			//owner.A_SetAngle(Clamp(AngleTo(CPlayer),-40,40),SPF_INTERPOLATE);
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		owner.A_SetRenderstyle(alpha,PrevRenderstyle);		//when the item is removed, we reset the monster's renderstyle
		owner.bNOGRAVITY = owner.default.bNOGRAVITY;
		super.DetachFromOwner();
	}
}
	
Class PK_PinVictim : Actor {		//the fake corpse (receives its visuals from the stake)
	Default {
		+NOBLOCKMAP
		+THRUACTORS
		+NOGRAVITY
		//+WALLSPRITE
		radius 2;
	}
	override void Tick(){
		super.Tick();
		//if the target is alive or doesn't exist, remove fake corpse
		if (!target || !target.bKILLED) {
			destroy();
			return;
		}
		//if the stake disappeared, stop affecting the target and go away
		if (!master) {
			if (target) {
				target.A_TakeInventory("PK_PinToWall");
				target.A_Stop();
			}
			destroy();
			return;
		}
		target.SetOrigin(pos,true);
	}
	states {
		Spawn:
			#### # 1;
			loop;
	}
}

Class PK_GrenadeHitbox : Actor {
	Actor hitstake;
	Actor ggrenade;
	class<Actor> collider;
	property collider : collider;
	class<Actor> newstake;
	property newstake : newstake;
	sound combosound;
	property combosound : combosound;
	Default {
		PK_GrenadeHitbox.collider "PK_Stake";
		PK_GrenadeHitbox.newstake "PK_ExplosiveStake";		
		PK_GrenadeHitbox.combosound "weapons/stakegun/combo";		
		+NOGRAVITY
		+SOLID
		radius 16;
		height 24;
	}
	override bool CanCollideWith(Actor other, bool passive) {
		if (other && passive && collider && other is collider && master && (abs(pos.z - other.pos.z) <= height)) {
			hitstake = other;
			master = null;			
		}
		return false;
	}
	override void Tick() {
		super.Tick();
		if (!master && hitstake) {				
			let exs = Spawn(newstake,hitstake.pos);
			if (exs) {
				exs.vel = hitstake.vel;
				exs.angle = hitstake.angle;
				exs.pitch = hitstake.pitch+5;
				exs.target = hitstake.target;
				A_StartSound(combosound);
			}
			hitstake.destroy();
			if (ggrenade)
				ggrenade.destroy();
			destroy();
			return;
		}
		if (master)
			SetOrigin(master.pos - (0,0,height * 0.5),false);
	}
}
	
Class PK_Grenade : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailfade 0.035;
		PK_Projectile.trailalpha 0.3;
		Obituary "$PKO_GRENADE";
		-NOGRAVITY
		bouncetype 'hexen';
		bouncefactor 0.35;
		gravity 0.45;
		bouncesound "weapons/grenade/bounce";
		deathsound "weapons/grenade/explosion";
		height 6;
		radius 8;
		speed 13;		
		damage (25);
		ExplosionDamage 140;
	}
	override void Tick() {
		super.Tick();
		if (pos.z <= floorz) {
			vel *= 0.9999;
		}
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		let trg = PK_GrenadeHitbox(Spawn("PK_GrenadeHitbox",pos));
		trg.master = self;
		trg.ggrenade = self;
	}
	states {
	Spawn:
		MODL A 1 {
			if (vel.length() < 3) {
				bMISSILE = false;
			}
			if (pos.z <= floorz+4) {
				pitch+= 15;
				if (!s_particles)
					s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
				if (s_particles.GetInt() > 0) {
					let smk = Spawn("PK_WhiteSmoke",pos+(frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](-2,2)));
					if (smk) {
						smk.vel = (frandom[sfx](-0.5,0.5),frandom[sfx](-0.5,0.5),frandom[sfx](0.2,0.5));
						smk.A_SetScale(0.15);
						smk.alpha = 0.35;
					}
				}
			}
			else
				A_FaceMovementDirection(flags:FMDF_INTERPOLATE);
			if (Age > 70)
				SetStateLabel("XDeath");
		}
		loop;
	XDeath:
		TNT1 A 0 A_Scream();
	Death:
		TNT1 A 1 {
			A_Stop();
			bNOGRAVITY = true;
			A_RemoveChildren(1,RMVF_EVERYTHING);
			A_StopSound(CHAN_BODY);
			//A_StartSound("weapons/grenade/explosion",CHAN_5);
			A_Explode(-1);
			let exp = PK_GenericExplosion(Spawn("PK_GenericExplosion",pos));
			if (mod && exp) {
				Spawn("PK_FlameExplosion",pos);
				exp.scale *= 1.5;
				//exp.explosivedebris = 10;
				exp.smokingdebris = 4;
				double pangle;
				while (pangle < 360) {
					double zp;
					if (pos.z <= floorz)
						zp = 12;
					else if (pos.z >= ceilingz-12)
						zp = -24;
					A_SpawnItemEx(
						"PK_FlameThrowerFlame",
						xofs:16,
						zofs:zp,
						xvel:2,
						angle:pangle
					);
					pangle += 30;
				}
			}
		}
		stop;
	}
}

Class PK_FlameExplosion : PK_SmallDebris {
	Default {
		alpha 0.6;
		scale 0.8;
		renderstyle 'Add';
		+NOINTERACTION
		+BRIGHT
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[sfx](0,359);
	}
	override void Tick() {
		super.Tick();
		if (!isFrozen() && scale.x < 1)
			scale *= 1.02;
	}
	States {
	Spawn:
		FLT1 ABCDEFGHIJKLMNOPS 1;
		FLT1 TUVWXYZ 2;
		FLT2 ABCDEFG 2	A_FadeOut(0.1);
		stop;
	}
}
		

Class PK_ExplosiveStake : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "ffe8b1";
		PK_Projectile.trailscale 0.02;
		PK_Projectile.trailfade 0.04;
		PK_Projectile.trailalpha 0.35;
		-NOGRAVITY
		speed 60;
		gravity 0.45;
		radius 4;
		height 4;
		damage (40);
		decal "Scorch";
		obituary "$PKO_EXSTAKE";
	}
	states {
	Spawn:
		MODL A 1;
		loop;
	Death:
		TNT1 A 1 { 
			bNOGRAVITY = true;
			A_Quake(1,8,0,256,"");
			A_StartSound("weapons/stakegun/comboexplosion",CHAN_AUTO);
			A_Explode(256,200);			
			let ex = Spawn("PK_GenericExplosion",pos);
			if (ex)
				ex.A_SetScale(0.5);
		}
		stop;
	}
}