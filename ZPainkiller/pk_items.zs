Class PK_InventoryToken : Inventory abstract {
	protected int age;
	Default {
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.PERSISTENTPOWER;
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || (owner.player && PK_Mainhandler.IsVoodooDoll(PlayerPawn(owner)))) {
			Destroy();
			return;
		}
		if (owner && !owner.isFrozen())
			age++;
	}
	override void Tick() {}
}

Class PK_InvReplacementControl : Inventory {
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.PERSISTENTPOWER
		inventory.maxamount 1;
	}
	const ALLWEAPONS = 9;
	static const Class<Weapon> vanillaWeapons[] = {
		"Fist",
		"Chainsaw",
		"Pistol",
		"Shotgun",
		"SuperShotgun",
		"Chaingun",
		"RocketLauncher",
		"PlasmaRifle",
		"BFG9000"
	};
	static const Class<Weapon> pkWeapons[] = {
		"PK_Painkiller",
		"PK_Painkiller",
		"PK_Painkiller",
		"PK_Shotgun",
		"PK_Stakegun",
		"PK_Chaingun",
		"PK_Boltgun",
		"PK_Rifle",
		"PK_Electrodriver"
	};
	static const Class<Inventory> vanillaItems[] = {
		"GreenArmor",
		"BlueArmor"
	};
	static const Class<Inventory> pkItems[] = {
		"PK_SilverArmor",
		"PK_GoldArmor"
	};
	//here we make sure that the player will never have vanilla weapons in their inventory:
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		let plr = owner.player;
		array < int > changeweapons; //stores all weapons that need to be exchanged
		int selweap = -1; //will store readyweapon
		//record all weapons that need to be replaced
		for (int i = 0; i < ALLWEAPONS; i++) {
			//if a weapon is found, cache its position in the array:
			Class<Weapon> oldweap = vanillaWeapons[i];
			if (owner.CountInv(oldweap) >= 1) {
				if (pk_debugmessages)  console.printf("found %s that shouldn't be here",oldweap.GetClassName());
				changeweapons.Push(i);
			}
			//also, if it was seleted, cache its number separately:
			if (owner.player.readyweapon && owner.player.readyweapon.GetClass() == oldweap)
				selweap = i;
		}
		//if no old weapons were found, do nothing else:
		if (changeweapons.Size() <= 0)
			return;
		for (int i = 0; i < ALLWEAPONS; i++) {
			//do nothing if this weapon wasn't cached:
			if (changeweapons.Find(i) == changeweapons.Size())
				continue;
			Class<Weapon> oldweap = vanillaWeapons[i];
			Class<Weapon> newweap = pkWeapons[i];
			//remove old weapon
			owner.A_TakeInventory(oldweap);
			if (pk_debugmessages) console.printf("Exchanging %s for %s",oldweap.GetClassName(),newweap.GetClassName());
			if (!owner.CountInv(newweap)) {
				owner.A_GiveInventory(newweap,1);
				/*
				//create a copy that won't give any ammo and attach it to the player
				let wp = Weapon(Spawn(newweap));
				if (wp) {
					wp.ammogive1 = 0;
					wp.ammogive2 = 0;
					wp.AttachToOwner(owner);
					//console.printf("Giving %s",wp.GetClassName());
				}*/
			}
		}		
		//select the corresponding new weapon if an old weapon was selected:
		if (selweap != -1) {
			Class<Weapon> newsel = pkWeapons[selweap];
			let wp = Weapon(owner.FindInventory(newsel));
			if (wp) {
				if (pk_debugmessages) console.printf("Selecting %s", wp.GetClassName());
				owner.player.pendingweapon = wp;
			}
		}
		changeweapons.Clear();
	}
    override bool HandlePickup (Inventory item) {
        let oldItemClass = item.GetClassName();
        Class<Inventory> replacement =  null;
		for (int i = 0; i < ALLWEAPONS; i++) {
			if (pkWeapons[i] && oldItemClass == vanillaWeapons[i]) {
				replacement = pkWeapons[i];
				break;
			}
		}
		for (int i = 0; i < vanillaItems.Size(); i++) {
			if (pkItems[i] && oldItemClass == vanillaItems[i]) {
				replacement = pkItems[i];
				break;
			}
		}
        if (!replacement) {
			if (pk_debugmessages > 1)
				console.printf("%s doesn't need replacing, giving as is",oldItemClass);
			return super.HandlePickup(item);
		}
		int r_amount = GetDefaultByType(replacement).amount;
        item.bPickupGood = true;
        owner.A_GiveInventory(replacement,r_amount);
		if (pk_debugmessages) {
			console.printf("Replacing %s with %s (amount: %d)",oldItemClass,replacement.GetClassName(),r_amount);
		}
        return true;
    }
}

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
	mixin PK_Math;
}

