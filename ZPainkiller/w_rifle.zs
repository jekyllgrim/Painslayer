Class PK_Rifle : PKWeapon {
	private int shots;
	protected double rollangVel;
	protected double rollang;
	protected double damping;
	private int fireFrame;
	private double prevAngle[8];
	private double prevPitch[8];
	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		weapon.slotnumber 6;
		weapon.ammotype1	"PK_BulletAmmo";
		weapon.ammouse1		1;
		weapon.ammogive1	80;
		weapon.ammotype2	"PK_GrenadeAmmo";
		weapon.ammouse1		1;
		weapon.ammogive1	100;
		inventory.pickupmessage "Picked up an Assault Rifle/Flamethrower";
		inventory.pickupsound "pickups/weapons/rifle";
		Tag "Assault Rifle/Flamethrower";
	}
	/*override void DoEffect() {
		if (owner) {
			prevAngle = owner.angle;
			prevPitch = owner.pitch;
		}
		super.DoEffect();*/
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
		if (psp.rotation == 0 && invoker.rollangVel == 0) {
			invoker.damping = 0.018;
			invoker.rollangVel = 0.05 * randompick[sfx](-1,1);
		}
		else {
			double pspeed = Clamp(vel.length(),0,15);
			invoker.damping = 0.018 - (0.0024 * pspeed);
		}
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
		A_OverlayScale(PSP_HIGHLIGHTS,wx,wy,flags);
		
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
		let psph = player.FindPSprite(PSP_HIGHLIGHTS);
		
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
		if (psph)
			A_OverlayScale (PSP_HIGHLIGHTS, Clamp(pspb.scale.x- 0.015,1,99), Clamp(pspb.scale.y- 0.015,1,99),WOF_INTERPOLATE);
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
		PKRI A 5 {		
			int i = waterlevel > 2 ? WRF_NOSECONDARY : 0;
			PK_WeaponReady(flags:i);
			invoker.shots = 0;
			A_Overlay(RIFLE_BOLT,"Bolt",nooverride:true);
			A_Overlay(RIFLE_STOCK,"Stock",nooverride:true);
			A_Overlay(RIFLE_BARREL,"Barrel",nooverride:true);
			A_Overlay(RIFLE_STRAP,"Strap",nooverride:true);
			A_Overlay(RIFLE_PILOT,"PilotLightHandle",nooverride:true);
			A_Overlay(PSP_HIGHLIGHTS,"PilotHighlights",nooverride:true);
		}
		loop;
	Strap:
		PKRI E 1 {
			double pi = 3.141592653589793;
			double pspeed = vel.length();
			double velTarg = -(0.018 * invoker.rollang) - invoker.rollangVel*invoker.damping;
			invoker.rollangVel = Clamp(invoker.rollangVel + velTarg,-0.035,0.035);
			invoker.rollang = Clamp(invoker.rollang + invoker.rollangVel,-0.5,0.5);
			//console.printf("rollangVel %f player vel %f",invoker.rollangVel, pspeed);
			if (pspeed > 3)
				StartStrapSwing();
			A_OverlayRotate(OverlayID(),invoker.rollang * 180.0 / pi);
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
			A_OverlayPivot(RLIGHT_STOCK,-1,-2.1);
			//A_ClearOverlays(PSP_HIGHLIGHTS,PSP_HIGHLIGHTS);
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
			if (invoker.shots < 8)
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
	AltFire:
		TNT1 A 0 {
			A_AttachLight('PKFlameThrower', DynamicLight.RandomFlickerLight, "ffb30f", 80, 68, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
			A_StartSound("weapons/rifle/flamestart",CHAN_5);
			invoker.targOfs = (0,32);
			A_ClearOverlays(RIFLE_PILOT,RIFLE_PILOT);
		}
	AltHold:
		PKRI A 1 {
			A_Overlay(PSP_HIGHLIGHTS,"FlameHighlights");
			A_StartSound("weapons/rifle/flameloop",CHAN_6,flags:CHANF_LOOPING);
			DampedRandomOffset(3,3,3);
			if (invoker.fireFrame >= 8)
				invoker.fireFrame = 0;
			invoker.fireFrame++;
			A_Overlay(-30 + invoker.fireFrame,"FireFlash");
			A_FireProjectile("PK_FlameThrowerFlame",angle:frandom[flt](-3,3),spawnofs_xy:3,spawnheight:5,pitch:frandom[flt](-3,3));
		}
		TNT1 A 0 {
			if (waterlevel > 2)
				A_ClearRefire();
			else
				A_ReFire();
		}
		TNT1 A 0 {
			A_RemoveLight('PKFlameThrower');
			A_StopSound(CHAN_6);
			A_StartSound("weapons/rifle/flameend",CHAN_7);
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
			A_OverlayRotate(OverlayID(),frandom[sfx](-5,5)+randompick[sfx](0,90,-90,180));
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
	FlameHighlights:
		PRFM A 2 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),frandom[sfx](0.5,1));
		}
		stop;
	PilotHighlights:
		TNT1 A 0 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0);
		}
		PRFM BBBBB 1 bright {
			let psp = Player.FindPSprite(OverlayID());
			if (psp)
				A_OverlayAlpha(OverlayID(),psp.alpha + 0.15);
		}			
		PRFM B 2 bright {
			A_OverlayAlpha(OverlayID(),frandom[sfx](0.35,0.6));
		}
		wait;
	PilotLightHandle:
		PFLF A 2 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),frandom[sfx](0.25,0.4));
			A_OverlayOffset(OverlayID(),-4,2,WOF_INTERPOLATE);
			if (invoker.fireFrame >= 6)
				invoker.fireFrame = 0;
			invoker.fireFrame++;			
			A_Overlay(-30 + invoker.fireFrame,"PilotLight");
		}
		loop;
	PilotLight:
		TNT1 A 0 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.9);
			A_OverlayOffset(OverlayID(),-4,5+frandom[sfx](-0.5,0.5),WOF_ADD);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayRotate(OverlayID(),frandom[sfx](-90,90));
			A_OverlayScale(OverlayID(),0.4,0.4);
			int i = OverlayID() + 29;
			invoker.prevAngle[i] = angle;
			invoker.prevPitch[i] = pitch;
		}
	PilotLightDo:
		TNT1 A 0 A_Jump(256,1,5);
		PFLA ABCDEFGHIJILKLMNOPQRS 1 bright {	
			let psp = player.FindPSprite(OverlayID());
			if (psp) {
				A_OverlayAlpha(OverlayID(),psp.alpha - 0.05);
				if (psp.alpha <= 0)
					return ResolveState("Null");
			}
			A_OverlayScale(OverlayID(),-0.015,-0.015,WOF_ADD);
			int i = OverlayID() + 29;
			A_OverlayOffset(OverlayID(),-(invoker.prevAngle[i] - angle), -1 + (invoker.prevPitch[i] - pitch),WOF_ADD);
			invoker.prevAngle[i] = angle;
			invoker.prevPitch[i] = pitch;
			return ResolveState(null);
		}
		stop;
	FireFlash:
		TNT1 A 0 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.9);
			A_OverlayFlags(OverlayID(),PSPF_AddWeapon|PSPF_AddBob,false);
			A_OverlayOffset(OverlayID(),0,32,WOF_ADD);
			A_OverlayOffset(OverlayID(),frandom[sfx](-3,3),frandom[sfx](-3,3),WOF_ADD);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayRotate(OverlayID(),frandom[sfx](-90,90));
			A_OverlayScale(OverlayID(),0.7,0.7);
			int i = OverlayID() + 29;
			invoker.prevAngle[i] = angle;
			invoker.prevPitch[i] = pitch;
		}
	FireFlashDo:
		PFLA ABCDEFGHIJILKLMNOPQRS 1 bright {	
			let psp = player.FindPSprite(OverlayID());
			if (psp) {
				A_OverlayAlpha(OverlayID(),psp.alpha - 0.08);
				if (psp.alpha <= 0)
					return ResolveState("Null");
			}
			A_OverlayScale(OverlayID(),0.05,0.05,WOF_ADD);
			int i = OverlayID() + 29;
			//console.printf ("angle %f | pitch %f || prev.angle %f | prev.pitch %f",angle,pitch,invoker.prevAngle,invoker.prevPitch);
			A_OverlayOffset(OverlayID(),-5 - (invoker.prevAngle[i] - angle),-5 + (invoker.prevPitch[i] - pitch),WOF_ADD);
			invoker.prevAngle[i] = angle;
			invoker.prevPitch[i] = pitch;
			return ResolveState(null);
		}
		stop;
	}
}

