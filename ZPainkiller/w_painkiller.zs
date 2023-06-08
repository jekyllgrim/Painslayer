Class PK_Painkiller : PKWeapon {
	PK_Killer pk_killer;
	bool beam;
	bool killer_fired;
	bool combofire;
	protected double wmodAlpha;
	private int wmodCounter;

	Default {
		+WEAPON.MELEEWEAPON;
		PKWeapon.ammoSwitchCVar 'pk_switch_Painkiller';
		Obituary "$PKO_PAIN";
		Tag "Painkiller";
		weapon.slotnumber 1;
		inventory.pickupmessage "$PKI_PAINKILLER";
		inventory.icon "PKWIG0";
		Tag "$PK_PAINKILLER_TAG";
		+PKWeapon.NOICON
	}

	states {
	Spawn:
		PKWI G -1;
		stop;
	BeamFlare:
		PKOF A -1 bright {
			A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE,true);
			A_OverlayRenderstyle(OverlayID(),STYLE_Add);
		}
		stop;
	Ready:
		PKIR A 1 {
			A_WeaponOffset(0,32);
			let bm = player.FindPSprite(PSP_UNDERGUN);
			if (invoker.beam && !bm)
				A_Overlay(PSP_UNDERGUN,"BeamFlare");
			else if (!invoker.beam && bm)
				A_Overlay(PSP_UNDERGUN,null);
			/*if (invoker.beam)
				A_Overlay(PSP_UNDERGUN,"BeamFlare");
			else
				A_Overlay(PSP_UNDERGUN,null);*/
			if (invoker.pk_killer) {
				let psp = Player.FindPSprite(PSP_Weapon);
				if (psp) 
					psp.sprite = GetSpriteIndex("PKIM");
				PK_WeaponReady(WRF_NOPRIMARY);
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
			PK_AttackSound("weapons/painkiller/start",CHAN_VOICE);
			invoker.wmodAlpha = 0;
			invoker.wmodCounter = 0;
			return ResolveState(null);
		}
		PKIR BCDEF 1;
		TNT1 A 0 {
			A_StartSound("weapons/painkiller/spin",CH_LOOP,CHANF_LOOPING);
			return ResolveState("Hold");
		}
		goto ready;
	Hold:
		TNT1 A 0 {
			A_CustomPunch(12,true,CPF_NOTURN,"PK_PainkillerPuff",80); 
			if (invoker.hasWmod) {
				A_Overlay(PSP_OVERGUN,"Hold.Mod");
				A_OverlayRenderstyle(PSP_OVERGUN,Style_AddShaded);
				A_OverlayFlags(PSP_OVERGUN,PSPF_ALPHA|PSPF_FORCEALPHA,true);
				A_OverlayAlpha(PSP_OVERGUN,invoker.wmodAlpha);
			}
		}
		PKIL ABCD 1 {
			double spitch = 1.0;	
			let psp = Player.FindPSprite(OverlayID());			
			if (invoker.hasWmod) {
				if (invoker.wmodCounter >= 3) {
					invoker.wmodCounter = 0;
					A_SetTics(0);
				}		
				spitch += 0.05;
				if (invoker.wmodAlpha < 1)
					invoker.wmodAlpha += 0.07;
				invoker.wmodCounter++;		
				let fr = Player.FindPSprite(PSP_OVERGUN);
				if (psp && fr)
					fr.frame = psp.frame;
			}
			if (invoker.hasDexterity) {
				spitch += 0.1;
				invoker.wmodCounter++;	
				if (random[sfx](0,1) == 1) {
					if (psp && psp.frame < 3)
						psp.frame++;
				}
			}		
			A_SoundPitch(CH_LOOP,spitch);
			if (PressingAttackButton(secondary: true, holdCheck: PAB_NOTHELD)) {
				A_StopSound(CH_LOOP);
				invoker.combofire = true;
				A_ClearRefire();
				return ResolveState("AltFire");
			}
			A_WeaponOffset(frandom(-0.15,0.15),frandom(32,32.3));
			return ResolveState(null);
		}
		TNT1 A 0 PK_Refire();
		goto HoldEnd;
	Hold.Mod:
		PKIW ### 1 bright {
			A_OverlayAlpha(PSP_OVERGUN,invoker.wmodAlpha);
		}
		stop;
	HoldEnd:
		TNT1 A 0 {
			A_StopSound(CH_LOOP);
			A_StartSound("weapons/painkiller/stop",CHAN_BODY);
		}
		PKIR DCBA 1 A_WeaponReady();
		goto ready;
	AltFire:
		TNT1 A 0 {
			if (invoker.pk_killer) {
				if ((PressingAttackButton(secondary:true, holdCheck: PAB_NOTHELD)))
					invoker.pk_killer.SetStateLabel("XDeath");
				return ResolveState("Ready");
			}
			else if ((PressingAttackButton(secondary:true, holdCheck: PAB_HELD)))
				return ResolveState("Ready");
			A_StartSound("weapons/painkiller/killer");
			if (invoker.combofire)
				invoker.pk_killer = PK_ComboKiller(A_FireProjectile("PK_ComboKiller"));
			else {
				invoker.pk_killer = PK_Killer(A_FireProjectile("PK_Killer"));
				A_Overlay(PSP_UNDERGUN,"BeamFlare");
			}
			A_WeaponOffset(0,32,WOF_INTERPOLATE);
			invoker.combofire = false;
			invoker.killer_fired = true;
			return ResolveState(null);
		}
		PKIM ABC 1 A_WeaponOffset(9,3,WOF_ADD);
		PKIM CCC 1 {
			A_WeaponOffset(0.5,0.3,WOF_ADD);
		}
		PKIM BBBAAA 1 {
			A_WeaponReady(WRF_NOBOB);
			A_WeaponOffset(-5,-1.5,WOF_ADD);
		}
		goto ready;
	KillerReturn:
		TNT1 A 0 {
			invoker.killer_fired = false;
			//A_StartSound("weapons/painkiller/killerback");
		}
		PKIR AAA 1 {
			A_WeaponOffset(13.5,4.5,WOF_ADD);
		}
		PKIR AAA 1 {
			A_WeaponOffset(0.75,0.45,WOF_ADD);
			// If we fired a regular Killer, make the weapon ready
			// for firing instantly. If we fired a Combo Killer,
			// delay the readiness by 3 more tics:
			if (invoker.pk_killer && invoker.pk_killer.GetClass() == 'PK_Killer') {
				invoker.pk_killer = null;
			}
			if (!invoker.pk_killer)
				A_WeaponReady(WRF_NOBOB);
		}
		PKIR AAA 1 {
			invoker.pk_killer = null;
			A_WeaponReady(WRF_NOBOB);
			A_WeaponOffset(-7.125,-1.65,WOF_ADD);
		}
		PKIR AAA 1 {
			A_WeaponReady(WRF_NOBOB);
			A_WeaponOffset(-8,-3,WOF_ADD);
		}
		goto ready;
	}
}
	
