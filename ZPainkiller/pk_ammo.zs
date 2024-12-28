/////////////////////////
// AMMO PICKUPS
/////////////////////////

Class PK_Shells : Ammo {
	Default {
		inventory.pickupmessage "$PKI_SHELLS";
		inventory.pickupsound "pickups/ammo/shells";
		inventory.icon "pkhshell";
		inventory.amount 12;
		inventory.maxamount 100;
		ammo.backpackamount 24;
		ammo.backpackmaxamount 100;
		xscale 0.3;
		yscale 0.25;
	}
	states {
	spawn:
		AMSH A -1;
		stop;
	}
}

Class PK_FreezerAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_FREEZEAMMO";
		inventory.pickupsound "pickups/ammo/freezerammo";
		inventory.icon "pkhfreez";
		inventory.amount 8;
		inventory.maxamount 100;
		ammo.backpackamount 16;
		ammo.backpackmaxamount 100;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMFR A -1;
		stop;
	}
}


Class PK_StakeAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_STAKEAMMO";
		inventory.pickupsound "pickups/ammo/stakes";
		inventory.icon "pkhstake";
		inventory.amount 8;
		inventory.maxamount 100;
		ammo.backpackamount 16;
		ammo.backpackmaxamount 100;
		xscale 0.3;
		yscale 0.25;
	}
	states	{
	spawn:
		AMST A -1;
		stop;
	}
}

Class PK_GrenadeAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_GRENADEAMMO";
		inventory.pickupsound "pickups/ammo/grenades";
		inventory.icon "pkhrock";
		inventory.amount 5;
		inventory.maxamount 100;
		ammo.backpackamount 10;
		ammo.backpackmaxamount 100;
		scale 0.4;
	}
	states	{
	spawn:
		AMRO A -1;
		stop;
	}
}

Class PK_BulletAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_MINIGUNAMMO";
		inventory.pickupsound "pickups/ammo/bullets";
		inventory.icon "pkhbull";
		inventory.amount 40;
		inventory.maxamount 500;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 500;
		scale 0.4;
	}
	states	{
	spawn:
		AMBE A -1;
		stop;
	}
}


Class PK_ShurikenAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_STARAMMO";
		inventory.pickupsound "pickups/ammo/stars";
		inventory.icon "pkhstars";
		inventory.amount 20;
		inventory.maxamount 250;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 250;
		xscale 0.3;
		yscale 0.25;
	}
	states {
	spawn:
		AMSU A -1;
		stop;
	}
}

Class PK_CellAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_ELECTROAMMO";
		inventory.pickupsound "pickups/ammo/battery";
		inventory.icon "pkhshock";
		inventory.amount 40;
		inventory.maxamount 500;
		ammo.backpackamount 100;
		ammo.backpackmaxamount 500;
		scale 0.4;
		yscale 0.34;
	}
	states	{
	spawn:
		AMEL A -1;
		stop;
	}
}

Class PK_RifleBullets : Ammo {
	Default {
		inventory.pickupmessage "$PKI_RIFLEAMMO";
		inventory.pickupsound "pickups/ammo/riflebullets";
		inventory.icon "pkhmag";
		inventory.amount 30;
		inventory.maxamount 250;
		ammo.backpackamount 90;
		ammo.backpackmaxamount 250;
		scale 0.4;
	}
	states	{
	spawn:
		AMRB A -1;
		stop;
	}
}

Class PK_FuelAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_FUELAMMO";
		inventory.pickupsound "pickups/ammo/fuel";
		inventory.icon "pkhfuel";
		inventory.amount 80;
		inventory.maxamount 500;
		ammo.backpackamount 200;
		ammo.backpackmaxamount 500;
		xscale 0.3;
		yscale 0.24;
	}
	states	{
	spawn:
		AMFU B -1;
		stop;
	}
}


Class PK_BoltAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_BOLTAMMO";
		inventory.pickupsound "pickups/ammo/bolts";
		inventory.icon "pkhbolts";
		inventory.amount 25;
		inventory.maxamount 500;
		ammo.backpackamount 50;
		ammo.backpackmaxamount 500;
		xscale 0.4;
		yscale 0.3;
	}
	states	{
	spawn:
		AMBO A -1;
		stop;
	}
}

Class PK_BombAmmo : Ammo {
	Default {
		inventory.pickupmessage "$PKI_HEATERAMMO";
		inventory.pickupsound "pickups/ammo/bombs";
		inventory.icon "pkhbombs";
		inventory.amount 40;
		inventory.maxamount 250;
		ammo.backpackamount 80;
		ammo.backpackmaxamount 250;
		xscale 0.5;
		yscale 0.42;
	}
	states	{
	spawn:
		AMBM B -1;
		stop;
	}
}

