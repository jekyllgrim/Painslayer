Class PK_DemonTargetControl : PK_InventoryToken {
	private double p_gravity;
	private double p_speed;
	private vector3 p_vel;
	private int p_renderstyle;
	private double p_alpha;
	private color p_color;
	private state slowstate;
	private double speedfactor;
	private double gravityfactor;
	private PlayerPawn CPlayerPawn;
	property speedfactor : speedfactor;
	property gravityfactor : gravityfactor;
	Default {
		PK_DemonTargetControl.speedfactor 0.85;
		PK_DemonTargetControl.gravityfactor 0.5;
	}
	override void Tick() {}
	override void AttachToOwner(actor other) {
		//only affect missiles, monsters and players:
		if (!other.bISMONSTER && !other.bMISSILE && !(other is "PlayerPawn")) {
			destroy();
			return;
		}
		//do not affect player missiles:
		if (other.bMISSILE && other.target && other.target.player) {
			destroy();
			return;
		}
		super.AttachToOwner(other);
		if (!owner) {
			return;
		}
		CPlayerPawn = players[consoleplayer].mo;
		if (!CPlayerPawn)
			return;
		//record the looks of the actor:
		p_renderstyle = owner.GetRenderstyle();
		p_alpha = owner.alpha;
		p_color = owner.fillcolor;
		//monsters and missiles have their gravity, speed and current vel lowered:
		if (owner.bISMONSTER || owner.bMISSILE) {
			p_gravity = owner.gravity;
			p_speed = owner.speed;
			owner.gravity *= gravityfactor;
			owner.speed *= speedfactor;
			owner.vel *= speedfactor;
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			destroy();
			return;
		}
		//monsters and players are colorized (only for consoleplayer) so that the demon shader can make them red:
		if (owner.bISMONSTER || (owner is "PlayerPawn")) {
			//demo shader requires them to be purple, stencil and fullbright
			if (CPlayerPawn.FindInventory("PK_DemonWeapon")) {
				//console.printf("Modifying %s's appearance",owner.GetClassName());
				owner.bBRIGHT = true;
				owner.A_SetRenderstyle(1.0,Style_Stencil);
				owner.SetShade("ff00ff");
			}			
			else {
				owner.bBRIGHT = owner.default.bBRIGHT;
				owner.A_SetRenderstyle(p_alpha,p_renderstyle);
				owner.SetShade(p_color);
			}
		}
		if (owner.isFrozen())
			return;
		//lowers pitch and reduces speed for non-player actors:
		if (owner.bISMONSTER) {
			for (int i = CH_END; i > 0; i--)
				owner.A_SoundPitch(i,0.9);
			if (owner.CurState != slowstate) {
				owner.A_SetTics(owner.tics*1.5);
				slowstate = Owner.CurState;
			}
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		if (owner.bISMONSTER || owner.bMISSILE) {
			owner.gravity = owner.default.gravity; //p_gravity;
			owner.speed = owner.default.speed; //p_speed;
		}
		//the looks need to be reset here as well, in case the item gets removed from somewhere else before the reset in DoEffect can run:
		owner.bBRIGHT = owner.default.bBRIGHT;
		owner.A_SetRenderstyle(p_alpha,p_renderstyle);
		owner.SetShade(p_color);
		super.DetachFromOwner();
	}
}

Class PK_DemonMorphControl : PK_InventoryToken {
	int pk_souls;
	int pk_minsouls;
	int pk_fullsouls;
	property minsouls : pk_minsouls;
	property fullsouls : pk_fullsouls;
	Default {
		PK_DemonMorphControl.minsouls 64;
		PK_DemonMorphControl.fullsouls 66;
	}
	override void Tick() {}
	/*override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player || !owner.player.readyweapon)
			return;
		console.printf("souls: %d | Demon Weapon: %d",pk_souls,owner.CountInv("PK_DemonWeapon"));
	}*/
}

Class PK_DemonWeapon : PKWeapon {
	private PK_DemonMorphControl control;
	private PK_MainHandler handler;
	private int minsouls;
	private int fullsouls;	
	private int cursouls;	
	private int dur;
	Weapon prevweapon;
	private double p_speed;
	private double p_gravity;	
	private double rippleTimer;
	private bool runRipple;
	Default {
		+WEAPON.NOAUTOFIRE;
		+WEAPON.DONTBOB;
		+WEAPON.CHEATNOTWEAPON;
		+WEAPON.NO_AUTO_SWITCH;
		weapon.upsound "";
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.player)
			return;
		//stop all sounds on the owner (I use 12 for most looped sounds btw)
		for (int i = 12; i > 0; i--)
			owner.A_StopSound(i);
		//get the "first flash" and "activate demon" numbers of souls (64 and 66 by default)
		control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		minsouls = control.pk_minsouls;
		fullsouls = control.pk_fullsouls;
		cursouls = control.pk_souls;
		dur = 25;
		owner.A_StartSound("demon/start",CHAN_AUTO,flags:CHANF_LOCAL);		
		prevweapon = owner.player.readyweapon;
		let psp = owner.player.GetPSprite(PSP_WEAPON);
		if (psp) {
			owner.player.readyweapon = self;
			owner.player.SetPSprite(PSP_WEAPON,FindState("Ready"));
			psp.y = WEAPONTOP;
		}
		//enable demon shader if given to the consoleplayer
		if(players[consoleplayer] == owner.player)   {
			owner.A_StartSound("demon/loop",CH_HELL,CHANF_UI|CHANF_LOOPING);
			SetMusicVolume(0);
			Shader.SetEnabled( players[consoleplayer], "DemonMorph", true);
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "waveSpeed", 25 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "waveAmount", 10 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "centerX", 0.5 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "centerY", 0.5 );
		}
		handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (handler) {
			for (int i = 0; i < handler.demontargets.Size(); i++) {
				let act = handler.demontargets[i];
				if (act) {
					//console.printf("Giving SlowMoControl to %s",act.GetClassName());
					act.GiveInventory("PK_DemonTargetControl",1);
				}
			}
		}
		//make invulnerable:
		owner.bNODAMAGE = true;
		owner.bNOBLOOD = true;
		owner.bNOPAIN = true;
		if (cursouls >= fullsouls) {
			//disable golden cards before changing speed/gravity
			let cardcontrol = PK_CardControl(owner.FindInventory("PK_CardControl"));
			if (cardcontrol && cardcontrol.goldActive)
				cardcontrol.StopGoldenCards();
			//record previous speed and gravity for the slowmo effect
			p_speed = owner.speed;
			p_gravity = owner.gravity;
			//the owner will be slowed down a little
			owner.speed *= 0.6;
			owner.gravity *= 0.6;
			if (pk_debugmessages)
				console.printf("Changing player %d speed to %f and gravity to %f",owner.player.mo.PlayerNumber(),owner.speed,owner.gravity);
		}
		//also reduce view bob
		owner.player.mo.viewbob = 0.4;		
		//and INSTANTLY switch the current weapon to Demon Weapon
		owner.player.readyweapon = self;
		owner.player.readyweapon.crosshair = 99;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player || owner.bKILLED || !control || cursouls < minsouls) {
			Destroy();
			return;
		}
		if (control) {
			//if we have 2 or 1 souls shy of the required number, show a short "demon preview flash" but do nothing after that
			if (cursouls >= minsouls && cursouls < fullsouls) {
				//the preview lasts 20 tics, then switches you INSTANTLY back to previous weapon
				if (GetAge() >= 20) {
					owner.player.readyweapon = prevweapon;
					let psp = owner.player.GetPsprite(PSP_WEAPON);
					if (psp) {
						owner.player.SetPSprite(PSP_WEAPON,prevweapon.FindState("Ready"));
						psp.y = WEAPONTOP;
					}
					Destroy();
					return;
				}
			}
			//and this handles the actual removal of the effect once the duration has passed
			else if (cursouls >= fullsouls && GetAge() >= 35*dur) {
				control.pk_souls = Clamp(control.pk_souls - fullsouls,0,fullsouls);
				owner.player.readyweapon = prevweapon;
				let psp = owner.player.GetPsprite(PSP_WEAPON);
				if (psp) {
						owner.player.SetPSprite(PSP_WEAPON,prevweapon.FindState("Ready"));
						psp.y = WEAPONTOP;
				}
				Destroy();
				return;
			}
		}
		//do the ripple effect when the player fires
		if(runRipple) {
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "rippleTimer", rippleTimer );
			rippleTimer += 1.0 / 35;
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "amount", 35 * (1.0 - rippleTimer) );
			if(rippleTimer >= 1)	{
				Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "rippleTimer", 0);
				Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "amount", 0 );
				rippleTimer = 0;
				runRipple = false;
			}
		}
		//console.printf("owner speed %f | owner gravity %f",owner.speed,owner.gravity);
	}	
	override void DetachFromOwner() {
		if(players[consoleplayer] == owner.player)   {
			Shader.SetEnabled( players[consoleplayer], "DemonMorph", false);
			owner.A_StopSound(CH_HELL);
			SetMusicVolume(1);
		}
		if (!PK_MainHandler.CheckPlayersHave("PK_DemonWeapon") && handler) {
			for (int i = 0; i < handler.demontargets.Size(); i++) {
				let act = handler.demontargets[i];
				if (handler.demontargets[i]) {
					act.TakeInventory("PK_DemonTargetControl",1);
					//console.printf("removing SlowMocontrol from %s",act.GetClassName());
				}
			}
		}
		owner.A_StartSound("demon/end",CHAN_AUTO,CHANF_LOCAL);
		//restore vulnerability, speed, gravity and viewbob
		owner.bNODAMAGE = owner.default.bNODAMAGE;
		owner.bNOBLOOD = owner.default.bNOBLOOD;
		owner.bNOPAIN = owner.default.bNOPAIN;
		if (cursouls >= fullsouls) {
			owner.speed = owner.default.speed; //p_speed;
			owner.gravity = owner.default.gravity; //p_gravity;
		}
		if (pk_debugmessages)
			console.printf("Changing player %d speed to %f and gravity to %f",owner.player.mo.PlayerNumber(),owner.speed,owner.gravity);
		owner.player.mo.viewbob = owner.player.mo.default.viewbob;
		//instantly  switch back to previous weapon
		if (owner.player.readyweapon) {
			owner.player.readyweapon.crosshair = 0;
			owner.player.readyweapon.A_ZoomFactor(1.0);
		}
		owner.player.SetPsprite(PSP_DEMON,null);
		super.DetachFromOwner();
	}
	private double wzoom;
	states {
	Ready:
		TNT1 A 1 {
			A_Overlay(PSP_DEMON,"DemonCross");
			A_ZoomFactor(0.85,ZOOM_NOSCALETURNING);
			let psp = player.GetPSprite(PSP_WEAPON);
			psp.y = WEAPONTOP;
			A_WeaponOffset(0,0);
			if (invoker.control && invoker.control.pk_souls >= invoker.fullsouls)
				A_WeaponReady(WRF_NOSWITCH|WRF_NOBOB);
		}
		loop;
	Fire:
		TNT1 A 20 {
			A_Overlay(PSP_DEMON,"DemonCrossFire");
			A_WeaponOffset(0,0);
			A_StartSound("demon/fire",CHAN_AUTO);
			A_FireBullets(5,5,50,50,"PK_NullPuff",FBF_NORANDOM);
			invoker.rippleTimer = 0;
			invoker.runRipple = true;
			//invoker.wzoom = 1;
			//A_ZoomFactor(invoker.wzoom,ZOOM_NOSCALETURNING|ZOOM_INSTANT);
		}
		goto ready;
	DemonCross:
		DCRH A 25 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON,false);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.5);
		}
		stop;
	DemonCrossFire:
		DCRH E 2 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayFlags(OverlayID(),PSPF_ADDWEAPON,false);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.5);
		}
		DCRH DCB 2;
		DCRH A 15;
		stop;
	}
}


