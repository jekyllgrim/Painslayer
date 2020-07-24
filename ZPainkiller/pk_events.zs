Class KillerTargetHandler : EventHandler {
	override void WorldThingDied(worldevent e) {
		if (!e.thing || !e.thing.bISMONSTER)
			return;
		actor c = Actor.Spawn("PK_EnemyDeathControl",e.thing.pos);
		if (c)
			c.master = e.thing;
	}
	
	array <Actor> allactors;
	override void WorldThingspawned (worldevent e) {
		if (!e.thing)
			return;
		if (e.thing.bISMONSTER || e.thing.bMISSILE) {
			allactors.push(e.thing);
		}
		if ((e.thing is "PlayerPawn") && !e.thing.FindInventory("PK_DemonMorphControl"))
			e.thing.GiveInventory("PK_DemonMorphControl",1);
	}
	
	static const Class<Weapon> PK_VanillaWeaponsList[] = { 'Fist', 'Chainsaw', 'Pistol', 'Shotgun', 'SuperShotgun', 'Chaingun', 'RocketLauncher', 'PlasmaRifle', 'BFG9000' };
	override void WorldTick() {
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;			
			PlayerInfo player	= players[pn];
			PlayerPawn mo		= player.mo;
			if (!player || !mo)
				continue;			
			for (int i = 0; i < PK_VanillaWeaponsList.Size(); i++) {
				mo.TakeInventory(PK_VanillaWeaponsList[i],1);
			}
			if (!player.readyweapon) {
				//console.printf("no readyweapon");
				if (!mo.FindInventory("PK_Painkiller"))
					mo.GiveInventory("PK_Painkiller",1);
				player.pendingweapon = mo.PickWeapon(1,true);
			}
		}
		
		PK_DemonWeapon weap;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo player	= players[pn];
			PlayerPawn mo		= player.mo;
			if (!player || !mo)
				continue;
			weap = PK_DemonWeapon(mo.FindInventory("PK_DemonWeapon"));
			if (!weap)
				continue;
		}
		if (weap) {
			Shader.SetEnabled( players[consoleplayer], "DemonMode", true);
			for (int i = 0; i < allactors.Size(); i++) {
				if (allactors[i] && !(allactors[i].FindInventory("PK_SlowMoControl")))
					allactors[i].GiveInventory("PK_SlowMoControl",1);
			}
		}
		else {
			Shader.SetEnabled( players[consoleplayer], "DemonMode", false);
			for (int i = 0; i < allactors.Size(); i++) {
				if (allactors[i])
					allactors[i].TakeInventory("PK_SlowMoControl",1);
			}
		}
	}
}