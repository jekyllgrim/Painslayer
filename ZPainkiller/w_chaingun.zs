Class PK_Chaingun : PKWeapon {
	private int holddur;
	private double atkzoom;
	Default {
		PKWeapon.emptysound "weapons/empty/chaingun";
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
			PK_WeaponReady();
		}
		loop;
	Fire:
		MIGN A 2 {
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_Quake(1,9,0,32,"");
			A_FireProjectile("PK_Rocket",spawnofs_xy:6,spawnheight:-2);
			A_ZoomFactor(0.98,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		MIGN EF 1 A_WeaponOffset(12,3,WOF_ADD);
		MIGN GGG 1 A_WeaponOffset(2,3,WOF_ADD);
		MIGN FFF 2 A_WeaponOffset(-3,0,WOF_ADD);
		MIGN EEE 2 A_WeaponOffset(-3,-2,WOF_ADD);
		MIGN AAA 2 A_WeaponOffset(-4,-3,WOF_ADD);
		MIGN A 0 A_WeaponOffset(0,32);
		goto ready;
	AltFire:
		TNT1 A 0 {
			A_StartSound("weapons/chaingun/loop",12,CHANF_LOOPING);
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
			A_StartSound("weapons/chaingun/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);
			A_Overlay(-100,"AltFlash");
			A_FireBullets(2.5,2.5,-1,9,pufftype:"PK_BulletPuff",flags:FBF_USEAMMO|FBF_NORANDOM,missile:"PK_BulletTracer",spawnheight:player.viewz-pos.z-40,spawnofs_xy:8.6);
			
			A_QuakeEX(1,1,0,2,0,1,sfx:"world/null");
			return ResolveState(null);
		}
		TNT1 A 0 A_ReFire();
	AltFireEnd:
		TNT1 A 0 {
			invoker.holddur = 0;
			A_ClearOverlays(5,5);
			A_StopSound(12);
			A_StopSound(CHAN_7);
			A_StartSound("weapons/chaingun/stop");
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
		}
		MIGN ABCD 1 {
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
	AltFireEndDo:
		MIGN AABBCCDD 1 {
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN AAABBBCCCCDDDD 1 {
			PK_WeaponReady();
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
	AltFlash:
		CMUZ A 1 bright {
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


Class PK_Rocket : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailfade 0.035;
		PK_Projectile.trailalpha 0.12;
		speed 30;
		seesound "weapons/chaingun/rocketfire";
		height 8;
		radius 10;
		decal 'Scorch';
		damage (30);
	}
	override void PostBeginplay() {
		super.PostBeginplay();
		A_StartSound("weapons/chaingun/rocketfly",CHAN_5,flags:CHANF_LOOPING,volume:0.8,attenuation:4);
	}
	override void Tick () {
		Vector3 oldPos = self.pos;		
		Super.Tick();
		if (!farenough)
			return;
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / clamp(int(trailscale * 50),1,8); //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );
		
		for( int i = 0; i < steps; i++ )  {
			let smk = Spawn("PK_RocketSmoke",oldPos+(frandom[smk](-4,4),frandom[smk](-4,4),frandom[smk](-4,4)));
			if (smk) {
				smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
			}
			oldPos = level.vec3Offset( oldPos, direction );
		}
	}
	states {
	Spawn:
		MODL A 1 NoDelay A_FaceMovementDirection(flags:FMDF_INTERPOLATE);
		loop;
	Death:
		TNT1 A 1 { 
			bNOGRAVITY = true;
			A_Quake(1,8,0,256,"");
			A_StartSound("weapons/chaingun/rocketboom",CHAN_5);
			A_Explode(128,128);
			Spawn("PK_GenericExplosion",pos);
		}
		stop;
	}
}

Class PK_RocketSmoke : PK_BaseSmoke {
	Default {
		alpha 0.5;
		scale 0.05;
		renderstyle 'translucent';
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[smk](0,5);
		wrot = frandom[smk](8,15)*randompick[smk](-1,1);
	}
	states	{
	Spawn:		
		SMO2 A 1 {
			A_FadeOut(0.03);
			scale *= 1.03;
			roll+=wrot;
		}
		wait;
	}
}