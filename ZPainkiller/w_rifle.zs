Class PK_Rifle : PKWeapon {
	private int shots;
	protected double rollangVel;
	protected double rollang;
	protected double damping;
	private int fireFrame;
	private double prevAngle[8];
	private double prevPitch[8];
	private int fuelDepleteRate;
	private bool speedup;

	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		PKWeapon.ammoSwitchCVar 'pk_switch_RifleFlamethrower';
		weapon.slotnumber 6;
		weapon.ammotype1	"PK_RifleBullets";
		weapon.ammouse1		1;
		weapon.ammogive1	80;
		weapon.ammotype2	"PK_FuelAmmo";
		weapon.ammouse2		1;
		weapon.ammogive2	100;
		inventory.pickupmessage "$PKI_RIFLE";
		inventory.pickupsound "pickups/weapons/rifle";
		inventory.icon "PKWIE0";
		Tag "$PK_RIFLE_TAG";
		Obituary "$PKO_RIFLE";
	}

	action void FireFlameThrower() {
		let flm = PK_FlameThrowerFlame(Fire3DProjectile("PK_FlameThrowerFlame", true, forward: radius, leftright: 3, updown: 0, angleoffs: frandom[flt](-3,3), pitchoffs: frandom[flt](-3,3)));

		if (flm) {
			flm.vel += vel;
			/*console.printf("Flame base vel: %1.f | added vel: %.1f | total vel: %1.f",
				flm.basevel,
				vel.length(),
				flm.vel.length()
			);*/
			if (invoker.hasWmod) {
				flm.scale *= 1.5;
				flm.vel *= 1.5;			
				flm.A_SetSize(flm.radius * 1.2, flm.height * 1.2);
			}
			flm.SetOrigin(flm.pos + flm.vel, false);
		}
	}

	action void StartStrapSwing(double rfactor = 1.0) {
		if (!player)
			return;
		let psp = Player.FindPSprite(OverlayID());
		if (!psp)
			return;
		if (abs(psp.rotation) < 0.05 && abs(invoker.rollangVel) < 0.045) {
			invoker.damping = 0.018;
			invoker.rollangVel = 0.05 * PK_Utils.Sign(invoker.rollangVel);
		}
		else {
			double pspeed = Clamp(vel.length(),0,15);
			invoker.damping = 0.018 - (0.0024 * pspeed);
		}
		//console.printf("rollangvel: %f | damping: %f",invoker.rollangVel,invoker.damping);
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
	action void PK_RifleRestoreScale(double deduct = 0.25) {
		if (!player)
			return;
		let pspw = player.FindPSprite(PSP_WEAPON);
		let pspo = player.FindPSprite(RIFLE_BOLT);
		let psps = player.FindPSprite(RIFLE_STOCK);
		let pspu = player.FindPSprite(RIFLE_BARREL);
		let pspb = player.FindPSprite(RIFLE_STRAP);
		let psph = player.FindPSprite(PSP_HIGHLIGHTS);
		
		if (pspw) {
			A_OverlayScale(PSP_WEAPON,  Clamp(pspw.scale.x- deduct,1,99), Clamp(pspw.scale.y- deduct,1,99),WOF_INTERPOLATE);
			A_WeaponOffset(Clamp(pspw.x - deduct,0,99), Clamp(pspw.y - deduct,32,99), WOF_INTERPOLATE);
		}
		if (pspo) {
			A_OverlayScale (RIFLE_BOLT, Clamp(pspo.scale.x- deduct,1,99), Clamp(pspo.scale.y- deduct,1,99),WOF_INTERPOLATE);
			A_OverlayOffset(RIFLE_BOLT, Clamp(pspo.x - deduct,0,99), Clamp(pspo.y - deduct,0,99), WOF_INTERPOLATE);
		}
		if (psps)
			A_OverlayScale(RIFLE_STOCK, Clamp(psps.scale.x- deduct,1,99), Clamp(psps.scale.y- deduct,1,99),WOF_INTERPOLATE);
		if (pspu) {
			A_OverlayScale (RIFLE_BARREL, Clamp(pspu.scale.x- deduct,1,99), Clamp(pspu.scale.y- deduct,1,99),WOF_INTERPOLATE);
			A_OverlayOffset(RIFLE_BARREL, Clamp(pspu.x  - deduct,0,99), Clamp(pspu.y - deduct,0,99), WOF_INTERPOLATE);
		}
		if (pspb)
			A_OverlayScale (RIFLE_STRAP, Clamp(pspb.scale.x- deduct,1,99), Clamp(pspb.scale.y- deduct,1,99),WOF_INTERPOLATE);
		if (psph)
			A_OverlayScale (PSP_HIGHLIGHTS, Clamp(pspb.scale.x- deduct,1,99), Clamp(pspb.scale.y- deduct,1,99),WOF_INTERPOLATE);
	}

	action void DrawRifleOverlays(bool nooverride = true) {
		A_Overlay(RIFLE_BOLT,"Bolt",nooverride:nooverride);
		A_Overlay(RIFLE_STOCK,"Stock",nooverride:nooverride);
		A_Overlay(RIFLE_BARREL,"Barrel",nooverride:nooverride);
		A_Overlay(RIFLE_STRAP,"Strap",nooverride:nooverride);
	}

	states {
	Spawn:
		PKWI E -1;
		stop;
	Select:
		TNT1 A 0 {
			/*A_Overlay(RIFLE_BOLT,"Bolt");
			A_Overlay(RIFLE_STOCK,"Stock");
			A_Overlay(RIFLE_BARREL,"Barrel");
			A_Overlay(RIFLE_STRAP,"Strap");*/
		}
		TNT1 A 0 A_Raise();
		wait;
	Ready:
		PKRI A 1 {
			int fflags = 0;			
			if (waterlevel > 2)
				fflags |= WRF_NOSECONDARY;
			else if (PK_CheckAmmo(secondary:true)) {
				A_Overlay(PSP_HIGHLIGHTS,"PilotHighlights",nooverride:true);
				A_Overlay(RIFLE_PILOT,"PilotLightHandle",nooverride:true);
			}
			PK_WeaponReady(flags:fflags);
			invoker.shots = 0;
			DrawRifleOverlays();
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
	ComboFire:
		TNT1 A 0 {
			PK_FireArchingProjectile("PK_FlamerTank",spawnofs_xy:1,spawnheight:-4,flags:FPF_NOAUTOAIM,pitch:-25);
			A_StartSound("weapons/edriver/diskshot",CHAN_5);
			//A_StartSound("weapons/gastank/fire",CH_LOOP);
		}
		PKRI AAA 2 {
			PK_RifleScale(0.1,0.1);
			A_WeaponOffset(3,3,WOF_ADD);
		}
		PKRI AAAAAA 2 {
			PK_RifleScale(-0.05,-0.05);
			A_WeaponOffset(-1.5,-1.5,WOF_ADD);			
		}
		PKRI AAAAA 1 {
			PK_RifleRestoreScale();
		}
		goto ready;
	Fire:
		TNT1 A 0 {
			PK_AttackSound("weapons/rifle/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);
			if (invoker.hasDexterity)
				A_SoundPitch(CHAN_WEAPON,1.1);
			double dmg = 14;
			if (invoker.hasWmod) dmg *= 1.5;
			PK_FireBullets(1,1,1,dmg,spawnheight: GetPlayerAtkHeight(player.mo) - 37,spawnofs:6.6);
			if (!invoker.hasWmod)
				invoker.shots++;
			A_OverlayPivot(RIFLE_STOCK,-1,-2.1);
			A_OverlayPivot(RLIGHT_STOCK,-1,-2.1);
			//A_ClearOverlays(PSP_HIGHLIGHTS,PSP_HIGHLIGHTS);
		}
		PKRI A 1 {
			if (invoker.hasDexterity)
				A_SetTics(0);
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
			if (invoker.hasWmod)
				PK_RifleRestoreScale(0.5);
			if (invoker.shots < 8)
				PK_Refire();
		}
		PKRI AAAA 1 {
			PK_RifleRestoreScale();
		}
		TNT1 A 0 {
			A_WeaponOffset(0,32);
		}
		goto ready;
	AltFire:
		TNT1 A 0 {
			A_AttachLight('PKWeaponlight', DynamicLight.RandomFlickerLight, "ffb30f", 80, 68, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
			A_StartSound("weapons/rifle/flamestart",CHAN_5);
			invoker.targOfs = (0,32);
			A_ClearOverlays(RIFLE_PILOT,RIFLE_PILOT);
		}
	AltHold:
		PKRI A 2 {
			if (PressingAttackButton() && PK_CheckAmmo(true, 50)) {
				A_RemoveLight('PKWeaponlight');
				PK_DepleteAmmo(true, 50);
				A_ClearRefire();
				A_StopSound(CH_LOOP);
				return ResolveState("ComboFire");
			}
			A_Overlay(PSP_HIGHLIGHTS,"FlameHighlights");
			PK_AttackSound("weapons/rifle/flameloop",CH_LOOP,flags:CHANF_LOOPING);
			DampedRandomOffset(3,3,3);
			if (invoker.fireFrame >= 8)
				invoker.fireFrame = 0;
			invoker.fireFrame++;
			A_Overlay(-30 + invoker.fireFrame,"FireFlash");
			FireFlameThrower();
			return ResolveState(null);
		}
		TNT1 A 0 {
			if (waterlevel <= 2)
				PK_Refire();
		}
	AltHoldEnd:
		PKRI A 4 {
			A_RemoveLight('PKWeaponlight');
			A_StopSound(CH_LOOP);
			A_StartSound("weapons/rifle/flameend",CHAN_7);
		}
		goto ready;
	Flash:
		RMUZ A 1 bright {
			A_AttachLight('PKWeaponlight', DynamicLight.PointLight, "ffcd66", frandom[sfx](32,46), 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF, ofs: (32,32,player.viewheight));
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON,false);
			A_OverlayOffset(OverlayID(),0,32);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),1.0);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayRotate(OverlayID(),frandom[sfx](-5,5)+randompick[sfx](0,90,-90,180));
		}
		#### # 1 bright A_OverlayScale(OverlayID(),0.8,0.8,WOF_INTERPOLATE);
		TNT1 A 0 A_RemoveLight('PKWeaponlight');
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
		}
		PRFM B 2 bright {
			if (waterlevel > 1 || !PK_CheckAmmo(secondary:true))
				return ResolveState("Null");
			A_OverlayAlpha(OverlayID(),frandom[sfx](0.35,0.6));
			return ResolveState(null);
		}
		wait;
	PilotLightHandle:
		PFLF A 2 bright {			
			if (waterlevel > 1 || !PK_CheckAmmo(secondary:true)) {
				A_ClearOverlays(-36,-30);
				return ResolveState("Null");
			}
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),frandom[sfx](0.25,0.4));
			A_OverlayOffset(OverlayID(),-4,2,WOF_INTERPOLATE);
			if (invoker.fireFrame >= 6)
				invoker.fireFrame = 0;
			invoker.fireFrame++;			
			A_Overlay(-30 + invoker.fireFrame,"PilotLight");
			return ResolveState(null);
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
			A_OverlayOffset(OverlayID(), -4 - (invoker.prevAngle[i] - angle), -4 + (invoker.prevPitch[i] - pitch),WOF_ADD);
			invoker.prevAngle[i] = angle;
			invoker.prevPitch[i] = pitch;
			return ResolveState(null);
		}
		stop;
	}
}

