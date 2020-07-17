Class PK_Painkiller : PKWeapon {
	PK_Killer pk_killer;
	Killer_Ptarget kptarget;
	bool killer_fired;
	bool combofire;
	Default {
		+WEAPON.MELEEWEAPON;
		Obituary "%k ripped %o apart with Painkiller";
		Tag "Painkiller";
		weapon.slotnumber 1;
		inventory.pickupmessage "Picked up Painkiller";
		Tag "Painkiller";
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || level.isFrozen())
			return;
		if (owner.player.readyweapon != self && pk_killer) {
			pk_killer.SetStateLabel("XDeath");			
			killer_fired = false;
		}
	}
	states {
		Spawn:
			MODL A 1;
			loop;
		Ready:
			PKIR A 1 {
				A_WeaponOffset(0,32);
				if (invoker.pk_killer) {
					let psp = Player.FindPSprite(PSP_Weapon);
					if (psp) psp.sprite = GetSpriteIndex("PKIM");
					A_WeaponReady(WRF_NOPRIMARY);
				}
				else if (!invoker.pk_killer && invoker.killer_fired)
					return ResolveState("KillerReturn");
				else
					A_WeaponReady();
				return ResolveState(null);
			}
			loop;
		Fire:	
			TNT1 A 0 {
				if (invoker.pk_killer) {
					A_ClearRefire();
					return ResolveState("Ready");
				}
				A_WeaponOffset(0,32);
				A_StartSound("weapons/painkiller/start",CHAN_VOICE);
				return ResolveState(null);
			}
			PKIR BCDEF 1;
			TNT1 A 0 A_StartSound("weapons/painkiller/spin",CHAN_BODY,CHANF_LOOPING);
		Hold:
			TNT1 A 0 A_CustomPunch(12,true,CPF_NOTURN,"PK_PainkillerPuff",80); 
			PKIL ABCD 1 {
				if ((player.cmd.buttons & BT_ALTATTACK) && !(player.oldbuttons & BT_ALTATTACK)) {
					A_StopSound(CHAN_BODY);
					invoker.combofire = true;
					A_ClearRefire();
					return ResolveState("AltFire");
				}
				A_WeaponOffset(frandom(-0.15,0.15),frandom(32,32.3));
				return ResolveState(null);
			}
			TNT1 A 0 A_ReFire();
			TNT1 A 0 A_StartSound("weapons/painkiller/stop",CHAN_BODY);
			PKIR DCBA 1 A_WeaponReady();
			goto ready;
		AltFire:
			TNT1 A 0 {
				if (invoker.pk_killer) {
					invoker.pk_killer.SetStateLabel("XDeath");
					return ResolveState("Ready");
				}
				A_StartSound("weapons/painkiller/killer");
				if (invoker.combofire) {
					invoker.kptarget = Killer_Ptarget (Spawn("Killer_Ptarget",player.mo.pos));
					if (invoker.kptarget) {
						invoker.kptarget.master = player;
						invoker.kptarget.tracer = self.mo;
					}
					invoker.pk_killer = PK_ComboKiller(A_FireProjectile("PK_ComboKiller"));
				}
				else
					invoker.pk_killer = PK_Killer(A_FireProjectile("PK_Killer"));
				invoker.combofire = false;
				invoker.killer_fired = true;
				return ResolveState(null);
			}
			PKIM A 1 A_WeaponOffset(8, 7.8,WOF_ADD);
			PKIM A 1 A_WeaponOffset(8,12  ,WOF_ADD);
			PKIM B 1 A_WeaponOffset(8,15.6,WOF_ADD);
			PKIM BCC 1 A_WeaponOffset(-5,-2.6,WOF_ADD);
			PKIM BBA 1 {
				A_WeaponOffset(-2,-6  ,WOF_ADD);
				A_WeaponReady(WRF_NOBOB);
			}
			PKIM AAA 1 {
				A_WeaponOffset(-1,-1.3,WOF_ADD);
				A_WeaponReady(WRF_NOBOB);
			}
			goto ready;
		KillerReturn:
			TNT1 A 0 {
				invoker.pk_killer = null;
				invoker.killer_fired = false;
				//A_StartSound("weapons/painkiller/killerback");
			}
			PKIM A 1 A_WeaponOffset(12,11.7,WOF_ADD);
			PKIM B 1 A_WeaponOffset(12,18  ,WOF_ADD);
			PKIM C 1 A_WeaponOffset(12,23.4,WOF_ADD);
			PKIR AAA 1 A_WeaponOffset(-7.5,-3.9,WOF_ADD);
			PKIR AAA 1 {
				A_WeaponOffset(-3,-9  ,WOF_ADD);
				A_WeaponReady(WRF_NOBOB);
			}
			PKIR AAA 1 {
				A_WeaponOffset(-1.5,-1.95,WOF_ADD);
				A_WeaponReady(WRF_NOBOB);
			}
			goto ready;
	}
}
	
Class PK_PainkillerPuff : PKPuff {
	Default {
		Seesound "weapons/painkiller/hit";
		Attacksound "weapons/painkiller/hitwall";
		+NODAMAGETHRUST
		+PUFFONACTORS
	}
}
	