Class PK_EnemyDeathControl : PK_BaseActor {
	KillerFlyTarget kft;
	private int restcounter;
	private int restlife;
	private int maxlife;
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master) {
			//destroy();
			return;
		}
		restlife = random[cont](42,60);
		maxlife = int(35*frandom[cont](6,10));
		//spawn a hitbox for the Killer projectile to let the player juggle the corpse:
		kft = KillerFlyTarget(Spawn("KillerFlyTarget",master.pos));
		if (kft) {
			kft.target = master;
			kft.A_SetSize(master.radius,master.default.height*0.5);
			kft.vel = master.vel;
		}
	}	
	override void Tick () {
		if (master) {	
			SetOrigin(master.pos,true);
			if (!master.isFrozen())
				age++;
			if (GetAge() == 1 && kft)
				kft.vel = master.vel;	
			if  (master.vel.length() < 0.02)
				restcounter++;
			else
				restcounter = 0;
		}		
		double rad = 8;
		double smkz = 20;
		if (master) {
			rad = master.radius;
			smkz = master.height;
		}
		//this handles death if killed in Demon Mode:
		if (master && master.bKILLED && master.FindInventory("PK_DemonTargetControl")) {
			for (int i = 40; i > 0; i--) {
				smkz = master.default.height;
				let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](0,smkz)));
				if (smk) {
					smk.vel = (frandom[part](-0.4,0.4),frandom[part](-0.4,0.4),frandom[part](0,1));
					smk.A_SetRenderstyle(1.0,Style_Stencil);
					smk.SetShade("FF00FF");
					smk.bBRIGHT = true;
				}
			}
			master.destroy();
			destroy();
			return;
		}	
		//this handles regular death:
		else if (restcounter >= restlife || age > maxlife) {
			if (kft)
				kft.destroy();
			A_StartSound("world/bodypoof",CHAN_AUTO);
			for (int i = 26; i > 0; i--) {
				let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](0,smkz*1.5)));
				if (smk)
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
			}
			for (int i = 8; i > 0; i--) {
				let smk = Spawn("PK_WhiteDeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](pos.z,smkz)));
				if (smk) {
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
					smk.A_SetScale(0.4);
					smk.alpha = 0.5;
				}
			}
			//Class<Inventory> soul = (master && master.default.health >= 500) ? "PK_RedSoul" : "PK_Soul";			
			double pz = (pos.z ~== floorz) ? frandom[soul](8,14) : 0;
			//Spawn(soul,pos+(0,0,pz));
			
			// Spawn soul. In contrast to Painkiller, here soul healing amount is based on the monster's health:
			let soul = PK_Soul(Spawn("PK_Soul",pos+(0,0,pz)));
			if (soul && master) {
				soul.bearer = master.GetClass();
				/*//define an amount between 1-20 based on monster's health (linearly mapped between 20-500):
				double am = Clamp(LinearMap(double(master.SpawnHealth()), 20, 500, 1, 20), 1, 20);
				soul.amount = am;
				//slightly change soul's alpha and scale based on the resulting number:
				soul.alpha = Clamp(LinearMap(am, 1, 20, 0.5, 1.5), 0.5 , 1.5);
				soul.scale *= Clamp(LinearMap(am, 1, 20, 0.6, 1.15), 0.7, 1.15);
				//if the amount is over 15, make the soul red:
				if (am >= 15) {
					soul.A_SetTranslation("PK_RedSoul");
					//soul.A_SetRenderstyle(soul.alpha,Style_Shaded);
					//soul.SetShade("FF0000");
					soul.pickupsound = "pickups/soul/red";
				}
				console.printf("Spawned soul, master: %s, amount: %d",master.GetClassName(),soul.amount);*/
			}
			if (master)
				master.destroy();
			destroy();
			return;
		}
	}
}

