Class PK_ElectroDriver : PKWeapon {
	private bool attackrate;
	private int celldepleterate;

	Default {
		-PKWeapon.ALWAYSBOB
		PKWeapon.emptysound "weapons/empty/electrodriver";
		PKWeapon.ammoSwitchCVar 'pk_switch_ElectroDriver';
		weapon.slotnumber 5;
		weapon.ammotype1 "PK_ShurikenAmmo";
		weapon.ammogive1 20;
		weapon.ammouse1  1;
		weapon.ammotype2 "PK_CellAmmo";
		weapon.ammogive2 40;
		weapon.ammouse2 1;
		inventory.pickupmessage "$PKI_ELECTRODRIVER";
		inventory.pickupsound "pickups/weapons/eldriver";
		inventory.icon "PKWID0";
		Tag "$PK_ELECTRODRIVER_TAG";
		Obituary "$PKO_ELECTRO";
	}

	// Finds a suitable target to attack. 
	// First checks if a water sector was hit, and if so, deals area damage in water.
	// Otherwise looks for a suitable target within a 15-degree cone around crosshair.
	// If that fails, just finds a point in front of the player. If that point is on
	// geometry, spawns a puff there, otherwise doesn't spawn anything.
	// Returns coordinates where the trace ended (whether target, or geometry, or geo)
	// and returns 'true' if the lightning is supposed to be drawn.
	action vector3, bool FindElectroTarget(int atkdist = 280) {
		if (!player || !player.mo)
			return (0,0,0), false;
		
		double closestDist = atkdist;
		
		// First, try to detect water with a linetracer:
		let tracer = PK_WaterDetectionTracer(New("PK_WaterDetectionTracer"));
		if (tracer) {
			Vector3 tracedir = (AngleToVector(angle, cos(pitch)), -sin(pitch));
			tracer.Trace(pos + (0, 0, GetPlayerAtkHeight(player.mo)), cursector, tracedir, PLAYERMISSILERANGE, TRACE_NoSky);

			// If a water sector was detected within attack distance,
			// spawn an electri splash at its top and deal splash
			// electric damage around it:
			let hpos = tracer.results.HitPos;
			if (tracer.watersector && Level.Vec3Diff(tracer.results.SrcFromTarget, hpos).Length() <= atkdist) {
				let puf = PK_ElectroDamageSplash(Spawn("PK_ElectroDamageSplash", hpos));
				if (puf) {
					puf.waitTimer = 2;
					puf.pitch = 0;
				}
				DoUnderwaterElectroDamage(puf, self);
				return hpos, true;
			}
		}

		actor ltarget;
		// Try to find potential targets close the the shooter:
		BlockThingsIterator itr = BlockThingsIterator.Create(self,atkdist);
		while (itr.next()) {
			let next = itr.thing;
			if (!next || next == self)
				continue;
			bool isValid = (next.bSHOOTABLE && (next.bISMONSTER || next.player) && next.health > 0 );
			if (!isValid)
				continue;
			double dist = Distance3D(next);
			if (dist > atkdist)
				continue;
			if (dist < closestDist)
				closestDist = dist;
			if (!CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;
			// Get spherical coords to the potential target
			// to make sure they're close to our crosshair:
			vector3 targetpos = Level.SphericalCoords((pos.x,pos.y,GetPlayerAtkHeight(player.mo, true)),next.pos+(0,0,next.default.height*0.5),(angle,pitch));
			// If the target is further than 15 degrees from
			// our crosshair, skip it:
			double goodofs = 15 + next.radius * 0.5;
			if (abs(targetpos.x) > goodofs  || abs(targetpos.y) > goodofs) {
				continue;
			}
			// Cache the target if successful:
			ltarget = next;
			//console.printf("Target found: %s, (%d, %d, %d)",ltarget.Getclassname(),ltarget.pos.x,ltarget.pos.y,ltarget.pos.z);
		}

		// If we couldn't find any potential targets,
		// aim the beam at whatever wall/plane we've hit,
		// spawn the puff there, deal electri damage around it
		// if it's underwater, and return the coordinates
		// to that point:
		if (!ltarget) {
			// Otherwise fire a linetrace to detect solid
			// actors and geometry:
			FLineTraceData hit;
			LineTrace(angle, atkdist, pitch, TRF_NOSKY|TRF_SOLIDACTORS, GetPlayerAtkHeight(player.mo), data:hit);

			if (hit.HitType != TRACE_HitNone) {
				vector3 puffpos = hit.HitLocation;
				double puffangle = 0;
				// If hitting a wall, make the puff face away
				// from the wall and move it out of it a bit:
				if (hit.HitType == TRACE_HitWall && hit.HitLine) {
					let wallnormal = invoker.GetLineNormal(hit.Hitlocation.xy, hit.HitLine);
					puffpos += wallnormal * 8;
					//puffangle = 
				}
				let puf = Spawn("PK_ElectricPuff", hit.HitLocation);
				if (puf) {
					puf.target = self;
					puf.angle = puffangle;
				}
			}

			return hit.HitLocation, true;
		}

		int dmg = invoker.hasDexterity ? 8 : 4;
		PK_ElectroTargetControl.DealElectroDamage(ltarget, self, self, dmg, DMG_THRUSTLESS|DMG_PLAYERATTACK, delay:12);
		if (ltarget.waterlevel >= 2)
			DoUnderwaterElectroDamage(ltarget, self);

		// If the player has Weapon Modifier, the beam
		// is supposed to split from the main target to
		// monsters around it. So, we need another 
		// BlockThingsIterator to find more targets:
		if (invoker.hasWmod) {
			double closestDist = double.infinity;
			// Remember that this iterator should be created
			// around the original monster, not around the player!
			BlockThingsIterator itr = BlockThingsIterator.Create(ltarget,atkdist);
			while (itr.next()) {
				let next = itr.thing;
				if (!next || next == self)
					continue; 
				// Perform the usual set of checks to make sure
				// it's a valid target:
				if (next == ltarget || next.health <= 0 || !next.bShootable || !(next.bIsMonster || (next is "PlayerPawn")) || !next.IsHostile (self) || self.bKILLED)
					continue;
				// Make sure it's the closest possible target:
				double cdist = ltarget.Distance3D(next);
				if (cdist > 180)
					continue;
				if (cdist < closestDist)
					closestDist = cdist;
				if (!CheckSight(next,SF_IGNOREWATERBOUNDARY))
					continue;
				PK_TrackingBeam.MakeBeam("PK_Lightning",ltarget,radius:32,hitpoint:next.pos+(0,0,next.height*0.5),masterOffset:(0,0,ltarget.height*0.5),style:STYLE_ADD);
				// The secondary damage is 75% of the base beam damage
				// and never causes pain:
				PK_ElectroTargetControl.DealElectroDamage(next, self, self, dmg * 0.75, DMG_NO_PAIN|DMG_THRUSTLESS|DMG_PLAYERATTACK);
			}
		}
		return ltarget.pos+(0,0,ltarget.height*0.5), true;
	}

	action void A_DoElectroAttack() {
		if (waterlevel < 2) {
			vector3 hitpos; bool hit;
			[hitpos, hit] = FindElectroTarget();
			if (hit) {
				PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:hitpos,masterOffset:(24,8.5,10),style:STYLE_ADD);
				PK_TrackingBeam.MakeBeam("PK_Lightning2",self,radius:32,hitpoint:hitpos,masterOffset:(24,8.5,10),style:STYLE_ADD);
				if (invoker.hasDexterity) {
					PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:hitpos,masterOffset:(24,8.2,9.5),style:STYLE_ADD);
					PK_TrackingBeam.MakeBeam("PK_Lightning2",self,radius:32,hitpoint:hitpos,masterOffset:(24,8.9,10.5),style:STYLE_ADD);
				}
			}
		}

		else {
			A_Overlay(PSP_UNDERGUN, "UnderwaterMuzzleFlash", true);
			if (random(0,1) == 1)
				DamageMobj(self, self, 1, 'Electricity', DMG_THRUSTLESS);
			
			DoUnderwaterElectroDamage(self, self, 256);
		}
	}

	action void DoUnderwaterElectroDamage(Actor emitter, Actor source, double rad = 320) {
		vector3 emitPos = emitter.pos;
		emitPos.z -= rad + Clamp(emitter.waterdepth, 0, rad);
		BlockThingsIterator itr = BlockThingsIterator.CreateFromPos(emitPos.x, emitPos.y, emitPos.z, emitPos.z, rad, false);
		while (itr.next()) {
			let next = itr.thing;
			if (!next || next == emitter || next.waterlevel < 2)
				continue;
			bool isValid = (next.bSHOOTABLE && (next.bIsMonster || !next.player) && next.health > 0 );
			if (!isValid)
				continue;
			double dist = emitter.Distance3D(next);
			if (dist > rad)
				continue;
			if (!CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;
			PK_ElectroTargetControl.DealElectroDamage(next, emitter, source, 2, DMG_THRUSTLESS|DMG_PLAYERATTACK, delay:6);
		}
		
		double v = 4;
		if (invoker.GetParticlesLevel() >= PK_BaseActor.PL_REDUCED) {
			for (int i = 80; i > 0; i--) {
				vector3 ppos;
				ppos = emitter.pos + (
					frandom[epart](-rad, rad),
					frandom[epart](-rad, rad),
					frandom[epart](-rad, rad)
				);
				ppos.z = Clamp(ppos.z, emitter.pos.z - rad, emitter.pos.z + emitter.waterdepth);
				Sector sec = Level.PointInSector(ppos.xy);
				double wh; bool w;
				[wh, w] = PK_BaseActor.GetWaterHeight(sec, ppos);
				if (!w)
					continue;

				FSpawnParticleParams electricBlip;
				electricBlip.color1 = "6a7dfa";
				electricBlip.flags = SPF_FULLBRIGHT;
				electricBlip.pos = ppos;
				electricBlip.vel = (frandom[epart](-v, v),frandom[epart](-v, v), frandom[epart](-v, v) * 0.5);
				electricBlip.accel = electricBlip.vel * frandom[epart](-0.1, -0.8);
				electricBlip.startalpha = 1;
				electricBlip.Size = frandom[epart](5,7);
				electricBlip.lifetime = 10;
				Level.SpawnParticle(electricBlip);
			}
		}
	}

	States {
	Spawn:
		PKWI D -1;
		stop;
	Ready:
		ELDR A 1 {
			PK_WeaponReady();
			if (PK_CheckAmmo(secondary:true) && waterlevel < 2)
				A_Overlay(PSP_OVERGUN,"ElectricSpark",nooverride:true);
		}
		loop;
	Fire:
		TNT1 A 0 {
			PK_AttackSound("weapons/edriver/starshot");
			Fire3DProjectile("PK_Shuriken", leftright:5);
			A_WeaponOffset(2+frandom[sfx](-0.5,0.5),34+frandom[sfx](-0.5,0.5));
		}
		ELDR BC 1 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		ELDR D 1 {
			A_WeaponOffset(-0.5,-0.5,WOF_ADD);
			invoker.attackrate = !invoker.attackrate;
			if (invoker.attackrate)
				A_SetTics(2);
		}
		ELDR A 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		TNT1 A 0 PK_ReFire();
		goto ready;
	AltFire:
		TNT1 A 0 {
			PK_AttackSound("weapons/edriver/electroloopstart",CHAN_VOICE);
			invoker.targOfs = (0,32);
		}
	AltHold:
		ELDR A 1 {
			if (PressingAttackButton() && PK_CheckAmmo(secondary:true, 80)) {
				A_WeaponOffset(0,32);
				PK_DepleteAmmo(secondary:true,80);
				A_ClearRefire();
				A_StopSound(CH_LOOP);
				return ResolveState("DiskFire");
			}
			
			A_StartSound("weapons/edriver/electroloop",CH_LOOP,CHANF_LOOPING);
			invoker.celldepleterate++;
			int req = invoker.hasDexterity ? 1 : 2;
			if (invoker.celldepleterate > req) {				
				invoker.celldepleterate = 0;
				if (!PK_CheckAmmo(secondary:true))
					return ResolveState("AltHoldEnd");
				PK_DepleteAmmo(secondary:true);
			}
			A_DoElectroAttack();
			player.SetPSprite(PSP_OVERGUN, ResolveState("Null"));
			DampedRandomOffset(5,5,1.5);
			double brt = frandom[sfx](40,56);
			A_AttachLight('PKWeaponlight', DynamicLight.PointLight, "5464fc", int(brt), 0, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF|DYNAMICLIGHT.LF_ATTENUATE, ofs: (32,32,player.viewheight));
			double brt2 = (brt - 40) / 16;
			A_Overlay(PSP_HIGHLIGHTS,"Hightlights");
			A_OverlayFlags(PSP_HIGHLIGHTS,PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(PSP_HIGHLIGHTS,Style_Add);
			A_OverlayAlpha(PSP_HIGHLIGHTS,brt2);
			return ResolveState(null);
		}
		TNT1 A 0 PK_Refire();
	AltHoldEnd:
		TNT1 A 0 {
			A_ClearRefire();
			A_StopSound(CH_LOOP);
			A_StartSound("weapons/edriver/electroloopend",CH_LOOP);
			A_RemoveLight('PKWeaponlight');
			player.SetPSprite(PSP_UNDERGUN, ResolveState("Null"));
		}
		goto ready;	
	Hightlights:
		ELDR Z 1 bright;
		stop;
	DiskFire:
		ELDR E 1 {
			A_RemoveLight('PKWeaponlight');
			A_WeaponOffset(16,12,WOF_ADD);
			A_StartSound("weapons/edriver/diskshot",CHAN_WEAPON);
			A_FireProjectile("PK_DiskProjectile",spawnofs_xy:2,spawnheight:5);
		}
		ELDR EEE 2 A_WeaponOffset(3.2,2.4,WOF_ADD);
		ELDR FFE 2 A_WeaponOffset(frandom[sfx](-0.5,0.5),frandom[sfx](-0.5,0.5),WOF_ADD);
		ELDR EE 2 A_WeaponOffset(-3.2,-2.4,WOF_ADD);
		ELDR GGGHHHIIIJJJKKK 1 A_WeaponOffset(-1.2,-1,WOF_ADD);
		ELDR A 1 A_WeaponOffset(0,32);
		goto ready;
	ElectricSpark:
		TNT1 A 0 {
			A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE|PSPF_ALPHA|PSPF_FORCEALPHA,true);
			A_OverlayRenderstyle(OverlayID(),STYLE_Add);
		}
		ELDT # 2 bright {
			if (waterlevel >= 2 || !player.readyweapon || player.readyweapon != invoker || !PK_CheckAmmo(secondary:true)) {
				player.SetPSprite(PSP_HIGHLIGHTS, ResolveState("Null"));
				return ResolveState("Null");
			}
			A_Overlay(PSP_HIGHLIGHTS,'ReadyHighlights',nooverride:true);
			let psp = player.FindPSprite(overlayID());
			if (psp) {
				int newframe = random[sfx](0,5);
				while (newframe == psp.frame) {
					newframe = random[sfx](0,5);
				}
				psp.frame = newframe;
			}
			A_OverlayAlpha(PSP_HIGHLIGHTS,frandom[sfx](0.4,1));	
			return ResolveState(null);
		}
		wait;
	ReadyHighlights:
		ELDR Y -1 bright {
			A_OverlayFlags(OverlayID(),PSPF_Renderstyle|PSPF_Alpha|PSPF_ForceAlpha,true);
			A_OverlayRenderstyle(OverlayID(),Style_Add);
		}
		stop;
	UnderwaterMuzzleFlash:
		TNT1 A 0 {
			A_OverlayFlags(OverlayID(), PSPF_RENDERSTYLE|PSPF_FORCEALPHA, true);
			A_OverlayRenderstyle(OverlayID(), STYLE_Add);			
		}
		ELDS # 1 {
			if (waterlevel < 2)
				return ResolveState("Null");
			let psp = player.FindPSprite(OverlayID());
			if (psp) {
				psp.alpha = frandom[sfx](1, 2);
				int newframe = random[sfx](0,11);
				while (newframe == psp.frame) {
					newframe = random[sfx](0,11);
				}
				psp.frame = newframe;
			}
			return ResolveState(null);
		}
		loop;
	}
}

