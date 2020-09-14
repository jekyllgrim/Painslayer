Class PK_ElectroDriver : PKWeapon {
	private bool attackrate;
	private int celldepleterate;
	Default {
		PKWeapon.emptysound "weapons/empty/electrodriver";
		weapon.slotnumber 5;
		weapon.ammotype1 "PK_ShurikenAmmo";
		weapon.ammogive1 20;
		weapon.ammouse1  1;
		weapon.ammotype2 "PK_Battery";
		weapon.ammogive2 40;
		weapon.ammouse2 1;
		scale 0.23;
		inventory.pickupmessage "Picked up Electro/Driver";
		inventory.pickupsound "pickups/weapons/eldriver";
		Tag "Electro/Driver";
	}
	action vector3 FindElectroTarget(int atkdist = 280) {
		actor ltarget;			
		double closestDist = double.infinity;
		BlockThingsIterator itr = BlockThingsIterator.Create(self,atkdist);
		while (itr.next()) {
			let next = itr.thing;
			if (next == self)
				continue; 
			if (!next.bShootable || !(next.bIsMonster || (next is "PlayerPawn")))
				continue;
			double dist = Distance3D(next);
			if (dist > atkdist)
				continue;
			if (dist < closestDist)
				closestDist = dist;
			if (!CheckSight(next,SF_IGNOREWATERBOUNDARY))
				continue;
			vector3 targetpos = LevelLocals.SphericalCoords((pos.x,pos.y,player.viewz),next.pos+(0,0,next.default.height*0.5),(angle,pitch));	
			if (abs(targetpos.x) > 15 || abs(targetpos.y) > 15) {
				//console.printf("%s found but out of range",next.Getclassname());
				continue;
			}
			ltarget = next;
			//console.printf("Target found: %s, (%d, %d, %d)",ltarget.Getclassname(),ltarget.pos.x,ltarget.pos.y,ltarget.pos.z);
		}
		if (!ltarget) {
			FLineTraceData hit;
			LineTrace(angle,atkdist,pitch,TRF_ABSPOSITION,player.viewz,pos.x,pos.y,data:hit);
			if (hit.HitType != TRACE_HitNone && hit.HitType != TRACE_HitActor) {
				Spawn("PK_ElectricPuff",hit.HitLocation);
			}
			return hit.HitLocation;
		}
		int dmg = invoker.hasDexterity ? 6 : 3;
		if (frandom(0,2) > 1.5)
			ltarget.DamageMobj(self,self,dmg,'normal',flags:DMG_THRUSTLESS);
		else
			ltarget.DamageMobj(self,self,dmg,'normal',flags:DMG_THRUSTLESS|DMG_NO_PAIN);
		if (!ltarget.FindInventory("PK_ElectroTargetControl"))
			ltarget.GiveInventory("PK_ElectroTargetControl",1);
		return ltarget.pos+(0,0,ltarget.height*0.5);
	}
	states {
	Ready:
		ELDR A 1 {
			PK_WeaponReady();
			if (CountInv("PK_Battery") > 0) {
				let psp = player.FindPSprite(-10);
				if (!psp)
					A_Overlay(-10,"ElectricSpark");
			}
		}
		loop;
	Fire:
		TNT1 A 0 {
			A_StartSound("weapons/edriver/starshot");
			A_FireProjectile("PK_Shuriken",spawnofs_xy:5);
			A_WeaponOffset(2+frandom[eld](-0.5,0.5),34+frandom[eld](-0.5,0.5));
		}
		ELDR BC 1 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		ELDR D 1 {
			A_WeaponOffset(-0.5,-0.5,WOF_ADD);
			invoker.attackrate = !invoker.attackrate;
			if (invoker.attackrate)
				A_SetTics(2);
		}
		ELDR A 2 A_WeaponOffset(-0.5,-0.5,WOF_ADD);
		TNT1 A 0 A_ReFire();
		goto ready;
	AltFire:
		TNT1 A 0 {
			A_StartSound("weapons/edriver/electroloopstart",CHAN_VOICE);
			if (invoker.hasDexterity) {
				A_SoundPitch(CHAN_VOICE,1.4);
			}
		}
	AltHold:
		ELDR A 1 {
			if (player.cmd.buttons & BT_ATTACK && CountInv("PK_Battery") >= 40) {
				A_WeaponOffset(0,32);
				TakeInventory("PK_Battery",40);
				A_ClearRefire();
				A_StopSound(12);
				return ResolveState("DiskFire");
			}
			if (!FindInventory("PowerInfiniteAmmo",true)) {
				invoker.celldepleterate++;
				int req = invoker.hasDexterity ? 1 : 3;
				if (invoker.celldepleterate > req) {				
					invoker.celldepleterate = 0;
					if (CountInv("PK_Battery") >= 1)
						TakeInventory("PK_Battery",1);
					else {
						A_ClearRefire();
						A_StartSound("weapons/edriver/electroloopend",12);
						return ResolveState("Ready");
					}
				}
			}
			A_StartSound("weapons/edriver/electroloop",12,CHANF_LOOPING);
			vector3 atkpos = FindElectroTarget();
			PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:atkpos,masterOffset:(24,8.5,10),style:STYLE_ADD);
			PK_TrackingBeam.MakeBeam("PK_Lightning2",self,radius:32,hitpoint:atkpos,masterOffset:(24,8.5,10),style:STYLE_ADD);
			if (invoker.hasDexterity) {
				PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:atkpos,masterOffset:(24,8.2,9.5),style:STYLE_ADD);
				PK_TrackingBeam.MakeBeam("PK_Lightning2",self,radius:32,hitpoint:atkpos,masterOffset:(24,8.9,10.5),style:STYLE_ADD);
				A_SoundPitch(12,1.25);
			}
			else
				A_SoundPitch(12,1);
			A_WeaponOffset(frandom[eld](-0.3,0.3),frandom[eld](32,32.4));
			return ResolveState(null);
		}
		TNT1 A 0 {
			A_WeaponOffset(0,32);
			A_Refire();
		}
		TNT1 A 0 {
			A_StopSound(12);
			A_StartSound("weapons/edriver/electroloopend",12);
		}
		goto ready;	
	DiskFire:
		ELDR E 1 {
			A_WeaponOffset(16,12,WOF_ADD);
			A_StartSound("weapons/edriver/diskshot",CHAN_WEAPON);
			A_FireProjectile("PK_DiskProjectile",spawnofs_xy:2,spawnheight:5);
		}
		ELDR EEE 2 A_WeaponOffset(3.2,2.4,WOF_ADD);
		ELDR FFE 2 A_WeaponOffset(frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),WOF_ADD);
		ELDR EE 2 A_WeaponOffset(-3.2,-2.4,WOF_ADD);
		ELDR GGGHHHIIIJJJKKK 1 A_WeaponOffset(-1.2,-1,WOF_ADD);
		ELDR A 1 A_WeaponOffset(0,32);
		goto ready;
	ElectricSpark:
			TNT1 A 0 {
				A_OverlayFlags(OverlayID(),PSPF_RENDERSTYLE|PSPF_ALPHA|PSPF_FORCEALPHA,true);
				A_OverlayRenderstyle(OverlayID(),STYLE_Add);
			}
			ELDS A 1 bright {
				if (!player.readyweapon || player.readyweapon != invoker || CountInv("PK_Battery") < 1)	
					return ResolveState("Null");
				let psp = player.FindPSprite(overlayID());
				if (psp)
					psp.frame = random[eld](0,4);
				A_OverlayAlpha(OverlayID(),frandom[eld](0.4,1.0));	
				return ResolveState(null);
			}
			wait;
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
			for (int i = random[eld](5,8); i > 0; i--) {
				let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
				if (part) {
					part.vel = (frandom[eld](-3,3),frandom[eld](-3,3),frandom[eld](2,5));
					part.frame = 2;
				}
				//if (random[eld](0,4) == 4)
					//A_StartSound("weapons/edriver/spark",attenuation:5);
			}
			for (int i = random[eld](2,4); i > 0; i--) {
				let part = Spawn("PK_WhiteSmoke",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
				if (part) {
					part.vel = (frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),frandom[eld](0.2,0.5));
				}
			}
		}
		stop;
	}
}
			

