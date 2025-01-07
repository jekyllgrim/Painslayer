Class PK_Boltgun : PKWeapon {
	private bool scoped;
	private int scopedelay;
	const scopeOfs = 14;
	private vector2 prevOfs;
	private PK_ReflectionCamera cam;
	
	Default {
		+PKWeapon.NOAUTOSECONDARY
		PKWeapon.emptysound "weapons/empty/rifle";
		PKWeapon.ammoSwitchCVar 'pk_switch_BoltgunHeater';
		weapon.slotnumber 	7;
		weapon.ammotype1	"PK_BoltAmmo";
		weapon.ammouse1		5;
		weapon.ammogive1	40;
		weapon.ammotype2	"PK_BombAmmo";
		weapon.ammogive2	10;
		weapon.ammouse2		10;
		inventory.pickupmessage "$PKI_BOLTGUN";
		inventory.pickupsound "pickups/weapons/Boltgun";
		inventory.icon "PKWIF0";
		Tag "$PK_BOLTGUN_TAG";
	}

	action void PK_FireBoltGun(double leftright = 0, double updown = 0) {
		Fire3DProjectile("PK_Bolt", useammo: false, forward: 1, leftright: leftright, updown: updown);
	}
	
	action void A_BoltgunScale(double scalex, double scaley, int flags = 0)
	{
		A_OverlayScale(PSP_Weapon, scalex, scaley, flags);
		A_OverlayScale(PSP_OVERGUN, scalex, scaley, flags);
		A_OverlayScale(PSP_SCOPE1, scalex, scaley, flags);
		A_OverlayScale(PSP_SCOPE2, scalex, scaley, flags);
		A_OverlayScale(PSP_SCOPE3, scalex, scaley, flags);
	}
	
	action void A_BoltgunRotate(double angle, int flags = 0)
	{
		A_OverlayRotate(PSP_Weapon, angle, flags);
		A_OverlayRotate(PSP_OVERGUN, angle, flags);
		A_OverlayRotate(PSP_SCOPE1, angle, flags);
		A_OverlayRotate(PSP_SCOPE2, angle, flags);
		A_OverlayRotate(PSP_SCOPE3, angle, flags);
	}
	
	action void A_BoltgunPivot(double wx = 0.5, double wy = 0.5, int flags = 0)
	{
		A_OverlayPivot(PSP_Weapon, wx, wy, flags);
		A_OverlayPivot(PSP_OVERGUN, wx, wy, flags);
		A_OverlayPivot(PSP_SCOPE1, wx, wy, flags);
		A_OverlayPivot(PSP_SCOPE2, wx, wy, flags);
		A_OverlayPivot(PSP_SCOPE3, wx, wy, flags);
	}
	
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		let wpn = owner.player.readyweapon;
		if (wpn == self && !cam) {
			cam = PK_ReflectionCamera(Spawn("PK_ReflectionCamera", pos));
			cam.plr = PlayerPawn(owner);
			TexMan.SetCameraToTexture(cam, "Weapon.camtex", 120/*owner.player.FOV*/);
		}
		if (wpn != self && cam) {
			cam.Destroy();
		}
		if (scopedelay > 0) {
			scopedelay--;
			return;
		}
		if (wpn != self)
			return;
		let plr = owner.player;
		if (plr.cmd.buttons & BT_ZOOM && !(plr.oldbuttons & BT_ZOOM)) {
			scopedelay = 5;
			scoped = !scoped;
			state scopestate = scoped ? ResolveState("GoScope") : ResolveState("Unscope");
			plr.SetPSprite(PSP_HIGHLIGHTS,scopestate);
		}
	}
	
	states {
	Cache:		
		BGUN ABCD 0;
		BGU1 ABCDEFGHIIJKLMNOPQRST 0;
		BGU2 ABCDEFGHIIJKLMNOPQRST 0;		
	Spawn:
		PKWI F -1;
		stop;
	Deselect:
		TNT1 A 0 {
			A_ZoomFactor(1.0,ZOOM_NOSCALETURNING|ZOOM_INSTANT);
			invoker.scoped = false;
			A_ClearOverlays(PSP_OVERGUN,PSP_SCOPE3);
		}
		goto super::Deselect;
	Select:
		TNT1 A 0 {		
			A_Overlay(PSP_OVERGUN,"Bolts");
			A_Overlay(PSP_SCOPE3,"Scope");
		}
		TNT1 A 0 A_Raise();
		goto super::Select;
	Ready:
		BGUN A 1 {
			vector2 wofs = (0,32);
			if (invoker.scoped)
				wofs += (invoker.scopeOfs,invoker.scopeOfs) * 3;
			A_WeaponOffset(wofs.x,wofs.y);
			if (!PK_CheckAmmo(true)) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 1;
			}
			A_Overlay(PSP_OVERGUN,"Bolts",nooverride:true);
			A_Overlay(PSP_SCOPE3,"Scope",nooverride:true);
			/*if (player.cmd.buttons & BT_ZOOM && !(player.oldbuttons & BT_ZOOM)) {
				if (!invoker.scoped) {
					A_ZoomFactor(2);
					A_Overlay(PSP_HIGHLIGHTS,"GoScope",nooverride:true);
					invoker.scoped = true;
				}
				else {
					A_ZoomFactor(1.0);
					invoker.scoped = false;
				}
			}*/
			PK_WeaponReady(invoker.scoped ? WRF_NOBOB : 0);
		}
		loop;
	GoScope:
		TNT1 A 0 {
			A_ZoomFactor(2);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON|PSPF_ADDBOB,false);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
			A_OverlayScale(OverlayID(),1.3,1.3);
			A_StartSound("weapons/boltgun/zoom",8);
			A_SetCrosshair(99);
		}
		BGUV AAA 1 {
			A_WeaponOffset(scopeOfs,scopeOfs,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.1,-0.1,WOF_ADD);
		}
		BGUV A 1 {
			if (!player.readyweapon || player.readyweapon != invoker)
				return ResolveState("Null");
			if (!invoker.scoped)
				return ResolveState("Unscope");
			return ResolveState(null);
		}
		wait;
	Unscope:
		TNT1 A 0 {
			A_ZoomFactor(1.0);
			A_StartSound("weapons/boltgun/zoom",8);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON|PSPF_ADDBOB,false);
			A_OverlayPivotAlign(OverlayID(),PSPA_CENTER,PSPA_CENTER);
		}
		BGUV AAA 1 {
			A_WeaponOffset(-scopeOfs,-scopeOfs,WOF_ADD);
			A_OverlayScale(OverlayID(),0.1,0.1,WOF_ADD);
		}
		TNT1 A 0 {
			//A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_SetCrosshair(0);
		}
		stop;
	Bolts:
		BGUN C 1 {
			if (!PK_CheckAmmo()) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 3;
			}
		}
		wait;
	Scope:	
		BGUS E -1 {
			A_Overlay(PSP_SCOPE1,"ScopeBase");
			A_Overlay(PSP_SCOPE2,"ScopeHighlight");
			A_OverlayFlags(PSP_SCOPE2,PSPF_ALPHA|PSPF_FORCEALPHA,true);
			A_OverlayAlpha(PSP_SCOPE2,0.5);
			A_OverlayPivotAlign(PSP_SCOPE2,PSPA_CENTER,PSPA_CENTER);
		}
		stop;
	ScopeBase:
		BGUS A -1;
		stop;
	ScopeHighlight:
		BGUS F 1 {
			double ofs = 0 + (0.083 * Clamp(pitch,-60,60));			
			A_OverlayRotate(OverlayID(),Normalize180(angle));
			A_OverlayOffset(OverlayID(),ofs,ofs,WOF_INTERPOLATE);
		}
		loop;
	Fire:
		BGU1 A 0 {
			let psp = Player.FindPSprite(OverlayID());
			if (psp)
				invoker.prevOfs = (psp.x,psp.y);
			A_ClearOverlays(PSP_OVERGUN,PSP_OVERGUN);
			if (!PK_CheckAmmo(true)) {
				if (psp)
					psp.sprite = GetSpriteIndex("BGU2");
			}
		}
		#### A 4 {
			double xofs = invoker.scoped ? 0 : 3;
			double yofs = invoker.scoped ? 2 : 0;
			PK_FireBoltGun(xofs, yofs);
			PK_DepleteAmmo(amount:1);
			PK_AttackSound("weapons/boltgun/fire1",CHAN_5);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### B 4 {
			double xofs = invoker.scoped ? -2.5 : 0;
			double yofs = invoker.scoped ? 1 : -1;
			PK_DepleteAmmo(amount:2);
			PK_FireBoltGun(xofs, yofs);
			xofs = invoker.scoped ? 2.5 : 6;
			PK_FireBoltGun(xofs, yofs);
			A_StartSound("weapons/boltgun/fire2",CHAN_6);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### C 2 {
			double xofs = invoker.scoped ? -5 : -3;
			double yofs = invoker.scoped ? 0 : -2;
			PK_DepleteAmmo(amount:2);
			PK_FireBoltGun(xofs, yofs);
			xofs = invoker.scoped ? 5 : 9;
			PK_FireBoltGun(xofs, yofs);
			A_StartSound("weapons/boltgun/fire3",CHAN_7);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### # 0 {
			if (!PK_CheckAmmo())
				return ResolveState("FireEndEmpty");
			return ResolveState(null);
		}
		#### D 2 {
			A_StartSound("weapons/boltgun/reload");
			A_ClearOverlays(PSP_SCOPE1,PSP_SCOPE3);
			A_Overlay(PSP_SCOPE2,"ScopeReload");
			return ResolveState(null);
		}
		#### EFGHI 2 A_WeaponOffset(-1,-1,WOF_ADD);
		#### IJKLM 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		#### # 0 A_Overlay(PSP_SCOPE2,"ScopeReload");
		#### NNOOPPQQRRSSTT 1 A_WeaponOffset(-0.25,-0.25,WOF_ADD);
		TNT1 A 0 A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y,WOF_INTERPOLATE);
		goto ready;
	FireEndEmpty:
		#### ###### 1 A_WeaponOffset(-2,-2,WOF_ADD);
		TNT1 A 0 A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y);
		goto ready;
	ScopeReload:
		BGUS E 0 {
			A_OverlayPivot(OverlayID(),0,1);
			A_OverlayPivot(PSP_SCOPE1,0,1);
			A_Overlay(PSP_SCOPE1,"ScopeBase");
		}
		#### #### 1 {
			A_OverlayOffset(OverlayID(),2,-2,WOF_ADD);
			A_OverlayRotate(OverlayID(),-1.2,WOF_ADD);
			A_OverlayScale(OverlayID(),0.03,0.03,WOF_ADD);
			A_OverlayOffset(PSP_SCOPE1,4,-2,WOF_ADD);
			A_OverlayRotate(PSP_SCOPE1,-1.2,WOF_ADD);
			A_OverlayScale(PSP_SCOPE1,0.03,0.03,WOF_ADD);
		}
		#### # 6;
		#### #### 1 {
			A_OverlayOffset(OverlayID(),-2,2,WOF_ADD);
			A_OverlayRotate(OverlayID(),1.2,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.03,-0.03,WOF_ADD);
			A_OverlayOffset(PSP_SCOPE1,-4,2,WOF_ADD);
			A_OverlayRotate(PSP_SCOPE1,1.2,WOF_ADD);
			A_OverlayScale(PSP_SCOPE1,-0.03,-0.03,WOF_ADD);
		}
		#### # -1 {
			A_OverlayRotate(OverlayID(),0);
			A_OverlayScale(OverlayID(),1,1);
			A_OverlayRotate(PSP_SCOPE1,0);
			A_OverlayScale(PSP_SCOPE1,1,1);
		}
		stop;
	AltFire:
		TNT1 A 0 {
			let psp = Player.FindPSprite(PSP_WEAPON);
			if (psp)
				invoker.prevOfs = (psp.x,psp.y);
			A_Overlay(PSP_OVERGUN,"Bolts");
			PK_AttackSound("weapons/boltgun/heater");
			A_ClearOverlays(PSP_SCOPE1,PSP_SCOPE2);
			A_BoltgunPivot(0.1, 1.0);
		}
		BGUB ABCD 1 
		{
			A_WeaponOffset(1.2,1.2,WOF_ADD);
			A_BoltgunScale(0.03, 0.03, WOF_ADD);
			A_BoltgunRotate(-2, WOF_ADD);
		}
		BGUB E 2 {
			A_BoltgunScale(0.06, 0.036, WOF_ADD);
			A_BoltgunRotate(-4, WOF_ADD);
			A_WeaponOffset(6,6,WOF_ADD);
			PK_DepleteAmmo(true);
			double ofs = -2.2;
			double ang = 5;
			double bpitch = invoker.hasWmod ? -15 : -25;
			for (int i = 0; i < 10; i++) {				
				let bomb = PK_FireArchingProjectile("PK_Bomb",angle:ang+frandom[bomb](-0.7,0.7),useammo:false,spawnofs_xy:ofs,spawnheight:-4+frandom[bomb](-0.8,0.8),pitch:bpitch+frandom[bomb](-4,4));
				ofs += 2.2;
				ang -= 1;
			}
		}
		BGUB FGHI 3 
		{
			A_BoltgunScale(-0.03, -0.03, WOF_ADD);
			A_BoltgunRotate(2, WOF_ADD);
			A_WeaponOffset(-2.5,-2.5,WOF_ADD);			
		}
		TNT1 A 0 {
			A_Overlay(PSP_SCOPE3,"Scope");
			A_BoltgunScale( 1, 1, WOF_INTERPOLATE);
			A_BoltgunRotate(0, WOF_INTERPOLATE);
			if (!PK_CheckAmmo(true)) {
				A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y,WOF_INTERPOLATE);
				return ResolveState("Ready");
			}
			return ResolveState(null);
		}
		BGUB JKLMNA 2 A_WeaponOffset(-0.1,-0.1,WOF_ADD);
		TNT1 A 0 A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y,WOF_INTERPOLATE);
		goto Ready;
	}
}

