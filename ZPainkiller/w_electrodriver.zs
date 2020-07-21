Class PK_ElectroDriver : PKWeapon {
	private bool attackrate;
	Default {
		weapon.slotnumber 5;
		weapon.ammotype1 "PK_ShurikenBox";
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
	action vector3 FindElectroTarget(int atkdist = 256) {
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
			double adiff = abs(DeltaAngle(angle,AngleTo(next,true)));
			//Console.Printf("%s angle %d",next.Getclassname(),adiff);
			if (adiff > 15)
				continue;
			ltarget = next;
		}
		vector3 atkpos;
		if (!ltarget) {
			FLineTraceData hit;
			LineTrace(angle,atkdist,pitch,offsetz:player.viewz,data:hit);
			return hit.HitLocation;
		}
		return ltarget.pos+(0,0,ltarget.height*0.5);
	}
	states {
	Ready:
		ELDR A 1 A_WeaponReady();
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
		TNT1 A 0 A_StartSound("weapons/edriver/electroloopstart",CHAN_VOICE);
	AltHold:
		ELDR A 1 {
			vector3 atkpos = FindElectroTarget();
			PK_TrackingBeam.MakeBeam("PK_Lightning",self,radius:32,hitpoint:atkpos,masterOffset:(30,8.5,10),style:STYLE_ADD);
			PK_TrackingBeam.MakeBeam("PK_Lightning2",self,radius:32,hitpoint:atkpos,masterOffset:(30,8.5,10),style:STYLE_ADD);
			A_StartSound("weapons/edriver/electroloop",CHAN_WEAPON,CHANF_LOOPING);
			A_WeaponOffset(frandom[eld](-0.3,0.3),frandom[eld](32,32.4));
		}
		TNT1 A 0 {
			A_WeaponOffset(0,32);
			A_Refire();
		}
		TNT1 A 0 {
			A_StopSound(CHAN_WEAPON);
			A_StartSound("weapons/edriver/electroloopend");
		}
		goto ready;		
	}
}

Class PK_Lightning : PK_TrackingBeam {
	States	{
		cache:
			MODL ABCDEFGHIJ 0;
		Spawn:
			TNT1 A 0;
			MODL A 1 NoDelay bright {
				lifetimer--;
				frame = random(0,9);
			}
			#### # 0 A_JumpIf(lifetimer <=0,"death");
			loop;
	}
}

Class PK_Lightning2 : PK_Lightning {}

Class PK_Shuriken : PK_Projectile {
	Default {
		PK_Projectile.trailcolor 'white';
		PK_Projectile.trailscale 0.018;
		PK_Projectile.trailfade 0.03;
		PK_Projectile.trailalpha 0.12;
		PK_Projectile.TranslucentTrail true;
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
		MODL A 1 {
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
		}
		BOM3 ABCDEFGHIJKLMNOPQRSTU 1 bright;
		stop;
	Crash:
	XDeath:
		TNT1 A 1;
		stop;
	}
}