// holds current gold and equipped cards:
Class PK_CardControl : PK_InventoryToken {
	int pk_gold; //current amount of gold
	array <name> UnlockedTarotCards; //holds names of all purchased cards for the board
	name EquippedSlots[5]; //holds names of all cards equipped into slots
	Class<Inventory> EquippedCards[5]; //holds classes of currently equipped cards (reinitialized when closing the board)	
	bool goldActive;
	private int dryUseTimer; //> 0 you try to use gold cards when you're out of uses
	int goldUses;
	private int totalGoldUses;
	property goldUses : goldUses;
	int goldDuration;
	property goldDuration : goldDuration;
		
	Default {
		PK_CardControl.goldUses 1;
		PK_CardControl.goldDuration 30;
	}
	
	clearscope int GetDryUseTimer() {
		return dryUseTimer;
	}
	
	//used by Forgiveness to make sure you can't reuse golden cards infinitely by unequipping and reequipping Forgiveness
	clearscope int GetTotalGoldUses() {
		return totalGoldUses;
	}
	
	//called to reset everything that needs resetting when starting a new map:
	void RefreshCards() {
		totalGoldUses = 0;
		goldUses = 1;
		if (FindInventory("PKC_Forgiveness"))
			goldUses++;
		if (pk_debugmessages)
			console.printf("Gold activations refreshed (remaining: %d)",goldUses);
	}
	
	void UseGoldenCards() {
		//check that the array has actually been successfully created
		if (EquippedCards.Size() < 5) {
			owner.A_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_LOCAL);
			if (pk_debugmessages)
				Console.Printf("The board hasn't been opened this map");
			return;
		}
		//do nothing if all 3 golden cards are unequipped (checking slots is easier here, since EquippedCards entries will never be null due to being allocated earlier)
		if (!EquippedSlots[2] && !EquippedSlots[3] && !EquippedSlots[4]) {
			owner.A_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_LOCAL);
			if (pk_debugmessages)
				Console.Printf("No gold cards equipped");
			return;
		}
		if (goldActive)
			return;
		if (goldUses < 1) {
			if (pk_debugmessages)
				console.printf("Can't use cards. Remaining uses: %d | Total uses: %d",goldUses,totalGoldUses);
			if (dryUseTimer == 0) {
				owner.A_StartSound("cards/cantuse",CHAN_AUTO,CHANF_LOCAL);
				//while this counter is above 0, we won't play the sound again and the hud will briefly show red cards signifying you can't use them anymore
				dryUseTimer = 45;
			}
			return;
		}
		goldUses--;
		totalGoldUses++;
		if (pk_debugmessages) {
			Console.Printf("Remaining gold activations: %d | Total activations: %d",goldUses,totalGoldUses);
		}
		for (int i = 2; i < EquippedCards.Size(); i++) {
			let card = PK_BaseGoldenCard(owner.FindInventory(EquippedCards[i]));
			if (!card)
				continue;
			card.GoldenCardStart();
			if (pk_debugmessages)
				Console.Printf("Activating %s golden card",card.GetTag());
		}
		owner.A_StartSound("cards/use",CHAN_AUTO,CHANF_LOCAL);
		goldActive = true;
	}
	void StopGoldenCards(bool silent = false) {
		goldActive = false;
		goldDuration = default.goldDuration;
		if (!silent)
			owner.A_StartSound("cards/end",CHAN_AUTO,CHANF_LOCAL);
		if (EquippedCards.Size() < 5) {
			if (pk_debugmessages)
				Console.Printf("Something went wrong: equipped golden cards were changed while they were active!");
			return;
		}
		for (int i = 2; i < EquippedCards.Size(); i++) {
			let card = PK_BaseGoldenCard(owner.FindInventory(EquippedCards[i]));
			if (!card)
				continue;
			if (pk_debugmessages)
				Console.Printf("Stopping %s golden card",card.GetTag());
			card.GoldenCardEnd();
		}
	}	
	void PK_EquipCards() {
		for (int i = 0; i < EquippedCards.Size(); i++) {
			EquippedCards[i] = null;
		}
		/*EquippedCards.Clear();
		EquippedCards.Reserve(5);		
		if (pk_debugmessages)
			console.printf("Allocated %d card slots successfully",EquippedCards.Size());*/
		//give the equipped cards:
		for (int i = 0; i < EquippedCards.Size(); i++) {
			//construct card classname based on card ID from ui
			name cardClassName = String.Format("PKC_%s",EquippedSlots[i]);
			//turn that into a class type
			Class<Inventory> card = cardClassName;
			//if the slot card ID is empty, make sure the slot is empty too (and if there was a card in it before, remove it)
			if (!card) {			
				if (pk_debugmessages)
					console.printf("Slot %d is empty (\"%s:\" is not a valid class)",i,cardClassName);
				continue;
			}
			//record new class type in a slot
			EquippedCards[i] = card;
			//if player has no card class of that type, give it to them
			if (!owner.FindInventory(card)) {
				owner.GiveInventory(card,1);
			}
			if (pk_debugmessages) {
				if (owner.FindInventory(card))
					console.printf("%s is in slot %d",owner.FindInventory(card).GetClassName(),i);
			}
		}
		//if player has some cards that are NOT equipped, take them away:
		for (int unC = 0; unC < UnlockedTarotCards.Size(); unC++) {
			//construct card classname based on card ID from ui
			name cardClassName = String.Format("PKC_%s",UnlockedTarotCards[unC]);
			//turn that into an actual class type
			Class<Inventory> card = cardClassName;
			//check if it's a valid class type
			if (!card) {
				if (pk_debugmessages)
					console.printf("Tried taking \"%s\" but it's not a valid class",cardClassName);
				continue;
			}
			//check the player even has it
			if (!owner.FindInventory(card)) {
				continue;
			}
			//check every unlocked card name against every equipped card name
			//(for simplicity and speed we check the name arrays against each other instead of class type arrays)
			bool isEquipped = false;
			for (int curC = 0; curC < 5; curC++) {
				if (EquippedSlots[curC] == UnlockedTarotCards[unC]) {
					isEquipped = true;
					break;
				}
			}
			if (!isEquipped) {	
				if (pk_debugmessages)
					console.printf("Taking card %s (not equipped)",owner.FindInventory(card).GetClassName());
				owner.TakeInventory(card,1);
			}
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player) {
			return;
		}
		if (dryUseTimer > 0)
			dryUseTimer = Clamp(dryUseTimer - 1,0,45);
		if (!goldActive)
			return;
		else if (level.time % 35 == 0) {
			if (goldDuration > 0 && owner.health > 0)
				goldDuration--;
			else
				StopGoldenCards();
		}
	}
}

