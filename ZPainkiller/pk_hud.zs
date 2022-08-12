Class PainkillerHUD : BaseStatusBar {
	const noYStretch = 0.833333;
	const PWICONSIZE = 18;
		
	HUDFont mIndexFont;
	HUDFont mNotifFont;
	//HUDFont mStatFont;
	protected class<Inventory> prevLatestPickup;
	protected class<Inventory> curLatestPickup;
	protected double notifAlpha;
	protected double notifAlphaMod;
	protected int notifDur;
	protected CVar notifsCvar;
	protected CVar showCards;
	
	protected int hudstate;
	protected int arrowangle;
	protected int checktic;
	protected int goldnum;
	protected int soulsnum;
	protected int soulscol;
	protected bool isDemon;
	protected PK_Mainhandler mainhandler;
	protected PK_InvReplacementControl invcontrol;
	protected transient CVar aspectScale;
	
	PK_CardControl cardcontrol;
	
	protected vector2 cardTexSize;
	
	protected Actor nearestBoss;
	protected Shape2D healthBarShape;
	protected ui double healthBarFraction;
	protected ui double prevHealthBarFraction;
	protected vector2 hpBarScale;
	protected TextureID hpBarBackground;
	protected TextureID hpBartex;
	protected name bossSpriteName;
	protected TextureID bossSprite;
		
	/*	
		I'm using these wrappers to counteract Doom's native vertical
		pixel stretch. I could also counteract it by using a forcescaled
		HUD, but that would disable user-side HUD scaling, and I wanted
		to let the players change the size of the HUD no matter what,
		so I ended up using this simple HUD.
		It checks for the value of the hud_aspectscale CVAR that 
		determines whether HUD stretching is used, and if true,
		simply multiplies vertical position and scale of all elements by
		0.83... which effectively gets rid of all stretching.
	*/
	void PK_DrawImage(String texture, Vector2 pos, int flags = 0, double Alpha = 1., Vector2 box = (-1, -1), Vector2 scale = (1, 1)) {
		if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}
		DrawImage(texture, pos, flags, Alpha, box, scale);
	}
	
	// Same as above but for strings
	void PK_DrawString(HUDFont font, String string, Vector2 pos, int flags = 0, int translation = Font.CR_UNTRANSLATED, double Alpha = 1., int wrapwidth = -1, int linespacing = 4, Vector2 scale = (1, 1)) {
		if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}
		DrawString(font, string, pos, flags, translation, Alpha, wrapwidth, linespacing, scale);
	}

	// Same as above but for inventory icons
	void PK_DrawInventoryIcon(Inventory item, Vector2 pos, int flags = 0, double alpha = 1.0, Vector2 boxsize = (-1, -1), Vector2 scale = (1.,1.)) {
		if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}
		DrawInventoryIcon(item, pos, flags, alpha, boxsize, scale);
	}
	
	override void Init() {
		super.Init();
		Font fnt = "PKHNUMS"; //font with numbers 
		Font times = font_times; //Times font used in other places too
		mIndexFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true, 1, 1);
		mNotifFont = HUDFont.Create("consolefont");
		// Base values for the Codex notif pop-up:
		notifAlpha = 0.6;
		notifAlphaMod = 0.05;
		// Values for the circular boss health bar:
		hpBarBackground = TexMan.CheckForTexture("pkxhpbkg");
		hpBartex = TexMan.CheckForTexture("pkxhpbar");
		hpBarScale = TexMan.GetScaledSize(hpBartex);
		//dimensions of a card texture:
		cardTexSize = TexMan.GetScaledSize(TexMan.CheckForTexture("graphics/HUD/Tarot/cards/UsedCard.png"));
	}
	
	override void Draw (int state, double TicFrac) {
		Super.Draw (state, TicFrac);
		if (aspectScale == null)
			aspectScale = CVar.GetCvar('hud_aspectscale',CPlayer);
		
		hudstate = state;
		//the hud is completely skipped if automap is active or the player
		//is in a demon mode and debug messages aren't active:
		if (state == HUD_none || automapactive || (isDemon /*&& !pk_debugmessages*/))
			return;
		BeginHUD();
		//draw invulnerability overlay:
		if (CPlayer.mo.FindInventory("PowerInvulnerable",true)) {
			PK_DrawImage("PKHHORNS",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);
		}
		// Top elements draw in Fullscreen and Alt Hud
		// These include mosnter compass, gold and soul counters, and keys:
		if (state == HUD_Fullscreen || state == HUD_AltHud)
			DrawTopElements();
		// Health, armor, ammo, etc.
		// In statusbar mode it also moves the monster compass,
		// keys, gold and soul counters to the bottom
		if (state == HUD_StatusBar || state == HUD_Fullscreen)
			DrawBottomElements();
		DrawEquippedCards();
		DrawCardUses();
		DrawCodexNotif();
		DrawActiveGoldenCards();
		// Keys are already present in the AltHud:
		if (state != HUD_AltHud) {
			DrawKeys();
		}		
	}	
	
	// Draws arrow for the compass pointing at the nearest monster.
	// Incorporates no-vertical-stretch effect from the above.
	void DrawMonsterArrow(vector2 arrowPos = (0,23), vector2 shadowofs = (0,0)) {
		if (nearestBoss)
			return;
		int fflags = (hudstate == HUD_StatusBar) ? DI_SCREEN_CENTER_BOTTOM : DI_SCREEN_HCENTER;
		vector2 arrowscale = (1, 1);
		if (hudstate == HUD_StatusBar)
			arrowscale *= 1.2;
		if (aspectScale.GetBool() == true) {
			arrowscale.y /= noYStretch;
			arrowPos.y *= noYStretch;
			shadowOfs.y *= noYStretch;
		}
		if (shadowofs != (0,0)) {
			DrawImageRotated("pkharrow", arrowPos+shadowOfs, fflags, arrowangle, scale: arrowscale, col:color(128,0,0,0));	
		}
		DrawImageRotated("pkharrow", arrowPos, fflags, arrowangle, scale: arrowscale);
	}
	
	//show 3 active golden cards at the lower center of the screen
	protected void DrawActiveGoldenCards() {
		if (!cardcontrol || (!cardcontrol.goldActive && cardcontrol.GetDryUseTimer() <= 0))
			return;			
		for (int i = 2; i < 5; i++) {
			if (cardcontrol.EquippedSlots[i]) {
				string texpath = String.Format("graphics/HUD/Tarot/cards/%s.png",cardcontrol.EquippedSlots[i]);
				vector2 cardpos = ((-77 + i*22),-80);
				int fflags = DI_SCREEN_CENTER_BOTTOM|DI_ITEM_LEFT_TOP;
				PK_DrawImage(texpath,cardpos,fflags,scale:(0.14,0.14));
				//if out of uses, draw a red overlay atop the cards
				if (cardcontrol.GetDryUseTimer() > 0)
					PK_DrawImage("graphics/HUD/Tarot/cards/UsedCard.png",cardpos,fflags,alpha:0.75,scale:(0.14,0.14));
			}
		}
	}
	
	// A very basic function that draws icons for the active power-ups
	// vertically, at the right side of the screen.
	// It also makes sure to not move the icons up and down when a specific
	// icon is blinking, as opposed to the similar vanilla function.
	override void DrawPowerUps() {
		Vector2 pos = (-PWICONSIZE / 2, -49);
		for (let iitem = CPlayer.mo.Inv; iitem != NULL; iitem = iitem.Inv) {
			let item = Powerup(iitem);
			if (item != null) {
				let icon = item.GetPowerupIcon();
				if (icon.IsValid()) {
					if (!item.IsBlinking())
						DrawTexture(icon, pos, DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER, 1.0, (PWICONSIZE, PWICONSIZE));
					pos.y -= PWICONSIZE;
				}
			}
		}
	}

	override void Tick() {
		super.Tick();
		let player = CPlayer.mo;
		if (!player)
			return;
		/*	check if player is demon (cheaper to do it here than in Draw, fewer calls)
			This is supposed to be true whenever the player has a demon weapon,
			not only when they're actually a demon, since seeing a "demon preview"
			is also supposed to disable the HUD.
		*/
		isDemon = player.CountInv("PK_DemonWeapon");
		if (isDemon || hudstate == HUD_None)
			return;
		//get gold amount:
		if (!cardcontrol)
			cardcontrol = PK_CardControl(player.FindInventory("PK_CardControl"));
		if (cardcontrol)
			goldnum = cardcontrol.GetGoldAmount();
		//get souls amount:
		let dmcont = PK_DemonMorphControl(player.FindInventory("PK_DemonMorphControl"));
		if (dmcont) {
			soulsnum = dmcont.GetSouls();
			//make souls number red if it's only 3 souls before turning into demon:
			soulscol = (soulsnum >= dmcont.GetMinSouls()) ? Font.CR_RED : Font.CR_UNTRANSLATED;
		}
		UpdateCodexNotif();
		UpdateMonsterCompass();
	}
	
	// Update information for the monster compass to determine
	// where the arrow is going to point:
	protected void UpdateMonsterCompass() {		
		let player = CPlayer.mo;
		if (!player)
			return;
		//get pointer to PK_Mainhandler:
		if (!mainhandler)
			mainhandler = PK_Mainhandler(EventHandler.Find("PK_Mainhandler"));
		if (!mainhandler)
			return;		

		//Find nearest boss, if any:
		int bosses = mainhandler.allbosses.size();
		if (bosses > 0) {
			actor bossmonster;
			double closestDist = 1400;
			for (int i = 0; i < bosses; i++) {
				let act = mainhandler.allbosses[i];
				if (act && act.target) {
					int dist = player.Distance2D(act);
					if (closestDist > 0 && dist < closestDist) {
						bossmonster = act;
						closestDist = dist;
					}
				}
			}
			if (bossmonster) {
				nearestBoss = bossmonster;
				if (nearestBoss.SpawnState && nearestBoss.SpawnState.sprite) {
					bossSprite = nearestBoss.SpawnState.GetSpriteTexture(2);
					bossSpriteName = TexMan.GetName(bossSprite);
				}
				prevHealthBarFraction = healthBarFraction;
				healthBarFraction = bossmonster.health*1. / bossmonster.GetMaxHealth(true);
				
				// Only update the shape if the health actually changed
				if (prevHealthBarFraction != healthBarFraction)
					UpdateHealthBar(healthBarShape, healthBarFraction);
			}
			else {
				bossSpritename = '';
				nearestBoss = null;
			}
		}
		if (nearestBoss)
			return;
		
		//If no bosses around, find nearest regular monster:
		int enemies = mainhandler.allenemies.size();
		if (enemies > 0) {
			//check 2D distance to every monster in the array and find the closest one:
			actor closestMonst;
			double closestDist = double.infinity;
			for (int i = 0; i < enemies; i++) {
				let act = mainhandler.allenemies[i];
				if (act) {
					int dist = player.Distance2DSquared(act);
					if (closestDist > 0 && dist < closestDist) {
						closestMonst = act;
						closestDist = dist;
					}
				}
			}
			//define the angle for the monster compass arrow based on the relative position of the monster:
			if (closestMonst) {
				arrowangle = (Actor.DeltaAngle(player.angle, player.AngleTo(closestMonst)));
				//console.printf("%s angle %d",closestMonst.GetClassName(),arrowangle);
			}
		}
	}
	
	// Draw notification pop-up for a new Codex entry.
	// This happens when you pick up a weapon, or item that haven't been 
	// picked up before, as well as in some specific cases, such as
	// opening the Tarot for the first time, getting gold, etc.
	// (All of those are handled manually in those places.)
	protected void DrawCodexNotif() {
		// Do nothing if the player disabled Codex notifs:
		if (!notifsCvar || notifsCvar.GetBool() == false)
			return;
		// Do nothing if there's no recorded last pickup:
		if (!invcontrol || !invcontrol.latestPickup || invcontrol.codexOpened)
			return;
		// Get the name of the pickup (not necessarily weapon):
		string weapname = StringTable.Localize(invcontrol.latestPickupName);
		// Get the binding for opening the Codex:
		string codexKey = PK_Keybinds.getKeyboard("netevent PKCOpenCodex");
		// Draw the notification:
		// "Codex updated"
		vector2 pos1 = (-4, 0);
		PK_DrawString(mNotifFont, String.Format(StringTable.Localize("$PKC_NEWENTRY"),codexKey), pos1, DI_SCREEN_RIGHT_TOP|DI_TEXT_ALIGN_RIGHT, Font.CR_Gold, alpha: notifAlpha);
		// Codex tab name:
		vector2 pos2 = (pos1.x, pos1.y + 10);
		PK_DrawString(mNotifFont, weapname, pos2, DI_SCREEN_RIGHT_TOP|DI_TEXT_ALIGN_RIGHT, Font.CR_Gold, alpha: notifAlpha);
	}
	
	// Handle the Codex notif display:
	protected void UpdateCodexNotif() {
		let player = CPlayer.mo;
		if (!player)
			return;
		// Cache the "allow notifs" CVAR:
		if (!notifsCvar)
			notifsCvar = CVar.GetCVar('pk_CodexNotifs', CPlayer);
		if (notifsCvar.GetBool() == false)
			return;
		if (!invcontrol)
			invcontrol = PK_InvReplacementControl(player.FindInventory("PK_InvReplacementControl"));
		// Do nothing if there's no recorded last pickup:
		if (!invcontrol || !invcontrol.latestPickup || invcontrol.codexOpened)
			return;
		curLatestPickup = invcontrol.latestPickup;
		double targetMod;
		vector2 notifAlphaLimits;
		// Keep displaying the same notif as long as we haven't picked up
		// anythign new:
		if (prevLatestPickup && prevLatestPickup == curLatestPickup) {
			// The notif has a limited duration. If it's above 0,
			// the notif flashes between 0.5 and 1.0 alpha:
			if (notifDur > 0) {
				notifDur--; //decrement duration
				notifAlphaLimits = (0.5, 1);
				targetMod = 0.05; //alpha step
			}
			// Otherwise the notif doesn't disappear but instead
			// flashes between 0.1 and 0.25 alpha with lower speed:
			else {
				notifAlphaLimits = (0.1, 0.25);
				targetMod = 0.005; //alpha step
			}
			// double-check the alpha step is correct:
			if (abs(notifAlphaMod) != targetMod)
				notifAlphaMod = targetMod;
			notifAlpha = Clamp(notifAlpha + notifAlphaMod, notifAlphaLimits.x, notifAlphaLimits.y);
			// invert alpha step if the alpha reaches the top/bottom limit:
			if (notifAlpha <= notifAlphaLimits.x || notifAlpha >= notifAlphaLimits.y)
				notifAlphaMod *= -1;
			return;
		}
		// Set the initial duration to 175:
		else {
			notifDur = 175;
			prevLatestPickup = curLatestPickup;
		}
	}
	
	// Draws currently equipped cards (not present in the original game)
	protected void DrawEquippedCards() {
		if (!cardcontrol)
			return;
		if (!showCards)
			showCards = CVar.GetCVar('pk_ShowCardsInHUD', CPlayer);
		if (!showCards || !showCards.GetBool())
			return;
		int cwidth = 19; //card width
		int xpos = 2;
		vector2 sscale = (0.13, 0.13);
		int fflags = DI_SCREEN_LEFT_TOP|DI_ITEM_LEFT_TOP;
		for (int slot = 0; slot < 5; slot++) {
			if (!cardcontrol.EquippedSlots[slot])
				continue;			
			string tex = String.Format("graphics/HUD/Tarot/cards/%s.png",cardcontrol.EquippedSlots[slot]);
			vector2 pos = (xpos + cwidth * slot, 1);
			PK_DrawImage(tex, pos, fflags, scale: sscale);
			if (slot >= 2 && !cardcontrol.goldActive && cardcontrol.GetGoldUses() <= 0)
				PK_DrawImage("graphics/HUD/Tarot/cards/UsedCard.png", pos, fflags, alpha: 0.7, scale: sscale);
		}	
	}	
	
	// Draws a small indicator with a number of remaining
	// golden cards activations (not present in the original
	// game):
	protected void DrawCardUses() {
		if (!cardcontrol)
			return;
		// Check if any gold cards are equipped:
		if (!cardcontrol.EquippedSlots[2] && !cardcontrol.EquippedSlots[3] && !cardcontrol.EquippedSlots[4])
			return;
		// Draw to the left of the top bar by default:
		int fflags = DI_SCREEN_TOP|DI_SCREEN_HCENTER;		
		vector2 ppos = (-94, 24);
		// For statusbar mode, draw next to the bottom
		// left panel with health/armor:
		if (hudstate == HUD_StatusBar) {
			fflags = DI_SCREEN_LEFT_BOTTOM;
			ppos = (69, -14);
		}				
		// Draw the indicator and the number of uses:
		PK_DrawImage("pkxuses", ppos, (fflags |= DI_ITEM_RIGHT));
		PK_DrawString(
			mIndexFont, 
			String.Format("%d", cardcontrol.GetGoldUses()), 
			ppos - (7.4, 17), 
			(fflags |= DI_TEXT_ALIGN_LEFT),
			scale: (0.8, 0.8)
		);
	}
	
	//draw all bottom elements (health/armor/ammo)
	protected void DrawBottomElements() {
		//draw bottom corners:
		PK_DrawImage("pkxleft",(0,0),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_LEFT_BOTTOM);
		PK_DrawImage("pkxright",(0,0),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM);
		
		//draw health and armor icons:
		PK_DrawImage("pkhlife",(11,-23),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER ,0.8);
		
		//draw armor icon:
		let armor = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		if (armor && armor.amount > 0)
			PK_DrawInventoryIcon(armor, (11, -11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
		else
			PK_DrawImage("pkharm0",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER,0.8);
		
		//draw health and armor amounts:
		int healthColor = CPlayer.Health <= 20 ? Font.CR_Red : Font.CR_UNTRANSLATED;
		PK_DrawString(mIndexFont, String.Format("%03d",CPlayer.health), (19, -28),DI_SCREEN_LEFT_BOTTOM,translation:healthColor);
		PK_DrawString(mIndexFont, String.Format("%03d",GetArmorAmount()), (19, -16),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		
		// Ff using statusbar, we don't draw the top bar at all 
		// and we draw souls/gold counters as well as compass at the bottom:
		if (hudstate == HUD_StatusBar) {		
			//draw compass at bottom center
			PK_DrawImage("pkxtop0",(0,4),DI_SCREEN_BOTTOM|DI_SCREEN_HCENTER|DI_ITEM_BOTTOM);
			//draw arrow and outline (shadow and glass are skipped in this version for simplicity)
			DrawMonsterArrow(arrowPos: (0,-24));
		
			//gold counter above health:
			PK_DrawImage("pkhgold",(5,-38),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mIndexFont, String.Format("%05d",goldnum), (10, -43),DI_SCREEN_LEFT_BOTTOM|DI_TEXT_ALIGN_LEFT,translation:font.CR_UNTRANSLATED);			
			//souls counter above ammo:
			PK_DrawImage("pkhsouls",(-5,-38),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mIndexFont, String.Format("%05d",soulsnum), (-10,-43),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:soulscol);
			
			DrawBossHealthBar(true);
		}		
		
		//AMMO
		let weap = CPlayer.readyweapon;
		// If Painkiller is selected, explicitly draw painkiller blade/projectile
		// icons and an infinity symbol next to them:
		if (weap && weap.GetClassName() == "PK_Painkiller") {
			PK_DrawImage("pkhpkill",(-13,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhblade",(-13,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhinfin",(-30,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhinfin",(-30,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			return; //and do nothing else
		}
		// Otherwise draw the proper ammo icons and amounts:
		Inventory ammotype1, ammotype2;
		[ammotype1, ammotype2] = GetCurrentAmmo();
		if (ammotype1) {
			PK_DrawInventoryIcon(ammotype1, (-11,-22),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mIndexFont, String.Format("%03d",ammotype1.amount),(-19,-27),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:GetAmmoColor(ammotype1));
		}
		if (ammotype2) {
			PK_DrawInventoryIcon(ammotype2, (-11,-10),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mIndexFont, String.Format("%03d",ammotype2.amount),(-19,-15),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:GetAmmoColor(ammotype2));
		}
	}
	
	//top bar, compass, and souls and gold counters:
	protected void DrawTopElements() {
		//draw the compass background:
		PK_DrawImage("pkxtop0",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);
		//otherwise draw the compass arrow (in 3 layers):
		DrawMonsterArrow(shadowofs: (3,3));
		
		//draw the top bar and the compass outline:
		PK_DrawImage("pkxtop1",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);	//main top
		PK_DrawImage("pkxtop2",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP,alpha:0.4);	//glass
		//draw souls and gold on the top bar:
		PK_DrawImage("pkhgold",(-31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		PK_DrawImage("pkhsouls",(31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		//draw souls and gold values on the top bar:
		PK_DrawString(mIndexFont, String.Format("%05d",goldnum), (-38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_RIGHT,translation:font.CR_UNTRANSLATED);			
		PK_DrawString(mIndexFont, String.Format("%05d",soulsnum), (38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_LEFT,translation:soulscol);
		//if there's a boss around, draw healthbar for it:
		DrawBossHealthBar();
	}
	
	// Draws circular boss health bar around the compass.
	// The healthbar becomes active if there's a boss relatively close
	// and they're active (has a target).
	// Written by Boondorl, adapted to HUD by me.
	protected void DrawBossHealthBar(bool bottom = false) {
		if (!nearestBoss)
			return;
		vector2 hudscale = GetHUDScale();
		Vector2 barScale = (hpBarScale.x * hudscale.x, hpBarScale.y * hudscale.y);
		int posx = Screen.GetWidth() / 2.;
		int posy = hpBarScale.y / 2 * hudscale.y;
		if (bottom)
			posy = Screen.GetHeight() - posy;
		Screen.DrawTexture(hpBarBackground, false, posx, posy,
			DTA_CenterOffset, true,
			DTA_DestWidthF, barScale.x,
			DTA_DestHeightF, barScale.y
		);
		
		// Correctly scale the shape and shift it to the health bar background's location:
		let transform = new("Shape2DTransform");
		transform.Scale(barScale * 0.5); //for some reason without * 0.5 the healthbar is twice as big
		transform.Translate((posx,posy));
		healthBarShape.SetTransform(transform);
		
		// Draw health bar:
		Screen.DrawShape(hpbartex, false, healthBarShape);
		
		//Draw boss sprite:
		vector2 spritescale = ScaleToBox(bossSprite,barScale.x,barScale.y) * 0.65;
		Screen.DrawTexture(bossSprite, false, posx, posy,
			DTA_CenterOffset, true,
			DTA_TranslationIndex, Translation.GetID('PK_HUDBoss'),
			DTA_DestWidthF, spritescale.x,
			DTA_DestHeightF, spritescale.y
		);
	}
	
	// Scales an image to box keeping its ratio:
	vector2 ScaleToBox(TextureID tex, int w, int h) {
		Vector2 size = TexMan.GetScaledSize(tex);
		double ratio = min(w / size.x, h / size.y*1.2);

		return size * ratio;
	}
	
	protected void UpdateHealthBar(out Shape2D hb, double frac = 1, uint segments = 100)
	{
		// Create the circle if we don't have one yet
		if (!hb)
		{
			hb = new("Shape2D");
			
			// What starting angle you use and which direction you go 
			// (clockwise or counter clockwise) will determine where 
			// the healthbar starts and which direction it removes segments:
			double angStep = -360. / segments; // - decreases clockwise, + decreases counter clockwise
			double ang = 270; // 90 = bottom, 270 = top, 0 = right, 180 = left
			
			// Anchor a point in the middle
			hb.PushVertex((0,0));
			hb.PushCoord((0.5,0.5));
			
			// Circumference points
			for (uint i = 0; i < segments; ++i)
			{
				double c = cos(ang);
				double s = sin(ang);
				
				hb.PushVertex((c,s));
				hb.PushCoord(((c+1)/2, (s+1)/2));
				
				ang += angStep;
			}
		}
		
		// Only draw segments up to a fraction of our total segments based on remaining health
		hb.Clear(Shape2D.C_Indices);
		int maxSegments = ceil(segments * frac);
		for (uint i = 1; i <= maxSegments; ++i)
		{
			int next = i+1;
			if (next > segments)
				next -= segments;
			
			hb.PushTriangle(0, i, next); // Use the middle anchor point
		}
	}
		
	// Ammo counter is red if we have 25% or fewer ammo:
	int GetAmmoColor(Inventory ammoclass) {		
		int ammoColor = FONT.CR_UNTRANSLATED;
		if (ammoclass.amount <= ammoclass.default.maxamount * 0.25) 
			ammoColor = FONT.CR_RED;			
		return ammoColor;
	}

	//Roughtly copied from AltHUD but returns the texture, not a bool:
	protected TextureID GetKeyTexture(Key inv) {		
		TextureID icon;	
		if (!inv) 
			return icon;
		TextureID AltIcon = inv.AltHUDIcon;
		if (!AltIcon.Exists()) 
			return icon;	// Setting a non-existent AltIcon hides this key.

		if (AltIcon.isValid()) 
			icon = AltIcon;
		else if (inv.SpawnState && inv.SpawnState.sprite) {
			let state = inv.SpawnState;
			if (state) 
				icon = state.GetSpriteTexture(0);
			else 
				icon.SetNull();
		}
		// missing sprites map to TNT1A0. So if that gets encountered, use the default icon instead.
		if (icon.isNull() || TexMan.GetName(icon) == 'tnt1a0') 
			icon = inv.Icon; 

		return icon;
	}
	
	// Draws keys in a horizontal bar, similarly to how AltHUD
	// does it, but does NOT ignore HUD scale:
	void DrawKeys() {
		if (deathmatch)
			return;		
		int hofs = 1;
		vector2 iconpos = (0, -34);
		if (hudstate == HUD_StatusBar)
			iconpos.y -= 10;
		
		int count = Key.GetKeyTypeCount();			
		for(int i = 0; i < count; i++)	{
			Key inv = Key(CPlayer.mo.FindInventory(Key.GetKeyType(i)));
			TextureID icon = GetKeyTexture(inv);
			if (icon.IsNull()) 
				continue;
			vector2 iconsize = TexMan.GetScaledSize(icon) * 0.5;
			DrawTexture(icon, iconpos, flags: DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM, scale: (0.5, 0.5));
			iconpos.x -= (iconsize.x + hofs);
		}
	}
}