Class PK_PainkillerPuff : PK_BulletPuff {
	Default {
		Seesound "weapons/painkiller/hit";
		Attacksound "weapons/painkiller/hitwall";
		decal "PKIMark";
		+NODAMAGETHRUST
		+PUFFONACTORS
	}
	states {
	Crash:
		TNT1 A 1 {			
			if (GetParticlesLevel() < PK_BaseActor.PL_REDUCED)
				return resolveState(null);

			FindLineNormal();
			if (random[sfx](0,10) > 5) {
				let deb = Spawn("PK_RandomDebris", debrisPos);
				if (deb)
					deb.vel = (hitnormal + (frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](3,5)));
			}

			if (GetParticlesLevel() < PK_BaseActor.PL_FULL)
				return resolveState(null);
			bool mod = target && PKWeapon.CheckWmod(target);
			if (mod || (random[sfx](0,10) > 2)) {
				let bull = PK_RicochetBullet(Spawn("PK_RicochetBullet", debrisPos));
				if (bull) {
					bull.vel = (hitnormal + (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](-3,3)) * frandom[sfx](2,6));
					bull.A_FaceMovementDirection();
					if (mod) {
						bull.A_SetRenderstyle(bull.alpha,Style_AddShaded);
						bull.SetShade("FF6000");
						//bull.scale *= 2;
					}
				}
			}
			return resolveState(null);
		}
		stop;
	Melee:
		TNT1 A 1;
		stop;
	}
}
	
