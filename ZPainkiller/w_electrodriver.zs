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
	}
}

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
	states {
	Spawn:
		MODL A 1 {
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
			if (age > 16)
				SetStateLabel("Boom");
		}
		loop;
	Death:
		MODL A 100 {
			bNOINTERACTION = true;
			A_Stop();
			A_StartSound("weapons/edriver/starwall",attenuation:2);
		}
		#### A 0 A_SetRenderstyle(alpha,STYLE_Translucent);
		#### A 1 A_FadeOut(0.03);
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