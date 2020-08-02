Class PK_Stakegun : PKWeapon {
	Array <Actor> grenades;
	Default {
		PKWeapon.emptysound "weapons/empty/rifle";
		weapon.slotnumber 3;
		weapon.ammotype1	"PK_Stakes";
		weapon.ammouse1		1;
		weapon.ammogive1	10;
		weapon.ammotype2	"PK_Bombs";
		weapon.ammogive2	0;
		weapon.ammouse2		1;
		scale 0.23;
		inventory.pickupmessage "Picked up Stakegun";
		inventory.pickupsound "pickups/weapons/stakegun";
		Tag "Stakegun/Grenade Launcher";
	}
	/*override void DoEffect () {
		super.DoEffect();
		Console.Printf("greandes: %d",grenades.size());
	}*/
	states {
		Cache:
			PSGT AHIJKLMN 0;
		Spawn:
			PSGZ ABCDEFGHIJKLMNOP 3;
			loop;
		Ready:
			PSGN A 1 {
				PK_WeaponReady();
				if (CountInv("PK_Stakes") < 1) {
					let psp = player.FindPSprite(PSP_Weapon);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
			}
			loop;
		Fire:
			TNT1 A 0 {
				A_StartSound("weapons/stakegun/fire");
				A_WeaponOffset(7,5,WOF_ADD);
				A_FireProjectile("PK_Stake",spawnofs_xy:2,spawnheight:5,flags:FPF_NOAUTOAIM,pitch:-2.5);
				A_WeaponOffset(4,4,WOF_ADD);
			}
			PSGN BBBBB 2 A_WeaponOffset(1.44,1.2,WOF_ADD);
			PSGN CDEF 3 A_WeaponOffset(-0.8,-0.5,WOF_ADD);
			PSGN GGGGGGG 2 A_WeaponOffset(-0.12,-0.1,WOF_ADD);
			PSGN A 0 {
				if (CountInv("PK_Stakes") < 1) {
					let psp = player.FindPSprite(PSP_Weapon);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
			}
			#### HIJKAA 3 A_WeaponOffset(-2.35,-2.04,WOF_ADD);
			TNT1 A 0 A_WeaponOffset(0,32,WOF_INTERPOLATE);
			goto ready;
		AltFire:
			PSGN A 0 {
				A_StartSound("weapons/stakegun/grenade");
				A_WeaponOffset(6,2,WOF_ADD);
				let a = A_FireProjectile("PK_Grenade",spawnofs_xy:1,spawnheight:-4,flags:FPF_NOAUTOAIM,pitch:-25);
				if (a) 
					invoker.grenades.push(a);
				if (CountInv("PK_Stakes") < 1) {
					let psp = Player.FindPSprite(PSP_WEAPON);
					if (psp)
						psp.sprite = GetSpriteIndex("PSGT");
				}
			}
			#### AL 1 A_WeaponOffset(5,3,WOF_ADD);
			#### A 0 {
				if (CountInv("PK_Bombs") > 0)
					A_StartSound("weapons/grenade/load",CHAN_7);
			}
			#### MNN 1 A_WeaponOffset(3.5,2.5,WOF_ADD);
			#### NNNNMMMMLLLL 1 A_WeaponOffset(-1.6,-1,WOF_ADD);
			#### AAAA 1 {
				A_WeaponOffset(-0.32,-0.35,WOF_ADD);
				PK_WeaponReady(WRF_NOSECONDARY|WRF_NOSWITCH);
			}
			#### A 5 {
				A_WeaponOffset(0,32,WOF_INTERPOLATE);
				PK_WeaponReady();
			}
			goto ready;
	}
}
		


