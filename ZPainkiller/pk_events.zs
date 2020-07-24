Class KillerTargetHandler : EventHandler {
	override void WorldThingDied(worldevent e) {
		if (!e.thing || !e.thing.bISMONSTER)
			return;
		actor c = Actor.Spawn("PK_EnemyDeathControl",e.thing.pos);
		if (c)
			c.master = e.thing;
	}
	array < Class<Actor> > allmonsters;
	override void WorldThingspawned (worldevent e) {
		if (e.thing && (e.thing is "PlayerPawn") && !e.thing.FindInventory("PK_DemonMorphControl"))
			e.thing.GiveInventory("PK_DemonMorphControl",1);
		if (e.thing.bISMONSTER)
			allmonsters.push(e.thing);
	}
}