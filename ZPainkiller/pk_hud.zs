Class PainkillerHUD : BaseStatusBar {
	HUDFont mIndexFont;
	HUDFont mStatFont;
	
	private int arrowangle;
	private int checktic;
	
	override void Init() {
		super.Init();
		Font fnt = "PKHNUMS";
		mIndexFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
		mStatFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true,1 ,1);
	}
	
	override void Draw (int state, double TicFrac) {
		Super.Draw (state, TicFrac);
		if (CPlayer.mo.FindInventory("PK_DemonWeapon") || automapactive)
			return;
		BeginHUD(forcescaled:true);
		DrawVisualElements();
		DrawNumbers();
		fullscreenOffsets = true;
	}
	
	override void Tick() {
		let player = CPlayer.mo;
		if (!player)
			return;
		let event = PK_DeathHandler(EventHandler.Find("PK_DeathHandler"));
		if (!event)
			return;		
		int enemies = event.allenemies.size();
		if (enemies < 1)
			return;
		actor closestact;
		double closestDist = double.infinity;
		/*checktic++;
		if (checktic > 10 || checktic < 1)
			checktic = 1;
		int segmentstart = enemies / 10 * Clamp(checktic,1,9);
		int segmentend = enemies / 10 * Clamp(checktic+1,1,10);
		for (int i = segmentstart; i < segmentstart; i++) {		*/
		for (int i = 0; i < enemies; i++) {
			let act = event.allenemies[i];
			if (!act)
				return;
			int dist = player.Distance2DSquared(act);
			if (closestDist > 0 && dist < closestDist) {
				closestact = act;
				closestDist = dist;
			}
		}
		if (closestact) {
			arrowangle = -(Actor.DeltaAngle(player.angle, player.AngleTo(closestact)));
			//console.printf("%s angle %d",closestact.GetClassName(),arrowangle);
		}
	}
	
	protected void DrawVisualElements() {
		DrawImage("pkxleft",(0,0),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_LEFT_BOTTOM);
		DrawImage("pkxright",(0,0),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM);	
		
		DrawImage("pkhlife",(11,-23),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER ,0.8);
		DrawImage("pkharm0",(11,-11),DI_SCREEN_LEFT_BOTTOM|DI_ITEM_CENTER ,0.8);
		
		DrawImage("pkhkills",(-31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		DrawImage("pkhsouls",(31,11),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_CENTER);
		
		DrawImage("pkxtop0",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,92),rotation:arrowangle,scale:(2,2),tint:color(256,0,0,0));	//dark outline
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(966,105),rotation:arrowangle,scale:(2,2),alpha:0.45,tint:color(256,48,0,0)); //arrow
		PK_StatusBarScreen.DrawRotatedImage("pkxarrow",(960,92),rotation:arrowangle,scale:(1.6,1.6));	//arrow shadow
		
		DrawImage("pkxtop1",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP);	//main top
		DrawImage("pkxtop2",(0,0),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_ITEM_TOP,alpha:0.9);	//glass
	}
	
	protected void DrawNumbers() {
		DrawString(mIndexFont, String.Format("%03d",CPlayer.health), (19, -28),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		DrawString(mIndexFont, String.Format("%03d",GetArmorAmount()), (19, -16),DI_SCREEN_LEFT_BOTTOM,translation:font.CR_UNTRANSLATED);
		
		DrawString(mStatFont, String.Format("%05d",multiplayer? CPlayer.killcount : level.killed_monsters), (-38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_RIGHT,translation:font.CR_UNTRANSLATED);
		
		let control = PK_DemonMorphControl(CPlayer.mo.FindInventory("PK_DemonMorphControl"));
		if (control) {
			int souls = control.pk_souls;
			int soulsColor = (souls >= 64) ? Font.CR_RED : Font.CR_UNTRANSLATED;			
			DrawString(mStatFont, String.Format("%05d",souls), (38, 6),DI_SCREEN_TOP|DI_SCREEN_HCENTER|DI_TEXT_ALIGN_LEFT,translation:soulsColor);
		}
		
		let weap = CPlayer.readyweapon;
		if (weap && weap.GetClassName() == "PK_Painkiller") {
			DrawImage("pkhpkill",(-13,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhblade",(-13,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhinfin",(-30,-11),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
			DrawImage("pkhinfin",(-30,-23),DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_CENTER);
		}
		
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

	int GetAmmoColor(Inventory ammoclass) {		
		int ammoColor;
		if	(ammoclass.amount > ammoclass.default.maxamount * 0.25) 
			ammoColor = FONT.CR_UNTRANSLATED;
		else
			ammoColor = FONT.CR_RED;			
		return ammoColor;
	}
}