Class PK_Inventory : Inventory {
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


Class PK_GoldPickup : PK_Inventory abstract {
	PK_GoldGleam gleam;
	Default {
		inventory.maxamount 99999;
		inventory.amount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.NEVERRESPAWN;
		+BRIGHT
		xscale 0.5;
		yscale 0.415;
		radius 8;
		height 16;
		inventory.pickupmessage "";
	}
	override void Tick() {
		super.Tick();
		if (owner)
			return;
		if (isFrozen())
			return;
		if (level.time % 10 != 0)
			return;
		if (frandom[sfx](1,10) > 9 && !gleam) {
			gleam = PK_GoldGleam(Spawn("PK_GoldGleam",pos+(0,0,frandom(2,height))));
			if (gleam)
				gleam.scale *= frandom[sfx](1,1.4);
		}
	}
	states {
	Spawn:
		PGLD # -1;
		stop;
	}
}

Class PK_GoldGleam : PK_BaseFlare {
	private int scaledir;
	Default {
		renderstyle 'Translucent';
		+ROLLCENTER
		alpha 3;
		scale 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		scaledir = 1;
	}
	states {
	Spawn:
		PGLD Z 1 {
			//roll -= 5;
			A_SetScale(scale.x+(0.02 * scaledir));
			if (scale.x > default.scale.x*1.1)
				scaledir = -1;
			if (scale.x < default.scale.x*0.1)
				destroy();
		}
		loop;
	}
}

Class PK_SmallGold : PK_GoldPickup {
	Default {
		height 4;
		inventory.pickupsound "pickups/gold/small";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](0,4);
	}
}

Class PK_MedGold : PK_GoldPickup {
	Default {
		height 8;
		inventory.pickupsound "pickups/gold/med";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](5,9);
	}
}

Class PK_BigGold : PK_GoldPickup {
	Default {
		height 10;
		inventory.pickupsound "pickups/gold/big";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](10,13);
	}
}

Class PK_VeryBigGold : PK_GoldPickup {
	Default {
		height 14;
		inventory.pickupsound "pickups/gold/vbig";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](14,16);
	}
}