Class PK_ElectricPuff : PKPuff {
	Default {
		renderstyle 'add';
		alpha 0.08;
		scale 0.1;
	}
	states {
	Spawn:
		SPRK C 1 NoDelay {
			A_FaceTarget();
			if (GetParticlesLevel() >= PL_Reduced) {					
				TextureID smoketex = TexMan.CheckForTexture(PK_BaseActor.GetRandomWhiteSmoke());
				FSpawnParticleParams smoke;
				smoke.lifetime = 40;
				smoke.color1 = "";
				smoke.style = STYLE_Translucent;
				smoke.flags = SPF_REPLACE|SPF_ROLL;
				smoke.texture = smoketex;
				smoke.pos = pos+(frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](-2,2));
				smoke.vel = (frandom[sfx](-0.5,0.5),frandom[sfx](-0.5,0.5),frandom[sfx](0.2,0.5));
				smoke.size = 30;
				smoke.sizestep = smoke.size * 0.03;
				smoke.startalpha = 0.8;
				smoke.fadestep = -1;
				smoke.rollvel = frandom[sfx](2,5)*randompick[sfx](-1,1);
				Level.SpawnParticle(smoke);
			}			
			if (GetParticlesLevel() >= PL_Full) {
				for (int i = random[eld](5,8); i > 0; i--) {
					let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
					if (part) {
						part.vel = (frandom[eld](-3,3),frandom[eld](-3,3),frandom[eld](2,5));
						part.frame = 2;
					}
				}
			}
		}
		stop;
	}
}

