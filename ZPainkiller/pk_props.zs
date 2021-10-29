Class PK_GoldContainer : PK_BaseActor abstract {
	color debriscolor;
	property debriscolor : debriscolor;
	Default {
		+SHOOTABLE
		+VULNERABLE
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
		for (int i = 32; i > 0; i--) {
			SetOrigin(FindRandomPosAround(pos, 96),false);
			if (CheckClippingLines(radius*1.5))
				break;
		}
	}
	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath) {
		double zofs = default.height;
		for (int i = random[gold](4,7); i > 0; i--) {
			let gg = Actor.Spawn("PK_GoldCoin",pos + (0,0,zofs*frandom[gold](0.8,1.2)));
			if (gg)
				gg.vel = (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](2,5));
		}
		for (int i = random[gold](0,3); i > 0; i--) {
			let gg = Actor.Spawn("PK_MedGold",pos + (0,0,zofs*frandom[gold](0.8,1.2)));
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
	