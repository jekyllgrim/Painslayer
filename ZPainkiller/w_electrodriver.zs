Class PK_ElectroDriver : PKWeapon {
	private bool attackrate;
	private int celldepleterate;
	private PK_LaserBeam lightningBeam;

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
	action Vector3 FindElectroVictim(double atkdist = 280) {
		Actor victim;
		Vector3 hitPos;
		Vector3 attackPos = (pos.xy, player.viewz);

		// First, try finding a nearby victim within 15-degree area
		// around our crosshair:
		double closestDist = atkdist;
		BlockThingsIterator itr = BlockThingsIterator.Create(self, atkdist);
		while (itr.next()) {
			let next = itr.thing;
			// only living, visible monsters or players are valid:
			if (!next || 
				next == self ||
				! next.bSHOOTABLE ||
				!(next.bISMONSTER || next.player) ||
				next.health <= 0 ||
				!CheckSight(next,SF_IGNOREWATERBOUNDARY)) {
				continue;
			}
			// Get spherical coords to the potential target
			// to make sure they're close to our crosshair:
			Vector3 coordsToVictim = Level.SphericalCoords(attackPos, next.pos.PlusZ(next.height*0.5), (angle,pitch));
			// Too far from crosshair - skip:
			if (max(abs(coordsToVictim.x), abs(coordsToVictim.y)) > 15 + next.radius * 0.5) {
				continue;
			}
			// Too far in general:
			if (coordsToVictim.z > closestDist) {
				continue;
			}
			closestDist = coordsToVictim.z;
			// Cache the target if successful:
			victim = next;
			// (Iteration will continue until the closest one is found)
		}

		// still no target - try finding something directly in front of our crosshair:
		FLineTraceData tracedata;
		if (!victim) {
			LineTrace(angle, atkdist+radius, pitch, TRF_SOLIDACTORS, offsetz: player.viewz-pos.z, data: tracedata);
			Actor act = tracedata.HitActor;
			// Check if linetrace hit a valid actor. Note, in contrast to the
			// BlockThingsIterator method above, which only checks for enemies
			// (players and monsters), linetrace (direct aim) method checks for
			// anything shootable, so we can still destroy shootable objects
			// (like treasure chests):
			if (tracedata.HitType == TRACE_HitActor && act.bShootable && health > 0) {
				victim = act;
			}
			// hit nothing - store position to it:
			else {
				hitPos = tracedata.HitLocation;
			}
		}

		// If a victim was found, get a position of its center:
		// (if it wasn't found, then we got hitpos from LineTrace's
		// HitLocation earlier):
		if (victim) {
			hitPos = victim.pos.PlusZ(victim.height*0.5);
		}
		// Get direction towards whatever we hit (actor, geometry
		// or empty space):
		Vector3 diff = level.Vec3Diff(attackPos, hitPos);
		Vector3 beamDir = diff.Unit();
		double beamDist = diff.Length();

		// Now, we need to detect if there's water in the way first.
		// If there is, we'll do special underwater handling.
		let [hitWater, waterPos, waterTracer] = PK_WaterCollisionTracer.Detect(attackPos, beamDir, self);
		if (hitwater && level.Vec3Diff(attackPos, waterPos).Length() <= beamDist) {
			let puf = PK_ElectroDamageSplash(Spawn("PK_ElectroDamageSplash", waterPos));
			if (puf) {
				puf.waitTimer = 2;
				puf.splash_anglestep = 0;
				PK_Utils.OrientActorToNormal(puf, PK_Utils.GetNormalFromTracer(watertracer.results));
			}
			PK_ElectroDriver.DealWaterDamage(puf, self);
			// do nothing else:
			return waterPos;
		}

		// If no victim is found, handle other types of collision:
		if (!victim) {
			// Hit nothing - return the position where the trace ended:
			if (tracedata.HitType == TRACE_HitNone) {
				return hitPos;
			}
			// if we hit something, also draw a puff there:
			let normal = PK_Utils.GetNormalFromTrace(tracedata);
			Vector3 pufpos = level.Vec3Offset(hitPos, normal * 5);
			bool hitflatwater = false;
			// if that something is flat water, deal damage across that:
			if (tracedata.HitType == TRACE_HitFloor && tracedata.hitTexture.isValid()) {
				let puf = PK_ElectroDamageSplash(Spawn("PK_ElectroDamageSplash", pufpos));
				if (puf) {
					puf.waitTimer = 2;
					puf.splash_anglestep = 0;
					PK_Utils.OrientActorToNormal(puf, normal);
				}
				if (puf && puf.GetFloorTerrain().isLiquid) {
					hitflatwater = true;
				}
				else if (PK_BaseActor.IsLiquidTexture(tracedata.HitTexture)) {
					hitflatwater = true;
				}
				if (hitflatwater && puf) {
					PK_ElectroDriver.DealWaterDamage(puf, self, flatTexName: TexMan.GetName(tracedata.hitTexture));
					return pufpos;
				}
				else if (puf) {
					puf.Destroy();
				}
			}
			let puf = Spawn('PK_ElectricPuff', pufpos);
			if (puf) {
				puf.target = self;
			}
			return pufpos;
		}

		// Actually found a victim and didn't hit water in the process
		// - proceed to attack the victim:
		int dmg = invoker.hasDexterity ? 8 : 4;
		PK_ElectroTargetControl.DealElectroDamage(victim, self, self, dmg, DMG_THRUSTLESS|DMG_PLAYERATTACK, delay:12);
		// if victim's in water, deal electric damage around it:
		if (victim.waterlevel > 0) {
			PK_ElectroDriver.DealWaterDamage(victim, self);
		}

		// If the player has Weapon Modifier, the beam
		// is supposed to split from the main target to
		// monsters around it. So, we need another 
		// BlockThingsIterator to find more targets:
		else if (invoker.hasWmod) {
			// Remember that this iterator should be created
			// around the victim, not around the shooter!
			BlockThingsIterator itr = BlockThingsIterator.Create(victim, atkdist);
			while (itr.next()) {
				// only living, visible monsters or players are valid:
				let next = itr.thing;
				if (!next || 
					next == self ||
					next == victim ||
					!next.bSHOOTABLE ||
					!(next.bISMONSTER || next.player) ||
					next.health <= 0 ||
					victim.Distance3D(next) > 180 ||
					!CheckSight(next, SF_IGNOREWATERBOUNDARY)) {
					continue;
				}
				
				PK_Lightning.Fire(victim, next.pos+(0,0,next.height*0.5), temporary: true);
				// The secondary damage is 75% of the base beam damage
				// and never causes pain:
				PK_ElectroTargetControl.DealElectroDamage(next, self, self, dmg * 0.75, DMG_NO_PAIN|DMG_THRUSTLESS|DMG_PLAYERATTACK);
			}
		}
		return victim.pos.PlusZ(victim.height*0.5);
	}

	void FireLightning(Actor from, Vector3 aimpos, double fw, double lr, double ud) {
		if (!lightningBeam) {
			lightningBeam = PK_Lightning.Fire(from, aimpos, fw, lr, ud);
		}
		lightningBeam.SetEnabled(true);
		lightningBeam.StartTracking(aimpos);
	}

	void StopLightning() {
		if (lightningBeam) {
			lightningBeam.SetEnabled(false);
		}
	}

	action void A_DoElectroAttack() {
		if (!player || !player.mo) {
			invoker.StopLightning();
			return;
		}

		if (waterlevel < 2) {
			invoker.FireLightning(self, FindElectroVictim(), 24, 8.5, 10);
		}

		else {
			invoker.StopLightning();
			A_Overlay(PSP_UNDERGUN, "UnderwaterMuzzleFlash", true);
			if (random(0,1) == 1)
				DamageMobj(self, self, 1, 'Electricity', DMG_THRUSTLESS);
			
			DealWaterDamage(self, self, 256);
		}
	}

	static const color electricBlipColors[] = { "6a7dfa", "65B0DB", "95DFF6", "2C60DB", "485FF9" };

	static void DealWaterDamage(Actor emitter, Actor source, double rad = 320, name flatTexName = 'none') {
		Vector3 emitPos = emitter.pos;
		TextureID watertex;
		waterTex.SetInvalid();
		if (flatTexName != 'none') {
			watertex = TexMan.CheckForTexture(flatTexName);
		}
		bool flatwater = watertex.IsValid();
		// build an array of connected sectors (used for flat water):
		/*array<Sector> connectedSectors;
		if (flatwater) {
			Sector cursector, othersector;
			cursector = emitter.cursector;
			connectedSectors.Push(cursector);
			Line curline;
			for (int i = cursector.lines.Size() - 1; i >= 0; i--) {
				curline = cursector.lines[i];
				if (!curline) continue;
				othersector = curline.frontsector == cursector? curline.backsector : curline.frontsector;
				if (othersector == cursector) continue;
				if (othersector.GetTexture(Sector.floor) != watertex) continue;

				if (othersector && connectedSectors.Find(othersector) == connectedSectors.Size()) {
					connectedSectors.Push(othersector);
				}
			}
		}*/

		BlockThingsIterator itr = BlockThingsIterator.CreateFromPos(emitPos.x, emitPos.y, emitPos.z, emitPos.z, rad, false);
		double dist = rad * rad;
		while (itr.next()) {
			let next = itr.thing;
			// only damage shootable, alive monsters or players:
			if (!next || next == emitter || next.health <= 0 ||
			    !next.bShootable || (!next.bIsMonster && !next.player))
				continue;
			
			// flat water - check distance, that the texture
			// undex next matches, actor is close enough to
			// the floor, and is in a connected sector:
			if (flatwater) {
				if (emitter.Distance2DSquared(next) > dist ||
				    next.floorpic != watertex ||
				    abs(next.pos.z - next.floorz) > 10/* ||
					connectedSectors.Find(next.cursector) == connectedSectors.Size()*/)
				continue;
			}
			// 3d water - check distance and waterlevel:
			else if (emitter.Distance3DSquared(next) > dist || next.waterlevel <= 0) {
				continue;
			}
			PK_ElectroTargetControl.DealElectroDamage(next, emitter, source, 2, DMG_THRUSTLESS|DMG_PLAYERATTACK, delay:6);
		}
		
		FSpawnParticleParams pp;
		pp.flags = SPF_FULLBRIGHT|SPF_REPLACE;
		pp.style = STYLE_Add;
		pp.startalpha = 3;
		pp.fadestep = -1;
		pp.lifetime = 10;
		double pz, pr, pAngle, pDist;

		Vector3 pdir;
		for (int i = int(round(rad / 4.0)); i > 0; i--) {
			pz = frandom[etp](-1.0, 1.0);
			pr = sqrt(1.0 - pz*pz);
			pAngle = frandom[etp](0.0, 360.0);
			pdir.x = pr * cos(pAngle);
			pdir.y = pr * sin(pAngle);
			pdir.z = pz;

			pDist = rad * (frandom[etp](0.0, 1.0) ** 0.3334);
			pp.pos = level.Vec3Offset(emitpos, pdir * pDist);
			emitter.SetOrigin((pp.pos), false);
			emitter.UpdateWaterLevel(false);
			if (flatwater && emitter.waterlevel <= 0) {
				pp.pos.z = emitter.cursector.floorplane.ZAtPoint(pp.pos.xy);
				emitter.SetZ(pp.pos.z);
			}
			if (!level.IsPointInLevel(pp.pos)) {
				continue;
			}
			if ((flatwater && emitter.floorpic == watertex/* && connectedSectors.Find(emitter.cursector) != connectedSectors.Size()*/) || emitter.waterlevel) {
				pp.color1 = PK_ElectroDriver.electricBlipColors[random[epart](0, PK_ElectroDriver.electricBlipColors.Size() - 1)];
				pp.Size = frandom[epart](10, 22);
				level.SpawnParticle(pp);
			}
		}
		emitter.SetOrigin(emitPos, false);
		emitter.UpdateWaterLevel(false);
	}

	override void Tick() {
		Super.Tick();
		if (lightningBeam) {
			if (!owner || !owner.player || owner.health <= 0 ||
				!owner.player.readyweapon || owner.player.readyweapon != self) {
				lightningBeam.Destroy();
				return;
			}
			let psp = owner.player.FindPSprite(PSP_WEAPON);
			if (!psp || !psp.curstate.InStateSequence(FindState("AltFire"))) {
				lightningBeam.Destroy();
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
			Fire3DProjectile("PK_Shuriken", updown: -6.5, leftright:8, crosshairConverge: true);
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
				invoker.StopLightning();
				A_WeaponOffset(0,WEAPONTOP);
				PK_DepleteAmmo(secondary:true,80);
				A_ClearRefire();
				A_StopSound(CH_LOOP);
				player.SetPSprite(PSP_UNDERGUN, ResolveState("Null"));
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
			invoker.StopLightning();
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

class PK_Lightning : PK_LaserBeam {
	int lifetime;
	Default {
		PK_LaserBeam.LaserColor "";
		Renderstyle 'Add';
		Alpha 3;
		XScale 50;
		YScale 1;
	}

	static PK_Lightning Fire(Actor from, Vector3 aimpos, double fw = 0, double lr = 0, double ud = 0, bool temporary = false) {
		let beam = PK_Lightning(PK_LaserBeam.Create(from, fw, lr, -ud, type: 'PK_Lightning'));
		if (beam) {
			if (from.player)
				beam.bNOTIMEFREEZE = true;
			if (temporary) {
				beam.lifetime = 4;
				beam.alpha *= 0.2;
				beam.scale.x *= 0.6;
			}
			else {
				beam.lifetime = -1;
			}
			beam.SetEnabled(true);
			beam.StartTracking(aimpos);
		}
		return beam;
	}

	static void DrawParticleLightning(Vector3 from, Vector3 to)
	{
		let diff = Level.Vec3Diff(from, to);
		let dir = diff.Unit();
		let dist = diff.Length();
		double nodeDist = Clamp(dist / 10, min(8, dist), min(80, dist));
		int steps = nodeDist < dist? floor(dist / nodeDist) : 1;
		double ofss = nodeDist / 4.0;

		array <double> litPosX;
		array <double> litPosY;
		array <double> litPosZ;
		Vector3 partPos = from;
		Vector3 node;
		for (int i = 1; i <= steps; i++)
		{
			partPos += dir*nodeDist;
			node = partPos;
			if (i < steps)
			{
				node += (frandom[lightningpart](-ofss, ofss), 
						frandom[lightningpart](-ofss, ofss), 
						frandom[lightningpart](-ofss, ofss));
			}
			litPosX.Push(node.x);
			litPosY.Push(node.y);
			litPosZ.Push(node.z);
		}

		steps = min(litPosX.Size(), litPosY.Size(), litPosZ.Size());
		for (int i = 0; i < steps; i++)
		{
			node.x = litPosX[i];
			node.y = litPosY[i];
			node.z = litPosZ[i];
			DrawParticleLightningSegment(from, node, density: 1, size: 4, posOfs: 0);
			from = node;
		}
	}

	static void DrawParticleLightningSegment(Vector3 from, Vector3 to, double density = 8, double size = 10, double posOfs = 2)
	{
		let diff = Level.Vec3Diff(from, to); // difference between two points
		let dir = diff.Unit(); // direction from point 1 to point 2
		int steps = floor(diff.Length() / density); // how many steps to take:

		// Generic particle properties:
		posOfs = abs(posOfs);
		FSpawnParticleParams pp;
		pp.color1 = 0xFFCCCCFF;
		pp.flags = SPF_FULLBRIGHT|SPF_REPLACE;
		pp.lifetime = 1;
		pp.size = size; // size
		pp.style = STYLE_Add; //additive renderstyle
		pp.startalpha = 1;
		Vector3 partPos = from; //initial position
		for (int i = 0; i <= steps; i++)
		{
			pp.pos = partPos;
			if (posOfs > 0)
			{
				pp.pos + (frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs), frandom[lightningpart](-posOfs,posOfs));
			}
			// spawn the particle:
			Level.SpawnParticle(pp);
			// Move position from point 1 topwards point 2:
			partPos += dir*density;
		}
	}

	override void Tick() {
		Super.Tick();
		if (lifetime > 0) {
			lifetime--;
			if (lifetime == 0) {
				Destroy();
				return;
			}
		}
		if (tics >= 0) {
			if (tics > 0)
				tics--;
			while (!tics) {	
				if (!curstate.nextState) {
					Destroy();
					return;
				}
				else {
					SetState (CurState.NextState);
				}
			}
		}
	}

	States	{
	Spawn:
		M000 A 1 NoDelay {
			for (int i = 0; i < 2; i++) {
				A_ChangeModel("",
					skinindex: i,
					skinpath: "models/lightning",
					skin: String.Format("electrobolt_%d.png",random[sfxlit](0,9)),
					flags: CMDL_USESURFACESKIN);
			}
		}
		loop;
	}
}

Class PK_ElectricPuff : PKPuff {

	Default {
		renderstyle 'add';
		alpha 0.08;
		scale 0.1;
		radius 6;
	}

	States {
	Spawn:
		TNT1 A 0 NoDelay {
			if (GetParticlesLevel() >= PL_Reduced) {
				FindLineNormal();
				TextureID smoketex = TexMan.CheckForTexture(PK_BaseActor.GetRandomWhiteSmoke());
				FSpawnParticleParams smoke;
				smoke.lifetime = 40;
				smoke.color1 = "";
				smoke.style = STYLE_Translucent;
				smoke.flags = SPF_REPLACE|SPF_ROLL;
				smoke.texture = smoketex;
				smoke.pos = debrisPos;
				smoke.vel = (hitnormal + 
					(frandom[sfx](-0.01,0.01),
					frandom[sfx](-0.01,0.01),
					frandom[sfx](-0.01,0.01)))
					* frandom[sfx](0.1,0.5);
				smoke.size = 30;
				smoke.sizestep = smoke.size * 0.03;
				smoke.startalpha = 0.8;
				smoke.fadestep = -1;
				smoke.rollvel = frandom[sfx](2,5)*randompick[sfx](-1,1);
				Level.SpawnParticle(smoke);
			}

			TextureID sparktex = TexMan.CheckForTexture("SPRKC0");
			for (int i = random[eld](5,8); i > 0; i--) {
				PK_LightDebris.PK_SpawnSpark(sparktex,
					debrispos,
					vel: (hitnormal + (frandom[sfx](-1,1),frandom[sfx](-1,1),frandom[sfx](-1,1))) * frandom[sfx](0.1, 4),
					hordampen: 0.95,
					size: frandom[sfx](5, 8),
					gravity: 0.35,
					sizefac: 0.96
				);
			}
		}
		SPRK C 1 A_FadeOut(0.08);
		wait;
	}
}

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
			let esplash = Spawn("PK_ElectroDamageSplash",owner.pos + (0,0,owner.height*0.5));
			if (esplash) {
				esplash.tracer = owner;
				esplash.master = self;
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
	double splash_scalestep;
	double splash_anglestep;
	int waitTimer;

	Default {
		scale 0.2;
		alpha 0.5;
		+FLATSPRITE
		renderstyle 'add';
	}

	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (tracer) {
			splash_scalestep = 0.014 * tracer.radius;
			pitch = frandom[ett](10,120)*randompick[ett](-1,1);
			splash_anglestep = frandom[ett](10,25)*randompick[ett](-1,1);
		}
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
				A_SetScale(splash_scalestep * frandom[ett](0.75,1.0));
			}
			frame = random[sfx](0,11);
			alpha = frandom[sfx](0.1,0.9);
			if (tracer)
				angle += splash_anglestep;
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
		DamageFunction (20);
		+FORCEXYBILLBOARD;
		+ROLLSPRITE;		
	}
	override void StakeBreak() {
		if (GetParticlesLevel() >= PL_REDUCED) {
			for (int i = random[sfx](2,4); i > 0; i--) {
				PK_LightDebris.PK_SpawnDebris(
					PK_LightDebris.GetRandomDebrisTex(),
					pos,
					vel: (frandom[sfx](-5,5),
					      frandom[sfx](-5,5),
					      pos.z <= botz? frandom[sfx](3,6) : frandom(-1, -4)),
					gravity:0.35,
					size:frandom[sfx](6, 10),
					sizefac: 0.98,
					rollstep: frandom[sfx](-15, 15),
					hordampen: 0.96);
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
			
			if (GetParticlesLevel() >= PL_REDUCED) {
				for (int i = random[sfx](2,7); i > 0; i--) {
					PK_LightDebris.PK_SpawnDebris(
						PK_LightDebris.GetRandomDebrisTex(),
						pos,
						vel: (frandom[sfx](-5,5),
						      frandom[sfx](-5,5),
						      frandom[sfx](-2,6)),
						gravity:0.3,
						size:frandom[sfx](6, 10),
						sizefac: 0.98,
						rollstep: frandom[sfx](-15, 15),
						hordampen: 0.96);
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

Class PK_DiskProjectile : PK_StakeProjectile {
	const MASK_DISK_CAPACITY = 10;
	private int deadtics;
	private Array < Actor > disktargets;
	TextureID secondaryPartTex;

	Default {
		PK_Projectile.trailcolor "8bb1ff";
		PK_Projectile.trailscale 0.028;
		PK_Projectile.trailalpha 0.2;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailshrink 0.7;
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
	
	override void CreateParticleTrail(out FSpawnParticleParams trail, vector3 ppos, double pvel, double velstep) {
		if (!secondaryPartTex)
			secondaryPartTex = TexMan.CheckForTexture("SPRKC0");		
		FSpawnParticleParams sTrail;
		sTrail.texture = secondaryPartTex;
		sTrail.color1 = "";
		sTrail.style = STYLE_Add;
		sTrail.flags = SPF_REPLACE;
		sTrail.lifetime = 24;
		sTrail.size = 5;
		sTrail.startalpha = 1;
		sTrail.fadestep = -1;
		double v = 0.5;
		sTrail.vel = (frandom[sfx](-v, v),frandom[sfx](-v, v),frandom[sfx](-v, v));
		sTrail.pos = ppos+(frandom[sfx](-radius, radius),frandom[sfx](-radius, radius),frandom[sfx](-height * 0.5,height * 0.5));
		Level.SpawnParticle(sTrail);

		super.CreateParticleTrail(trail, ppos, pvel, velstep);
		trail.style = Style_Add;
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

		if (!target)
			return;
		double atkdist = 190;

		if (waterlevel >= 2) {
			PK_ElectroDriver.DealWaterDamage(self, target, 280);
			return;
		}

		BlockThingsIterator itr = BlockThingsIterator.Create(self,atkdist);
		while (itr.next()) {
			let next = itr.thing;
			if (!next || 
				next == target ||
				next == self ||
				!next.bShootable ||
				!(next.bISMONSTER || next.player) ||
				next.health <= 0 ||
				next.isFriend(target) ||
				Distance3D(next) > atkdist ||
				!CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;

			if (next && CheckDisktargetsEntries(next) < 3) {
				disktargets.push(next);
				if (disktargets.size() > MASK_DISK_CAPACITY) {
					disktargets.delete(0);
				}
			}
		}
			
		for (int i = disktargets.Size() - 1; i >= 0; i--) {
			let trg = disktargets[i];
			if (!trg) continue;

			if (Distance3D(trg) > atkdist)
				disktargets.delete(i);
			else {
				PK_Lightning.Fire(self, trg.pos+(0,0,trg.height*0.5), temporary: true);
				PK_ElectroTargetControl.DealElectroDamage(trg, self, target, 2, DMG_THRUSTLESS, delay: 17);
				if (!CheckSight(trg,SF_IGNOREWATERBOUNDARY)) {
					trg.TakeInventory("PK_ElectroTargetControl",1);
					disktargets.delete(i);
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
			if (waterlevel < 2 && GetParticlesLevel() >= PK_BaseActor.PL_Reduced) {
				TextureID sparktex = TexMan.CheckForTexture("SPRKC0");
				for (int i = random[eld](4,6); i > 0; i--) {
					PK_LightDebris.PK_SpawnSpark(sparktex,
						pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)),
						vel: (frandom[eld](-5,5),frandom[eld](-5,5),frandom[eld](4,7)),
						hordampen: 0.95,
						size: frandom[sfx](8, 12),
						gravity: 0.35,
						sizefac: 0.98
					);
				}

				TextureID smoketex = TexMan.CheckForTexture(PK_BaseActor.GetRandomBlackSmoke());
				FSpawnParticleParams smoke;
				smoke.texture = smoketex;
				smoke.color1 = "";
				smoke.style = STYLE_Add;
				smoke.flags = SPF_ROLL|SPF_REPLACE;
				smoke.lifetime = 28;
				smoke.size = TexMan.GetSize(smoketex) * 0.5;
				smoke.sizestep = smoke.size * 0.05;
				smoke.startalpha = 0.5;
				smoke.fadestep = -1;
				for (int i = random[sfx](2,4); i > 0; i--) {
					smoke.vel = (frandom[sfx](-0.5,0.5),frandom[sfx](-0.5,0.5),frandom[sfx](0.2,0.5));
					smoke.pos = pos+(frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](-2,2));
					smoke.startroll = frandom[etc](-20, 20);
					Level.SpawnParticle(smoke);
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
			
			if (waterlevel < 2 && GetParticlesLevel() >= PK_BaseActor.PL_Reduced) {
				TextureID sparktex = TexMan.CheckForTexture("SPRKC0");
				for (int i = 32; i > 0; i--) {
					PK_LightDebris.PK_SpawnSpark(sparktex,
						pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)),
						vel: (frandom[eld](-5,5),frandom[eld](-5,5),frandom[eld](-5,5)),
						hordampen: 0.95,
						size: frandom[sfx](12, 15),
						gravity: 0.2,
						sizefac: 0.95
					);
				}
			}
		}
		BOM2 ABCDEFGHIJKLMNOPQRSTUVWXY 1 bright;
		stop;
	}
}