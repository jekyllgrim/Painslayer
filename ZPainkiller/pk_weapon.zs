/*
	Painkiller weapons
	for ammo and weapon/ammo spawners see pk_ammo.zs
*/

Class PKWeapon : Weapon abstract {
	mixin PK_Math;
	protected int PKWflags;
	FlagDef NOAUTOPRIMARY 		: PKWflags, 0; //NOAUTOFIRE analog for primary attack only
	FlagDef NOAUTOSECONDARY 	: PKWflags, 1; //NOAUTOFIRE analog for secondary attack only
	FlagDef ALWAYSBOB			: PKWflags, 2; //if true, weapon will bob all the time (currently unused)
	FlagDef NOICON				: PKWFlags, 3; //do not spawn Weapon Icon above
	sound emptysound; //clicking sound when trying to fire without ammo
	property emptysound : emptysound;
	protected bool hasDexterity; //player has one of dexterity effects/cards
	protected bool hasWmod; //player has Weapon Modifier powerup/card
	protected vector2 targOfs; //used by DampedRandomOffset
	protected vector2 shiftOfs; //used by DampedRandomOffset
	protected double spitch; //used by DampedRandomOffset
	/* a version of NOAUTOFIRE but for one attack only. It also only prevents firing on
	selection and doesn't affect the refire function. See NOAUTO* flags above. See Chaingun 
	and Boltgun for implementation:
	*/
	protected bool blockFireOnSelect;
	
	//Functionality needed to let the player switch primary/secondary fire buttons:
	protected transient CVar c_switchmodes; //pointer to the related cvar
	protected bool switchmodes; //true if fire modes were switched 
	protected name ammoSwitchCVar; //holds the name of the firemodes cvar for this weapon 
	property ammoSwitchCVar : ammoSwitchCVar; //allows assigning the cvar via defaults
	
	//state pointers:
	protected state s_fire;
	protected state s_hold;
	protected state s_altfire;
	protected state s_althold;
	
	Default {
		+PKWeapon.ALWAYSBOB
		weapon.BobStyle "InverseSmooth";
		weapon.BobRangeX 0.32;
		weapon.BobRangeY 0.17;
		weapon.BobSpeed 1.85;
		weapon.upsound "weapons/select";
		+FLOATBOB;
		+WEAPON.AMMO_OPTIONAL;
		+WEAPON.ALT_AMMO_OPTIONAL;
		FloatBobStrength  0.3;
		inventory.amount 1;
		inventory.maxamount 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!bNOICON) {
			let icon = Spawn("PK_WeaponIcon",pos);
			if (icon)  {
				icon.master = self;
			}
		}
		spitch = frandompick[sfx](-0.1,0.1);
		s_fire = FindState("Fire");
		s_hold = FindState("Hold");
		s_altfire = FindState("AltFire");
		s_althold = FindState("AltHold");
	}
	override void DoEffect() {
		Super.DoEffect();
		if (!owner || !owner.player)
			return;		
		SwitchAmmoTypes();
		let weap = owner.player.readyweapon;
		if (!weap)
			return;
		//if (bALWAYSBOB && weap == self)
			//owner.player.WeaponState |= WF_WEAPONBOBBING;
		hasDexterity = owner.FindInventory("PowerDoubleFiringSpeed",subclass:true);
		hasWmod = owner.FindInventory("PK_WeaponModifier",subclass:true);
	}
	
	action bool CheckInfiniteAmmo() {
		return (sv_infiniteammo || FindInventory("PowerInfiniteAmmo",true) );
	}
	static bool CheckWmod(actor checker) {
		if (!checker || !checker.player || !checker.player.readyweapon)
			return false;
		let weap = PKWeapon(checker.player.readyweapon);
		if (!weap || !weap.hasWmod)
			return false;
		return true;
	}
	//plays a sound and also a WeaponModifier sound if Weaponmodifier is in inventory:
	action void PK_AttackSound(sound snd = "", int channel = CHAN_AUTO, int flags = 0) {
		//play regular attack sound:
		if (snd)
			A_StartSound(snd,channel,flags);
		//play weapon modifier sound only once for automatic weapons (important):
		if (invoker.hasWmod && player && !player.refire) {
			A_StartSound("pickups/wmod/use",CH_WMOD);
		}
	}
	
	//This switches around ammotypes when the player switches primary/secondary attacks:
	virtual void SwitchAmmoTypes() {
		if (!ammoSwitchCVar)
			return;
		if (c_switchmodes == null)
			c_switchmodes = CVAR.GetCVar(ammoSwitchCVar,owner.player);
		//switchmodes = c_switchmodes.GetBool(); return;
		if (!c_switchmodes/* || switchmodes == c_switchmodes.GetBool()*/)
			return;
		if (c_switchmodes.GetBool()) {
			ammotype1 = default.ammotype2;
			ammouse1 = default.ammouse2;
			ammogive1 = default.ammogive2;
			ammotype2 = default.ammotype1;
			ammouse2 = default.ammouse1;
			ammogive2 = default.ammogive1;
		}
		else {
			ammotype1 = default.ammotype1;
			ammouse1 = default.ammouse1;
			ammogive1 = default.ammogive1;
			ammotype2 = default.ammotype2;
			ammouse2 = default.ammouse2;
			ammogive2 = default.ammogive2;
		}
		ammo1 = Ammo(owner.FindInventory (ammotype1));
		ammo2 = Ammo(owner.FindInventory (ammotype2));
		switchmodes = c_switchmodes.GetBool();
	}
	
	//If firemodes are switched, we need to return different states:
	override State GetAtkState (bool hold) {	
		if (switchmodes) {
			return super.GetAltAtkState(hold);
		}
		return super.GetAtkState(hold);
	}	
	override State GetAltAtkState (bool hold)	{
		if (switchmodes) {
			return super.GetAtkState(hold);
		}
		return super.GetAltAtkState(hold);
	}
	
	//This checks if we have enough ammo and incorporates the firemodes switch feature:
	action bool PK_CheckAmmo(bool secondary = false, int amount = -1) {
		if (CheckInfiniteAmmo())
			return true;
		let tAmmo = secondary ? invoker.ammo2 : invoker.ammo1;
		if (invoker.switchmodes) //switch ammo pointers if firemodes are switched 
			tAmmo = secondary ? invoker.ammo1 : invoker.ammo2;
		if (!tAmmo)
			return true; //this weapon doesn't use ammo at all
		//check for default ammouse value if -1, otherwise check for specified:
		if (amount <= -1) {
			amount = secondary ? invoker.ammouse2 : invoker.ammouse1;
			if (invoker.switchmodes)
				amount = secondary ? invoker.ammouse1 : invoker.ammouse2;
		}
		if (tAmmo.amount < amount)
			return false;
		return true;
	}
	
	action void PK_DepleteAmmo(bool secondary = false, int amount = -1) {
		if (CheckInfiniteAmmo())
			return;
		let tAmmo = secondary ? invoker.ammo2 : invoker.ammo1;
		if (invoker.switchmodes)
			tAmmo = secondary ? invoker.ammo1 : invoker.ammo2;
		if (!tAmmo)
			return;
		let tAmmoType = secondary ? invoker.AmmoType2 : invoker.AmmoType1;
		if (invoker.switchmodes)
			tAmmoType = secondary ? invoker.AmmoType1 : invoker.AmmoType2;
		if (!tAmmoType)
			return;
		if (amount <= -1) {
			amount = secondary ? invoker.ammouse2 : invoker.ammouse1;
			if (invoker.switchmodes)
				amount = secondary ? invoker.ammouse1 : invoker.ammouse2;
		}
		TakeInventory(tAmmoType,amount);
	}
	
	
	enum PABCheck {
		PAB_ANY,		//don't check if the button is held down
		PAB_HELD,		//check if the button is held down
		PAB_NOTHELD,	//check if the button is NOT held down
		PAB_HELDONLY	//check ONLY if the button is held down and ignore if it's pressed now
	}
	//A variation on GetPlayerInput that incorporates the switching primary/secondary attack feature:
	action bool PressingAttackButton(bool secondary = false, int holdCheck = PAB_ANY) {
		if (!player)
			return false;
		//get the button:
		int button = secondary ? BT_ALTATTACK : BT_ATTACK;
		//if fire modes are switched, switch buttons around:
		if (invoker.switchmodes)
			button = secondary ? BT_ATTACK : BT_ALTATTACK;
		
		bool pressed = (player.cmd.buttons & button); //check if pressed now 
		bool held = (player.oldbuttons & button); //check if it was held from previous tic
		
		switch (holdCheck) {
		case PAB_HELDONLY:			//true if held and not pressed
			return held;
			break;
		case PAB_NOTHELD:				//true if not held, only pressed
			return !held && pressed;
			break;
		case PAB_HELD:					//true if held and pressed
			return held && pressed;
			break;
		}
		return pressed;				//true if pressed, ignore held check
	}
	
	//A custom version of A_Refire():
	action void PK_ReFire() {
		if (!player)
			return;		
		let psp = Player.FindPsprite(overlayID());
		if (!psp)
			return;
		//just to get rid of invoker:
		let s_fire = invoker.s_fire;
		let s_hold = invoker.s_hold;
		let s_altfire = invoker.s_altfire;
		let s_althold = invoker.s_althold;
		state targetState = null;
		//check if this is being called from Fire or Hold:
		if ((s_fire && InStateSequence(psp.curstate,s_fire)) || (s_hold && InStateSequence(psp.curstate,s_hold))) {
			//console.printf("In Fire/Hold sequence");
			//check if fire button is being held and we have enough primary ammo:
			if (PressingAttackButton() && PK_CheckAmmo()) {
				//console.printf("Pressing Fire button");
				if (s_hold) {
					targetState = s_hold; //point to Hold if it exists
					//console.printf("jumping to Fire state");
				}
				else {
					targetState = s_fire; //otherwise point to Fire
					//console.printf("jumping to Hold state");
				}
			}
		}
		//otherwise check if this is being called from AltFire or AltHold:
		else if ((s_altfire && InStateSequence(psp.curstate,s_altfire)) || (s_althold && InStateSequence(psp.curstate,s_althold))) {
			//console.printf("In AlFire/AlHold sequence");
			//check if altfire button is being held and we have enough secondary ammo:
			if (PressingAttackButton(secondary:true) && PK_CheckAmmo(secondary:true)) {
				//console.printf("Pressing AltFire button");
				if (s_althold) {
					targetState = s_althold; //point to AltHold if it exists
					//console.printf("jumping to AltFire state");
				}
				else {
					targetState = s_altfire; //otherwise point to AltFire
					//console.printf("jumping to AltHold state");
				}
			}
		}
		//Perform jump if the state is not null and set refire:
		if (targetState) {
			player.refire++;
			player.SetPsprite(OverlayID(),targetState);
		}
		//otherwise unset refire, because why wouldn't we just do it here?
		else {
			player.refire = 0;			
		}
		//console.printf("player refire: %d",player.refire);
	}
	
	/*	A version of A_WeaponReady that incporates:
		- the feature to switch primary/secondary firemodes;
		- NOAUTOPRIMARY/NOAUTOSECONDARY flags;
		- playing a dry click sound if the player is pressing an attack
		button but not holding it.
	*/
	action void PK_WeaponReady(int flags = 0) {
		//buncha debug stuff
		if (pk_debugmessages > 3) {
			let psp = player.FindPsprite(OverlayID());
			if (psp) {
				textureID sprt = psp.curstate.GetSpriteTexture(0);
				string call = String.Format("calling PK_WeaponReady on %s%d",TexMan.GetName(sprt),psp.frame);
				string prim = (player.cmd.buttons & BT_ATTACK) ? " pressing Fire," : "";
				string sec = (player.cmd.buttons & BT_ALTATTACK) ? " pressing AltFire," : "";
				string primamt = prim ? String.Format(" has ammo1: %d (need: %d)", invoker.ammo1.amount, invoker.ammouse1) : "";
				string secamt = sec ? String.Format(" has ammo2: %d (need: %d)", invoker.ammo2.amount, invoker.ammouse2) : "";
				string plr = (prim || sec) ? " player" : "";
				console.printf("%s%s%s%s%s%s",call,plr,prim,sec,primamt,secamt);
			}
		}		
		A_RemoveLight('PKWeaponlight');
		
		bool NOAUTOPRIMARY 	= invoker.bNOAUTOPRIMARY;
		bool NOAUTOSECONDARY 	= invoker.bNOAUTOSECONDARY;
		bool firePressed 		= PressingAttackButton(secondary:false); 
		bool fireHeld 			= PressingAttackButton(secondary:false,	holdCheck:PAB_HELD);	
		bool altfirePressed 	= PressingAttackButton(secondary:true);
		bool altfireHeld 		= PressingAttackButton(secondary:true,	holdCheck:PAB_HELD);
		
		//console.printf("%s: should block fire %d | fire held %d || should block alt fire %d | alt fire held %d",invoker.GetClassName(),NOAUTOPRIMARY,fireHeld,NOAUTOSECONDARY,altFireHeld);
		
		if (NOAUTOPRIMARY && !fireHeld) {
			invoker.blockFireOnSelect = false;
		}
		else if (NOAUTOSECONDARY && !altFireHeld) {
			invoker.blockFireOnSelect = false;
		}
		
		if (!PK_CheckAmmo() || invoker.blockFireOnSelect) {
			A_ClearRefire();
			if (firePressed && !fireHeld)
				A_StartSound(invoker.emptysound);
			flags |= WRF_NOPRIMARY;
		}
		if (!PK_CheckAmmo(secondary:true) || invoker.blockFireOnSelect) {
			A_ClearRefire();
			if (altFirePressed && !AltFireHeld)
				A_StartSound(invoker.emptysound);
			flags |= WRF_NOSECONDARY;
		}
		
		/*	Finally I need to invert WRF_NOPRIMARY/WRF_NOSECONDARY flags if firemodes are switched.
			This has to be done here, so that it covers both the flags that were set in the
			cheks above, AND the flags that were set in the function call itself, since those
			also need to be inverted.
		*/
		if (invoker.switchmodes) {
			bool invertprimary;
			bool invertsecondary;
			if (flags & WRF_NOPRIMARY) {
				flags &= ~WRF_NOPRIMARY;
				invertprimary = true;
			}
			if (flags & WRF_NOSECONDARY) {
				flags &= ~WRF_NOSECONDARY;
				invertsecondary = true;
			}
			if (invertprimary) {
				flags |= WRF_NOSECONDARY;				
			}
			if (invertsecondary) {
				flags |= WRF_NOPRIMARY;				
			}
		}
		
		A_WeaponReady(flags);
	}
	
	/*
		A version of A_OverlayRotate that allows additive rotation
		without intepolation. Necessary because interpolation breaks 
		when combined with animation. 
		See stakegun primary fire for an example of use.
	*/
	action void PK_WeaponRotate(double degrees = 0, int flags = 0) {
		let psp = player.FindPsprite(OverlayID());
		if (!psp)
			return;
		double targetAngle = degrees;
		if (flags & WOF_ADD)
			targetAngle += psp.rotation;
		A_OverlayRotate(OverlayID(), targetAngle);
	}
	
	// Same but for scale:	
	action void PK_WeaponScale(double wx = 1, double wy = 1, int flags = 0) {
		let psp = player.FindPsprite(OverlayID());
		if (!psp)
			return;
		vector2 targetScale = (wx,wy);
		if (flags & WOF_ADD)
			targetScale += psp.scale;
		A_OverlayScale(OverlayID(), targetScale.x, targetScale.y);
	}
	
	//a wrapper function that fires tracers with A_FireProjectile so that they don't break on portals and such:
	action void PK_FireBullets(double spread_horz = 0, double spread_vert = 0, int numbullets = 1, int damage = 1, sound snd = "", Class<Actor> pufftype = "PK_BulletPuff", double spawnheight = 0, double spawnofs = 0) {
		if (numbullets == 0) numbullets = 1;
		let weapon = player.ReadyWeapon;
		//deplete the appropriate ammo
		if (!weapon || !weapon.DepleteAmmo(weapon.bAltFire, true))
			return;
		//play only if non-null
		if (snd)
			A_StartSound(snd,CHAN_WEAPON);
		//emulate perfect accuracy on first bullet: it'll happen if there's only 1 bullet, player isn't in refire (holding attack button), and numbullets is positive
		bool held = (numbullets != 1 || player.refire);
		//make sure numbullets is positive, now that the check is finished
		numbullets = abs(numbullets);
		//fire bullets with explicit angle and simply pass the offsets to the projectiles instead of using AimBulletMissile at puffs (because puffs don't always spawn!)
		for (int i = 0; i < numbullets; i++) {			
			double hspread = held ? frandom(-spread_horz,spread_horz) : 0;
			double vspread = held ? frandom(-spread_vert,spread_vert) : 0;	
			A_FireProjectile("PK_BulletTracer",hspread,useammo:false,spawnofs_xy:spawnofs,spawnheight:spawnheight,pitch:vspread);
			A_FireBullets (hspread, vspread, -1, damage, pufftype,flags:FBF_NORANDOMPUFFZ|FBF_EXPLICITANGLE|FBF_NORANDOM);
		}
	}
	
	/*	If a gravity-affected projectile is fired via the regular A_FireProjectile directly upwards,
		it won't actually fly upwards, it'll get a curve out of nowhere.
		This function sets the pitch correctly to circumvent that.
	*/
	action actor PK_FireArchingProjectile(class<Actor> missiletype, double angle = 0, bool useammo = true, double spawnofs_xy = 0, double spawnheight = 0, int flags = 0, double pitch = 0) {
		if (!self || !self.player) 
			return null;
		double pitchOfs = pitch;
		if (pitch != 0 && self.pitch < 0)
			pitchOfs = invoker.LinearMap(self.pitch, 0, -90, pitchOfs, 0);
		return A_FireProjectile(missiletype, angle, useammo, spawnofs_xy, spawnheight, flags, pitchOfs);
	}
	
	/*	This function staggers an overlay offset change over a few tics, so that
		I can randomize layer offsets but make it smoother than if it were called
		every tic. Used by Electro and Flamethrower.
	*/
	action void DampedRandomOffset(double rangeX, double rangeY, double rate = 1) {
		let psp = Player.FindPSprite(PSP_WEAPON);			
		if (!psp)
			return;
		if (abs(psp.x) >= abs(invoker.targOfs.x) || abs(psp.y) >= abs(invoker.targOfs.y)) {
			invoker.targOfs = (frandom[sfx](0,rangeX),frandom[sfx](0,rangeY)+32);
			vector2 shift = (rangeX * rate, rangeY * rate);
			shift = (shift.x == 0 ? 1 : shift.x, shift.y == 0 ? 1 : shift.y);
			invoker.shiftOfs = ((invoker.targOfs.x - psp.x) / shift.x, (invoker.targOfs.y - psp.y) / shift.y);
		}
		A_WeaponOffset(invoker.shiftOfs.x, invoker.shiftOfs.y, WOF_ADD);
	}
	
	States {
	//can't define a weapon class without Ready/Fire/Deselect/Select
	Ready:
		TNT1 A 1;
		loop;
	Fire:
		TNT1 A 1;
		loop;
	Deselect:
		TNT1 A 0 {
			A_StopSound(CH_LOOP);
			A_RemoveLight('PKWeaponlight');
			invoker.blockFireOnSelect = false;
		}
		//instant weapon switch:
		TNT1 A 0 A_Lower();
		wait;
	Select:
		TNT1 A 0 {
			if (pk_debugmessages >= 2) {
				string str1 = player.cmd.buttons & BT_ATTACK ? "is pressing Fire" : "is NOT pressing Fire";
				string str2 = player.cmd.buttons & BT_ALTATTACK ? "is pressing AltFire" : "is NOT pressing AltFire";
				string str3 = invoker.bNOAUTOPRIMARY ? "gun has +NOAUTOPRIMARY" : "gun has -NOAUTOPRIMARY";
				string str4 = invoker.bNOAUTOSECONDARY ? "gun has +NOAUTOSECONDARY" : "gun has -NOAUTOSECONDARY";	
				console.printf("player %s, %s, %s, %s", str1, str2, str3, str4);
			}
			bool blockFire = invoker.bNOAUTOPRIMARY;
			bool blockAltFire = invoker.bNOAUTOSECONDARY;
			bool fireHeld = PressingAttackButton();
			bool altFireHeld = PressingAttackButton(secondary:true);
			//console.printf("block fire %d | fire held %d | block alt fire %d | alt fire held %d",blockFire,fireHeld,blockAltFire,altFireHeld);
			if 	((blockfire && fireHeld) || (blockAltFire && altFireHeld)) {
				invoker.blockFireOnSelect = true;
				console.printf("blocking fire on selection");
			}
		}
		//instant weapon switch:
		TNT1 A 0 {
			let psp = player.FindPsprite(PSP_WEAPON);
			if (psp)
				psp.y = WEAPONTOP;
			return ResolveState("Ready");
		}
		wait;
	LoadSprites:
		PSGT AHIJK 0;
		stop;
	}
}