Class PK_ElectroTargetControl : Inventory {
	protected int deadtics;
	protected int age;
	Default {
		inventory.maxamount 1;
	}
	override void Tick() {}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!owner)
			return;
		owner.A_StartSound("weapons/edriver/shockloop",CHAN_6,CHANF_LOOPING,attenuation:3);
		deadtics = 35*random[eld](3,5);
		for (int i = 3; i > 0; i--) {
			let etarget = Spawn("PK_ElectroTarget",owner.pos + (0,0,owner.height*0.5));
			if (etarget) {
				etarget.pitch = frandom[eld](10,120)*randompick[eld](-1,1);
				etarget.tracer = owner;
				etarget.master = self;
			}
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
		let smk = Spawn("PK_BlackSmoke",owner.pos+(frandom[eld](-8,8),frandom[eld](-8,8),owner.height*0.5 + frandom[eld](-4,12)));
		if (smk) {
			smk.vel = (frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),frandom[eld](0.6,0.9));
		}
		if (owner.health <= 0) {
			owner.A_SetTRanslation("Scorched");
			owner.SetOrigin(owner.pos + (frandom[eld](-1,1),frandom[eld](-1,1),frandom[eld](0.5,1.5)),false);
			age++;
			if (age > deadtics){
				owner.A_StopSound(CHAN_6);
				DepleteOrDestroy();
				return;
			}
		}
		else if (GetAge() > 20) {
			owner.A_StopSound(CHAN_6);
			DepleteOrDestroy();
			return;
		}
	}
}

