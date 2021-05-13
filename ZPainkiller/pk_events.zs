Class PK_MainHandler : EventHandler {

	/*ui void Test_CheckWeaponInInventory(Class<Weapon> weap, double x, double y) {
		if (!weap)
			return;
		let plr = players[0].mo;
		if (!plr)
			return;
		let wweap = plr.FindInventory(weap);
		bool has = wweap ? true : false;
		int amt = wweap ? wweap.amount : -1;
		string wname = weap.GetClassName();
		if (wweap && wweap.GetTag()) wname = wweap.GetTag();
		double xofs = x;
		Screen.DrawText(bigfont,Font.CR_Red,xofs,y,wname);
		xofs += 240;
		if (has) {
			Screen.DrawText(bigfont,Font.CR_Green,xofs,y," in inventory"); xofs += 144;
			Screen.DrawText(bigfont,Font.CR_White,xofs,y," | amount: "); xofs += 128;
			Screen.DrawText(bigfont,Font.CR_Green,xofs,y,String.Format("%d",amt));
		}
		else
			Screen.DrawText(bigfont,Font.CR_White,xofs,y," none");
	}
	override void RenderOverlay(renderEvent e) {
		if (!pk_debugmessages)	
			return;
		double tx = 2000;
		double ty = 200;
		double parag = 16;
		Test_CheckWeaponInInventory("PK_Painkiller",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Shotgun",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Stakegun",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Boltgun",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Chaingun",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Rifle",tx,ty); ty += parag;
		Test_CheckWeaponInInventory("PK_Electrodriver",tx,ty); ty += parag;
	}*/
	
	array <Actor> demontargets; //holds all monsters, players and enemy projectiles
	array <Actor> allenemies; //only monsters
	
	//converted from source code by 3saster:
	bool CheckCheatmode (bool printmsg = true) {
		if ((G_SkillPropertyInt(SKILLP_DisableCheats) || netgame || deathmatch) && (!sv_cheats)) {
			if (printmsg) console.printf ("sv_cheats must be true to enable this command.");
			return true;
		}
		else if (cl_blockcheats != 0) {
			if (printmsg && cl_blockcheats == 1) console.printf("cl_blockcheats is turned on and disabled this command.\n");
			return true;
		}
		return false;
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
	
	//returns true if ANY of the players has the item
	//(unless checkall is true, then it returns true if ALL have it)
	static bool CheckPlayersHave(Class<Inventory> itm, bool checkall = false) {
		if(!itm)
			return false;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo)
				continue;
			bool found = plr.mo.CountInv(itm);
			if (checkall && !found) {
				if (pk_debugmessages > 1)
					console.printf("Player %d doesn't have %s",plr.mo.PlayerNumber(),itm.GetClassName());
				return false;
				break;
			}
			else if (found) {
				if (pk_debugmessages > 1)
					console.printf("Player %d has %s",plr.mo.PlayerNumber(),itm.GetClassName());
				return true;
				break;
			}
		}
		return false;
	}
	
	//tarot card-related events:
	override void NetworkProcess(consoleevent e) {
		if (!e.isManual)
			return;
		let plr = players[e.Player].mo;
		if (!plr)
			return;
		//open black tarot board
		if (e.name == "PKCOpenBoard") {
			if (pk_debugmessages)
				console.printf("Trying to open board");
			let goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
			if (!goldcontrol)
				return;
			if (goldcontrol.goldActive || plr.health <= 0 || plr.FindInventory("PK_DemonWeapon")) {
				if (e.player == consoleplayer) {
					plr.A_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI|CHANF_LOCAL);
					if (pk_debugmessages)
						console.printf("Can't open the board at this time");
				}
				if (pk_debugmessages)
					console.printf("health: %d | goldActive: %d | has demon weapon: %d",goldcontrol.goldActive,plr.health,plr.CountInv("PK_DemonWeapon"));
				return;
			}
			Menu.SetMenu("PKCardsMenu");
		}
		//PKGOLD cheat (gives or takes gold)
		if (CheckCheatMode())
			return;
		if (e.name == "PK_UseGoldenCards") {
			let cont = PK_CardControl(plr.FindInventory("PK_CardControl"));
			if (cont) {
				cont.PK_UseGoldenCards();
			}
		}
		if (e.name == "PK_GiveGold") {
			//gives a specified number of gold, or max gold if no number is specified:
			int amt = (e.args[0] == 0) ? 99990 : e.args[0];
			let cont = PK_CardControl(plr.FindInventory("PK_CardControl"));
			if (cont) {
				cont.pk_gold = Clamp(cont.pk_gold + amt, 0, 99990);
			}
			if (e.player == consoleplayer) {				
				string str = (amt > 0) ? Stringtable.Localize(PKCH_GoldMessage[random(0,3)]) : Stringtable.Localize(PKCH_GoldMessage[random(4,5)]);
				console.printf(str);
				S_StartSound("pickups/gold/vbig",CHAN_AUTO,CHANF_UI);
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
	
	override void WorldLoaded(WorldEvent e) {
		Shader.SetEnabled(players[consoleplayer], "DemonMorph", false); 
		//spawn gold randomly in secret areas:
		//iterate throguh sectors:
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
			int goldnum = Clamp((secSize / 72.),1,10);

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
				//throw gold around randomly
				goldPickup.VelFromAngle(frandom[gold](1,3),random[gold](0,359));
				//console.printf("goldpickup bDROPPED: %d",goldpickup.bDROPPED);
			}
			for (int i = random[moregold](1,4); i > 0; i--) {
				actor goldPickup = actor.Spawn("PK_SmallGold",cCenter);
				goldPickup.VelFromAngle(frandom[gold](4,8),random[gold](0,359));
			}
		}
	}
	//push stuff into arrays:
	override void WorldThingspawned (worldevent e) {
		let act = e.thing;		
		if (!act)
			return;
		//players need control items for demon morph and cards
		if (act.player) {
			if  (!act.FindInventory("PK_DemonMorphControl"))
				act.GiveInventory("PK_DemonMorphControl",1);
			if  (!act.FindInventory("PK_CardControl"))
				act.GiveInventory("PK_CardControl",1);			
		}
		//this is only used by the HUD compass:
		if (act.bISMONSTER && !act.bFRIENDLY)
			allenemies.push(act);
		//monsters, projectiles and players can be subjected to various effects, such as Demon Morph or Haste, so put them in an array:
		if (act.bISMONSTER || act.bMISSILE || (act is "PlayerPawn")) {
			demontargets.push(act);
			//console.printf("Pushing %s into the demontargets array",act.GetClassName());
			if (CheckPlayersHave("PK_DemonWeapon"))
				act.GiveInventory("PK_DemonTargetControl",1);
			if (CheckPlayersHave("PK_HasteControl"))
				act.GiveInventory("PK_HasteControl",1);
			if (CheckPlayersHave("PK_ConfusionControl"))
				act.GiveInventory("PK_ConfusionControl",1);
		}
	}
	override void WorldThingrevived(worldevent e) {
		let act = e.thing;
		if (!act || !act.bISMONSTER)
			return;		
		allenemies.push(act);
	}		
	//spawn death effects on monster death and also delete them from the monster array
	override void WorldThingDied(worldevent e) {
		let act = e.thing;
		if (!act || !act.bISMONSTER)
			return;		
		allenemies.delete(allenemies.Find(act));
		let edc = PK_EnemyDeathControl(Actor.Spawn("PK_EnemyDeathControl",act.pos));
		if (edc)
			edc.master = act;
	}
	override void WorldThingDestroyed(WorldEvent e) {
		let act = e.thing;
		if (act && demontargets.Find(act)) {
			demontargets.delete(demontargets.Find(act));
			allenemies.delete(allenemies.Find(act));
			//console.printf("Deleting %s from demontargets",act.GetClassName());
		}
	}
}

