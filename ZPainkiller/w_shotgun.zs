Class PK_Shotgun : PKWeapon {
	int freload; //counter for freezer reload to prevent from quickly re-entering AltFire by using Fire first
	Default {
		PKWeapon.emptysound "weapons/empty/shotgun";
		weapon.slotnumber 2;
		weapon.ammotype1 "PK_Shells";
		weapon.ammogive1 20;
		weapon.ammouse1  1;
		weapon.ammotype2 "PK_FreezerAmmo";
		weapon.ammogive2 0;
		weapon.ammouse2 1;
		scale 0.23;
		inventory.pickupmessage "Picked up Shotgun/Freezer";
		inventory.pickupsound "pickups/weapons/shotgun";
		Tag "Shotgun/Freezer";
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
			A_StartSound("weapons/shotgun/fire",CHAN_VOICE);
			A_Overlay(-100,"Flash");
			A_firebullets(5,5,10,9,pufftype:"PK_BulletPuff",flags:FBF_NORANDOM|FBF_USEAMMO,missile:"PK_BulletTracer",spawnheight:player.viewz-pos.z-44,spawnofs_xy:9);
			A_ZoomFactor(0.99,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
			//A_Eject				
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		PSHT CDF 1 A_WeaponOffset(10,2,WOF_ADD);
		PSHT HHHH 1 A_WeaponOffset(0.5,2.5,WOF_ADD);
		PSHT HHHH 1 A_WeaponOffset(-0.5,2,WOF_ADD);
		PSHT GGFFEE 1 A_WeaponOffset(-2.5,-3,WOF_ADD);
		PSHT DDCCBBAAA 1 A_WeaponOffset(-1.66,-0.66,WOF_ADD);
		PSHT A 8 { //allows immediate primary refire but prevents using altfire immediately
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
		}
		goto ready;
	AltFire:
		PSHT A 5 {
			//A_FireProjectile("FreezerProjectile");
			A_StartSound("weapons/shotgun/freezer",CHAN_7);
			A_FireProjectile("PK_FreezerProjectile",0,true,-7,spawnheight:6);
			A_FireProjectile("PK_FreezerProjectile",0,false,7,spawnheight:6);
			invoker.freload = 55;
		}
		PSHF BCDE 2 {
			A_WeaponOffset(-1,   1.2,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF FGHI 4 {
			A_WeaponOffset(-0.4, 0.4,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF JKLM 4 {
			A_WeaponOffset( 0.4,-0.4,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF EDCB 2 {
			A_WeaponOffset( 1,  -1.2,WOF_ADD);
			PK_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHT A 1 A_WeaponOffset(0,32,WOF_INTERPOLATE);
		TNT1 A 0 A_ReFire();			
		goto ready;
	Flash:
		SMUZ A 2 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.95);
			let fl = Player.FindPsprite(OverlayID());
			if (fl)
				fl.frame = random[sfx](0,3);
			}
		stop;
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
	states 	{
	Spawn:
		BAL7 A 1;
		loop;
	Death:
		TNT1 A 0 {
			A_Stop();
			roll = random(0,359); 
			if (tracer && (tracer.bISMONSTER || tracer.player) && !tracer.bBOSS) {
				tracer.GiveInventory("PK_FreezeControl",1);
				let frz = PK_FreezeControl(tracer.FindInventory("PK_FreezeControl"));
				if (frz)
					frz.fcounter+=64;
			}
			for (int i = random[sfx](10,15); i > 0; i--) {
				let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
					debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
					debris.A_SetScale(frandom[sfx](0.12,0.25));
					debris.A_SetRenderstyle(0.9,Style_AddShaded);
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
		Translation "PK_IceChunk";
		alpha 0.8;
		scale 0.6;
		gravity 0.3;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		wrot = frandom[sfx](4,8)*randompick[sfx](-1,1);
		scale *= frandom[sfx](0.7,1.1);
		frame = random[sfx](1,4);
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
	Cache:
		IGIB ABCDE 0;
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
	
Class PK_FreezeControl : Inventory {
	int fcounter;
	uint ownertrans;
	bool grav;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void ModifyDamage (int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags) {
		if (inflictor && owner && passive)
			newdamage = damage*1.25;			
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		grav = owner.bNOGRAVITY;
		if (grav)
			owner.bNOGRAVITY = false;
		owner.bNOPAIN = true;
		ownertrans = owner.translation;
		owner.A_SetTranslation("PK_Ice");
		owner.A_StartSound("weapons/shotgun/freeze");
		let layer = Spawn("PK_FrozenLayer",owner.pos);
		if (layer) {
			layer.master = owner;
			layer.sprite = owner.sprite;
			layer.frame = owner.frame;
			layer.angle = owner.angle;
			layer.scale.x = owner.scale.x*1.32;
			layer.scale.y = owner.scaley*1.07;
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (level.isFrozen() || !owner)
			return;
		owner.A_SetTics(fcounter);
		fcounter--;
		//console.printf("owner: %s, counter: %d",owner.GetclassName(),fcounter);
		if (fcounter <= 0) {
			DepleteOrDestroy();
			return;
		}
		if (owner.health <= 0) {
			for (int i = 7; i >= 0; i--)
				owner.A_SoundVolume(i,0);
			int rad = owner.radius;
			for (int i = random[sfx](16,20); i > 0; i--) {
				let ice = Spawn("PK_FrozenChunk",owner.pos + (frandom[sfx](-rad,rad),frandom[sfx](-rad,rad),frandom[sfx](0,owner.default.height)));
				if (ice) {
					ice.vel = (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](2,6));
					ice.master = owner;
					ice.scale *= 1.2;
				}
			}
			for (int i = random[sfx](16,20); i > 0; i--) {
				let ice = Spawn("PK_FrozenChunk",owner.pos + (frandom[sfx](-rad,rad),frandom[sfx](-rad,rad),frandom[sfx](0,owner.default.height)));
				if (ice) {
					ice.vel = (frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](4,6));
					ice.master = owner;
					ice.A_SetRenderstyle(1.0,Style_Shaded);
					ice.SetShade("08caed");
					ice.scale *= 0.8;
				}
			}
			owner.A_StartSound("weapons/shotgun/freezedeath");
			owner.gravity = 0.4;
			//owner.vel = (frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](3,6));
			owner.vel *= 0.15;
			owner.A_SetScale(Clamp(owner.radius*0.04,0.1,1));
			owner.SetOrigin(owner.pos + (0,0,owner.default.height*0.5),false);
			owner.bSPRITEFLIP = random[sfx](0,1);
			owner.sprite = GetSpriteIndex("IGIB");
			owner.frame = 0;
			owner.A_SetTranslation("PK_IceChunk");
			owner.A_SetTics(1000);
			owner.deathsound = "";
			DepleteOrDestroy();
			return;
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		owner.bNOPAIN = owner.default.bNOPAIN;
		owner.bNOGRAVITY = grav;
		if (owner.health > 0)
			owner.translation = ownertrans;
		super.DetachFromOwner();
	}
}