Class PKPuff : PK_BaseActor abstract {
	mixin PK_Math;
	Default {
		+NOBLOCKMAP
		+NOGRAVITY
		+FORCEXYBILLBOARD
		+PUFFGETSOWNER
		-ALLOWPARTICLES
		+DONTSPLASH
		-FLOORCLIP
	}
}

Class PK_NullPuff : Actor {
	Default {
		decal "none";
		+NODECAL
		+NOINTERACTION
		+BLOODLESSIMPACT
		+PAINLESS
		+PUFFONACTORS
		+NODAMAGETHRUST
	}
	states {
		Spawn:
			TNT1 A 1;
			stop;
	}
}

Class PK_BulletPuff : PKPuff {
	protected Vector3 hitnormal;			//vector normal of the hit 
	protected FLineTraceData puffdata;
	double debrisOfz;
	Default {
		decal "BulletChip";
		scale 0.032;
		renderstyle 'add';
		alpha 0.6;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
	}
	void FindLineNormal() {
		LineTrace(angle,128,pitch,TRF_THRUACTORS|TRF_NOSKY,data:puffdata);
		hitnormal = -puffdata.HitDir;
		if (puffdata.HitType == TRACE_HitFloor) {
			debrisOfz = 1;
			if (puffdata.Hit3DFloor) 
				hitnormal = -puffdata.Hit3DFloor.top.Normal;
			else 
				hitnormal = puffdata.HitSector.floorplane.Normal;
		}
		else if (puffdata.HitType == TRACE_HitCeiling)	{
			debrisOfz = -1;
			if (puffdata.Hit3DFloor) 
				hitnormal = -puffdata.Hit3DFloor.bottom.Normal;
			else 
				hitnormal = puffdata.HitSector.ceilingplane.Normal;
		}
		else if (puffdata.HitType == TRACE_HitWall) {
			hitnormal = (-puffdata.HitLine.delta.y,puffdata.HitLine.delta.x,0).unit();
			if (!puffdata.LineSide) 
				hitnormal *= -1;
		}
	}
	states {
	Crash:
		TNT1 A 0 {
			if (!s_particles)
				s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
			if (s_particles.GetInt() < 1)
				return resolveState(null);
			if (target) {
				angle = target.angle;
				pitch = target.pitch;
			}
			FindLineNormal();
			let smok = PK_WhiteSmoke(Spawn("PK_WhiteSmoke",puffdata.Hitlocation + (0,0,debrisOfz)));
			if (smok) {
				smok.vel = (hitnormal + (frandom[sfx](-0.05,0.05),frandom[sfx](-0.05,0.05),frandom[sfx](-0.05,0.05))) * frandom[sfx](0.8,1.3);
				smok.A_SetScale(0.085);
				smok.alpha = 0.85;
				smok.fade = 0.025;
			}
			if (s_particles.GetInt() < 2)
				return resolveState(null);
			let deb = Spawn("PK_RandomDebris",puffdata.Hitlocation + (0,0,debrisOfz));
			if (deb)
				deb.vel = (hitnormal + (frandom[sfx](-4,4),frandom[sfx](-4,4),frandom[sfx](3,5)));
			bool mod = target && PKWeapon.CheckWmod(target);
			name lit = mod ? 'PK_BulletPuffMod' : 'PK_BulletPuff';
			A_AttachLightDef('puf',lit);
			if (mod || (random[sfx](0,10) > 7)) {
				let bull = PK_RicochetBullet(Spawn("PK_RicochetBullet",pos));
				if (bull) {
					bull.vel = (hitnormal + (frandom[sfx](-3,3),frandom[sfx](-3,3),frandom[sfx](-3,3)) * frandom[sfx](2,6));
					bull.A_FaceMovementDirection();
					if (mod) {
						bull.A_SetRenderstyle(bull.alpha,Style_AddShaded);
						bull.SetShade("FF2000");
						//bull.scale *= 2;
					}
				}
			}
			return resolveState(null);
		}
		FLAR B 1 bright A_FadeOut(0.1);
		wait;
	}
}