Class PK_ReplacementHandler : EventHandler {
	array < Class<Weapon> > mapweapons;
	override void CheckReplacement (ReplaceEvent e) {
		switch (e.Replacee.GetClassName()) {
			case 'Chainsaw' 		: e.Replacement = 'PK_BaseWeaponSpawner_Chainsaw'; 			break;
			case 'Shotgun'			: e.Replacement = 'PK_BaseWeaponSpawner_Shotgun'; 			break;
			case 'SuperShotgun' 	: e.Replacement = 'PK_BaseWeaponSpawner_SuperShotgun';			break;
			case 'Chaingun' 		: e.Replacement = 'PK_BaseWeaponSpawner_Chaingun'; 			break;
			case 'RocketLauncher'	: e.Replacement = 'PK_BaseWeaponSpawner_RocketLauncher'; 			break;
			case 'PlasmaRifle' 	: e.Replacement = 'PK_BaseWeaponSpawner_PlasmaRifle';				break;
			case 'BFG9000' 		: e.Replacement = 'PK_BaseWeaponSpawner_BFG9000';		break;
			
			case 'Clip' 			: e.Replacement = 'PK_EquipmentSpawner_Clip';			break;
			case 'ClipBox' 		: e.Replacement = 'PK_EquipmentSpawner_ClipBox';		break;
			case 'Shell' 			: e.Replacement = 'PK_EquipmentSpawner_Shell';		break;
			case 'ShellBox' 		: e.Replacement = 'PK_EquipmentSpawner_ShellBox';		break;
			case 'RocketAmmo' 		: e.Replacement = 'PK_EquipmentSpawner_RocketAmmo';		break;
			case 'RocketBox' 		: e.Replacement = 'PK_EquipmentSpawner_RocketBox';		break;
			case 'Cell' 			: e.Replacement = 'PK_EquipmentSpawner_Cell';		break;
			case 'CellPack' 		: e.Replacement = 'PK_EquipmentSpawner_CellPack';	break;

			case 'Stimpack' 		: e.Replacement = 'PK_AmmoSpawner_Stimpack';	break;
			case 'Medikit' 		: e.Replacement = 'PK_AmmoSpawner_Stimpack';	break;
			
			case 'SoulSphere' 		: e.Replacement = 'PK_GoldSoul';	break;
			case 'MegaSphere' 		: e.Replacement = 'PK_MegaSoul';	break;
			case 'GreenArmor' 		: e.Replacement = (random[repl](1,100) > 60) ? 'PK_SilverArmor' : 'PK_BronzeArmor';	break;
			Case 'BlueArmor'		: e.Replacement = 'PK_GoldArmor'; break;
			
			case 'Berserk'			: e.Replacement = 'PK_WeaponModifier';  break;
		}
		//e.IsFinal = true;
	}
	
	override void WorldThingSpawned(WorldEvent e) {
		if (!e.thing)
			return;
		if (e.thing.player) {
			if (!e.thing.FindInventory("PK_InvReplacementControl"))
				e.thing.GiveInventory("PK_InvReplacementControl",1);
		}
		if (e.thing is "Weapon") {
			Class<Weapon> weap = (Class<Weapon>)(e.thing.GetClass());
			if (weap && mapweapons.Find(weap) != mapweapons.Size())
				mapweapons.Push(e.thing);
		}
	}
}

