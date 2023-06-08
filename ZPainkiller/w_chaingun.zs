Class PK_Chaingun : PKWeapon {
	private int holddur;
	private double atkzoom;
	private bool hideFlash;
	private int atkframe;
	private int atkframeDelay;
	Default {
		+PKWeapon.NOAUTOPRIMARY
		PKWeapon.emptysound "weapons/empty/chaingun";
		PKWeapon.ammoSwitchCVar 'pk_switch_MinigunRocket';
		weapon.slotnumber 4;
		weapon.ammotype1	"PK_GrenadeAmmo";
		weapon.ammouse1	1;
		weapon.ammogive1	5;
		weapon.ammotype2	"PK_BulletAmmo";
		weapon.ammouse2	1;
		weapon.ammogive2	100;		
		inventory.pickupmessage "$PKI_CHAINGUN";
		inventory.pickupsound "pickups/weapons/chaingun";
		inventory.icon "PKWIC0";
		Tag "$PK_CHAINGUN_TAG";
		Obituary "$PKO_CHAINGUN";
	}
	action void SetMinigunFrame(int delay = 0) {
		let psp = player.FindPsprite(OverlayID());
		if (!psp)
			return;
		if (delay > 0 && invoker.atkframeDelay <= delay)
			invoker.atkframeDelay++;
		else {
			invoker.atkframeDelay = 0;
			invoker.atkframe++;
			if (invoker.atkframe > 3)
				invoker.atkframe = 0;
		}
		psp.frame = invoker.atkframe;
	}
	action void PK_FireChaingun() {
		double spread = 1;
		double dmg = 10;
		if (!invoker.hasWmod) {
			spread = Clamp(double(invoker.holddur * 0.2), 2, 8.5);
			dmg = 11;
		}
		PK_FireBullets(spread,spread,-1,dmg,spawnheight: GetPlayerAtkHeight(player.mo) - 39,spawnofs:8.6);
		player.refire++;
		if (invoker.hasDexterity)
			invoker.hideFlash = !invoker.hideFlash;
		else
			invoker.hideFlash = false;
		if (!invoker.hideFlash)
			A_Overlay(PSP_PFLASH,"AltFlash");
	}
	States {
	Spawn:
		PKWI C -1;
		stop;
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
			PK_AttackSound();
			//A_FireProjectile("PK_Rocket",spawnofs_xy:3.2,spawnheight:-2);
			Fire3DProjectile("PK_Rocket", leftright:8, updown:-8, crosshairConverge: True);
			A_ZoomFactor(0.98,ZOOM_INSTANT|ZOOM_NOSCALETURNING);
			A_OverlayPivot(OverlayID(),0.1,1.0);
		}
		TNT1 A 0 A_ZoomFactor(1,ZOOM_NOSCALETURNING);
		MIGR AB 1 {
			A_WeaponOffset(12,3,WOF_ADD);
			A_OverlayRotate(OverlayID(),-2.5,WOF_ADD);
			A_OverlayScale(OverlayID(),0.05,0.05,WOF_ADD);
		}
		MIGR CDE 1 {
			A_WeaponOffset(2,3,WOF_ADD);
			A_OverlayRotate(OverlayID(),-2.5,WOF_ADD);
			A_OverlayScale(OverlayID(),0.05,0.05,WOF_ADD);
		}
		MIGR EED 2 {
			A_WeaponOffset(-3,0,WOF_ADD);
			A_OverlayRotate(OverlayID(),1.38,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.027,-0.027,WOF_ADD);
		}
		MIGR DCC 2 {
			A_WeaponOffset(-3,-2,WOF_ADD);
			A_OverlayRotate(OverlayID(),1.38,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.027,-0.027,WOF_ADD);
		}
		MIGR BBA 2 {
			A_WeaponOffset(-4,-3,WOF_ADD);
			A_OverlayRotate(OverlayID(),1.38,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.027,-0.027,WOF_ADD);
		}
		MIGN A 0 {
			A_WeaponOffset(0,32);
			A_OverlayRotate(OverlayID(),0);
			A_OverlayScale(OverlayID(),1,1);
		}
		goto ready;
	AltFire:
		TNT1 A 0 {
			A_StartSound("weapons/chaingun/loop",CHAN_6,CHANF_LOOPING);
			A_StartSound("weapons/chaingun/spin",CHAN_7,CHANF_LOOPING);
		}
		MIGN BCD 2 SetMinigunFrame();
		MIGN AB 2 SetMinigunFrame();
		MIGN CD 1 SetMinigunFrame();
		TNT1 A 0 {
			A_Overlay(PSP_OVERGUN,"MinigunFire");
		}
		goto AltHold;
	AltHold:
		TNT1 AAA 2 {
			A_Overlay(PSP_OVERGUN,"MinigunFire",noOverride: true);
			if (!PK_CheckAmmo(true))
				return ResolveState("AltFireEnd");
			invoker.holddur++;
			PK_AttackSound("weapons/chaingun/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);			
			PK_FireChaingun();			
			A_QuakeEX(1,1,0,2,0,1,sfx:"world/null");
			return ResolveState(null);
		}
		TNT1 A 0 {
			A_RemoveLight('PKWeaponlight');
			PK_ReFire();
		}
	AltFireEnd:
		TNT1 A 0 {
			invoker.holddur = 0;
			A_Overlay(PSP_OVERGUN,null);
			A_StopSound(CHAN_6);
			A_StopSound(CHAN_7);
			A_StartSound("weapons/chaingun/stop");
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
		}
		MIGN ABCD 1 {
			SetMinigunFrame();
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN AABBCCDD 1 {
			SetMinigunFrame(1);
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN AAABBB 1 {
			SetMinigunFrame(2);
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN CCCCDDDD 1 {
			SetMinigunFrame(3);
			PK_WeaponReady();
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006,0,0.1);
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		}
		MIGN # 1 {
			SetMinigunFrame(3);
			PK_WeaponReady();
			if (invoker.atkframe == 0)
				return ResolveState("Ready");
			return ResolveState(null);
		}
		wait;
	MinigunFire:
		MIGN ABCD 1 {
			let psp = Player.FindPsprite(OverlayID());
			if (invoker.hasDexterity) {
				A_SoundPitch(CHAN_6,1.25);
				A_SoundPitch(CHAN_7,1.25);
				if (psp && psp.frame == 0)
					psp.frame = 2;
				else
					psp.frame == 0;
			}
			else {
				SetMinigunFrame();
				A_SoundPitch(CHAN_6,1);
				A_SoundPitch(CHAN_7,1);
			}
			
			double brt = frandom[sfx](40,70);
			A_AttachLight('PKWeaponlight', DynamicLight.PointLight, "fcbb53", int(brt), 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
			double brt2 = (brt - 40) / 30;
			A_Overlay(PSP_HIGHLIGHTS,"Hightlights");
			A_OverlayFlags(PSP_HIGHLIGHTS,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(PSP_HIGHLIGHTS,Style_Add);
			A_OverlayAlpha(PSP_HIGHLIGHTS,frandom[sfx](0,1.2));
			let hl = Player.FindPsprite(PSP_HIGHLIGHTS);
			if (psp && hl)
				hl.frame = psp.frame;
				
			double ofs = Clamp(invoker.holddur * 0.04,0,1.2);
			A_OverlayOffset(OverlayID(),frandom[mgun](0,ofs),frandom[mgun](0,ofs));
			A_OverlayOffset(PSP_HIGHLIGHTS,psp.x,psp.y);
			invoker.atkzoom = Clamp(invoker.holddur * 0.001,0,0.04);
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
	Hightlights:
		MIGF # 1 bright;
		stop;
	}
}


Class PK_Rocket : PK_Grenade {
	Default {
		speed 30;
		seesound "weapons/chaingun/rocketfire";
		deathsound "weapons/chaingun/rocketboom";
		decal 'Scorch';
		DamageFunction (50);
		ExplosionDamage 128;
		+NOGRAVITY
		bouncetype 'none';
		Obituary "$PKO_ROCKET";
		//PK_Projectile.trailactor "PK_RocketSmoke";
		PK_Projectile.trailvel 0.42;
		PK_Projectile.trailshrink 1.03;
		PK_Projectile.trailalpha 0.3;
		PK_Projectile.trailfade 0.05;
		PK_Projectile.trailscale 0.1;
	}

	override void PostBeginplay() {
		PK_Projectile.PostBeginplay();
		A_StartSound("weapons/chaingun/rocketfly",CHAN_5,flags:CHANF_LOOPING,volume:0.8,attenuation:4);
		if (mod)
			vel *= 1.5;
	}

	override void CreateParticleTrail(out FSpawnParticleParams trail, vector3 ppos, double pvel, double velstep) {		
		trailTexture = PK_BaseActor.GetRandomWhiteSmoke();

		super.CreateParticleTrail(trail, ppos, pvel, -0.05);
		trail.lifetime = 100;
		trail.startRoll = random[smk](0, 359);
		trail.rollVel = frandom[smk](8,15)*randompick[smk](-1,1);
		trail.rollacc = trail.rollVel * -0.05;
	}
	
	states {
	Spawn:
		M000 A 1 NoDelay A_FaceMovementDirection(flags:FMDF_INTERPOLATE);
		loop;
	}
}

Class PK_RocketSmoke : PK_BaseSmoke {
	Default {
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