//unused
class PK_BulletPuffSmoke : PK_BlackSmoke {
	Default {
		alpha 0.3;
		scale 0.12;
	}
	states	{
	Spawn:
		SMOK ABCDEFGHIJKLMNOPQR 1 NoDelay {
			A_FadeOut(0.02);
			scale *= 0.9;
		}
		wait;
	}
}
	
//A weapon icon that  floats above weapon pickups:
Class PK_WeaponIcon : Actor {
	//state mspawn;
	PKWeapon weap;
	Default {
		+BRIGHT
		xscale 0.14;
		yscale 0.1162;
		+NOINTERACTION
		+FLOATBOB
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (master)
			weap = PKWeapon(master);
		if (!weap) {
			Destroy();
			return;
		}
		FloatBobStrength = weap.FloatBobStrength;
		FloatBobPhase = weap.FloatBobPhase;
		name weapcls = weap.GetClassName();
		switch (weapcls) {
		case 'PK_Shotgun':
			frame = 0;
			break;
		case 'PK_Stakegun':
			frame = 1;
			break;
		case 'PK_Chaingun':
			frame = 2;
			break;
		case 'PK_ElectroDriver':
			frame = 3;
			break;
		case 'PK_Rifle':
			frame = 4;
			break;
		case 'PK_Boltgun':
			frame = 5;
			break;
		}
	}
	override void Tick () {
		if (!weap || weap.owner) {
			Destroy();
			return;
		}
		SetOrigin(weap.pos + (0,0,30),true);
	}
	states {
		Spawn:
			PWIC # -1;
			stop;
	}
}

