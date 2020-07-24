Class PK_GoldSoul : Health {
	Default {
		inventory.pickupmessage "Gold Soul!";
		inventory.amount 100;
		inventory.maxamount 100;
		inventory.pickupsound "";
		renderstyle 'Add';
		+NOGRAVITY;
		alpha 0.9;
		xscale 0.4;
		yscale 0.332;
		inventory.pickupsound "pickups/soul/gold";
		+COUNTITEM
		+BRIGHT;
		+RANDOMIZE;
	}
	override void Tick() {
		super.Tick();
		if (isFrozen())
			return;	
		A_SpawnItemEx(
			"GoldSoulparticle",
			xofs: frandom[part](4,10),zofs:frandom[part](16,32),
			xvel:-0.35,zvel:frandom[part](0.5,2),
			angle:frandom[part](0,359)
		);
	}
	states {
	Spawn:
		GSOU ABCDEFGHIJKLMNOPQRSTU 2;
		loop;
	}
}

Class GoldSoulparticle : PK_BaseFlare {
	Default {
		scale 0.025;
		renderstyle 'Add';
		PK_BaseFlare.style 1;
		PK_BaseFlare.fadefactor 0.02;
		PK_BaseFlare.shrinkfactor 0.9;
		alpha 1;
	}
}

Class PK_MegaSoul : PK_GoldSoul {
	Default {
		inventory.amount 200;
		inventory.maxamount 200;
		inventory.pickupsound "pickups/soul/mega";
		inventory.pickupmessage "Mega soul!";
		xscale 0.3;
		yscale 0.25;
		alpha 2.5;
	}
	override void Tick() {
		Actor.Tick();
	}
	states {
	Spawn:
		MSOU ABCDEFGHIJKLMNOPQRSTU 2;
		loop;
	}
}