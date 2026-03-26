class PK_PainkillerPlayer : PK_PlayerPawn {
	double pk_jumpDirAngle;

	Default {
		Player.DisplayName "Painkiller Player";
		Player.Startitem "PK_Painkiller";
		Player.WeaponSlot 1, "PK_Painkiller";
		Player.WeaponSlot 2, "PK_Shotgun";
		Player.WeaponSlot 3, "PK_Stakegun";
		Player.WeaponSlot 4, "PK_Chaingun";	
		Player.WeaponSlot 5, "PK_ElectroDriver";
		Player.WeaponSlot 6, "PK_Rifle";
		Player.WeaponSlot 7, "PK_Boltgun";

		PK_PlayerPawn.AccelerationFactor 0.75;
		PK_PlayerPawn.HorizontalViewBobRange 0.0;
		PK_PlayerPawn.MaxBobFrequency 24;
		PK_PlayerPawn.LandingViewDipDistance 5.0;
		PK_PlayerPawn.VerticalWeaponBobRange 3.5;
		PK_PlayerPawn.HorizontalWeaponBobRange 6.0;
		Speed 1.0;
	}

	// picking up items for Codex:
	override void HasReceived(Inventory item, class<Inventory> itemcls) {
		PK_CodexData data = PK_CodexData.Get(self.PlayerNumber());
		if (data && itemcls) {
			data.TryAddingClass(itemcls);
		}
	}
	
	// Disable demon shader on level change:
	override void PostBeginPlay() {
		Super.PostBeginPlay();
		if (!FindInventory("PK_DemonWeapon") && self.player == players[consoleplayer]) {
			PPShader.SetEnabled("DemonMorph", false);
		}
	}

	// Generic check for whether we're currently mid-jump:
	bool PK_IsJumping() {
		// not on ground, not in water, affected by gravity, not in coyote time:
		return !player.onground && !waterlevel && !bNoGravity && (am_coyoteTime > 0 || player.jumptics != 0) && !PK_IsPlayerFlying();
	}

	// -------------------------------
	// Painkiller aircontrol changes
	// -------------------------------

	// Record relative angle at which we perform a jump:
	override void CheckJump() {
		Super.CheckJump();
		if ((player.cmd.buttons & BT_JUMP) && player.jumptics == -1) {
			pk_jumpDirAngle = Normalize180(self.angle) - self.vel.xy.Angle();
		}
	}

	// When jumping, even if we're not pressing any movement keys,
	// keep the initial jump momentum unchanged and allow redirecting
	// by simply turning camera without having to press any buttons:
	override void MovePlayer() {
		let player = self.player;
		UserCmd cmd = player.cmd;
		if (!cmd.forwardmove && !cmd.sidemove && PK_IsJumping() && !(vel.xy ~== (0,0))) {
			VelFromAngle(vel.xy.Length(), Normalize180(angle) - pk_jumpDirAngle);
		}
		Super.MovePlayer();
	}
	
	override Vector2 PK_ApplyAirControl(Vector2 wishvel) {
		if (PK_IsJumping()) {
			// Painkiller-like aircontrol ignores level.aircontrol entirely):

			// velocity dir (Y needs flipping to compare with input)
			Vector2 velDir = (vel.x, -vel.y).Unit();
			// input dir rotated to be comparable to velocity
			Vector2 inputDir = Actor.RotateVector((player.cmd.forwardmove, player.cmd.sidemove), -angle).Unit();
			// Compare the direction of velocity and input
			// (-1 = opposite, 0 = sideways, 1 = same)
			double dd = velDir.Unit() dot inputDir.Unit();

			// input is ~ same direction of vel - move there directly:
			if (dd > 0.85) {
				return wishvel;
			}
			// input is ~ opposite direction of vel - stop immediately:
			else if (dd < -0.85) {
				return (0,0);
			}
			// sideways input - no effect:
			else {
				return vel.xy;
			}
		}
		return wishvel;
	}
}