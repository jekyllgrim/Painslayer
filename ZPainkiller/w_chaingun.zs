class PK_Chaingun : PKWeapon {
	private double atkzoom;

	const CHAN_SPIN = 15; //unaffected by Dexterity, since I set pitch manually

	//private int spinDur;
	double spinTics;
	enum ESpinSpeed {
		SS_Min = 0,
		SS_Max = 2,
	}

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

	action void PK_FireChaingun() {
		if (invoker.spinTics > SS_Min)
			return;
		
		A_StartSound("weapons/chaingun/spin",CHAN_7,CHANF_LOOPING);
		double spread = 1;
		int dmg = 10;
		if (!invoker.hasWmod) {
			spread = Clamp(double(player.refire * 0.2), 2, 8.5);
			dmg = 11;
		}

		PK_AttackSound("weapons/chaingun/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);	
		PK_FireBullets(spread,spread,-1,dmg,spawnheight: GetPlayerAtkHeight(player.mo) - 39,spawnofs:8.6);

		// muzzle flash:
		A_Overlay(PSP_PFLASH,"AltFlash");
		
		// dynamic light:
		double brt = frandom[sfx](40,70);
		A_AttachLight('PKWeaponlight', DynamicLight.PointLight, "fcbb53", int(brt), 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
		// muzzle highlights:
		A_Overlay(PSP_HIGHLIGHTS, "MinigunHighlights");
		A_OverlayFlags(PSP_HIGHLIGHTS, PSPF_Renderstyle|PSPF_ForceAlpha, true);
		A_OverlayRenderstyle(PSP_HIGHLIGHTS, Style_Add);
		A_OverlayAlpha(PSP_HIGHLIGHTS, PK_Utils.LinearMap(brt, 0, 70, 0.0, 1.0));

		// shake the gun:
		double ofs = Clamp(player.refire * 0.04, 0, 1.2);
		A_WeaponOffset(frandom[mgun](0,ofs), WEAPONTOP + frandom[mgun](0, ofs));

		// slightly change fov:
		invoker.atkzoom = Clamp(player.refire * 0.001, 0.01, 0.04);
		if (invoker.atkzoom < 0.04)
			A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
		else
			A_ZoomFactor(frandom[mgun](0.96,0.9575),ZOOM_NOSCALETURNING);	
	}

	action void PK_FireRocketLauncher() {
		PK_ResetMiningunSpin();
		A_WeaponOffset(0, WEAPONTOP, WOF_INTERPOLATE);
		A_Quake(1,9,0,32,"");
		Fire3DProjectile("PK_Rocket", leftright:8, updown:-8, crosshairConverge: True);
	}

	action void PK_ResetMiningunSpin() {
		invoker.spinTics = SS_Max;
		A_StopSound(CHAN_SPIN);
		A_StopSound(CHAN_7);
		player.SetPsprite(PSP_OVERGUN, ResolveState("Null"));
		player.SetPsprite(PSP_HIGHLIGHTS, ResolveState("Null"));
		A_ZoomFactor(1,ZOOM_NOSCALETURNING);
	}

	override void BeginPlay() {
		super.BeginPlay();
		spintics = SS_Max;
	}

	States {
	Spawn:
		PKWI C -1;
		stop;
	Select:
		TNT1 A 0 A_Overlay(PSP_OVERGUN, "MinigunReady");
		goto super::Select;
	Deselect:
		TNT1 A 0 PK_ResetMiningunSpin();
		goto super::Deselect;
	Ready:
		TNT1 A 1 {
			A_Overlay(PSP_OVERGUN, "MinigunReady", true);			
			A_SoundPitch(CHAN_SPIN, PK_Utils.LinearMap(invoker.spintics, SS_Max, SS_Min, 0.5, 1.0));
			A_StopSound(CHAN_7);
			invoker.atkzoom = Clamp(invoker.atkzoom - 0.006, 0.00, 0.1);
			if (invoker.atkzoom > 0)
				A_ZoomFactor(1 - invoker.atkzoom,ZOOM_NOSCALETURNING);
			else
				A_ZoomFactor(1,ZOOM_NOSCALETURNING);
			invoker.spintics = Clamp(invoker.spintics  + 0.1, SS_Min, SS_Max + 1);
			if (invoker.spinTics >= SS_Max) {
				A_StopSound(CHAN_SPIN);
			}			
			PK_WeaponReady();
		}
		loop;
	MinigunReady:
		MIGN A -1;
		stop;		
	Fire:
		MIGN A 2 {
			PK_FireRocketLauncher();
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
			let psp = player.FindPSprite(PSP_OVERGUN);
			if (!psp || InStateSequence(psp.curstate, ResolveState("MinigunReady"))) {
				player.SetPsprite(PSP_OVERGUN, ResolveState("MinigunFire"));
			}
		}
	AltHold:
		TNT1 A 2 {
			A_StartSound("weapons/chaingun/loop",CHAN_SPIN,CHANF_LOOPING);
			A_SoundPitch(CHAN_SPIN, PK_Utils.LinearMap(invoker.spintics, SS_Max, SS_Min, 0.5, invoker.hasDexterity ? 1.2 : 1.0));
			A_SetTics(invoker.hasDexterity ? 1 : 2);
			invoker.spintics = Clamp(invoker.spintics - 0.25, SS_Min, SS_Max);
			PK_FireChaingun();
		}
		TNT1 A 0 PK_Refire();
		goto ready;
	MinigunFire:
		MIGN ABCDEFGHABCDEFGH 1 {
			let psp = player.FindPsprite(OverlayID());
			let lightlayer = player.FindPsprite(PSP_HIGHLIGHTS);
			if (psp) {
				int ntics = Clamp(ceil(invoker.spintics), 1, SS_Max);
				// check if we're at max speed:
				if (invoker.spintics <= SS_Min) {
					// if so, skip every second frame
					// also skip every third, if player has Dexterity:
					if (psp.frame % 2 == 0 || (invoker.hasDexterity && psp.frame % 3 == 0)) {
						return psp.curstate.nextstate;
					}
				}
				psp.tics = ntics;

				if (lightlayer) {
					lightlayer.frame = psp.frame;
				}
			}
			return ResolveState(null);
		}
		TNT1 A 0 {		
			if (invoker.spintics > SS_Max) {
				return ResolveState("MinigunReady");
			}
			return ResolveState(null);
		}
		loop;
	MinigunHighlights:
		MIGF ### 1 bright {
			let thislayer = player.FindPsprite(OverlayID());
			if (thislayer) {
				thislayer.alpha -= 0.1;
			}
		}
		stop;
	AltFlash:
		CMUZ A 1 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayPivot(OverlayID(), 0.9, 0.9);
			let fl = Player.FindPsprite(OverlayID());
			if (fl) {
				fl.frame = random[sfx](0,3);
				fl.scale *= frandom[sfx](0.8, 1.1);
			}
		}
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
