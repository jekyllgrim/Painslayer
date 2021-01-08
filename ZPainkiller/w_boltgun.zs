Class PK_Boltgun : PKWeapon {
	private bool scoped;
	const scopeOfs = 12;
	private vector2 prevOfs;
	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		weapon.slotnumber 	7;
		weapon.ammotype1	"PK_Bolts";
		weapon.ammouse1		5;
		weapon.ammogive1	40;
		weapon.ammotype2	"PK_Bombs";
		weapon.ammogive2	0;
		weapon.ammouse2		10;
		scale 0.23;
		inventory.pickupmessage "Picked up Boltgun/Heater";
		inventory.pickupsound "pickups/weapons/Boltgun";
		Tag "Boltgun/Heater";
	}
	states {
	Cache:		
		BGUN ABCD 0;
		BGU1 ABCDEFGHIIJKLMNOPQRST 0;
		BGU2 ABCDEFGHIIJKLMNOPQRST 0;		
	Spawn:
		BGUZ A -1;
		stop;
	Deselect:
		TNT1 A 0 {
			A_ZoomFactor(1.0,ZOOM_NOSCALETURNING|ZOOM_INSTANT);
			A_ClearOverlays(PSP_OVERGUN,PSP_SCOPE3);
		}
		goto super::Deselect;
	Select:
		TNT1 A 0 {		
			A_Overlay(PSP_OVERGUN,"Bolts");
			A_Overlay(PSP_SCOPE3,"Scope");
		}
		TNT1 A 0 A_Raise();
		wait;
	Ready:
		BGUN A 1 {
			PK_WeaponReady(WRF_NOBOB);
			if (invoker.ammo2.amount < 10) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 1;
			}
			A_Overlay(PSP_OVERGUN,"Bolts",nooverride:true);
			A_Overlay(PSP_SCOPE3,"Scope",nooverride:true);
			if (player.cmd.buttons & BT_ZOOM && !(player.oldbuttons & BT_ZOOM)) {
				if (!invoker.scoped) {
					A_ZoomFactor(2);
					A_Overlay(PSP_HIGHLIGHTS,"GoScope",nooverride:true);
				}
				else {
					A_ZoomFactor(1.0);
					invoker.scoped = false;
				}
				A_OverlayFlags(PSP_HIGHLIGHTS,PSPF_ADDWEAPON|PSPF_ADDBOB,false);
			}
		}
		loop;
	GoScope:
		TNT1 A 0 {
			A_StartSound("weapons/boltgun/zoom");
			A_SetCrosshair(99);
		}
		BGUV AAA 1 A_WeaponOffset(scopeOfs,scopeOfs,WOF_ADD);
		TNT1 A 0 { 
			//A_WeaponOffset(48,48+32);
			invoker.scoped = true; 
		}
		BGUV A 1 {
			if (!invoker.scoped)
				return ResolveState("Unscope");
			return ResolveState(null);
		}
		wait;
	Unscope:
		TNT1 A 0 A_StartSound("weapons/boltgun/zoom");
		BGUV AAA 1 A_WeaponOffset(-scopeOfs,-scopeOfs,WOF_ADD);
		TNT1 A 0 {
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			A_SetCrosshair(0);
		}
		stop;
	Bolts:
		BGUN C 1 {
			if (invoker.ammo1.amount < 5) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 3;
			}
		}
		wait;
	Scope:
		BGUS A -1 {
			A_Overlay(PSP_SCOPE1,"ScopeBase");
			A_Overlay(PSP_SCOPE2,"ScopeHighlight");
			A_OverlayPivotAlign(PSP_SCOPE2,PSPA_CENTER,PSPA_CENTER);
		}
		stop;
	ScopeBase:
		BGUS B -1;
		stop;
	ScopeHighlight:
		BGUS C 1 {
			double ofs = 0 + (0.083 * Clamp(pitch,-60,60));			
			A_OverlayRotate(OverlayID(),Normalize180(angle));
			A_OverlayOffset(OverlayID(),ofs,ofs,WOF_INTERPOLATE);
		}
		loop;
	Fire:
		BGU1 A 0 {
			let psp = Player.FindPSprite(PSP_WEAPON);
			if (psp)
				invoker.prevOfs = (psp.x,psp.y);
			A_ClearOverlays(PSP_OVERGUN,PSP_OVERGUN);
			if (invoker.ammo2.amount < 10) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.sprite = GetSpriteIndex("BGU2");
			}
		}
		#### A 4 {
			TakeInventory(invoker.ammo1.GetClass(),1);
			int xofs = invoker.scoped ? 0 : 3;
			int yofs = invoker.scoped ? 11 : 5;
			A_FireProjectile("PK_Bolt",useammo:false,spawnofs_xy:xofs,spawnheight:yofs,flags:FPF_NOAUTOAIM);
			A_StartSound("weapons/boltgun/fire1",CHAN_5);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### B 4 {
			TakeInventory(invoker.ammo1.GetClass(),2);
			int xofs = invoker.scoped ? -3 : 0;
			int yofs = invoker.scoped ? 9 : 3;
			A_FireProjectile("PK_Bolt",useammo:false,spawnofs_xy:xofs,spawnheight:yofs,flags:FPF_NOAUTOAIM);
			xofs = invoker.scoped ? 3 : 6;
			A_FireProjectile("PK_Bolt",useammo:false,spawnofs_xy:xofs,spawnheight:yofs,flags:FPF_NOAUTOAIM);
			A_StartSound("weapons/boltgun/fire2",CHAN_6);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### C 2 {
			TakeInventory(invoker.ammo1.GetClass(),2);
			int xofs = invoker.scoped ? -6 : -3;
			int yofs = invoker.scoped ? 7 : 1;
			A_FireProjectile("PK_Bolt",useammo:false,spawnofs_xy:xofs,spawnheight:yofs,flags:FPF_NOAUTOAIM);
			xofs = invoker.scoped ? 6 : 9;
			A_FireProjectile("PK_Bolt",useammo:false,spawnofs_xy:xofs,spawnheight:yofs,flags:FPF_NOAUTOAIM);
			A_StartSound("weapons/boltgun/fire3",CHAN_7);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### D 2 {
			A_StartSound("weapons/boltgun/reload");
			A_ClearOverlays(PSP_SCOPE1,PSP_SCOPE3);
			A_Overlay(PSP_SCOPE1,"ScopeReload");
		}
		#### EFGHI 2 A_WeaponOffset(-1,-1,WOF_ADD);
		#### IJKLM 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		#### # 0 A_Overlay(PSP_SCOPE1,"ScopeReload");
		#### NOPQRST 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		TNT1 A 0 A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y,WOF_INTERPOLATE);
		goto ready;
	ScopeReload:
		TNT1 A 0 A_OverlayPivot(OverlayID(),0,1);
		BGUS DDDD 1 {
			A_OverlayOffset(OverlayID(),2,-2,WOF_ADD);
			A_OverlayRotate(OverlayID(),-1.2,WOF_ADD);
			A_OverlayScale(OverlayID(),0.03,0.03,WOF_ADD);
		}
		BGUS D 6;
		BGUS DDDD 1 {
			A_OverlayOffset(OverlayID(),-2,2,WOF_ADD);
			A_OverlayRotate(OverlayID(),1.2,WOF_ADD);
			A_OverlayScale(OverlayID(),-0.03,-0.03,WOF_ADD);
		}
		BGUS D -1 {
			A_OverlayRotate(OverlayID(),0);
			A_OverlayScale(OverlayID(),1,1);
		}
		stop;
	AltFire:
		TNT1 A 0 {
			let psp = Player.FindPSprite(PSP_WEAPON);
			if (psp)
				invoker.prevOfs = (psp.x,psp.y);
			A_Overlay(PSP_OVERGUN,"Bolts");
			A_StartSound("weapons/boltgun/heater");
		}
		BGUB ABCD 1 A_WeaponOffset(1.2,1.2,WOF_ADD);
		BGUB E 2 {
			A_WeaponOffset(6,6,WOF_ADD);
			TakeInventory(invoker.ammo2.GetClass(),10);
			double ofs = -2.2;
			double ang = 5;
			for (int i = 0; i < 10; i ++) {				
				let bomb = A_FireProjectile("PK_Bomb",angle:ang+frandom[bomb](-0.7,0.7),useammo:false,spawnofs_xy:ofs,spawnheight:-4+frandom[bomb](-0.8,0.8),flags:FPF_NOAUTOAIM,pitch:-25+frandom[bomb](-4,4));
				ofs += 2.2;
				ang -= 1;
			}
		}
		BGUB FGHI 3 A_WeaponOffset(-2.5,-2.5,WOF_ADD);
		BGUB JKLMNA 2  A_WeaponOffset(-0.1,-0.1,WOF_ADD);
		TNT1 A 0 A_WeaponOffset(invoker.prevOfs.x,invoker.prevOfs.y,WOF_INTERPOLATE);
		goto Ready;
	}
}