Class PK_ReflectionCamera : Actor {
	PlayerPawn plr;
	Default	{
		+NOINTERACTION
		radius 1;
		height 1;
	}
	override void Tick() {
		if (!plr) {
			Destroy();
			return;
		}
		Warp(
			plr, 
			xofs:-plr.radius, 
			yofs:8,
			zofs: plr.player.viewheight - 8
		);
		A_SetRoll(plr.roll + 180,SPF_INTERPOLATE);
		A_SetAngle(plr.angle + 180,SPF_INTERPOLATE);
		A_SetPitch(plr.pitch * -1,SPF_INTERPOLATE);
	}
}

Class PK_Bolt : PK_Stake {
	Default {
		PK_Projectile.trailscale 0.01;
		PK_Projectile.surfaceSpeed 85;
		+NOGRAVITY
		scale 0.86;
		Obituary "$PKO_BOLT";
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		basedmg = mod ? 70 : 57;
		if (mod)
			trailcolor = "F43510";
		burnstate = BS_CannotBurn;
	}

	override void StakeBreak() {
		for (int i = random[sfx](3,5); i > 0; i--) {
			let deb = PK_RandomDebris(Spawn("PK_RandomDebris",(pos.x,pos.y,pos.z)));
			if (deb) {
				deb.A_SetScale(0.5);
				double vz = frandom[sfx](-1,-4);
				if (pos.z <= botz)
					vz = frandom[sfx](3,6);
				deb.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),vz);
			}
		}
		A_StartSound("weapons/boltgun/boltbreak",volume:0.8, attenuation:3);
		PK_StakeProjectile.StakeBreak();
	}
}