class PK_WaterDetectionTracer : LineTracer {
	Sector watersector;

	override ETraceStatus TraceCallBack() {
		if (results.CrossedWater) {
			watersector = results.CrossedWater;
			results.hitPos = results.CrossedWaterPos;
			return TRACE_Stop;
		}

		if (results.Crossed3DWater) {
			watersector = results.Crossed3DWater;
			results.hitPos = results.Crossed3DWaterPos;
			return TRACE_Stop;
		}

		return TRACE_Skip;
	}
}

/*class PK_ElectroLineTracer : LineTracer {
	Sector watersector;
	bool hitGeo;
	Actor tracesource;

	override ETraceStatus TraceCallBack() {	
		let hact = results.HitActor;
		if (results.HitType == TRACE_HitActor) {
			if (hact && hact.bSOLID && hact != tracersource)
				return TRACE_Stop;
			else if (hact)
				return TRACE_Skip;
		}

		if (results.CrossedWater) {
			console.printf("Linetracer hit water at %.1f, %.1f, %.1f", results.hitpos.x, results.hitpos.y, results.hitpos.z);
			watersector = results.CrossedWater;
			results.hitPos = results.CrossedWaterPos;
			return TRACE_Stop;
		}

		if (results.Crossed3DWater) {
			console.printf("Linetracer hit water at %.1f, %.1f, %.1f", results.hitpos.x, results.hitpos.y, results.hitpos.z);
			watersector = results.Crossed3DWater;
			results.hitPos = results.Crossed3DWaterPos;
			return TRACE_Stop;
		}

		let h = results.hittype;
		if (h == TRACE_HitWall) {
			if (results.Tier == TIER_Lower || results.Tier == TIER_Upper ||
				!(results.HitLine.flags & Line.ML_TWOSIDED) ||
				(results.HitLine.flags & Line.ML_BLOCKEVERYTHING) || 
				(results.HitLine.flags & Line.ML_BLOCKPROJECTILE) || 
				(results.HitLine.flags & Line.ML_BLOCKHITSCAN) ) {

				console.printf("Linetracer hit wall at %.1f, %.1f, %.1f", results.hitpos.x, results.hitpos.y, results.hitpos.z);
				vector2 diff = Level.Vec2Diff(results.SrcFromTarget.xy, results.hitpos.xy);
				vector2 dir = diff.unit();
				results.hitpos.xy -= dir * 8;
				hitGeo = true;
				return TRACE_Stop;
			}
			return TRACE_Skip;
		}

		if (h == TRACE_HitCeiling) {
			console.printf("Linetracer hit ceiling at %.1f, %.1f, %.1f", results.hitpos.x, results.hitpos.y, results.hitpos.z);
			results.hitpos.z -= 1;
			hitGeo = true;
			return TRACE_Stop;
		}

		if (h == TRACE_HitFloor) {
			console.printf("Linetracer hit floor at %.1f, %.1f, %.1f", results.hitpos.x, results.hitpos.y, results.hitpos.z);
			results.hitpos.z += 1;
			hitGeo = true;
			return TRACE_Stop;
		}

		return TRACE_Stop;
	}
}*/