Class PK_BurnControl : PK_InventoryToken {
	protected int prevTranslation;
	TextureID flamePartTex;

	protected int timer;
	void ResetTimer() {
		timer = 35*5;
	}

	// Only make them scorched if they were actually killed by fire while burning:
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags) {
		if (owner && damageType == 'Fire' && owner.health > 0 && owner.health - damage <= 0) {
			owner.A_SetTRanslation("Scorched");
		}
	}

	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		ResetTimer();
		//if (owner.FindInventory("PK_FreezeControl"))
			//owner.TakeInventory("PK_FreezeControl",1);
		prevTranslation = owner.translation;
		owner.A_AttachLight('PKBurn', DynamicLight.RandomFlickerLight, "ffb30f", 48, 40, flags: DYNAMICLIGHT.LF_ATTENUATE);
	}

	override void DoEffect() {
		super.DoEffect();

		if (!owner || !target || owner.waterlevel > 1) {
			Destroy();
			return;
		}

		if (owner.isFrozen())
			return;

		if (timer <= 0) {
			Destroy();
			return;
		}

		timer--;
		if (timer % 35 == 0) {
			int fl = (random[burn](1,3) == 1) ? 0 : DMG_NO_PAIN;
			owner.DamageMobj(self,target,4,"Fire",flags:DMG_THRUSTLESS|fl);
		}
		
		double rad = owner.radius*0.5;

		if (!flamePartTex)
			flamePartTex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);
		PK_FlameParticle.SpawnFlameParticle(
			flamePartTex,
			owner.pos + (
				frandom[sfx](-rad,rad), 
				frandom[sfx](-rad,rad), 
				frandom[sfx](owner.height * 0.15, owner.height * 0.75)
			),
			scale: 0.4,
			alpha: 0.65,
			hvel: 0.5,
			vvel: frandom[sfx](0.5,1.65)
		);
	}

	override void DetachFromOwner() {
		if (owner) {
			owner.A_RemoveLight('PKBurn');
			owner.translation = prevTranslation;
		}
		super.DetachFromOwner();
	}
}