Class PK_ElectroTarget : PK_BaseFlare {
	protected int deadtics;
	protected int deadage;
	protected double sscale;
	protected double bangle;
	Default {
		scale 0.2;
		alpha 0.5;
		+FLATSPRITE
		renderstyle 'add';
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		deadtics = 35*random[eld](3,5);
		if (tracer)
			sscale = 0.014 * tracer.radius;
		bangle = frandom[eld](10,25)*randompick[eld](-1,1);
	}
	states {
	Cache:
		ELTE ABCDEFGHIJKL 0;
	Spawn:
		ELTE # 1 {
			frame = random[eld](0,11);
			alpha = frandom[eld](0.1,0.9);
			A_SetScale(sscale * frandom[eld](0.75,1.0));
			if (!tracer || !master) {
				return ResolveState("End");				
			}
			angle+=bangle;
			SetOrigin(tracer.pos+(0,0,tracer.height*0.5),true);
			return ResolveState(null);
		}
		loop;
	End:
		ELTE # 1 {
			A_FadeOut(0.1);
		}
		wait;
	}
}

	

Class PK_Lightning : PK_TrackingBeam {
	States	{
		cache:
			MODL ABCDEFGHIJ 0;
		Spawn:
			TNT1 A 0;
			MODL A 1 bright {
				lifetimer--;
				frame = random[lit](0,9);
			}
			#### # 0 A_JumpIf(lifetimer <=0,"death");
			loop;
	}
}

//same but the model attached to it is angled differently
Class PK_Lightning2 : PK_Lightning {}

Class PK_Shuriken : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.018;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailalpha 0.12;
		obituary "%k showed %o a world full of stars";
		speed 35;
		radius 3;
		height 4;
		damage (5);
		+FORCEXYBILLBOARD;
		+ROLLSPRITE;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		spriterotation = random(0,359);
		if (target)
			pitch = target.pitch;
	}
	states {
	Spawn:
		MODL A 1 NoDelay {
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
			spriterotation += 10;
			if (age > 16)
				SetStateLabel("Boom");				
		}
		loop;
	Death:
		MODL B 100 {
			bNOINTERACTION = true;
			A_Stop();
			A_StartSound("weapons/edriver/starwall",attenuation:2);
		}
		#### # 0 A_SetRenderstyle(alpha,STYLE_Translucent);
		#### # 1 A_FadeOut(0.03);
		wait;
	Boom:
		TNT1 A 0 {
			A_StartSound("weapons/edriver/starboom");
			A_Stop();
			A_SetScale(0.6);
			A_SetRenderstyle(0.75,STYLE_Add);
			roll = random[star](0,359);
			A_Explode(128,40,fulldamagedistance:64);
			for (int i = random[sfx](5,10); i > 0; i--) {
				let debris = Spawn("PK_RandomDebris",pos);
				if (debris) {
					debris.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),frandom[sfx](-2,6));
					debris.A_SetScale(0.5);
					debris.gravity = 0.25;
				}
			}
		}
		BOM3 ABCDEFGHIJKLMNOPQRSTU 1 bright;
		stop;
	Crash:
	XDeath:
		TNT1 A 1;
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


Class PK_DiskProjectile : PK_Shuriken {
	private int deadtics;
	private Array < Actor > disktargets;
	Default {
		PK_Projectile.trailcolor "8bb1ff";
		PK_Projectile.trailscale 0.022;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailalpha 0.12;
		PK_Projectile.flareactor "PK_DiskFlare";
		PK_Projectile.flarecolor "1ba7f8";
		obituary "%k gave %o a capital punishment";
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
			if (!next.bShootable || !(next.bIsMonster || (next is "PlayerPawn")) || !target.IsHostile (next) || target.bKILLED)
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
						if (random(0,2) == 2)
							trg.DamageMobj(self,self,2,'normal',flags:DMG_THRUSTLESS);
						else
							trg.DamageMobj(self,self,2,'normal',flags:DMG_THRUSTLESS|DMG_NO_PAIN);
						if (!trg.FindInventory("PK_ElectroTargetControl"))
							trg.GiveInventory("PK_ElectroTargetControl",1);
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
		MODL A 1 {
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
			spriterotation += 10;			
		}
		loop;
	Crash:
	XDeath:
	Death:
		TNT1 A 0 {
			A_Stop();
			A_StartSound("weapons/edriver/starwall",attenuation:2);
			A_StartSound("weapons/edriver/shockloop",CHAN_VOICE,CHANF_LOOPING);
		}
		MODL B 3 {
			for (int i = random[eld](4,6); i > 0; i--) {
				let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
				if (part) {
					part.vel = (frandom[eld](-5,5),frandom[eld](-5,5),frandom[eld](4,7));
					part.frame = 2;
					part.A_SetScale(0.04);
				}
			}
			for (int i = random[eld](2,4); i > 0; i--) {
				let smk = Spawn("PK_WhiteSmoke",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
				if (smk) {
					smk.vel = (frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),frandom[eld](0.2,0.5));
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
			A_Explode(128,160);
			for (int i = 32; i > 0; i--) {
				let part = Spawn("PK_RicochetSpark",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
				if (part) {
					part.vel = (frandom[eld](-6.5,6.5),frandom[eld](-6.5,6.5),frandom[eld](4,9));
					part.frame = 2;
					part.A_SetScale(0.06);
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