Class KillerTargetHandler : EventHandler {
	override void WorldThingDied(worldevent e) {
		if (!e.thing || !e.thing.bISMONSTER)
			return;
		actor c = Actor.Spawn("PK_EnemyDeathControl",e.thing.pos);
		if (c)
			c.master = e.thing;
	}
	override void WorldThingspawned (worldevent e) {
		if (!e.thing || !(e.thing is "PlayerPawn") || e.thing.FindInventory("PK_DemonMorphControl"))
			return;
		e.thing.GiveInventory("PK_DemonMorphControl",1);
	}
}