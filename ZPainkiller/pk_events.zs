Class PK_MainHandler : EventHandler {	
	override void RenderOverlay(renderEvent e) {
		PlayerInfo plr = players[consoleplayer];
		if (plr && plr.readyweapon is "PK_Boltgun") {			
			let camTex = TexMan.CheckForTexture("Weapon.camtex", TexMan.Type_Any);
			if (camTex.IsValid())
			{
				Screen.DrawTexture(camTex, false, 0.0, 0.0, DTA_Alpha, 0.0);
			}
		}
	}
	
	array <Actor> demontargets; //holds all monsters, players and enemy projectiles
	array <Actor> allenemies; //only monsters
	array <Actor> allbosses; //only boss monsters
	array <PK_StakeProjectile> stakes; //stake projectiles
	array <Inventory> keyitems; //pre-placed weapons and keys, to be displayed when the player picks up a Crystal Ball
	array <PK_GoldContainer> goldcontainers;
	
	//By default returns true if ANY of the players has the item.
	//If 'checkall' argument is true, the function returns true if ALL players have the item.
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
	
	static bool IsVoodooDoll(PlayerPawn mo) {
		return !mo.player || !mo.player.mo || mo.player.mo != mo;
	}
	
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
	
	
	void SpawnMapMarkers(PlayerInfo player) {
		if (!player || player != players[consoleplayer])
			return;
		for (int i = 0; i < keyitems.Size(); i++) {
			let itm = keyitems[i];
			if (!itm) continue;
			if (!itm.SpawnState || !itm.SpawnState.sprite) continue;
			let state = itm.SpawnState;
			let targetsprite = state.sprite;
			let spritename = TexMan.GetName(state.GetSpriteTexture(0));
			if (pk_debugmessages > 1)
				console.printf("Spawning map marker for %s. Sprite name: %s",itm.GetClassName(),spritename);
			if (targetsprite && spritename != 'TNT1A0') {
				let marker = Actor.Spawn("PK_SafeMapMarker",itm.pos);			
				if (marker) {
					marker.A_SetScale(itm is "PKWeapon" ? 0.5 : 1.0);
					marker.sprite = targetsprite;
					marker.frame = state.frame;
				}
			}
		}
	}
	
	//different messages for PKGOLD cheat:
	static const string PKCH_GoldMessage[] = {
		"$PKCH_GIVEGOLD1",
		"$PKCH_GIVEGOLD2",
		"$PKCH_GIVEGOLD3",
		"$PKCH_GIVEGOLD4",
		"$PKCH_GIVEGOLD5",
		"$PKCH_TAKEGOLD1",
		"$PKCH_TAKEGOLD2"
	};
	//tarot card-related events:
	override void NetworkProcess(consoleevent e) {
		if (!e.isManual)
			return;
		let plr = players[e.Player].mo;
		if (!plr)
			return;
		let cardcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!cardcontrol)
			return;
		//open black tarot board
		if (e.name == "PKCOpenBoard") {
			if (pk_debugmessages)
				console.printf("Trying to open board");
			if (skill < 1) {
				if (e.player == consoleplayer) {
					plr.A_StartSound("ui/board/wrongplace",CH_PKUI,CHANF_UI|CHANF_LOCAL);
					string str = Stringtable.Localize("$TAROT_LOWSKILL");
					console.printf("%s",str);
				}
				return;
			}
			if (cardcontrol.goldActive || plr.health <= 0 || plr.FindInventory("PK_DemonWeapon")) {
				if (e.player == consoleplayer) {
					plr.A_StartSound("ui/board/wrongplace",CH_PKUI,CHANF_UI|CHANF_LOCAL);
					if (pk_debugmessages)
						console.printf("Can't open the board at this time");
				}
				if (pk_debugmessages)
					console.printf("skill: %d | health: %d | goldActive: %d | has demon weapon: %d",skill,cardcontrol.goldActive,plr.health,plr.CountInv("PK_DemonWeapon"));
				return;
			}
			Menu.SetMenu("PKCardsMenu");
		}
		if (e.name == "PKCOpenCodex") {
			Menu.SetMenu("PKCodexMenu");
		}
		if (e.name == "PK_UseGoldenCards") {
			cardcontrol.UseGoldenCards();
		}
		//CHEATS:
		if (CheckCheatMode())
			return;
		//PKGOLD cheat (gives or takes gold)
		if (e.name == "PK_GiveGold") {
			//gives a specified number of gold, or max gold if no number is specified:
			int amt = (e.args[0] == 0) ? 99990 : e.args[0];
			cardcontrol.pk_gold = Clamp(cardcontrol.pk_gold + amt, 0, 99990);
			if (e.player == consoleplayer) {				
				string str = (amt > 0) ? Stringtable.Localize(PKCH_GoldMessage[random(0,3)]) : Stringtable.Localize(PKCH_GoldMessage[random(4,5)]);
				console.printf(str);
				S_StartSound("pickups/gold/vbig",CH_PKUI,CHANF_UI|CHANF_LOCAL);
			}
		}
		//PKREFRESH cheat (reset golden card uses)
		if (e.name == "PK_RefreshCards") {		
			cardcontrol.RefreshCards();
		}
		if (e.name == "PK_GiveSouls") {
			int amt = (e.args[0] == 0) ? 1 : e.args[0];
			let dmc = PK_DemonMorphControl(plr.FindInventory("PK_DemonMorphControl"));
			if (dmc)
				dmc.GiveSoul(amt);
		}
		//PKDEMON cheat (toggles demon morph instantly)
		if (e.name == "PK_DemonMorph") {
			let dmc = PK_DemonMorphControl(plr.FindInventory("PK_DemonMorphControl"));
			if (plr.FindInventory("PK_DemonWeapon")) {
				plr.A_TakeInventory("PK_DemonWeapon");
				if (dmc)
					dmc.GiveSoul(-66);
			}
			else if (dmc) {
				dmc.GiveSoul(66);
			}
		}
	}
	
	//returns the size of a sector:
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
		if (level.Mapname == "TITLEMAP")
			return;
		let it = ThinkerIterator.Create("PK_PickupsTracker", Thinker.STAT_STATIC);
		let tracker = PK_PickupsTracker(it.Next());
		if (!tracker) {
			if (pk_debugmessages)
				console.printf("Item track Thinker created");
			new("PK_PickupsTracker").Init();
		}
		if (e.IsSaveGame || e.isReopen)
			return;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo)
				continue;
			let cardcontrol = PK_CardControl(plr.mo.FindInventory("PK_CardControl"));
			if (cardcontrol) {
				cardcontrol.RefreshCards();
				if (pk_debugmessages)
					console.printf("New map start: Refreshing cards for player %d. Gold Uses left: %d",pn,cardcontrol.goldUses);
			}
		}		
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
			
			//spawn big gold:
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
				goldpickup.bCOUNTITEM = true;
				//console.printf("goldpickup bDROPPED: %d",goldpickup.bDROPPED);
			}
			//spawn some extra small gold:
			for (int i = random[moregold](1,4); i > 0; i--) {
				actor goldPickup = actor.Spawn("PK_SmallGold",cCenter);
				goldPickup.VelFromAngle(frandom[gold](4,8),random[gold](0,359));
			}
			//throw in some coins too:
			for (int i = random[moregold](5,20); i > 0; i--) {
				actor goldPickup = actor.Spawn("PK_GoldCoin",cCenter+(0,0,4));
				goldpickup.bMISSILE = false;
				goldPickup.VelFromAngle(frandom[gold](1,5),random[gold](0,359));
				goldpickup.SetStateLabel("Death");
			}
		}
	}
	
	override void WorldThingspawned (worldevent e) {
		if (level.Mapname == "TITLEMAP")
			return;
		let act = e.thing;		
		if (!act)
			return;
		if (act is "PK_GoldContainer") {
			goldcontainers.Push(PK_GoldContainer(act));
		}
		if (act is "Inventory") {
			let foo = Inventory(act);
			if (foo && (foo is  "Key" || (foo is "Weapon" && !foo.bTOSSED)))
				keyitems.Push(foo);
		}
		//record all stake projectiles that exist in the world (see PK_StakeStickHandler)
		if (act is "PK_StakeProjectile") {
			let stake = PK_StakeProjectile(act);
			if (stake) {
				stakes.Push(stake);
			}
		}
		/*if (act.player && IsVoodooDoll(PlayerPawn(act))) {
			console.printf("actor at %f,%f,%f is a voodoo doll",act.pos.x,act.pos.y,act.pos.z);
		}*/
		//this is only used by the HUD compass:
		if (act.bISMONSTER && !act.bFRIENDLY) {
			allenemies.push(act);
			if (act.bBOSS)
				allbosses.Push(act);
		}
		//monsters, projectiles and players can be subjected to various effects, such as Demon Morph or Haste, so put them in an array:
		if (act.bISMONSTER || act.bMISSILE || (act.player && !IsVoodooDoll(PlayerPawn(act)))) {
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
		if (act.bISMONSTER && !act.bFRIENDLY) {
			allenemies.push(act);
			if (act.bBOSS)
				allbosses.Push(act);
		}
	}
	//spawn death effects on monster death and also delete them from the monster array
	override void WorldThingDied(worldevent e) {
		let act = e.thing;
		if (!act || !act.bISMONSTER)
			return;		
		allenemies.delete(allenemies.Find(act));
		if (act.bBOSS)
			allbosses.delete(allbosses.Find(act));
		let edc = PK_EnemyDeathControl(Actor.Spawn("PK_EnemyDeathControl",act.pos));
		if (edc)
			edc.master = act;
		//spawn some gold from the corpse:
		int goldchance = 0;//random[gold](0,3);
		int mh = abs(act.health);
		//increase chance of gold if the monster was gibbed:
		bool gibbed = (mh >= act.SpawnHealth() || (act.gibhealth > 0 && mh >= act.gibhealth));
		if (gibbed)
			goldchance = Clamp(goldchance * 3,3,10);
		double zofs = act.default.height;
		for (int i = goldchance; i > 0; i--) {
			let gg = Actor.Spawn("PK_GoldCoin",act.pos + (0,0,zofs*frandom[gold](0.8,1.2)));
			if (gg)
				gg.vel = (frandom[goldchance](-3,3),frandom[goldchance](-3,3),frandom[goldchance](2,5));
		}
		if (gibbed) {
			let gg = Actor.Spawn("PK_MedGold",act.pos + (0,0,zofs*frandom[gold](0.8,1.2)));
			if (gg)
				gg.vel = (frandom[goldchance](-2,2),frandom[goldchance](-2,2),frandom[goldchance](1,4));
		}
	}
	override void WorldThingDestroyed(WorldEvent e) {
		let act = e.thing;
		if (act && demontargets.Find(act)) {
			demontargets.delete(demontargets.Find(act));
			allenemies.delete(allenemies.Find(act));
			//console.printf("Deleting %s from demontargets",act.GetClassName());
		}
	}
	
	void GiveStartingPlayerItems(int pnumber) {
		if (!PlayerInGame[pnumber])
			return;
		let plr = players[pnumber].mo;
		if (!plr)
			return;
		//plr.A_StartSound("world/mapstart",CH_PKUI,CHANF_UI|CHANF_LOCAL);
		if  (!plr.FindInventory("PK_DemonMorphControl"))
			plr.GiveInventory("PK_DemonMorphControl",1);
		if  (!plr.FindInventory("PK_CardControl"))
			plr.GiveInventory("PK_CardControl",1);
		if (!plr.FindInventory("PK_InvReplacementControl"))
			plr.GiveInventory("PK_InvReplacementControl",1);
		if (!plr.FindInventory("PK_QoLCatcher"))
			plr.GiveInventory("PK_QoLCatcher",1);
	}
	//players need control items for demon morph, cards and item replacement handling:
	override void PlayerRespawned(PlayerEvent e) {
		GiveStartingPlayerItems(e.PlayerNumber);
	}	
	override void PlayerSpawned(PlayerEvent e) {
		GiveStartingPlayerItems(e.PlayerNumber);
	}
	//open Black Tarot at map start:
	override void PlayerEntered(PlayerEvent e) {
		if (!pk_autoOpenBoard)
			return;
		if (level.Mapname == "TITLEMAP")
			return;
		if (!PlayerInGame[e.PlayerNumber])
			return;
		let plr = players[e.PlayerNumber].mo;
		if (!plr)
			return;
		if (e.PlayerNumber == consoleplayer)
			Menu.SetMenu("PKCardsMenu");
	}
	void StopPlayerGoldenCards(PlayerInfo player) {
		if (!player || !player.mo)
			return;
		let plr = player.mo;		
		let control = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (control) {
			control.StopGoldenCards();
			if (pk_debugmessages)
				console.printf("Stopping golden cards for player %d",plr.PlayerNumber());
		}
	}
	void StopPlayerDemonMorph(PlayerInfo player) {
		if (!player || !player.mo)
			return;
		let plr = player.mo;
		let control = PK_DemonMorphControl(plr.FindInventory("PK_DemonMorphControl"));
		if (control) {
			control.ResetSouls();
			if (pk_debugmessages)
				console.printf("Soul count for player %d set to %d",plr.PlayerNumber(),control.GetSouls());
		}
		if (pk_debugmessages)
			console.printf("Removing demon weapon from player %d",plr.PlayerNumber());
		plr.TakeInventory("PK_DemonWeapon",999);
	}
	override void PlayerDied (PlayerEvent e) {
		PlayerInfo player = players[e.PlayerNumber];
		StopPlayerGoldenCards(player);
		if (player) {
			for (int i = 1000; i > 0; i--)
				player.SetPSprite(i,null);
			for (int i = -1000; i < 0; i++)
				player.SetPSprite(i,null);
		}
		player.mo.A_StartSound("world/gameover",CH_PKUI,CHANF_UI|CHANF_LOCAL);
	}
	override void WorldUnloaded (WorldEvent e) {
		if (level.Mapname == "TITLEMAP")
			return;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			StopPlayerGoldenCards(plr);
			StopPlayerDemonMorph(plr);
		}
	}
	//debug function
	/*ui void Test_CheckWeaponInInventory(Class<Weapon> weap, double x, double y) {
		if (!weap)
			return;
		let plr = players[consoleplayer].mo;
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
		let plr = players[consoleplayer].mo;
		let goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		string str = String.Format("Remaining card uses: %d | Total uses: %d",goldcontrol.goldUses,goldcontrol.GetTotalGoldUses());
		Screen.DrawText(bigfont,Font.CR_Green,1800,800,str);
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
}

Class PK_ShaderHandler : StaticEventHandler {
	override void WorldLoaded(WorldEvent e) {
		PlayerInfo plr = players[consoleplayer];
		if (!plr || !plr.mo || plr.mo.FindInventory("PK_DemonWeapon"))
			return;
		Shader.SetEnabled(players[consoleplayer], "DemonMorph", false);
	}
}

/*	When hitting a wall, stakes get attached to a secplane of the sector
	behind the wall, so that if the wall moves (as a door/lift), the stake
	will move with it.
	Since for whatever reason secplane can't be saved into save games,
	and the secplane variable used by stakes has to be transient,
	(see pk_weapons.zs/PK_StakeProjectile), whenever a save is loaded,
	I make all existing dead stakes call their StickToWall() function again
	to make them find the required stickplane AGAIN.
*/
Class PK_StakeStickHandler : StaticEventHandler {
	override void WorldLoaded(WorldEvent e) {
		if (!e.isSaveGame)
			return;
		let handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (!handler)
			return;
		for (int i = 0; i < handler.stakes.Size(); i++) {
			PK_StakeProjectile stake = handler.stakes[i];
			if (!stake)
				continue;
			if (!stake.stuckToSecPlane)
				continue;
			stake.StickToWall();
		}
	}
}

