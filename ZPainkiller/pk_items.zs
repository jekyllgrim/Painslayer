Class PK_Soul : Health {
	Default {
		inventory.pickupmessage "";
		inventory.amount 1;
		inventory.maxamount 200;
		inventory.pickupsound "";
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 1;
		xscale 0.25;
		yscale 0.2;
		inventory.pickupsound "pickups/soul";
		+BRIGHT;
		+INVENTORY.ALWAYSPICKUP;
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
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		return super.TryPickup(other);
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

Class PK_GoldSoul : Health {
	Default {
		inventory.pickupmessage "Gold Soul!";
		inventory.amount 100;
		inventory.maxamount 100;
		inventory.pickupsound "";
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 0.9;
		xscale 0.4;
		yscale 0.332;
		inventory.pickupsound "pickups/soul/gold";
		+COUNTITEM
		+BRIGHT;
		+RANDOMIZE;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;	
		A_SpawnItemEx(
			"GoldSoulparticle",
			xofs: frandom[part](4,10),zofs:frandom[part](16,32),
			xvel:-0.35,zvel:frandom[part](0.5,2),
			angle:frandom[part](0,359)
		);
	}
	states {
	Spawn:
		GSOU ABCDEFGHIJKLMNOPQRSTU 2;
		loop;
	}
}

Class GoldSoulparticle : PK_BaseFlare {
	Default {
		scale 0.025;
		renderstyle 'Add';
		PK_BaseFlare.style 1;
		PK_BaseFlare.fadefactor 0.02;
		PK_BaseFlare.shrinkfactor 0.9;
		alpha 1;
	}
}

Class PK_MegaSoul : PK_GoldSoul {
	Default {
		inventory.amount 200;
		inventory.maxamount 200;
		inventory.pickupsound "pickups/soul/mega";
		inventory.pickupmessage "Mega soul!";
		xscale 0.3;
		yscale 0.25;
		alpha 2.5;
	}
	override void Tick() {
		Actor.Tick();
	}
	states {
	Spawn:
		MSOU ABCDEFGHIJKLMNOPQRSTU 2;
		loop;
	}
}