Class PK_Killer : PK_Projectile {
	bool returning;
	Default {
		PK_Projectile.flarecolor 'yellow';
		PK_Projectile.flarescale 0.09;
		PK_Projectile.flarealpha 0.7;
		+SKYEXPLODE
		+NOEXTREMEDEATH
		+NODAMAGETHRUST
		projectile;
		scale 0.3;
		damage (15);
		speed 25;
		radius 2;
		height 2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (self.GetClassName() != "PK_Killer")
			return;
		let a = Spawn("PK_KillerRail",pos);
		if (a && target) {
			a.master = self;
			a.target = target;
		}
	}
	states {
		Spawn:
			KILR A 1;
			wait;
		Death.Sky:
		Crash:
		XDeath:
			#### # 0 {					
				A_Stop();
				bNOCLIP = true;
				returning = true;
			}
			#### # 1 {
				if (target) {
					vel = Vec3To(target).Unit() * 30;
					if (Distance3D(target) <= 320)
						A_StartSound("weapons/painkiller/return",CHAN_AUTO,CHANF_NOSTOP);
					A_FaceTarget(flags:FAF_MIDDLE);
					if (Distance3D(target) <= 64) {
						target.A_StartSound("weapons/painkiller/killerback",CHAN_AUTO);
						let pkl = PK_Painkiller(target.FindInventory("PK_Painkiller"));
						if (pkl && pkl.kptarget)
							pkl.kptarget.destroy();
						destroy();
						return;
					}
				}
			}
			wait;
		Death:
			KILR A 1;
			loop;
	}
}

Class Killer_Ptarget : PK_SmallDebris {
	Default {
		+FORCEXYBILLBOARD
		+NOINTERACTION
		+BRIGHT
		renderstyle 'Add';
		alpha 0.9;
		scale 0.02;
		gravity 0;
	}
	override void Tick() {
		super.Tick();
		if (!master || !tracer || tracer.bKILLED) {
			destroy();
			return;
		}
		Vector3 ofs = tracer.pos+(0,0,master.player.viewz - tracer.pos.z);
		Vector3 x, y, z;
		[x, y, z] = Matrix4.getaxes(tracer.pitch,tracer.angle,tracer.roll);
		SetOrigin(ofs+x*16-z*3.5,true);
	}
	states {
	Spawn:
		FLAR H 1 {
			if (master && master.player.readyweapon.GetClassName != "PK_Painkiller")
				A_FadeOut(0.1,FTF_CLAMP);
			else
				A_FadeInt(0.1,FTF_CLAMP);
		}
		loop;
	}
}
	
Class PK_KillerRail : Actor {
	Default {
		+NOINTERACTION;
		radius 2;
		height 2;
	}
	override void Tick() {
		super.Tick();
		if (level.isFrozen())
			return;
		if (!master) {
			if (target)
				target.A_StopSound(CHAN_VOICE);
			destroy();
			return;
		}
		A_FaceTarget(flags:FAF_MIDDLE);
		let adiff = DeltaAngle(angle,target.angle);
		//Console.Printf("Delta angle: %f",adiff);
		SetOrigin(master.pos,true);
		if (adiff < 163 && adiff > -170) {
			target.A_StopSound(CHAN_VOICE);
			return;
		}
		if (!CheckLOF(flags:CLOFF_SKIPENEMY)) {
			target.A_StopSound(CHAN_VOICE);
			return;
		}
		/*let dist = Distance3D(target);
		A_CustomRailgun(0,0,"","ffd28e",RGF_SILENT|RGF_FULLBRIGHT|RGF_CENTERZ,0,1.6,"PK_NullPuff",range:dist,duration:1,sparsity:0.1,driftspeed:0);
		A_CustomRailgun(0,0,"","fdfbb0",RGF_SILENT|RGF_FULLBRIGHT|RGF_CENTERZ,0,1,"PK_NullPuff",range:dist,duration:1,sparsity:0.1,driftspeed:0);
		A_CustomRailgun(0,0,"","white",RGF_SILENT|RGF_FULLBRIGHT|RGF_CENTERZ,0,0.3,"PK_NullPuff",range:dist,duration:1,sparsity:0.15,driftspeed:0);*/
		PK_TrackingBeam beam = PK_TrackingBeam.MakeBeam("PK_TrackingBeam",self,target,"fca800",radius: 4.0, targetOffset: (8,0,target.height*0.5),style: STYLE_ADDSHADED);
		if(beam)
			beam.alpha = 3.0;
		target.A_StartSound("weapons/painkiller/laser",CHAN_VOICE,CHANF_LOOPING,volume:0.5);
	}
		
	states {
		Spawn:
			TNT1 A 1;
			loop;
	}
}

Class PK_ComboKiller : PK_Killer {
	Default {
		PK_Projectile.flarecolor "";
		+SKYEXPLODE
		-NOEXTREMEDEATH
		+EXTREMEDEATH
		+FLATSPRITE
		+ROLLSPRITE
		+ROLLCENTER
		Xscale 0.31;
		YScale 0.2573;
		damage (40);
		speed 12;
		radius 4;
		height 4;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		A_StartSound("weapons/painkiller/spin",CHAN_BODY,CHANF_LOOPING);
		if (target)
			pitch = target.pitch-90;
	}
	states {
		Spawn:
			KBLD A 1 A_SetRoll(roll-40,SPF_INTERPOLATE);
			wait;
		Death:
		XDeath:
			#### # 0 A_StopSound(CHAN_BODY);
			goto super::XDeath;
	}
}		