Class PK_BoardEventHandler : EventHandler {
	ui bool boardOpened; //whether the Black Tarot board has been opened on this map
	ui bool allowOpenBoard; //if false, the board won't open (to block openmenu CCMD, since I only want the menu to be openable with a netevent
	
	bool SoulKeeper;
	array <Ammo> ammopickups;
	
	override void WorldThingSpawned(Worldevent e) {
		if (!e.thing)
			return;		
		/*if (e.thing && e.thing.player && e.thing.FindInventory("PK_CardControl"))
			Menu.SetMenu("PKCardsMenu");*/
		if (e.thing is "Ammo") {
			ammopickups.Push(Ammo(e.thing));
		}
	}
	
	override void WorldThingDamaged(worldevent e) {
		if (!e.thing)
			return;
		let enm = e.thing;
		if (enm.bISMONSTER && e.DamageSource && e.DamageSource.FindInventory("PKC_HealthStealer") && enm.isHostile(e.DamageSource)) {
			if (pk_debugmessages)
				console.printf("%s dealt %d damage to %s",e.DamageSource.GetClassName(),e.damage,enm.GetClassName());
			let card = PKC_HealthStealer(e.DamageSource.FindInventory("PKC_HealthStealer"));
			double drain = e.Damage*0.05;
			if (card)
				card.drainedHP += drain;
		}
		if ((enm.player || enm.bISMONSTER) && 	e.Inflictor && e.Inflictor is "PK_FlamerTank" && e.DamageSource && !enm.FindInventory("PK_BurnControl")) {
			enm.GiveInventory("PK_BurnControl",1);
			let control = enm.FindInventory("PK_BurnControl");
			if (control)
				control.target = e.DamageSource;
		}
	}
	
	override void NetworkProcess(consoleevent e) {
		if (e.isManual || e.Player < 0)
			return;
		let plr = players[e.Player].mo;
		if (!plr)
			return;
		let goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!goldcontrol)
			return;
		//card purchase: push the card into array, reduce current gold
		if (e.name.IndexOf("PKCBuyCard") >= 0) {
			Array <String> cardname;
			e.name.split(cardname, ":");
			if (cardname.Size() == 0)
				return;
			//apparently, dynamic arrays are iffy, that's why we need int(name
			goldcontrol.UnlockedTarotCards.Push(int(name(cardname[1])));
			int cost = e.args[0];
			goldcontrol.pk_gold = Clamp(goldcontrol.pk_gold - cost,0,99990);
		}
		if (e.name == 'PKCTakeGold') {
			int cost = e.args[0];
			goldcontrol.pk_gold = Clamp(goldcontrol.pk_gold - cost,0,99990);
		}
		//equip card into a slot
		if (e.name.IndexOf("PKCCardToSlot") >= 0) {
			Array <String> cardname;
			e.name.split(cardname, ":");
			if (cardname.Size() == 0)
				return;
			int slotID = e.args[0];
			goldcontrol.EquippedSlots[slotID] = cardname[1];
		}
		//remove card from slot
		if (e.name == 'PKCClearSlot') {
			int slotID = e.args[0];
			goldcontrol.EquippedSlots[slotID] = '';
		}
		if (e.name == 'PKCCloseBoard') {
			//console.printf("trying to initalize card slots");
			goldcontrol.PK_EquipCards();
		}
	}
}