Class PK_FlameThrowerFlame : PK_Projectile {
	protected actor hitvictim;
	protected int ripdepth;
	protected double rollOfs; //randomized roll
	protected double scaleMul;
	TextureID flamePartTex;

	Default {
		+BRIGHT
		+ROLLSPRITE
		+ROLLCENTER
		+FORCEXYBILLBOARD
		renderstyle 'add';
		alpha 0.3;
		speed 7.2;
		scale 0.08;
		radius 16;
		height 22;
		damage 0;
		Obituary "$PKO_FLAME";
	}

	override int SpecialMissileHit(actor victim) {
		if (victim && target && victim != target && victim.health > 0 && CheckVulnerable(victim)) {
			if (victim != hitvictim) {
				hitvictim = victim;
				ripdepth -= victim.health;
				int fl = (random[burn](1,3) == 1) ? 0 : DMG_NO_PAIN;
				victim.DamageMobj(self,target,8,"Fire",flags:DMG_THRUSTLESS|fl);
				if (victim.health > 0 && !victim.CountInv("PK_BurnControl") && !victim.CountInv("PK_FreezeControl")) {
					victim.GiveInventory("PK_BurnControl",1);
					let control = PK_BurnControl(victim.FindInventory("PK_BurnControl"));
					if (control && target)
						control.target = target;
				}
				else if (victim) {
					let control = PK_BurnControl(victim.FindInventory("PK_BurnControl"));
					if (control)
						control.ResetTimer();
				}
			}
			if (ripdepth <= 0 || victim.bDONTRIP)
				return 0;
		}
		return 1;
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		ripdepth = 300;
		roll = frandom[sfx](0,360);
		rollOfs = frandom[sfx](5,20) * randompick[sfx](-1,1);
		scaleMul = 1.02;
	}

	override void Tick() {
		super.Tick();
		if (waterlevel > 1) {
			Destroy();
			return;
		}
		if (!isFrozen()) {
			A_SetScale(Clamp(scale.x * scaleMul, 0.08, 0.7));
			scaleMul = Clamp(scaleMul * 1.01, 1.02, 1.08);
		}
		if (alpha <= 0) {
			Destroy();
		}
	}

	void SlowDownFlame(double fac) {
		// slow flame down:
		vel *= fac;
		speed *= fac;
		// if it's higher than base vel,
		// and base vel was recorded,
		// scale it down further:
		if (vel.length() > speed) {
			vel *= 0.8;
		}
	}		

	states {
	Spawn:
		FLT1 ABCD 2 {
			rollOfs *= 0.98;
			roll += rollOfs;
		}
		FLT1 EFGHIJKLMNO 2 {
			SlowDownFlame(0.99);
			rollOfs *= 0.98;
			roll += rollOfs;
		}
		FLT1 PSTUVWXYZ 2 {
			SlowDownFlame(0.96);
			rollOfs *= 0.91;
			roll += rollOfs;
			alpha *= 0.99;
		}
		FLT2 ABCDEFG 1 {
			SlowDownFlame(0.92);
			rollOfs *= 0.91;
			roll += rollOfs;
			A_FadeOut(0.02);
		}
		wait;
	Crash:
	XDeath:
		TNT1 A 1;
		stop;
	Death:
		TNT1 A 0 A_Stop();
		TNT1 AAAAAAAAAAAAAA random(3,6) {			
			if (GetParticlesLevel() >= PL_Full) {
				if (!flamePartTex)
					flamePartTex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);

				PK_FlameParticle.SpawnFlameParticle(
					flamePartTex,
					pos,
					scale: 0.2,
					hvel: 0.6,
					vvel: frandom[sfx](0.4,1.5)
				);
			}
		}
		stop;
	}
}