Class PK_GoldPickup : PK_Inventory abstract {
	protected PK_GoldGleam gleam;
	Default {
		+INVENTORY.NEVERRESPAWN;
		+BRIGHT
		xscale 0.5;
		yscale 0.415;
		inventory.amount 1;
		inventory.pickupmessage "";
	}
	/*override void PostBeginPlay() {
		super.PostBeginPlay();
		if (bDROPPED)
			A_StartSound(pickupsound);
	}*/
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
		if (bCOUNTITEM)
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
				if (gleam) {
					gleam.scale *= frandom[sfx](1,1.4);
					gleam.master = self;
				}
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
	vector3 masterofs;
	private int scaledir;
	Default {
		renderstyle 'Translucent';
		+ROLLCENTER
		alpha 3;
		scale 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master) {
			Destroy();
			return;
		}
		masterOfs = master.pos - pos;
		scaledir = 1;
	}
	override void Tick() {
		super.Tick();
		if (master)
			SetOrigin(master.pos - masterOfs,false);
		else
			Destroy();
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

Class PK_GoldCoin : PK_GoldPickup {
	double broll;
	Default {
		inventory.amount 5;
		+INVENTORY.NOSCREENFLASH
		height 4;
		inventory.pickupsound "pickups/gold/coin";
		bouncesound "pickups/gold/coindrop";
		bouncetype 'Doom';
		bouncecount 4;
		+MISSILE
		+ROLLSPRITE
		+ROLLCENTER
		xscale 0.4;
		yscale 0.44;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (vel ~== (0,0,0)) {
			bMISSILE = false;
			roll = 0;
			SetStateLabel("DeathEnd");
			return;
		}
		roll = frandom[sfx](0,359);
		broll = frandom[sfx](2,6) * randompick[sfx](-1,1);
		bouncefactor *= frandom[gold](0.7,1);
	}
	States {
	Spawn:
		PGLC ABCDEFGH 1 A_SetRoll(roll+broll);
		loop;
	Death:
		TNT1 A 0 { roll = randompick[sfx](-90,90); }
		PGLC ABC 1;
		PGLC DEF 2;
		PGLC GGGG 1 { roll *= 0.5; }
	DeathEnd:
		PGLC G -1 { roll = 0; }
		stop;
	}
}

Class PK_SmallGold : PK_GoldPickup {
	Default {
		inventory.amount 10;
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
		inventory.amount 25;
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
		inventory.amount 100;
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
		inventory.amount 500;
		height 16;
		inventory.pickupsound "pickups/gold/vbig";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		frame = random[gold](14,16);
	}
}

///////////////////////////
// ENEMY SOULS (healing) //
///////////////////////////

/*	Enemies spawn souls that will heal the player.
	The amount healed is based on the monster's spawnhealth
*/

Class PK_Soul : PK_Inventory {
	PK_BoardEventHandler event;
	protected int age;
	protected int maxage;
	property maxage : maxage;
	Class<Actor> bearer;
	Default {
		+INVENTORY.NEVERRESPAWN
		+BRIGHT
		+DONTGIB
		PK_Soul.maxage 350;
		inventory.pickupmessage "";
		inventory.amount 2;
		inventory.maxamount 100;
		renderstyle 'Add';
		//stencilcolor "00FF00";
		//+NOGRAVITY;
		gravity 0.025;
		alpha 1;
		xscale 0.3;
		yscale 0.26;
		radius 16;
		height 20;
		inventory.pickupsound "pickups/soul";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		event = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (bearer) {
			//define an amount between 1-20 based on monster's health (linearly mapped between 20-500):
			double am = Clamp(LinearMap(double(GetDefaultByType(bearer).health), 20, 500, 1, 20), 1, 20);
			amount = am;
			//slightly change soul's alpha and scale based on the resulting number:
			alpha = Clamp(LinearMap(am, 1, 20, 0.5, 1.5), 0.5 , 1.5);
			scale *= Clamp(LinearMap(am, 1, 20, 0.6, 1.15), 0.7, 1.15);
			color lit = "00FF00";
			//if the amount is over 15, make the soul red:
			if (am >= 15) {
				A_SetTranslation("PK_RedSoul");
				//A_SetRenderstyle(alpha,Style_Shaded);
				//SetShade("FF0000");
				lit = "FF0000";
				pickupsound = "pickups/soul/red";
			}
			lit *= alpha * 2;
			A_AttachLight('soul',DynamicLight.PointLight,lit, 48 * scale.x, 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_NOSHADOWMAP|DYNAMICLIGHT.LF_DONTLIGHTACTORS);
		}
		if (pk_debugmessages > 2) {
			string str = "none";
			if (bearer)
				str = bearer.GetClassName();
			console.printf("Spawned soul, bearer: %s, amount: %d",str,amount);
		}
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
			cont.GiveSoul();
		if (other.FindInventory("PKC_SoulRedeemer"))
			amount *= 2;
		other.GiveBody(Amount, MaxAmount);
		Console.Printf("Consumed %d health from a soul",amount);
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

/*Class PK_RedSoul : PK_Soul {
	Default {
		inventory.amount 15;
		PK_Soul.maxage 450;
		translation "0:255=%[0.00,0.00,0.00]:[2.00,0.00,0.00]";
		alpha 0.85;
		inventory.pickupsound "pickups/soul/red";
	}
}*/


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

Class PK_AmmoPack : Backpack {
	Default {
		inventory.pickupsound "pickups/ammopack";
		inventory.pickupmessage "$PKI_AMMOPACK";
		xscale 0.42;
		yscale 0.38;
	}
	states {
	Spawn:
		AMPK A -1;
		stop;
	}
}

Mixin Class PK_SpawnPickupRing {
	color pickupRingColor;
	property pickupRingColor : pickupRingColor;
	override void BeginPlay() {
		super.BeginPlay();
		if (!pickupRingColor)
			return;
		let ring = Spawn("PK_PickupRing",(pos.x,pos.y,floorz));
		if (ring) {
			ring.master = self;
			ring.SetShade(color(pickupRingColor));
		}
	}
}

Class PK_PickupRing : Actor {
	Default {
		+NOINTERACTION
		+BRIGHT
		renderstyle 'AddShaded';
		alpha 0.75;
	}
	override void Tick() {
		if (!master) {
			Destroy();
			return;
		}
		let mmaster = Inventory(master);
		if (!mmaster || mmaster.owner) {
			Destroy();
			return;
		}
		if (!isFrozen())
			SetOrigin(master.pos,true);
	}
	States {
	Spawn:
		BAL1 A -1;
		stop;
	}
}

Class PK_PowerupGiver : PowerupGiver {
	mixin PK_PlayerSightCheck;
	color pickupRingColor;
	property pickupRingColor : pickupRingColor;
	override void BeginPlay() {
		super.BeginPlay();
		if (!pickupRingColor)
			return;
		let ring = Spawn("PK_PickupRing",(pos.x,pos.y,floorz));
		if (ring) {
			ring.master = self;
			ring.SetShade(color(pickupRingColor));
		}
	}
	Default {
		powerup.duration -40;
		+COUNTITEM
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		Inventory.MaxAmount 0;
	}
	override bool TryPickup (in out Actor other) {
		if (!(other.player))
			return false;
		if (other.CountInv("PK_DemonWeapon"))
			return false;
		return super.TryPickup(other);
	}
}

Mixin Class PK_PowerUp {
	sound lastSecondsSound;
	property lastSecondsSound : lastSecondsSound;
	Default {
		+INVENTORY.ADDITIVETIME
	}
	override void Tick () {
		if (Owner == NULL)	{
			Destroy ();
			return;
		}
		//do not tick if the player is currently morphed into demon:
		if (owner.CountInv("PK_DemonWeapon"))
			return;
		if (EffectTics == 0 || (EffectTics > 0 && --EffectTics == 0)) {
			Destroy ();
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player) {
			Destroy();
			return;
		}
		if (lastSecondsSound && EffectTics >= 0 && EffectTics <= 35*5 && (EffectTics % 35 == 0))
			owner.A_StartSound(lastSecondsSound,CHAN_AUTO,CHANF_LOCAL);
	}
	override void EndEffect () {
		if (owner && owner.player && deathsound)
			owner.A_StartSound(deathsound,CHAN_AUTO,CHANF_LOCAL);
		super.EndEffect();
	}
	override bool HandlePickup (Inventory item) {
		if (item.GetClass() == GetClass()) {
			let power = Powerup(item);
			if (power.EffectTics == 0)	{
				power.bPickupGood = true;
				return true;
			}
			/*	Increase the effect's duration, but do not go over
				the default maximum duration (in contrast to vanilla
				PowerUp). I.e. you can't extend the duration 
				beyond max even if you pick up multiple powerups.
			*/
			if (power.bAdditiveTime) {
				EffectTics = Clamp(EffectTics + power.EffectTics, 0, default.EffectTics);
				BlendColor = power.BlendColor;
			}
			// If it's not blinking yet, you can't replenish the power unless the
			// powerup is required to be picked up.
			else if (EffectTics > BLINKTHRESHOLD && !power.bAlwaysPickup) {
				return true;
			}
			// Reset the effect duration.
			else if (power.EffectTics > EffectTics) {
				EffectTics = power.EffectTics;
				BlendColor = power.BlendColor;
			}
			power.bPickupGood = true;
			return true;
		}
		return false;
	}
}

Class PK_WeaponModifier : Powerup {
	mixin PK_PowerUp;
	Default {
		deathsound "pickups/wmod/end";
		inventory.icon "wmodicon";
	}
}		

Class PK_WeaponModifierGiver : PK_PowerUpGiver {
	Default {
		inventory.pickupmessage "$PKI_WMODIFIER";
		inventory.pickupsound "pickups/wmod/pickup";
		Powerup.Type "PK_WeaponModifier";
		PowerUp.duration -30;
		xscale 0.43;
		yscale 0.36;
		+FLOATBOB
		FloatBobStrength 0.32;
		PK_PowerUpGiver.pickupRingColor "f77300";
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
	override bool TryPickup (in out Actor other) {
		bool ret = super.TryPickup(other);
		if (ret && other is "PlayerPawn")
			other.GiveBody(100,100);
		return ret;
	}
	states {
	Spawn:
		PMOD A -1;
		stop;
	}
}

Class PK_PowerDemonEyes : PowerTorch {
	mixin PK_PowerUp;
	Default {
		deathsound "pickups/powerups/lightampEnd";
		inventory.icon "iconeyes";
	}
}

Class PK_DemonEyes : PK_PowerupGiver {
	Default {
		scale 0.5;
		+FLOATBOB
		FloatBobStrength 0.3;
		PK_PowerUpGiver.pickupRingColor "fefc6a";
		Powerup.Type "PK_PowerDemonEyes";
		inventory.pickupmessage "$PKI_DEMONEYES";
		inventory.pickupsound "pickups/powerups/lightamp";
	}
	States {
	Spawn:
		PDEY H 80 A_SetTics(random[sfx](8,80));
		PDEY FDB 1;
		PDEY ABCDEFG 2;
		loop;
	}
}

Class PK_PowerPentagram : PowerInvulnerable {
	mixin PK_PowerUp;
	Default {
		deathsound "pickups/powerups/pentagramEnd";
		inventory.icon "penticon";
	}
}


Class PK_Pentagram : PK_PowerupGiver {
	Default {
		+FLOATBOB
		+BRIGHT
		+INVENTORY.BIGPOWERUP
		Powerup.Type "PK_PowerPentagram";
		Inventory.PickupMessage "$GOTINVUL";
		renderstyle 'Add';
		FloatBobStrength 0.35;
		PK_PowerUpGiver.pickupRingColor "FF1904";
		inventory.pickupsound "pickups/powerups/pentagram";
		scale 1.5;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;	
		if (GetAge() % 10 == 0)
			canSeePlayer = CheckPlayerSights();
		if (canSeePlayer)
			A_SpawnParticle(
				"fc5a2d",
				SPF_FULLBRIGHT|SPF_RELVEL|SPF_RELACCEL,
				lifetime:random(20,60),size:frandom[sfx](2,4.2),
				angle:frandom[sfx](0,359),
				xoff:frandom[sfx](-12,12),yoff:frandom[sfx](-12,12),zoff:frandom[sfx](32,56) + GetBobOffset(),
				velx:frandom[sfx](0.5,1.5),velz:frandom[sfx](0.3,1.5),accelx:frandom[sfx](-0.05,-0.12),accelz:-0.01,
				startalphaf:0.9,sizestep:-0.1
			);
	}
	States {
	Spawn:
		BAL1 ABCDEFGHIJKLMNOPQRSTUVWXYZ 5;
		BAL2 ABCDEFGHIJKLMNOPQRSTUV 5;
		loop;
	}
}

Class PK_PowerAntiRad : PowerIronFeet {
	mixin PK_PowerUp;
	Default {
		deathsound "pickups/powerups/radsuitEnd";
		Powerup.Color "000000", 0;
		inventory.icon "HLBOB0";
	}
}

Class PK_AntiRadArmor : PK_PowerupGiver {
	Default {
		Powerup.Type "PK_PowerAntiRad";
		Inventory.PickupMessage "$PKI_ANTIRAD";
		PK_PowerUpGiver.pickupRingColor "11821c";
		inventory.pickupsound "pickups/powerups/radsuit";
		scale 0.4;	
	}
	States {
	Spawn:
		HLBO B -1;
		stop;
	}
}	