/* The stake can pierce a monster and pin them to a wall (or a solid actor)
but at the same time it's NOT a piercing projectile, i.e. it should only damage
only one victim and fly through others if they exist. For that we employ a few tricks.
*/
Class PK_Stake : PK_Projectile {
	protected int basedmg;
	actor hitvictim; //Stores the first monster hit. Allows us to deal damage only once and to only one victim
	actor pinvictim; //The fake corpse that will be pinned to a wall
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.012;
		PK_Projectile.trailfade 0.02;
		PK_Projectile.trailalpha 0.2;
		-NOGRAVITY
		+NOEXTREMEDEATH
		speed 60;
		gravity 0.45;
		radius 2;
		height 2;
		damage 0;
		decal "";
		obituary "%k pinned %o to the wall";
	}
	override void Tick () {
		super.Tick();
		if (age >= 12) {
			trailactor = "PK_StakeFlame";
			trailscale = 0.08;
		}
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		basedmg = 120;
		if (target)
			pitch = target.pitch; //In case it's fired at a floor or ceiling at point-blank range, the Spawn state won't be used and the stake won't receive proper pitch. So, we do this.
	}
	override int SpecialMissileHit (Actor victim) {
		if (victim && (victim.bisMonster || victim.player) && victim != target && !hitvictim) { //We only do the following block if the actor hit by the stake exists, isn't the shooter, and the stake has never hit anyone yet
			if (age >= 12)
				basedmg *= 1.5;
			victim.DamageMobj (self, target, basedmg, 'normal');
			A_StartSound("weapons/stakegun/hit",volume:0.7,attenuation:3);
			hitvictim = victim; //store the victim hit; when this is non-null, stake won't deal damage to anyone else
			if (!victim.bBOSS && victim.health <= 0 && victim.mass <= 400) { //we do the "pin to the wall" effect only if the victim is dead, not a boss and not huge (mass <= 400)
				pinvictim = PK_PinVictim(Spawn("PK_PinVictim",victim.pos)); //spawn fake corpse and give it appearance identical to the monster
				if (pinvictim) {											
					pinvictim.target = victim;
					pinvictim.master = self;
					pinvictim.angle = victim.angle;
					pinvictim.height = victim.default.height*0.5;
					pinvictim.sprite = victim.sprite;
					pinvictim.frame = victim.frame;
					pinvictim.translation = victim.translation;
					pinvictim.scale = victim.scale;
					pinvictim.A_SetRenderstyle(victim.alpha,victim.GetRenderstyle());
				}
				victim.GiveInventory("PK_PinToWall",1);	//the dummy item that makes the ACTUAL killed monster follow the stake (so that the fake and real corpse are synced in position — this is important for item drops, Arch-Vile ressurrect and anything else that may interact with the monster's corpse)
				let pinned = victim.FindInventory("PK_PinToWall");
				if (pinned)
					pinned.master = self;
				let ct = PK_StakeStuckCounter(victim.FindInventory("PK_StakeStuckCounter"));	// This item contains an array of all visual stakes stuck in the victim;
				if (ct && ct.stuckstakes.Size() > 0) {											// this is needed because we need to move those stakes to the pinvictim when it spawns
					for (int i = ct.stuckstakes.Size()-1; i >= 0; i--)
						ct.stuckstakes[i].master = pinvictim;
				}
			}
			else { // If the victim is not dead and hit by a stake, spawn fake stake that gets "stuck" in it while it's alive
				let stuck = PK_StakeStuck(Spawn("PK_StakeStuck",victim.pos + (frandom(-5,5),frandom(-5,5),victim.height * 0.65 + frandom(-5,5))));
				if (stuck) {
					stuck.master = victim;
					stuck.tracer = self;
					stuck.pitch = pitch;
					stuck.angle = angle;
					stuck.stuckangle = DeltaAngle(angle,victim.angle);
					stuck.stuckpos = stuck.pos - victim.pos;
				}
				if (victim.CountInv("PK_StakeStuckCounter") < 1)
					victim.GiveInventory("PK_StakeStuckCounter",1);
				let ct = PK_StakeStuckCounter(victim.FindInventory("PK_StakeStuckCounter"));
				if (ct && stuck)
					ct.stuckstakes.Push(stuck);
				return -1;
			}
		}
		if (!victim.bISMONSTER && victim.bSOLID) {		//Funnily enough, a solid actor like a column is also processed as 'victim' here. So, if that happens, we stop the stake
			return -1;
		}
		return 1;
	}
	states {
		Spawn:
			MODL A 1 {
				A_FaceMovementDirection(flags:FMDF_INTERPOLATE);		//makes it properly adjust its actual pitch and the associated model's pitch
				if (pinvictim) {
					pinvictim.angle = angle;			//if we already "grabbed" a fake corpse, the stake carries it with it
					pinvictim.vel = vel;
					//pinvictim.SetOrigin(pos - (0,0,pinvictim.height),true);
				}
				if (hitvictim)					//and it carries the real corpse (invisible at this stage) with it as well
					hitvictim.vel = vel;
				else if (target) {
					let stakegun = PK_Stakegun(target.FindInventory("PK_Stakegun"));
					if (stakegun && stakegun.grenades.size() > 0) {
						for (int i = stakegun.grenades.size()-1; i >= 0; i--) {
							if (stakegun.grenades[i] && Distance3D(stakegun.grenades[i]) < 32) {
								let a = Spawn("PK_ExplosiveStake",stakegun.grenades[i].pos);
								if (a) {
									a.vel = vel;
									a.angle = angle;
									a.pitch = pitch+5;
									a.target = target;
									A_StartSound("weapons/stakegun/combo");
								}
								stakegun.grenades[i].destroy();
								destroy();
								return;
							}
						}							
					}
				}
			}
			loop;
		Death: 
			MODL A 100 { 
				if (blockingline) {
					A_StartSound("weapons/stakegun/stakewall",attenuation:2);
					A_SprayDecal("Stakedecal",8);		
				}
				bNOINTERACTION = true;
				bNOGRAVITY = true;
				A_Stop();
				if (hitvictim)
					hitvictim.A_Stop();	//stop moving the real corpse, otherwise it can slide pretty far away if we hit a floor, for example
				if (pinvictim) {
					pinvictim.A_Stop();
					pinvictim.SetOrigin((pos.x,pos.y,pinvictim.pos.z),false);	//make sure the fake corpse is at the middle of the stake
					if (blockingline)	{		//if we hit an actual wall (not a solid obstacle actor), flatten the fake corpse against the wall
						pinvictim.bWALLSPRITE = true;
						pinvictim.angle = atan2(blockingline.delta.y, blockingline.delta.x) - 90;
					}
				}
				if (pinvictim && hitvictim && !blockingline && pos.z <= floorz+4) { //remove the pinned corpse completely if the stake is basically on the floor
					pinvictim.destroy();
					hitvictim.TakeInventory("PK_PinToWall",1);
				}		
			}
			TNT1 A 0 A_SetRenderStyle(1.0,Style_Translucent);
			MODL A 1 A_FadeOut(0.03);
			wait;
		Crash:
		XDeath:
			TNT1 A 1;
			stop;
	}
}

