class PK_PlayerPawn : DoomPlayer
{
	enum EStepMode
	{
		PK_STEP_RIGHT,
		PK_STEP_LEFT,
		PK_STEP_BOTH,
	}

	protected bool am_deathrolled;

	protected uint am_coyotetime;
	protected uint am_underwaterTime;

	protected double am_prevbobphase;
	protected double am_bobphase;
	protected double am_prevfootstepphase;
	protected double am_footstepphase;
	protected double am_weapBobDamp;
	protected double am_prevWeapBobDamp;
	protected bool am_blockfootstep;

	protected double am_prevPitch;
	protected double am_curPitch;
	
	protected double am_intrYaw;
	protected double am_prevIntrYaw;
	protected PK_ValueInterpolator am_YawInterpolator;

	protected double am_distToObst;
	protected double am_prevDistToObst;
	protected PK_ValueInterpolator am_obstDistInter;
	
	protected uint am_prevJumpLandTime;
	protected uint am_JumpLandTime;
	protected uint am_JumplandDuration;

	protected int am_prevwaterlevel;
	protected bool am_prevbOnMobj;
	protected double am_prevVelZ;

	protected double am_accelfac;
	property AccelerationFactor			: am_accelfac;

	int am_maxcoyotetime;
	property MaxCoyoteTime				: am_maxcoyotetime;

	double am_maxBobFreq;
	double am_maxFootstepFreq;
	double am_landViewDipDist;
	double am_viewBobRangeVert;
	double am_viewBobrangeHorz;
	double am_weapBobRangeHorz;
	double am_weapBobRangeVert;
	property MaxBobFrequency			: am_maxBobFreq;
	property MaxFootstepFrequency		: am_maxFootstepFreq;
	property LandingViewDipDistance 	: am_landViewDipDist;
	property VerticalViewBobRange		: am_viewBobRangeVert;
	property HorizontalViewBobRange		: am_viewBobrangeHorz;
	property HorizontalWeaponBobRange 	: am_weapBobRangeHorz;
	property VerticalWeaponBobRange		: am_weapBobRangeVert;

	double am_weapLeanPitchRangeMin;
	double am_weapLeanPitchRangeMax;
	double am_weapLeanYawRange;
	double am_weapLeanDistRange;
	property WeaponLeanPitchRangeMin	: am_weapLeanPitchRangeMin;
	property WeaponLeanPitchRangeMax	: am_weapLeanPitchRangeMax;
	property WeaponLeanYawRange			: am_weapLeanYawRange;
	property WeaponLeanDistRange		: am_weapLeanDistRange;

	double am_weap3DLeanPitchRangeMin;
	double am_weap3DLeanPitchRangeMax;
	double am_weap3DLeanYawRange;
	double am_weap3DLeanDistRange;
	property Weapon3DLeanPitchRangeMin	: am_weap3DLeanPitchRangeMin;
	property Weapon3DLeanPitchRangeMax	: am_weap3DLeanPitchRangeMax;
	property Weapon3DLeanYawRange		: am_weap3DLeanYawRange;
	property Weapon3DLeanDistRange		: am_weap3DLeanDistRange;

