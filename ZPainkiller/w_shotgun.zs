Class PK_Shotgun : PKWeapon {
	int freload; //counter for freezer reload to prevent from quickly re-entering AltFire by using Fire first
	Default {
		PKWeapon.emptysound "weapons/empty/shotgun";
		PKWeapon.ammoSwitchCVar 'pk_switch_ShotgunFreezer';
		weapon.slotnumber 2;
		weapon.ammotype1 "PK_Shells";
		weapon.ammogive1 20;
		weapon.ammouse1  1;
		weapon.ammotype2 "PK_FreezerAmmo";
		weapon.ammogive2 5;
		weapon.ammouse2 1;
		inventory.pickupmessage "$PKI_SHOTGUN";
		inventory.pickupsound "pickups/weapons/shotgun";
		inventory.icon "PKWIA0";
		Tag "$PK_SHOTGUN_TAG";
		Obituary "$PKO_SHOTGUN";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || level.isFrozen())
			return;
		if (freload > 0)
			freload--;
		//Console.Printf("%d",freload);
	}
	states {
	Spawn:
		PKWI A -1;
		stop;
	SpawnSp:
		PSHZ ABCDEFGH 4;
		loop;
	Ready:
		PSHT A 1 {
			if (invoker.freload <= 0)
				PK_WeaponReady();
			else
				PK_WeaponReady(WRF_NOSECONDARY);
		}
		loop;
	Fire:
		PSHT A 2 {
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_Quake(1,7,0,1,"");
			PK_AttackSound("weapons/shotgun/fire",CHAN_VOICE);
			A_Overlay(PSP_PFLASH,"Flash");
			vector2 spread = (invoker.hasWmod) ? (2.8, 2.3) : (7, 5);
			PK_FireBullets(spread.x,spread.y,10,9,pufftype:"PK_ShotgunPuff",spawnheight:player.viewz-pos.z-44,spawnofs:9);
			A_ZoomFactor(0.99,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
			A_AttachLight('PKWeaponlight', DynamicLight.PulseLight, "e1b03e", 64, 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF|DYNAMICLIGHT.LF_ATTENUATE, ofs: (32,32,player.viewheight), param: 0.1);
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		PSHT CDF 1 A_WeaponOffset(10,2,WOF_ADD);
		TNT1 A 0 A_RemoveLight('PKWeaponlight');
		PSHT HH 2 A_WeaponOffset(1,5,WOF_ADD);
		PSHT HH 2 A_WeaponOffset(-1,4,WOF_ADD);
		PSHT GFE 2 A_WeaponOffset(-5,-6,WOF_ADD);
		PSHT DCBA 2 A_WeaponOffset(-3.22,-1.22,WOF_ADD);
		PSHT A 9 { //allows immediate primary refire but prevents using altfire immediately
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
		}
		goto ready;
	AltFire:
		PSHT A 5 {
			PK_AttackSound("weapons/shotgun/freezer",CHAN_7);
			A_FireProjectile("PK_FreezerProjectile",0,true,-4,spawnheight:6);
			A_FireProjectile("PK_FreezerProjectile",0,false,4,spawnheight:6);
			invoker.freload = 55;
		}
		PSHF BCDE 2 {
			A_WeaponOffset(-1,   1.2,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF FGHI 4 {
			A_WeaponOffset(-0.4, 0.4,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
		}
		PSHF JKLM 4 {
			A_WeaponOffset( 0.4,-0.4,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
		}
		PSHF EDCB 2 {
			A_WeaponOffset( 1,  -1.2,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
		}
		PSHT A 1 A_WeaponOffset(0,32,WOF_INTERPOLATE);
		//TNT1 A 0 A_ReFire();			
		goto ready;
	Flash:
		SMUZ A 2 bright {
			A_Overlay(PSP_HIGHLIGHTS,"Hightlights");
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.95);
			let fl = Player.FindPsprite(OverlayID());
			if (fl)
				fl.frame = random[sfx](0,3);
		}
		stop;
	Hightlights:
		PSHT Z 2 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),1);
		}
		stop;
	}
}
	
Class PK_FreezerProjectile : PK_Projectile {
	Default {
		Translation "112:127=%[0.00,2.00,2.00]:[0.00,0.00,1.01]";
		renderstyle 'Add';
		alpha 0.4;
		+BRIGHT
		+HITTRACER
		+ROLLSPRITE
		+ROLLCENTER
		scale 0.15;
		seesound "";
		deathsound "";
		speed 50;
		damage 0;
		PK_Projectile.flarecolor "08caed";
		PK_Projectile.flarescale 0.065;
		PK_Projectile.flarealpha 0.7;
		PK_Projectile.trailcolor "08caed";
		PK_Projectile.trailscale 0.05;
		PK_Projectile.trailalpha 0.2;
		PK_Projectile.trailfade 0.06;
		PK_Projectile.trailshrink 0.7;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		A_AttachLight('frez', DynamicLight.PointLight, "75edff", 40, 0, flags: DYNAMICLIGHT.LF_ATTENUATE);
		if (mod)
			vel *= 1.5;
	}
	states 	{
	Spawn:
		BAL7 A 1;
		loop;
	Death:
		TNT1 A 0 {
			A_Stop();
			A_AttachLight('frez', DynamicLight.RandomFlickerLight, "75edff", 32, 52, flags: DYNAMICLIGHT.LF_ATTENUATE);
			roll = random(0,359); 
			if (tracer && (tracer.bISMONSTER || tracer.player) && !tracer.bBOSS) {
				tracer.GiveInventory("PK_FreezeControl",1);
				let frz = PK_FreezeControl(tracer.FindInventory("PK_FreezeControl"));
				if (frz) {
					frz.fcounter+=64;
					//double freeze duration if player has Weapon Modifier:
					if (mod)
						frz.fcounter+=64;
				}
			}
			for (int i = random[sfx](10,15); i > 0; i--) {
				let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
					debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
					debris.A_SetScale(frandom[sfx](0.12,0.25));
					debris.A_SetRenderstyle(0.65,Style_AddShaded);
					debris.SetShade("08caed");
				}
			}
		}
		BAL7 CCCDDDEEE 2 {
			roll+=10;
			A_FadeOut(0.1);
			scale*=0.9;
		}
		wait;
	}
}



Class PK_FrozenChunk : PK_SmallDebris {
	Default {
		PK_SmallDebris.dbrake 0.9;
		//renderstyle 'Shaded';
		//stencilcolor "08caed";
		renderstyle 'Translucent';
		//Translation "PK_IceChunk";
		alpha 0.8;
		scale 0.5;
		gravity 0.3;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		wrot = frandom[sfx](4,8)*randompick[sfx](-1,1);
		scale *= frandom[sfx](0.7,1.1);
		frame = random[sfx](1,5);
	}
	override void Tick() {
		super.Tick();
		if (!master) {
			let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-4,4),frandom[part](-4,4),frandom[part](0,4)));
			if (smk) {
				smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
				smk.scale *= 0.6;
			}
			destroy();
			return;
		}
	}
	states {
	Spawn:
		IGIB # 1 {
			roll += wrot;
		}
		loop;
	Death:
		IGIB # 1 {
			scale *= 0.99;
			if (scale.x < 0.01) {
				destroy();
				return;
			}
		}
		loop;
	}
}