// Originally, a decorative actor that was spawned directly.
// Now, only a container for the static function that spawns
// animated textured particles that imitate its look:
Class PK_FlameParticle : PK_SmallDebris {
	protected int rollOfs;
	Default {
		+NOINTERACTION
		+BRIGHT
		renderstyle 'add';
		scale 0.12;
		alpha 0.5;
	}

	static void SpawnFlameParticle(TextureID tex, vector3 pos, double scale = 0.15, double alpha = 0.5, double hvel = 0, double vvel = 0, double accelf = 0.02) {
		if (!tex)
			tex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);
		FSpawnParticleParams flamepart;	
		flamepart.color1 = "";
		flamepart.texture = tex;
		flamepart.lifetime = 34;
		flamepart.flags = SPF_FULLBRIGHT|SPF_ROLL|SPF_REPLACE;
		flamepart.style = STYLE_Add;
		flamepart.pos = pos;
		flamepart.vel = (frandom[sfx](-hvel, hvel), frandom[sfx](-hvel, hvel), vvel);
		flamepart.accel = flamepart.vel * -accelf;
		flamepart.startalpha = alpha;
		flamepart.fadestep = -1;
		flamepart.Size = TexMan.GetSize(tex) * scale;
		flamepart.sizeStep = flamepart.Size * 0.03;
		flamepart.startRoll = frandom[sfx](0, 360);
		flamepart.rollvel = frandom[sfx](2,4) * randompick[sfx](-1,1);
		Level.SpawnParticle(flamepart);
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

Class PK_FlamerTank : PK_Projectile {
	PK_FlamerTankModel tankmodel;	
	private bool landed;
	private double pitchMod;
	private double targetPitch;
	private double rollMod;

	TextureID flamePartTex;

	Default {
		-NOGRAVITY
		+ALLOWBOUNCEONACTORS
		-BOUNCEAUTOOFF
		+USEBOUNCESTATE
		bouncetype 'hexen';
		wallbouncefactor 0.25;
		bouncefactor 0.15;
		gravity 0.5;
		height 10;
		radius 16;
		speed 14;		
		damage (80);
		Obituary "$PKO_FLAMETANK";
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		tankmodel = PK_FlamerTankModel(Spawn("PK_FlamerTankModel",pos));
		if (tankmodel) {
			tankmodel.master = self;
			tankmodel.pitch = pitch;
			tankmodel.angle = angle;
		}
		A_StartSound("weapons/gastank/fire",CHAN_6);
		//tankmodel.roll = randompick[sfx](-10,10);
	}

	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		if (!tankmodel)
			return;			
		
		if (GetParticlesLevel() >= PL_Reduced) {
			if (!flamePartTex)
				flamePartTex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);
			
			PK_FlameParticle.SpawnFlameParticle(
				flamePartTex,
				tankmodel.pos + (frandom[sfx](-3,3), frandom[sfx](-3,3), frandom[sfx](-2,5)),
				scale: 0.3,
				alpha: 0.4,
				hvel: 0.7,
				vvel: frandom[sfx](0.8,1.8)
			);
			
			TextureID smokePartTex = TexMan.CheckForTexture(PK_BaseActor.GetRandomBlackSmoke());
			FSpawnParticleParams smokepart;	
			smokepart.color1 = "";
			smokepart.texture = smokePartTex;
			smokepart.lifetime = 30;
			smokepart.flags = SPF_ROLL|SPF_REPLACE;
			smokepart.pos = tankmodel.pos + (frandom[sfx](-6,6), frandom[sfx](-6,6), frandom[sfx](10,14));
			smokepart.vel = (frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),frandom[eld](1,1.2));
			smokepart.startalpha = 0.5;
			smokepart.fadestep = -1;
			smokepart.Size = TexMan.GetSize(smokePartTex) * 0.4;
			smokepart.sizeStep = smokepart.Size * -0.03;
			smokepart.startRoll = frandom[etc](-20, 20);
			Level.SpawnParticle(smokepart);
		}
		
		if (!landed) {
			//tankmodel.A_SetRoll(tankmodel.roll+10, SPF_INTERPOLATE);
			if (age > 200)
				SetStateLabel("XDeath");
			return;
		}
		else {
			vel *= 0.9;
		}

		if (!tankmodel.straight && abs(rollMod) > 0.01) {
			tankmodel.A_SetRoll(tankmodel.roll+rollMod, SPF_INTERPOLATE);
			rollMod *= 0.96;
		}
		
		if ( (pitchMod > 0 && tankmodel.pitch < targetPitch) || (pitchMod < 0 && tankmodel.pitch > targetPitch)) {
			tankmodel.A_SetPitch(Clamp(tankmodel.pitch + pitchMod, -180, 180));
			//console.printf("targetPitch: %d | pitch: %d",targetPitch,tankmodel.pitch);
		}
	}

	States {
	Spawn:
		TNT1 A 1 {
			double vvel = vel.length();
			//console.printf("in Spawn; vel: %f", vvel);
			if (tankmodel)
				tankmodel.A_SetPitch(tankmodel.pitch + vvel, SPF_INTERPOLATE);
			if (!landed && vvel < 3 && pos.z <= floorz+20) {
				rollMod = vvel * frandom[sfx](0.5,1) *randompick[sfx](-1,1);
				bMISSILE = false;
				bUSEBOUNCESTATE = false;
				return ResolveState("Death");
			}
			return ResolveState(null);
		}
		loop;
	Bounce:
		TNT1 A 1 {
			A_StartSound("weapons/gastank/bounce",flags:CHANF_NOSTOP);
		}
		goto spawn;
	Death:
		TNT1 A 175 {
			if (tankmodel) {
				tankmodel.pitch = Normalize180(tankmodel.pitch);
				if (abs(tankmodel.pitch) < 165)
					targetPitch = 90 * PK_Utils.Sign(tankmodel.pitch);
				else {
					tankmodel.straight = true;
					targetPitch = tankmodel.pitch;
				}
				pitchMod = -(tankmodel.pitch - targetPitch) / 4;
			}
			landed = true;
			//console.printf("Landed %d | pitch: %d | targetPitch: %d",landed, tankmodel.pitch, targetPitch);
			A_SetTics(random[gas](140,180));
		}
	XDeath:
		TNT1 A 1 {
			landed = true;
			A_StartSound("weapons/gastank/explosion");
			let ex = PK_GenericExplosion(Spawn("PK_GenericExplosion",pos));
			if (ex) {
				ex.smokingdebris = 0;
				ex.explosivedebris = 12;
				ex.randomdebris = 10;
				ex.scale *= 1.5;
				ex.alpha = 1.5;
				ex.quakeintensity = 4;
				ex.quakeduration = 16;
				ex.quakeradius = 400;
			}
			
			if (waterlevel < 3) {
				if (GetParticlesLevel() >= PL_Reduced) {
					for (int i = 4; i >= 0; i--) {
						let debris = Spawn("PK_FlameTankPiece",pos + (frandom[sfx](-6,6),frandom[sfx](-6,6),frandom[sfx](2,6)));
						if (debris) {
							double zvel = (pos.z > floorz) ? frandom[sfx](-2,6) : frandom[sfx](4,8);
							debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
							debris.frame = i;
						}
					}
				}
				if (GetParticlesLevel() >= PL_Full && tankmodel) {
					for (int i = 15; i > 0; i--) {
						if (!flamePartTex)
							flamePartTex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);

						PK_FlameParticle.SpawnFlameParticle(
							flamePartTex,
							tankmodel.pos + (frandom[sfx](-6,6), frandom[sfx](-6,6), frandom[sfx](pos.z > floorz + height ? - 12 : 4,12)),
							scale: 0.4,
							alpha: 0.65,
							hvel: 0.5,
							vvel: frandom[sfx](pos.z > floorz + height ? -10 : 4,10),
							accelf: 0.03
						);
					}
				}
				bool b; Actor fl;
				for (int i = 0; i < 360; i+= 20) {
					double zp;
					if (pos.z <= floorz)
						zp = 12;
					else if (pos.z >= ceilingz-12)
						zp = -24;
					[b, fl] = A_SpawnItemEx("PK_FlameThrowerFlame", xofs:16, zofs:zp, xvel: 2, angle:i);
					if (b && fl) {
						fl.target = target;
					}
				}
			}

			if (tankmodel)
				tankmodel.destroy();
			int exdist = 180;
			A_Explode(320,exdist);
		}
		stop;
	}
}

