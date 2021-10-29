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
	Class<Inventory> latestPickup; //keep track of the latest pickup
	string latestPickupName; //the tag of the latest pickup
	bool codexOpened;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.PERSISTENTPOWER
		inventory.maxamount 1;
	}
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
		"BlueArmor",
		"BasicArmorPickup"
	};
	static const Class<Inventory> pkItems[] = {
		"PK_SilverArmor",
		"PK_GoldArmor",
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
		for (int i = 0; i < vanillaWeapons.Size(); i++) {
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
		for (int i = 0; i < vanillaWeapons.Size(); i++) {
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
		bool ret = false;
		let oldItemClass = item.GetClassName();
        Class<Inventory> replacement =  null;
		for (int i = 0; i < vanillaWeapons.Size(); i++) {
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
			ret = super.HandlePickup(item);
		}
		else {
			int r_amount = GetDefaultByType(replacement).amount;
			item.bPickupGood = true;
			owner.A_GiveInventory(replacement,r_amount);
			if (pk_debugmessages) {
				console.printf("Replacing %s with %s (amount: %d)",oldItemClass,replacement.GetClassName(),r_amount);
			}
			ret = true;
		}		
		RecordLastPickup(replacement ? replacement : item.GetClass());
        return ret;
    }
	
	/*	This function records the latest item the player has picked up
		for the first time. Used by the Codex to display the tab
		for that item (if available). See pk_codex.zs.
	*/	
	void RecordLastPickup(class<Inventory> toRecord) {
		if (!toRecord || !owner || !owner.player)
			return;
		bool isInCodex = false;
		for (int i = 0; i < CodexCoveredClasses.Size(); i++) {
			if (toRecord is CodexCoveredClasses[i]) {
				isInCodex = true;
				break;
			}
		}
		if (!isInCodex)
			return;
		int pnum = owner.PlayerNumber();
		if (pnum < 0)
		  return;

		let it = ThinkerIterator.Create("PK_PickupsTracker", STAT_STATIC);	
		let tracker = PK_PickupsTracker(it.Next());
		if (!tracker) {
			if (pk_debugmessages)
				console.printf("Item track Thinker not found");
			return;
		}
		

		/*	We use a dynamic array to check that the player hasn't
			picked up this item before, because CountInv won't catch
			the items that don't actually get placed in the inventory,
			such as armor.
		*/
		if (toRecord is "PK_GoldPickup" && tracker.pickups[pnum].pickups.Find((class<Inventory>)("PK_GoldPickup")) == tracker.pickups[pnum].pickups.Size()) {
			tracker.pickups[pnum].pickups.Push((class<Inventory>)("PK_GoldPickup"));
			latestPickup = toRecord;
			latestPickupName = GetDefaultByType(toRecord).GetTag();
			codexOpened = false;
			if (pk_debugmessages) {
				console.printf("Latest pickup is %s",latestPickup.GetClassName());
			}
		}
		
		else if (tracker.pickups[pnum].pickups.Find(toRecord) == tracker.pickups[pnum].pickups.Size()) {
			tracker.pickups[pnum].pickups.Push(toRecord);
			latestPickup = toRecord;
			latestPickupName = GetDefaultByType(toRecord).GetTag();
			codexOpened = false;
			if (pk_debugmessages) {
				console.printf("Latest pickup is %s",latestPickup.GetClassName());
			}
		}
	}
	
	static const Class<Actor> CodexCoveredClasses[] = {
		'PK_Painkiller',
		'PK_Shotgun',
		'PK_Stakegun',
		'PK_Chaingun',
		'PK_ElectroDriver',
		'PK_Rifle',
		'PK_Boltgun',
		'PK_Soul',
		'PK_GoldSoul',
		'PK_MegaSoul',
		'PK_BronzeArmor',
		'PK_SilverArmor',
		'PK_GoldArmor',
		'PK_AmmoPack',
		'PK_PowerAntiRad',
		'PK_AllMap',
		'PowerChestOfSoulsRegen',
		'PK_WeaponModifier',
		'PK_PowerDemonEyes',
		'PK_PowerPentagram',
		'PK_GoldPickup'
	};
}

struct PK_PlayerItems
{
    Array<class<Inventory> > pickups;
}

class PK_PickupsTracker : Thinker
{
    PK_PlayerItems pickups[MAXPLAYERS];
	
	PK_PickupsTracker Init(void)
    {
        ChangeStatNum(STAT_STATIC);
		return self;
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
		+INVENTORY.NEVERRESPAWN
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+BRIGHT
		+NOTELEPORT
		xscale 0.5;
		yscale 0.415;
		inventory.amount 1;
		inventory.pickupmessage "";
		Tag "$PKC_GOLDOBTAIN";
	}
	override bool Use (bool pickup) {
		if (!owner)
			return true;
		let cont = PK_CardControl(owner.FindInventory("PK_CardControl"));
		if (cont) {
			int goldmul = (owner.FindInventory("PKC_Greed")) ? 2 : 1;
			cont.pk_gold = Clamp(cont.pk_gold + (amount*goldmul), 0, 99990);
		}
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
				bool picked;
				[picked, tracer] = CallTryPickup(tracer);
				if (picked)
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
		Tag "$PKC_GOLDTYPES";
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
	protected int actualAmount;
	property maxage : maxage;
	Class<Actor> bearer;
	Default {
		+INVENTORY.NEVERRESPAWN
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+BRIGHT
		+DONTGIB		
		PK_Soul.maxage 350;
		inventory.pickupmessage "$PKI_SOUL";
		inventory.amount 2;
		inventory.maxamount 100;
		renderstyle 'Add';
		gravity 0.025;
		alpha 1;
		xscale 0.3;
		yscale 0.26;
		radius 16;
		height 20;
		inventory.pickupsound "pickups/soul";
		Tag "$PKC_Souls";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		event = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (bearer) {
			//define an amount between 1-20 based on monster's health (linearly mapped between 20-500):
			//the amount is clamped to 20 (or to 80 if the monster is a boss)
			int maxAmt = GetDefaultByType(bearer).bBOSS ? 80 : 20;
			double am = LinearMap(double(GetDefaultByType(bearer).health), 20, 500, 1, 20);
			amount = Clamp(am, 1, maxAmt);
			actualAmount = amount;
			//slightly change soul's alpha and scale based on the resulting number:
			alpha = Clamp(LinearMap(am, 1, 20, 0.5, 1.5), 0.5 , 1.5);
			scale *= Clamp(LinearMap(am, 1, 20, 0.6, 1.15), 0.7, 1.15);
			//define color and its density based on the alpha of the soul
			int colalpha = Clamp(LinearMap(alpha, 0.5, 1.5, 64, 255), 128 , 255);
			color lit = Color(colalpha, 0, 255, 0);
			//if the amount is over 15, make the soul red:
			if (am >= 15) {
				A_SetTranslation("PK_RedSoul");
				//A_SetRenderstyle(alpha,Style_Shaded);
				//SetShade("FF0000");
				lit = Color(colalpha, 255, 0, 0);
				pickupsound = "pickups/soul/red";
			}
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
				bool picked;
				[picked, tracer] = CallTryPickup(tracer);
				if (picked) {
					CallTryPickup(tracer);
					PlayPickupSound(tracer);
					PrintPickupMessage(tracer.CheckLocalView(), PickupMessage ());
				}
				tracer = null;
			}
		}
		else if (bNOINTERACTION)
			bNOINTERACTION = false;
	}
	override string PickupMessage () {
		return String.Format(StringTable.Localize(PickupMsg),actualAmount);
	}
	/*override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.GiveSoul();
		if (other.FindInventory("PKC_SoulRedeemer"))
			amount *= 2;
		other.GiveBody(Amount, MaxAmount);
		//Console.Printf("Consumed %d health from a soul",amount);
		GoAwayAndDie();
		return true;
	}*/
	
	override bool Use (bool pickup) { 
		if (!owner)
			return true;
		let cont = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.GiveSoul();
		if (owner.FindInventory("PKC_SoulRedeemer"))
			amount *= 2;
		owner.GiveBody(Amount, MaxAmount);
		return true; 
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
	Idle:
		DSOU ABCDEFGHIJKLMNOPQRSTU 2 {
			if (age > maxage)
				A_FadeOut(0.05);
		}
		loop;
	}
}

Class PK_ChestOfSouls : Inventory {
	mixin PK_PickupSound;
	Default {
		+COUNTITEM
		Inventory.Amount 20;
		Inventory.Maxamount 0;
		Inventory.PickupMessage "$PKI_CHESTOFSOULS";
		Inventory.PickupSound "pickups/chestOfSouls/pickup";
		xscale 0.4;
		yscale 0.34;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		//A_AttachLight('base',DynamicLight.FlickerLight,color(0,0,80,0), 16, 18, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTACTORS,(0,0,24));
		A_AttachLight('spot',DynamicLight.FlickerLight,color(200,0,255,0), 0, 48, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTACTORS|DYNAMICLIGHT.LF_SPOT,(0,0,0),spoti:24,spoto:48,spotp:-90);
		A_StartSound("pickups/chestOfSouls/idle",flags:CHANF_LOOP,attenuation:5);
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.GiveSoul(amount);
		other.GiveInventory("PowerChestOfSoulsRegen",1);
		GoAwayAndDie();
		return true;
	}
	States {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[sfx](1,12));
	Idle:
		PSOC ABCDEFGHIJKL 3;
		loop;
	}
}