Class PK_FrozenLayer : PK_SmallDebris {
	Default {
		+NOINTERACTION
		renderstyle 'shaded';
		stencilcolor "08caed";
	}
	override void Tick() {
		if (master && master.FindInventory("PK_FreezeControl")) {
			SetOrigin(master.pos,true);
		}
		else
			destroy();
	}
	states {
	Spawn:
		#### # -1;
		stop;
	}
}
	
Class PK_FreezeControl : PK_InventoryToken {
	int fcounter;
	uint ownertrans;
	bool grav;
	override void ModifyDamage (int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags) {
		if (damage > 0 && inflictor && owner && passive) {
			//reduces fire damage:
			if (damagetype == 'Fire')
				newdamage = damage * 0.5;
			//x1.5 damage if hitting with a shotgun blast:
			else if (source && source.player && source.player.readyweapon && source.player.readyweapon is "PK_Shotgun")
				newdamage = damage * 1.5;
			//for all other weapons x1.25 damage:
			else
				newdamage = damage*1.25;
		}
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		if (owner.FindInventory("PK_BurnControl"))
			owner.TakeInventory("PK_BurnControl",1);
		grav = owner.bNOGRAVITY;
		if (grav)
			owner.bNOGRAVITY = false;
		owner.bNOPAIN = true;
		ownertrans = owner.translation;
		owner.bInConversation = true; //this actually makes the monster completely frozen AND disable wake-up on damage
		owner.A_SetTranslation("PK_Ice");
		owner.A_StartSound("weapons/shotgun/freeze");
		let layer = Spawn("PK_FrozenLayer",owner.pos);
		if (layer) {
			layer.master = owner;
			layer.sprite = owner.sprite;
			layer.frame = owner.frame;
			layer.angle = owner.angle;
			layer.scale.x = owner.scale.x*1.15;
			layer.scale.y = owner.scale.y*1.07;
			layer.bSPRITEFLIP = owner.bSPRITEFLIP;
			layer.bYFLIP = owner.bYFLIP;
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (level.isFrozen() || !owner)
			return;
		owner.A_SetTics(-1);
		fcounter--;
		if (fcounter <= 0) {
			owner.A_SetTics(20);
			DepleteOrDestroy();
			return;
		}
		if (owner.health <= 0) {
			for (int i = 7; i >= 0; i--)
				owner.A_SoundVolume(i,0);
			int rad = owner.radius;
			for (int i = random[sfx](5,8); i > 0; i--) {
				let ice = Spawn("PK_FrozenChunk",owner.pos + (frandom[sfx](-rad,rad),frandom[sfx](-rad,rad),frandom[sfx](0,owner.default.height)));
				if (ice) {
					ice.vel = (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](2,6));
					ice.master = owner;
					ice.gravity = 0.7;
				}
			}
			for (int i = random[sfx](12,16); i > 0; i--) {
				let ice = Spawn("PK_RandomDebris",owner.pos + (frandom[sfx](-rad,rad),frandom[sfx](-rad,rad),frandom[sfx](0,owner.default.height)));
				if (ice) {
					ice.vel = (frandom[sfx](-3.5,3.5),frandom[sfx](-3.5,3.5),frandom[sfx](3,7));
					ice.master = owner;
					ice.gravity = 0.5;
					ice.A_SetRenderstyle(1.0,Style_AddShaded);
					ice.SetShade("08caed");
					ice.A_SetScale(frandom[sfx](0.4,0.75));
				}
			}
			owner.A_StartSound("weapons/shotgun/freezedeath");
			owner.gravity = 0.4;
			owner.bINVISIBLE = true;
			owner.vel *= 0.15;
			owner.A_NoBlocking();
			owner.deathsound = "";
			owner.bDONTTHRUST = true;
			owner.A_SetTics(-1);
			owner.vel = (frandom[sfx](-1.3,1.3),frandom[sfx](-1.3,1.3),frandom[sfx](3,4));
			double ownersize = (owner.radius * owner.default.height) / 8;
			//standard zombieman size:
			if (ownersize >= 140) {
				let icebod = PK_IceCorpse(Spawn("PK_IceCorpse",owner.pos));
				if (icebod) {
					icebod.master = owner;
					icebod.A_SetScale(Clamp(owner.radius*0.05,0.1,1.5));
					icebod.bSPRITEFLIP = random[sfx](0,1);
				}
				let rc = PK_IceRibcage(Spawn("PK_IceRibcage",owner.pos));
				if (random[sfx](0,1) == 1) {
					if (rc) {
						rc.master = owner;
						rc.A_SetScale(Clamp(owner.radius*0.03,0.1,1));
						rc.scale *= frandom[sfx](0.7,1.1);
						rc.bSPRITEFLIP = random[sfx](0,1);
						rc.vel = (frandom[sfx](-1.7,1.7),frandom[sfx](-1.7,1.7),frandom[sfx](2,4));
					}
				}
			}
			//large size: spawn another ribcage
			if (ownersize >= 190) {				
				let rc = PK_IceRibcage(Spawn("PK_IceRibcage",owner.pos));
				if (rc) {
					rc.master = owner;
					rc.A_SetScale(Clamp(owner.radius*0.03,0.1,1));
					rc.scale *= frandom[sfx](0.7,1.1);
					rc.bSPRITEFLIP = random[sfx](0,1);
					rc.vel = (frandom[sfx](-1.7,1.7),frandom[sfx](-1.7,1.7),frandom[sfx](2,4));
				}
			}
			DepleteOrDestroy();
			return;
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		owner.bNOPAIN = owner.default.bNOPAIN;
		owner.bInConversation = false;
		owner.bNOGRAVITY = grav;
		owner.translation = ownertrans;
		super.DetachFromOwner();
	}
}

class PK_IceCorpse : PK_FrozenChunk {
	Default {
		translation "PK_IceChunk";
		renderstyle 'Normal';
		+NOINTERACTION
	}
	override void PostBeginPlay() {
		PK_SmallDebris.PostBeginPlay();
	}
	override void Tick() {
		Super.Tick();
		if (master)
			PK_SetOrigin(master.pos);
	}
	States {
	Spawn:
		IGBZ ABCD 3;
		IGBZ E -1;
		stop;
	Death:
		stop;
	}
}

class PK_IceRibcage : PK_IceCorpse {
	Default {
		-NOINTERACTION
		gravity 0.8;
	}
	override void Tick() {
		PK_FrozenChunk.Tick();
	}
	States {
	Spawn:
		IGIB A -1;
		stop;
	}
}

Class PK_ShotgunPuff : PK_BulletPuff {
	Default {
		+HITTRACER
		+PUFFONACTORS
	}
	states {
	Spawn:
		TNT1 A 1 NoDelay {		
			if (target && tracer && tracer.bISMONSTER && !tracer.bDONTTHRUST && !tracer.bBOSS && !tracer.bFLOAT && tracer.mass <= 400 && tracer.health <= 0 && tracer.Distance3D(target) <= 200 && !tracer.FindInventory("PK_PushAwayControl") && !tracer.FindInventory("PK_FreezeControl")) {
				tracer.GiveInventory("PK_PushAwayControl",1);
				let pac = PK_PushAwayControl(tracer.FindInventory("PK_PushAwayControl"));
				if (pac) {
					//initial push away speed is based on mosnter's mass:
					double pushspeed = LinearMap(tracer.mass,100,400,20,5);
					//a modifier is added based on how far away the player is
					double pushmod = Clamp(LinearMap(Distance3D(target),32,256,1.2,0), 0, 1);
					if (pushmod <= 0)
						return ResolveState(null);
					pushspeed = Clamp(pushspeed,5,20) * frandom[sfx](0.85,1.2) * pushmod;
					//bonus Z velocity is based on the players view pitch (so that you can knock monsters further by looking up):
					double pushz = Clamp(LinearMap(target.pitch,0,-90,0,10), 0, 10) * pushmod;
					tracer.Vel3DFromAngle(
						pushspeed,
						target.angle,
						Clamp(target.pitch - 5, -15, -45)
					);
					tracer.vel.z += pushz;
					//if the push is strong enough and the monster is light enough, we'll also rotate it while it's flying:
					if (pushmod > 0.7 && !tracer.bFLOAT && tracer.mass < 300) {
						tracer.gravity *= 0.75;
						pac.broll = frandom[sfx](2,5) * randompick[sfx](-1,1) * (18 / pushspeed);						
						tracer.bROLLSPRITE = true;
						//with a 15% chance we'll yeet the monster with high force just for lulz:
						if (random[hiroller](0,100) >= 85) {
							tracer.bROLLCENTER = true;
							tracer.A_SetTics(500);
							pac.broll *= 10;
							tracer.A_Scream();
							tracer.deathsound = "";
							tracer.vel *= 2;
						}
					}
					//console.printf("%s was pushed away, speed: %f, vel: %d,%d,%d, roll: %f",tracer.GetClassName(),pushspeed,tracer.vel.x,tracer.vel.y,tracer.vel.z,pac.broll);
				}
			}
			return ResolveState(null);
		}
		stop;
	}
}

Class PK_PushAwayControl : PK_InventoryToken {
	double broll;
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			destroy();
			return;
		}
		if (owner.isFrozen() || !owner.bROLLSPRITE)
			return;
		if (owner.pos.z <= owner.floorz || age > 80) {
			owner.roll = owner.default.roll;
			owner.bROLLSPRITE = owner.default.bROLLSPRITE;
			if (owner.bROLLCENTER)
				owner.A_SetTics(1);
			owner.gravity = owner.default.gravity;
			destroy();
			return;
		}
		owner.roll += broll;//= Clamp(owner.roll + broll,-45,45);
		if (!owner.bNOBLOOD && random[sfx](1,3) == 3)
			owner.SpawnBlood(owner.pos,0,1);
		broll *= 0.95;
	}
}