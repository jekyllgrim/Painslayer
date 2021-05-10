Mixin Class PK_PickupSound {
	//default PlayPickupSound EXCEPT the sounds can play over each other
	override void PlayPickupSound (Actor toucher)	{
		double atten;
		int chan;
		int flags = 0;

		if (bNoAttenPickupSound)
			atten = ATTN_NONE;
		else
			atten = ATTN_NORM;
		if (toucher != NULL && toucher.CheckLocalView()) {
			chan = CHAN_ITEM;
			flags = CHANF_NOPAUSE | CHANF_MAYBE_LOCAL | CHANF_OVERLAP;
		}
		else {
			chan = CHAN_ITEM;
			flags = CHANF_MAYBE_LOCAL;
		}
		
		toucher.A_StartSound(PickupSound, chan, flags, 1, atten);
	}
}

Class PK_Inventory : Inventory abstract {
	mixin PK_PlayerSightCheck;
	mixin PK_PickupSound;
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
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (bDROPPED)
			A_StartSound(pickupsound);
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
		if (owner)
			return;
		if (isFrozen())
			return;
		//Soul Catcher effect:
		if (tracer && tracer.player) {
			vel = Vec3To(tracer).Unit() * 10.5;
			bNOINTERACTION = true;
			if (Distance3D(tracer) < 32) {
				CallTryPickup(tracer);
				PlayPickupSound(tracer);
				tracer = null;
			}
		}
		else if (bNOINTERACTION)
			bNOINTERACTION = false;
		if (GetAge() % 10 == 0) {
			if (CheckPlayerSights() && !gleam && frandom[sfx](1,10) > 9) {
				gleam = PK_GoldGleam(Spawn("PK_GoldGleam",pos+(0,0,frandom(2,height))));
				if (gleam)
					gleam.scale *= frandom[sfx](1,1.4);
			}
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
		+INVENTORY.NEVERRESPAWN
		PK_Soul.maxage 350;
		inventory.pickupmessage "";
		inventory.amount 2;
		inventory.maxamount 100;
		renderstyle 'Add';
		//+NOGRAVITY;
		gravity 0.025;
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
		//Soul Catcher effect:
		if (tracer && tracer.player) {
			vel = Vec3To(tracer).Unit() * 10.5;
			bNOINTERACTION = true;
			if (Distance3D(tracer) < 32) {
				CallTryPickup(tracer);
				PlayPickupSound(tracer);
				tracer = null;
			}
		}
		else if (bNOINTERACTION)
			bNOINTERACTION = false;
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		if (cont.pk_souls >= cont.pk_minsouls && !other.FindInventory("PK_DemonWeapon")) {
			other.GiveInventory("PK_DemonWeapon",1);
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
	mixin PK_PlayerSightCheck;
	mixin PK_PickupSound;
	Default {
		inventory.pickupmessage "$PKI_GOLDSOUL";
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
		if (GetAge() % 10 == 0)
			canSeePlayer = CheckPlayerSights();
		if (canSeePlayer)
			A_SpawnItemEx(
				"PK_GoldSoulparticle",
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

Class PK_GoldSoulparticle : PK_BaseFlare {
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
		inventory.pickupmessage "$PKI_MEGASOUL";
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

///////////////////////////
////////           ////////
////////   ARMOR   ////////
////////           ////////
///////////////////////////

Class PK_BronzeArmor : GreenArmor  {
	Default {
		inventory.pickupsound "pickups/armor/bronze";
		inventory.pickupmessage "$PKI_ARMOR1";
		Armor.SavePercent 33.335;
		Armor.SaveAmount 100;
		scale 0.65;
		inventory.icon "pkharm1";
	}
	states {
	Spawn:
		PARM A -1;
		stop;
	}
}

Class PK_SilverArmor : PK_BronzeArmor  {
	Default {
		inventory.pickupsound "pickups/armor/silver";
		inventory.pickupmessage "$PKI_ARMOR2";
		Armor.SavePercent 60;
		Armor.SaveAmount 150;
		inventory.icon "pkharm2";
	}
	states {
	Spawn:
		PARM B -1;
		stop;
	}
}

Class PK_GoldArmor : PK_BronzeArmor  {
	Default {
		inventory.pickupsound "pickups/armor/gold";
		inventory.pickupmessage "$PKI_ARMOR3";
		Armor.SavePercent 80;
		Armor.SaveAmount 200;
		inventory.icon "pkharm3";
	}
	states {
	Spawn:
		PARM C -1;
		stop;
	}
}

////////////////////////////
////////            ////////
////////  POWER UPS ////////
////////            ////////
////////////////////////////

// A base 'power-up' class that doesn't define any special behavior except being time-limited. It's designed to be used in manual checks.
Class PK_PowerUp : PK_Inventory abstract {
	int duration;
	property duration : duration;
	Default {
		+INVENTORY.ALWAYSPICKUP
		inventory.maxamount 1;
		PK_PowerUp.duration 40;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		if (GetAge() % 35 == 0) {
			duration--;
			console.printf("%s remaining time: %d",GetClassName(),duration);
		}
		if (duration <= 0) {
			if (deathsound)
				owner.A_StartSound(deathsound, CHAN_AUTO, CHANF_LOCAL);
			DepleteOrDestroy();
		}
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let pwr = PK_PowerUp(other.FindInventory(GetClassName()));
		if (pwr && pwr.duration > 0) {
			pwr.duration = pwr.default.duration;
			GoAwayAndDie();
			return false;
		}
		return super.TryPickup(other);
	}
}

Class PK_WeaponModifier : PK_PowerUp {
	Default {
		inventory.pickupmessage "$PKI_WMODIFIER";
		inventory.pickupsound "pickups/wmod/pickup";
		deathsound "pickups/wmod/end";
		//activesound "pickups/wmod/use";
		PK_PowerUp.duration 30;
		xscale 0.43;
		yscale 0.36;
		+FLOATBOB
		FloatBobStrength 0.32;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen() || owner)
			return;
		if (GetAge() % 10 == 0)
			canSeePlayer = CheckPlayerSights();
		if (canSeePlayer) {
			color col = Color(0xff,0x45+random[sfx](0,100),0x00);
			A_SpawnParticle(
				col,
				SPF_FULLBRIGHT|SPF_RELVEL|SPF_RELACCEL,
				lifetime:random(20,60),size:frandom[sfx](1.5,4),
				angle:frandom[sfx](0,359),
				xoff:frandom[sfx](-4,4),yoff:frandom[sfx](-4,4),zoff:frandom[sfx](14,24) + GetBobOffset(),
				velx:frandom[sfx](0.5,1.5),velz:frandom[sfx](-0.2,-1),accelx:frandom[sfx](-0.05,-0.2),accelz:0.02,
				startalphaf:0.9,sizestep:-0.2
			);
		}
	}
	states {
	Spawn:
		PMOD A -1;
		stop;
	}
}