Class PowerChestOfSoulsRegen : PowerRegeneration {
	Default {
		Powerup.Duration -20;
		Powerup.Strength 1;
		Tag "$PKC_ChestOfSouls";
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
		+NOGRAVITY
		alpha 0.9;
		xscale 0.4;
		yscale 0.332;
		inventory.pickupsound "pickups/soul/gold";
		+COUNTITEM
		+BRIGHT
		Tag "$PKC_GoldSoul";
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
	override bool TryPickup(in out actor toucher) {
		if (toucher && toucher.player) {
			let irc = PK_InvReplacementControl(toucher.FindInventory("PK_InvReplacementControl"));
			if (irc)
				irc.RecordLastPickup(self.GetClass());
		}
		return super.TryPickup(toucher);
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
	Idle:
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
		Tag "$PKC_MegaSoul";
	}
	override void Tick() {
		Actor.Tick();
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
	Idle:
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
		Tag "$PKC_Armor";
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
		Tag "$PKC_AmmoPack";
	}
	/*	Sometimes for some reason this item doesn't call
		HandlePickup on PK_InvReplacementControl, so I had to added
		this manual call so it gets registered as "latest pickup"
		properly.
	*/
	override bool TryPickup(in out actor toucher) {
		if (toucher && toucher.player) {
			let irc = PK_InvReplacementControl(toucher.FindInventory("PK_InvReplacementControl"));
			if (irc)
				irc.RecordLastPickup(self.GetClass());
		}
		return super.TryPickup(toucher);
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

/*	A mixin class that defines the following:
	- Plays runningOutsound every second if the remaining powerup time is between 1-5 seconds
	- Plays deathsound when the powerup effect ends
	- If a new powerup is picked up when the same powerup is active, its time is reset (but not added)
*/

Mixin Class PK_PowerUpBehavior {
	sound runningOutSound;
	property runningOutSound : runningOutSound;
	Default {
		+INVENTORY.ADDITIVETIME
	}
	/*override void Tick () {
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
	}*/
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player) {
			Destroy();
			return;
		}
		if (runningOutSound && EffectTics >= 0 && EffectTics <= 35*5 && (EffectTics % 35 == 0))
			owner.A_StartSound(runningOutSound,CHAN_AUTO,CHANF_LOCAL|CHANF_UI);
	}
	override void EndEffect () {
		if (owner && owner.player && deathsound)
			owner.A_StartSound(deathsound,CHAN_AUTO,CHANF_LOCAL|CHANF_UI);
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

/*	A standalone class containing the same behavior.
	Used by those powerups that don't need to be based on an existing ZDoom power-up.
*/
class PK_Powerup : Powerup {
	mixin PK_PowerUpBehavior;
}

Class PK_WeaponModifier : PK_Powerup {
	Default {
		deathsound "pickups/wmod/end";
		inventory.icon "wmodicon";
		Tag "$PKC_WeaponModifier";
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

Class PK_PowerDemonEyes : PK_Powerup {
	private PK_DemonEyesLight eyeslight1, eyeslight2;
	private int lightdir;
	private array <actor> feartargets;
	const feardist = 512;
	const fearangle = 48;
	Default {
		deathsound "pickups/powerups/lightampEnd";
		inventory.icon "iconeyes";
		Tag "$PKC_DemonEyes";
	}
	override void InitEffect() {
		super.InitEffect();
		if (owner && owner.player) {
			eyeslight1 = PK_DemonEyesLight(Spawn("PK_DemonEyesLight",owner.pos));
			eyeslight1.user = PlayerPawn(owner);
			eyeslight2 = PK_DemonEyesLight(Spawn("PK_DemonEyesLight",owner.pos));
			eyeslight2.user = PlayerPawn(owner);
			eyeslight2.isLeft = true;
			owner.player.extralight = 12;
		}
		lightdir = 1;
	}
	override void DoEffect() {
		super.DoEffect();
		/*if (level.time % 3 == 0 && owner && owner.player) {
			let plr = owner.player;
			plr.extralight += lightdir;
			if (plr.extralight > 12 || plr.extralight < -18) 
				lightdir *= -1;
		}*/
		BlockThingsIterator itr = BlockThingsIterator.Create(owner,feardist);
		while (itr.next()) {
			let next = itr.thing;
			if (!next || next == self)
				continue;
			if (feartargets.Find(next) != feartargets.Size())
				continue;
			bool isValid = (!next.bFRIGHTENED && next.bSHOOTABLE && next.bIsMonster && !next.bBOSS && next.health > 0);
			if (!isValid)
				continue;
			double dist = owner.Distance3D(next);
			if (dist > feardist)
				continue;
			if (!owner.CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;
			vector3 targetpos = LevelLocals.SphericalCoords((owner.pos.x,owner.pos.y,owner.player.viewz),next.pos+(0,0,next.default.height*0.5),(owner.angle,owner.pitch));	
			if (abs(targetpos.x) > fearangle || abs(targetpos.y) > fearangle)
				continue;
			feartargets.Push(next);
			let marker = Spawn("PK_FearTargetMarker",next.pos + (0,0,next.height + 6));
			if (marker) marker.master = next;
			owner.A_StartSound("pickups/powerups/fear",CHAN_AUTO,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
		}
		for (int i = 0; i < feartargets.Size(); i++) {
			if (!feartargets[i])
				continue;
			let trg = feartargets[i];
			if (trg.health <= 0 || owner.Distance3D(trg) > feardist || !owner.CheckSight(trg,SF_IGNOREWATERBOUNDARY)) {
				trg.bFRIGHTENED = trg.default.bFRIGHTENED;
				feartargets.Delete(i);
				continue;
			}
			vector3 targetpos = LevelLocals.SphericalCoords((owner.pos.x,owner.pos.y,owner.player.viewz),trg.pos+(0,0,trg.default.height*0.5),(owner.angle,owner.pitch));	
			if (abs(targetpos.x) > fearangle || abs(targetpos.y) > fearangle) {
				trg.bFRIGHTENED = trg.default.bFRIGHTENED;
				feartargets.Delete(i);
				continue;
			}
			trg.bFRIGHTENED = true;
		}
	}
	override void EndEffect() {
		if (eyeslight1)
			eyeslight1.Destroy();
		if (eyeslight2)
			eyeslight2.Destroy();
		if (owner && owner.player)			
			owner.player.extralight = 0;
		for (int i = 0; i < feartargets.Size(); i++) {
			if (!feartargets[i])
				continue;
			feartargets[i].bFRIGHTENED = feartargets[i].default.bFRIGHTENED;
		}
		super.EndEffect();
	}
}

class PK_FearTargetMarker : PK_SmallDebris {
	Default {
		+NOINTERACTION
		+BRIGHT
	}
	override void Tick() {
		if (!master || master.health <= 0 || !master.bFRIGHTENED) {
			Destroy();
			return;
		}
		SetOrigin(master.pos + (0,0,master.height + 6),true);
		if (scale.x > 0.5)
			scale *= 0.92;
		super.Tick();
	}
	States {
	Spawn:
		PDEO ABCDEFEDCBA 2;
		loop;
	}
}

class PK_DemonEyesLight : SpotLight {
	PlayerPawn user;
	bool isLeft;
	private double angOfs;
	override void PostBeginPlay() {
		super.PostBeginPlay();
		color c = "ffd50f";
		args[0] = c.r;
		args[1] = c.g;
		args[2] = c.b;
		args[3] = 512;
		SpotInnerAngle = 32;
		SpotOuterAngle = 56;
		angOfs = 8 * (isLeft ? 1 : -1);
	}
	override void Tick() {
		if (!user) {
			Destroy();
			return;
		}
		//Warp(user,zofs:user.player.viewheight,flags:WARPF_COPYPITCH|WARPF_WARPINTERPOLATION|WARPF_COPYVELOCITY);
		SetOrigin(user.pos+(0,0,user.player.viewheight),true);
		A_SetAngle(user.angle + angOfs,SPF_INTERPOLATE);
		A_SetPitch(user.pitch,SPF_INTERPOLATE);
		super.Tick();
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
	mixin PK_PowerUpBehavior;
	Default {
		deathsound "pickups/powerups/pentagramEnd";
		inventory.icon "penticon";
		Tag "$PKC_Pentagram";
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
	mixin PK_PowerUpBehavior;
	Default {
		deathsound "pickups/powerups/radsuitEnd";
		Powerup.Color "000000", 0;
		inventory.icon "HLBOA0";
		Tag "$PKC_Antirad";
	}
}

Class PK_AntiRadArmor : PK_PowerupGiver {
	Default {
		Powerup.Type "PK_PowerAntiRad";
		Inventory.PickupMessage "$PKI_ANTIRAD";
		PK_PowerUpGiver.pickupRingColor "11821c";
		inventory.pickupsound "pickups/powerups/radsuit";
		xscale 0.38;
		yscale 0.33;
	}
	States {
	Spawn:
		HLBO A -1;
		stop;
	}
}

Class PK_SafeMapMarker : MapMarker {
	Default {
		+NOINTERACTION
		+SYNCHRONIZED
		+DONTBLAST
		FloatBobPhase 0;
	}
}

class PK_AllMap : AllMap {
	mixin PK_SpawnPickupRing;
	Default {
		scale 0.6;
		inventory.pickupmessage "$PKI_ALLMAP";
		PK_AllMap.pickupRingColor "ce73fe";
		Tag "$PKC_CrystalBall";
	}
	override bool TryPickup (in out Actor toucher) {
		bool ret = super.TryPickup(toucher);
		if (ret) {
			if (toucher && toucher.player && toucher.player == players[consoleplayer]) {
				let handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
				handler.SpawnMapMarkers(toucher.player);
			}
			let irc = PK_InvReplacementControl(toucher.FindInventory("PK_InvReplacementControl"));
			if (irc)
				irc.RecordLastPickup(self.GetClass());
		}
		return ret;
	}			
	States {
	Spawn:
		PCY1 ABCDEFGH 3;
		PCY1 IJKLMMLKJIH 3;
		PCY1 NOPQRSTUVW 3;
		PCY1 VUTYZ 3;
		PCY2 GHIJKKJHIG 3;
		PCY2 ABCDEF 3;
		PCY1 QPONHGFEDCBA 3;
		loop;
	}
}

// The following is handled in the HUD instead

/*
Class PK_PowerupOverlay : CustomInventory {
	protected PK_PowerPentagram penta;
	Default {
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.PERSISTENTPOWER;
		+INVENTORY.AUTOACTIVATE;
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void Tick() {
		super.Tick();
		if (!owner || (owner.player && PK_Mainhandler.IsVoodooDoll(PlayerPawn(owner)))) {
			Destroy();
			return;
		}
	}
	States {
	Use:
		TNT1 A 1 A_Overlay(PWR_HANDLER,"Handler");
		fail;
	Handler:
		TNT1 A 1 {
			if (!invoker.penta) {
				invoker.penta = PK_PowerPentagram(FindInventory("PK_PowerPentagram"));
				if (invoker.penta)
					A_Overlay(PWR_PENTA,"Pentagram",nooverride:true);
			}
		}
		loop;
	Pentagram:
		PHRN ABCDEFEDCB 5 {
			if (!invoker.penta)
				return ResolveState("Null");
			else if (invoker.penta.isBlinking())
				return ResolveState("PentagramFast");
			return ResolveState(null);
		}
		loop;
	PentagramFast:
		PHRN ABCDEFGHI 4 {
			if (!invoker.penta)
				return ResolveState("Null");
			else if (!invoker.penta.isBlinking())
				return ResolveState("Pentagram");
			return ResolveState(null);
		}
		loop;
	}
}*/