Class PK_BaseSilverCard : PK_InventoryToken abstract {
	protected PK_CardControl control;
	protected virtual void GetCard() {}
	protected virtual void RemoveCard() {}
	PK_BoardEventHandler event;
	
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.player) {
			DepleteOrDestroy();
			return;
		}
		event = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		control = PK_CardControl(owner.FindInventory("PK_CardControl"));
		if (!event || !control)
			return;
		GetCard();
		if (pk_debugmessages)
			console.printf("Player %d has %s card now",owner.player.mo.PlayerNumber(),self.GetClassName());
	}
	override void DetachFromOwner() {
		if (!owner || !owner.player) {
			DepleteOrDestroy();
			return;
		}
		RemoveCard();
		super.DetachFromOwner();
	}
}

//flips a global bool. While true, souls don't disappear (PK_Soul age variable doesn't increase)
Class PKC_SoulKeeper : PK_BaseSilverCard {	
	Default {
		tag "SoulKeeper";
	}	
	override void GetCard() {
		if (event) {
			event.SoulKeeper = true;
			if (pk_debugmessages)
				console.printf("Soul Keeper active: %d",event.SoulKeeper);
		}
	}	
	override void RemoveCard() {
		if (event) {
			event.SoulKeeper = PK_MainHandler.CheckPlayersHave(self.GetClassName());
			if (pk_debugmessages)
				console.printf("Soul Keeper active: %d",event.SoulKeeper);
		}
	}
}