	Default
	{
		Player.ViewHeight 49;
		Player.GruntSpeed 16;
		Speed 1.0;

		// How quickly player reaches maximum velocity when they start
		// moving. Represents how much of maximum velocity is reached
		// per tic (default 0.2 = ~5 tics to reach maximum velocity).
		// Valid values are in [0.01, 1.0] range.
		PK_playerPawn.AccelerationFactor 0.2;

		// Duration of coyote time in tics (starts counting down as soon as
		// player crosses a ledge):
		PK_PlayerPawn.MaxCoyoteTime 10;

		// Maximum frequency of bobbing, achievable when running at maximum
		// possible speed. Affects both view and weapon bob. Doesn't affect
		// the range of bobbing:
		PK_PlayerPawn.MaxBobFrequency 30.0;
		// Maximum frequency of footstep. If at the default 0.0, footsteps
		// are perfectly synced with view and weapon bobbing (which is
		// usually desirable). If this is positive, footsteps will be
		// calculated separately from view bobbing:
		PK_PlayerPawn.MaxFootstepFrequency 0.0;

		// Maximum vertical (downward) range of view (not weapon) bobbing:
		PK_PlayerPawn.VerticalViewBobRange 5.0;
		// Maximum range of horizontal (side-to-side) view bobbing:
		PK_PlayerPawn.HorizontalViewBobRange 0.3;
		// How far the camera can dip down when landing on the ground:
		PK_PlayerPawn.LandingViewDipDistance 10.0;

		// Maximum horizontal range of weapon bobbing:
		PK_PlayerPawn.HorizontalWeaponBobRange 7.0;
		// Maximum vertical range of weapon bobbing:
		PK_PlayerPawn.VerticalWeaponBobRange 2.3;

		// SPRITE WEAPON BOBBING:

		// How far the weapon can be pushed UP by LOWERING camera
		// (0.0 by default to avoid potential sprite cutoffs):
		PK_PlayerPawn.WeaponLeanPitchRangeMin 0.0; 		// NEGATIVE = HIGHER
		// How far the weapon can be pushed DOWN by RAISING camera:
		PK_PlayerPawn.WeaponLeanPitchRangeMax 14.0;		// POSITIVE = LOWER
		// How far the weapon sprite can be pushed left/right
		// by rotating the camera:
		PK_PlayerPawn.WeaponLeanYawRange 14.0;
		// How far the weapon can be pushed down by approaching
		// a solid actor / wall:
		PK_PlayerPawn.WeaponLeanDistRange 34.0;

		// 3D WEAPON BOBBING:

		// How how far the weapon can pitch UP by LOWERING camera:
		PK_PlayerPawn.Weapon3DLeanPitchRangeMin -6.0; 		// NEGATIVE = HIGHER
		// How far the weapon can pitch DOWN by RAISING camera:
		PK_PlayerPawn.Weapon3DLeanPitchRangeMax 6.0;		// POSITIVE = LOWER
		// How far the weapon can roll sideways by
		// rotating the camera:
		PK_PlayerPawn.Weapon3DLeanYawRange 9.0;
		// How far the weapon move towards the screen
		// by approaching a solid actor / wall:
		PK_PlayerPawn.Weapon3DLeanDistRange 34.0;
	}

	clearscope bool PK_IsPlayerFlying()
	{
		return bFLYCHEAT || (player.cheats & CF_FLY) || (player.cheats & CF_NOCLIP2);
	}
	
	// [AA] Calculates "idealized" maximum run velocity at a given
	// movefactor and friction. By default passes the hardcoded
	// default movefactor and friction values:
	clearscope double PK_GetBaseRunVel( double movefactor = ORIG_FRICTION_FACTOR, double friction = ORIG_FRICTION)
	{
		return (gameinfo.normforwardmove[1] * self.speed * movefactor * (35 / TICRATE)) / (1.0 - friction);
	}