Class PK_ElectroTargetControl : PK_InventoryToken {	
	int noPainTics;
	protected int deadtics;
	protected int deadage;
	protected bool isFlesh;
	TextureID smoketex;
	
	// A universal wrapper for dealing Electro damage. Used by
	// Electro, Electric Disk and secondary Electro beams.
	static int DealElectroDamage(actor victim, actor inflictor, actor source, int damage, int flags, int delay = 19) {
		if (!victim || damage <= 0)
			return 0;
		if (victim.health > 0 && delay > 0) {
			let control = victim.FindInventory("PK_ElectroTargetControl");
			if (!control)
				victim.GiveInventory("PK_ElectroTargetControl",1);
			// If the target already has the control item in their
			// inventory, then we make sure that they can't be pain'ed
			// again if the item has been in their inventory for
			// a period smaller than 'delay' (to reduce excessive 
			// stunlocking).
			else if (control.GetAge() < delay)
				flags |= DMG_NO_PAIN;
		}
		for (int i = random[sfx](2,4); i > 0; i--) {
			double ang = frandom[sfx](0,359);
			double hvel = frandom[sfx](2,4);
			double vvel = frandom[sfx](3,7);
			victim.A_SpawnParticle(
				"CCCCFF",
				SPF_FULLBRIGHT|SPF_RELATIVE,
				lifetime: 30,
				size: 3,
				angle: ang + frandom[sfx](-40,40),
				zoff: victim.height * 0.5,
				velx: hvel,
				velz: vvel,
				accelx: -(hvel / 30.),
				accelz: -0.75,
				sizestep: -0.05
			);
		}
		return victim.DamageMobj(inflictor, source, damage, 'Electricity', flags);
	}	
	
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		isFlesh = (owner.bISMONSTER || owner is "PlayerPawn");
		owner.A_StartSound("weapons/edriver/shockloop",CH_LOOP,CHANF_LOOPING,attenuation:3);
		deadtics = 35*random[etc](3,5);
		for (int i = 3; i > 0; i--) {
			let etarget = Spawn("PK_ElectroDamageSplash",owner.pos + (0,0,owner.height*0.5));
			if (etarget) {
				etarget.tracer = owner;
				etarget.master = self;
			}
		}
	}
	
	override void DoEffect() {
		super.DoEffect();
		if (!owner) {
			Destroy();
			return;
		}
		if (owner.isFrozen())
			return;
		
		if (isFlesh && owner.waterlevel < 2 && GetParticlesLevel() >= PK_BaseActor.PL_FULL) {
			//if (!smoketex)
				//smoketex = TexMan.CheckForTexture("SMOKA0");
			
			name smoketexname = PK_BaseActor.GetRandomBlackSmoke();		
			owner.A_SpawnParticleEx(
				"",
				TexMan.CheckForTexture(smoketexname),
				//STYLE_Add,
				flags: SPF_REPLACE|SPF_ROLL,
				lifetime: 30,
				size: 48,
				xoff: frandom[etc](-8,8),
				yoff: frandom[etc](-8,8),
				zoff: owner.height*0.5 + frandom[etc](-4,12),
				velx: frandom[etc](-0.5,0.5),
				vely: frandom[etc](-0.5,0.5),
				velz: frandom[etc](0.6,0.9),
				startalphaf: 0.6,
				sizestep: -1.6,
				startroll: frandom[etc](-20, 20)
			);

			/*let smk = Spawn("PK_BlackSmoke",owner.pos+(frandom[etc](-8,8),frandom[etc](-8,8),owner.height*0.5 + frandom[etc](-4,12)));
			if (smk) {
				smk.vel = (frandom[etc](-0.5,0.5),frandom[etc](-0.5,0.5),frandom[etc](0.6,0.9));
			}*/
		}

		if (noPainTics > 0) {
			noPainTics--;
		}

		if (owner.health <= 0) {
			if (!owner.bISMONSTER || owner.bBOSS) {
				Destroy();
				return;
			}
			if (isFlesh)
				owner.A_SetTRanslation("Scorched");
			owner.SetOrigin(owner.pos + (frandom[etc](-1,1),frandom[etc](-1,1),frandom[etc](0.5,1.5)),false);
			deadage++;
			if (deadage > deadtics){
				Destroy();
				return;
			}
		}

		if (age > 300 || (owner.health > 0 && age > 20)) {
			Destroy();
			return;
		}
	}

	override void DetachFromOwner() {
		if (owner)
			owner.A_StopSound(CH_LOOP);
		super.DetachFromOwner();
	}
}