//Base projectile class that can produce relatively solid trails:
Class PK_Projectile : PK_BaseActor abstract {
	protected bool mod; //affteced by Weapon Modifier
	mixin PK_Math;
	protected vector3 spawnpos;
	protected bool farenough;	
	color flarecolor;
	double flarescale;
	double flarealpha;
	color trailcolor;
	double trailscale;
	double trailalpha;
	double trailfade;
	double trailvel;
	double trailz;
	double trailshrink;
	
	class<Actor> trailactor;
	property trailactor : trailactor;
	class<PK_ProjFlare> flareactor;	
	property flareactor : flareactor;
	property flarecolor : flarecolor;
	property flarescale : flarescale;
	property flarealpha : flarealpha;
	property trailcolor : trailcolor;
	property trailalpha : trailalpha;
	property trailscale : trailscale;
	property trailfade : trailfade;
	property trailshrink : trailshrink;
	property trailvel : trailvel;
	property trailz : trailz;
	Default {
		projectile;
		height 6;
		radius 6;
		PK_Projectile.flarescale 0.065;
		PK_Projectile.flarealpha 0.7;
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailalpha 0.4;
		PK_Projectile.trailfade 0.1;
		PK_Projectile.flareactor "PK_ProjFlare";
		PK_Projectile.trailactor "PK_BaseFlare";
	}
	/*
		For whatever reason the fancy pitch offset calculation used in arching projectiles 
		like grenades (see PK_FireArchingProjectile) screws up the projectiles' collision, 
		so that it'll collide with the player if it fell down on them after being fired 
		directly upwards.
		I had to add this override to circumvent that.
	*/
	override bool CanCollideWith(Actor other, bool passive) {
		if (!other)
			return false;
		if (!passive && target && other == target)
			return false;
		return super.CanCollideWith(other, passive);
	}
	//This is just to make sure the projectile doesn't collide with certain
	//non-collidable actors. Used by stuff like stakes.
	static bool CheckVulnerable(actor victim, actor missile = null) {
		if (!victim)
			return false;
		/*if (missile) {
			if (missile.bMTHRUSPECIES && missile.target && missile.target.species == victim.species)
				return true;
			if (victim.bSPECTRAL && !missile.bSPECTRAL)
				return true;
		}*/
		return (victim.bSHOOTABLE && !victim.bNONSHOOTABLE && !victim.bNOCLIP && !victim.bNOINTERACTION && !victim.bINVULNERABLE && !victim.bDORMANT && !victim.bNODAMAGE  && !victim.bSPECTRAL);
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();		
		mod = target && PKWeapon.CheckWmod(target);
		if (trailcolor)
			spawnpos = pos;
		if (!flarecolor || !flareactor)
			return;
		let fl = PK_ProjFlare( Spawn(flareactor,pos) );
		if (fl) {
			fl.master = self;
			fl.fcolor = flarecolor;
			fl.fscale = flarescale;
			fl.falpha = flarealpha;
		}
	}
	//An override initially by Arctangent that spawns trails like FastProjectile does it:
	override void Tick () {
		Vector3 oldPos = self.pos;		
		Super.Tick();
		if (!trailcolor || !trailactor)
			return;		
		if (!s_particles)
			s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
		if (s_particles.GetInt() < 1)
			return;	
		if (!farenough) {
			if (level.Vec3Diff(pos,spawnpos).length() < 80)
				return;
			farenough = true;
		}
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / clamp(int(trailscale * 50),1,8); //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );
		
		for( int i = 0; i < steps; i++ )  {
		
			let trl = Spawn(trailactor,oldPos+(0,0,trailz));
			if (trl) {
				trl.master = self;
				let trlflr = PK_BaseFlare(trl);
				if (trlflr) {
					trlflr.fcolor = trailcolor;
					trlflr.fscale = trailscale;
					trlflr.falpha = trailalpha;
					if (trailactor.GetClassName() == "PK_BaseFlare")
						trlflr.A_SetRenderstyle(alpha,Style_Shaded);
					if (trailfade != 0)
						trlflr.fade = trailfade;
					if (trailshrink != 0)
						trlflr.shrink = trailshrink;
				}
				if (trailvel != 0)
					trl.vel = (frandom(-trailvel,trailvel),frandom(-trailvel,trailvel),frandom(-trailvel,trailvel));
			}
			oldPos = level.vec3Offset( oldPos, direction );
		}
	}
}