	override void PlayerThink()
	{
		Super.PlayerThink();

		let player = self.player;

		// [AA] Undo rolling applied in DeathThink:
		if (health > 0 && am_deathrolled)
		{
			A_SetViewRoll(0, SPF_INTERPOLATE);
			am_deathrolled = false;
		}

		// [AA] Movement should be predicted:
		
		// [AA] Landing on an actor:
		if (bOnMobj && !am_prevbOnMobj && am_prevVelZ < -4)
		{
			PK_PlayerLanded(am_prevVelz, true);
		}
		am_prevbOnMobj = bOnMobj;
		am_prevVelZ = vel.z;

		// [AA] coyote time:
		if (player.onground || waterlevel > 0)
		{
			am_coyotetime = 0;
		}
		else if (am_coyotetime) am_coyotetime--;
	
		// [AA] update tracked camera pitch:
		am_prevPitch = am_curPitch;
		am_curPitch = self.pitch;

		// [AA] update tracked and lerped yaw values:
		if (!am_YawInterpolator)
		{
			am_YawInterpolator = PK_ValueInterpolator.Create(0, 0.2, 1, 200, true);
		}
		else
		{
			am_YawInterpolator.Update(self.player.cmd.yaw);
		}
		am_prevIntrYaw = am_intrYaw;
		am_intrYaw = am_YawInterpolator.GetValue();

		// [AA] time spent underwater:
		if (am_underwaterTime)
		{
			am_underwaterTime = clamp(am_underwaterTime + waterlevel? 1 : -1, -10, 10);
		}

		// [AA] Keep track of obstacles in front of us:
		am_prevDistToObst = am_distToObst;
		double distToObst = radius*2;
		let tracer = New('PK_CollisionTracer');
		if (tracer)
		{
			tracer.Trace((pos.xy, player.viewz), cursector, (AngleToVector(angle, cos(pitch)), -sin(pitch)), radius*2, TRACE_HitSky, Line.ML_BLOCKEVERYTHING, false, self);
			switch (tracer.results.HitType)
			{
				case TRACE_HitActor:
					let a = tracer.results.HitActor;
					if (!a || !a.bSolid || a.bNoClip || a.bNoInteraction)
					{
						break;
					}
				case TRACE_HitFloor:
				case TRACE_HitCeiling:
				case TRACE_HitWall:
					distToObst = clamp(tracer.results.distance, 0, radius*2);
					break;
			}
		}
		if (!am_obstDistInter)
		{
			am_obstDistInter = PK_ValueInterpolator.Create(0, 0.25, 1, 20, true);
		}
		else
		{
			am_obstDistInter.Update(int(round(distToObst)));
		}
		am_distToObst = am_obstDistInter.GetValue();

		// [AA] This is for weapon bobbing but it has to be
		// calcualted here so it's not frame-dependent:
		am_prevWeapBobDamp = am_weapBobDamp;
		am_weapBobDamp += (!PK_IsPlayerFlying() && (player.weaponstate & WF_WEAPONBOBBING))? 0.05 : -0.1;
		am_weapBobDamp = clamp(am_weapBobDamp, 0.0, 1.0);

		// [AA] Timer for jumping landing (affects vertical weapon bob):
		am_prevJumpLandTime = am_JumpLandTime;
		if (am_JumpLandTime)
		{
			am_JumpLandTime--;
		}

		if (!(player.cheats & CF_PREDICTING))
		{
			// [AA] Landing in water:
			if (am_prevwaterlevel == 0 && waterlevel > 0)
			{
				PK_LandedInLiquid(true, null);
			}
			else if (am_prevwaterlevel > 0 && waterlevel == 0)
			{
				A_StartSound("pkplayer/steps/water-out", CHAN_AUTO);
			}
			am_prevwaterlevel = waterlevel;
		}
	}

	override void MovePlayer ()
	{
		let player = self.player;
		UserCmd cmd = player.cmd;

		if (player.turnticks)
		{
			player.turnticks--;
			Angle += (180. / TURN180_TICKS);
		}
		else
		{
			Angle += cmd.yaw * (360./65536.);
		}

		player.onground = (pos.z <= floorz) || bOnMobj || bMBFBouncer || (player.cheats & CF_NOCLIP2);

		double friction, movefactor;
		[friction, movefactor] = GetFriction();

		if (cmd.forwardmove | cmd.sidemove)
		{
			double forwardmove, sidemove;
			double fm, sm;

			fm = cmd.forwardmove;
			sm = cmd.sidemove;
			[fm, sm] = TweakSpeeds (fm, sm);
			fm *= Speed / 256;
			sm *= Speed / 256;

			// When crouching, speed and bobbing have to be reduced
			// [AA] only when onground:
			if (CanCrouch() && player.crouchfactor != 1 && player.onground)
			{
				fm *= player.crouchfactor;
				sm *= player.crouchfactor;
			}

			// [AA] If we're on a slippery or muddy floor (friction is not equal
			// to default value), we'll just use default Doom movement: add to
			// velocity - this is way easier than trying to reinvent it, and
			// there are relatively few sectors overall that use it. 
			// The only difference from vanilla is that we're not calling Bob()
			// here since we're handling view bob  in a fully custom manner:
			if (player.onground && !waterlevel && !bNOGRAVITY && !(friction ~== ORIG_FRICTION))
			{
				double forwardmove = fm * movefactor * (35 / TICRATE);
				if (forwardmove)
				{
					ForwardThrust(forwardmove, angle);
				}
				double sidemove = sm * movefactor * (35 / TICRATE);
				if (sidemove)
				{
					Thrust(sidemove, angle - 90);
				}
			}

			// [AA] In a normal-friction sector or mid-air we're using custom movement:
			else
			{
				// [AA] We want to start moving at nearly full speed immediately
				// instead of slowly ramping up, fighting against friction. 
				// So, first, calculate intended velocity from the given 
				// values:
				Vector2 accel = (fm, -sm) * movefactor  * (35 / TICRATE);
				Vector2 wishvel = accel / (1.0 - friction);
				// [AA] rotate to current yaw (facing angle):
				wishvel = Actor.RotateVector(wishvel, angle);
				
				// [AA] Since we're not using ForwardThrust(), this bit is
				// moved out of it to still allow underwater movement by
				// by pressing forward:
				if ((waterlevel || bNoGravity) && !(pitch ~== 0) && !player.GetClassicFlight())
				{
					// [AA] Note zpush is calculated from accel, NOT wishvel:
					double zpush = accel.Length() * sin(Pitch);
					if (waterlevel && waterlevel < 2 && zpush < 0)
					{
						zpush = 0;
					}
					vel.z -= zpush;
					// [AA] but wishvel has to be reduced here accordingly,
					// so forward momentum is reduced relative to vertical
					// momentum gained:
					wishvel *= cos(Pitch);
				}

				am_accelfac = clamp(am_accelfac, 0.01, 1.0);
				wishvel /= am_accelfac / (1.0 - friction + am_accelfac);
				wishvel = PK_ApplyAirControl(wishvel);

				// [AA] Finally, modify velocity - not instantly, but
				// over a very short ramp-up period:
				vel.xy += (wishvel - vel.xy) * am_accelfac;
			}

			if (player.cheats & CF_REVERTPLEASE)
			{
				player.cheats &= ~CF_REVERTPLEASE;
				if (!PK_Utils.IsVoodooDoll(self))
				{
					player.camera = player.mo;
				}
			}
		}
		
		// [AA] If the player isn't pressing movement keys at all and is
		// on top of default-friction floor, quickly reduce their
		// velocity to remove the vanilla ever-slippery feel:
		else if (player.onground && !waterlevel && friction <= ORIG_FRICTION && !PK_IsPlayerFlying())
		{
			vel.xy *= friction * 0.5;
		}
	}