Class PK_ElectroDamageSplash : PK_BaseFlare {
	//protected int deadtics;
	//protected int deadage;
	protected double sscale;
	protected double bangle;
	int waitTimer;

	Default {
		scale 0.2;
		alpha 0.5;
		+FLATSPRITE
		renderstyle 'add';
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		//deadtics = 35*random[ett](3,5);
		if (tracer)
			sscale = 0.014 * tracer.radius;
		bangle = frandom[ett](10,25)*randompick[ett](-1,1);
		pitch = frandom[etc](10,120)*randompick[etc](-1,1);
	}
	
	states {
	Spawn:
		ELTE # 1 {
			if (waitTimer > 0)
				waitTimer--;
			if (waittimer <= 0 && (!tracer || !master)) {
				return ResolveState("End");				
			}
			if (tracer) {
				SetOrigin(tracer.pos+(0,0,tracer.height*0.5),true);
				A_SetScale(sscale * frandom[ett](0.75,1.0));
			}
			frame = random[sfx](0,11);
			alpha = frandom[sfx](0.1,0.9);
			angle+=bangle;
			return ResolveState(null);
		}
		loop;
	End:
		ELTE # 1 {
			A_FadeOut(0.1);
			scale *= 0.95;
		}
		wait;
	}
}

	

