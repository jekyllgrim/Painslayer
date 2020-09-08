Class PK_SlowMoControl : PK_InventoryToken {
	private double p_gravity;
	private double p_speed;
	private vector3 p_vel;
	private state slowstate;
	private int p_renderstyle;
	private double p_alpha;
	private color p_color;
	private double speedfactor;
	private double gravityfactor;
	property speedfactor : speedfactor;
	property gravityfactor : gravityfactor;
	Default {
		PK_SlowMoControl.speedfactor 0.5;
		PK_SlowMoControl.gravityfactor 0.2;
	}
	override void Tick() {}
	override void AttachToOwner(actor other) {
		if (!other.bISMONSTER && !other.bMISSILE && !other.player) {
			destroy();
			return;
		}
		super.AttachToOwner(other);
		if (!owner) {
			return;
		}
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
		}/*
		//monsters spawn a wobbly after-image:
		if (owner.bISMONSTER) {
			let img = Spawn("PK_SlowMoAfterImage",owner.pos);
			if (img) {
				img.master = owner;
			}
		}*/
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			DepleteOrDestroy();
			return;
		}
		//monsters and players are colorized so that the demon shader can make them red:
		if (owner.bISMONSTER || (owner.player && owner.player != players[consoleplayer])) {
			if (players[consoleplayer].mo.FindInventory("PK_DemonWeapon")) {			
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
		if (!owner.player) {
			for (int i = 7; i >= 0; i--)
				owner.A_SoundPitch(i,0.8);
			if (owner.CurState != slowstate) {
				owner.A_SetTics(owner.tics*1.5);
				slowstate = Owner.CurState;
			}
		}
	}
	override void DetachFromOwner() {
		if (!owner) {
			return;
		}
		owner.bBRIGHT = owner.default.bBRIGHT;
		owner.gravity = p_gravity;
		owner.speed = p_speed;
		owner.A_SetRenderstyle(p_alpha,p_renderstyle);
		owner.SetShade(p_color);
		super.DetachFromOwner();
	}
}

