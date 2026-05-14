class PK_PainkillerPlayer : PK_PlayerPawn {
	double pk_jumpDirAngle;
	PK_CodexData codexdata;
	static const String PK_FloorTypes[] = {
		// creaky wood:
		"pkplayer/steps/wood|CEIL1_1,CEIL1_3",
		// dirt/ground:
		"pkplayer/steps/dirt|CEIL5_1,FLAT10,FLAT509,FLAT510,FLAT512,FLAT513,FLAT516,FLAT5_3,FLAT5_5,FLAT5_6,FLOOR6_1,FLOOR6_2,GRASS1,GRASS2,MFLR8_2,MFLR8_3,MFLR8_4,RROCK03,RROCK09,RROCK16,RROCK17,RROCK18,RROCK19,RROCK20",
		// hard/solid wood:
		"pkplayer/steps/woodfloor|CEIL3_1,CEIL3_2,FLAT507,FLAT508,FLAT5_1,FLAT5_2,FLOOR7_1",
		// hard/solid metal:
		"pkplayer/steps/metalbig|CEIL5_2,FLAT22,FLAT23,FLOOR0_5,FLOOR0_6,FLOOR0_7,FLOOR3_3,FLOOR4_8,FLOOR5_1,GATE1,GATE2,GATE3,GATE4,STEP1,STEP2",
		// thin metal/metal sheets:
		"pkplayer/steps/metal|CEIL1_2,CONS1_1,CONS1_5,CONS1_7,FLAT1_3,FLAT3,FLAT4,FLOOR08,FLOOR4_1,FLOOR4_5,SLIME14,SLIME15,SLIME16",
		// carpet/sand:
		"pkplayer/steps/sand|CEIL4_1,CEIL4_2,CEIL4_3,FLAT14,FLAT17,FLAT18,FLAT19,FLAT2,FLAT9,FLOOR1_1,FLOOR1_7",
		// solid stone:
		"pkplayer/steps/stone|CEIL3_5,CEIL3_6,COMP01,DEM1_1,DEM1_2,DEM1_3,DEM1_4,DEM1_5,DEM1_6,FLAT1,FLAT1_1,FLAT1_2,FLAT5,FLAT502,FLAT503,FLAT504,FLAT506,FLAT520,FLAT521,FLAT522,FLAT523,FLAT5_4,FLAT5_7,FLAT5_8,FLAT8,FLOOR00,FLOOR01,FLOOR03,FLOOR04,FLOOR05,FLOOR06,FLOOR07,FLOOR09,FLOOR10,FLOOR11,FLOOR12,FLOOR16,FLOOR17,FLOOR18,FLOOR19,FLOOR20,FLOOR21,FLOOR22,FLOOR23,FLOOR24,FLOOR25,FLOOR26,FLOOR27,FLOOR28,FLOOR29,FLOOR30,FLOOR5_4,FLOOR7_2,FLTTELE1,FLTTELE2,FLTTELE3,FLTTELE4,GRNROCK,MFLR8_1,RROCK01,RROCK02,RROCK04,RROCK05,RROCK06,RROCK07,RROCK08,RROCK10,RROCK11,RROCK12,RROCK13,RROCK14,RROCK15,SLIME09,SLIME10,SLIME11,SLIME12,SLIME13",
		// solid tile (same as stone):
		"pkplayer/steps/stone|CEIL3_3,CEIL3_4,CRATOP1,CRATOP2,FLAT20,FLAT500,FLAT517,FLOOR0_1,FLOOR0_2,FLOOR0_3,FLOOR1_6,FLOOR4_6,FLOOR5_2,FLOOR5_3,GRNLITE1,TLITE6_1,TLITE6_4,TLITE6_5,TLITE6_6",
		// semi-shallow water:
		"pkplayer/steps/wet|BLOOD1,BLOOD2,BLOOD3,FLTFLWW1,FLTFLWW2,FLTFLWW3,FLTSLUD1,FLTSLUD2,FLTSLUD3,FLTWAWA1,FLTWAWA2,FLTWAWA3,FWATER1,FWATER2,FWATER3,FWATER4,NUKAGE1,NUKAGE2,NUKAGE3,SLIME01,SLIME02,SLIME03,SLIME04,SLIME05,SLIME06,SLIME07,SLIME08",
		// goop/slime/swamp:
		"pkplayer/steps/swamp|FLATHUH1,FLATHUH2,FLATHUH3,FLATHUH4,FLTLAVA1,FLTLAVA2,FLTLAVA3,FLTLAVA4,LAVA1,LAVA2,LAVA3,LAVA4",
		// guts/meat:
		"pkplayer/steps/meat|SFLR6_1,SFLR6_4,SFLR7_1,SFLR7_4"
	};

	Map<name, Sound> pk_floorsounds;

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

		PK_PlayerPawn.AccelerationFactor 0.3;
		PK_PlayerPawn.HorizontalViewBobRange 0.0;
		PK_PlayerPawn.MaxFootstepFrequency 30.0;
		PK_PlayerPawn.MaxBobFrequency 24;
		PK_PlayerPawn.LandingViewDipDistance 5.0;
		PK_PlayerPawn.VerticalWeaponBobRange 3.5;
		PK_PlayerPawn.HorizontalWeaponBobRange 6.0;
		Speed 1.0;
	}

	// picking up items for Codex:
	override void HasReceived(Inventory item, class<Inventory> itemcls) {
		if (!codexdata)
			codexdata = PK_CodexData.Get(self.PlayerNumber());
		else if (itemcls) {
			codexdata.TryAddToCodex(itemcls);
		}
	}
	
	// Disable demon shader on level change:
	override void PostBeginPlay() {
		Super.PostBeginPlay();
		PK_BuildFootstepSounds();
		if (!FindInventory("PK_DemonWeapon") && self.player == players[consoleplayer]) {
			PPShader.SetEnabled("DemonMorph", false);
		}
	}

	// -----------------------------------
	// Footstep sounds (TERRAIN-agnostic)
	// -----------------------------------

	void PK_BuildFootstepSounds() {
		Sound snd;
		String texturelist;
		array<String> definition;
		for (int d = PK_FloorTypes.Size() - 1; d >= 0; d--) {
			definition.Clear();
			PK_FloorTypes[d].Split(definition,"|");
			snd = definition[0];
			texturelist = definition[1];
			definition.Clear();
			texturelist.Split(definition, ",");
			foreach (texname : definition) {
				//Console.Printf("Sound: \cd%s\c- | Texturelist: \cy%s\c-", snd, texname);
				pk_floorsounds.Insert(texname, snd);
			}
		}
	}

	Sound PK_FindFootstepSound(TextureID tex) {
		if (!tex.IsValid() || tex == skyflatnum) return "";
		if (pk_floorsounds.CountUsed() <= 1) {
			PK_BuildFootstepSounds();
		}
		name texname = TexMan.GetName(tex);
		Sound snd = pk_floorsounds.Get(texname);
		if (!snd) {
			snd = "pkplayer/steps/dirt";
		}
		return snd;
	}

	override void PK_PlayFootstep(EStepMode mode)
	{
		Sound snd;
		let ter = self.GetFloorTerrain();
		// shallow water:
		if (ter && ter.IsLiquid && ter.footclip < 10)
		{
			snd = "pkplayer/steps/wetsmall";
		}
		// any other floor:
		else
		{
			snd = PK_FindFootstepSound(self.floorpic);
		}
		if (snd) {
			A_StartSound(snd, 8, CHANF_OVERLAP);
		}
	}

	// -------------------------------
	// Painkiller aircontrol changes
	// -------------------------------

	// Allow continuous jumping if pkzm_autojump CVar is true:
	override bool PK_IsJumpingAllowed() {
		return (!(player.oldbuttons & BT_JUMP) || pkzm_autojump) &&
		       player.crouchfactor > 0.5 &&
		       level.IsJumpingAllowed() &&
		       (player.onground || am_coyotetime) &&
		       player.jumpTics >= 0;
	}

	// Generic check for whether we're currently mid-jump:
	bool PK_IsJumping() {
		// not on ground, not in water, affected by gravity, not in coyote time:
		return /*player.jumptics != 0 && */!player.onground && !waterlevel && !bNoGravity && !PK_IsPlayerFlying();
	}

	// Record relative angle at which we perform a jump:
	override void CheckJump() {
		if (!pk_movement) {
			DoomPlayer.CheckJump();
			return;
		}
		Super.CheckJump();
		if ((player.cmd.buttons & BT_JUMP) && player.jumptics == -1) {
			pk_jumpDirAngle = Normalize180(self.angle) - self.vel.xy.Angle();
		}
	}

	// When jumping, even if we're not pressing any movement keys,
	// keep the initial jump momentum unchanged and allow redirecting
	// by simply turning camera without having to press any buttons:
	override void MovePlayer() {
		if (!pk_movement) {
			DoomPlayer.MovePlayer();
			return;
		}
		let player = self.player;
		UserCmd cmd = player.cmd;
		if (!cmd.forwardmove && !cmd.sidemove && PK_IsJumping() && !(vel.xy ~== (0,0))) {
			VelFromAngle(vel.xy.Length(), Normalize180(angle) - pk_jumpDirAngle);
		}
		Super.MovePlayer();
	}
	
	override Vector2 PK_ApplyAirControl(Vector2 wishvel) {
		if (!PK_IsJumping()) {
			return Super.PK_ApplyAirControl(wishvel);
		}
		// Painkiller-like aircontrol (ignores level.aircontrol entirely):

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

	override void DeathThink() {
		if ((player.cmd.buttons & BT_USE || ((deathmatch || alwaysapplydmflags) && sv_forcerespawn)) && !sv_norespawn) {
			if (Level.maptime >= player.respawn_time || ((player.cmd.buttons & BT_USE) && player.Bot == NULL)) {
				player.cls = NULL;		// Force a new class if the player is using a random class
				player.playerstate = (multiplayer || level.AllowRespawn || sv_singleplayerrespawn || G_SkillPropertyInt(SKILLP_PlayerRespawn)) ? PST_REBORN : PST_ENTER;
				if (special1 > 2) {
					special1 = 0;
				}
			}
		}
	}

	override void PlayerThink() {
		if (!pk_movement) {
			DoomPlayer.PlayerThink();
			return;
		}
		Super.PlayerThink();
	}

	override double, double TweakSpeeds (double forward, double side) {
		double d1, d2;
		if (!pk_movement) {
			[d1, d2] = DoomPlayer.TweakSpeeds(forward, side);
		}
		else {
			[d1, d2] = Super.TweakSpeeds(forward, side);
		}
		return d1, d2;
	}

	override Vector2 BobWeapon (double ticfrac) {
		if (!pk_movement) {
			return DoomPlayer.BobWeapon(ticfrac);
		}
		return Super.BobWeapon(ticfrac);
	}

	override void PlayerLandedMakeGruntSound(Actor onmobj) {
		if (!pk_movement) {
			DoomPlayer.PlayerLandedMakeGruntSound(onmobj);
		}
	}

	override void CheckCrouch(bool totallyfrozen) {
		if (!pk_movement) {
			DoomPlayer.CheckCrouch(totallyfrozen);
			return;
		}
		Super.CheckCrouch(totallyfrozen);
	}

	override void CalcHeight() {
		if (!pk_movement) {
			DoomPlayer.CalcHeight();
			return;
		}
		Super.CalcHeight();
	}

	override void FallAndSink(double grav, double oldfloorz) {
		if (!pk_movement) {
			DoomPlayer.FallAndSink(grav, oldfloorz);
			return;
		}
		Super.FallAndSink(grav, oldfloorz);
		if (floorz < oldfloorz && player.jumptics == 0) {
			pk_jumpDirAngle = Normalize180(self.angle) - self.vel.xy.Angle();
		}
	}
}