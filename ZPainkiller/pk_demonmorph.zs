Class PK_Soul : Inventory {
	protected int age;
	Default {
		inventory.pickupmessage "";
		inventory.amount 1;
		inventory.maxamount 200;
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 1;
		xscale 0.25;
		yscale 0.2;
		inventory.pickupsound "pickups/soul";
		+BRIGHT;
	}
	override void Tick() {
		super.Tick();
		if (!isFrozen())
			age++;
	}
	override void PlayPickupSound (Actor toucher)
	{
		double atten;
		int chan;
		int flags = 0;

		if (bNoAttenPickupSound)
		{
			atten = ATTN_NONE;
		}
		else
		{
			atten = ATTN_NORM;
		}

		if (toucher != NULL && toucher.CheckLocalView())
		{
			chan = CHAN_ITEM;
			flags = CHANF_NOPAUSE | CHANF_MAYBE_LOCAL | CHANF_OVERLAP;
		}
		else
		{
			chan = CHAN_ITEM;
			flags = CHANF_MAYBE_LOCAL;
		}
		toucher.A_StartSound(PickupSound, chan, flags, 1, atten);
	}
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		if (cont.pk_souls >= cont.pk_minsouls && !other.FindInventory("PK_DemonWeapon")) {
			other.GiveInventory("PK_DemonWeapon",1);			
			let dew = PK_DemonWeapon(other.FindInventory("PK_DemonWeapon"));
			if (dew) {
				if (other.player.readyweapon)
					dew.prevweapon = other.player.readyweapon;
				other.player.readyweapon = dew;
				let psp = other.player.GetPSprite(PSP_WEAPON);
				if (psp) {
					other.player.SetPSprite(PSP_WEAPON,dew.FindState("Ready"));
					psp.y = WEAPONTOP;
				}
				else
					Console.printf("something went really wrong");
			}
		}
		other.GiveBody(Amount, MaxAmount);
		GoAwayAndDie();
		return true;
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,random[soul](1,20));
		DSOU ABCDEFGHIJKLMNOPQRSTU 2 {
			if (age > 35*10)
				A_FadeOut(0.05);
		}
		goto spawn+1;
	}
}

Class PK_RedSoul : PK_Soul {
	Default {
		inventory.amount 10;
		translation "0:255=%[0.00,0.00,0.00]:[2.00,0.00,0.00]";
		alpha 0.85;
		inventory.pickupsound "pickups/soul/red";
	}
}

