Class PK_Boltgun : PKWeapon {
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
	Spawn:
		BGUZ A -1;
		stop;
	Ready:
		BGUN A 1 {
			PK_WeaponReady();
			if (invoker.ammo2.amount < 10) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 1;
			}
			A_Overlay(PSP_OVERGUN,"Bolts",nooverride:true);
			A_Overlay(PSP_SCOPE3,"Scope",nooverride:true);
		}
		loop;
	Bolts:
		BGUN C -1 {
			if (invoker.ammo1.amount < 5) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 3;
			}
		}
		stop;
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
			A_OverlayRotate(OverlayID(),Normalize180(angle));
		}
		loop;
	Fire:
		BGU1 A 0 {
			A_ClearOverlays(PSP_OVERGUN,PSP_OVERGUN);
			if (invoker.ammo2.amount < 10) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.sprite = GetSpriteIndex("BGU2");
			}
		}
		#### A 4 {
			TakeInventory(invoker.ammo1.GetClass(),1);
			A_FireProjectile("PK_Stake",useammo:false,spawnofs_xy:3,spawnheight:5,flags:FPF_NOAUTOAIM,pitch:-2.5);
			A_StartSound("weapons/boltgun/fire1",CHAN_5);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### B 4 {
			TakeInventory(invoker.ammo1.GetClass(),2);
			A_FireProjectile("PK_Stake",useammo:false,spawnofs_xy:0,spawnheight:3,flags:FPF_NOAUTOAIM,pitch:-2.5);
			A_FireProjectile("PK_Stake",useammo:false,spawnofs_xy:6,spawnheight:3,flags:FPF_NOAUTOAIM,pitch:-2.5);
			A_StartSound("weapons/boltgun/fire2",CHAN_6);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### C 2 {
			TakeInventory(invoker.ammo1.GetClass(),2);
			A_FireProjectile("PK_Stake",useammo:false,spawnofs_xy:-3,spawnheight:1,flags:FPF_NOAUTOAIM,pitch:-2.5);
			A_FireProjectile("PK_Stake",useammo:false,spawnofs_xy:9,spawnheight:1,flags:FPF_NOAUTOAIM,pitch:-2.5);
			A_StartSound("weapons/boltgun/fire3",CHAN_7);
			A_WeaponOffset(4,4,WOF_ADD);
		}
		#### D 2 {
			A_StartSound("weapons/boltgun/reload");
			A_ClearOverlays(PSP_SCOPE1,PSP_SCOPE3);
			A_Overlay(PSP_SCOPE1,"ScopeReload");
		}
		#### EFGH 2 A_WeaponOffset(-1,-1,WOF_ADD);
		#### IJKLM 3 A_WeaponOffset(-1,-1,WOF_ADD);
		#### NOPQRST 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		goto ready;
	ScopeReload:
		TNT1 A 0 A_OverlayPivot(OverlayID(),0,1);
		BGUS DDDD 1 {
			A_OverlayOffset(OverlayID(),2,-2,WOF_ADD);
			A_OverlayRotate(OverlayID(),-1.2,WOF_ADD);
			A_OverlayScale(OverlayID(),0.03,0.03,WOF_ADD);
		}
		BGUS D 29;
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
			A_Overlay(PSP_OVERGUN,"Bolts");
			A_StartSound("weapons/boltgun/heater");
		}
		BGUB ABCD 1 A_WeaponOffset(1.2,1.2,WOF_ADD);
		BGUB E 4 {
			A_WeaponOffset(6,6,WOF_ADD);
			TakeInventory(invoker.ammo2.GetClass(),10);
			double ofs = -2.2;
			double ang = 5;
			for (int i = 0; i < 10; i ++) {				
				A_FireProjectile("PK_Grenade",angle:ang+frandom[bolt](-0.5,0.5),useammo:false,spawnofs_xy:ofs,spawnheight:-4+frandom[bolt](-0.8,0.8),flags:FPF_NOAUTOAIM,pitch:-25+frandom[bolt](-3,3));
				ofs += 2.2;
				ang -= 1;
			}
		}
		BGUB FGHI 4 A_WeaponOffset(-2.5,-2.5,WOF_ADD);
		BGUB JKLMN 2  A_WeaponOffset(-0.2,-0.2,WOF_ADD);
		goto Ready;
	}
}