//sets player's base and current health to 150 (reverts when removed)
Class PKC_Blessing : PK_BaseSilverCard {
	private int curHealth;
	Default {
		tag "Blessing";
	}	
	override void GetCard() {
		curHealth = owner.health;
		let plr = owner.player.mo;
		plr.BonusHealth = 50;
		plr.GiveBody(150, 100); //Note that bonushealth gets automatically added to the second argument, so, to limit given health to 150, I actually have to use 100 because bonushealth is already 50 (I know, it's really weird)
	}	
	override void RemoveCard() {
		let plr = owner.player.mo;
		plr.BonusHealth = 0;
		plr.A_SetHealth(curhealth); //revert health, so that the player can't equip/unequip this card for free heals
	}
}

// doubles the amount of picked up ammo
Class PKC_Replenish : PK_BaseSilverCard {
	Default {
		tag "Replenish";
	}
	override bool HandlePickup (Inventory item) {
		if (item is "Ammo")
			item.amount *= 2;
		return super.HandlePickup(item);
	}
}

//Demon Morph is activated at 50 souls with this:
Class PKC_DarkSoul : PK_BaseSilverCard {
	Default {
		tag "DarkSoul";
	}
	override void GetCard() {
		let control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		if (!control)
			return;
		control.pk_minsouls = 48;
		control.pk_fullsouls = 50;
	}
	override void RemoveCard() {
		let control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		if (!control)
			return;
		control.pk_minsouls = control.default.pk_minsouls;
		control.pk_fullsouls = control.default.pk_fullsouls;
	}
}

//Makes PK_Soul and PK_GoldPikcup descendants fly towards the player (special handling in their Tick when they have a tracer):
Class PKC_SoulCatcher : PK_BaseSilverCard {
	Default {
		tag "SoulCatcher";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		BlockThingsIterator itr = BlockThingsIterator.Create(owner,144);
		while (itr.next()) {
			let next = itr.thing;
			if (next && (next is "PK_GoldPickup" || next is "PK_Soul") && !next.tracer) {
				next.tracer = owner;
				if (pk_debugmessages)
					console.printf("found %s",next.GetClassName());
			}
		}
	}
}

//changes goldUses variable on card control to allow activating them twice
Class PKC_Forgiveness : PK_BaseSilverCard {
	Default {
		tag "Forgiveness";
	}
	override void GetCard() {
		//only increase gold uses if the cards have been used no more than once in total
		if (control && control.GetTotalGoldUses() < 2)
			control.goldUses = Clamp(control.goldUses + 1,0,2);
		if (pk_debugmessages)
			console.printf("Giving Forgiveness");
	}
	override void RemoveCard() {
		if (control)
			control.goldUses = Clamp(control.goldUses - 1,0,1);
		if (pk_debugmessages)
			console.printf("Removing Forgiveness");
	}
}

//PK_GoldPickup descendants will givs the player double the amount with this in inventory:
Class PKC_Greed : PK_BaseSilverCard {
	Default {
		tag "Greed";
	}
}

//PK_Soul checks for this in its TryPickup and does amount*=2 if it's found
Class PKC_SoulRedeemer : PK_BaseSilverCard {
	Default {
		tag "SoulRedeemer";
	}
}

//Adds 1 HP per second if player hasn't been damaged for 10 seconds
Class PKC_HealthRegeneration : PK_BaseSilverCard {
	private int dmgCounter;
	Default {
		tag "HealthRegeneration";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		if (level.time % 35 == 0) {
			if (dmgCounter > 0)
				dmgCounter = Clamp(dmgCounter-1,0,10);
			else
				owner.GiveBody(1,100);
		}
	}
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags) {
		if (passive && damage > 0)
			dmgCounter = 10;
	}
}