Class PK_ExplosiveBolt : PK_ExplosiveStake {
	Default {
		PK_Projectile.trailcolor "ff7538";
		PK_Projectile.trailscale 0.024;
		PK_Projectile.trailfade 0.04;
		PK_Projectile.trailalpha 0.35;
		speed 75;
		DamageFunction (35);
		decal "Scorch";
		obituary "$PKO_EXBOLT";
	}
	states {
	Death:
		TNT1 A 0 { 
			bNOGRAVITY = true;
			bFORCEXYBILLBOARD = true;
			A_Quake(1,6,0,160,"");
			A_StartSound("weapons/boltgun/explosion",attenuation:1);
			A_Explode(64,96);				
			A_SetRenderstyle(alpha,STYLE_Add);
			A_SetScale(frandom[sfx](0.4,0.47));
			bSPRITEFLIP = randompick[sfx](0,1);
			roll = random[sfx](0,359);
			
			if (GetParticlesLevel() >= PL_Full) {
				for (int i = random[sfx](5,8); i > 0; i--) {
					let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
					if (debris) {
						double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](6,14);
						debris.vel = (frandom[sfx](-9,9),frandom[sfx](-9,9),zvel);
						debris.A_SetScale(0.5);
					}
				}
			}
			A_AttachLight('Bomb',DynamicLight.PulseLight,"FFAA00",0,32,DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF,param:1.2);
		}
		BOM4 JKLMNOPQ 1 bright;
		BOM5 ABCDEFGHIJKLMN 2 bright A_FadeOut(0.05);
		wait;
	}
}