Class PK_StakeFlame : PK_BaseFlare {
	Default {
		scale 0.05;
		renderstyle 'translucent';
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		roll = random[sfx](0,359);
	}
	states {
	Spawn:
		BOM4 JKLMNOPQ 1;
		BOM5 ABCDEFGHIJKLMN 1 A_FadeOut(0.02);
		wait;
	}
}

//Decorative stake stuck in a living monster
Class PK_StakeStuck : Actor {
	state mmissile;
	state mmelee;
	double stuckangle;
	vector3 stuckpos;
	Default {
		+INTERPOLATEANGLES
		+NOINTERACTION
	}
	override void PostBeginPlay() {
		super.PostBeginPlay();
		if (!master)
			return;
		mmissile = master.FindState("Missile");
		mmelee = master.FindState("Melee");
	}
	states {
		Spawn:
			MODL A 1 NoDelay {
				if (master) {
					SetOrigin(master.pos + stuckpos,true);
					angle = master.angle + stuckangle;
					if (master.bWALLSPRITE)
						angle -= 90;
					if (master.bISMONSTER) {
						if (master.health <= 0 && (master.bBOSS || master.mass > 400))
							SetStateLabel("Fall");
						else if (master.InStateSequence(master.curstate,mmissile) || master.InStateSequence(master.curstate,mmelee)) {
							angle += frandom(-5,5);
							SetOrigin(pos + (frandom(-0.4,0.4),frandom(-0.4,0.4),frandom(-0.4,0.4)),true);
						}
					}
				}
				else
					SetStateLabel("Fall");
			}
			loop;
		Fall:
			MODL A 1 {
				vel.z -= gravity;
				if (pos.z <= floorz) {
					A_Stop();
					SetOrigin((pos.x,pos.y,floorz),true);
					pitch = 0;
					bRELATIVETOFLOOR = true;
					bMOVEWITHSECTOR = true;
					A_SetRenderStyle(1.0,Style_Translucent);
					SetStateLabel("End");
				}
			}
			loop;
		End:
			MODL A 1 A_FadeOut(0.03);
			loop;
	}
}

Class PK_StakeStuckCounter : Inventory {
	array <PK_StakeStuck> stuckstakes;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
		inventory.maxamount 1;
	}
}