	override double, double TweakSpeeds (double forward, double side)
	{
		// [AA] Disable straferunning:
		let player = self.player;
		UserCmd cmd = player.cmd;
		double magn = (forward, side).Length();
		if (magn > 0)
		{
			forward  = forward / magn * 256.0 * ((cmd.buttons & BT_RUN)? gameinfo.normforwardmove[1] : gameinfo.normforwardmove[0]);
			side = side / magn * 256.0 * ((cmd.buttons & BT_RUN)? gameinfo.normsidemove[1] : gameinfo.normsidemove[0]);
		}
		[forward, side] = Super.TweakSpeeds(forward, side);
		return forward, side;
	}

	// [AA] Calculates interpolated values and returns:
	// - movement bob
	// - interpolated pitch
	// - interpolated yaw
	// - interpolated distance to obstacle
	// - interpolated jump/land camera dip
	clearscope Vector2, double, double, double, double PK_CalculateBobValues(double ticfrac)
	{
		let player = self.player;
		Vector2 bob, bob1, bob2, bobrange;
		// [AA] Movement-based bobbing:
		
		// Bobdamp lets the weapon smoothly transition between bobbing
		// and non-bobbing frames by modifying reducing the range.
		// am_prevWeapBobDamp and am_weapBobDamp are calculated in
		// PlayerThink(), then lerp'd here:
		double bobdamp = am_prevWeapBobDamp + (am_weapBobDamp - am_prevWeapBobDamp) * ticfrac;
		double horVelLength = self.vel.xy.Length();
		double baseRunVel = PK_GetBaseRunVel();
		bobrange.x = PK_Utils.LinearMap(horVelLength, 0, baseRunVel, 0, am_weapBobRangeHorz) * bobdamp;
		bobrange.y = PK_Utils.LinearMap(horVelLength, 0, baseRunVel, 0, am_weapBobRangeVert) * bobdamp;
		// deeper downward movement when underwater:
		if (waterlevel) bobrange.y *= 1.8;
		// multiply by weapon-specific bobranges:
		if (player.readyweapon)
		{
			bobrange.x *= player.readyweapon.BobRangeX;
			bobrange.y *= player.readyweapon.BobRangeY;
		}

		double bobphase;
		// Get weapon bob for previous and curernt tic and lerp,
		// as usual:
		for (int i = 0; i < 2; i++)
		{
			bobphase = i == 0? am_prevbobphase : am_bobphase;
			bob.x = (cos(bobphase*0.5)) * -bobrange.x;
			// Faster downward movement to better convey
			// the weight of the weapon:
			double t = (sin(bobphase) + 1.0) * 0.5;
			bob.y = (t ** 2.0) * bobrange.y;
			if (i == 0)
			{
				bob1 = bob;
			}
			else
			{
				bob2 = bob;
			}
		}
		bob.x = bob1.x + (bob2.x - bob1.x)*ticfrac;
		bob.y = bob1.y + (bob2.y - bob1.y)*ticfrac;

		double ipitch, iyaw, idist, idip;

		ipitch = am_prevPitch + (am_curPitch - am_prevPitch) * ticFrac;
		iyaw = am_prevIntrYaw + (am_intrYaw - am_prevIntrYaw) * ticFrac;
		iDist = am_prevDistToObst + (am_distToObst - am_prevDistToObst) * ticfrac;

		// dip weapon based on jumping/landing:
		if (am_JumplandDuration != 0)
		{
			double prevdip = PK_Utils.CubicBezierPulse(am_JumplandDuration, time: am_prevJumpLandTime, 0, 1.2, 0.8, 0.0) * am_landViewDipDist;
			double curdip = PK_Utils.CubicBezierPulse(am_JumplandDuration, time: am_JumpLandTime, 0, 1.2, 0.8, 0.0) * am_landViewDipDist;
			idip = prevdip + (curdip - prevdip) * ticFrac;
		}

		return bob, ipitch, iyaw, idist, idip;
	}

