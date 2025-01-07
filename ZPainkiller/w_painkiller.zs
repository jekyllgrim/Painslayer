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
			if (GetParticlesLevel() < PL_Full)
				return resolveState(null);

			FindLineNormal();
			if (random[sfx](0,10) > 5) {
				let deb = Spawn("PK_RandomDebris", debrisPos);
				if (deb)
					deb.vel = (hitnormal + (frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](3,5)));
			}

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
	PK_LaserBeam beam_outer;
	PK_LaserBeam beam_inner;
	protected string prevspecies;
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
		+BLOODSPLATTER
		projectile;
		scale 0.3;
		DamageFunction (40);
		speed 25;
		radius 2;
		height 2;
	}

	override String GetObituary (Actor victim, Actor inflictor, Name mod, bool playerattack) {
		if (mod == 'PK_KillerBeam') {
			return StringTable.Localize("$PKO_KILLERBEAM");
		}
		return StringTable.Localize(obituary);
	}
	
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!target || !target.player) {
			return;
		}
		A_FaceMovementDirection();

		Vector3 beamofs = (12, 11.2, -11);
		beam_outer = PK_LaserBeam.Create(target, beamofs.x, beamofs.y, beamofs.z);
		beam_outer.shade = 0xf2ac21;
		beam_outer.alpha = 0.5;
		beam_outer.scale.x = 5;
		beam_outer.trackPSprite = true;
		beam_outer.trackPSLayer = PSP_WEAPON;

		beam_inner = PK_LaserBeam.Create(target, beamofs.x, beamofs.y, beamofs.z);
		beam_inner.shade = 0xffffff;
		beam_inner.scale.x = beam_outer.scale.x * 0.35;
		beam_inner.alpha = 1.0;
		beam_inner.trackPSprite = true;
		beam_inner.trackPSLayer = PSP_WEAPON;
	}

	void StartBeams() {

		let weap = PK_Painkiller(target.FindInventory("PK_Painkiller"));
		if (weap)
			weap.beam = true;

		if (beam_outer) {
			beam_outer.SetEnabled(true);
			beam_outer.StartTracking(self.pos);
		}
		if (beam_inner) {
			beam_inner.SetEnabled(true);
			beam_inner.StartTracking(self.pos);
		}

		target.A_StartSound("weapons/painkiller/laser",CHAN_VOICE,CHANF_LOOPING,volume:0.5);
	}

	void StopBeams() {
		if (target.IsActorPlayingSound(CHAN_VOICE, "weapons/painkiller/laser")) {
			target.A_StopSound(CHAN_VOICE);
		}
		
		let weap = PK_Painkiller(target.FindInventory("PK_Painkiller"));
		if (weap)
			weap.beam = false;

		if(beam_outer) {
			beam_outer.SetEnabled(false);
		}

		if(beam_inner) {
			beam_inner.SetEnabled(false);
		}
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
	
	override void Tick() {
		super.Tick();

		if (isFrozen())
			return;

		if (!target || !target.player || target.health <= 0) {
			Stopbeams();
			return;
		}

		if ((!target.player.readyweapon || target.player.readyweapon.GetClass() != 'PK_Painkiller') &&
			!InStateSequence(curstate,FindState("XDeath"))) {
			SetStateLabel("XDeath");
		}

		if (!target || !CheckSight(target,SF_IGNOREWATERBOUNDARY)) {
			StopBeams();
			return;
		}

		Vector3 start = (target.pos.xy, target.player.viewz);
		Vector3 view = level.SphericalCoords(start, self.pos, (target.angle, target.pitch));
		if (!PKWeapon.CheckWmod(target) && (abs(view.x) > 16 || abs(view.y) > 20)) {
			StopBeams();
			return;
		}

		StartBeams();
		Vector3 dir = level.Vec3Diff(start, self.pos).Unit();
		let tracer = PK_KillerBeamTracer.Fire(target, start, direction: dir, range: view.z);
		if (!tracer) return;

		/*double step = tracer.results.distance * 0.05;
		while (step < tracer.results.distance) {
			FSpawnParticleParams p;
			p.size = 5;
			p.lifetime = 2;
			p.startalpha = 1.0;
			p.fadestep = -1;
			p.flags = SPF_FULLBRIGHT;
			p.color1 = 0xff0000;
			p.pos = level.Vec3Offset(start, tracer.results.hitVector.Unit()*step);
			level.SpawnParticle(p);
			step += step;
		}*/
		
		foreach (victim : tracer.beamVictims) {
			if (victim) {
				victim.A_StartSound("weapons/painkiller/laserhit", CHAN_VOICE, CHANF_NOSTOP, volume:0.8, attenuation:4);
				int dmg = victim.DamageMobj(self, target, 2, 'PK_KillerBeam', DMG_THRUSTLESS|DMG_NO_FACTOR|DMG_NO_PAIN);
				if (dmg > 0) {
					victim.SpawnBlood(level.Vec3Offset(start, dir * (target.Distance3D(victim) - victim.radius)), victim.AngleTo(target), dmg);
					victim.TraceBleed(dmg, target);
				}
			}
		}
	}

	override void OnDestroy() {
		StopBeams();
		if (beam_outer)
			beam_outer.Destroy();
		if (beam_inner)
			beam_inner.Destroy();
		Super.OnDestroy();
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
				return ResolveState(null);
				
			// If Killer kills a monster, immediately throw that monster
			// towards the player (PK_KillerFlyTarget hasn't spawned yet,
			// so at this point we interact directly with the monster):
			if (tracer && tracer.health <= 0 && tracer.bISMONSTER && !tracer.bBOSS) {
				ThrowBody(tracer);
				return ResolveState(null);
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
						return ResolveState(null);
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
			return ResolveState(null);
		}
		#### # 1 {
			if (target) {
				double dist = Distance3D(target);
				vel = Vec3To(target).Unit() * min(30, dist);
				if (dist <= 320)
					A_StartSound("weapons/painkiller/return",CHAN_AUTO,CHANF_NOSTOP);
				A_FaceTarget(flags:FAF_MIDDLE);
				if (dist <= 64) {
					target.A_StartSound("weapons/painkiller/killerback",CHAN_AUTO);
					let pk = PK_Painkiller(target.FindInventory("PK_Painkiller"));
					if (pk && target.player && target.player.readyweapon && target.player.readyweapon != pk)
						pk.killer_fired = false;
					return ResolveState("Null");
				}
			}
			return ResolveState(null);
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

class PK_KillerBeamTracer : LineTracer
{
	Actor beamSource;
	array<Actor> beamVictims;

	static PK_KillerBeamTracer Fire(Actor source, Vector3 start, Vector3 direction, double range)
	{
		let tracer = new('PK_KillerBeamTracer');
		tracer.beamSource = source;
		if (tracer.Trace(start, source.cursector, direction, range,
			TRACE_HitSky,
			wallmask: Line.ML_BLOCKEVERYTHING,
			ignore: source) == false)
		{
			return null;
		}
		return tracer;
	}

	override ETraceStatus TraceCallback()
	{
		if (results.HitType == TRACE_HitActor && results.HitActor)
		{
			let victim = results.HitActor;
			// hit its shooter:
			if (victim == beamSource)
			{
				return TRACE_Skip;
			}
			// not shotable:
			if (!victim.bShootable || victim.health <= 0)
			{
				return TRACE_Skip;
			}
			beamVictims.Push(victim);
			return TRACE_Continue;
		}

		switch (results.HitType)
		{
			case TRACE_HitWall:
			case TRACE_HitFloor:
			case TRACE_HitCeiling:
			case TRACE_HasHitSky:
				return TRACE_Stop;
				break;
		}

		return TRACE_Continue;
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
			//console.printf("Combo killed dealt %d damage to %s. Remaining health: %d", damage, target.GetClassName(), target.health);
		}
		return ret;
	}

	override void PostBeginPlay() {
		Actor.PostBeginPlay();
		A_StartSound("weapons/painkiller/spin",CHAN_BODY,CHANF_LOOPING);
		if (target)
			pitch = target.pitch-90;
	}

	override void Tick() {
		Actor.Tick();
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