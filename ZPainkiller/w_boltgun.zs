Class PK_Boltgun : PKWeapon {
	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		weapon.slotnumber 3;
		weapon.ammotype1	"PK_Stakes";
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
		BGU1 A 1 {
			PK_WeaponReady();
			if (invoker.ammo1.amount < 5) {
				let psp = player.FindPSprite(OverlayID());
				if (psp)
					psp.frame = 2;
			}
			A_Overlay(PSP_OVERGUN,"Sight",nooverride:true);
		}
		loop;
	Sight:
		BGUN C 