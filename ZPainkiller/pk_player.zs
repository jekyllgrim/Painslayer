/*
	This is a significantly gutted version of Painkiller player
	from ZMovement by Ivory Duke.
	
	Dash, Double jump, weird wall friction options and acrobatics 
	have been cut out since they're not needed in the mod.
	
	All CVARs except autojump have been converted into consts,
	since again, there's no reason to let the player change all 
	of these values.
	
*/


Class PK_PainkillerPlayer : DoomPlayer
{
	//===============================================
	//General
	const	zm_friction			= 8.0;
	const	zm_maxgroundspeed		= 12;
	const	zm_maxhopspeed			= 28;
	const	zm_walkspeed			= 0.7;
	const	zm_crouchspeed			= 0.7;
	const	zm_strafemodifier		= 1.0;

	//==============
	//Jumping
	const 	zm_jumpheight			= 5.5;
	const	zm_setgravity			= 0.56;
	const 	pk_bhopjumpheight		= 0.85;

	//Jump Landing
	const	zm_landingsens			= 6.0;
	const	zm_landingspeed		= 0.25;
	const	zm_minlanding			= 0.5;

	//==============
	//Bobbing

	//Sway
	const	zm_swayspeed			= 2;
	const	zm_swayrange			= 25;

	//Y Offset
	const	zm_offsetspeed			= 2;
	const	zm_offsetrange			= 25;

	//===============================================
	//Painkiller
	const	pk_acceleration			= 1.0;



	//=========================
	//Common
	
	const BOB_MIN_REALIGN 	 = 0.25f;
	const GROUND_DASH_COOLER = 18;
	
	//Movement General
	bool	Pain;
	double	ViewAngleDelta;
	double	ActualSpeed;
	double	MaxAirSpeed;
	double 	MaxGroundSpeed;
	double	MoveFactor;
	int		AnimateJump;
	int		ForceVelocity;
	int		OldFloorZ;
	playerinfo ZMPlayer;
	vector2 OldVelXY;
	vector3	Acceleration;
	
	//////////////////
	
	//Jumping
	bool 	BlockJump;
	bool	Jumped;
	double	FloorAngle;
	int		DoubleJumpCooler;
	int		JumpSoundCooler;
	
	//Double Jump
	bool	BlockDoubleJump;
	bool	CanDoubleJump;
	
	//////////////////
	
	//Double Tap
	int		FirstTapTime;
	int		FirstTapValue;
	int		OldTapValue;
		
	//////////////////
	
	//View Bobbing
	bool	PostLandingBob;
	double	ZMBob;
	
	//Weapon bobbing
	bool	DoBob;
	double	BobTime;
	double	HorizontalSway;
	double	BobRange;
	double 	OldTicFrac;
	double	VerticalOffset;
	
	//=========================
	//Painkiller only
	
	//Movement
	bool	TrickFailed;
	double	AirControl;
	double	ActualMaxAirSpeed;
	
	//Jumping
	double	TrickJumpAngle;
	int		SmallerJumpHeight;
	
	Default
    {
		Player.DisplayName "Painkiller Player";
		Player.Startitem "PK_Painkiller";
		Player.WeaponSlot 1, "PK_Painkiller";
		Player.WeaponSlot 2, "PK_Shotgun";
		Player.WeaponSlot 3, "PK_Stakegun";
		Player.WeaponSlot 4, "PK_Chaingun";	
		Player.WeaponSlot 5, "PK_ElectroDriver";
		Player.WeaponSlot 6, "PK_Rifle";
		Player.WeaponSlot 7, "PK_Boltgun";
    }
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////
	////																						////
	//// Non-Movement Stuff																		////
	////																						////
	////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////
	
	//Because GZDoom's Unit() returns NaN if a vector has no value
	vector3 SafeUnit3(Vector3 VecToUnit)
	{
		if(VecToUnit.Length()) { VecToUnit /= VecToUnit.Length(); }
		return VecToUnit;
	}
	
	vector2 SafeUnit2(Vector2 VecToUnit)
	{
		if(VecToUnit.Length()) { VecToUnit /= VecToUnit.Length(); }
		return VecToUnit;
	}
	
	/*Override void PostBeginPlay()
	{
		Super.PostBeginPlay();		
		//No voodoo dolls allowed past this point
		if(!self.player || self.player.mo != self) 
			return;
		bNOFRICTION = True;
	}*/
	
	Override void Tick()
	{
		Super.Tick();
		if (pk_movement)
			bNOFRICTION = self.player && self.player.mo == self;
		else			
			bNOFRICTION = default.bNOFRICTION;
	}
	
	Override void PlayerThink()
	{
		if (!pk_movement) {
			gravity = default.gravity;
			super.PlayerThink();
			return;
		}
		//======================================
		//Store info needed in multiple places
		
		ZMPlayer = self.player;
		ActualSpeed = Speed * GetPowerSpeed();
		MaxGroundSpeed = zm_maxgroundspeed * ActualSpeed;
		MoveFactor = ScaleMovement();
		Pain = InStateSequence(CurState, FindState("Pain"));
		ZMPlayer.OnGround = Pos.Z <= FloorZ || bONMOBJ || bMBFBOUNCER || (ZMPlayer.Cheats & CF_NOCLIP2);
		
		//======================================
		//Execute Player tic cycle
		
		CheckFOV();
		
		if(ZMPlayer.inventorytics) { ZMPlayer.inventorytics--; }
		CheckCheats();

		bool totallyfrozen = CheckFrozen();

		// Handle crouching
		CheckCrouch(totallyfrozen);
		CheckMusicChange();

		if(ZMPlayer.playerstate == PST_DEAD)
		{
			DeathThink();
			return;
		}
		if(ZMPlayer.morphTics && !(ZMPlayer.cheats & CF_PREDICTING)) { MorphPlayerThink (); }

		CheckPitch();
		HandleMovement();
		CalcHeight();

		if(!(ZMPlayer.cheats & CF_PREDICTING))
		{
			CheckEnvironment();
			// Note that after this point the PlayerPawn may have changed due to getting unmorphed or getting its skull popped so 'self' is no longer safe to use.
			// This also must not read mo into a local variable because several functions in this block can change the attached PlayerPawn.
			ZMPlayer.mo.CheckUse();
			ZMPlayer.mo.CheckUndoMorph();
			// Cycle psprites.
			ZMPlayer.mo.TickPSprites();
			// Other Counters
			if(ZMPlayer.damagecount) ZMPlayer.damagecount--;
			if(ZMPlayer.bonuscount) ZMPlayer.bonuscount--;

			if(ZMPlayer.hazardcount)
			{
				ZMPlayer.hazardcount--;
				if(!(Level.maptime % ZMPlayer.hazardinterval) && ZMPlayer.hazardcount > 16*TICRATE)
					ZMPlayer.mo.DamageMobj (NULL, NULL, 5, ZMPlayer.hazardtype);
			}
			ZMPlayer.mo.CheckPoison();
			ZMPlayer.mo.CheckDegeneration();
			ZMPlayer.mo.CheckAirSupply();
		}
		
		//Bob weapon stuff
		BobWeaponAuxiliary();
		
		//Old values for comparisons
		OldFloorZ = FloorZ;
		OldVelXY = Vel.XY;
	}
	
	double GetPowerSpeed()
	{
		double factor = 1.f;
		
		if(!ZMPlayer.morphTics)
		{
			for(let it = Inv; it != null; it = it.Inv)
			{
				factor *= it.GetSpeedFactor();
			}
		}
		
		return factor;
	}
	
	Override void DeathThink()
	{
		if (!pk_movement) {
			super.DeathThink();
			return;
		}
		bNOFRICTION = False;
		Gravity = zm_setgravity;
		
		Super.DeathThink();
	}
	
	Override void CalcHeight()
	{
		if (!pk_movement) {
			super.CalcHeight();
			return;
		}
		
		Usercmd cmd = ZMPlayer.cmd;
		
		double HeightAngle;
		double bob;
		bool still = false;

		if(!ZMPlayer.OnGround || (ZMPlayer.OnGround && ((cmd.buttons & BT_JUMP) && !BlockJump)) || ZMPlayer.cheats & CF_NOCLIP2) //nobody walks in the air
		{
			ZMBob--;
			ZMBob = max(bNOGRAVITY ? 0.5f : 0.f, ZMBob);
			PostLandingBob = True;
		}
		else
		{
			if(PostLandingBob)
			{
				ZMBob += Vel.XY.Length() / (MaxGroundSpeed ? MaxGroundSpeed : 1.f);
				if(ZMBob >= Vel.XY.Length() * ZMPlayer.GetMoveBob()) { PostLandingBob = False; }
			}
			else
			{
				ZMBob = Vel.XY.Length() * ZMPlayer.GetMoveBob(); //this way all GetMoveBob() values are meaningful
			}
			
			if(!ZMBob)
				still = true;
			else
				ZMBob = min(MaxGroundSpeed, ZMBob);
		}

		double defaultviewheight = ViewHeight + ZMPlayer.crouchviewdelta;

		if(ZMPlayer.cheats & CF_NOVELOCITY)
		{
			ZMPlayer.viewz = pos.Z + defaultviewheight;

			if(ZMPlayer.viewz > ceilingz-4)
				ZMPlayer.viewz = ceilingz-4;

			return;
		}

		if(still)
		{
			if(ZMPlayer.health > 0)
				bob = 2 * ZMPlayer.GetStillBob() * sin(2 * Level.maptime);
			else
				bob = 0;
		}
		else
		{
			HeightAngle = Level.maptime / 20. * 360.;
			bob = ZMBob * sin(HeightAngle) * (waterlevel > 2 ? 0.25f : 0.5f);
		}
		
		if(ZMPlayer.morphTics) { bob = 0; }
		
		//=======================================
		// Customizable Landing
		
		if(ZMPlayer.playerstate == PST_LIVE)
		{
			if(!ZMPlayer.OnGround)
			{
				if(Vel.Z >= 0)
				{
					ZMPlayer.viewheight += ZMPlayer.deltaviewheight;
					ZMPlayer.deltaviewheight += zm_landingspeed * 2.f; //ensure a speedy recovery while in the air
					if(ZMPlayer.viewheight >= defaultviewheight)
					{
						ZMPlayer.deltaviewheight = 0;
						ZMPlayer.viewheight = defaultviewheight;
					}
				}
				else
				{
					ZMPlayer.deltaviewheight = Vel.Z / zm_landingsens;
					ZMPlayer.viewheight = defaultviewheight;
				}
			}
			else
			{
				ZMPlayer.viewheight += ZMPlayer.deltaviewheight;

				if(ZMPlayer.viewheight > defaultviewheight)
				{
					ZMPlayer.viewheight = defaultviewheight;
					ZMPlayer.deltaviewheight = 0;
				}
				else if(ZMPlayer.viewheight < defaultviewheight * zm_minlanding)
				{
					ZMPlayer.viewheight = defaultviewheight * zm_minlanding;
					if(ZMPlayer.deltaviewheight <= 0) { ZMPlayer.deltaviewheight = 1 / 65536.f; }
				}
				
				if(ZMPlayer.deltaviewheight)	
				{
					ZMPlayer.deltaviewheight += zm_landingspeed;
					if(!ZMPlayer.deltaviewheight) { ZMPlayer.deltaviewheight = 1 / 65536.f; }
				}
			}
		}
			
		//Let's highlight the important stuff shall we?
		ZMPlayer.viewz = pos.Z + ZMPlayer.viewheight + (bob * clamp(ViewBob, 0., 1.5));
		
		if(Floorclip && ZMPlayer.playerstate != PST_DEAD && pos.Z <= floorz) { ZMPlayer.viewz -= Floorclip; }
		if(ZMPlayer.viewz > ceilingz - 4) { ZMPlayer.viewz = ceilingz - 4; }
		if(ZMPlayer.viewz < FloorZ + 4) { ZMPlayer.viewz = FloorZ + 4; }
	}
	
	Override void CheckPitch()
	{
		if (!pk_movement) {
			super.CheckPitch();
			return;
		}
		
		Usercmd cmd = ZMPlayer.cmd;
		
		int clook = cmd.pitch;
		if(clook != 0)
		{
			if(clook == -32768)
			{
				ZMPlayer.centering = true;
			}
			else if(!ZMPlayer.centering)
			{
				A_SetPitch(Pitch - clook * (360. / 65536.), SPF_INTERPOLATE);
			}
		}
		
		if(ZMPlayer.centering)
		{
			if(abs(Pitch) > 2.)
			{
				Pitch *= (2. / 3.);
			}
			else
			{
				Pitch = 0.;
				ZMPlayer.centering = false;
				if(PlayerNumber() == consoleplayer)
				{
					LocalViewPitch = 0;
				}
			}
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////
	////																						////
	//// Movement Stuff																			////
	////																						////
	////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////
	
	Override void HandleMovement()
	{
		if (!pk_movement) {
			super.HandleMovement();
			return;
		}
		
		Usercmd cmd = ZMPlayer.cmd;
		
		// [RH] Check for fast turn around
		if(cmd.buttons & BT_TURN180 && !(ZMPlayer.oldbuttons & BT_TURN180)) { ZMPlayer.turnticks = TURN180_TICKS; }

		// Handle movement
		if(reactiontime)
		{ // Player is frozen
			reactiontime--;
		}
		else
		{	
			ViewAngleDelta = cmd.Yaw * (360.0 / 65536.0); //needed for two other things
			
			if(ZMPlayer.TurnTicks) //moved here to save many doubled lines
			{
				ZMPlayer.TurnTicks--;
				A_SetAngle(Angle + (180.0 / TURN180_TICKS), SPF_INTERPOLATE);
			}
			else
			{
				A_SetAngle(Angle + ViewAngleDelta, SPF_INTERPOLATE);
			}
			
			//========================================
			//Gravity
			PainkillerGravity();
			
			//========================================
			//Say no to wall friction
			QuakeWallFriction();
			
			//========================================
			if(WaterLevel >= 2)
			{
				PainkillerWaterMove();
			}
			else if(bNOGRAVITY)
			{
				PainkillerFlyMove();
			}
			else
			{
				PainkillerHandleMove();
			}
			
			//========================================
			//Jumping
			PainkillerJump();
			
			//========================================
			//Misc
			if(ZMPlayer.Cheats & CF_REVERTPLEASE != 0)
			{
				ZMPlayer.Cheats &= ~CF_REVERTPLEASE;
				ZMPlayer.Camera = ZMPlayer.Mo;
			}
			
			CheckMoveUpDown();
		}
	}
	
	void QuakeWallFriction()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		if(ForceVelocity)
		{
			if(OldVelXY.Length() && Vel.XY.Length() && (cmd.forwardmove || cmd.sidemove))
			{
				Vector2 VelUnit = Vel.XY.Unit();
				double VelDot = OldVelXY.Unit() dot VelUnit;
				if(VelDot > 0)
				{
				   if(VelDot > 0.75)
					  VelDot = 1.f;
				   else
					  VelDot /= 0.75;
				   
				   Vel.XY = VelDot * OldVelXY.Length() * VelUnit;
				}
				ForceVelocity--;
			}
			else
			{
				ForceVelocity = 0;
			}
		}
		if(!CheckMove(Pos.XY + Vel.XY)) { ForceVelocity = 2; }
	}
	
	//////////////////////////////////////////
	// Jumping								//
	//////////////////////////////////////////
	
	void PreJumpCommon()
	{
		//Jumptics settings
		if(Jumped && (Player.OnGround || WaterLevel >= 2 || bNOGRAVITY)) { Jumped = False; }
		
		//Jump Sound Cooler
		if(JumpSoundCooler) { JumpSoundCooler--; }
	}
	
	double GetPowerJump()
	{
		double JumpFac = 0.f;
		
		for(let p = Inv; p != null; p = p.Inv)
		{
			let pp = PowerHighJump(p);
			if(pp) { JumpFac = max(JumpFac, pp.Strength); }
		}
		
		return JumpFac;
	}
	
	bool, bool CheckIfJumpable()
	{
		if(CeilingZ - FloorZ <= Height) //sector is just high enough for player to pass through but not jump
		{
			return True, False;
		}
		else
		{
			//===============================
			// Get floor normal
			
			Vector3 FloorNormal;
			F3DFloor ThreeDFloor;
			for(int i = 0; i < FloorSector.Get3DFloorCount(); i++)
			{
				if(FloorSector.Get3DFloor(i).Top.ZAtPoint(Pos.XY) ~== FloorZ)
				{
					ThreeDFloor = FloorSector.Get3DFloor(i);
					break;
				}
			}
			FloorNormal = ThreeDFloor ? - ThreeDFloor.Top.Normal : FloorSector.FloorPlane.Normal;
			FloorAngle = atan2(FloorNormal.XY.Length(), FloorNormal.Z);
			
			//==============================
			//Come to the logical conclusion
			
			if(FloorAngle < 45)
				return BlockJump ? True : False, !FloorAngle ? False : True;
			else
				return ZMPlayer.OnGround ? True : False, True; //floor is too steep
		}
    }
		
	void PainkillerGravity()
	{
		if(WaterLevel >= 2)
		{
			if(Vel.Length() < MaxGroundSpeed / 3.f)
				Gravity = 0.5f;
			else
				Gravity = 0.f;
		}
		else if(bNOGRAVITY)
		{
			Gravity = 0.f;
		}
		else
		{
			Gravity = zm_setgravity;
		}
	}
	
	void PainkillerJump()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		//Common stuff
		PreJumpCommon();
		
		//underwater/flying specific jump behavior are in WaterMove and FlyMove
		if(WaterLevel >= 2 || bNOGRAVITY) { return; }
		
		//Check slope angle and sector height
		Bool SlopedFloor;
		[BlockJump, SlopedFloor] = CheckIfJumpable();
		
		////////////////////////////////
		//Actual Jump
		if(cmd.buttons & BT_JUMP)
		{			
			if(ZMPlayer.crouchoffset != 0)
			{
				ZMPlayer.crouching = 1;
			}
			else if(ZMPlayer.onground && !BlockJump)
			{
				SmallerJumpHeight++;
				
				double JumpVelZ = zm_jumpheight;
				double JumpFac = GetPowerJump();
				if(JumpFac) { JumpVelZ *= JumpFac; }
					
				Vel.Z += (SmallerJumpHeight > 1 ? pk_bhopjumpheight : 1) * JumpVelZ;
				
				bONMOBJ = false;
				Jumped = True;
				
				if(!(ZMPlayer.cheats & CF_PREDICTING) && !JumpSoundCooler)
				{
					A_StartSound("*jump", CHAN_BODY);
					JumpSoundCooler = 4;
				}
				
				//if autojump is on set Blockjump false while jump key is pressed
				BlockJump = !pkzm_autojump;
			}
		}
		else
		{
			BlockJump = False;
		}
	}
	
	//////////////////////////////////////////
	// Ground Movement						//
	//////////////////////////////////////////
	
	double ScaleMovement()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		double MoveMulti;
		if(cmd.sidemove || cmd.forwardmove)
		{
			Bool IsWalking = (cl_run && (cmd.buttons & BT_SPEED)) || (!cl_run && !(cmd.buttons & BT_SPEED));
			
			if(ZMPlayer.CrouchFactor == 0.5)
				MoveMulti = min(zm_crouchspeed, zm_walkspeed);
			else if(IsWalking)
				MoveMulti = zm_walkspeed;
			else
				MoveMulti = 1;
		}
		else
		{
			MoveMulti = 1;
		}
		
		return MoveMulti;
	}
	
	double SpeedMulti()
	{
		return MoveFactor * (ZMPlayer.cmd.forwardmove && ZMPlayer.cmd.sidemove ? zm_strafemodifier : 1);
	}
	
	double AccelMulti()
	{
		return ActualSpeed * (ZMPlayer.cmd.forwardmove && ZMPlayer.cmd.sidemove ? zm_strafemodifier : 1);
	}
	
	void GroundSpriteAnimation()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		if(ZMPlayer.Cheats & CF_PREDICTING == 0 && Vel.XY.Length() > 1.f && (cmd.forwardmove || cmd.sidemove))
			PlayRunning();
		else
			PlayIdle();
			
		AnimateJump = 6;
	}
	
	void AirSpriteAnimation()
	{
		if(AnimateJump)
		{
			PlayRunning();
			AnimateJump--;
		}
		else
		{
			PlayIdle();
		}
	}
	
	//////////////////////////////////////////
	// Painkiller
	
	void PainkillerHandleMove()
	{
		if(!ZMPlayer.OnGround || (ZMPlayer.OnGround && ((ZMPlayer.cmd.buttons & BT_JUMP) && !BlockJump)))
		{
			PainkillerAirMove();
		}
		else
		{
			MaxGroundSpeed *= SpeedMulti();
			PainkillerGroundMove();
		}
	}
	
	void PainkillerFriction()
	{
		//Going too slow, stop
		if(WaterLevel >= 2 || bNOGRAVITY)
		{
			if(Vel.Length() < 1.f)
			{
				Vel.XY = (0, 0);
				return;
			}
		}
		else if(Vel.XY.Length() < 1.f)
		{
			Vel.XY = (0, 0);
			return;
		}
		
		double Friction; //I modded PK to print to console the length of the velocity vector and it increased and decreased by a fixed value
		if(WaterLevel >= 2 || bNOGRAVITY)
		{
			Friction = MaxGroundSpeed / (WaterLevel >= 2 ? 2.f : 10.f);
			
			if(Vel.Length() >= Friction)
				Vel -= Friction * SafeUnit3(Vel);
			else if(Vel.Length())
				Vel -= Vel.Length() * SafeUnit3(Vel);
		}
		else
		{
			Friction = MaxGroundSpeed / (12.f - zm_friction);
			
			if(Vel.XY.Length() >= Friction)
				Vel.XY -= Friction * SafeUnit2(Vel.XY);
			else if(Vel.XY.Length())
				Vel.XY -= Vel.XY.Length() * SafeUnit2(Vel.XY);
		}
	}
	
	void PainkillerValuesReset()
	{
		MaxAirSpeed = ActualMaxAirSpeed = max(Vel.XY.Length(), MaxGroundSpeed / 4.f);
		SmallerJumpHeight = TrickFailed = 0;
		AirControl = 1;
	}
	
	void PainkillerGroundMove()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		//Values Reset
		PainkillerValuesReset();
		
		//====================================
		//Actual Movement
		
		//Directional inputs
		Acceleration.XY = (cmd.forwardmove, - cmd.sidemove);
		Acceleration.XY = MaxGroundSpeed * 0.6f * SafeUnit2(Acceleration.XY);
		
		//Friction
		PainkillerFriction();
		
		//Acceleration
		Vel.XY += RotateVector(Acceleration.XY, Angle);
		
		//Limiter
		Vel.XY = min(Vel.XY.Length(), MaxGroundSpeed) * SafeUnit2(Vel.XY);
		
		//Sprite Animation
		GroundSpriteAnimation();
	}
	
	void PainkillerAirMove()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		Vector2 DirInput = SafeUnit2((cmd.forwardmove, - cmd.sidemove));
		ActualMaxAirSpeed = Vel.XY.Length(); //if speed is forcefully lowered due to impact with walls or actors we need to get along with that. Not lowering going up stairs
		
		if(!TrickFailed)
		{
			//Air Control
			AirControlCheck(DirInput.Length());
			//Trickjump check
			if(DirInput.Length()) { TrickJumpCheck(DirInput); }
		}
		
		if(ZMPlayer.OnGround) //ground hop
		{
			if(TrickFailed) //Trick jump failed
			{
				Acceleration.XY = MaxAirSpeed * DirInput;
				MaxAirSpeed = MaxGroundSpeed / 2.f; //penalty
				Vel.XY = RotateVector(Acceleration.XY, Angle); //redirect movement in the pressed direction before applying the uber low air control
				AirControl = 0.01f;
				TrickFailed = False;
			}
			else if(AirControl == 1) //regular movement
			{
				//Directional inputs
				Acceleration.XY = MaxAirSpeed * DirInput;
				
				//Top Speed
				if(ZMPlayer.CrouchFactor == 1) { MaxAirSpeed = clamp(Vel.XY.Length() + pk_acceleration * ActualSpeed, MaxGroundSpeed, zm_maxhopspeed); } //no cheap speed up coming out of QSlide
				ActualMaxAirSpeed = MaxAirSpeed;
			}
			else
			{
				//Top Speed
				MaxAirSpeed = clamp(Vel.XY.Length() - pk_acceleration * ActualSpeed, MaxGroundSpeed, zm_maxhopspeed);
			}
			
			//Acceleration
			Vel.XY += RotateVector(Acceleration.XY, Angle) * AirControl;
			
			//Limiter
			Vel.XY = min(Vel.XY.Length(), MaxAirSpeed) * SafeUnit2(Vel.XY);
		}
		else //mid air
		{
			if(TrickFailed) //Trick jump failed
			{
				PainkillerFriction();
			}
			else //regular movement
			{
				//Acceleration
				Vel.XY += RotateVector(Acceleration.XY, Angle) * AirControl;
				
				//Top speed penality
				TopSpeedPenality();
				
				//Limiter
				Vel.XY = min(Vel.XY.Length(), ActualMaxAirSpeed) * SafeUnit2(Vel.XY);
			}
		}
		
		//Sprite Animation
		AirSpriteAnimation();
	}
	
	void AirControlCheck(Bool DirInput)
	{
		if(!DirInput || Pain)
		{
			AirControl = 0.01f;
			if(!DirInput && Vel.XY.Length() <= 1.f)
			{
				Acceleration.XY = (0, 0);
				Vel.XY = (0, 0);
			}
		}
		else
		{
			AirControl = 1;
		}
	}
	
	void TrickJumpCheck(Vector2 DirInput)
	{
		Bool BadTrick = SafeUnit2(Acceleration.XY) dot DirInput <= 0;
		
		if(abs(FloorZ - Pos.Z) > 16)
		{
			if(BadTrick)
				TrickFailed = True;
			else
				TrickJumpAngle = Angle;
		}
		else
		{
			if(BadTrick && abs(Angle - TrickJumpAngle) < 90) { TrickFailed = True; }
		}
	}
	
	void TopSpeedPenality()
	{
		//Directional change top speed penalty
		double AbsViewAngleDelta = abs(ViewAngleDelta);									//In Painkiller speed punishment
		if(AbsViewAngleDelta >= 3.f)													//is 5 times the angle variation,		
			ActualMaxAirSpeed -= AbsViewAngleDelta * 0.01f; //this feels good			//although in that engine view angle
		else																			//is 0 to pi for real world 0 to 180,
			ActualMaxAirSpeed += 0.2f; //this too										//and -pi to 0 for 180 to 360.
		
		ActualMaxAirSpeed = clamp(ActualMaxAirSpeed, MaxGroundSpeed, MaxAirSpeed);		//This is an as close as possible imitation
	}
	
	void PainkillerWaterMove()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		//Value Resets
		PainkillerValuesReset();
		
		//====================================
		//Actual Movement
		
		//Directional inputs
		Acceleration = (cmd.forwardmove, -cmd.sidemove, 0);
		//XY
		Acceleration.XY = (MaxGroundSpeed / 2.f) * SafeUnit2(Acceleration.XY);
		//Z
		if(cmd.buttons & BT_JUMP || cmd.buttons & BT_CROUCH)
		{
			Acceleration.Z = (cmd.buttons & BT_JUMP ? 1 : -1) * 30.f * ActualSpeed;
		}
		else
		{
			Acceleration.Z = Acceleration.X * sin(-Pitch);
			Acceleration.X *= cos(Pitch);
		}
		
		//Friction
		PainkillerFriction();
		
		//Acceleration
		Vel += (RotateVector(Acceleration.XY, Angle), Acceleration.Z);
		
		//Limiter
		Vel = min(Vel.Length(), MaxGroundSpeed / 2.f) * SafeUnit3(Vel);
		
		//Sprite Animation
		GroundSpriteAnimation();
		
		//Set acceleration for when you stop swimming
		Acceleration.XY = 30.f * SafeUnit2(Acceleration.XY);
	}
	
	void PainkillerFlyMove()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		//Value Resets
		PainkillerValuesReset();
		
		//====================================
		//Actual Movement
		
		//Directional inputs
		Acceleration = (cmd.forwardmove, -cmd.sidemove, 0);
		//XY
		Acceleration.XY = (MaxGroundSpeed * 3.f) / 2.f * SafeUnit2(Acceleration.XY);
		//Z
		if(cmd.buttons & BT_JUMP || cmd.buttons & BT_CROUCH)
		{
			Acceleration.Z = (cmd.buttons & BT_JUMP ? 1 : -1) * 30.f * ActualSpeed;
		}
		else
		{
			Acceleration.Z = Acceleration.X * sin(-Pitch);
			Acceleration.X *= cos(Pitch);
		}
		
		//Friction
		PainkillerFriction();
		
		//Acceleration
		Vel += (RotateVector(Acceleration.XY, Angle), Acceleration.Z);
		
		//Limiter
		Vel = min(Vel.Length(), (MaxGroundSpeed * 3.f) / 2.f) * SafeUnit3(Vel);
		
		//Sprite Animatiom
		PlayIdle();
		
		//Set acceleration for when the flight ends
		Acceleration.XY = 30.f * SafeUnit2(Acceleration.XY);
	}
	
	//====================================
	// Quake
	
	void QuakeFriction(double StopSpeed, double Friction)
	{
		if(WaterLevel >= 2 || bNOGRAVITY)
		{
			if(Vel.Length() < 0.5f)
			{
				Vel.XY = (0, 0);
				return;
			}
		}
		else if(Vel.XY.Length() < 1.f)
		{
			Vel.XY = (0, 0);
			return;
		}
		
		if(FloorAngle >= 45 && ZMPlayer.OnGround) //lower friction on steep slopes
		{
			StopSpeed *= 4;
			Friction /= 4;
		}
		
		Double Velocity = Vel.Length();
		Double Drop, Control;
		if(WaterLevel >= 2)
		{
			drop = Velocity * Friction / TICRATE; //very tight friction
		}
		else if(bNOGRAVITY)
		{
			drop = Velocity * Friction / TICRATE; //loose friction
		}
		else if(ZMPlayer.OnGround)
		{
			if(!Pain)
			{
				Control = Velocity < StopSpeed ? zm_friction : Velocity;
				Drop = Control * Friction / TICRATE;
			}
		}
		
		Double NewVelocity = (Velocity - Drop <= 0 ? 0 : Velocity - Drop) / Velocity;
		if(WaterLevel >= 2 || bNOGRAVITY)
			Vel *= NewVelocity;
		else
			Vel.XY *= NewVelocity;
	}
	
	void QuakeAcceleration(Vector3 WishDir, double WishSpeed, double Accel)
	{
		double CurrentSpeed = WishDir dot Vel;
		double AddSpeed = WishSpeed - CurrentSpeed;
		if(AddSpeed <= 0) { return; }
		
		double AccelerationSpeed = min(Accel * WishSpeed / TICRATE, AddSpeed);
		Vel += AccelerationSpeed * WishDir;
	}
	
	//////////////////////////////////////////
	// Crouching							//
	//////////////////////////////////////////
	
	//====================================
	// Regular crouching
	
	Override void CheckCrouch(bool totallyfrozen)
	{
		if (!pk_movement) {
			super.CheckCrouch(totallyfrozen);
			return;
		}
		
		Usercmd cmd = ZMPlayer.cmd;
		
		if(cmd.buttons & BT_JUMP)
		{
			cmd.buttons &= ~BT_CROUCH;
		}
		
		if(ZMPlayer.health > 0)
		{
			if(!totallyfrozen)
			{
				int crouchdir = ZMPlayer.crouching;
				
				if(bNOGRAVITY || WaterLevel >= 2) //forcefully uncrouch when flying/swimming
					crouchdir = 1;
				else if(crouchdir == 0)
					crouchdir = (cmd.buttons & BT_CROUCH) ? -1 : 1;
				else if(cmd.buttons & BT_CROUCH)
					ZMPlayer.crouching = 0;
				
				if(crouchdir == 1 && ZMPlayer.crouchfactor < 1 && pos.Z + height < ceilingz)
					CrouchMove(1);
				else if(crouchdir == -1 && ZMPlayer.crouchfactor > 0.5)
					CrouchMove(-1);
			}
		}
		else
		{
			ZMPlayer.Uncrouch();
		}

		ZMPlayer.crouchoffset = -(ViewHeight) * (1 - ZMPlayer.crouchfactor);
	}
	
	Override void CrouchMove(int direction)
	{
		if (!pk_movement) {
			super.CrouchMove(direction);
			return;
		}
		
		double defaultheight = FullHeight;
		double savedheight = Height;
		double crouchspeed = direction * CROUCHSPEED;
		double oldheight = ZMPlayer.viewheight;

		ZMPlayer.crouchdir = direction;
		ZMPlayer.crouchfactor += crouchspeed;

		// check whether the move is ok
		Height  = defaultheight * ZMPlayer.crouchfactor;
		if(!TryMove(Pos.XY, false, NULL))
		{
			Height = savedheight;
			if(direction > 0)
			{
				// doesn't fit
				ZMPlayer.crouchfactor -= crouchspeed;
				return;
			}
		}
		Height = savedheight;

		ZMPlayer.crouchfactor = clamp(ZMPlayer.crouchfactor, 0.5, 1.);
		ZMPlayer.viewheight = ViewHeight * ZMPlayer.crouchfactor;
		ZMPlayer.crouchviewdelta = ZMPlayer.viewheight - ViewHeight;

		// Check for eyes going above/below fake floor due to crouching motion.
		CheckFakeFloorTriggers(pos.Z + oldheight, true);
	}
	
	//////////////////////////////////////
	// Bobbing							//
	//////////////////////////////////////
	
	void BobWeaponAuxiliary()
	{
		Usercmd cmd = ZMPlayer.cmd;
		
		double Velocity = min(Vel.XY.Length(), zm_maxgroundspeed);
		Bool  InTheAirNoOffset = bNOGRAVITY || WaterLevel >= 2;
		Bool  InTheAir = Jumped || abs(FloorZ - Pos.Z) > 16 || InTheAirNoOffset;
		
		//////////////////////////////////////////
		//Bobbing counter						//
		/////////////////////////////////////////
		
		DoBob = (cmd.forwardmove || cmd.sidemove) && Velocity > 1.f && !InTheAir && !VerticalOffset;
		if(DoBob || BobRange)
			BobTime += Velocity / zm_maxgroundspeed;
		else
			BobTime = 0;
		
		//////////////////////////////////////////
		//Horizontal sway and Vertical offset	//
		//////////////////////////////////////////
		
		Let PWeapon = ZMPlayer.ReadyWeapon;
		if(PWeapon == Null || PWeapon.bDontBob || !(ZMPlayer.WeaponState & WF_WEAPONBOBBING))
		{
			HorizontalSway = VerticalOffset = 0;
			return;
		}
		
		Let WeaponSprite = ZMPlayer.PSprites;
		if(WeaponSprite == Null) { return; }
	}
	
	void GetBobMulti(double ticfrac) //bobbing range and smooth transitioning
	{
		if(DoBob)
		{
			Double BobRangeCandidate = zm_maxgroundspeed * MoveFactor;
			if(BobRangeCandidate == BobRange) { return; }
			
			if(BobRangeCandidate > BobRange)
				BobRange = min(BobRange + abs(OldTicFrac - ticfrac) * abs(BobRangeCandidate - BobRange) / zm_maxgroundspeed, BobRangeCandidate); //make transitions proportional to frame time for fps consistency
			else
				BobRange = max(BobRange - abs(OldTicFrac - ticfrac) * abs(BobRangeCandidate - BobRange) / zm_maxgroundspeed, BobRangeCandidate); //and make the transition proportional to the value difference
		}
		else if(BobRange)
		{
			BobRange = max(BobRange - abs(OldTicFrac - ticfrac), 0);
		}
		OldTicFrac = ticfrac;
	}
	
	Override Vector2 BobWeapon(double ticfrac)
	{
		if (!pk_movement) {
			return super.BobWeapon(ticfrac);
		}
		if(!ZMPlayer) { return (0, 0); }
		
		let weapon = ZMPlayer.ReadyWeapon;
		if(weapon == null) { return (0, 0); }
		
		Vector2 r;
		GetBobMulti(ticfrac);
		int bobstyle = weapon.BobStyle;
		double RangeY = weapon.BobRangeY;
		if(weapon.bDontBob || !BobRange || !(ZMPlayer.WeaponState & WF_WEAPONBOBBING)) //I should add a variable to do this very cleanly but I don't wanna
		{
			BobRange = BobTime = 0;
			switch(bobstyle)
			{
			case Bob_Dusk:
				r.Y = zm_maxgroundspeed * RangeY;
				break;
				
			case Bob_Painkiller:
				r.Y = zm_maxgroundspeed * RangeY;
				break;
					
			case Bob_UT:
				r.Y = zm_maxgroundspeed * RangeY;
			}
			return r;
		}
		
		double BobSpeed = weapon.BobSpeed * 128;
		double bobx = weapon.BobRangeX * BobRange;
		double boby = RangeY * BobRange;
		Vector2 p1, p2;
		
		for(int i = 0; i < 2; i++)
		{
			double BobAngle = BobSpeed * ZMPlayer.GetWBobSpeed() * (BobTime + i - 1) * (360. / 8192.);
			
			switch(bobstyle)
			{
			case Bob_Normal:
				r.X = bobx * cos(BobAngle);
				r.Y = boby * abs(sin(BobAngle));
				break;
			
			case Bob_Inverse:
				r.X = bobx * cos(BobAngle);
				r.Y = boby * (1. - abs(sin(BobAngle)));
				break;
				
			case Bob_Alpha:
				r.X = bobx * sin(BobAngle);
				r.Y = boby * abs(sin(BobAngle));
				break;
			
			case Bob_InverseAlpha:
				r.X = bobx * sin(BobAngle);
				r.Y = boby * (1. - abs(sin(BobAngle)));
				break;
			
			case Bob_Smooth:
				r.X = bobx * cos(BobAngle);
				r.Y = boby * (1. - (cos(BobAngle * 2))) / 2.f;
				break;
			
			case Bob_InverseSmooth:
				r.X = bobx * cos(BobAngle);
				r.Y = boby * (1. + (cos(BobAngle * 2))) / 2.f;
			
			case Bob_Build:
				r.X = 2. * bobx * cos(BobAngle);	
				r.Y = boby * (1. - abs(sin(BobAngle)));
				break;
			
			case Bob_Dusk:
				r.X = bobx * cos((BobAngle * 2.) / 3.);
				r.Y = boby * (cos(2.2 * BobAngle)) + zm_maxgroundspeed * RangeY;
				break;
			
			case Bob_Painkiller:
				r.X = bobx * cos(BobAngle);	
				r.Y = - boby * (1. - abs(sin(BobAngle))) + zm_maxgroundspeed * RangeY;
				break;
							
			case Bob_UT:
				r.X = 1.5 * bobx * cos(BobAngle);	
				r.Y = boby * sin(2. * BobAngle) + zm_maxgroundspeed * RangeY;
			}
			
			if (i == 0) p1 = r; else p2 = r;
		}
		
		return p1 * (1. - ticfrac) + p2 * ticfrac;
	}
}

enum Bobbing
{
	Bob_Normal,
	Bob_Inverse,
	Bob_Alpha,
	Bob_InverseAlpha,
	Bob_Smooth,
	Bob_InverseSmooth,
	Bob_Build,
	Bob_Dusk,
	Bob_Painkiller,
	Bob_UT
}