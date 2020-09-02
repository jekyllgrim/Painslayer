Class PK_InventoryToken : Inventory {
	Default {
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
		+INVENTORY.PERSISTENTPOWER;
	}
	override void Tick() {}
}

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

Class PK_GoldPickup : PK_Inventory abstract {
	protected PK_GoldGleam gleam;
	Default {
		+INVENTORY.NEVERRESPAWN;
		+BRIGHT
		xscale 0.5;
		yscale 0.415;
		radius 8;
		height 16;
		inventory.amount 1;
		inventory.pickupmessage "";
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_CardControl(other.FindInventory("PK_CardControl"));
		if (cont) {
			int goldmul = (other.FindInventory("PKC_Greed")) ? 2 : 1;
			cont.pk_gold = Clamp(cont.pk_gold + (amount*goldmul), 0, 99990);
		}
		GoAwayAndDie();
		return true;
	}
	override void Tick() {
		super.Tick();
		if (owner) {
			return;
		}
		if (isFrozen())
			return;
		if (tracer && tracer.player) {
			vel = Vec3To(tracer).Unit() * 12;
		}
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
		inventory.amount 3;
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
		inventory.amount 10;
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
		inventory.amount 50;
		height 11;
		inventory.pickupsound "pickups/gold/big";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](10,13);
	}
}

Class PK_VeryBigGold : PK_GoldPickup {
	Default {
		inventory.amount 100;
		height 16;
		inventory.pickupsound "pickups/gold/vbig";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](14,16);
	}
}

Class PK_Soul : PK_Inventory {
	PK_BoardEventHandler event;
	protected int age;
	protected int maxage;
	property maxage : maxage;
	Default {
		PK_Soul.maxage 350;
		inventory.pickupmessage "";
		inventory.amount 2;
		inventory.maxamount 100;
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 1;
		xscale 0.25;
		yscale 0.2;
		inventory.pickupsound "pickups/soul";
		+BRIGHT;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		event = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		if (!event || !event.SoulKeeper)
			age++;
		if (tracer && tracer.player) {
			vel = Vec3To(tracer).Unit() * 12;
		}
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		if (cont.pk_souls >= cont.pk_minsouls && !other.FindInventory("PK_DemonWeapon")) {
			let weap = other.player.readyweapon;
			other.GiveInventory("PK_DemonWeapon",1);			
			let dew = PK_DemonWeapon(other.FindInventory("PK_DemonWeapon"));
			if (dew) {
				if (weap) {
					//console.printf("prev weapon %s",weap.GetClassName());
					dew.prevweapon = weap;
				}
				other.player.readyweapon = dew;
				let psp = other.player.GetPSprite(PSP_WEAPON);
				if (psp) {
					other.player.SetPSprite(PSP_WEAPON,dew.FindState("Ready"));
					psp.y = WEAPONTOP;
				}
				/*else
					Console.printf("something went really wrong");*/
			}
		}
		if (other.FindInventory("PKC_SoulRedeemer"))
			amount *= 2;
		other.GiveBody(Amount, MaxAmount);
		GoAwayAndDie();
		return true;
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
		DSOU ABCDEFGHIJKLMNOPQRSTU 2 {
			if (age > maxage)
				A_FadeOut(0.05);
		}
		goto spawn+1;
	}
}

Class PK_RedSoul : PK_Soul {
	Default {
		inventory.amount 15;
		PK_Soul.maxage 450;
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