//weapon and item replacements
Class PK_ReplacementHandler : EventHandler {
	//array <Weapon> mapweapons;
	array < Class<Weapon> > mapweapons;
	override void CheckReplacement (ReplaceEvent e) {
		switch (e.Replacee.GetClassName()) {
			case 'Chainsaw' 		: e.Replacement = 'PK_BaseWeaponSpawner_Chainsaw'; 			break;
			case 'Pistol' 			: e.Replacement = 'PK_Painkiller'; 			break;
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
			case 'HealthBonus' 	: 
				if (random[propspawn](1,10) > 9)
					e.Replacement = 'PK_BreakableChest';
				else
					e.Replacement = 'PK_NullActor';
				break;
			case 'ArmorBonus' 		: 
				//if (random[propspawn](1,10) > 8)
					e.Replacement = 'PK_BronzeArmor';
				//else
					//e.Replacement = 'PK_NullActor';
				break;			
			case 'SoulSphere' 		: e.Replacement = 'PK_GoldSoul';	break;
			case 'MegaSphere' 		: e.Replacement = 'PK_MegaSoul';	break;
			case 'BlurSphere' 		: e.Replacement = 'PK_ChestOfSouls';	break;
			case 'GreenArmor' 		: e.Replacement = 'PK_SilverArmor';	break;
			Case 'BlueArmor'		: e.Replacement = 'PK_GoldArmor'; break;
			
			case 'Berserk'			: e.Replacement = 'PK_WeaponModifierGiver';  break;
			case 'Infrared'		: e.Replacement = 'PK_DemonEyes';  break;
			case 'AllMap'			: e.Replacement = 'PK_AllMap';  break;
			case 'InvulnerabilitySphere'		: e.Replacement = 'PK_Pentagram';  break;
			case 'Backpack'		: e.Replacement = 'PK_AmmoPack';  break;
			case 'RadSuit'			: e.Replacement = 'PK_AntiRadArmor';  break;
			
			case 'ExplosiveBarrel': e.Replacement = 'PK_ExplosiveBarrel';  break;
			
			case 'DeadCacodemon'	: e.Replacement = 'PK_BreakableChest'; break;
			case 'DeadDemon'	: e.Replacement = 'PK_BreakableChest'; break;
			case 'DeadDoomImp'	: e.Replacement = 'PK_BreakableChest'; break;
			case 'DeadLostSoul'	: e.Replacement = 'PK_BreakableChest'; break;
			case 'DeadShotgunGuy'	: e.Replacement = 'PK_BreakableChest'; break;
			case 'DeadZombieMan'	: e.Replacement = 'PK_BreakableChest'; break;
		}
		//e.IsFinal = true;
	}
	
	override void WorldThingSpawned(WorldEvent e) {
		let act = e.thing;
		if (!act || act.GetClass() != "PK_BronzeArmor")
			return;
		double checkdist = 1200;
		let itr = BlockThingsIterator.Create(act, checkdist);
		while (itr.Next()) {
			let arm = PK_BronzeArmor(itr.thing);
			if (arm && arm != act && act.GetClass() == "PK_BronzeArmor" && act.Distance3D(arm) <= checkdist) {
				act.Destroy();
				return;
			}
		}
	}
}

