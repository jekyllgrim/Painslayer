Class PK_DeathHandler : EventHandler {
	override void WorldThingDied(worldevent e) {
		if (!e.thing || !e.thing.bISMONSTER)
			return;
		actor c = Actor.Spawn("PK_EnemyDeathControl",e.thing.pos);
		if (c)
			c.master = e.thing;
	}
	
	array <Actor> demontargets;
	override void WorldThingspawned (worldevent e) {
		if (!e.thing)
			return;
		if (e.thing.bISMONSTER || e.thing.bMISSILE || (e.thing is "PlayerPawn")) {
			demontargets.push(e.thing);
		}
		if ((e.thing is "PlayerPawn") && !e.thing.FindInventory("PK_DemonMorphControl"))
			e.thing.GiveInventory("PK_DemonMorphControl",1);
	}
	
	override void WorldTick() {
		if (players[consoleplayer].mo.FindInventory("PK_DemonWeapon"))
			Shader.SetEnabled( players[consoleplayer], "DemonMorph", true);
		else
			Shader.SetEnabled( players[consoleplayer], "DemonMorph", false);
		PK_DemonWeapon weap;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo player	= players[pn];
			PlayerPawn mo		= player.mo;
			if (!player || !mo)
				continue;
			weap = PK_DemonWeapon(mo.FindInventory("PK_DemonWeapon"));
			if (weap)
				break;
		}
		if (weap) {
			for (int i = 0; i < demontargets.Size(); i++) {
				if (demontargets[i] && !(demontargets[i].FindInventory("PK_SlowMoControl")) && !(demontargets[i].FindInventory("PK_DemonWeapon")))
					demontargets[i].GiveInventory("PK_SlowMoControl",1);
			}
		}
		else {
			for (int i = 0; i < demontargets.Size(); i++) {
				if (demontargets[i])
					demontargets[i].TakeInventory("PK_SlowMoControl",1);
			}
		}
	}
}

Class PK_ReplacementHandler : EventHandler {
	override void CheckReplacement (ReplaceEvent e) {
		switch (e.Replacee.GetClassName()) {
			case 'Chainsaw' 		: e.Replacement = 'PK_MegaSoul'; 			break;
			case 'Shotgun'			: e.Replacement = 'PK_Shotgun'; 			break;
			case 'SuperShotgun' 	: e.Replacement = 'PK_StakeGun';			break;
			case 'Chaingun' 		: e.Replacement = 'PK_Chaingun'; 			break;
			case 'RocketLauncher'	: e.Replacement = 'PK_Chaingun'; 			break;
			case 'PlasmaRifle' 	: e.Replacement = 'PK_Electrodriver';		break;
			case 'BFG9000' 		: e.Replacement = 'PK_Electrodriver';		break;
			
			case 'Shell' 			: e.Replacement = (frandom[ammo](1,10) > 7.5) ? 	'PK_FreezerAmmo' : 'PK_Shells';		break;
			case 'ShellBox' 		: e.Replacement = (frandom[ammo](1,10) > 7) ? 	'PK_Shells' : 'PK_FreezerAmmo';		break;
			case 'ShellBox' 		: e.Replacement = (frandom[ammo](1,10) > 7) ? 	'PK_Shells' : 'PK_FreezerAmmo';		break;
			case 'RocketAmmo' 		: e.Replacement = 'PK_Bombs';		break;
			case 'RocketBox' 		: e.Replacement = 'PK_Bombs';		break;
			case 'Clip' 			: e.Replacement = (frandom[ammo](1,10) > 6) ? 	'PK_Shells' : 'PK_Bullets';			break;
			case 'Cell' 			: e.Replacement = (frandom[ammo](1,10) > 7.5) ? 	'PK_Battery': 'PK_ShurikenAmmo';		break;
			case 'CellBox' 		: e.Replacement = (frandom[ammo](1,10) > 7) ? 	'PK_ShurikenAmmo' : 'PK_Battery';	break;
			case 'Stimpack' 		: e.Replacement = 'PK_Stakes';	break;
			case 'Medikit' 		: e.Replacement = 'PK_Stakes';	break;
			
			case 'SoulSphere' 		: e.Replacement = 'PK_GoldSoul';	break;
			case 'MegaSphere' 		: e.Replacement = 'PK_MegaSoul';	break;
		}
		e.IsFinal = true;
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
	}
}