//Vampirism: WolrdThingDamaged checks if this is in e.DamageSource's inventory and if so, adds e.Damage value to drainedHP:
Class PKC_HealthStealer : PK_BaseSilverCard {
	double drainedHP;
	Default {
		tag "HealthStealer";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		/* Stagger giving drained HP over 10 tics. This allows to record drained HP in a
		double rather than int (which is important since you only drain 3% and that would
		often be rounded down to 0 with an int); plus it helps to make sure stuff like
		shotgun or minigun don't become too OP since the results of several shots get smashed
		together and then limited to 8 HP max.
		*/
		if (level.time % 10 == 0 && drainedHP > 0) {
			int drain = Clamp(drainedHP,1,8);
			owner.GiveBody(drain,100);
			if (pk_debugmessages)
				console.printf("Drained %d HP (%f\%)",drainedHP,drain);
			drainedHP = 0;
		}
	}
}

//Same as Health Regeneration but gives 1 point of armor per sec instead:
Class PKC_HellishArmor : PK_BaseSilverCard {
	private int dmgCounter;
	Default {
		tag "HellishArmor";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		if (level.time % 35 == 0) {
			if (dmgCounter > 0)
				dmgCounter = Clamp(dmgCounter-1,0,10);
			else
				owner.GiveInventory("PK_HellishArmorBonus",1);
		}
	}
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags) {
		if (passive && damage > 0)
			dmgCounter = 10;
	}
}

//used by Hellish Armor
Class PK_HellishArmorBonus : BasicArmorBonus  {
	Default {
		armor.saveamount 1;
		armor.maxsaveamount 100;
		+INVENTORY.IGNORESKILL;
	}
}

//iterates through player's inventory and sets all Ammo amount to 666 (beyond max)
Class PKC_666Ammo : PK_BaseSilverCard {
	Default {
		tag "666Ammo";
	}
	static const Class<Ammo> PKAmmoTypes[] = {
		'PK_Shells',
		'PK_FreezerAmmo',
		'PK_StakeAmmo',
		'PK_BombAmmo',
		'PK_BulletAmmo',
		'PK_ShurikenAmmo',
		'PK_CellAmmo'
	};
	private array < Class<Ammo> > modifiedAmmo;
	private array <int> prevAmmoAmount;
	override void GetCard() {
		//give mod ammo types if there is none
		for (int i = 0; i < PKAmmoTypes.Size(); i++) {
			let am = PKAmmoTypes[i];
			if (owner.CountInv(am) < 1)
				owner.GiveInventory(am,0); //we only need the pointers, no ammount increase
		}
		modifiedAmmo.Clear();
		//iterate through inventory, record every found ammo and its current amount in parallel into two arrays
		for(let item = owner.Inv; item; item = item.Inv) {
			let am = Ammo(item);
			if (am) {
				Class<Ammo> foundammo = am.GetClassName();
				modifiedAmmo.push(foundammo);
				prevAmmoAmount.push(owner.CountInv(foundammo));
				//now set current ammo amount to 666
				owner.A_SetInventory(item.GetClassName(),666,beyondMax:true);
			}
		}		
	}
	override void RemoveCard() {
		//restore original ammo amount using the two arrays we recorded earlier
		if (modifiedAmmo.Size() < 1 || prevAmmoAmount.Size() < 1 || modifiedAmmo.Size() != prevAmmoAmount.Size())
			return;
		for (int i = 0; i < modifiedAmmo.Size(); i++)
			owner.A_SetInventory(modifiedAmmo[i],prevAmmoAmount[i]);
	}
}

//base class for golden cards. They're activated with a netevent that makes PK_CardControl call GoldenCardStart on all equipped cards
Class PK_BaseGoldenCard : PK_BaseSilverCard {
	protected bool cardActive;
	virtual void GoldenCardStart() {
		cardActive = true;
	}
	virtual void GoldenCardEnd() {
		cardActive = false;
	}
}

//simply reduces incoming damage by 50%
Class PKC_Endurance : PK_BaseGoldenCard {
	Default {
		tag "Endurance";
	}
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)	{
		if (cardActive && passive && damage > 0)
			newdamage = max(0, ApplyDamageFactors(GetClass(), damageType, damage, damage * 0.5));
	}
}

//simply modifies max duration of gold cards in cardcontrol item
Class PKC_TimeBonus : PK_BaseGoldenCard {
	Default {
		tag "TimeBonus";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		if (control)
			control.goldDuration = 45;
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		if (control)
			control.goldDuration = control.default.goldDuration;
	}
}

//changes player's speed
Class PKC_Speed : PK_BaseGoldenCard {
	private double p_speed;
	Default {
		tag "Speed";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		if (owner) {
			p_speed = owner.speed;
			owner.speed *= 1.33;
		}
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		if (owner) {
			owner.speed = owner.default.speed; //p_speed;
		}
	}
}

//essentially, a Megasphere
Class PKC_Rebirth : PK_BaseGoldenCard {
	Default {
		tag "Rebirth";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		if (owner && owner.player) {
			owner.GiveInventory("BlueArmorForMegasphere",1);
			//make sure we increase health to 200 but not beyond (even with "Blessing" which adds 50 bonushealth)
			owner.GiveBody(200,200-owner.player.mo.BonusHealth);
		}
	}
}