Class PK_BoardEventHandler : EventHandler {
	ui bool boardOpened; //whether the Black Tarot board has been opened on this map
	ui bool CodexOpened;
	bool SoulKeeper;
	
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
		if (e.name == 'PKCCodexOpened') {
			let irc = PK_InvReplacementControl(plr.FindInventory("PK_InvReplacementControl"));
			if (irc) {
				irc.codexOpened = true;
			}
		}
		let cardcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!cardcontrol)
			return;
		//card purchase: push the card into array, reduce current gold
		if (e.name.IndexOf("PKCBuyCard") >= 0) {
			Array <String> cardname;
			e.name.split(cardname, ":");
			if (cardname.Size() != 0) {
				//apparently, dynamic arrays are iffy, that's why we need int(name
				cardcontrol.UnlockedTarotCards.Push(int(name(cardname[1])));
				int cost = e.args[0];
				cardcontrol.pk_gold = Clamp(cardcontrol.pk_gold - cost,0,99990);
				if (pk_debugmessages)
					console.printf("buying card %s at %d",name(cardname[1]),cost);
			}
		}
		if (e.name == 'PKCTakeGold') {
			int cost = e.args[0];
			cardcontrol.pk_gold = Clamp(cardcontrol.pk_gold - cost,0,99990);
		}
		//equip card into a slot
		if (e.name.IndexOf("PKCCardToSlot") >= 0) {
			Array <String> cardname;
			e.name.split(cardname, ":");
			if (cardname.Size() != 0) {
				int slotID = e.args[0];
				cardcontrol.EquippedSlots[slotID] = cardname[1];
			}
		}
		//remove card from slot
		if (e.name == 'PKCClearSlot') {
			int slotID = e.args[0];
			cardcontrol.EquippedSlots[slotID] = '';
		}
		if (e.name == 'PKCCloseBoard') {
			//console.printf("trying to initalize card slots");
			cardcontrol.PK_EquipCards();
		}
	}
}