	override Vector3, Vector3 BobWeapon3D (double ticfrac)
	{
		let player = self.player;
		if (!player || !player.readyweapon) return (0,0,0), (0,0,0);

		let [bob, ipitch, iyaw, idist, idip] = PK_CalculateBobValues(ticfrac);
		
		// pitch weapon based on pitch:
		double raise, yaw, depth;
		
		if (am_weap3DLeanPitchRangeMin < 0 || am_weap3DLeanPitchRangeMax > 0)
		{
			raise += PK_Utils.LinearMap(ipitch, 
				am_weap3DLeanPitchRangeMin < 0? 90 : 0,
				am_weap3DLeanPitchRangeMax > 0? -90 : 0,
				am_weap3DLeanPitchRangeMax,
				am_weap3DLeanPitchRangeMin,
				true
			);
		}
		// roll weapon based on yaw:
		if (am_weap3DLeanYawRange > 0)
		{
			yaw = PK_Utils.LinearMap(iyaw, 2000, -2000, -am_weap3DLeanYawRange, am_weap3DLeanYawRange, true);
		}

		// push weapon to screen based on distance to obstacle:
		if (am_weap3DLeanDistRange > 0)
		{
			depth = PK_Utils.LinearMap(idist, radius*2, 0, 0, am_weap3DLeanDistRange, true);
		}
		// dip weapon based on jumping/landing:
		bob.y += idip;

		return (0, raise, depth), (bob.x / 4, bob.y / -4, yaw);
	}

	override Vector2 BobWeapon (double ticfrac)
	{
		let player = self.player;
		if (!player || !player.readyweapon) return (0, 0);

		let [bob, ipitch, iyaw, idist, idip] = PK_CalculateBobValues(ticfrac);

		// dip weapon based on camera pitch (raised camera - dip weapon):
		if (am_weapLeanPitchRangeMin < 0 || am_weapLeanPitchRangeMax > 0)
		{
			bob.y += PK_Utils.LinearMap(ipitch, 
				am_weapLeanPitchRangeMin < 0? 90 : 0,
				am_weapLeanPitchRangeMax > 0? -90 : 0,
				am_weapLeanPitchRangeMin,
				am_weapLeanPitchRangeMax,
				true
			);
		}

		// push weapon left/right when changing angle:
		if (am_weapLeanYawRange > 0)
		{
			bob.x += PK_Utils.LinearMap(iyaw, 2000, -2000, am_weapLeanYawRange, -am_weapLeanYawRange, true);
		}

		// dip weapon based on obstacle in front of us:
		if (am_weapLeanDistRange > 0)
		{
			bob.y += PK_Utils.LinearMap(idist, radius*2, 0, 0, am_weapLeanDistRange, true);
		}

		// dip weapon based on jumping/landing:
		bob.y += idip;

		return bob;
	}

	void PK_SetJumpLandTimer(uint duration)
	{
		am_JumplandDuration = duration;
		am_JumpLandTime = duration;
	}