Class PK_SlowMoControl : Inventory {
	private double p_gravity;
	private double p_speed;
	private vector3 p_vel;
	private state slowstate;
	private int p_renderstyle;
	private double p_alpha;
	private color p_color;
	private double slowfactor;
	property slowfactor : slowfactor;
	Default {
		PK_SlowMoControl.slowfactor 0.25;
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
	}
	override void Tick() {}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner) {
			return;
		}
		// monsters will be slowed down:
		if (owner.bISMONSTER) {
			p_gravity = owner.gravity;
			owner.gravity *= slowfactor;
			p_speed = owner.speed;
			owner.speed *= slowfactor;		
			let img = Spawn("PK_SlowMoAfterImage",owner.pos);
			if (img) {
				img.master = owner;
			}
		}
		// change vel for projectiles and debris (non-missile actors that don't have speed defined, like PK_RandomDebris)
		if (!owner.bMISSILE) {
			p_vel = owner.vel;
			owner.vel *= slowfactor*0.5;
		}
		// monsters and enemy players will be colorized:
		if (owner.bISMONSTER || (owner.player && owner.player != players[consoleplayer])) {
			owner.bBRIGHT = true;
			p_renderstyle = owner.GetRenderstyle();
			p_alpha = owner.alpha;
			p_color = owner.fillcolor;
			owner.A_SetRenderstyle(1.0,Style_Stencil);
			owner.SetShade("ff00ff");
		}
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			DepleteOrDestroy();
			return;
		}
		if (owner.isFrozen())
			return;
		if (owner.player)
			return;		
		for (int i = 7; i >= 0; i--)
			owner.A_SoundPitch(i,0.8);
		if(owner.CurState != slowstate) {
			owner.A_SetTics(owner.tics*2);
			slowstate = Owner.CurState;
		}
	}
	override void DetachFromOwner() {
		if (!owner) {
			return;
		}
		owner.bBRIGHT = owner.default.bBRIGHT;
		if (owner.bISMONSTER) {
			owner.gravity = p_gravity;
			owner.speed = p_speed;
		}
		if (!owner.bISMONSTER && !owner.speed && !owner.player)
			owner.vel = p_vel;
		if (owner.bISMONSTER || (owner.player && owner.player != players[consoleplayer])) {
			owner.A_SetRenderstyle(p_alpha,p_renderstyle);
			owner.SetShade(p_color);
		}
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

Class PK_DemonMorphControl : Inventory {
	int pk_souls;
	int pk_minsouls;
	int pk_fullsouls;
	property minsouls : pk_minsouls;
	property fullsouls : pk_fullsouls;
	Default {
		PK_DemonMorphControl.minsouls 4;
		PK_DemonMorphControl.fullsouls 6;
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
	Default {
		+WEAPON.NOAUTOFIRE;
		+WEAPON.DONTBOB;
		+WEAPON.CHEATNOTWEAPON;
		weapon.upsound "";
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner || !owner.player)
			return;
		control = PK_DemonMorphControl(owner.FindInventory("PK_DemonMorphControl"));
		minsouls = control.pk_minsouls;
		fullsouls = control.pk_fullsouls;
		dur = 25;
		owner.A_StartSound("demon/start",CHAN_AUTO,flags:CHANF_LOCAL);
		if(players[consoleplayer] == owner.player)   {
			owner.A_StartSound("demon/loop",66,CHANF_LOOPING,attenuation:20);
			//S_PauseSound (false, false);
			SetMusicVolume(0);
		}
		owner.bNODAMAGE = true;
		owner.bNOBLOOD = true;
		owner.bNOPAIN = true;
		p_speed = owner.speed;
		p_gravity = owner.gravity;
		if (control.pk_souls >= fullsouls) {
			owner.speed *= 0.6;
			owner.gravity *= 0.6;
		}
		owner.player.mo.viewbob = 0.2;		
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
	}	
	override void DetachFromOwner() {
		if(players[consoleplayer] == owner.player)   {
			owner.A_StopSound(66);
			//S_ResumeSound (false);
			SetMusicVolume(1);
		}		
		owner.A_StartSound("demon/end",CHAN_AUTO,CHANF_LOCAL);
		owner.bNODAMAGE = owner.default.bNODAMAGE;
		owner.bNOBLOOD = owner.default.bNOBLOOD;
		owner.bNOPAIN = owner.default.bNOPAIN;
		owner.speed = p_speed;
		owner.gravity = p_gravity;
		owner.player.mo.viewbob = owner.player.mo.default.viewbob;
		if (owner.player.readyweapon)
			owner.player.readyweapon.crosshair = 0;
		owner.player.SetPsprite(66,null);
		super.DetachFromOwner();
	}
	states {
	Ready:
		TNT1 A 1 {
			A_Overlay(66,"DemonCross");
			let psp = player.GetPSprite(PSP_WEAPON);
			psp.y = WEAPONTOP;
			A_WeaponOffset(0,0);
			if (invoker.control && invoker.control.pk_souls >= invoker.fullsouls)
				A_WeaponReady(WRF_NOSWITCH|WRF_NOBOB);
		}
		loop;
	Fire:
		TNT1 A 20 {
			A_WeaponOffset(0,0);
			A_StartSound("demon/fire",CHAN_AUTO);
			A_FireBullets(5,5,50,50,"PK_NullPuff",FBF_NORANDOM);
		}
		goto ready;
	DemonCross:
		DCRH A 25 {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
			A_OverlayAlpha(OverlayID(),0.5);
		}
		stop;
	}
}