Class PK_Soul : Inventory {
	Default {
		inventory.pickupmessage "";
		inventory.amount 1;
		inventory.maxamount 200;
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 1;
		xscale 0.25;
		yscale 0.2;
		inventory.pickupsound "pickups/soul";
		+BRIGHT;
	}
	override void PlayPickupSound (Actor toucher)
	{
		double atten;
		int chan;
		int flags = 0;

		if (bNoAttenPickupSound)
		{
			atten = ATTN_NONE;
		}
		else
		{
			atten = ATTN_NORM;
		}

		if (toucher != NULL && toucher.CheckLocalView())
		{
			chan = CHAN_ITEM;
			flags = CHANF_NOPAUSE | CHANF_MAYBE_LOCAL | CHANF_OVERLAP;
		}
		else
		{
			chan = CHAN_ITEM;
			flags = CHANF_MAYBE_LOCAL;
		}
		toucher.A_StartSound(PickupSound, chan, flags, 1, atten);
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		if (other.FindInventory("PK_DemonWeapon")) {
			console.printf("already a demon, can't pick up souls");
			return false;
		}
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		if (cont.pk_souls >= cont.pk_minsouls) {
			other.GiveInventory("PK_DemonWeapon",1);			
			let dew = PK_DemonWeapon(other.FindInventory("PK_DemonWeapon"));
			if (dew) {
				dew.prevweapon = other.player.readyweapon;
				other.player.pendingweapon = dew;
			}
		}
		other.GiveBody(Amount, MaxAmount);
		GoAwayAndDie();
		return true;
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
		DSOU ABCDEFGHIJKLMNOPQRSTU 2;
		goto spawn+1;
	}
}

Class PK_RedSoul : PK_Soul {
	Default {
		inventory.amount 10;
		translation "0:255=%[0.00,0.00,0.00]:[2.00,0.00,0.00]";
		alpha 0.85;
		inventory.pickupsound "pickups/soul/red";
	}
}

Class PK_DemonMorphControl : Inventory {
	int pk_souls;
	int pk_minsouls;
	int pk_fullsouls;
	property minsouls : pk_minsouls;
	property fullsouls : pk_fullsouls;
	Default {
		PK_DemonMorphControl.minsouls 4;
		PK_DemonMorphControl.fullsouls 6;
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
	}
	override void Tick() {}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player || !owner.player.readyweapon)
			return;
		console.printf("souls: %d | Demon Weapon: %d",pk_souls,owner.CountInv("PK_DemonWeapon"));
	}
}

Class PK_DemonWeapon : PKWeapon {
	PK_DemonMorphControl control;
	private int minsouls;
	private int fullsouls;	
	private int dur;	
	Weapon prevweapon;
	Default {
		+WEAPON.NOAUTOFIRE;
		+WEAPON.DONTBOB;
		+WEAPON.CHEATNOTWEAPON;
		weapon.upsound "";
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		minsouls = control.pk_minsouls;
		fullsouls = control.pk_fullsouls;
		dur = 5;
		Shader.SetEnabled( players[consoleplayer], "DemonMode", true);
		owner.A_StartSound("demon/start",CHAN_AUTO,flags:CHANF_LOCAL);
		owner.A_StartSound("demon/loop",66,CHANF_LOOPING,attenuation:20);
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player || owner.bKILLED || !control || control.pk_souls < minsouls) {
			Destroy();
			return;
		}
		if (control) {
			if (control.pk_souls >= minsouls && control.pk_souls < fullsouls) {
				if (GetAge() >= 35) {
					owner.player.pendingweapon = prevweapon;				 
					Destroy();
					return;
				}
			}
			else if (control.pk_souls >= fullsouls && GetAge() >= 35*dur) {
				control.pk_souls = 0;
				owner.player.pendingweapon = prevweapon;
				Destroy();
				return;
			}
		}
	}	
	override void DetachFromOwner() {
		Shader.SetEnabled( players[consoleplayer], "DemonMode", false);
		owner.A_StopSound(66);
		owner.A_StartSound("demon/end",CHAN_AUTO,CHANF_LOCAL);
		super.DetachFromOwner();
	}
	states {
	Ready:
		DCRH A 1 {
			A_WeaponOffset(0,0);
			if (invoker.control && invoker.control.pk_souls >= invoker.fullsouls)
				A_WeaponReady(WRF_NOSWITCH|WRF_NOBOB);
		}
		loop;
	Fire:
		DCRH A 20 {
			A_WeaponOffset(0,0);
			A_StartSound("demon/fire",CHAN_AUTO);
			A_FireBullets(5,5,50,50,"PK_NullPuff",FBF_NORANDOM);
		}
		goto ready;
	}
}