Class PK_FlameThrowerFlame : Actor {
	protected double rollOfs;
	protected double scaleMul;
	protected double realSpeed;
	Default {
		projectile;
		+BRIGHT
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		renderstyle 'add';
		alpha 0.3;
		speed 52;
		scale 0.08;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[sfx](0,360);
		rollOfs = frandom[sfx](5,20) * randompick[sfx](-1,1);
		scaleMul = 1.02;
		realSpeed = 7.2;
		vel = vel.unit() * realSpeed;
		if (target) {
			vel += target.vel;
			SetOrigin(pos + target.vel,false);
		}
	}
	override void Tick() {
		super.Tick();
		if (waterlevel > 1)
			destroy();
		if (!isFrozen()) {
			A_SetScale(Clamp(scale.x * scaleMul, 0.08, 0.7));
			scaleMul = Clamp(scaleMul * 1.01, 1.02, 1.08);
		}
		if (alpha <= 0)
			destroy();
	}
	states {
	Spawn:
		FLT1 ABCDEFGHIJKLMNO 2 {
			vel *= 0.99;
			realSpeed *= 0.99;
			rollOfs *= 0.98;
			roll += rollOfs;
		}
		FLT1 PSTUVWXYZ 2 {
			vel *= 0.96;
			realSpeed *= 0.96;
			if (vel.length() > realSpeed){
				vel *= 0.8;
				realSpeed *= 0.8;
			}
			rollOfs *= 0.91;
			roll += rollOfs;
			alpha *= 0.99;
		}
		FLT2 ABCDEFG 1 {
			vel *= 0.92;
			realSpeed *= 0.92;
			if (vel.length() > realSpeed){
				vel *= 0.8;
				realSpeed *= 0.8;
			}
			rollOfs *= 0.91;
			vel *= 0.92;
			rollOfs *= 0.91;
			roll += rollOfs;
			alpha *= 0.85;
		}
		wait;
	Crash:
	XDeath:
		TNT1 A 1;
		stop;
	Death:
		TNT1 A 0 A_Stop();
		TNT1 AAAAAAAAAAAAAA random(3,6) {
			A_SpawnItemEx(
				"PK_FlameParticle",
				xvel:frandom[sfx](-0.6,0.6),
				yvel:frandom[sfx](-0.6,0.6),
				zvel:frandom[sfx](0.4,1.5),
				failchance: 80
			);
		}
		stop;
	}
}

Class PK_FlameParticle : PK_SmallDebris {
	protected int rollOfs;
	Default {
		+NOINTERACTION
		+BRIGHT
		renderstyle 'add';
		scale 0.12;
		alpha 0.5;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[sfx](0,360);
		rollOfs = frandom[sfx](4,8) * randompick[sfx](-1,1);
	}
	States {
	Spawn:
		PFLP ABCDEFGHIJILKLMNOPQR 1 {
			scale *= 1.03;
			A_FadeOut(0.015);
			vel *= 0.98;
			roll += rollOfs;
		}
		wait;
	}
}