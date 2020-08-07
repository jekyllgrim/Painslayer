Class PK_Soul : PK_Inventory {
	protected int age;
	Default {
		inventory.pickupmessage "";
		inventory.amount 3;
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
	override bool TryPickup (in out Actor other) {
		if (!(other is "PlayerPawn"))
			return false;
		let cont = PK_DemonMorphControl(other.FindInventory("PK_DemonMorphControl"));
		if (cont)
			cont.pk_souls += 1;
		if (cont.pk_souls >= cont.pk_minsouls && !other.FindInventory("PK_DemonWeapon")) {
			let weap = other.player.readyweapon;
			other.GiveInventory("PK_DemonWeapon",1);			
			let dew = PK_DemonWeapon(other.FindInventory("PK_DemonWeapon"));
			if (dew) {
				if (weap) {
					//console.printf("prev weapon %s",weap.GetClassName());
					dew.prevweapon = weap;
				}
				other.player.readyweapon = dew;
				let psp = other.player.GetPSprite(PSP_WEAPON);
				if (psp) {
					other.player.SetPSprite(PSP_WEAPON,dew.FindState("Ready"));
					psp.y = WEAPONTOP;
				}
				/*else
					Console.printf("something went really wrong");*/
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
		inventory.amount 20;
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
	private double speedfactor;
	private double gravityfactor;
	property speedfactor : speedfactor;
	property gravityfactor : gravityfactor;
	Default {
		PK_SlowMoControl.speedfactor 0.5;
		PK_SlowMoControl.gravityfactor 0.2;
		inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE;
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNCLEARABLE;
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

Class PK_DemonMorphControl : Inventory {
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
				Shader.SetUniform1f(players[consoleplayer], "DemonMorph", "rippleTimer", 0 );
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