/////////////////////////
// AMMO SPAWN CONTROL
/////////////////////////

/*	This object is designed to replace each ammo pickup and spawn 
	either primary or alternative ammo for one of 2 weapons.
	With a small chance it'll also spawn alternative ammo
	next to the primary (that is currently disabled)
*/

Class PK_EquipmentSpawner : Inventory {
	Class<Ammo> primary1; //primary ammo type for the 1st weapon
	Class<Ammo> secondary1; //secondary ammo type for the 1st weapon
	Class<Ammo> primary2; //primary ammo type for the 2nd weapon
	Class<Ammo> secondary2; //secondary ammo type for the 2nd weapon
	Class<Weapon> weapon1; //1st weapon class to spawn ammo for
	property weapon1 : weapon1;
	Class<Weapon> weapon2; //2nd weapon class to spawn ammo for
	property weapon2 : weapon2;
	double altSetChance; //chance of spawning ammo for weapon2 instead of weapon1
	double secondaryChance; //chance of spawning ammotype2 instead of ammotype1
	double secondaryChance2; //chance of spawning ammotype2 instead of ammotype1 for weapon2 (optional)
	double twoPickupsChance;	//chance of spawning the second ammotype next to the one chosen to be spawned
	double dropChance; //chance that this will be obtainable if dropped by an enemy
	property altSetChance : altSetChance;
	property secondaryChance : secondaryChance;
	property secondaryChance2 : secondaryChance2;
	property twoPickupsChance : twoPickupsChance;
	property dropChance : dropChance;
	
	static const class<Weapon> pkWeapons[] = {
		"PK_Painkiller",
		"PK_Shotgun",
		"PK_Stakegun",
		"PK_Boltgun",
		"PK_Chaingun",
		"PK_Rifle",
		"PK_ElectroDriver"
	};
	
	Default {
		+NOBLOCKMAP
		-SPECIAL
		//+INVENTORY.NEVERRESPAWN
		PK_EquipmentSpawner.altSetChance 50;
		PK_EquipmentSpawner.secondaryChance 35;
		PK_EquipmentSpawner.twoPickupsChance 25;
		PK_EquipmentSpawner.dropChance 50;
	}
	
	void SpawnInvPickup(vector3 spawnpos, Class<Inventory> ammopickup) {
		let am = Inventory(Spawn(ammopickup,spawnpos));
		if (am) {
			am.vel = vel;
			if (bTOSSED) {
				am.bTOSSED = true;
				am.amount = Clamp(am.amount / 2, 1, am.amount);
				//console.printf("Spawner bTOSSED: %d | ammo bTOSSED: %d",bTOSSED,am.bTOSSED);
			}
			//this is important to make sure that the weapon that wasn't dropped doesn't get DROPPED flag (and this can't be crushed by moving ceilings)
			else
				am.bDROPPED = false;
		}		
	}
	
	const ammoSpawnOfs = 16;
	static const double AmmoSpawnPos[] = {
		ammoSpawnOfs,
		-ammoSpawnOfs,
		-ammoSpawnOfs,
		ammoSpawnOfs,
		ammoSpawnOfs
	};	
	
	vector3 FindSpawnPosition() {
		vector3 spawnpos = (0,0,0);
		for (int i = 0; i < AmmoSpawnPos.Size()-1; i++) {
			let ppos = pos + (AmmoSpawnPos[i],AmmoSpawnPos[i+1],pos.z);
			//Spawn("AmmoPosTest",ppos);
			if (!Level.IsPointInLevel(ppos))
				continue;
			sector psector = Level.PointInSector(ppos.xy);
			if (curSector && curSector == psector) {
				spawnpos = ppos;
				break;
			}
			double ofsFloor = psector.NextLowestFloorAt(ppos.x,ppos.y,ppos.z);
			if (abs(floorz - ofsFloor) <= 16) {
				spawnpos = (ppos.xy,ofsFloor);
				break;
			}
		}
		return spawnpos;
	}
	
	//returns true if any of the weapons have the weapon, or if the weapon exists on the current map:
	bool CheckExistingWeapons(Class<Weapon> checkWeapon) {
		//check players' inventories:
		if (PK_MainHandler.CheckPlayersHave(checkWeapon))
			return true;
		//check the array that contains all spawned weapon classes:
		PK_ReplacementHandler handler = PK_ReplacementHandler(EventHandler.Find("PK_ReplacementHandler"));
		if (handler && handler.mapweapons.Find(checkWeapon) != handler.mapweapons.Size())
			return true;
		return false;
	}
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		//weapon1 is obligatory; if for whatever reason it's empty, Destroy it:
		if (!weapon1) {
			Destroy();
			return;
		}	
		if (bTOSSED && dropChance < frandom[ammoSpawn](1,100)) {
			Destroy();
			return;
		}
		//get ammo classes for weapon1 and weapon2:
		primary1 = GetDefaultByType(weapon1).ammotype1;
		secondary1 = GetDefaultByType(weapon1).ammotype2;
		if (weapon2) {
			primary2 = GetDefaultByType(weapon2).ammotype1;
			secondary2 = GetDefaultByType(weapon2).ammotype2;	
			//if none of the players have weapon1 and it doesn't exist on the map, increase the chance of spawning ammo for weapon2:
			if (!CheckExistingWeapons(weapon1))
				altSetChance *= 1.5;
			//if none of the players have weapon2 and it doesn't exist on the map, decreate the chance of spawning ammo for weapon2:
			if (!CheckExistingWeapons(weapon2))
				altSetChance /= 1.5;
			//if players have neither, both calculations will happen, ultimately leaving the chance unchanged!
			if (pk_debugmessages > 1)
				console.printf("alt set chance: %f",altSetChance);
		}
		//define two possible ammo pickups to spawn:
		class<Ammo> ammo1toSpawn = primary1;
		class<Ammo> ammo2toSpawn = secondary1;
		//with a chance they'll be replaced with ammo for weapon2:
		if (weapon2 && altSetChance >= frandom[ammoSpawn](1,100)) {
			ammo1toSpawn = primary2;
			ammo2toSpawn = secondary2;
			if (secondaryChance2)
				secondaryChance = secondaryChance2;
		}
		//ammo dropped by enemies should almost always be primary:
		if (bTOSSED) {
			// If secondaryChance is set above 100, make this an exception
			// (used by Minigun/RocketLauncher to disable rocket spawning
			// from clips):
			if (secondaryChance <= 100)
				secondaryChance *= 0.25;
		}
		//finally, decide whether we need to spawn primary or secondary ammo:
		class<Ammo> tospawn = (secondaryChance >= frandom[ammoSpawn](1,100)) ? ammo2toSpawn : ammo1toSpawn;
		SpawnInvPickup(pos,tospawn);
		//console.printf("Spawning %s at %d,%d,%d",tospawn.GetClassName(),pos.x,pos.y,pos.z);
		//if the chance for two pickups is high enough, spawn the other type of ammo:
		/*if (twoPickupsChance >= frandom[ammoSpawn](1,100)) {
			class<Ammo> tospawn2 = (tospawn == ammo1toSpawn) ? ammo2toSpawn : ammo1toSpawn;
			let spawnpos = FindSpawnPosition();
			//console.printf("Spawning %s at %d,%d,%d",tospawn2.GetClassName(),spawnpos.x	,spawnpos.y,spawnpos.z);
			if (spawnpos != (0,0,0))
				SpawnInvPickup(spawnpos,tospawn2);
		}*/
	}

	States {
	Spawn:
		TNT1 A 1;
		stop;
	}
}

