Class KillerTargetHandler : EventHandler {
	override void WorldThingDied(worldevent e) {
		if (!e.thing || !e.thing.bISMONSTER || !e.thing.target || e.thing.FindInventory("PK_EnemyDeathControl"))
			return;
		e.thing.GiveInventory("PK_EnemyDeathControl",1);
	}
	override void WorldThingspawned (worldevent e) {
		if (!e.thing || !(e.thing is "PlayerPawn") || e.thing.FindInventory("PK_DemonMorphControl"))
			return;
		e.thing.GiveInventory("PK_DemonMorphControl",1);
	}
}