// This dummy item handles what happens to the actual monster killed by a stake
Class PK_PinToWall : Inventory {
	int PrevRenderstyle;
	Default {
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNCLEARABLE
		inventory.maxamount 1;
	}
	override void AttachToOwner(actor other) {
		super.AttachToOwner(other);
		if (!other)
			return;
		PrevRenderstyle = other.GetRenderstyle();	//save existing renderstyle
		other.A_SetRenderstyle(alpha,STYLE_None);	//make it invisible
		other.bNOGRAVITY = true;
	}
	override void DoEffect() {
		super.DoEffect();
		if (!owner || !owner.bKILLED) {
			DepleteOrDestroy();
			return;
		}
	}
	override void DetachFromOwner() {
		if (!owner)
			return;
		owner.A_SetRenderstyle(alpha,PrevRenderstyle);		//when the item is removed, we reset the monster's renderstyle
		owner.bNOGRAVITY = owner.default.bNOGRAVITY;
		super.DetachFromOwner();
	}
}
	
Class PK_PinVictim : Actor {		//the fake corpse (receives its visuals from the stake)
	Default {
		+NOBLOCKMAP
		+THRUACTORS
		+NOGRAVITY
		//+WALLSPRITE
		radius 2;
	}
	override void Tick(){
		super.Tick();
		if (!target || !target.bKILLED) {	//if the target is non dead or doesn't exist, remove fake corpse
			destroy();
			return;
		}
		target.SetOrigin(pos,true);
	}
	states {
		Spawn:
			#### # 1;
			loop;
	}
}
	
Class PK_Grenade : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "f4f4f4";
		PK_Projectile.trailscale 0.04;
		PK_Projectile.trailfade 0.035;
		PK_Projectile.trailalpha 0.3;
		-NOGRAVITY
		bouncetype 'hexen';
		bouncefactor 0.35;
		gravity 0.45;
		bouncesound "weapons/grenade/bounce";
		height 6;
		radius 8;
		speed 13;		
		damage (25);
	}
	override void Tick() {
		super.Tick();
		if (pos.z <= floorz) {
			vel *= 0.9999;
		}
		if (target && target.FindInventory("PK_Stakegun") && vel ~== (0,0,0)) {
			let stakegun = PK_Stakegun(target.FindInventory("PK_Stakegun"));
			stakegun.grenades.delete(stakegun.grenades.Find(self));
		}
	}
	states {
		Spawn:
			MODL A 1 {
				if (vel.length() < 3) {
					bMISSILE = false;
				}
				if (pos.z <= floorz+4) {
					pitch+= 15;
					let smk = Spawn("PK_WhiteSmoke",pos+(frandom[eld](-2,2),frandom[eld](-2,2),frandom[eld](-2,2)));
					if (smk) {
						smk.vel = (frandom[eld](-0.5,0.5),frandom[eld](-0.5,0.5),frandom[eld](0.2,0.5));
						smk.A_SetScale(0.32);
					}
				}
				else
					A_FaceMovementDirection(flags:FMDF_INTERPOLATE);
				if (age > 35*2)
					SetStateLabel("XDeath");
			}
			loop;
		XDeath:
			TNT1 A 1 { 
				bNOGRAVITY = true;
				A_RemoveChildren(1,RMVF_EVERYTHING);
				A_StopSound(4);
				A_Quake(1,8,0,256,"");
				A_StartSound("weapons/grenade/explosion",CHAN_5);
				A_Explode();
				Spawn("PK_GenericExplosion",pos);
			}
			stop;
	}
}

Class PK_ExplosiveStake : PK_Projectile {
	Default {
		PK_Projectile.trailcolor "ffe8b1";
		PK_Projectile.trailscale 0.02;
		PK_Projectile.trailfade 0.04;
		PK_Projectile.trailalpha 0.35;
		-NOGRAVITY
		speed 60;
		gravity 0.45;
		radius 4;
		height 4;
		damage (40);
		decal "Scorch";
		obituary "%k was impressed by %o's grenade-on-a-stick";
	}
	states {
	Spawn:
		MODL A 1;
		loop;
	Death:
		TNT1 A 1 { 
			bNOGRAVITY = true;
			A_Quake(1,8,0,256,"");
			A_StartSound("weapons/stakegun/comboexplosion",CHAN_AUTO);
			A_Explode(256,200);			
			let ex = Spawn("PK_GenericExplosion",pos);
			if (ex)
				ex.A_SetScale(0.5);
		}
		stop;
	}
}