/*	A base projectile class that can stick into walls and planes.
	It'll move with the sector if it hit a moving one (e.g. door/platform).
	Base for stakes, bolts and shurikens.
*/
Class PK_StakeProjectile : PK_Projectile {
	protected int hitplane; //0: none, 1: floor, 2: ceiling
	protected actor stickobject; //a non-monster object that was hit
	protected transient SecPlane stickplane; //a plane to stick to (has to be transient, can't be recorded into savegames)
	protected vector2 sticklocation; //the point at the line the stake collided with
	protected double stickoffset; //how far the stake is from the nearest ceiling or floor (depending on whether it hit top or bottom part of the line)
	protected double topz; //ZAtPoint below stake
	protected double botz; //ZAtPoint above stake
	actor pinvictim; //The fake corpse that will be pinned to a wall
	protected double victimofz; //the offset from the center of the stake to the victim's corpse center
	protected state sspawn; //pointer to Spawn label
	bool stuckToSecPlane; //a non-transient way to record whether it stuck to a wall. Used by PK_StakeStickHandler
	Default {
		+MOVEWITHSECTOR
		+NOEXTREMEDEATH
	}
	
	//this function is called when the projectile dies and checks if it hit something
	virtual void StickToWall() {
		string myclass = GetClassName();
		bTHRUACTORS = true;
		bNOGRAVITY = true;
		A_Stop();
		
		if (stickobject) {
			stickoffset = pos.z - stickobject.pos.z;
			if (pk_debugmessages > 2)
				console.printf("%s hit %s at at %d,%d,%d",myclass,stickobject.GetClassName(),pos.x,pos.y,pos.z);
			return;
		}
		
		//use linetrace to get information about what we hit
		FLineTraceData trac;
		LineTrace(angle,radius+64,pitch,TRF_NOSKY|TRF_THRUACTORS|TRF_BLOCKSELF,data:trac);
		sticklocation = trac.HitLocation.xy;
		topz = CurSector.ceilingplane.ZatPoint(sticklocation);
		botz = CurSector.floorplane.ZatPoint(sticklocation);
		
		//if hit floor/ceiling, we'll attach to them:
		if (trac.HitLocation.z >= topz) {
			hitplane = 2;
			if (pk_debugmessages > 2)
				console.printf("%s hit ceiling at at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
		}
		else if (trac.HitLocation.z <= botz) {
			hitplane = 1;
			if (pk_debugmessages > 2)
				console.printf("%s hit floor at at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
		}
		if (hitplane > 0)
			return;
			
		//3D floor is easiest, so we start with it:
		if (trac.Hit3DFloor) {
			stuckToSecPlane = true;
			//we simply attach the stake to the 3D floor's top plane, nothing else
			F3DFloor flr = trac.Hit3DFloor;
			stickplane = flr.top;
			stickoffset = stickplane.ZAtPoint(sticklocation) - pos.z;
			if (pk_debugmessages > 2)
				console.printf("%s hit a 3D floor at %d,%d,%d",myclass,pos.x,pos.y,pos.z);
			return;
		}
		//otherwise see if we hit a line:
		if (trac.HitLine) {
			//check if the line is two-sided first:
			let tline = trac.HitLine;
			//if it's one-sided, it can't be a door/lift, so don't do anything else:
			if (!tline.backsector) {
				if (pk_debugmessages > 2)
					console.printf("%s hit one-sided line, not doing anything else",myclass);
				return;
			}
			stuckToSecPlane = true;
			//if it's two-sided:
			//check which side we're on:
			int lside = PointOnLineSide(pos.xy,tline);
			string sside = (lside == 0) ? "front" : "back";
			//we'll attach the stake to the sector on the other side:
			let targetsector = (lside == 0 && tline.backsector) ? tline.backsector : tline.frontsector;
			let floorHitZ = targetsector.floorplane.ZatPoint (sticklocation);
			let ceilHitZ = targetsector.ceilingplane.ZatPoint (sticklocation);
			string secpart = "middle";
			//check if we hit top or bottom floor (i.e. door or lift):
			if (pos.z <= floorHitZ) {
				secpart = "lower";
				stickplane = targetsector.floorplane;
				stickoffset = floorHitZ - pos.z;
			}
			else if (pos.z >= ceilHitZ) {
				secpart = "top";
				stickplane = targetsector.ceilingplane;
				stickoffset = ceilHitZ - pos.z;
			}
			if (pk_debugmessages > 2)
				console.printf("%s hit the %s %s part of the line at %d,%d,%d",myclass,secpart,sside,pos.x,pos.y,pos.z);
		}
	}
	//record a non-monster solid object the stake runs into if there is one:
	override int SpecialMissileHit (Actor victim) {
		if (!victim.bISMONSTER && victim.bSOLID) {
			stickobject = victim;
		}
		return -1;
	}
	//virtual for breaking apart; child actors override it to add debris spawning and such:
	virtual void StakeBreak() {
		if (pk_debugmessages > 2)
			console.printf("%s Destroyed",GetClassName());
		if (self)
			Destroy();
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		sspawn = FindState("Spawn");
	}
	override void Tick () {
		super.Tick();
		//all stake-like projectiles need to face their movement direction while in Spawn sequence:
		if (!isFrozen() && sspawn && InStateSequence(curstate,sspawn))
			A_FaceMovementDirection(flags:FMDF_INTERPOLATE );
		//otherwise stake is dead, so we'll move it alongside the object/plane it's supposed to be attached to:
		if (bTHRUACTORS) {
			topz = CurSector.ceilingplane.ZAtPoint(pos.xy);
			botz = CurSector.floorplane.ZAtPoint(pos.xy);
			/*	Destroy the stake if it's run into ceiling/floor by a moving sector 
				(e.g. a door opened, pulled the stake up and pushed it into the ceiling). 
				Only do this if the stake didn't actually hit a plane before that:
			*/
			if (!hitplane && (pos.z >= topz-height || pos.z <= botz)) {
				StakeBreak();
				return;
			}
			//attached to floor/ceiling:
			if (hitplane > 0) {
				if (hitplane > 1)
					SetZ(ceilingz);
				else
					SetZ(floorz);
			}
			//attached to a plane (hit a door/lift earlier)
			else if (stickplane) {
				SetZ(stickplane.ZAtPoint(sticklocation) - stickoffset);
			}
			//otherwise attach it to the solid object it hit earlier:
			else if (stickobject)
				SetZ(stickobject.pos.z + stickoffset);
			//and if there's a decorative corpse on the stake, move it as well:
			if (pinvictim)
				pinvictim.SetZ(pos.z + victimofz);
		}
	}
}

Class PK_BulletTracer : FastProjectile {
	Default {
		-ACTIVATEIMPACT;
		-ACTIVATEPCROSS;
		+BLOODLESSIMPACT;
		+BRIGHT
		damage 0;
		radius 4;
		height 4;
		speed 180;
		renderstyle 'add';
		alpha 2;
		scale 0.3;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();		
		if (target && PKWeapon.CheckWmod(target)) {
			A_SetRenderstyle(5,Style_AddShaded);
			SetShade("FF2000");
			scale *= 2;
		}
	}
	states {
	Spawn:
		MODL A -1;
		stop;
	Death:
		TNT1 A 1;
		stop;
	}
}

//a ricochetting bullet, looks similar to a tracer:
Class PK_RicochetBullet : PK_SmallDebris {
	Default {
		renderstyle 'Add';
		alpha 0.8;
		scale 0.4;
		+BRIGHT
		+BOUNCEONWALLS
		+BOUNCEONFLOORS
		gravity 0.7;
		bouncefactor 0.55;
		bouncecount 1;
	}
	override void Tick() {
		super.Tick();
		if (!isFrozen())
			scale.x = default.scale.x * 0.1 * vel.length(); //faster trails will be longer!
	}
	states {
	Spawn:
		MODL A 1 A_FadeOut(0.035);
		loop;
	}
}

//Decorative explosion actor that spawns debris and stuff:
Class PK_GenericExplosion : PK_SmallDebris {
	int randomdebris;
	int explosivedebris;
	int smokingdebris;
	int quakeintensity;
	int quakeduration;
	int quakeradius;
	property randomdebris : randomdebris;
	property explosivedebris : explosivedebris;
	property smokingdebris : smokingdebris;
	property quakeintensity : quakeintensity;
	property quakeduration : quakeduration;
	property quakeradius : quakeradius;
	Default {
		PK_GenericExplosion.randomdebris 16;
		PK_GenericExplosion.smokingdebris 12;
		PK_GenericExplosion.explosivedebris 0;
		PK_GenericExplosion.quakeintensity 3;
		PK_GenericExplosion.quakeduration 12;
		PK_GenericExplosion.quakeradius 220;
		+NOINTERACTION;
		renderstyle 'add';
		+BRIGHT;
		alpha 1;
		scale 0.52;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		double rs = scale.x * frandom[sfx](0.8,1.1)*randompick[sfx](-1,1);
		A_SetScale(rs);
		roll = random[sfx](0,359);
		A_Quake(quakeintensity,quakeduration,0,quakeradius,"");
		if (!CheckPlayerSights())
			return;
		CVar s_particles = CVar.GetCVar('pk_particles', players[consoleplayer]);
		if (s_particles.GetInt() < 1)
			return;
		if (randomdebris > 0) {
			for (int i = randomdebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_RandomDebris",pos + (frandom[sfx](-8,8),frandom[sfx](-8,8),frandom[sfx](-8,8)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,5) : frandom[sfx](4,12);
					debris.vel = (frandom[sfx](-7,7),frandom[sfx](-7,7),zvel);
					debris.A_SetScale(0.5);
				}
			}
		}
		if (s_particles.GetInt() < 2)
			return;
		if (smokingdebris > 0) {
			for (int i = smokingdebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_SmokingDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,10) : frandom[sfx](5,15);
					debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10),zvel);
				}
			}
		}
		if (explosivedebris > 0) {
			for (int i = explosivedebris*frandom[sfx](0.7,1.3); i > 0; i--) {
				let debris = Spawn("PK_ExplosiveDebris",pos + (frandom[sfx](-12,12),frandom[sfx](-12,12),frandom[sfx](-12,12)));
				if (debris) {
					double zvel = (pos.z > floorz) ? frandom[sfx](-5,10) : frandom[sfx](5,15);
					debris.vel = (frandom[sfx](-10,10),frandom[sfx](-10,10),zvel);
				}
			}
		}
	}
	states {
	Spawn:
		BOM6 ABCDEFGHIJKLMNOPQRST 1;
		stop;
	}
}
		
