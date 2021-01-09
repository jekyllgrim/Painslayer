Class PK_Rifle : PKWeapon {
	private int shots;
	protected double rollangVel;
	protected double rollang;
	protected double damping;
	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		weapon.slotnumber 6;
		weapon.ammotype1	"PK_Bullets";
		weapon.ammouse1		1;
		weapon.ammogive1	80;
		inventory.pickupmessage "Picked up a Rifle/Flamethrower";
		inventory.pickupsound "pickups/weapons/chaingun";
		Tag "Rocket Launcher/Chaingun";
	}
	action int PK_Sign (int i) {
		if (i >= 0)
			return 1;
		else
			return -1;
	}
	action void StartStrapSwing(double rfactor = 1.0) {
		if (!player)
			return;
		let psp = Player.FindPSprite(OverlayID());
		if (!psp)
			return;
		double sspeed = 1 * rfactor;
		for (int i = 4; i > 0; i--) {
			if (random[sfx](0,100) < 50)
				sspeed *= 0.7;
		}
		if (psp.rotation ~== 0)
			invoker.rollangVel = 0.1 * PK_Sign(invoker.rollangVel);
		else 
			invoker.rollangVel = 0.1 * PK_Sign(psp.rotation);
		invoker.rollangVel *= sspeed;
	}
	action void PK_RifleFlash() {		
		A_Overlay(RLIGHT_WEAPON,"Highlight");
		A_Overlay(RLIGHT_BOLT,"HighlightBolt");
		A_Overlay(RLIGHT_STOCK,"HighlightStock");
		A_Overlay(RLIGHT_BARREL,"HighlightBarrel");
		
		A_OverlayFlags(RLIGHT_WEAPON,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
		A_OverlayRenderstyle(RLIGHT_WEAPON,Style_Add);
		A_OverlayAlpha(RLIGHT_WEAPON,0.9);
		
		A_OverlayFlags(RLIGHT_BOLT,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
		A_OverlayRenderstyle(RLIGHT_BOLT,Style_Add);
		A_OverlayAlpha(RLIGHT_BOLT,0.9);
		
		A_OverlayFlags(RLIGHT_STOCK,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
		A_OverlayRenderstyle(RLIGHT_STOCK,Style_Add);
		A_OverlayAlpha(RLIGHT_STOCK,0.9);
		
		A_OverlayFlags(RLIGHT_BARREL,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
		A_OverlayRenderstyle(RLIGHT_BARREL,Style_Add);
		A_OverlayAlpha(RLIGHT_BARREL,0.9);
	}
	//scale all layers
	action void PK_RifleScale(double wx, double wy, int flags = WOF_ADD) {
		A_OverlayScale(PSP_WEAPON,wx,wy,flags);
		A_OverlayScale(RIFLE_BOLT,wx,wy,flags);
		A_OverlayScale(RIFLE_STOCK,wx,wy,flags);
		A_OverlayScale(RIFLE_BARREL,wx,wy,flags);
		A_OverlayScale(RIFLE_STRAP,wx,wy,flags);
		
		A_OverlayScale(RLIGHT_WEAPON,wx,wy,flags);
		A_OverlayScale(RLIGHT_BOLT,wx,wy,flags);
		A_OverlayScale(RLIGHT_STOCK,wx,wy,flags);
		A_OverlayScale(RLIGHT_BARREL,wx,wy,flags);
	}
	//gradually scale down all layers
	action void PK_RifleRestoreScale() {
		if (!player)
			return;
		let pspw = player.FindPSprite(PSP_WEAPON);
		let pspo = player.FindPSprite(RIFLE_BOLT);
		let psps = player.FindPSprite(RIFLE_STOCK);
		let pspu = player.FindPSprite(RIFLE_BARREL);
		let pspb = player.FindPSprite(RIFLE_STRAP);
		
		if (pspw)			
			A_OverlayScale(PSP_WEAPON,  Clamp(pspw.scale.x- 0.015,1,99), Clamp(pspw.scale.y- 0.015,1,99),WOF_INTERPOLATE);
		if (pspo)
			A_OverlayScale (RIFLE_BOLT, Clamp(pspo.scale.x- 0.015,1,99), Clamp(pspo.scale.y- 0.015,1,99),WOF_INTERPOLATE);
		if (psps)
			A_OverlayScale(RIFLE_STOCK, Clamp(psps.scale.x- 0.015,1,99), Clamp(psps.scale.y- 0.015,1,99),WOF_INTERPOLATE);
		if (pspu)
			A_OverlayScale (RIFLE_BARREL, Clamp(pspu.scale.x- 0.015,1,99), Clamp(pspu.scale.y- 0.015,1,99),WOF_INTERPOLATE);
		if (pspb)
			A_OverlayScale (RIFLE_STRAP, Clamp(pspb.scale.x- 0.015,1,99), Clamp(pspb.scale.y- 0.015,1,99),WOF_INTERPOLATE);
	}
	states {
	Select:
		TNT1 A 0 {
			A_Overlay(RIFLE_BOLT,"Bolt");
			A_Overlay(RIFLE_STOCK,"Stock");
			A_Overlay(RIFLE_BARREL,"Barrel");
			A_Overlay(RIFLE_STRAP,"Strap");
		}
		TNT1 A 0 A_Raise();
		wait;
	Ready:
		PKRI A 1 {
			PK_WeaponReady();
			A_Overlay(RIFLE_BOLT,"Bolt",nooverride:true);
			A_Overlay(RIFLE_STOCK,"Stock",nooverride:true);
			A_Overlay(RIFLE_BARREL,"Barrel",nooverride:true);
			A_Overlay(RIFLE_STRAP,"Strap",nooverride:true);
			invoker.shots = 0;
		}
		loop;
	Strap:
		PKRI E 1 {
			if (vel.length () > 3 && abs(invoker.rollangVel) < 0.05)
				StartStrapSwing();
		}
		PKRI EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE 1 {
			double pi = 3.141592653589793;
			invoker.rollangVel += -(0.018 * invoker.rollang) - invoker.rollangVel*0.018;
			invoker.rollang = Clamp(invoker.rollang + invoker.rollangVel,-0.5,0.5);
			A_OverlayRotate(OverlayID(),invoker.rollang * 180.0 / pi);
			//console.printf("rollangVel %f",invoker.rollangVel);
		}
		loop;
		PKRI E 20;
		TNT1 A 0 {
			if (vel.length() > 5)
				return ResolveState("StrapWobbleStart");
			return ResolveState(null);
		}
		loop;
	Stock:
		PKRI D -1;
		stop;
	Bolt:
		PKRI C -1;
		stop;
	Barrel:
		PKRI B -1;
		stop;
	Fire:
		TNT1 A 0 {
			A_StartSound("weapons/rifle/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);
			A_FireBullets(1.2,1.2,-1,14,pufftype:"PK_BulletPuff",flags:FBF_USEAMMO|FBF_NORANDOM,missile:"PK_BulletTracer",spawnheight:player.viewz-pos.z-40,spawnofs_xy:8.6);
			invoker.shots++;
			A_OverlayPivot(RIFLE_STOCK,-1,-2.1);
		}
		PKRI A 1 {
			A_Overlay(PSP_PFLASH,"Flash");
			PK_RifleFlash();
			PK_RifleScale(0.11,0.11);
			A_WeaponOffset(2,2,WOF_ADD);
			A_OverlayOffset(RIFLE_BOLT,2.1,1.5,WOF_ADD); //bolt
			A_OverlayScale(RIFLE_BOLT,0.33,0.33,WOF_ADD); //bolt
			A_OverlayOffset(RIFLE_BARREL,3,3,WOF_ADD); //barrel
		}
		PKRI AAA 1 {			
			PK_RifleScale(-0.033,-0.033);
			A_WeaponOffset(-0.6,-0.6,WOF_ADD);
			A_OverlayOffset(RIFLE_BOLT,-0.7,-0.5,WOF_ADD);
			A_OverlayScale(RIFLE_BOLT,-0.11,-0.11,WOF_ADD);
			A_OverlayOffset(RIFLE_BARREL,-1,-1,WOF_ADD);
		}
		TNT1 A 0 {
			if (invoker.shots < 7)
				A_ReFire();
			else
				A_ClearRefire();
		}
		PKRI AAAAAA 1 {
			PK_RifleRestoreScale();
			let psp = Player.FindPSprite(PSP_WEAPON);
			if (psp)
				A_WeaponOffset(Clamp(psp.x - 0.25,0,99), Clamp(psp.y - 0.25,32,99), WOF_INTERPOLATE);
			let pspo = Player.FindPSprite(RIFLE_BOLT);
			if (pspo)
				A_OverlayOffset(RIFLE_BOLT, Clamp(pspo.x - 0.25,0,99), Clamp(pspo.y - 0.25,0,99), WOF_INTERPOLATE);
			let pspu = Player.FindPSprite(RIFLE_BARREL);
			if (pspu)
				A_OverlayOffset(RIFLE_BARREL, Clamp(pspu.x  - 0.25,0,99), Clamp(pspu.y - 0.25,0,99), WOF_INTERPOLATE);
		}
		TNT1 A 0 {
			A_WeaponOffset(0,32);
			A_OverlayOffset(RIFLE_BOLT,0,0);
			A_OverlayOffset(RIFLE_BARREL,0,0);
			PK_RifleScale(1,1,flags:0);
		}
		goto ready;
	Flash:
		RMUZ A 1 bright {
			A_AttachLight('PKRifleFlash', DynamicLight.PointLight, "ffcd66", frandom[sfx](32,46), 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON,false);
			A_OverlayOffset(OverlayID(),0,32);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),1.0);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayRotate(OverlayID(),frandom[sfx](-30,30));
		}
		#### # 1 bright A_OverlayScale(OverlayID(),0.8,0.8,WOF_INTERPOLATE);
		TNT1 A 0 A_RemoveLight('PKRifleFlash');
		stop;
	Highlight:
		PRHI A 1 bright;
		stop;
	HighlightStock:
		PRHI D 1 bright;
		stop;
	HighlightBolt:
		PRHI C 1 bright;
		stop;
	HighlightBarrel:
		PRHI B 1 bright;
		stop;
	}
}