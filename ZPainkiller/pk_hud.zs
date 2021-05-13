Class PainkillerHUD : BaseStatusBar {
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
	
	PK_CardControl cardcontrol;
	
	
	override void Init() {
		super.Init();
		Font fnt = "PKHNUMS";
		mIndexFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
		mStatFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
	}
	
	override void Draw (int state, double TicFrac) {
		Super.Draw (state, TicFrac);
		hudstate = state;
		//the hud is completely skipped if automap is active or the player is in a demon mode
		if (state == HUD_none || automapactive || isDemon)
			return;
		BeginHUD(forcescaled:true);
		//DrawVisualElements();
		//DrawNumbers();
		if (state == HUD_Fullscreen || state == HUD_AltHud)
			DrawTopElements();
		if (state == HUD_StatusBar || state == HUD_Fullscreen)
			DrawBottomElements();
		//DrawEquippedCards();
		DrawActiveGoldenCards();
		fullscreenOffsets = true;
	}
	
	override void Tick() {
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
		let dmcont = PK_DemonMorphControl(CPlayer.mo.FindInventory("PK_DemonMorphControl"));
		if (dmcont) {
			soulsnum = dmcont.pk_souls;
			//make souls number red if it's only 3 souls before turning into demon:
			soulscol = (soulsnum >= dmcont.pk_minsouls) ? Font.CR_RED : Font.CR_UNTRANSLATED;
		}
		if (hudstate == HUD_None)
			return;
		
		//get access to the array of all enemies from PK_Mainhandler:
		if (!mainhandler)
			mainhandler = PK_Mainhandler(EventHandler.Find("PK_Mainhandler"));
		if (!mainhandler)
			return;		
		int enemies = mainhandler.allenemies.size();
		if (enemies < 1)
			return;
		//check 2D distance to every monster in the array and find the closest one:
		actor closestact;
		double closestDist = double.infinity;
		for (int i = 0; i < enemies; i++) {
			let act = mainhandler.allenemies[i];
			if (!act)
				return;
			int dist = player.Distance2DSquared(act);
			if (closestDist > 0 && dist < closestDist) {
				closestact = act;
				closestDist = dist;
			}
		}
		//define the angle for the monster compass arrow based on the relative position of the monster:
		if (closestact) {
			arrowangle = -(Actor.DeltaAngle(player.angle, player.AngleTo(closestact)));
			//console.printf("%s angle %d",closestact.GetClassName(),arrowangle);
		}
	}
	
	//show 3 active golden cards at the lower center of the screen
	protected void DrawActiveGoldenCards() {
		if (!cardcontrol || (!cardcontrol.goldActive && cardcontrol.GetDryUseTimer() == 0))
			return;			
		for (int i = 2; i < 5; i++) {
			if (cardcontrol.EquippedSlots[i]) {
				string texpath = String.Format("graphics/Tarot/cards/%s.png",cardcontrol.EquippedSlots[i]);
				DrawImage(texpath,((-77 + i*22),195),DI_SCREEN_HCENTER|DI_ITEM_LEFT_TOP,scale:(0.14,0.14));
				//if out of uses, draw a red overlay atop the cards
				if (cardcontrol.GetDryUseTimer() > 0)
					DrawImage("graphics/Tarot/cards/UsedCard.png",((-77 + i*22),195),DI_SCREEN_HCENTER|DI_ITEM_LEFT_TOP,alpha:0.75,scale:(0.14,0.14));
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
				DrawImage(texpath,((4 + i*18),2),DI_SCREEN_LEFT_TOP|DI_ITEM_LEFT_TOP,scale:(0.12,0.12));
			}
			string framepath;
			if (i < 2)
				framepath = "graphics/Tarot/cards/FrameSilver.png";
			else
				framepath = "graphics/Tarot/cards/FrameGold.png";
			DrawImage(framepath,((4 + i*18),2),DI_SCREEN_LEFT_TOP|DI_ITEM_LEFT_TOP,scale:(0.12,0.12));
		}
	}
	
	//draw all bottom elements (health/armor/ammo)
	protected void DrawBottomElements() {
		//draw bottom corners:
		DrawImage("pkxleft",(0,0),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_LEFT_BOTTOM);
		DrawImage("pkxright",(0,0),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM);	
		
		//draw health and armor icons:
		DrawImage("pkhlife",(11,-23),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER ,0.8);
		
		//draw armor icon:
		let armor = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		if (armor && armor.amount > 0) {
			//this is for cheaters: if "give all" was used, forcefully display gold armor icon, otherwise gzdoom will display BlueArmor icon			
			if (armor.amount >= 200 && armor.ArmorType != "PK_BronzeArmor" && armor.ArmorType != "PK_SilverArmor" && armor.ArmorType != "PK_GoldArmor")
				DrawImage("pkharm3",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER,0.8);
			else
				DrawInventoryIcon(armor, (11, -11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
		}
		else
			DrawImage("pkharm0",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER,0.8);
		
		//draw health and armor amounts:
		DrawString(mIndexFont, String.Format("%03d",CPlayer.health), (19, -28),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		DrawString(mIndexFont, String.Format("%03d",GetArmorAmount()), (19, -16),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		
		//if using statusbar, we don't draw the top bar at all and we draw souls/gold counters as well as compass at the bottom:
		if (hudstate == HUD_StatusBar) {		
			//draw compass at bottom center
			DrawImage("pkxtop0",(0,4),DI_SCREEN_BOTTOM|DI_SCREEN_HCENTER|DI_ITEM_BOTTOM);
			//draw arrow and outline (shadow and glass are skipped in this version for simplicity)
			PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,988),rotation:arrowangle,scale:(1.8,1.8),tint:color(256,0,0,0));	//dark arrow outline
			PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,988),rotation:arrowangle,scale:(1.4,1.4));	//arrow		
		
			//gold counter above health:
			DrawImage("pkhgold",(5,-38),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER);
			DrawString(mStatFont, String.Format("%05d",goldnum), (10, -43),DI_SCREEN_LEFT_BOTTOM|DI_TEXT_ALIGN_LEFT,translation:font.CR_UNTRANSLATED);			
			//souls counter above ammo:
			DrawImage("pkhsouls",(-5,-38),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawString(mStatFont, String.Format("%05d",soulsnum), (-10,-43),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:soulscol);
		}		
		
		//AMMO
		let weap = CPlayer.readyweapon;
		//if Painkiller is selected, explicitly draw painkiller blade/projectile icons and an infinity symbol next to them:
		if (weap && weap.GetClassName() == "PK_Painkiller") {
			DrawImage("pkhpkill",(-13,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhblade",(-13,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhinfin",(-30,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhinfin",(-30,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			return; //and do nothing else
		}
		//otherwise draw the proper ammo
		Inventory ammotype1, ammotype2;
		[ammotype1, ammotype2] = GetCurrentAmmo();
		if (ammotype1) {
			DrawInventoryIcon(ammotype1, (-11,-22),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawString(mIndexFont, String.Format("%03d",ammotype1.amount),(-19,-27),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:GetAmmoColor(ammotype1));
		}
		if (ammotype2) {
			DrawInventoryIcon(ammotype2, (-11,-10),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawString(mIndexFont, String.Format("%03d",ammotype2.amount),(-19,-15),DI_SCREEN_RIGHT_BOTTOM|DI_TEXT_ALIGN_RIGHT,translation:GetAmmoColor(ammotype2));
		}
	}
	//top bar, compass, and souls and gold counters:
	protected void DrawTopElements() {
		//draw the compass background:
		DrawImage("pkxtop0",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);
		//draw the compass arrow (in 3 layers):
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,92),rotation:arrowangle,scale:(2,2),tint:color(256,0,0,0));	//dark arrow outline
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(966,105),rotation:arrowangle,scale:(2,2),alpha:0.45,tint:color(256,48,0,0)); //arrow shadow
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,92),rotation:arrowangle,scale:(1.6,1.6));	//arrow
		
		//draw the top bar and the compass outline:
		DrawImage("pkxtop1",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);	//main top
		DrawImage("pkxtop2",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP,alpha:0.4);	//glass
		//draw souls and gold on the top bar:
		DrawImage("pkhgold",(-31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		DrawImage("pkhsouls",(31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		//draw souls and gold values on the top bar:
		DrawString(mStatFont, String.Format("%05d",goldnum), (-38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_RIGHT,translation:font.CR_UNTRANSLATED);			
		DrawString(mStatFont, String.Format("%05d",soulsnum), (38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_LEFT,translation:soulscol);
	}

	int GetAmmoColor(Inventory ammoclass) {		
		int ammoColor;
		if	(ammoclass.amount > ammoclass.default.maxamount * 0.25) 
			ammoColor = FONT.CR_UNTRANSLATED;
		else
			ammoColor = FONT.CR_RED;			
		return ammoColor;
	}
}