Class PK_Killer : PK_Projectile {
	bool returning;
	Default {
		PK_Projectile.flarecolor "fed101";
		PK_Projectile.flarescale 0.2;
		PK_Projectile.flarealpha 0.75;
		PK_Projectile.flareactor "PK_KillerFlare";
		Obituary "$PKO_KILLER";
		+SKYEXPLODE
		+NOEXTREMEDEATH
		+NODAMAGETHRUST
		+HITTRACER
		projectile;
		scale 0.3;
		damage (15);
		speed 25;
		radius 2;
		height 2;
	}
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (self.GetClassName() != "PK_Killer" || !target) {
			return;
		}	
		A_FaceMovementDirection(0,0,0);
		actor emit = Spawn("Killer_BeamEmitter",pos);
		if (emit) {
			emit.target = target; //this is to track kill credit
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
	
	void ThrowBody(Actor body) {
		if (!body || !target)
			return;
		// Throw the corpse towards the player:
		body.A_FaceTarget();
		double dist = body.Distance2D(target);			//horizontal distance to target
		//make some room:
		if (dist > 32)
			dist -= 32;
		double vdisp = target.pos.z - body.pos.z;		//height difference between body and target
		double ftime = 20;									//desired time of flight
		double hvel = (dist / ftime) * -0.5 * body.gravity;		//calculate horizontal vel
		double vvel = body.bNOGRAVITY ? 0 : (vdisp + 0.5 * ftime*ftime) / ftime; //calculate vertical vel
		//Reduce velocity based on how heavy the monster is:
		double velMul = Clamp(PK_Utils.LinearMap(body.mass,300,1000,1.0,0.5), 0.5, 1.0);
		hvel *= velMul;
		//vvel *= velMul; 
		//Throw the body towards the player:
		body.VelFromAngle(hvel,angle);
		body.vel.z = vvel;
		// Finally, reduce the monster's gravity:
		body.gravity = 0.7;
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
			// The following should only execute for Killer, not for 
			// combo projectile, so return if this isn't called from
			// PK_Killer:
			if (!target || !tracer || GetClassName() != "PK_Killer")
				return null;
				
			// If Killer kills a monster, immediately throw that monster
			// towards the player (PK_KillerFlyTarget hasn't spawned yet,
			// so at this point we interact directly with the monster):
			if (tracer && tracer.health <= 0 && tracer.bISMONSTER && !tracer.bBOSS) {
				ThrowBody(tracer);
				return null;
			}
			
			// The following will drag the body if the Killer projectile
			// hits a PK_KillerFlyTarget, which is a "hitbox" actor
			// (this is to drag corpses that are already on the floor);
			if (tracer && tracer.GetClass() == "PK_KillerFlyTarget") {
				// Get a pointer to the hitbox:
				let kft = PK_KillerFlyTarget(tracer);
				// The hitbox's target is a corpse it's attached to.
				// Double-check it's valid:
				if (kft && kft.target) {
					// Get a pointer to the corpse:
					let body = kft.target;
					if (!body)
						return null;
					ThrowBody(body);
				
					// If we hit a body with a Killer projectile, spawn gold every 3 times Killer hits it:
					kft.hitcounter++;
					if (kft.hitcounter % 3 == 0) {
						Class<PK_GoldPickup> gold = "PK_SmallGold";
						//add a chance to spawn medium gold piece after a few hits:
						if (kft.hitcounter > random[gold](6,13))
							gold = "PK_MedGold";
						let goldspawn = PK_GoldPickup(Spawn(gold,tracer.target.pos));
						if (goldspawn)
							goldspawn.A_StartSound(goldspawn.pickupsound);
					}
					// PK_KillerFlyTarget is attached to PK_DeathControl.
					// Call ResetRestCounter() on PK_DeathControl in order to reset
					// the corpse's disappearing counter:
					if (kft.edc)
						kft.edc.ResetRestCounter();
				}
			}
			return null;
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
					Destroy();
					return;
				}
			}
		}
		wait;
	Death:
		KILR A -1 {
			if (tracer && tracer.GetClassName() == "PK_KillerFlyTarget")
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
		if (scale.x > 0.06) {
			scale *= 0.96;
			alpha *= 0.98;
		}
		else {
			A_SetScale(0.18);
			alpha = default.alpha;
		}
	}
	states {
	Spawn:
		FLAR B -1;
		stop;
	}
}


Class PK_KillerFlyTarget : Actor {
	int hitcounter;
	PK_EnemyDeathControl edc;
	Default {
		+SOLID
		+CANPASS
		+DROPOFF
		+NOTELEPORT
		renderstyle 'none';
		//gravity 0.7;
		+NOGRAVITY
	}
	
	override void Tick() {
		super.Tick();
		if (!target) {
			Destroy();
			return;
		}
		SetOrigin(target.pos,true);
		if (target.vel ~== (0,0,0))
			target.gravity = target.default.gravity;
	}
	
	override bool CanCollideWith (Actor other, bool passive) {
		if (other.GetClassName() == "PK_Killer" && passive) {
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
		+MISSILE
		Obituary "$PKO_KILLERBEAM";
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
		A_Facemaster(0,0,flags:FAF_MIDDLE);
		if (!master || !PKWeapon.CheckWmod(master)) {
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
		}
		if (!CheckSight(master,SF_IGNOREWATERBOUNDARY)) {
			StopBeams();
			return;
		}
		StartBeams();
		//this rail deals the actual damage, it doesn't define any visuals
		A_CustomRailGun(2,color1:"FFFFFF",flags:RGF_SILENT,pufftype:"PK_KillerBeamPuff",range:Distance3D(master),duration:1,sparsity:1024);
	}
}

Class PK_KillerBeamPuff : Actor {
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
		Obituary "$PKO_PAINKILLER";
		+SKYEXPLODE
		-NOEXTREMEDEATH
		+EXTREMEDEATH
		+FLATSPRITE
		+ROLLSPRITE
		+RIPPER
		Xscale 0.31;
		YScale 0.2573;
		DamageFunction (200);
		speed 9;
	}

	override int DoSpecialDamage(Actor target, int damage, name damagetype) {
		int ret = super.DoSpecialDamage(target, damage, damagetype);
		if (ret > 0) {
			SetDamage(0);
			bBLOODLESSIMPACT = true;
			console.printf("Combo killed dealt %d damage to %s. Remaining health: %d", damage, target.GetClassName(), target.health);
		}
		return ret;
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