Class PK_Bolt : PK_Stake {
	Default {
		PK_Projectile.trailscale 0.01;
		+NOGRAVITY
		scale 0.86;
		speed 75;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		sprite = GetSpriteIndex("BOLT");
		basedmg = 40;
	}
}

Class PK_Bomb : PK_Projectile {
	protected int bounces;
	protected double rollChange;
	protected int rollDir;
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.035;
		PK_Projectile.trailfade 0.015;
		PK_Projectile.trailalpha 0.12;
		-NOGRAVITY
		+USEBOUNCESTATE
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		bouncetype 'hexen';
		bouncefactor 0.65;
		gravity 0.45;
		bouncesound "weapons/boltgun/bounce";
		height 6;
		radius 8;
		speed 15;		
		damage (10);
		scale 0.17;
	}
	override void Tick() {
		if (!isFrozen()) {
			if (bounces >= 1) {
				let smk = PK_WhiteSmoke(Spawn("PK_WhiteSmoke",pos+(frandom[sfx](-0.3,0.3),frandom[sfx](-0.3,0.3),frandom[sfx](-0.3,0.3))));
				if (smk) {
					smk.vel = (frandom[sfx](-1.2,1.2),frandom[sfx](-1.2,1.2),frandom[sfx](1.2,1.2));
					smk.A_SetScale(0.08);
					smk.alpha = 0.35;
					smk.fade = 0.02;
				}
			}
			roll += rollChange * rollDir;
		}
		super.Tick();
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		/*let trg = PK_GrenadeHitbox(Spawn("PK_GrenadeHitbox",pos));
		trg.master = self;
		trg.ggrenade = self;*/
		bouncefactor *= frandom[bomb](0.85,1.15);
		roll = frandom[sfx](-30,30);
		rollDir = randompick[sfx](-1,1);
		rollChange = frandom[sfx](2,5);
	}
	states {
		Spawn:
			KULK ABC 2;
			loop;
		Bounce:
			#### # 1 {
				bounces++;
				if (bounces > 2) 
					return ResolveState("XDeath");
				roll = frandom[sfx](-30,30);
				if (bounces == 1) {
					A_AttachLight('Bomb',DynamicLight.FlickerLight,"DDBB00",17,12,DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF);
					let red = PK_BaseFlare(Spawn("PK_ProjFlare",pos));
					if (red) {
						red.fcolor = "FF0000";
						red.master = self;
						red.alpha = 0.65;
						red.A_SetScale(0.06);
					}
				}
				return ResolveState(null);
			}
			goto spawn;
		Death:
		XDeath:
			TNT1 A 0 {
				bUSEBOUNCESTATE = false; //without this it'll glitch on sloped 3D floors (those be damned): it'll continuously jump into Bounce state and then into XDeath, in cycle
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
				for (int i = random[sfx](3,6); i > 0; i--) {
					let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
					if (debris) {
						double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
						debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
						debris.A_SetScale(0.5);
					}
				}
				A_AttachLight('Bomb',DynamicLight.PulseLight,"FFAA00",0,18,DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF,param:0.7);
			}
			BOM4 JKLMNOPQ 1 bright;
			BOM5 ABCDEFGHIJKLMN 1 bright A_FadeOut(0.05);
			stop;
	}
}