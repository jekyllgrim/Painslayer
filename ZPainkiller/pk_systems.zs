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
		PK_DemonMorphControl.minsouls 10;
		PK_DemonMorphControl.fullsouls 12;
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
	private bool goldCardsUses;
	property goldCardsUses : goldCardsUses;
	
	Default {
		PK_CardControl.goldCardsUses 1;
	}
	
	override void Tick() {}
	
	void PK_EquipCards() {
		EquippedCards.Clear();
		EquippedCards.Reserve(5);			
		console.printf("Allocated %d card slots successfully",EquippedCards.Size());	
		
		//give the equipped cards:
		for (int i = 0; i < EquippedCards.Size(); i++) {
			//construct card classname based on card ID from ui
			name cardClassName = String.Format("PKC_%s",EquippedSlots[i]);
			//turn that into a class type
			Class<Inventory> card = cardClassName;
			//if the slot card ID is empty, make sure the slot is empty too (and if there was a card in it before, remove it)
			if (!card) {
				console.printf("Slot %d is empty (\"%s:\" is not a valid class)",i,cardClassName);
				continue;
			}
			//record new class type in a slot
			EquippedCards[i] = card;
			//if player has no card class of that type, give it to them
			if (!owner.FindInventory(card)) {
				owner.GiveInventory(card,1);
			}
			if (owner.FindInventory(card))
				console.printf("%s is in slot %d",owner.FindInventory(card).GetClassName(),i);
		}
		//if player has some cards that are NOT equipped, take them away:
		for (int unC = 0; unC < UnlockedTarotCards.Size(); unC++) {
			//construct card classname based on card ID from ui
			name cardClassName = String.Format("PKC_%s",UnlockedTarotCards[unC]);
			//turn that into an actual class type
			Class<Inventory> card = cardClassName;
			//check if it's a valid class type
			if (!card) {
				console.printf("Tried taking \"%s\" but it's not a valid class",cardClassName);
				continue;
			}
			//check the player even has it
			if (!owner.FindInventory(card)) {
				continue;
			}
			//check every unlocked card name against every equipped card name
			//(for simplicity and speed we're checking names here, not classes)
			bool isEquipped = false;
			for (int curC = 0; curC < 5; curC++) {
				if (EquippedSlots[curC] == UnlockedTarotCards[unC]) {
					isEquipped = true;
					break;
				}
			}
			if (!isEquipped) {	
				console.printf("Taking card %s (not equipped)",owner.FindInventory(card).GetClassName());
				owner.TakeInventory(card,1);
			}
		}
		/*console.printf("Equipped: [%s] [%s] [%s] [%s] [%s]",
			(EquippedCards[0] != null) ? "yes" : "x",
			(EquippedCards[1] != null) ? "yes" : "x",
			(EquippedCards[2] != null) ? "yes" : "x",
			(EquippedCards[3] != null) ? "yes" : "x",
			(EquippedCards[4] != null) ? "yes" : "x"
		);*/
	}
}

Class PKC_SoulKeeper : PK_InventoryToken {
	PK_BoardEventHandler event;
	
	Default {
		tag "SoulKeeper";
	}
	
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.player) {
			DepleteOrDestroy();
			return;
		}
		event = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (event)
			event.SoulKeeper = true;
	}	
	override void DetachFromOwner() {
		if (!owner || !owner.player) {
			DepleteOrDestroy();
			return;
		}
		PKC_SoulKeeper card;
		for (int pn = 0; pn < MAXPLAYERS; pn++) {
			if (!playerInGame[pn])
				continue;
			PlayerInfo plr = players[pn];
			if (!plr || !plr.mo || plr.mo == owner)
				continue;
			card = PKC_SoulKeeper(plr.mo.FindInventory("PKC_SoulKeeper"));
			if (card)
				break;
		}
		if (!card && event)
			event.SoulKeeper = false;
		super.DetachFromOwner();
	}
}

Class PKC_Blessing : PK_InventoryToken {
	Default {
		tag "Blessing";
	}
}

Class PKC_Replenish : PK_InventoryToken {
	Default {
		tag "Replenish";
	}
}

Class PKC_DarkSoul : PK_InventoryToken {
	Default {
		tag "DarkSoul";
	}
}

Class PKC_SoulCatcher : PK_InventoryToken {
	Default {
		tag "SoulCatcher";
	}
}

Class PKC_Forgiveness : PK_InventoryToken {
	Default {
		tag "Forgiveness";
	}
}

Class PKC_Greed : PK_InventoryToken {
	Default {
		tag "Greed";
	}
}

Class PKC_SoulRedeemer : PK_InventoryToken {
	Default {
		tag "SoulRedeemer";
	}
}

Class PKC_HealthRegeneration : PK_InventoryToken {
	Default {
		tag "HealthRegeneration";
	}
}

Class PKC_HealthStealer : PK_InventoryToken {
	Default {
		tag "HealthStealer";
	}
}

Class PKC_HellishArmor : PK_InventoryToken {
	Default {
		tag "HellishArmor";
	}
}

Class PKC_666Ammo : PK_InventoryToken {
	Default {
		tag "666Ammo";
	}
}

Class PKC_Endurance : PK_InventoryToken {
	Default {
		tag "Endurance";
	}
}

Class PKC_TimeBonus : PK_InventoryToken {
	Default {
		tag "TimeBonus";
	}
}

Class PKC_Speed : PK_InventoryToken {
	Default {
		tag "Speed";
	}
}

Class PKC_Rebirth : PK_InventoryToken {
	Default {
		tag "Rebirth";
	}
}

Class PKC_Confusion : PK_InventoryToken {
	Default {
		tag "Confusion";
	}
}

Class PKC_Dexterity : PK_InventoryToken {
	Default {
		tag "Dexterity";
	}
}

Class PKC_WeaponModifier : PK_InventoryToken {
	Default {
		tag "WeaponModifier";
	}
}

Class PKC_StepsOfThunder : PK_InventoryToken {
	Default {
		tag "StepsOfThunder";
	}
}

Class PKC_Rage : PK_InventoryToken {
	Default {
		tag "Rage";
	}
}

Class PKC_MagicGun : PK_InventoryToken {
	Default {
		tag "MagicGun";
	}
}

Class PKC_IronWill : PK_InventoryToken {
	Default {
		tag "IronWill";
	}
}

Class PKC_Haste : PK_InventoryToken {
	Default {
		tag "Haste";
	}
}