	// [AA] Plays a sound when landing in water:
	virtual void PK_LandedInLiquid(bool in3dWater, TerrainDef t)
	{
		// Landed into 3d water - play the sound if the velocity
		// is high enough and cheats allow:
		if (in3dWater)
		{
			if (vel.z < -4 && !(player.cheats & CF_NOCLIP) && !(player.cheats & CF_NOCLIP2))
			{
				A_StartSound("*landliquid", CHAN_AUTO);
			}
		}
		// Landed on a flat TERRAIN water - if splash is 0,
		// presumably no splash is assigned, so play a generic
		// liquid sound (otherwise presumably the splash
		// itself will play a sound):
		else if (t.Splash == 0)
		{
			A_StartSound("*landliquid", CHAN_AUTO);
		}
	}

	// [AA] We'll get rid of the original landed-sound-playing
	// function because it's inconsistent and has unclear
	// conditions.
	override void PlayerLandedMakeGruntSound(Actor onmobj)
	{}

	// [AA] This custom version is called for any landing:
	virtual void PK_PlayerLanded(double zvel, bool onMobj = false)
	{
		//Console.Printf("pos.z %.2f | floorz %.2f | vel.z %.2f", pos.z, floorz, vel.z);
		if (self.health <= 0 || waterlevel || bNoGravity || player.cheats & CF_NOCLIP || PK_IsPlayerFlying()) return;

		let t = GetFloorTerrain();
		bool isLiquid = t.IsLiquid;
		// [AA] Landed in liquid:
		if (isLiquid && !onMobj)
		{
			PK_LandedInLiquid(false, t);
		}
		// Landed on hard surface:
		else
		{
			// Low velocity - play footstep sound:
			if (zvel > -10)
			{
				PK_PlayFootstep(PK_STEP_BOTH);
			}
			// High velocity - play landing sound (ideally this should be
			// a custom sound separate from *grunt, as opposed to how it
			// works in vanilla Doom where they're identical):
			else
			{
				A_StartSound("*land", CHAN_AUTO);
			}
			// Additionally play ground sound if it's not the same as *land,
			// like in vanilla:
			if (zvel < -self.player.mo.GruntSpeed)
			{
				A_StartSoundIfNotSame("*land", "*grunt", CHAN_AUTO);
			}
			player.jumptics = clamp(int(round(abs(zvel))), 0, 12);
			PK_SetJumpLandTimer( int(clamp(abs(zvel), 0, 8)) );
		}
	}

	override void CheckCrouch(bool totallyfrozen)
	{
		let player = self.player;
		UserCmd cmd = player.cmd;

		// [AA] Jumping doesn't force uncrouching anymore. However, crouching
		// will work as swimming down instead of letting you "crouch" underwater:
		if (waterlevel > 0 && cmd.buttons & BT_CROUCH)
		{
			vel.z = -4 * speed;
			return;
		}
		if (CanCrouch() && player.health > 0 && level.IsCrouchingAllowed())
		{
			if (!totallyfrozen)
			{
				int crouchdir = player.crouching;
				if (crouchdir == 0)
				{
					crouchdir = (cmd.buttons & BT_CROUCH) ? -1 : 1;
				}
				else if (cmd.buttons & BT_CROUCH)
				{
					player.crouching = 0;
				}

				if (crouchdir == 1 && player.crouchfactor < 1 && pos.Z + height < ceilingz)
				{
					CrouchMove(1);
				}
				else if (crouchdir == -1 && player.crouchfactor > 0.5)
				{
					CrouchMove(-1);
				}
			}
		}
		else
		{
			player.Uncrouch();
		}

		player.crouchoffset = -(ViewHeight) * (1 - player.crouchfactor);
	}