//works via control item initially given to all monsters
Class PKC_Confusion : PK_BaseGoldenCard {
	private PK_MainHandler handler;
	Default {
		tag "Confusion";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		owner.GiveInventory("PK_ConfusionControl",1);
		handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (!handler)
			return;
		for (int i = 0; i < handler.demontargets.Size(); i++) {
			if (handler.demontargets[i]) {
				handler.demontargets[i].GiveInventory("PK_ConfusionControl",1);				
				console.printf("Giving ConfusionControl to %s",handler.demontargets[i].GetClassName());
			}
		}
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		owner.TakeInventory("PK_ConfusionControl",1);
		if (!handler)
			return;
		if (!PK_MainHandler.CheckPlayersHave("PK_ConfusionControl")) {
			if (pk_debugmessages)
				console.printf("Nobody has active \"Confusion\"; ending effect");
			for (int i = 0; i < handler.demontargets.Size(); i++) {
				if (handler.demontargets[i]) {
					handler.demontargets[i].TakeInventory("PK_ConfusionControl",1);
					handler.demontargets[i].target = null;
				}
			}
		}
	}
}


//Confusion control item: makes monsters select a random target from monsters around them and ignore the player
Class PK_ConfusionControl : PK_InventoryToken  {
	private int cycle; //this will hold a random interval, after which the monster will switch target
	override void AttachToOwner(actor other) {
		//only attach to monsters and players
		if (!other.bISMONSTER && !other.player) {
			destroy();
			return;
		}
		cycle = 1;
		super.AttachToOwner(other);			
	}
	override void DoEffect() {
		super.DoEffect();
		//do nothing for players but let them have the item, as a token
		if (!owner || owner.player || owner.health <= 0)
			return;
		if (level.time % 35 * cycle == 0) {
			cycle = random[conf](3,8); //set random interval
			//find a target with a blockthingsiterator (Won't affect unalerted monsters since this doesn't call A_Look, so even though a target gets set, they won't start chasing it. This is good since it won't mess with mosnters deep in the map.)
			BlockThingsIterator itr = BlockThingsIterator.Create(owner,320);
			while (itr.next()) {
				let next = itr.thing;
				if (next == owner)
					continue;
				if (!next.bISMONSTER)
					continue;
				if (next.bKILLED)
					continue;
				owner.target = next;
				if (pk_debugmessages)
					console.printf("%s is targeting %s",owner.GetClassName(),owner.target.GetClassName());
			}
		}
	}
}

//Essentially PowerDoubleFiringSpeed but some weapons have special checks and custom behavior changes when it's in inventory:
Class PKC_Dexterity : PK_BaseGoldenCard {
	Default {
		tag "Dexterity";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		if (!owner.FindInventory("PKC_Haste"))
			owner.GiveInventory("PK_DexterityEffect",1);
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		owner.TakeInventory("PK_DexterityEffect",1);
	}
}

//used by Dexterity
Class PK_DexterityEffect : PowerDoubleFiringSpeed {
	Default {
		powerup.duration 999999;
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		for (int i = CH_END; i > 0; i--)
			owner.A_SoundPitch(i,1.2);
	}
	override void DetachFromOwner() {
		if (!owner || !owner.player)
			return;
		for (int i = CH_END; i > 0; i--)
			owner.A_SoundPitch(i,1);
		super.DetachFromOwner();
	}
}

Class PKC_WeaponModifier : PK_BaseGoldenCard {
	Default {
		tag "WeaponModifier";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		owner.GiveInventory("PK_WeaponModifier",1);
		let wmod = PK_WeaponModifier(owner.FindInventory("PK_WeaponModifier"));
		if (wmod)
			wmod.duration += 99;
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		let wmod = PK_WeaponModifier(owner.FindInventory("PK_WeaponModifier"));
		if (wmod && wmod.duration > 0) {
			wmod.duration -= 99;
		}
	}
}

//spawns explosions while the player is running around
Class PKC_StepsOfThunder : PK_BaseGoldenCard {
	private int cycle; //how often to spawn explosions
	Default {
		tag "StepsOfThunder";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!cardActive)
			return;
		if (owner.Vel.Length() > 4) {
			cycle++;
			if (cycle % 10 == 0) {
				owner.A_Explode(20,256,XF_NOTMISSILE,alert:false,fulldamagedistance:128);
				owner.A_Quake(2,5,0,32,"");
				owner.A_StartSound("cards/thunderwalk",15);
			}
		}
		else
			cycle = 0;
	}
}

//a plain and simple quad damage
Class PKC_Rage : PK_BaseGoldenCard {
	Default {
		tag "Rage";
	}
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)	{
		if (cardActive && !passive && damage > 0)
			newdamage = max(0, ApplyDamageFactors(GetClass(), damageType, damage, damage * 4));
	}
}

Class PKC_MagicGun : PK_BaseGoldenCard {
	Default {
		tag "MagicGun";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		owner.GiveInventory("PK_MagicGunEffect",1);
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		owner.TakeInventory("PK_MagicGunEffect",1);
	}
}

Class PK_MagicGunEffect : PowerInfiniteAmmo {
	Default {
		powerup.duration 999999;
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}
}


Class PKC_IronWill : PK_BaseGoldenCard {
	Default {
		tag "IronWill";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		owner.bINVULNERABLE = true;
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		owner.bINVULNERABLE = owner.default.bINVULNERABLE;
	}
}