Class PK_EquipmentSpawner_Clip : PK_EquipmentSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Rifle";
		PK_EquipmentSpawner.weapon2 "PK_Chaingun";
		PK_EquipmentSpawner.secondaryChance2 101; //clip replacements should never spawn grenades
	}
}

Class PK_EquipmentSpawner_ClipBox : PK_EquipmentSpawner_Clip {
	Default {
		PK_EquipmentSpawner.twoPickupsChance 40;
	}
}

Class PK_EquipmentSpawner_Shell : PK_EquipmentSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Shotgun";
		PK_EquipmentSpawner.secondaryChance 25;
		PK_EquipmentSpawner.weapon2 "PK_Stakegun";
		PK_EquipmentSpawner.secondaryChance2 25;
	}
}

Class PK_EquipmentSpawner_ShellBox : PK_EquipmentSpawner_Shell {
	Default {
		PK_EquipmentSpawner.twoPickupsChance 40;
	}
}

Class PK_EquipmentSpawner_RocketAmmo : PK_EquipmentSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Chaingun";
		PK_EquipmentSpawner.weapon2 "PK_Boltgun";
		PK_EquipmentSpawner.secondaryChance 25; //rocket ammo spawns should provide rockets more commonly thab bullets
	}
}

Class PK_EquipmentSpawner_RocketBox : PK_EquipmentSpawner_RocketAmmo {
	Default {		
		PK_EquipmentSpawner.twoPickupsChance 60;
	}
}

