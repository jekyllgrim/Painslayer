Class PainkillerHUD : BaseStatusBar {
	const noYStretch = 0.833333;
	const PWICONSIZE = 18;
	//const PKHUDwidth = 320;
	//const PKHUDheight = 200;
		
	HUDFont mIndexFont;
	HUDFont mStatFont;
	
	private int hudstate;
	private int arrowangle;
	private int checktic;
	private int goldnum;
	private int soulsnum;
	private int soulscol;
	private bool isDemon;
	private PK_Mainhandler mainhandler;
	private transient CVar aspectScale;
	
	PK_CardControl cardcontrol;
	
	private Actor nearestBoss;
	private Shape2D healthBarShape;
	private ui double healthBarFraction;
	private ui double prevHealthBarFraction;
	private vector2 hpBarScale;
	private TextureID hpBarBackground;
	private TextureID hpBartex;
	private name bossSpriteName;
	private TextureID bossSprite;
	
	void DrawMonsterArrow(vector2 arrowPos = (0,23), vector2 shadowofs = (0,0)) {
		int fflags = (hudstate == HUD_StatusBar) ? DI_SCREEN_CENTER_BOTTOM : DI_SCREEN_HCENTER;
		vector2 arrowscale = (1, 1);
		if (hudstate == HUD_StatusBar)
			arrowscale *= 1.2;
		/*if (aspectScale.GetBool() == true) {
			arrowscale.y *= noYStretch;
			arrowPos.y *= noYStretch;
		}*/
		//draw shadow:
		if (shadowofs != (0,0)) {
			DrawImageRotated("pkharrow", arrowPos+shadowOfs, fflags, arrowangle, scale: arrowscale, col:color(128,0,0,0));	
		}
		//draw arrow:
		DrawImageRotated("pkharrow", arrowPos, fflags, arrowangle, scale: arrowscale);
	}
	
	/*	My HUD was originally coded using StatusBar's DrawImage, DrawString and DrawInventoryIcon,
		but later I realized I need to ignore "Preserve HUD aspect ratio" option because it leads to
		Y-stretching of pixels, which ruins round HUD elements.
		Since I didn't feel like rewriting the whole HUD, functions below are super-lazy wrappers
		that simply multiply vertical scale and pos by ~0.83 if "Preserve HUD scale" option is enabled.
	*/
	void PK_DrawImage(String texture, Vector2 pos, int flags = 0, double Alpha = 1., Vector2 box = (-1, -1), Vector2 scale = (1, 1)) {
		/*if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}*/
		DrawImage(texture, pos, flags, Alpha, box, scale);
	}
	
	void PK_DrawString(HUDFont font, String string, Vector2 pos, int flags = 0, int translation = Font.CR_UNTRANSLATED, double Alpha = 1., int wrapwidth = -1, int linespacing = 4, Vector2 scale = (1, 1)) {
		/*if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}*/
		DrawString(font, string, pos, flags, translation, Alpha, wrapwidth, linespacing, scale);
	}
	
	void PK_DrawInventoryIcon(Inventory item, Vector2 pos, int flags = 0, double alpha = 1.0, Vector2 boxsize = (-1, -1), Vector2 scale = (1.,1.)) {
		/*if (aspectScale.GetBool() == true) {
			scale.y *= noYStretch;
			pos.y *= noYStretch;
		}*/
		DrawInventoryIcon(item, pos, flags, alpha, boxsize, scale);
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
	
	override void Init() {
		super.Init();
		Font fnt = "PKHNUMS";
		hpBarBackground = TexMan.CheckForTexture("pkxhpbkg");
		hpBartex = TexMan.CheckForTexture("pkxhpbar");
		hpBarScale = TexMan.GetScaledSize(hpBartex);
		mIndexFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
		mStatFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
	}
	
	override void Draw (int state, double TicFrac) {
		Super.Draw (state, TicFrac);
		/*if (aspectScale == null)
			aspectScale = CVar.GetCvar('hud_aspectscale',CPlayer);
		*/
		hudstate = state;
		//the hud is completely skipped if automap is active or the player
		//is in a demon mode and debug messages aren't active:
		if (state == HUD_none || automapactive || (isDemon && !pk_debugmessages))
			return;
		BeginHUD();
		//draw invulnerability overlay:
		if (CPlayer.mo.FindInventory("PowerInvulnerable",true)) {
			PK_DrawImage("PKHHORNS",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);
		}
		if (state == HUD_Fullscreen || state == HUD_AltHud)
			DrawTopElements();
		if (state == HUD_StatusBar || state == HUD_Fullscreen)
			DrawBottomElements();
		//DrawEquippedCards();
		DrawActiveGoldenCards();
		if (state != HUD_AltHud) {
			vector2 keyofs = (1920,920);
			if (state == HUD_StatusBar)
				keyofs.y -= 40;
			DrawKeys(keyofs.x,keyofs.y);
		}
		fullscreenOffsets = true;
	}
	
	override void Tick() {
		super.Tick();
		let player = CPlayer.mo;
		if (!player)
			return;
		//check if player is demon (cheaper to do it here than in Draw, fewer calls)
		isDemon = player.CountInv("PK_DemonWeapon");
		//get gold amount:
		if (!cardcontrol)
			cardcontrol = PK_CardControl(player.FindInventory("PK_CardControl"));
		else
			goldnum = cardcontrol.pk_gold;
		//get souls amount:
		let dmcont = PK_DemonMorphControl(player.FindInventory("PK_DemonMorphControl"));
		if (dmcont) {
			soulsnum = dmcont.GetSouls();
			//make souls number red if it's only 3 souls before turning into demon:
			soulscol = (soulsnum >= dmcont.GetMinSouls()) ? Font.CR_RED : Font.CR_UNTRANSLATED;
		}
		if (hudstate == HUD_None)
			return;
			
		//get access to the array of all enemies from PK_Mainhandler:
		if (!mainhandler)
			mainhandler = PK_Mainhandler(EventHandler.Find("PK_Mainhandler"));
		if (!mainhandler)
			return;		

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
	
	//draws currently equipped cards (not present in the original game):
	protected void DrawEquippedCards() {
		if (!cardcontrol)
			return;
		for (int i = 0; i < 5; i++) {
			if (cardcontrol.EquippedSlots[i]) {
				string texpath = String.Format("graphics/Tarot/cards/%s.png",cardcontrol.EquippedSlots[i]);
				PK_DrawImage(texpath,((4 + i*18),2),DI_SCREEN_LEFT_TOP|DI_ITEM_LEFT_TOP,scale:(0.12,0.12));
			}
			string framepath;
			if (i < 2)
				framepath = "graphics/Tarot/cards/FrameSilver.png";
			else
				framepath = "graphics/Tarot/cards/FrameGold.png";
			PK_DrawImage(framepath,((4 + i*18),2),DI_SCREEN_LEFT_TOP|DI_ITEM_LEFT_TOP,scale:(0.12,0.12));
		}
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
		if (armor && armor.amount > 0) {
			//this is for cheaters: if "give all" was used, forcefully display gold armor icon, otherwise gzdoom will display BlueArmor icon			
			if (armor.amount >= 200 && armor.ArmorType != "PK_BronzeArmor" && armor.ArmorType != "PK_SilverArmor" && armor.ArmorType != "PK_GoldArmor")
				PK_DrawImage("pkharm3",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER,0.8);
			else
				PK_DrawInventoryIcon(armor, (11, -11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
		}
		else
			PK_DrawImage("pkharm0",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER,0.8);
		
		//draw health and armor amounts:
		PK_DrawString(mIndexFont, String.Format("%03d",CPlayer.health), (19, -28),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		PK_DrawString(mIndexFont, String.Format("%03d",GetArmorAmount()), (19, -16),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		
		//if using statusbar, we don't draw the top bar at all and we draw souls/gold counters as well as compass at the bottom:
		if (hudstate == HUD_StatusBar) {		
			//draw compass at bottom center
			PK_DrawImage("pkxtop0",(0,4),DI_SCREEN_BOTTOM|DI_SCREEN_HCENTER|DI_ITEM_BOTTOM);
			//draw arrow and outline (shadow and glass are skipped in this version for simplicity)
			DrawMonsterArrow(arrowPos: (0,-24));
		
			//gold counter above health:
			PK_DrawImage("pkhgold",(5,-38),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mStatFont, String.Format("%05d",goldnum), (10, -43),DI_SCREEN_LEFT_BOTTOM|DI_TEXT_ALIGN_LEFT,translation:font.CR_UNTRANSLATED);			
			//souls counter above ammo:
			PK_DrawImage("pkhsouls",(-5,-38),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawString(mStatFont, String.Format("%05d",soulsnum), (-10,-43),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:soulscol);
		}		
		
		//AMMO
		let weap = CPlayer.readyweapon;
		//if Painkiller is selected, explicitly draw painkiller blade/projectile icons and an infinity symbol next to them:
		if (weap && weap.GetClassName() == "PK_Painkiller") {
			PK_DrawImage("pkhpkill",(-13,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhblade",(-13,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhinfin",(-30,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			PK_DrawImage("pkhinfin",(-30,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			return; //and do nothing else
		}
		//otherwise draw the proper ammo
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
		if (!nearestBoss)
			DrawMonsterArrow(shadowofs: (3,3));
		
		//draw the top bar and the compass outline:
		PK_DrawImage("pkxtop1",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);	//main top
		PK_DrawImage("pkxtop2",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP,alpha:0.4);	//glass
		//draw souls and gold on the top bar:
		PK_DrawImage("pkhgold",(-31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		PK_DrawImage("pkhsouls",(31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		//draw souls and gold values on the top bar:
		PK_DrawString(mStatFont, String.Format("%05d",goldnum), (-38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_RIGHT,translation:font.CR_UNTRANSLATED);			
		PK_DrawString(mStatFont, String.Format("%05d",soulsnum), (38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_LEFT,translation:soulscol);
		//if there's a boss around, draw healthbar for it:
		if (nearestBoss)
			DrawBossHealthBar();
	}
	
	protected void DrawBossHealthBar() {
		if (!nearestBoss)
			return;
		vector2 hudscale = GetHUDScale();
		Vector2 barScale = (hpBarScale.x * hudscale.x, hpBarScale.y * hudscale.y);
		int posx = Screen.GetWidth() / 2.;
		int posy = hpBarScale.y / 2 * hudscale.y;
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
		Screen.DrawTexture(bossSprite, false, posx, posy,
			DTA_CenterOffset, true,
			DTA_TranslationIndex, Translation.GetID('PK_HUDBoss'),
			DTA_DestWidthF, barScale.x * 0.6,
			DTA_DestHeightF, barScale.y * 0.8
		);
	}
	
	void UpdateHealthBar(out Shape2D hb, double frac = 1, uint segments = 100)
	{
		// Create the circle if we don't have one yet
		if (!hb)
		{
			hb = new("Shape2D");
			
			// What starting angle you use and which direction you go (clockwise or counter clockwise)
			// will determine where the healthbar starts and which direction it removes segments
			double angStep = -360. / segments; // + = bar decreases counter clockwise, - = bar decreases clockwise
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
		

	int GetAmmoColor(Inventory ammoclass) {		
		int ammoColor;
		if	(ammoclass.amount > ammoclass.default.maxamount * 0.25) 
			ammoColor = FONT.CR_UNTRANSLATED;
		else
			ammoColor = FONT.CR_RED;			
		return ammoColor;
	}

	//functions copied from AltHud (with some tweaks):
	virtual bool DrawOneKey(int xo, int x, int y, in out int c, Key inv)
	{
		TextureID icon;
		
		if (!inv) return false;
		
		TextureID AltIcon = inv.AltHUDIcon;
		if (!AltIcon.Exists()) return false;	// Setting a non-existent AltIcon hides this key.

		if (AltIcon.isValid()) 
		{
			icon = AltIcon;
		}
		else if (inv.SpawnState && inv.SpawnState.sprite!=0)
		{
			let state = inv.SpawnState;
			if (state != null) icon = state.GetSpriteTexture(0);
			else icon.SetNull();
		}
		// missing sprites map to TNT1A0. So if that gets encountered, use the default icon instead.
		if (icon.isNull() || TexMan.GetName(icon) == 'tnt1a0') icon = inv.Icon; 

		if (icon.isValid())
		{
			DrawImageToBox(icon, x, y, 20, 26);
			return true;
		}
		return false;
	}
	
	void DrawKeys(int x, int y) {
		int yo = y;
		int xo = x;
		int i;
		int c = 0;
		Key inv;
		
		if (deathmatch)
			return;
		int count = Key.GetKeyTypeCount();			
		// Go through the key in reverse order of definition, because we start at the right.
		for(int i = count-1; i >= 0; i--)	{
			if ((inv = Key(CPlayer.mo.FindInventory(Key.GetKeyType(i)))) && DrawOneKey(xo, x - 22, y, c, inv)) {
				x -= 22;
				if (++c >= 10)	{
					x = xo;
					y -= 11;
					c = 0;
				}
			}
		}
		if (x == xo && y != yo) 
			y += 11;
	}
	
	void DrawImageToBox(TextureID tex, int x, int y, int w, int h, double trans = 0.75, bool animate = false)	{
		double scale1, scale2;
		if (!tex)
			return;
		let texsize = TexMan.GetScaledSize(tex);
		scale1 = w / texsize.X;
		scale2 = h / texsize.Y;

		/*if (w < texsize.X) scale1 = w / texsize.X;
		else scale1 = 1.;
		if (h < texsize.Y) scale2 = h / texsize.Y;
		else scale2 = 1.;
		scale1 = min(scale1, scale2);
		if (scale2 < scale1) scale1=scale2;*/

		x += w >> 1;
		y += h;

		w = (int)(texsize.X * scale1);
		h = (int)(texsize.Y * scale1);

		screen.DrawTexture(tex, animate, x, y,
			DTA_KeepRatio, true,
			DTA_VirtualWidth, 1920, DTA_VirtualHeight, 1080, DTA_Alpha, trans, 
			DTA_DestWidth, w, DTA_DestHeight, h, DTA_CenterBottomOffset, 1);
	}
}