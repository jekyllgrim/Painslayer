Class PK_GoldContainer : PK_BaseActor abstract {
	color debriscolor;
	property debriscolor : debriscolor;
	Default {
		+SHOOTABLE
		+VULNERABLE
		+NOBLOODDECALS
		bloodtype "PK_PropDebris";
		mass 1000;
		health 100;
		radius 20;
		height 24;
		scale 0.6;
		PK_GoldContainer.debriscolor "3a2B19";
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		//Check if there's enough space to spawn the prop (no more than 32 times):
		bool posValid = false;
		for (int i = 32; i > 0; i--) {
			SetOrigin(FindRandomPosAround(pos, 96),false);
			if (!CheckClippingLines(radius*2)) {
				posValid = true;
				break;
			}
		}
		if (!posValid) {
			if (pk_debugmessages > 1)
				Console.Printf("No valid position for chest at %d:%d:%d. Destroying.",pos.x,pos.y,pos.z);
			Destroy();
		}
	}
	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath) {
		double zofs = default.height;
		for (int i = random[gold](4,7); i > 0; i--) {
			let gg = Spawn("PK_GoldCoin",pos + (0,0,zofs*frandom[gold](0.8,1.2)));
			if (gg)
				gg.vel = (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](2,5));
		}
		for (int i = random[gold](0,3); i > 0; i--) {
			let gg = Spawn("PK_MedGold",pos + (0,0,zofs*frandom[gold](0.8,1.2)));
			if (gg)
				gg.vel = (frandom[sfx](-2,2),frandom[sfx](-2,2),frandom[sfx](1,4));
		}
		for (int i = random[sfx](5,8); i > 0; i--) {
			let deb = PK_RandomDebris(Spawn("PK_PropDebris",(pos.x,pos.y,pos.z) + (frandom[sfx](-radius,radius),frandom[sfx](-radius,radius),frandom[sfx](8,height))));
			if (deb) {
				deb.vel = (frandom[sfx](-5,5),frandom[sfx](-5,5),frandom[sfx](2,5));
				deb.target = self;
			}
		}
		super.Die(source, inflictor, dmgflags, MeansOfDeath);
	}
	override void Tick() {
		super.Tick();		
		if (frame == 0 && health <= default.health * 0.6)
			frame = 1;
	}
	States {
	Cache:
		PKP1 A 0;
	Death:
		#### C -1 A_Scream;
		stop;
	}
}

Class PK_PropDebris : PK_RandomDebris {
	Default {
		+PUFFGETSOWNER
		scale 0.3;
		renderstyle 'Shaded';
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (target && target is "PK_GoldContainer") {
			double targetAngle = -AngleTo(target) + frandom[debris](-40,40);
			VelFromAngle(frandom[debris](1,2),targetAngle);
			vel.z = frandom[debris](2,4);
			let prop = PK_GoldContainer(target);
			SetShade(prop.debriscolor);
		}
	}
}
	
Class PK_BreakableChest : PK_GoldContainer {
	Default {
		deathsound "props/chest/death";
	}
	states {
	Spawn:
		PKP1 A -1;
		stop;
	}
}

class PK_ExplosiveBarrel : ExplosiveBarrel {
	protected transient CVar s_particles;
	Default {
		scale 0.5;
		Deathsound "props/barrelExplode";
	}
	
	States {
	Cache:
		PBAS ABCDEF 0;
	Spawn:
		PBAR Z 1 {
			if (health <= 14)
				frame = 0;
		}
		loop;
	Death:
		TNT1 A 0 {
			A_Scream();
			A_SpawnItemEx("PK_BarrelExplosion", zofs:26, zvel: 0.5, flags:SXF_SETMASTER);
			A_SpawnItemEx("PK_GoldCoin", zofs:26, 
				xvel: frandom[coin](-0.5,0.5),
				yvel: frandom[coin](-0.5,0.5),
				zvel: frandom[coin](14,17)
			);
		}
		PBAR BC 3;
		PBAR D 4 {			
			A_Quake(2,12,0,220,"");
			if (random[bar](0,1) == 1)
				frame++;
			if (!s_particles)
				s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
			if (s_particles.GetInt() >= 1) {
				A_SpawnItemEx("PK_ExplosiveBarrelTop", zofs:default.height,
					xvel: frandom[sfx](-1,1),
					yvel: frandom[sfx](-1,1),
					zvel: frandom[sfx](13,20)
				);
			}
			if (s_particles.GetInt() >= 2) {
				for (int i = 0; i < 6; i++) {
					let prt = PK_RandomDebris( Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8), frandom[sfx](8,default.height))) );
					if (prt) {
						prt.scale = (0.5,0.5);
						prt.spritename = 'PBAS';
						prt.frame = i;
						prt.vel = (frandom[sfx](-6,6),frandom[sfx](-6,6), frandom[sfx](6,12));
						prt.randomroll = false;
						prt.wrot = 7;
					}
				}
				for (int i = random[sfx](8,14); i > 0; i--) {
					let debris = Spawn("PK_SmokingDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
					if (debris) {
						debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10), frandom[sfx](7,15));
					}
				}
			}
		}
		PBAR # 1065 {
			A_Explode();
			A_Noblocking();
		}
		TNT1 A 5 {
			if (multiplayer && sv_barrelrespawn)
				A_Respawn();
		}
		wait;
	}
}

class PK_ExplosiveBarrelTop : PK_SmallDebris {
	Default {
		PK_SmallDebris.dbrake 0.8;
		scale 0.5;
		-FORCEXYBILLBOARD
	}
	States {
	Spawn:
		PBAR F -1;
		stop;
	Death:
		PBAR G -1;
		stop;
	}
}

class PK_BarrelExplosion : PK_SmallDebris {
	Default {
		scale 0.5;
		+NOINTERACTION;
		renderstyle 'translucent';
		+BRIGHT;
		alpha 2;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = frandom[sfx](-60,60);
	}
	override void Tick() {		
		scale *= 1.014;
		if (master)
			SetOrigin((master.pos.x, master.pos.y, pos.z), true);
		if (!isFrozen())
			A_FadeOut(0.035);
		super.Tick();
	}
	States {
	Spawn:
		BOM4 ACEGHJLMNOPQ 1;
		BOM5 ABCDEF 2 { vel.z *= 0.95; }
		BOM5 GHIJKLMN 3 { vel.z *= 0.9; }
		wait;
	}
}