Class PK_EquipmentSpawner_Cell : PK_EquipmentSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_ElectroDriver";
		PK_EquipmentSpawner.weapon2 "PK_Rifle";
		PK_EquipmentSpawner.altSetChance 50;
	}
}

Class PK_EquipmentSpawner_CellPack : PK_EquipmentSpawner_Cell {
	Default {
		PK_EquipmentSpawner.altSetChance 30; //cell packs are usually placed next to BFG, so it should provide Electrodriver ammo more commonly
		PK_EquipmentSpawner.twoPickupsChance 60;
	}
}

/*	This special spawner is meant to replace Stimpack/Medikit
	(since the player is supposed to heal with enemy souls)
	and will randomly spawn any ammo for any weapon the player has.
*/

Class PK_AmmoSpawner_RandomAmmo : PK_EquipmentSpawner {
	override void PostBeginPlay() {
		//this will hold all weapons that at least one player has:
		array < Class<Weapon> > wweapons;
		//iterate over a static array of all weapon classes in the mod (see pk_items.zs):
		for (int i = 0; i < PK_EquipmentSpawner.pkWeapons.Size(); i++) {
			Class<Weapon> weap = PK_EquipmentSpawner.pkWeapons[i];
			// if at least one player has that weapon class or it 
			// exists on a map, and that weapon uses ammo, push it 
			// in the wweapons array:
			if (
				weap && 
				GetDefaultByType(weap).ammotype1 && 
				GetDefaultByType(weap).ammotype2 && 
				(CheckExistingWeapons(weap)) && 
				wweapons.Find(weap) == wweapons.Size()
			)
				wweapons.Push(weap);
		}
		
		//if the array size is zero (no ammo-using weapons in the inventory OR on the map), destroy this:
		if (wweapons.Size() <= 0) {
			Destroy();
			return;
		}
		
		//randomly choose a weapon to spawn ammo for:
		int toSpawn = random[ammoSpawn](0,wweapons.Size() - 1);
		if (!wweapons[tospawn]) {
			Destroy();
			return;
		}
		
		weapon1 = wweapons[tospawn];
		super.PostBeginPlay();
	}
}


/////////////////////////
// WEAPON PICKUPS
/////////////////////////

/*	This is a weapon spawner. Even though the total number of weapons in Painkiller
	is the same as in Doom, their power tiers are rather different, and some weapons
	are more similar to each other (e.g. Chaingun and Rifle).
	As such, each of Doom's weapons can be replaced with 1 of 2 possible Painkiller 
	weapons. The spawner checks which weapons are present in players' inventories AND 
	on the map, then decides which weapon to spawn.
	The spawning is staggered by 1 tic, so that it can first push the desired weapon
	into a global array, and then check if that weapon is already present in the array
	and spawn the other one, if necessary (so that we can get different PK weapons
	in case there are multiple identical Doom pickups).
*/

