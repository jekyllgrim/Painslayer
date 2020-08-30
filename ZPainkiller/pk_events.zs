Class PK_MainHandler : EventHandler {
	
	array <Actor> allenemies;
	array <Actor> demontargets;
	
	//converted from source code by 3saster:
    bool CheckCheatmode (bool printmsg = true)
    {
        if ((G_SkillPropertyInt(SKILLP_DisableCheats) || netgame || deathmatch) && (!sv_cheats))
        {
            if (printmsg) console.printf ("sv_cheats must be true to enable this command.");
            return true;
        }
        else if (cl_blockcheats != 0)
        {
            if (printmsg && cl_blockcheats == 1) console.printf("cl_blockcheats is turned on and disabled this command.\n");
            return true;
        }
        else
        {
            return false;
        }
    }
	//cheats:
	static const string PKCH_GoldMessage[] = {
		"$PKCH_GIVEGOLD1",
		"$PKCH_GIVEGOLD2",
		"$PKCH_GIVEGOLD3",
		"$PKCH_GIVEGOLD4",
		"$PKCH_GIVEGOLD5",
		"$PKCH_TAKEGOLD1",
		"$PKCH_TAKEGOLD2"
	};
	override void NetworkProcess(consoleevent e) {
		if (!e.isManual)
			return;
		if (CheckCheatMode())
			return;
		if (e.name == "PK_GiveGold") {
			let plr = players[e.Player].mo;
			if (!plr)
				return;
			if (e.player == consoleplayer) {				
				string str = Stringtable.Localize(PKCH_GoldMessage[random(0,3)]);
				console.printf(str);
				S_StartSound("pickups/gold/vbig",CHAN_AUTO,CHANF_UI);
			}
			//gives a specified number of gold, or max gold if no number is specified:
			int amt = (e.args[0] == 0) ? 99990 : e.args[0];
			let cont = PK_CardControl(plr.FindInventory("PK_CardControl"));
			if (cont) {
				cont.pk_gold = Clamp(cont.pk_gold + amt, 0, 99990);
			}
		}
	}
	Vector2 SectorBounds (Sector sec) {
		Vector2 posMin = ( double.Infinity,  double.Infinity);
		Vector2 posMax = (-double.Infinity, -double.Infinity);

		for (int i = 0; i < sec.lines.Size (); i++) {
			Line l = sec.Lines [i];
			posMin = (
				min (min (posMin.X, l.v1.p.X), l.v2.p.X),
				min (min (posMin.Y, l.v1.p.Y), l.v2.p.Y)
			);
			posMax = (
				max (max (posMax.X, l.v1.p.X), l.v2.p.X),
				max (max (posMax.Y, l.v1.p.Y), l.v2.p.Y)
			);
		}
		return (posMax - posMin);
	}
	//spawn gold randomly in secret areas:
	override void WorldLoaded(WorldEvent e) {
		for (int i = 0; i < level.Sectors.Size(); i++) {
			Sector curSec = level.Sectors[i];

			if (!curSec.IsSecret())	//do nothing if not secret
				continue;
			vector3 cCenter = (curSec.centerspot.x, curSec.centerspot.y, curSec.floorplane.ZAtPoint(curSec.centerspot));
			if (!level.IsPointInLevel(cCenter))	//do nothing if out of bounds
				continue;
			//do nothing if sector height is 0:
			if (curSec.floorplane.ZAtPoint(curSec.centerspot) == curSec.ceilingplane.ZAtPoint(curSec.centerspot))
				continue;
			
			vector2 sectorBB = SectorBounds(curSec); 
			double secSize = (sectorBB.x + sectorBB.y) / 2;
			//console.printf("sector %d size %d",curSec.sectornum,secSize);
			
			if (secsize < 24)
				continue;
			int goldnum = Clamp((secSize / 72),1,7);

			for (int i = goldnum; i > 0; i--) {
				int chance = random[gold](0,100);
				Class<Actor> gold;
				if (chance < 35)
					gold = "PK_MedGold";
				else if (chance < 85)
					gold = "PK_BigGold";
				else
					gold = "PK_VeryBigGold";
				actor goldPickup = actor.Spawn(gold,cCenter);
				if (!goldpickup)
					continue;
				/*BlockThingsIterator itr = BlockThingsIterator.Create(goldPickup,64,0);
				while (itr.Next())	{
					Actor next = itr.thing;					
					if (next is "Inventory")	{	
						goldPickup.VelFromAngle(frandom[gold](4,8),random[gold](0,359));
					}
				}*/
				goldPickup.VelFromAngle(frandom[gold](1,3),random[gold](0,359));
			}
			for (int i = random[moregold](1,4); i > 0; i--) {
				actor goldPickup = actor.Spawn("PK_SmallGold",cCenter);
				goldPickup.VelFromAngle(frandom[gold](4,8),random[gold](0,359));
			}
		}
	}

	override void WorldThingspawned (worldevent e) {
		let act = e.thing;		
		if (!act)
			return;
		if (act.bISMONSTER)
			allenemies.push(act);
		if (act.bISMONSTER || act.bMISSILE || (act.player)) {
			demontargets.push(act);
		}
		if (act.player) {
			if  (!act.FindInventory("PK_DemonMorphControl"))
				act.GiveInventory("PK_DemonMorphControl",1);
			if  (!act.FindInventory("PK_CardControl"))
				act.GiveInventory("PK_CardControl",1);
		}
	}
	override void WorldThingRevived (worldevent e) {
		let act = e.thing;		
		if (!act)
			return;
		if (act.bISMONSTER)
			allenemies.push(act);
		if (act.bISMONSTER || act.bMISSILE || (act.player)) {
			demontargets.push(act);
		}
		if (act.player) {
			if  (!act.FindInventory("PK_DemonMorphControl"))
				act.GiveInventory("PK_DemonMorphControl",1);
			if  (!act.FindInventory("PK_CardControl"))
				act.GiveInventory("PK_CardControl",1);
		}
	}	
	override void WorldThingDied(worldevent e) {
		let act = e.thing;
		if (!act || !act.bISMONSTER)
			return;		
		actor c = Actor.Spawn("PK_EnemyDeathControl",act.pos);
		if (c)
			c.master = act;		

		allenemies.delete(allenemies.Find(e.thing));
		//demontargets.delete(allenemies.Find(e.thing));
	}
	override void WorldThingDestroyed(WorldEvent e) {
		if (e.thing) {
			allenemies.delete(allenemies.Find(e.thing));
			demontargets.delete(allenemies.Find(e.thing));
		}
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