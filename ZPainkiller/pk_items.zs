Class PK_Soul : Health {
	Default {
		inventory.pickupmessage "";
		inventory.amount 1;
		inventory.maxamount 200;
		inventory.pickupsound "";
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 0.9;
		xscale 0.25;
		yscale 0.2;
		inventory.pickupsound "world/soulpickup";
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
	}
}

Class PK_Megahealth : PK_Soul {
	Default {
		inventory.pickupmessage "Mega Soul!";
		inventory.amount 100;
		inventory.maxamount 200;
		inventory.pickupsound "";
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 0.9;
		inventory.amount 100;
		xscale 0.4;
		yscale 0.332;
		inventory.pickupsound "world/goldensoul";
		+COUNTITEM
		+BRIGHT;
		+RANDOMIZE;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;	
		/*for (int i = 8; i > 0; i--) {
			A_SpawnParticle("gold",SPF_FULLBRIGHT|SPF_RELATIVE, 
				lifetime:random(20,35),size:5,
				angle: random(0,359),
				xoff: frandom[part](-8,8), yoff:frandom[part](-8,8),zoff:frandom[part](8,32),
				velx:-0.5,velz:frandom[part](0.8,2.2),
				startalphaf:0.9,sizestep:-0.05
			);*/
		A_SpawnItemEx(
			"PK_MegahealthParticle",
			xofs: frandom[part](4,10),zofs:frandom[part](16,32),
			xvel:-0.35,zvel:frandom[part](0.5,2),
			angle:frandom[part](0,359)
		);
	}
	states {
	Spawn:
		MSOU ABCDEFGHIJKLMNOPQRSTU 2;
		loop;
	}
}

Class PK_MegahealthParticle : PK_BaseFlare {
	Default {
		scale 0.025;
		PK_BaseFlare.fcolor 'gold';
		PK_BaseFlare.fadefactor 0.02;
		PK_BaseFlare.shrinkfactor 0.9;
		alpha 1;
	}
}