Class PK_BaseWeaponSpawner : PK_EquipmentSpawner {
	Class<Inventory> toSpawn;
	PK_ReplacementHandler rhandler;
	bool stagger; //if true, delay spawning by 1 tic to first check how many weapons of the same class are on the map
	Default {
		PK_EquipmentSpawner.secondaryChance 50;
		PK_EquipmentSpawner.dropChance 100;
	}
	override void PostBeginPlay() {
		Actor.PostBeginPlay();
		if (!weapon1) {
			return;
		}
		// First round only checks the players' inventories to determine what to spawn
		
		tospawn = weapon1;
		//check if players have weapon1 and weapon2 or those exist on the map:
		bool have1 = (PK_MainHandler.CheckPlayersHave(weapon1));
		bool have2 = weapon2 && (PK_MainHandler.CheckPlayersHave(weapon2));
		if (weapon2) {
			//if none of the players have weapon1, it should always spawn:
			if (!have1)
				secondaryChance -= 50;
			//otherwise, if none of the players have weapon2, that should always spawn:
			else if (!have2)
				secondaryChance += 50;
			//(if players have both weapons, secondaryChance is unchanged by this point)
			//set to spawn weapon2 if check passed:
			if (secondaryChance >= frandom[ammoSpawn](1,100))
				tospawn = weapon2;
		}
		//if weapon2 is true and the item was NOT dropped, stagger spawning:
		if (weapon2 && !bTOSSED) {
			stagger = true;
		}
		if (pk_debugmessages > 1) {
			string phave1 = have1 ? "have" : "don't have";
			string phave2 = have2 ? "have" : "don't have";	
			string wclass1 = weapon1.GetClassName();
			string wclass2 = "weapon2 (not defined)";
			if (weapon2) wclass2 = weapon2.GetClassName();
			string dr = bTOSSED ? "It was dropped." : "It was placed on the map.";
			console.printf("Players %s %s | Players %s %s | Secondary chance: %d, spawning %s. %s",phave1,wclass1,phave2,wclass2,secondaryChance,tospawn.GetClassName(),dr);
		}
		/* 
		If it was  dropped by an enemy and ALL players have the chosen weapon, 
		drop ammo instead 
		(this is mainly because weapons, being 3D and all, look very "prominent"
		and I just don't want many of them to exist on the map at once)
		*/
		if (bTOSSED && PK_MainHandler.CheckPlayersHave(tospawn, true)) {
			//simply randomly pick primary or secondary ammo:
			Class<Weapon> weap = (Class<Weapon>)(tospawn);			
			Class<Ammo> amToSpawn = null;
			if (weap)
				amToSpawn = (random[ammoSpawn](0,1) == 1) ? GetDefaultByType(weap).ammotype1 :GetDefaultByType(weap).ammotype2;
			if (amToSpawn)
				tospawn = amToSpawn;
		}		
		if (!stagger) {
			SpawnInvPickup(pos,tospawn);
			Destroy();
			return;
		}
		/*if we stagger spawning, push the desired weapon into array
		  of all weapons on the map instead of spawning directly:
		*/
		else {
			rhandler = PK_ReplacementHandler(EventHandler.Find("PK_ReplacementHandler"));	
			rhandler.mapweapons.Push((class<Weapon>)(toSpawn));
		}
	}
	States {
	Spawn:
		TNT1 A 1;
		TNT1 A 0 {
			/*	Iterate through the array of the weapon classes that
				have been spawned on the map. If there are at least 2
				weapons of the chosen class in the array, simply spawn
				the other weapon instead:
			*/
			Class<Inventory> toSpawnFinal = (toSpawn == weapon2) ? weapon1 : weapon2;
			int wcount;
			for (int i = 0; i < rhandler.mapweapons.Size(); i++) {
				if (rhandler.mapweapons[i] && rhandler.mapweapons[i] == toSpawn) {
					wcount++;
					if (wcount >= 3) {
						break;
					}
				}
			}
			//if there are 3 or more weapons of this class, spawn primary or secondary randomly:
			if (wcount >= 3 && random[ammoSpawn](0,1) == 1)
				toSpawnFinal = toSpawn;
			//if there's only current weapon, spawn it:
			else if (wcount <= 1)
				toSpawnFinal = toSpawn;
			if (pk_debugmessages > 1)
				Console.PrintF("There are at least %d instaces of %s on this map. Spawning %s",wcount,toSpawn.GetClassName(),toSpawnFinal.GetClassName());
			SpawnInvPickup(pos,toSpawnFinal);
		}
		stop;
	}
}

Class PK_BaseWeaponSpawner_Chainsaw : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Shotgun";
	}
}

Class PK_BaseWeaponSpawner_Shotgun : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Shotgun";
		PK_EquipmentSpawner.weapon2 "PK_Stakegun";
	}
}

Class PK_BaseWeaponSpawner_SuperShotgun : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Stakegun";
		PK_EquipmentSpawner.weapon2 "PK_Boltgun";
	}
}

Class PK_BaseWeaponSpawner_Chaingun : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Chaingun";
		PK_EquipmentSpawner.weapon2 "PK_Rifle";
	}
}

Class PK_BaseWeaponSpawner_RocketLauncher : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Chaingun";
		PK_EquipmentSpawner.weapon2 "PK_Boltgun";
	}
}

Class PK_BaseWeaponSpawner_PlasmaRifle : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_Rifle";
		PK_EquipmentSpawner.weapon2 "PK_ElectroDriver";
	}
}

Class PK_BaseWeaponSpawner_BFG9000 : PK_BaseWeaponSpawner {
	Default {
		PK_EquipmentSpawner.weapon1 "PK_ElectroDriver";
		PK_EquipmentSpawner.weapon2 "PK_Rifle";
	}
}