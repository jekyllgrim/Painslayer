Class PK_Rifle : PKWeapon {
	private int shots;
	Default {
		PKWeapon.emptysound "weapons/empty/chaingun";
		weapon.slotnumber 6;
		weapon.ammotype1	"PK_Bullets";
		weapon.ammouse1		1;
		weapon.ammogive1	80;
		inventory.pickupmessage "Picked up a Rifle/Flamethrower";
		inventory.pickupsound "pickups/weapons/chaingun";
		Tag "Rocket Launcher/Chaingun";
	}
	action void PK_RifleScale(double wx, double wy, int flags = WOF_ADD) {
		A_OverlayScale(PSP_WEAPON,wx,wy,flags);
		A_OverlayScale(PSP_OVERGUN,wx,wy,flags);
		A_OverlayScale(PSP_SCOPE1,wx,wy,flags);
		A_OverlayScale(PSP_UNDERGUN,wx,wy,flags);
		A_OverlayScale(PSP_BELOWGUN,wx,wy,flags);
	}
	states {
	Select:
		TNT1 A 0 {
			A_Overlay(PSP_OVERGUN,"Bolt");
			A_Overlay(PSP_SCOPE1,"Stock");
			A_Overlay(PSP_UNDERGUN,"Barrel");
			A_Overlay(PSP_BELOWGUN,"Strap");
		}
		TNT1 A 0 A_Raise();
		wait;
	Ready:
		PKRI A 1 {
			PK_WeaponReady();
			A_Overlay(PSP_OVERGUN,"Bolt",nooverride:true);
			A_Overlay(PSP_SCOPE1,"Stock",nooverride:true);
			A_Overlay(PSP_UNDERGUN,"Barrel",nooverride:true);
			A_Overlay(PSP_BELOWGUN,"Strap",nooverride:true);
			invoker.shots = 0;
		}
		loop;
	Strap:
		PKRI E 20;
		TNT1 A 0 {
			if (vel.length() > 5)
				return ResolveState("StrapWobbleStart");
			return ResolveState(null);
		}
		loop;
	StrapWobbleStart:
		PKRI EEEEEE 1 A_OverlayRotate(OverlayID(),1,WOF_ADD);
	StrapWobble:
		PKRI EEEEEEEEEEEE 1 A_OverlayRotate(OverlayID(),-1,WOF_ADD);
		PKRI EEEEEEEEEEEE 1 A_OverlayRotate(OverlayID(),1,WOF_ADD);
		TNT1 A 0 {
			if (vel.length() > 5)
				return ResolveState("StrapWobble");
			return ResolveState(null);
		}
	StrapWobbleEnd:
		PKRI EEEEEE 1 A_OverlayRotate(OverlayID(),-1,WOF_ADD);
		goto Strap;
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
			A_StartSound("weapons/chaingun/fire",CHAN_WEAPON,flags:CHANF_OVERLAP);
			A_FireBullets(2.5,2.5,-1,9,pufftype:"PK_BulletPuff",flags:FBF_USEAMMO|FBF_NORANDOM,missile:"PK_BulletTracer",spawnheight:player.viewz-pos.z-40,spawnofs_xy:8.6);
			invoker.shots++;
			A_OverlayPivot(PSP_SCOPE1,-1,-2.1);
		}
		PKRI A 1 {
			PK_RifleScale(0.33,0.33);
			A_WeaponOffset(6,6,WOF_ADD);
			A_OverlayOffset(PSP_OVERGUN,4.5,3.3,WOF_ADD);
			A_OverlayOffset(PSP_UNDERGUN,6,6,WOF_ADD);
			A_OverlayScale(PSP_OVERGUN,0.33,0.33,WOF_ADD);
		}
		PKRI AAA 1 {
			A_WeaponOffset(-2,-2,WOF_ADD);
			A_OverlayOffset(PSP_OVERGUN,-1.45,-1.1,WOF_ADD);
			A_OverlayOffset(PSP_UNDERGUN,-2,-2,WOF_ADD);
			A_OverlayScale(PSP_OVERGUN,-0.11,-0.11,WOF_ADD);
			PK_RifleScale(-0.11,-0.11);
		}
		TNT1 A 0 {
			A_WeaponOffset(0,32);
			A_OverlayOffset(PSP_OVERGUN,0,0);
			PK_RifleScale(1,1,flags:0);
		}
		PKRI A 6 {
			if (invoker.shots < 7)
				A_ReFire();
			else
				A_ClearRefire();
		}
		goto ready;
	}
}