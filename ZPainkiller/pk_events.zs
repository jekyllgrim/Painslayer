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
		if (e.thing.bISMONSTER) {
			allactors.push(e.thing);
			//e.thing.GiveInventory("PK_SlowMoControl",1);
		}
		if ((e.thing is "PlayerPawn") && !e.thing.FindInventory("PK_DemonMorphControl"))
			e.thing.GiveInventory("PK_DemonMorphControl",1);
	}
	
	override void WorldTick() {
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
			for (int i = 0; i < allactors.Size(); i++) {
				if (allactors[i] && !(allactors[i].FindInventory("PK_SlowMoControl")))
					allactors[i].GiveInventory("PK_SlowMoControl",1);
			}
		}
		else {
			for (int i = 0; i < allactors.Size(); i++) {
				if (allactors[i])
					allactors[i].TakeInventory("PK_SlowMoControl",1);
			}
		}
	}
}