Class PKC_Haste : PK_BaseGoldenCard {
	//PK_MainHandler handler;
	Default {
		tag "Haste";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		owner.GiveInventory("PK_HasteControl",1);
		let handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (!handler)
			return;
		for (int i = 0; i < handler.demontargets.Size(); i++) {
			if (handler.demontargets[i])
				handler.demontargets[i].GiveInventory("PK_HasteControl",1);
		}
	}
	override void GoldenCardEnd() {
		super.GoldenCardEnd();
		owner.TakeInventory("PK_HasteControl",1);
		let handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (!handler)
			return;
		if (!PK_MainHandler.CheckPlayersHave("PK_HasteControl")) {
			if (pk_debugmessages)
				console.printf("Nobody has active \"Haste\"; ending effect");
			console.printf("Demon targets array size: %d",handler.demontargets.Size());
			for (int i = 0; i < handler.demontargets.Size(); i++) {	
				let obj = handler.demontargets[i];
				if (!obj)
					continue;
				obj.TakeInventory("PK_HasteControl",1);
				if (pk_debugmessages)
					console.printf("Taking PK_HasteControl from %s",obj.GetClassName());
			}
		}
	}
}

Class PK_HasteControl : PK_InventoryToken {
	private double p_gravity;
	private double p_speed;
	private state slowstate;
	private int ownerType; // 0 - monster; 1 - monster projectile; 2 - player projectile; 3 - player;
	private state wstate0;
	private state wstate1;
	private state wstate2;
	private state wstate3;
	private bool ticvar;
	override void AttachToOwner(actor other) {
		//only affect missiles, monsters and players:
		if (!other.bISMONSTER && !other.bMISSILE && !(other is "PlayerPawn")) {
			destroy();
			return;
		}
		super.AttachToOwner(other);
		if (!owner)
			return;
		if (owner.bISMONSTER)
			ownerType = 0;
		else if (owner.bMISSILE) {
			if (owner.target && owner.target.player)
				ownerType = 2;
			else
				ownerType = 1;
		}
		else if (owner.player) {
			ownerType = 3;
			owner.player.mo.viewbob = 0.5;
		}
		else {
			//ownerType = 4;
			destroy();
			return;
		}
		p_gravity = owner.gravity;
		p_speed = owner.speed;
		//monsters and monster projectiles are slowed down most:
		double slowfactor = 0.4;
		//player projectiles are slowed down moderately
		if (ownerType == 2) 
			slowfactor = 0.6;
		//players are only slowed down a bit
		else 
			slowfactor = 0.8;
		owner.gravity *= slowfactor;
		owner.vel *= slowfactor;
		owner.speed *= slowfactor;	
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner)
			return;
		//monsters:
		if (ownerType == 0) {
			for (int i = CH_END; i > 0; i--)
				owner.A_SoundPitch(i,0.6);
			if (owner.CurState != slowstate) {
				owner.A_SetTics(owner.tics*1.8);
				slowstate = Owner.CurState;
			}
			/* make sure its speed is not too high, to override stuff like A_SkullAttack
			Do this only every so often (10 tics) since it involves a square root
			I use owner's age instead of level.time to not do it at once on every monster
			*/
			if (owner.GetAge() % 10 == 0) {
				if (vel.length() > 6)
					vel = vel.unit() * 6;
			}
		}
		//monster projectiles:
		else if (ownerType == 1) {
			for (int i = CH_END; i > 0; i--)
				owner.A_SoundPitch(i,0.6);
		}
		else {
			//player projectiles and players
			if (ownerType == 2)  {
				for (int i = CH_END; i > 0; i--)
					owner.A_SoundPitch(i,0.8);
				if (owner.CurState != slowstate) {
					owner.A_SetTics(owner.tics*1.5);
					slowstate = Owner.CurState;
				}				
			}
			//players (having Dexterity neutralizes the effect)
			if (ownerType == 3 && !owner.FindInventory("PKC_Dexterity")) {
				for (int i = CH_END; i > 0; i--)
					owner.A_SoundPitch(i,0.8);
				let weap = owner.player.readyweapon;
				if (!weap)
					return;
				//multiply every OTHER frame by 1.5 (multiplying every frame makes it too slow and using a smaller factor doesn't always work since we can't have fractional tics)
				double fac = ticvar ? 1.5 : 1;	
				let ps0 = owner.player.FindPSprite(PSP_WEAPON);
				if (!ps0)
					return;
				ticvar = !ticvar;	
				if (ps0.curstate != wstate0) {		
					ps0.tics = Clamp(double(ps0.tics*fac),2,5);
					wstate0 = ps0.curstate;
				}
				let ps1 = owner.player.FindPSprite(-1);
				if (ps1 && ps1.curstate != wstate1) {					
					ps1.tics = Clamp(double(ps1.tics*fac),2,5);
					wstate1 = ps1.curstate;
				}		
				let ps2 = owner.player.FindPSprite(2);
				if (ps2 && ps2.curstate != wstate2) {					
					ps2.tics = Clamp(double(ps2.tics*fac),2,5);
					wstate2 = ps2.curstate;
				}		
				let ps3 = owner.player.FindPSprite(-100);
				if (ps3 && ps3.curstate != wstate3) {					
					ps3.tics = Clamp(double(ps3.tics*fac),2,5);
					wstate3 = ps3.curstate;
				}			
			}
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		for (int i = CH_END; i > 0; i--)
			owner.A_SoundPitch(i,1);
		owner.speed = owner.default.speed; //p_speed;
		owner.gravity = owner.default.gravity; //p_gravity;
		if (owner.player)
			owner.player.mo.viewbob = owner.player.mo.default.viewbob;
		super.DetachFromOwner();
	}
}