Class PK_FlamerTankModel : Actor {
	bool straight;
	Default {
		+NOGRAVITY
		+SHOOTABLE
		+THRUACTORS
		+NOBLOOD
		health 50;
		radius 24;
		height 20;
	}
	override void Tick() {
		super.Tick();
		if (!master) {
			destroy();
			return;
		}
		double pz = straight ? 20 : 6;
		SetOrigin(master.pos + (0,0,pz),true);
	}
	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath) {
		if (master)
			master.SetStateLabel("XDeath");
		super.Die(source, inflictor, dmgflags, MeansOfDeath);
	}
	States {
	Spawn:
		M000 A -1;
		stop;
	}
}

Class PK_FlameTankPiece : PK_RandomDebris {
	TextureID flamePartTex;

	Default {
		PK_RandomDebris.spritename 'PFLD';
		scale 0.12;
	}

	override void Tick () {
		Super.Tick();
		if (isFrozen() || waterlevel > 1)
			return;
		if (GetAge() % 3 == 0) {
			if (!flamePartTex)
				flamePartTex = TexMan.CheckForTexture("PFLPA0", TexMan.Type_Wall);

			PK_FlameParticle.SpawnFlameParticle(
				flamePartTex,
				pos+(frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](0,4)),
				scale: 0.2,
				alpha: alpha * 0.5,
				hvel: 0.6,
				vvel: frandom[sfx](1,2.2)
			);
		}
	}
	states {
	Death:
		#### # 50;
		#### # 1 {
			A_FadeOut(0.02);
		}
		wait;
	}
}