class PK_PowerupGiverBase : PowerupGiver {
	Default {
		inventory.maxamount 5;
	}
	
	override void BeginPlay() {
		super.BeginPlay();
		usesound = pickupsound;
	}
}