Class PK_Lightning : PK_TrackingBeam {
	States	{
		cache:
			M000 ABCDEFGHIJ 0;
		Spawn:
			TNT1 A 0;
			M000 A 1 bright {
				lifetimer--;
				frame = random[lit](0,9);
			}
			#### # 0 A_JumpIf(lifetimer <=0,"death");
			loop;
	}
}

//same but the model attached to it is angled differently
Class PK_Lightning2 : PK_Lightning {}

Class PK_Shuriken : PK_StakeProjectile {
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.018;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailalpha 0.12;
		obituary "$PKO_DRIVER";
		speed 35;
		radius 5;
		height 4;
		damage (7);
		+FORCEXYBILLBOARD;
		+ROLLSPRITE;		
	}
	override void StakeBreak() {
		
		if (GetParticlesLevel() >= 2) {
			for (int i = random[sfx](2,4); i > 0; i--) {
				let deb = PK_RandomDebris(Spawn("PK_RandomDebris",(pos.x,pos.y,pos.z)));
				if (deb) {
					deb.A_SetScale(0.3);
					double vz = frandom[sfx](-1,-4);
					if (pos.z <= botz)
						vz = frandom[sfx](3,6);
					deb.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),vz);
				}
			}
		}
		A_StartSound("weapons/edriver/starbreak",volume:0.8, attenuation:4);
		super.StakeBreak();
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		spriterotation = random(0,359);
		if (target) {
			pitch = target.pitch;
		}
		if (mod)
			vel *= 1.35;
	}
	states {
	Spawn:
		M000 A 1 NoDelay {
			spriterotation += 10;
			if (age > 16)
				SetStateLabel("Boom");				
		}
		loop;
	Death:
		M000 B 100 {
			if (target && PKWeapon.CheckWmod(target))
				return ResolveState("Boom");
			StickToWall();
			A_StartSound("weapons/edriver/starwall",attenuation:2);
			return ResolveState(null);
		}
		#### # 0 A_SetRenderstyle(alpha,STYLE_Translucent);
		#### # 1 A_FadeOut(0.03);
		wait;
	Boom:
		TNT1 A 0 {
			A_StartSound("weapons/edriver/starboom");
			A_Stop();
			A_SetRenderstyle(1,STYLE_Add);
			roll = random[star](0,359);
			A_AttachLight('PKExplodingStar', DynamicLight.RandomFlickerLight, "ffAA00", 32, 44, flags: DYNAMICLIGHT.LF_ATTENUATE|DYNAMICLIGHT.LF_DONTLIGHTSELF);
			//when using weapon modifier, this explosion is way too strong, so we have to tone it down
			if (mod) {
				A_SetScale(0.6);
				A_Explode(32,32);
			}
			//otherwise it's so hard to make it useful, it should at least be powerful
			else
				A_Explode(40,128,fulldamagedistance:64);
			
			if (GetParticlesLevel() >= 2) {
				for (int i = random[sfx](2,7); i > 0; i--) {
					let debris = Spawn("PK_RandomDebris",pos);
					if (debris) {
						debris.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),frandom[sfx](-2,6));
						debris.A_SetScale(0.25);
						debris.gravity = 0.25;
					}
				}
			}
		}
		BOM3 ABCDEFGHIJKLMNOPQRSTU 1 bright;
		stop;
	Crash:
	XDeath:
		TNT1 A 1 {
			if (target && PKWeapon.CheckWmod(target))
				return ResolveState("Boom");
			return ResolveState(null);
		}
		stop;
	}
}