	override void CalcHeight()
	{
		let player = self.player;
		double bob, bobrange, bobfreq, footstepfreq;
	
		// [AA] New view bobbing. This is also used for weapon bobbing
		// (in contrast to vanilla where it's calculated separately).
		if ((player.onground || waterlevel) && !PK_IsPlayerFlying())
		{
			double hvel = vel.xy.length();
			double maxvel = PK_GetBaseRunVel();
			if (waterlevel) hvel *= 0.7;
			bobrange = PK_Utils.LinearMap(hvel, 0, maxvel, 0, am_viewBobRangeVert, true);
			bobfreq = PK_Utils.LinearMap(hvel, 0, maxvel, 0, am_maxBobFreq, true);
			footstepfreq = am_maxFootstepFreq <= 0? bobfreq : PK_Utils.LinearMap(hvel, 0, maxvel, 0, am_maxFootstepFreq, true);
		}
		else
		{
			bobrange = 0;
			bobfreq = 0;
		}
		// [AA] Store previous bobphase and calculate current one
		// (adding bobfreq keeps it stable as movement velocity
		// changes, avoiding any odd jumps):
		am_prevbobphase = am_bobphase;
		am_bobphase += bobfreq;
		// [AA] Same for footsteps:
		am_prevfootstepphase = am_footstepphase;
		am_footstepphase += footstepfreq;
		
		// [AA] Slight vertical bobbing and even slighter yaw bobbing,
		// with range and speed based on velocity:
		bob = sin(am_bobphase) * bobrange;
		A_SetViewAngle(sin(am_bobphase*0.5) * am_viewBobrangeHorz, SPF_INTERPOLATE);

		// [AA] Play footstep sounds at the end of the bob:
		if (cos(am_prevfootstepphase) > 0 && cos(am_footstepphase) <= 0)
		{
			if (!waterlevel)
			{
				PK_PlayFootstep(sin(am_bobphase*0.5) > 0? PK_STEP_LEFT : PK_STEP_RIGHT);
			}
			else
			{
				PK_PlaySwimming();
			}
		}

		// [AA] Slight camera dip at the start/end of a jump:
		int jumptics = abs(player.jumptics);
		if (jumptics > 0)
		{
			bob += PK_Utils.LinearMap(jumptics, 0, 6, 0, am_landViewDipDist, true);
		}

		// [AA] Dip camera down while underwater:
		if (am_underwaterTime)
		{
			bob += clamp(am_underwaterTime, 0, 8);
		}

		//Console.Printf("jumptics %d | bobrange %.1f | bobfreq %.1f | bob %.1f | viewroll %.1f", player.jumptics, bobrange, bobfreq, sin(am_bobphase), viewroll);

		double defaultviewheight = ViewHeight + player.crouchviewdelta;

		if (player.cheats & CF_NOVELOCITY)
		{
			player.viewz = min(pos.Z + defaultviewheight, ceilingz-4);
			return;
		}

		// move viewheight
		if (player.playerstate == PST_LIVE)
		{
			player.viewheight += player.deltaviewheight;

			if (player.viewheight > defaultviewheight)
			{
				player.viewheight = defaultviewheight;
				player.deltaviewheight = 0;
			}
			else if (player.viewheight < (defaultviewheight/2))
			{
				player.viewheight = defaultviewheight/2;
				if (player.deltaviewheight <= 0)
					player.deltaviewheight = 1 / 65536.;
			}

			if (player.deltaviewheight)
			{
				player.deltaviewheight += 0.25;
				if (!player.deltaviewheight)
					player.deltaviewheight = 1/65536.;
			}
		}

		player.viewz = pos.z + player.viewheight - bob;

		if (Floorclip && player.playerstate != PST_DEAD && pos.Z <= floorz)
		{
			player.viewz -= Floorclip;
		}
		player.viewz = clamp(player.viewz, floorz + 4, ceilingz - 4);
			
		// [AA] make sure attack height always matches crosshair:
		attackZOffset = player.viewz - pos.z - height*0.5;
	}

	virtual void PK_PlayFootstep(EStepMode mode)
	{
		let ter = self.GetFloorTerrain();
		if (ter)
		{
			Sound snd_R = ter.RightStepSound? ter.RightStepSound : ter.StepSound;
			Sound snd_L = ter.LeftStepSound? ter.LeftStepSound : snd_R;
			switch (mode)
			{
				case PK_STEP_RIGHT:
					Console.Printf("Right step");
					A_StartSound(snd_R, 8, CHANF_OVERLAP);
					break;
				case PK_STEP_LEFT:
					Console.Printf("Left step");
					A_StartSound(snd_L, 8, CHANF_OVERLAP);
					break;
				case PK_STEP_BOTH:
					Console.Printf("Both steps");
					A_StartSound(snd_R, 8, CHANF_OVERLAP);
					A_StartSoundIfNotSame(snd_L, snd_R, 8, CHANF_OVERLAP);
					break;
			}
		}
	}

	virtual void PK_PlaySwimming()
	{
		A_StartSound("*swimstep", 8, CHANF_OVERLAP);
	}

	override void DeathThink()
	{
		Super.DeathThink();
		if (self is 'PlayerChunk' || self.bIceCorpse) return;

		// [AA] Roll view upon death:
		let player = self.player;
		A_SetViewRoll(PK_Utils.LinearMap(player.viewheight, self.viewheight, 6, 0, 90), SPF_INTERPOLATE);
		am_deathrolled = true;
	}

