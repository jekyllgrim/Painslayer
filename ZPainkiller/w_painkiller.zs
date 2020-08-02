Class PK_Painkiller : PKWeapon {
	PK_Killer pk_killer;
	bool beam;
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
	states {
		Spawn:
			MODL A 1;
			loop;
		BeamFlare:
			PKOF A -1 bright {
				A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE,true);
				A_OverlayRenderstyle(OverlayID(),STYLE_Add);
			}
			stop;
		Ready:
			PKIR A 1 {
				A_WeaponOffset(0,32);
				if (invoker.beam)
					A_Overlay(-5,"BeamFlare");
				else
					A_ClearOverlays(-5,-5);
				if (invoker.pk_killer) {
					let psp = Player.FindPSprite(PSP_Weapon);
					if (psp) 
						psp.sprite = GetSpriteIndex("PKIM");
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
			TNT1 A 0 A_StartSound("weapons/painkiller/spin",12,CHANF_LOOPING);
		Hold:
			TNT1 A 0 A_CustomPunch(12,true,CPF_NOTURN,"PK_PainkillerPuff",80); 
			PKIL ABCD 1 {
				if ((player.cmd.buttons & BT_ALTATTACK) && !(player.oldbuttons & BT_ALTATTACK)) {
					A_StopSound(12);
					invoker.combofire = true;
					A_ClearRefire();
					return ResolveState("AltFire");
				}
				A_WeaponOffset(frandom(-0.15,0.15),frandom(32,32.3));
				return ResolveState(null);
			}
			TNT1 A 0 A_ReFire();
			TNT1 A 0 {
				A_StopSound(12);
				A_StartSound("weapons/painkiller/stop",CHAN_BODY);
			}
			PKIR DCBA 1 A_WeaponReady();
			goto ready;
		AltFire:
			TNT1 A 0 {
				if (invoker.pk_killer) {
					if (!(player.oldbuttons & BT_ALTATTACK))
						invoker.pk_killer.SetStateLabel("XDeath");
					return ResolveState("Ready");
				}
				else if (player.oldbuttons & BT_ALTATTACK)
					return ResolveState("Ready");
				A_StartSound("weapons/painkiller/killer");
				if (invoker.combofire) {
					invoker.pk_killer = PK_ComboKiller(A_FireProjectile("PK_ComboKiller"));
				}
				else {
					invoker.pk_killer = PK_Killer(A_FireProjectile("PK_Killer"));
				}
				A_WeaponOffset(0,32,WOF_INTERPOLATE);
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
		PK_Projectile.flarecolor "fed101";
		PK_Projectile.flarescale 0.2;
		PK_Projectile.flarealpha 0.75;
		PK_Projectile.flareactor "PK_KillerFlare";
		+SKYEXPLODE
		+NOEXTREMEDEATH
		+NODAMAGETHRUST
		+HITTRACER
		projectile;
		scale 0.3;
		damage (15);
		speed 25;
		radius 4;
		height 4;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (self.GetClassName() != "PK_Killer" || !target) {
			return;
		}	
		A_FaceMovementDirection(0,0,0);
		actor emit = Spawn("Killer_BeamEmitter",pos);
		if (emit) {
			emit.master = target;
			emit.tracer = self;
			emit.pitch = pitch;
			//console.printf("killer pitch %d", pitch);
		}
	}
	override void Tick() {
		super.Tick();
		if (isFrozen() || !target)
			return;
		if (target.player.readyweapon && !(target.player.readyweapon is "PK_Painkiller") && !InStateSequence(curstate,FindState("XDeath")))
			SetStateLabel("XDeath");
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
				if (!target || !tracer || GetClassName() != "PK_Killer")
					return ResolveState(null);
				name tracername = tracer.GetClassName();
				if (tracer.bKILLED || tracername == "KillerFlyTarget") {
					if (!tracer.target)
						tracer.target = target;
					tracer.A_FaceTarget();
					double dist = tracer.Distance2D(target);			//horizontal distance to target
					double vdisp = target.pos.z - tracer.pos.z;		//height difference between gib and target + randomized height
					double ftime = 20;									//time of flight					
					double vvel = (vdisp + 0.5 * ftime*ftime) / ftime;
					double hvel = (dist / ftime) * -0.8;		
					tracer.VelFromAngle(hvel,angle);
					tracer.vel.z = vvel;
					let kft = KillerFlyTarget(tracer);
					if (kft) {
						kft.hitcounter++;
						if (tracer.target && kft.hitcounter % 3 == 0)
							tracer.target.A_NoBlocking();
					}
				}
				return ResolveState(null);
			}
			#### # 1 {
				if (target) {
					vel = Vec3To(target).Unit() * 30;
					if (Distance3D(target) <= 320)
						A_StartSound("weapons/painkiller/return",CHAN_AUTO,CHANF_NOSTOP);
					A_FaceTarget(flags:FAF_MIDDLE);
					if (Distance3D(target) <= 64) {
						target.A_StartSound("weapons/painkiller/killerback",CHAN_AUTO);
						let pk = PK_Painkiller(target.FindInventory("PK_Painkiller"));
						if (pk && target.player && target.player.readyweapon && target.player.readyweapon != pk)
							pk.killer_fired = false;
						destroy();
						return;
					}
				}
			}
			wait;
		Death:
			KILR A -1 {
				if (tracer && tracer.GetClassName() == "KillerFlyTarget")
					return ResolveState("XDeath");
				A_StartSound("weapons/painkiller/stuck",attenuation:2);
				return ResolveState(null);
			}
			stop;
	}
}