//unused
Class PK_ShurikenDebris : PK_RandomDebris {
	Default {
		gravity 0.25;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		let trl = Spawn("PK_DebrisFlame",pos);
		if (trl) {
			trl.alpha = alpha*0.6;
			trl.scale *= 0.5;
		}
		A_FadeOut(0.05);
	}
}


Class PK_DiskProjectile : PK_StakeProjectile {
	private int deadtics;
	private Array < Actor > disktargets;
	Default {
		PK_Projectile.trailcolor "8bb1ff";
		PK_Projectile.trailscale 0.022;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailalpha 0.12;
		PK_Projectile.flareactor "PK_DiskFlare";
		PK_Projectile.flarecolor "1ba7f8";
		obituary "$PKO_ELECTRODRIVER";
		speed 40;
		radius 6;
		height 4;
		damage 25;
		+FORCEXYBILLBOARD;
		+ROLLSPRITE;
		scale 0.6;
		+HITTRACER;
		gravity 0.25;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		spriterotation = random(0,359);
		if (target)
			pitch = target.pitch;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		if (InStateSequence(curstate,FindState("Boom")))
			return;
		if (tracer) {
			if (tracer.bKILLED)
				bNOGRAVITY = false;
			else
				SetOrigin(tracer.pos+(0,0,tracer.height*0.5),true);
		}
		int atkdist = 190;
		double closestDist = double.infinity;
		int maxcapacity = 10;
		if (!target)
			return;
		BlockThingsIterator itr = BlockThingsIterator.Create(self,atkdist);
		while (itr.next()) {
			let next = itr.thing;
			if (!next || next == target)
				continue;
			bool isValid = (next.bSHOOTABLE && (next.bISMONSTER || next.player) && next.health > 0 && next.isHOSTILE(target));
			if (!isValid)
				continue;
			double cdist = Distance3D(next);
			if (cdist > atkdist)
				continue;
			if (cdist < closestDist)
				closestDist = cdist;
			if (!CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;
			if (next && CheckDisktargetsEntries(next) < 3) {				
				disktargets.push(next);
				//console.printf ("%s x %d",next.Getclassname(),CheckDisktargetsEntries(next));
				if (disktargets.size() > maxcapacity)
					disktargets.delete(0);
			}
		}
		if (disktargets.size() > 0) {
			for (int i = 0; i < disktargets.size(); i++) {
				let trg = disktargets[i];
				if (trg) {					
					if (Distance3D(trg) > atkdist)
						disktargets.delete(i);					
					else {
						PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:trg.pos+(0,0,trg.height*0.5),style:STYLE_ADD);
						PK_ElectroTargetControl.DealElectroDamage(trg, self, target, 2, DMG_THRUSTLESS, delay: 17);
						if (!CheckSight(trg,SF_IGNOREWATERBOUNDARY)) {
							//Console.printf("LOF check failed");
							trg.TakeInventory("PK_ElectroTargetControl",1);
							disktargets.delete(i);
						}
					}
				}
			}
		}
	}
	int CheckDisktargetsEntries(actor trg) {
		if (disktargets.size() == 0)
			return 0;
		int entries;
		for (int i = 0; i < disktargets.size(); i++) {
			if (trg == disktargets[i])
				entries++;
		}
		return entries;
	}
	states {
	Spawn:
		M000 A 1 {
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
			spriterotation += 10;			
		}
		loop;
	Crash:
	XDeath:
	Death:
		TNT1 A 0 {
			A_Stop();
			if (!tracer)
				StickToWall();
			A_StartSound("weapons/edriver/starwall",attenuation:2);
			A_StartSound("weapons/edriver/shockloop",CHAN_VOICE,CHANF_LOOPING);
		}
		M000 B 3 {
			
			if (GetParticlesLevel() >= 2) {
				for (int i = random[eld](4,6); i > 0; i--) {
					let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
					if (part) {
						part.vel = (frandom[eld](-5,5),frandom[eld](-5,5),frandom[eld](4,7));
						part.frame = 2;
						part.A_SetScale(0.04);
					}
				}
			}
			if (GetParticlesLevel() >= 1) {
				for (int i = random[sfx](2,4); i > 0; i--) {
					let smk = Spawn("PK_WhiteDeathSmoke",pos+(frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](-2,2)));
					if (smk) {
						smk.vel = (frandom[sfx](-0.5,0.5),frandom[sfx](-0.5,0.5),frandom[sfx](0.2,0.5));
						smk.A_SetScale(0.5);					
					}
				}
			}
			deadtics++;
			if (deadtics > 70)
				SetStateLabel("boom");
		}
		wait;
	Boom:
		TNT1 A 0 {
			A_StartSound("weapons/grenade/explosion",CHAN_VOICE);
			A_Stop();
			A_SetScale(0.9);
			A_SetRenderstyle(0.75,Style_AddShaded);
			roll = random[eld](0,359);
			SetShade("8bb1ff");
			A_Explode(128,160,flags:0);
			
			if (GetParticlesLevel() >= 2) {
				for (int i = 32; i > 0; i--) {
					let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
					if (part) {
						part.vel = (frandom[eld](-6.5,6.5),frandom[eld](-6.5,6.5),frandom[eld](4,9));
						part.frame = 2;
						part.A_SetScale(0.06);
					}
				}
			}
		}
		BOM2 ABCDEFGHIJKLMNOPQRSTUVWXY 1 bright;
		stop;
	}
}


Class PK_DiskFlare : PK_ProjFlare {
	Default {
		scale 0.11;		
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;
		A_SetScale(frandom[eld](0.06,0.12));
	}
}