	// [AA] Will uncomment come 4.15.1
	//override void OnRevive()
	//{
	//	A_SetViewRoll(0, SPF_INTERPOLATE);
	//}

	virtual Vector2 PK_ApplyAirControl(Vector2 wishvel)
	{
		// [AA] Only apply aircontrol when in the air, not flying
		// and not in coyote time:
		if (!player.onground && !waterlevel && !bNoGravity && (am_coyoteTime > 0 || player.jumptics != 0) && !PK_IsPlayerFlying())
		{
			// [AA] Compare the direction of current and desired
			// velocities. If it's aimed in the opposite direction,
			// we reduce the effect of aircontrol to let the player
			// brake more efficiently (better platforming), while
			// still not letting them easily change direction mid
			// jump:
			double ac = level.aircontrol;
			// -1 = opposite, 0 = sideways, 1 = same:
			double dd = vel.xy.Unit() dot wishvel.Unit();
			// [-1, 0] is mapped to [x10, x1] aircontrol multiplier:
			ac *= PK_Utils.LinearMap(dd, -1.0, 0, 10.0, 1.0, true);
			ac = clamp(ac, 0.0, 1.0);
			return vel.xy + (wishvel - vel.xy) * ac;
		}
		return wishvel;
	}

	override void FallAndSink(double grav, double oldfloorz)
	{
		// [AA] No falling in water if the player is moving,
		// or if the player's head is above the water:
		if (waterlevel == 1 || (waterlevel > 1 && vel.xy.LengthSquared() > 2))
		{
			return;
		}

		let player = self.player;
		bool done = false;

		if (pos.z > floorz && waterlevel == 0 && !bNOGRAVITY)
		{
			// Handling for crossing ledges:
			if (vel.z == 0 && pos.z == oldfloorz && oldfloorz > floorz)
			{
				// [AA] Coyote time:
				if (player.jumptics == 0 && am_coyotetime == 0 && level.IsJumpingAllowed())
				{
					am_coyotetime = am_maxcoyotetime;
				}
				else
				{
					vel.z -= grav; // [AA] default is grav * 2
					done = true;
				}
			}
			// reduced gravity effect when jumping:
			else if (player.jumptics < 0)
			{
				vel.z -= grav * 0.8; // [AA] default was 1.0
				done = true;
			}
		}

		// [AA] Call custom landing function when colliding with floor:
		if (!bNOGRAVITY && vel.z < -4 && pos.z <= floorz)
		{
			PK_PlayerLanded(vel.z);
		}

		if (!done)
		{
			super.FallAndSink(grav, oldfloorz);
		}
	}

	virtual bool PK_IsJumpingAllowed() {
		return !(player.oldbuttons & BT_JUMP) &&      // holding jump doesn't let you keep jumping
		       player.crouchfactor > 0.5 &&           // can't jump while crouching but can when standing up
		       level.IsJumpingAllowed() &&
		       (player.onground || am_coyotetime) &&  // can jump in coyote time
		       player.jumpTics >= 0;
	}

	override void CheckJump()
	{
		let player = self.player;
		if (!(player.cmd.buttons & BT_JUMP)) return;

		if (waterlevel >= 2)
		{
			Vel.Z = 4 * Speed;
		}
		else if (bNoGravity)
		{
			Vel.Z = 3.;
		}
		// [AA] The actual jumping with some changes to the default:
		else if (PK_IsJumpingAllowed())
		{
			if (am_coyotetime)
			{
				vel.z = max(vel.z, 0);
				am_coyotetime = 0;
			}

			double jumpvelz = JumpZ * 35 / TICRATE;
			double jumpfac = 0;

			// [BC] If the player has the high jump power, double his jump velocity.
			// (actually, pick the best factors from all active items.)
			for (let p = Inv; p != null; p = p.Inv)
			{
				let pp = PowerHighJump(p);
				if (pp)
				{
					double f = pp.Strength;
					if (f > jumpfac) jumpfac = f;
				}
			}
			if (jumpfac > 0) jumpvelz *= jumpfac;

			vel.z += jumpvelz;
			bOnMobj = false;
			player.jumpTics = -1;
			if (!(player.cheats & CF_PREDICTING)) 
			{
				A_StartSound("*jump", CHAN_BODY);
				PK_SetJumpLandTimer(9);
			}
		}
	}
}