//Explosion debris that spawn black smoke and flame:
Class PK_ExplosiveDebris : PK_RandomDebris {	
	Default {
		scale 0.5;
		gravity 0.3;
	}
	override void Tick () {
		Vector3 oldPos = self.pos;		
		Super.Tick();	
		if (isFrozen())
			return;
		let smk = Spawn("PK_BlackSmoke",pos+(frandom[smk](-9,9),frandom[smk](-9,9),frandom[smk](-9,9)));
		if (smk) {
			smk.A_SetScale(0.25);
			smk.alpha = alpha*0.3;
			smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
		}
		Vector3 path = level.vec3Diff( self.pos, oldPos );
		double distance = path.length() / 4; //this determines how far apart the particles are
		Vector3 direction = path / distance;
		int steps = int( distance );		
		for( int i = 0; i < steps; i++ )  {
			let trl = Spawn("PK_DebrisFlame",oldPos);
			if (trl)
				trl.alpha = alpha*0.75;
			oldPos = level.vec3Offset( oldPos, direction );
		}
		A_FadeOut(0.022);
	}
}

//Debris that spawn white smoke:
Class PK_SmokingDebris : PK_RandomDebris {	
	Default {
		scale 0.5;
		gravity 0.25;
	}
	override void Tick () {
		super.Tick();	
		if (isFrozen())
			return;
		let smk = Spawn("PK_WhiteSmoke",pos+(frandom[smk](-4,4),frandom[smk](-4,4),frandom[smk](-4,4)));
		if (smk) {
			smk.alpha = alpha*0.4;
			smk.vel = (frandom[smk](-1,1),frandom[smk](-1,1),frandom[smk](-1,1));
		}
		A_FadeOut(0.03);
	}
}

//Flame spawned by burning debris:
Class PK_DebrisFlame : PK_BaseFlare {
	Default {
		scale 0.05;
		renderstyle 'translucent';
		alpha 1;
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = random[sfx](0,359);
		wrot = frandom[sfx](5,10)+randompick[sfx](-1,1);
	}
	states {
	Spawn:
		TNT1 A 0 NoDelay A_Jump(256,1,3); //randomize appearance a bit:
		BOM4 IJKLMNOPQ 1 {
			A_FadeOut(0.05);
			roll += wrot;
			scale *= 1.1;
		}
		wait;
	}
}