Class PK_SlowMoAfterImage : PK_SmallDebris {
	Default {
		renderstyle 'Stencil';
		+BRIGHT;
		stencilcolor 'FF00FF';
		+NOINTERACTION;
	}
	override void Tick() {
		super.Tick();
		if (!master || (master&& !master.FindInventory("PK_SlowMoControl"))) {
			//console.printf("master has no control item");
			destroy();
			return;
		}
		SetOrigin(master.pos,true);
		angle = master.angle;
		sprite = master.sprite;
		frame = master.frame;
		scale = master.scale * frandom[sfx](0.9,1.1);
	}
	states {
	Spawn:
		#### # 1;
		wait;
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
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
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
	PK_DemonMorphControl control;
	private int minsouls;
	private int fullsouls;	
	private int dur;	
	Weapon prevweapon;
	private double p_speed;
	private double p_gravity;	
	private int p_renderstyle;
	private double p_alpha;
	private color p_color;
	Default {
		+WEAPON.NOAUTOFIRE;
		+WEAPON.DONTBOB;
		+WEAPON.CHEATNOTWEAPON;
		+WEAPON.NO_AUTO_SWITCH;
		weapon.upsound "";
	}
	private double rippleTimer;
	private bool runRipple;
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.player)
			return;
		owner.A_StopSound(12);
		control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		minsouls = control.pk_minsouls;
		fullsouls = control.pk_fullsouls;
		dur = 25;
		owner.A_StartSound("demon/start",CHAN_AUTO,flags:CHANF_LOCAL);
		if(players[consoleplayer] == owner.player)   {
			owner.A_StartSound("demon/loop",66,CHANF_UI|CHANF_LOOPING);
			SetMusicVolume(0);
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "waveSpeed", 25 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "waveAmount", 10 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "centerX", 0.5 );
			Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "centerY", 0.5 );
		}
		owner.bNODAMAGE = true;
		owner.bNOBLOOD = true;
		owner.bNOPAIN = true;
		p_speed = owner.speed;
		p_gravity = owner.gravity;
		p_renderstyle = owner.GetRenderstyle();
		p_alpha = owner.alpha;
		p_color = owner.fillcolor;
		if (control.pk_souls >= fullsouls) {
			owner.speed *= 0.6;
			owner.gravity *= 0.6;
			if (!players[consoleplayer].mo.FindInventory(self.GetClassName())) {
				owner.bBRIGHT = true;
				owner.A_SetRenderstyle(1.0,Style_AddShaded);
				owner.SetShade("FF0000");
			}
		}
		owner.player.mo.viewbob = 0.4;		
		owner.player.readyweapon = self;
		owner.player.readyweapon.crosshair = 99;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.player || owner.bKILLED || !control || control.pk_souls < minsouls) {
			Destroy();
			return;
		}
		if (control) {
			if (control.pk_souls >= minsouls && control.pk_souls < fullsouls) {
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
			else if (control.pk_souls >= fullsouls && GetAge() >= 35*dur) {
				control.pk_souls -= fullsouls;
				if (control.pk_souls < 0)
					control.pk_souls = 0;
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
	}	
	override void DetachFromOwner() {
		if(players[consoleplayer] == owner.player)   {
			owner.A_StopSound(66);
			SetMusicVolume(1);
		}		
		owner.A_StartSound("demon/end",CHAN_AUTO,CHANF_LOCAL);
		owner.bNODAMAGE = owner.default.bNODAMAGE;
		owner.bNOBLOOD = owner.default.bNOBLOOD;
		owner.bNOPAIN = owner.default.bNOPAIN;
		owner.speed = p_speed;
		owner.gravity = p_gravity;
		owner.player.mo.viewbob = owner.player.mo.default.viewbob;
		if (owner.player.readyweapon) {
			owner.player.readyweapon.crosshair = 0;
			owner.player.readyweapon.A_ZoomFactor(1.0);
		}
		owner.player.SetPsprite(66,null);
		owner.A_SetRenderstyle(p_alpha,p_renderstyle);
		owner.SetShade(p_color);
		owner.bBRIGHT = owner.default.bBRIGHT;
		super.DetachFromOwner();
	}
	private double wzoom;
	states {
	Ready:
		TNT1 A 1 {
			A_Overlay(66,"DemonCross");
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
			A_Overlay(66,"DemonCrossFire");
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


Class PK_EnemyDeathControl : Actor {
	KillerFlyTarget kft;
	private int restcounter;
	private int restlife;
	private int maxlife;
	private int age;
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master) {
			destroy();
			return;
		}
		restlife = random[cont](42,60);
		maxlife = int(35*frandom[cont](6,10));
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
			if  (master.vel ~== (0,0,0))
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
		if (master && master.bKILLED && master.FindInventory("PK_SlowMoControl")) {
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
		}	
		else if (restcounter >= restlife || age > maxlife || !master) {
			if (kft)
				kft.destroy();
			A_StartSound("world/bodypoof",CHAN_AUTO);
			for (int i = 26; i > 0; i--) {
				let smk = Spawn("PK_DeathSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](0,smkz*1.5)));
				if (smk)
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
			}
			for (int i = 8; i > 0; i--) {
				let smk = Spawn("PK_WhiteSmoke",pos+(frandom[part](-rad,rad),frandom[part](-rad,rad),frandom[part](pos.z,smkz)));
				if (smk) {
					smk.vel = (frandom[part](-0.5,0.5),frandom[part](-0.5,0.5),frandom[part](0.3,1));
					smk.A_SetScale(0.4);
					smk.alpha = 0.5;
				}
			}
			Class<Inventory> soul = (master && master.default.health >= 500) ? "PK_RedSoul" : "PK_Soul";			
			double pz = (pos.z ~== floorz) ? frandom[soul](8,14) : 0;
			Spawn(soul,pos+(0,0,pz));
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
	array < Class<Inventory> > EquippedCards; //holds classes of currently equipped cards (reinitialized when closing the board)
	
	bool goldActive;
	int goldUses;
	property goldUses : goldUses;
	int goldDuration;
	property goldDuration : goldDuration;
		
	Default {
		PK_CardControl.goldUses 1;
		PK_CardControl.goldDuration 30;
	}
	
	override void Tick() {}
	
	void PK_UseGoldenCards() {
		if (EquippedCards.Size() < 5) {
			if (pk_debugmessages)
				Console.Printf("The board hasn't been opened this map");
			return;
		}
		if (goldUses < 1 || goldActive) {
			if (!goldActive)
				owner.A_StartSound("cards/cantuse",CHAN_AUTO,CHANF_LOCAL);
			return;
		}
		goldUses--;
		if (pk_debugmessages)
			Console.Printf("Remaining gold card uses: %d",goldUses);
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
	void PK_StopGoldenCards() {
		if (EquippedCards.Size() < 5) {
			if (pk_debugmessages)
				Console.Printf("Something went wrong: equipped golden cards were changed while they were active!");
			return;
		}
		goldActive = false;
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
		EquippedCards.Clear();
		EquippedCards.Reserve(5);			
		if (pk_debugmessages)
			console.printf("Allocated %d card slots successfully",EquippedCards.Size());	
		
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
			destroy();
			return;
		}
		if (!goldActive)
			return;
		else if (level.time % 35 == 0) {
			if (goldDuration > 0)
				goldDuration--;
			else
				PK_StopGoldenCards();
		}
	}
}

Class PK_BaseTarotCard : PK_InventoryToken abstract {
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
	//returns false only if none of the current players have the same card:
	bool CheckPlayersHaveCard(Class<Inventory> card) {
		if(!card)
			return false;
		Inventory checkcard;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo)
				continue;
			checkcard = plr.mo.FindInventory(card);
			if (checkcard)
				break;
		}
		if (checkcard) {
			if (pk_debugmessages)
				console.printf("Somebody still has %s card",card.GetClassName());
			return true;
		}
		if (pk_debugmessages)
			console.printf("Nobody has %s card anymore",card.GetClassName());
		return false;
	}
}

//flips a global bool. While true, souls don't disappear (PK_Soul age variable doesn't increase)
Class PKC_SoulKeeper : PK_BaseTarotCard {	
	Default {
		tag "SoulKeeper";
	}	
	override void GetCard() {
		if (event)
			event.SoulKeeper = true;
	}	
	override void RemoveCard() {
		if (event)
			event.SoulKeeper = CheckPlayersHaveCard(self.GetClassName());
	}
}

//sets player's base and current health to 150 (reverts when removed)
Class PKC_Blessing : PK_BaseTarotCard {
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

/*Iterates over an array of all Ammo in an event handler and doubles it amount.
Also removes Ammo that has been picked up from the array.
(A bit awkward but I want this to work for all ammo, just in case.)*/
Class PKC_Replenish : PK_BaseTarotCard {
	Default {
		tag "Replenish";
	}
	override void GetCard() {
		if (event) {
			//first remove items that have already been picked up from the array
			for (int i = 0; i < event.ammopickups.Size(); i++) {
				if (!event.ammopickups[i] || event.ammopickups[i].owner)
					event.ammopickups.delete(i);
			}
			event.ammopickups.ShrinkToFit();
			for (int i = 0; i < event.ammopickups.Size(); i++) {
				if (event.ammopickups[i])
					event.ammopickups[i].amount *= 2;
			}
		}
	}	
	override void RemoveCard() {
		if (!CheckPlayersHaveCard(self.GetClassName()) && event) {
			//first remove items that have already been picked up from the array
			for (int i = 0; i < event.ammopickups.Size(); i++) {
				if (!event.ammopickups[i] || event.ammopickups[i].owner)
					event.ammopickups.delete(i);
			}
			event.ammopickups.ShrinkToFit();
			for (int i = 0; i < event.ammopickups.Size(); i++){
				if (event.ammopickups[i] && event.ammopickups[i] is "Ammo")
					event.ammopickups[i].amount =  event.ammopickups[i].default.amount;
			}				 
		}
	}
}

//Demon Morph is activated at 50 souls with this:
Class PKC_DarkSoul : PK_BaseTarotCard {
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

//Makes PK_Soul and PK_GoldPikcup descendants fly towards the player (with NOGRAVITY):
Class PKC_SoulCatcher : PK_BaseTarotCard {
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
				//console.printf("found %s",next.GetClassName());
			}
		}
	}
}

Class PKC_Forgiveness : PK_BaseTarotCard {
	Default {
		tag "Forgiveness";
	}
}

//PK_GoldPickup descendants will givs the player double the amount with this in inventory:
Class PKC_Greed : PK_BaseTarotCard {
	Default {
		tag "Greed";
	}
}

//PK_Soul checks for this in its TryPickup and does amount*=2 if it's found
Class PKC_SoulRedeemer : PK_BaseTarotCard {
	Default {
		tag "SoulRedeemer";
	}
}

//Adds 1 HP if player hasn't been damaged for 10 seconds
Class PKC_HealthRegeneration : PK_BaseTarotCard {
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

//WolrdThingDamaged checks if this is in e.DamageSource's inventory and if so, adds e.Damage value to drainedHP:
Class PKC_HealthStealer : PK_BaseTarotCard {
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

//Same as Health Regeneration but gives 1 point of armor instead:
Class PKC_HellishArmor : PK_BaseTarotCard {
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
		dmgCounter = 10;
		super.ModifyDamage(damage, damageType, newdamage, passive, inflictor, source, flags);
	}
}

//used by Hellish Armor
Class PK_HellishArmorBonus : BasicArmorBonus {
	Default {
		armor.saveamount 1;
		armor.maxsaveamount 100;
		+INVENTORY.IGNORESKILL;
	}
}

//iterates through player's inventory and sets all Ammo amount to 666 (beyond max)
Class PKC_666Ammo : PK_BaseTarotCard {
	Default {
		tag "666Ammo";
	}
	static const Class<Ammo> PKAmmoTypes[] = {
		'PK_Shells',
		'PK_FreezerAmmo',
		'PK_Stakes',
		'PK_Bombs',
		'PK_Bullets',
		'PK_ShurikenAmmo',
		'PK_Battery'
	};
	private array < Class<Ammo> > modifiedAmmo;
	private array <int> prevAmmoAmount;
	override void GetCard() {
		//give painkiller ammo if there is none
		for (int i = 0; i < PKAmmoTypes.Size(); i++) {
			let am = PKAmmoTypes[i];
			if (owner.CountInv(am) < 1)
				owner.GiveInventory(am,0); //we only need the pointers, no ammount increase
		}
		modifiedAmmo.Clear();
		//iterate through inventory, record every found ammo and its current amount in parallel into two arrays, then set amount to 666
		for(let item = owner.Inv; item; item = item.Inv) {
			let am = Ammo(item);
			if (am) {
				Class<Ammo> foundammo = am.GetClassName();
				modifiedAmmo.push(foundammo);
				prevAmmoAmount.push(owner.CountInv(foundammo));
				owner.A_SetInventory(item.GetClassName(),666,beyondMax:true);
			}
		}		
	}
	override void RemoveCard() {
		//restore original ammo amount using the two arrays
		if (modifiedAmmo.Size() < 1 || prevAmmoAmount.Size() < 1 || modifiedAmmo.Size() != prevAmmoAmount.Size())
			return;
		for (int i = 0; i < modifiedAmmo.Size(); i++)
			owner.A_SetInventory(modifiedAmmo[i],prevAmmoAmount[i]);
	}
}

//base class for golden cards. They're activated with a netevent that makes PK_CardControl call GoldenCardStart on all equipped cards
Class PK_BaseGoldenCard : PK_BaseTarotCard {
	protected bool cardActive; 
	virtual void GoldenCardStart() {
		cardActive = true;
	}
	virtual void GoldenCardEnd() {
		cardActive = false;
	}
}

//reduces received damage by 50%
Class PKC_Endurance : PK_BaseGoldenCard {
	Default {
		tag "Endurance";
	}
	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)	{
		if (cardActive && passive && damage > 0)
			newdamage = max(0, ApplyDamageFactors(GetClass(), damageType, damage, damage * 0.5));
	}
}


Class PKC_TimeBonus : PK_BaseGoldenCard {
	private PK_CardControl control;
	Default {
		tag "TimeBonus";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		control = PK_CardControl(owner.FindInventory("PK_CardControl"));
		if (!control)
			return;
		control.goldDuration = 45;
	}
	override void GoldenCardEnd() {
		if (control)
			control.goldDuration = control.default.goldDuration;
	}
}

//changes player's speed
Class PKC_Speed : PK_BaseGoldenCard {
	private double prevspeed;
	Default {
		tag "Speed";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		if (owner) {
			prevspeed = owner.speed;
			owner.speed *= 1.33;
		}
	}
	override void GoldenCardEnd() {
		if (owner) {
			owner.speed  = prevspeed;
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
		if (owner) {
			owner.GiveInventory("BlueArmorForMegasphere",1);
			owner.GiveInventory("MegasphereHealth",1);
		}
	}
}

Class PKC_Confusion : PK_BaseGoldenCard {
	private PK_MainHandler handler;
	Default {
		tag "Confusion";
	}
	override void GoldenCardStart() {
		super.GoldenCardStart();
		handler = PK_MainHandler(EventHandler.Find("PK_MainHandler"));
		if (!handler)
			return;
		for (int i = 0; i < handler.allenemies.Size(); i++) {
			if (!handler.allenemies[i])
				continue;
			let control = PK_ConfusionControl(handler.allenemies[i].FindInventory("PK_ConfusionControl"));
			if (control)
				control.active = true;
		}
	}
	override void GoldenCardEnd() {
		if (!handler)
			return;
		bool endConfusion;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo)
				continue;
			let card = PKC_Confusion(plr.mo.FindInventory("PKC_Confusion"));
			let control = PK_CardControl(plr.mo.FindInventory("PK_CardControl"));
			/*if (pk_debugmessages) {
				string conf = card ? "has Confusion" : "doesn't have Confusion";
				string cont = control ? "has CardControl" : "doesnt have CardControl";
				string gact = control.goldActive ? "gold cards are active" : "gold cards are inactive";
				console.printf("Player %d %s, %s, %s",plr.mo.PlayerNumber(),conf,cont,gact);
			}*/
			if (card && control && control.goldActive)
				continue;
			endConfusion = true;
		}
		if (endConfusion) {
			if (pk_debugmessages)
				console.printf("Nobody has active \"Confusion\"; ending effect");
			for (int i = 0; i < handler.allenemies.Size(); i++) {
				if (!handler.allenemies[i])
					continue;
				let thing = handler.allenemies[i];
				let control = PK_ConfusionControl(thing.FindInventory("PK_ConfusionControl"));
				if (control) {
					control.active = false;
					thing.target = null;
				}
			}
		}
	}
}

Class PK_ConfusionControl : PK_InventoryToken {
	private int cycle;
	bool active;
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.bISMONSTER) {
			destroy();
			return;
		}
		cycle = 1;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo)
				continue;
			let card = PKC_Confusion(plr.mo.FindInventory("PKC_Confusion"));
			let control = PK_CardControl(plr.mo.FindInventory("PK_CardControl"));
			if (card && control && control.goldActive) {
				active = true;
				break;
			}
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			destroy();
			return;
		}
		if (!active)
			return;
		if (owner.health < 1)
			return;
		if (level.time % 35 * cycle == 0) {
			cycle = random[conf](3,8);
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

Class PKC_Dexterity : PK_BaseGoldenCard {
	Default {
		tag "Dexterity";
	}
}

Class PKC_WeaponModifier : PK_BaseGoldenCard {
	Default {
		tag "WeaponModifier";
	}
}

Class PKC_StepsOfThunder : PK_BaseGoldenCard {
	Default {
		tag "StepsOfThunder";
	}
}

Class PKC_Rage : PK_BaseGoldenCard {
	Default {
		tag "Rage";
	}
}

Class PKC_MagicGun : PK_BaseGoldenCard {
	Default {
		tag "MagicGun";
	}
}

Class PKC_IronWill : PK_BaseGoldenCard {
	Default {
		tag "IronWill";
	}
}

Class PKC_Haste : PK_BaseGoldenCard {
	Default {
		tag "Haste";
	}
}