Class PK_BombHitbox : PK_GrenadeHitbox {
	Default {
		PK_GrenadeHitbox.collider "PK_Bolt";
		PK_GrenadeHitbox.newstake "PK_ExplosiveBolt";
	}
}

Class PK_Bomb : PK_Projectile {
	protected int bounces;
	protected double rollOfs;
	protected int boomCountdown;

	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.035;
		PK_Projectile.trailfade 0.005;
		PK_Projectile.trailalpha 0.12;
		-NOGRAVITY
		+USEBOUNCESTATE
		+CANBOUNCEWATER
		bouncetype 'hexen';
		bouncefactor 0.65;
		gravity 0.45;
		height 5;
		radius 4;
		bouncesound "weapons/boltgun/bounce";
		speed 15;		
		DamageFunction (35);
		scale 0.3;
	}

	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		
		if (!isFrozen() && GetParticlesLevel() >= PK_BaseActor.PL_Reduced) {
			// start spawning smoke on top of trails
			// when the bombs have bounced once:
			if (bounces >= 1 && farenough) {
				TextureID smoketex = TexMan.CheckForTexture(PK_BaseActor.GetRandomWhiteSmoke());
				FSpawnParticleParams smoke;
				smoke.texture = smoketex;
				smoke.color1 = "";
				smoke.flags = SPF_ROLL|SPF_REPLACE;
				smoke.lifetime = 18;
				smoke.size = TexMan.GetSize(smoketex) * 0.08;
				smoke.sizestep = smoke.size * 0.03;
				smoke.startalpha = 0.35;
				smoke.fadestep = 0.02;
				smoke.vel = (frandom[sfx](-1.2,1.2),frandom[sfx](-1.2,1.2),frandom[sfx](1.2,1.2));
				smoke.pos = pos+(frandom[sfx](-0.3,0.3),frandom[sfx](-0.3,0.3),frandom[sfx](-0.3,0.3));
				smoke.startroll = random[sfx](0, 359);
				smoke.rollvel = frandom[sfx](0.5,1) * randompick[sfx](-1,1);
				Level.SpawnParticle(smoke);
			}
		}
		A_SetRoll(roll += rollOfs,SPF_INTERPOLATE);
		A_SetPitch(pitch += 20,SPF_INTERPOLATE);
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		let trg = PK_GrenadeHitbox(Spawn("PK_BombHitbox",pos));
		trg.master = self;
		trg.ggrenade = self;
		bouncefactor *= frandom[bomb](0.85,1.15);
		roll = frandom[sfx](-20,20);
		rollOfs = frandom[sfx](2,5) + randompick[sfx](-1,1);
		if (mod) {
			bounces = 3;
			ActivateBomb();
			gravity *= 0.5;
		}
	}

	void ActivateBomb() {
		boomCountdown = 35 * 4;
		A_AttachLight('Bomb',DynamicLight.FlickerLight,"DDBB00",17,12,DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF);
		let red = PK_BaseFlare(Spawn("PK_ProjFlare",pos));
		if (red) {
			red.fcolor = "FF0000";
			red.master = self;
			red.alpha = 0.65;
			red.A_SetScale(0.06);
		}
	}

	states {
	Spawn:
		M000 A 1 {
			// Jump to death if stuck armed for too long
			// (mostly for water or very tall sectors):
			if (boomCountdown > 0) {
				boomCountdown--;
				if (boomCountdown <= 0)
					return ResolveState("XDeath");
			}
			return ResolveState(null);
		}
		loop;
	Bounce:
		#### # 1 {
			bounces++;
			if (bounces > 2) 
				return ResolveState("XDeath");
			roll = frandom[sfx](-30,30);
			if (bounces == 1) 
				ActivateBomb();
			return ResolveState(null);
		}
		goto spawn;
	Death:
	XDeath:
		TNT1 A 0 {
			// Without setting this to false, it'll glitch on sloped 3D floors (those be damned): 
			// it'll continuously jump into Bounce state and then into XDeath over and over:
			bUSEBOUNCESTATE = false; 
			A_Stop();
			bNOGRAVITY = true;
			A_RemoveChildren(1,RMVF_EVERYTHING);
			A_StopSound(4);
			A_Quake(1,6,0,160,"");
			A_StartSound("weapons/boltgun/explosion",CHAN_5);
			A_Explode(32,80);
			A_SetRenderstyle(alpha,STYLE_Add);
			A_SetScale(frandom[sfx](0.25,0.3));
			bSPRITEFLIP = randompick[sfx](0,1);
			roll = random[sfx](0,359);
			
			if (GetParticlesLevel() >= PL_Full) {
				for (int i = random[sfx](3,6); i > 0; i--) {
					let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
					if (debris) {
						double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
						debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
						debris.A_SetScale(0.5);
					}
				}
			}
			A_AttachLight('Bomb',DynamicLight.PulseLight,"FFAA00",0,18,DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF,param:0.7);
		}
		BOM4 JKLMNOPQ 1 bright;
		BOM5 ABCDEFGHIJKLMN 1 bright A_FadeOut(0.05);
		stop;
	}
}