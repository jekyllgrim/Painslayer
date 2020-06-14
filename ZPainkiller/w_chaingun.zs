Class PK_Chaingun : PKWeapon {
	private int holddur;
	private double atkzoom;
	Default {
		weapon.slotnumber 4;
		weapon.ammotype1	"PK_Bombs";
		weapon.ammouse1	1;
		weapon.ammogive1	5;
		weapon.ammotype2	"PK_Bullets";
		weapon.ammouse2	1;
		weapon.ammogive2	50;
		inventory.pickupmessage "Picked up a Chaingun";
		inventory.pickupsound "pickups/weapons/chaingun";
		Tag "Rocket Launcher/Chaingun";
	}
	States {
	Deselect:
		TNT1 A 0 {
			invoker.holddur = 0;
			invoker.atkzoom = 0;
			A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		}
		goto super::deselect;
	Ready:
		MIGN A 1 {
			invoker.holddur = 0;
			A_WeaponReady();
		}
		loop;
	Fire:
		MIGN A 2 {
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_Quake(1,9,0,32,"");
			A_FireProjectile("PK_Rocket",spawnofs_xy:7,spawnheight:-2);
			A_ZoomFactor(0.98,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		MIGN EEEFFF 1 A_WeaponOffset(4,1,WOF_ADD);
		MIGN GGG 1 A_WeaponOffset(2,3,WOF_ADD);
		MIGN FFF 1 A_WeaponOffset(-3,0,WOF_ADD);
		MIGN EEE 2 A_WeaponOffset(-3,-2,WOF_ADD);
		MIGN AAA 2 A_WeaponOffset(-4,-3,WOF_ADD);
		MIGN A 0 A_WeaponOffset(0,32);
		goto ready;
	AltFire:
		TNT1 A 0 {
			A_StartSound("weapons/chaingun/loop",CHAN_VOICE,CHANF_LOOPING);
			A_StartSound("weapons/chaingun/spin",CHAN_7,CHANF_LOOPING);
		}
		MIGN A 3;
		MIGN B 2;
		MIGN CD 1;
		TNT1 A 0 {
			A_Overlay(5,"MinigunFire");
		}
		goto AltHold;
	AltHold:
		TNT1 AAA 2 {
			if (invoker.ammo2.amount < 1)
				return ResolveState("AltFireEnd");
			invoker.holddur++;
			A_StartSound("weapons/chaingun/fire",flags:CHANF_OVERLAP);
			A_FireBullets(2.5,2.5,-1,(5));			
			return ResolveState(null);
		}
		TNT1 A 0 A_ReFire();
	AltFireEnd:
		TNT1 A 0 {
			invoker.holddur = 0;
			A_ClearOverlays(5,5);
			A_StopSound(CHAN_VOICE);
			A_StopSound(CHAN_7);
			A_StartSound("weapons/chaingun/stop");
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
		}
		MIGN ABCD 1 {
			A_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN AABBCCDD 1 {
			A_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN AAABBBCCCCDDDD 1 {
			A_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		goto ready;
	MinigunFire:
		MIGN ABCD 1 {
			invoker.holddur++;
			double ofs = Clamp(invoker.holddur * 0.04,0,1.2);
			A_OverlayOffset(OverlayID(),frandom[mgun](0,ofs),frandom[mgun](0,ofs),WOF_INTERPOLATE);
			invoker.atkzoom = Clamp(invoker.holddur * 0.0005,0,0.04);
			if (invoker.atkzoom < 0.04)
				A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
			else
				A_ZoomFactor(frandom[mgun](0.96,0.9575),ZOOM_NOSCALETURNING);				
		}
		loop;
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

Class PK_Rocket : Rocket {
	Default {
		speed 30;
		scale 0.6;
		seesound "weapons/chaingun/rocketfire";
		deathsound "weapons/chaingun/rocketboom";
	}
	override void PostBeginplay() {
		super.PostBeginplay();
		A_StartSound("weapons/chaingun/rocketfly",flags:CHANF_LOOPING,volume:0.8,attenuation:7);
	}
}