Class PK_KillerFlare : PK_ProjFlare {
	Default {
		renderstyle 'add';
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		if (scale.x > 0.06)
			scale *= 0.96;
		else
			A_SetScale(0.18);
	}
	states {
	Spawn:
		FLAR B -1;
		stop;
	}
}


Class KillerFlyTarget : Actor {
	int hitcounter;
	Default {
		+NODAMAGE
		+SOLID
		+CANPASS
		+DROPOFF
		+NOTELEPORT
		renderstyle 'none';
	}
	override void Tick() {
		super.Tick();
		if (!target) {
			destroy();
			return;
		}
		target.SetOrigin(pos,true);
	}
	override bool CanCollideWith (Actor other, bool passive) {
		if (other.GetClassName() == "PK_Killer" && passive) {
			//console.printf("hitcounter %d",hitcounter);
			//if (hitcounter % 3 == 0 && target)
				//target.A_NoBlocking();
			return true;
		}
		return false;
	}
	states {
	Spawn:
		BAL1 A -1;
		stop;
	}
}
		

Class Killer_BeamEmitter : Actor {
	Default {
		radius 1;
		height 1;
	}
	PK_TrackingBeam beam1;
	PK_TrackingBeam beam2;
	protected string prevspecies;
	void StartBeams() {
		if (!master)
			return;
		let weap = PK_Painkiller(master.FindInventory("PK_Painkiller"));
		if (weap)
			weap.beam = true;
		string curspecies = master.species;
		if (curspecies.IndexOf("PKPlayerSpecies") < 0) {
			prevspecies = master.species;
			master.species = String.Format("PKPlayerSpecies%d",master.PlayerNumber());
			species = master.species;
			//Console.printf("master species: %s",master.species);
		}
		beam1 = PK_TrackingBeam.MakeBeam("PK_TrackingBeam",master,tracer,"f2ac21",radius: 9.0,masterOffset:(13,13,12), style: STYLE_ADDSHADED);
		if(beam1) {
			beam1.alpha = 0.5;
		}
		beam2 = PK_TrackingBeam.MakeBeam("PK_TrackingBeam",master,tracer,"FFFFFF",radius: 1.6,masterOffset:(13,13,12),style: STYLE_ADDSHADED);
		if(beam2) {
			beam2.alpha = 3.0;
		}
		master.A_StartSound("weapons/painkiller/laser",CHAN_VOICE,CHANF_LOOPING,volume:0.5);
	}	
	void StopBeams() {
		if (master) {
			master.A_StopSound(CHAN_VOICE);
			let weap = PK_Painkiller(master.FindInventory("PK_Painkiller"));
			if (weap)
				weap.beam = false;
			string curspecies = master.species;
			if (curspecies.IndexOf("PKPlayerSpecies") >= 0) {
				master.species = prevspecies;
				//Console.printf("master species: %s",master.species);
			}
		}
		if(beam1) {
			beam1.destroy();
		}
		if(beam2)
			beam2.destroy();
	}	
	override void Tick() {
		if (!master || !tracer) {
			StopBeams();
			destroy();
			return;
		}
		SetOrigin(tracer.pos,true);
		A_FaceMaster(0,0,flags:FAF_MIDDLE);
		let adiff = DeltaAngle(angle,master.angle);
		if (adiff < 163 && adiff > -170) {
			StopBeams();
			return;
		}
		let pdiff = abs(pitch - -master.pitch);
		//console.printf("pitch %d | master pitch %d | diff %d",pitch,master.pitch,pdiff);
		if (pdiff > 10) {
			StopBeams();
			return;
		}
		/*FLineTraceData data;
		LineTrace(angle,4096,pitch,data:data);
		if (data.HitType == TRACE_HITWALL) {
			StopBeams();
			return;
		}*/
		if (!CheckSight(master,SF_IGNOREWATERBOUNDARY)) {
			StopBeams();
			return;
		}
		StartBeams();		
		A_CustomRailGun(2,color1:"FFFFFF",flags:RGF_SILENT,pufftype:"KillerBeamPuff",range:Distance3D(master),duration:1,sparsity:1024);
	}
}

Class KillerBeamPuff : Actor {
	Default {
		+PAINLESS
		+NOEXTREMEDEATH
		+NODAMAGETHRUST
		+ALLOWTHRUFLAGS
		+MTHRUSPECIES
		+HITTRACER
		+ALWAYSPUFF
	}	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (tracer) {
			//Console.Printf("beam tracer: %s",tracer.GetClassName());
			tracer.A_StartSound("weapons/painkiller/laserhit",CHAN_VOICE,CHANF_NOSTOP,volume:0.8,attenuation:4);
		}
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
		Xscale 0.31;
		YScale 0.2573;
		damage (80);
		speed 10;
		radius 2;
		height 2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		A_StartSound("weapons/painkiller/spin",CHAN_BODY,CHANF_LOOPING);
		if (target)
			pitch = target.pitch-90;
	}
	states {
		Spawn:
			KBLD A 1 A_SetRoll(roll+80,SPF_INTERPOLATE);
			wait;
		Death:
		XDeath:
			#### # 0 A_StopSound(CHAN_BODY);
			goto super::XDeath;
	}
}		