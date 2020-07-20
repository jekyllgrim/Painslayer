Class PK_Shotgun : PKWeapon {
	int freload; //counter for freezer reload to prevent from quickly re-entering AltFire by using Fire first
	Default {
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
				A_WeaponReady();
			else
				A_WeaponReady(WRF_NOSECONDARY);
		}
		loop;
	Fire:
		PSHT A 2 {
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_Quake(1,7,0,32,"");
			A_StartSound("weapons/shotgun/fire",CHAN_VOICE);
			A_firebullets(5,5,14,3);
			A_ZoomFactor(0.99,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
			//A_Eject				
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		PSHT CDF 2 A_WeaponOffset(10,2,WOF_ADD);
		PSHT HHHH 1 A_WeaponOffset(0.5,2.5,WOF_ADD);
		PSHT HHHH 1 A_WeaponOffset(-0.5,2,WOF_ADD);
		PSHT GGFFEE 1 A_WeaponOffset(-2.5,-3,WOF_ADD);
		PSHT DDCCBB 1 A_WeaponOffset(-2.5,-1,WOF_ADD);
		PSHT A 8 { //allows immediate primary refire but prevents using altfire immediately
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_WeaponReady(WRF_NOSECONDARY|WRF_NOBOB);
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
			A_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF FGHI 4 {
			A_WeaponOffset(-0.4, 0.4,WOF_ADD);
			A_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF JKLM 4 {
			A_WeaponOffset( 0.4,-0.4,WOF_ADD);
			A_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHF EDCB 2 {
			A_WeaponOffset( 1,  -1.2,WOF_ADD);
			A_WeaponReady(WRF_NOSECONDARY|WRF_DISABLESWITCH|WRF_NOBOB);
		}
		PSHT A 1 A_WeaponOffset(0,32,WOF_INTERPOLATE);
		TNT1 A 0 A_ReFire();			
		goto ready;
	}
}
	
Class PK_FreezerProjectile : PK_Projectile {
	Default {
		Translation "112:127=%[0.00,2.00,2.00]:[0.00,0.00,1.01]";
		renderstyle "Add";
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
		PK_Projectile.flarecolor 'blue';
		PK_Projectile.flarescale 0.065;
		PK_Projectile.flarealpha 0.7;
		PK_Projectile.trailcolor 'blue';
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
			roll = random(0,359); 
			if (tracer && (tracer.bISMONSTER || tracer.player) && !tracer.bBOSS) {
				tracer.GiveInventory("PK_FreezeControl",1);
				let frz = PK_FreezeControl(tracer.FindInventory("PK_FreezeControl"));
				if (frz)
					frz.fcounter+=64;
			}
		}
		BAL7 CCCDDDEEE 1 {
			roll+=10;
			A_FadeOut(0.1);
			scale*=0.9;
		}
		wait;
	}
}
	
Class PK_FreezerTrail : PK_BaseFlare {
	Default {
		scale 0.08;
		alpha 0.65;
		PK_BaseFlare.fcolor 'blue';
	}
	states {
	Spawn:
		FLAR C 1 A_FadeOut(0.03);
		loop;
	}
}
	
Class PK_FreezeControl : Inventory {
	int fcounter;
	color ownertrans;
	bool grav;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void AttachToOwner(actor user) {
		super.AttachToOwner(user);
		if (!user)
			return;
		grav = user.bNOGRAVITY;
		if (grav)
			user.bNOGRAVITY = false;
		user.painchance = 0;
		ownertrans = user.translation;
		user.A_SetTranslation("Ice");
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
			owner.A_IceGuyDie();
			DepleteOrDestroy();
			return;
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		owner.painchance = owner.default.painchance;
		owner.bNOGRAVITY = grav;
		if (owner.health > 0)
			owner.translation = ownertrans;
		super.DetachFromOwner();
	}
}