Class PKCardsMenu : PKCGenericMenu {
	const BOARD_WIDTH = 1024;
	const BOARD_HEIGHT = 768;
	const MENUTEXTSCALE = 1;
	double backgroundRatio;
	vector2 boardTopLeft;
	
	PlayerPawn plr;
	PK_GoldControl goldcontrol;
	
	PK_BoardEventHandler menuEHandler;
	PK_BoardElementsHandler elementsEHandler;
	
	array <PKCTarotCard> silvercards;	//all silver cards
	array <PKCTarotCard> goldcards;		//all gold cards
	
	PKCMenuHandler handler;
	PKCTarotCard SelectedCard;	//card attached to the pointer
	PKCTarotCard HoveredCard;	//card the pointer is hovering over
	
	PKCFrame silverSlotsInfo;
	PKCFrame goldSlotsInfo;
	
	PKCFrame boardElements;		//everything in the board except the background and popups
	PKCBoardMessage cardinfo;		//card information popup
	PKCBoardMessage promptPopup;	//an exit or purchase popup that blocks the board
	PKCBoardMessage firstUsePopup;	//first use notification
	int firstUsePopupDur;				//first use notification display duration
	
	PKCButton exitbutton;			//big round flashing menu close button
	bool ExitHovered;				//whether it's hovered
	int ExitAlphaDir;
	
	bool firstUse;
	
	override void Init (Menu parent) {
		super.Init(parent);
		
		/*vector2 screensize = (Screen.GetWidth(),screen.GetHeight());		
		SetBaseResolution(screensize);
		backgroundRatio = screensize.y / BOARD_HEIGHT;
		vector2 backgroundsize = (BOARD_WIDTH*backgroundRatio,BOARD_HEIGHT*backgroundRatio);
		boardTopLeft = */
		
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//checks if the board is opened for the first time on the current map:
		let plr = players[consoleplayer].mo;
		menuEHandler = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (menuEHandler) {
			if (!menuEHandler.boardOpened) {
				firstUse = true;
				menuEHandler.boardOpened = true;
			}
			else
				firstUse = false;
		}		
		elementsEHandler = PK_BoardElementsHandler(StaticEventHandler.Find("PK_BoardElementsHandler"));
		goldcontrol = PK_GoldControl(players[consoleplayer].mo.FindInventory("PK_GoldControl"));
		
		//first create the background (always 4:3, never stretched)
		vector2 backgroundsize = (BOARD_WIDTH,BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);
		let background = new("PKCImage");
		background.Init(
			(0,0),
			backgroundsize,
			image:"graphics/Tarot/cardsboard.png"/*,
			imagescale:(1*backgroundRatio,1*backgroundRatio)*/
		);
		background.Pack(mainFrame);
		
		//define the frame that will keep everything except text popups:
		boardelements = new("PKCFrame").Init((0,0),backgroundsize);
		boardelements.pack(mainFrame);

		handler = new("PKCMenuHandler");
		handler.menu = self;
		handler.elementsEHandler = PK_BoardElementsHandler(StaticEventHandler.Find("PK_BoardElementsHandler"));
		
		//clicking anywhere on the board is supposed to close the First Use popup:
		let closeFirstUseBtn = new("PKCButton").Init(
			(0,0),
			backgroundsize,
			cmdhandler:handler,
			command:"CloseFirstUse"
		);
		closeFirstUseBtn.SetTexture( "", "", "", "" );
		closeFirstUseBtn.Pack(boardElements);
		
		//create big round exit button:
		exitbutton = new("PKCButton").Init(
			(511,196),
			(173,132),
			cmdhandler:handler,
			command:"BoardButton"
		);
		exitbutton.SetTexture(
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png"
		);
		exitbutton.Pack(boardelements);

		SlotsInit();	//initialize card slots
		CardsInit();	//initialize cards
		SlotInfoInit();
		
		let goldcounter = PKCGoldCounter(new("PKCGoldCounter"));
		goldcounter.Pack(boardElements);
		goldcounter.Init(
			(728,237),
			(170,50)
		);		
	}
	
	private void SlotInfoInit() {
		double bkgalpha = 0.7;
		vector2 silverSlotSize = (280,80);
		silverSlotsInfo = new("PKCFrame").Init((75,255),silverSlotSize);
		silverSlotsInfo.Pack(boardElements);
		let silverSlotBkg = new("PKCImage").Init(
			(0,0),
			silverSlotSize,
			"graphics/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		silverSlotBkg.alpha = bkgalpha;
		silverSlotBkg.Pack(silverSlotsInfo);
		let silverSlotText = new("PKCLabel").Init(
			(5,5),
			(270,70),
			Stringtable.Localize("$TAROT_SILVERINFO"),
			font_times,
			alignment: PKCElement.AlignType_HCenter,
			textscale:MENUTEXTSCALE*0.9,
			textcolor: Font.FindFontColor('PKWhiteText'),
			linespacing: 0.1
		);
		silverSlotText.Pack(silverSlotsInfo);
		silverSlotsInfo.hidden = true;

		vector2 goldSlotSize = (360,80);
		goldSlotsInfo = new("PKCFrame").Init((560,440),goldSlotSize);
		goldSlotsInfo.Pack(boardElements);
		let goldSlotBkg = new("PKCImage").Init(
			(0,0),
			goldSlotSize,
			"graphics/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		goldSlotBkg.alpha = bkgalpha;
		goldSlotBkg.Pack(goldSlotsInfo);
		let goldSlotText = new("PKCLabel").Init(
			(5,5),
			(350,70),
			Stringtable.Localize("$TAROT_GOLDINFO"),
			font_times,
			alignment: PKCElement.AlignType_HCenter,
			textscale:MENUTEXTSCALE*0.9,
			textcolor: Font.FindFontColor('PKWhiteText'),
			linespacing: 0.1
		);
		goldSlotText.Pack(goldSlotsInfo);
		goldSlotsInfo.hidden = true;
	}
	
	//horizontal positions of slots
	static const int PKCSlotXPos[] = { 58, 231, 489, 660, 829 };
	//array of slots; filled on slots' initialization
	array <PKCCardSlot> cardslots;
	
	private void SlotsInit() {
		vector2 slotsize = (138,227);	
		for (int i = 0; i <= 4; i++) {			
			double slotY = (i < 2) ? 179 : 364;
			vector2 slotpos = (PKCSlotXPos[i],slotY);
			let cardslot = PKCCardSlot(new("PKCCardSlot"));
			cardslot.Init(
				slotpos,
				slotsize,
				cmdhandler:handler,
				command:"CardSlot"
			);
			cardslot.SetTexture("","","","");
			cardslot.slotpos = slotpos;
			cardslot.slotsize = slotsize;
			cardslot.slottype = (i < 2) ? false : true;
			cardslot.slotID = i;
			cardslots.insert(i,cardslot);
			cardslot.Pack(boardelements);
		}
	}
	//LANGUAGE references containing card names:
	static const string PKCCardNames[] = {
		//silver
		"$SOULKEEPER_NAME"	,	"$BLESSING_NAME"		,	"$REPLENISH_NAME"		,
		"$DARKSOUL_NAME"		,	"$SOULCATCHER_NAME"	,	"$FORGIVENESS_NAME"	,
		"$GREED_NAME"			,	"$SOULREDEEMER_NAME"	,	"$REGENERATION_NAME"	,
		"$HEALTHSTEALER_NAME"	,	"$HELLISHARMOR_NAME"	,	"$666AMMO_NAME"		,
		//gold
		"$ENDURANCE_NAME"		,	"$TIMEBONUS_NAME"		,	"$SPEED_NAME"			,
		"$REBIRTH_NAME"		,	"$CONFUSION_NAME"		,	"$DEXTERITY_NAME"		,
		"$WMODIFIER_NAME"		,	"$SOT_NAME"			,	"$RAGE_NAME"			,
		"$MAGICGUN_NAME"		,	"$IRONWILL_NAME"		,	"$HASTE_NAME"
	};
	//LANGUAGE references containing card descriptions:
	static const string PKCCardDescs[] = {
		//silver
		"$SOULKEEPER_DESC"	,	"$BLESSING_DESC"		,	"$REPLENISH_DESC"		,
		"$DARKSOUL_DESC"		,	"$SOULCATCHER_DESC"	,	"$FORGIVENESS_DESC"	,
		"$GREED_DESC"			,	"$SOULREDEEMER_DESC"	,	"$REGENERATION_DESC"	,
		"$HEALTHSTEALER_DESC"	,	"$HELLISHARMOR_DESC"	,	"$666AMMO_DESC"		,
		//gold
		"$ENDURANCE_DESC"		,	"$TIMEBONUS_DESC"		,	"$SPEED_DESC"			,
		"$REBIRTH_DESC"		,	"$CONFUSION_DESC"		,	"$DEXTERITY_DESC"		,
		"$WMODIFIER_DESC"		,	"$SOT_DESC"			,	"$RAGE_DESC"			,
		"$MAGICGUN_DESC"		,	"$IRONWILL_DESC"		,	"$HASTE_DESC"
	};
	//this is a generic ID also used to find the texture name:
	static const name PKCCardIDs[] = {
		//silver
		"SoulKeeper"			,	"Blessing"				,	"Replenish"			,
		"DarkSoul"				,	"SoulCatcher"			,	"Forgiveness"			,
		"Greed"				,	"SoulRedeemer"			,	"HealthRegeneration"	,
		"HealthStealer"		,	"HellishArmor"			,	"666Ammo"				,
		//gold
		"Endurance"			,	"TimeBonus"			,	"Speed"				,
		"Rebirth"				,	"Confusion"			,	"Dexterity"			,
		"WeaponModifier"		,	"StepsOfThunder"		,	"Rage"					,
		"MagicGun"				,	"IronWill"				,	"Haste"
	};
	static const int PKCCardCosts[] = {
		//silver
		500,	500,	700,	700,
		800,	800,	1000,	1000,
		1200,	1200,	1500,	1500,
		//gold
		500,	500,	700,	700,
		800,	800,	1000,	1000,
		1200,	1200,	1500,	1500
	};
	
	//I have to define slots' X pos manually because the gaps between them are not precisely identical:
	static const int PKCCardXPos[] = { 56, 135, 214, 291, 370, 447, 525, 604, 682, 759, 835, 913 };
	
	//Initialize cards:
	private void CardsInit() {				
		vector2 cardsize = (55,92);
		vector2 cardscale = (0.4,0.407); //slightly stretched vertically to fill the slot
		for (int i = 0; i < PKCCardIDs.Size(); i++) {
			//first 12 cards are silver, so we define pos based on where we are in the IDs array:
			vector2 cardpos = (i < 12) ? (PKCCardXPos[i],56) : (PKCCardXPos[i-12],618);
			let card = PKCTarotCard(new("PKCTarotCard"));
			card.Init(
				cardpos,
				cardsize,
				cmdhandler:handler,
				command:"HandleCard"
			);
			string texpath = String.Format("graphics/Tarot/cards/%s.png",PKCCardIDs[i]);
			card.SetTexture(texpath, texpath, texpath, texpath);
			card.menu = PKCardsMenu(self);
			card.buttonScale = cardscale;
			card.defaultscale = cardscale;
			card.defaultpos = cardpos;
			card.defaultsize = cardsize;
			card.cardname = PKCCardNames[i];
			card.carddesc = PKCCardDescs[i];
			card.cardID = PKCCardIDs[i];	
			card.cardCost = PKCCardCosts[i];
			if (i < 12) {
				card.slottype = false;
				silvercards.push(card);
			}
			else {
				card.slottype = true;
				goldcards.push(card);
			}
			card.Pack(boardelements);

			if (elementsEHandler) {
				//check if the card is already unlocked:
				if (elementsEHandler.UnlockedTarotCards.Find(int(name(card.cardID))) != elementsEHandler.UnlockedTarotCards.Size()) {
					//console.printf("%s is bought",card.cardID);
					card.cardbought = true;
				}
				//check if the card is already equipped, and if so, place it in that slot:
				if (elementsEHandler.EquippedSlots.Size() > 0 && elementsEHandler.EquippedSlots.Size() <= cardslots.Size()) {
					for (int i = 0; i < cardslots.Size(); i++) {
						if (elementsEHandler.EquippedSlots[i] == card.cardID) {
							let cardslot = cardslots[i];
							card.box.pos = cardslot.slotpos;
							card.box.size = cardslot.slotsize;
							card.buttonscale = (1,1);
							cardslot.placedcard = card;
						}
					}
				}
			}
			
		}
		//unlock 2 random silver and 3 random gold crads if you have none unlocked ("pistol start"):	
		if (elementsEHandler && elementsEHandler.UnlockedTarotCards.Size() == 0) {
			//S_StartSound("ui/board/cardunlocked",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			S_StartSound("ui/board/cardburn",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			//console.printf("fist unlock");
			
			string firstUseLine = Stringtable.Localize("$TAROT_FIRSTUSE");
			//show "first use" text popup (doesn't block the board):
			firstUsePopup = New("PKCBoardMessage");
			firstUsePopup.pack(mainFrame);
			firstUsePopup.Init(
				(192,256),
				(700,128),
				firstUseLine,
				textscale:MENUTEXTSCALE* 1.5
			);
			firstUsePopupDur = 120;	//"first use" message is temporary
			
			//these arrays are used to make sure we don't unlock the same card more than once:
			array <PKCTarotCard> UnlockedGoldCards;
			array <PKCTarotCard> UnlockedSilverCards;
			
			//unlock the cards and push them into an array on the item token via a netevent:
			while (UnlockedSilverCards.Size() < 2) {
				let card = PKCTarotCard(silvercards[random(0,silvercards.Size()-4)]);
				if (UnlockedSilverCards.Find(card) == UnlockedSilverCards.Size()) {
					card.cardbought = true;
					card.purchaseAnim = true;
					UnlockedSilverCards.push(card);					
					elementsEHandler.UnlockedTarotCards.push(int(name(card.cardID)));
					//string eventname = String.Format("PKCUnlockCard:%s",card.cardID);
					//EventHandler.SendNetworkEvent(eventname);
				}
			}
			while (UnlockedGoldCards.Size() < 3) {
				let card = PKCTarotCard(goldcards[random(0,goldcards.Size()-4)]);
				if (UnlockedGoldCards.Find(card) == UnlockedGoldCards.Size()) {
					card.cardbought = true;
					card.purchaseAnim = true;
					UnlockedGoldCards.push(card);
					elementsEHandler.UnlockedTarotCards.push(int(name(card.cardID)));
					//string eventname = String.Format("PKCUnlockCard:%s",card.cardID);
					//EventHandler.SendNetworkEvent(eventname);
				}
			}
		}
	}

	//shows exit popup message
	void ShowExitPopup() {
		if (!boardElements)
			return;
				
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);


		promptPopup = New("PKCBoardMessage");
		promptPopup.pack(mainFrame);
		promptPopup.Init(
			popuppos,
			popupsize,
			Stringtable.Localize("$TAROT_EXIT"),
			textscale:MENUTEXTSCALE* 1,
			alignment: PKCElement.AlignType_HCenter
		);
		
		let promptHandler = PKCPromptHandler(new("PKCPromptHandler"));
		promptHandler.menu = self;		
		
		//create Yes button:
		vector2 buttonsize = (100,60);
		let yesButton = new("PKCButton").Init(
			(100,160),
			buttonsize,
			text:"Yes",
			cmdhandler:promptHandler,
			command:"DoExit",
			fnt:font_times,
			textscale:MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		yesButton.SetTexture("","","","");
		yesButton.pack(promptPopup);
		
		//create No button:
		let noButton = new("PKCButton").Init(
			(440,160),
			buttonsize,
			text:"No",
			cmdhandler:promptHandler,
			command:"CancelPrompt",
			fnt:font_times,
			textscale:MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		noButton.SetTexture("","","","");
		noButton.pack(promptPopup);
	}

	void ShowPurchasePopup(PKCTarotCard card) {
		if (!boardElements || !card)
			return;
				
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);
		
		promptPopup = New("PKCBoardMessage");
		promptPopup.pack(mainFrame);
		promptPopup.Init(
			popuppos,
			popupsize,
			card.cardname,
			textscale:MENUTEXTSCALE* 1.4,
			alignment: PKCElement.AlignType_HCenter
		);
		
		int gold;
		if (goldcontrol)
			gold = goldcontrol.pk_gold;
		
		string purchaseLine = (gold >= card.cardcost) ? Stringtable.Localize("$TAROT_PURCHASE") : Stringtable.Localize("$TAROT_CANTPURCHASE");
		vector2 purchaseTextofs = (16,16);	
		let purchaseText = new("PKCLabel").Init(
			purchaseTextofs+(0,64),
			popupsize-(purchaseTextofs*1.2),
			String.Format(purchaseLine,card.cardCost), 
			font_times,
			alignment: PKCElement.AlignType_HCenter,
			textscale:MENUTEXTSCALE*1,
			textcolor: Font.FindFontColor('PKBaseText'),
			linespacing: 0.1
		);
		purchaseText.Pack(promptPopup);			
		
		let promptHandler = PKCPromptHandler(new("PKCPromptHandler"));
		promptHandler.menu = self;		
		promptHandler.card = card;
		
		vector2 buttonsize = (100,60);
		
		if (gold >= card.cardcost) {		
			//create Yes button:
			let yesButton = new("PKCButton");
			yesButton.pack(promptPopup);
			yesButton.Init(
				(100,160),
				buttonsize,
				text:"Yes",
				cmdhandler:promptHandler,
				command:"BuyCard",
				fnt:font_times,
				textscale:MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			yesButton.SetTexture("","","","");		
			
		
			//create No button:
			let noButton = new("PKCButton");
			noButton.pack(promptPopup);
			noButton.Init(
				(440,160),
				buttonsize,
				text:"No",
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			noButton.SetTexture("","","","");
		}
		
		else {		
			//create Close button:
			let okButton = new("PKCButton");
			okButton.pack(promptPopup);
			okButton.Init(
				(265,160),
				buttonsize,
				text:"Close",
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			okButton.SetTexture("","","","");	
		}			
	}
	
	void ShowCardToolTip(PKCTarotCard card) {
		if (!card)
			return;
		vector2 tippos = (62,430);
		vector2 tipsize = (378,173);

		string title = Stringtable.Localize(card.cardname);	//pulls name from LANGUAGE
		string desc = Stringtable.Localize(card.carddesc);	//pulls desc from LANGUAGE
		
		cardinfo = New("PKCBoardMessage");
		cardinfo.pack(mainFrame);
		cardinfo.Init(
			tippos,
			tipsize,
			String.Format("%s",title),
			textscale:MENUTEXTSCALE*1.2,
			textcolor: Font.FindFontColor('PKRedText')
		);
		
		vector2 tiptextofs = (16,16);	
		let tiptext = new("PKCLabel").Init(
			tiptextofs+(0,48),
			tipsize-(tiptextofs*1.2),
			String.Format("%s",desc), 
			font_times,
			textscale:MENUTEXTSCALE*1,
			textcolor: Font.FindFontColor('PKBaseText'),
			linespacing: 0.1
		);
		tiptext.Pack(cardinfo);	
		
		if (card.cardbought)
			return;
			
		let cardcostt = new("PKCLabel").Init(
			tiptextofs+(185,0),
			(160,64),
			String.Format("%dg",card.cardcost), 
			font_times,
			alignment:PKCElement.AlignType_TopRight,
			textscale:1,
			textcolor: Font.FindFontColor('PKGreenText'),
			linespacing: 0.1
		);
		cardcostt.Pack(cardinfo);	
	}

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (mkey == MKEY_Back) {
			//if used for the first time, don't close immediately
			if  (firstUse) {
				//if first use prompt is active, hitting Esc will close the popup, not the menu:
				if (firstUsePopup) {
					S_StartSound("ui/menu/open",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					firstUsePopup.Unpack();
					firstUsePopup.destroy();
					return false;
				}			
				//if exit prompt is active, hitting Esc will close the popup, not the menu:
				if (promptPopup && promptPopup.isEnabled()) {
					S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					promptPopup.hidden = true;
					promptPopup.disabled = true;
				}
				//otherwise draw a Yes/No exit prompt:
				else
					ShowExitPopup();
				return false;
			}
			//if not first use, just close the board with the right sound
			else {
				S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				Close();
				return true;
			}
		}
		return false;
    }
	
	override void Ticker() {
		if (promptPopup && promptPopup.isEnabled()) {
			boardElements.disabled = true;
		}
		else {
			boardElements.disabled = false;
		}
		
		if (promptPopup && !promptPopup.isEnabled()) {
			promptPopup.Unpack();
			promptPopup.Destroy();
		}
		
		//if the first use popup appears, start a counter and remove it when it runs out:
		if (firstUsePopup) {
			firstUsePopupDur--;			
			if (firstUsePopupDur <= 0) {
				firstUsePopup.Unpack();
				firstUsePopup.Destroy();
			}
		}
		
		//if the player  picked a card from a slot, attach it to the mouse pointer:
		if (SelectedCard) {			
			SelectedCard.box.pos = boardelements.screenToRel((mouseX,mouseY)) - SelectedCard.box.size / 2;
		}
		//show card info if mouse hovers over a card and there's no card selected:
		if (!cardinfo && HoveredCard && HoveredCard.isEnabled() && !HoveredCard.hidden && !SelectedCard)
			ShowCardToolTip(HoveredCard);
		//as soon as you hover off the card, immediately remove card info:
		if (cardinfo && (!HoveredCard || !HoveredCard.isEnabled() || HoveredCard.hidden || SelectedCard)) {
			cardinfo.unpack();
			cardinfo.destroy();
		}
		//exit button continuously flashes, like in original:
		if (exitbutton) {
			if (exitbutton.alpha <= 0.25)
				ExitAlphaDir = 1;
			else if (exitbutton.alpha >= 1)
				ExitAlphaDir = -1;
			exitbutton.alpha = (exitbutton.isHovered && !SelectedCard) ? 1.0 : Clamp(exitbutton.alpha+0.05*ExitAlphaDir,0.25,1.0);
		}
		super.Ticker();
	}
}

/* 
	A generalized Board message frame that includes a lighter outline,
	a darker inner image, and a slot for text. Use by popups.
*/
Class PKCBoardMessage : PKCFrame {
	private int dur;
	PKCBoardMessage init (vector2 msgpos, vector2 msgsize, string msgtext = "", double TextScale = 1.0, int TextColor = 0,  AlignType alignment = AlignType_TopLeft) {
		self.setBox(msgpos, msgsize);
		self.alpha = 1;
	
		let outline = new("PKCImage");
		outline.Pack(self);
		outline.Init(
			(0,0),
			msgsize,
			"graphics/Tarot/tooltip_bg_outline.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
				
		vector2 intofs = (4,4);
		let bkg = new("PKCImage");
		bkg.Pack(self);
		bkg.Init(
			intofs,
			msgsize-(intofs*2),
			"graphics/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		
		if (msgtext == "")
			return self;
		
		if (textColor == 0)
			textcolor = Font.FindFontColor('PKWhiteText');
		
		vector2 msgTextOfs = intofs+(12,12);
		let msgPrompt = new("PKCLabel");
		msgPrompt.Pack(self);
		msgPrompt.Init(
			msgTextOfs,
			msgsize-(msgTextOfs*2),
			msgtext,
			font_times,
			alignment: alignment,
			textscale: TextScale,
			textcolor: TextColor
		);
		
		return self;
	}
}

Class PKCGoldCounter : PKCFrame {
	PK_GoldControl goldcontrol;	//this item holds the amount of gold
	PKCImage GoldDigits[6]; //there's a total of 6 digits
	vector2 DigitPos[6];
	//digits are not spaced totally evently, so we define their X pos explicitly:
	static const int PKCGoldDigitXPos[] = { -3, 24, 53, 82, 111, 141 };
	int PKCGoldDigitYPos[6];
	
	DynamicValueInterpolator GoldInterpolator[6];
	
	PKCGoldCounter init(Vector2 pos, Vector2 size) {
		self.setBox(pos, size);
		self.alpha = 1;
		
		//the leftmost digit of the counter is always 0 since there are 6 digits but max gold is 99990, so we just draw it here and don't modify it further:
		vector2 digitsize = (27,50);
		let img = new("PKCImage");
		img.pack(self);
		img.Init(
			(-3,-5),
			digitsize,
			"PKCNUMS"
		);
		DigitPos[0] = img.box.pos;
		GoldDigits[0] = img;
		
		for (int i = 5; i > 0; i--) {
			GoldInterpolator[i] = DynamicValueInterpolator.Create(0,0.1,4,64);
		}
		
		//cast the gold item
		goldcontrol = PK_GoldControl(players[consoleplayer].mo.FindInventory("PK_GoldControl"));

		return self;
	}
	
	override void ticker() {
		super.ticker();
		if (!goldcontrol)
			return;		
		int gold = goldcontrol.pk_gold; //check how much gold we have
		vector2 digitsize = (32,640);	//digit size is fixed
		//iterate through digits, right to left:
		//we don't modify the leftmost one, so it's > 0, not >= 0:
		for (int i = 5; i > 0; i--) {
			//get Y offset based on the rightmost digit in the gold amount number:
			int digitYofs = ((gold % 10) * -64) - 5;
			//check if this Y offset is not equal to previously recorded value
			if (PKCGoldDigitYPos[i] != digitYofs) {			
				S_StartSound("ui/board/digitchange",CHAN_VOICE,CHANF_UI|CHANF_NOSTOP,volume:snd_menuvolume);
				//if so, reset interpolator
				GoldInterpolator[i].Reset(PKCGoldDigitYPos[i]);
				//and set the calculated value as target Y pos
				PKCGoldDigitYPos[i] = digitYofs;
			}
			else //otherwise update the interpolator
				GoldInterpolator[i].Update(digitYofs);
			int newY = GoldInterpolator[i].GetValue();			
			vector2 digitpos = (PKCGoldDigitXPos[i],newY);
			//if there's already a digit graphic in this position, destroy it first
			//because the image is limited to the frame size, we can't just move it
			if (GoldDigits[i]) {
				GoldDigits[i].unpack();
				GoldDigits[i].destroy();
			}			
			//draw a new digit graphic with the required offset
			let img = new("PKCImage");
			img.pack(self);
			img.Init(
				digitpos,
				digitsize,
				"PKCNUMS"
			);
			GoldDigits[i] = img;
			
			gold /= 10; //with this the next digitYofs will check the next digit in the number
		}
	}
}
		
// Slots are also buttons, but they can hold cards in them
Class PKCCardSlot : PKCButton {
	vector2 slotpos;
	vector2 slotsize;
	PKCButton placedcard;
	bool slottype;
	int slotID;
}

//cards are buttons that hold various data and also become translucent if not purchased
Class PKCTarotCard : PKCButton {
	PKCardsMenu menu;
	bool cardbought;	
	vector2 buttonScale;
	vector2 defaultpos;
	vector2 defaultsize;
	vector2 defaultscale;
	bool slottype;
	string cardname;
	string carddesc;
	name cardID;
	int cardCost;
	int purchaseFrame;
	bool purchaseAnim;
	override void drawer() {
		string texture = btnTextures[curButtonState];
		TextureID tex = TexMan.checkForTexture(texture, TexMan.Type_Any);
		Vector2 imageSize = TexMan.getScaledSize(tex);			
		imageSize.x *= buttonScale.x;
		imageSize.y *= buttonScale.y;
		drawImage((0,0), texture, true, buttonScale);
		
		//fade the card out if it's not purchased (and thus is inaccessible)
		if (!cardbought)
			drawTiledImage((0, 0), box.size, "graphics/Tarot/tooltip_bg.png", true, buttonScale,alpha: 0.75);
		
		//otherwise play the burn frame animation
		else if (purchaseAnim) {
			if (purchaseFrame <= 16) {
				purchaseFrame++;
				string tex = String.Format("graphics/Tarot/cardburn/pkcburn%d.png",purchaseFrame);
				drawImage((0,0),tex,true,buttonScale);
			}
			else {
				purchaseFrame = 0;
				purchaseAnim = false;
			}
		}
	}
}

//a separate handler for the exit and purchase prompts
Class PKCPromptHandler : PKCHandler {
	PKCardsMenu menu;
	PKCTarotCard card;
	
	//this handles Yes and No buttons in the popup:
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		//exit popup Yes: close the board
		if (command == "DoExit") {
			S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			menu.Close();
			return;
		}
		if (command == "BuyCard" && card) {			
			S_StartSound("ui/board/cardburn",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			EventHandler.SendNetworkEvent("PKCUnlockCard",card.cardcost);
			card.cardbought = true;
			card.purchaseAnim = true;
			menu.elementsEHandler.UnlockedTarotCards.push(int(name(card.cardID)));
			let popup = menu.promptPopup;
			if (popup) {
				//Popup.Unpack();
				//Popup.destroy();
				popup.hidden = true;
				popup.disabled = true;
			}
		}
		//No: close the popup
		if (command == "CancelPrompt") {
			S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			let popup = menu.promptPopup;
			if (popup) {
				//Popup.Unpack();
				//Popup.destroy();
				popup.hidden = true;
				popup.disabled = true;
			}
		}
	}
	
	//this makes Yes and No buttons slightly grow and become red when hovered:
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu || command == "")
			return;
		if (!caller || !caller.isEnabled())
			return;
		let btn = PKCButton(caller);			
		if (!unhovered) {
			btn.textscale = 1.8;
			btn.textcolor = Font.FindFontColor('PKRedText');
			S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		}
		else {
			btn.textscale = 1.5;
			btn.textcolor = Font.FindFontColor('PKBaseText');
		}
	}
}

//the main handler for the board menu
Class PKCMenuHandler : PKCHandler {
	PKCardsMenu menu;
	PKCCardSlot hoveredslot;
	PK_BoardElementsHandler elementsEHandler;
		
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		//exit button - works if you don't have a picked card:
		if (command == "BoardButton" && !menu.SelectedCard) {
			//if board opened for the first time in the map, show a yes/no prompt:
			if (menu.firstUse)
				menu.ShowExitPopup();	
			//otherwise just close the board  immediately
			else {
				S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				menu.Close();
			}
			return;
		}
		if (menu.promptPopup && menu.promptPopup.isEnabled())
			return;
		if (command == "CloseFirstUse" && menu.firstUsePopup) {
			S_StartSound("ui/menu/open",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			menu.firstUsePopup.Unpack();
			menu.firstUsePopup.Destroy();
		}
		//card slot: if you have a card picked and click the slot, the card will be placed in it and scaled up to its size:
		if (command == "CardSlot") {			
			let cardslot = PKCCardSlot(Caller);
			//check if there's a selected card
			if (menu.SelectedCard) {
				//if the card's type matches the slot's, place it in the slot:
				let card = PKCTarotCard(menu.SelectedCard);	
				if (card.slottype == cardslot.slottype) {
					menu.SelectedCard = null; //detach from cursor
					card.box.pos = cardslot.slotpos;
					card.box.size = cardslot.slotsize;
					card.buttonscale = (1,1);
					//if there was a card placed in the slot, move that card back to its default pos before placing this one
					if (cardslot.placedcard) {
						let placedcard = PKCTarotCard(cardslot.placedcard);
						placedcard.box.size = placedcard.defaultsize;
						placedcard.box.pos = placedcard.defaultpos;
						placedcard.buttonscale = placedcard.defaultscale;
					}
					//attach the card to slot
					cardslot.placedcard = card;
					sound snd = (cardslot.slottype) ? "ui/board/placegold" : "ui/board/placesilver";
					S_StartSound(snd,CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					if (elementsEHandler) {
						int i = cardslot.slotID;
						elementsEHandler.EquippedSlots[i] = card.cardID;
					}					
				}
				else				
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			}
			//otherwise check if there's a card in the slot; if there is, pick it up and attach to mouse pointer
			else if (cardslot.placedcard) {
				let card = PKCTarotCard(cardslot.placedcard);
				card.box.size = card.defaultsize;
				card.buttonscale = card.defaultscale;
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				cardslot.placedcard = null;
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.boardelements.elements.delete(menu.boardelements.elements.find(card));
				menu.boardelements.elements.push(card);
				if (elementsEHandler) {
					int i = cardslot.slotID;
					elementsEHandler.EquippedSlots[i] = '';
				}
			}
		}
		//clicking the card: attaches card to mouse pointer, or, if you already have one and you click *anywhere* where there's no card slot, the card will jump back to its original slot:
		if (command == "HandleCard") {
			let card = PKCTarotCard(Caller);
			if (!card.cardbought && !menu.SelectedCard) {
				menu.ShowPurchasePopup(card);
				return;
			}
			//don't do anything if you're hovering over a valid slot: we don't want placing into slot and clicking the card to happen at the same time
			if (hoveredslot) {
				//if clicking over incorrect slot color, don't jump back but instead play "wrong slot" sound
				if(hoveredslot.slottype != card.slottype)
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				return;
			}
			//if not hovering over slot, take card and attach it to the menu
			if (!menu.SelectedCard) {
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.boardelements.elements.delete(menu.boardelements.elements.find(card));
				menu.boardelements.elements.push(card);
			}
			//if we already have a card, put it back
			else {
				S_StartSound("ui/board/returncard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				card.box.pos = card.defaultpos;
				menu.SelectedCard = null;
			}
		}
	}
	
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		if (menu.promptPopup)
			return;
		//play sound of hovering over the exit button:
		if (command == "BoardButton" && !menu.SelectedCard) {
			if (!unhovered) {
				S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			}
		}
		//keep track of slots we're hovering over:
		if (command == "CardSlot") {
			if (!unhovered) {
				hoveredslot = PKCCardSlot(Caller);
				if (hoveredslot.slottype == 1) {
					menu.goldSlotsInfo.hidden = false;
					menu.boardelements.elements.delete(menu.boardelements.elements.find(menu.goldSlotsInfo));
					menu.boardelements.elements.push(menu.goldSlotsInfo);
				}
				else {
					menu.silverSlotsInfo.hidden = false;
					menu.boardelements.elements.delete(menu.boardelements.elements.find(menu.silverSlotsInfo));
					menu.boardelements.elements.push(menu.silverSlotsInfo);
				}
			}
			else {
				hoveredslot = null;
				menu.goldSlotsInfo.hidden = true;
				menu.silverSlotsInfo.hidden = true;
			}
		}
		if (command == "HandleCard") {
			let card = PKCTarotCard(Caller);
			if (!unhovered)
				menu.HoveredCard = card;
			else
				menu.HoveredCard = null;
		}
	}
}

Class PK_BoardElementsHandler : StaticEventHandler {
	ui array <name> UnlockedTarotCards;
	ui name EquippedSlots[5];
}

Class PK_BoardEventHandler : EventHandler {
	ui bool boardOpened; //whether the Black Tarot board has been opened on this map
	
	/*override void WorldThingSpawned(Worldevent e) {
		if (e.thing && e.thing == players[consoleplayer].mo)
			Menu.SetMenu("PKCardsMenu");
	}*/	
	override void NetworkProcess(consoleevent e) {
		if (e.name != "PKCUnlockCard")
			return;
		if (e.isManual || e.Player < 0)
			return;
		let plr = players[e.Player].mo;
		if (!plr)
			return;
		let goldcontrol = PK_GoldControl(plr.FindInventory("PK_GoldControl"));
		if (!goldcontrol)
			return;
		/*Array <String> cardname;
		e.name.split(cardname, ":");
		if (cardname.Size() == 0)
			return;
		bool cardtype = Clamp(e.args[0],0,1);
		//console.printf("pushing %s into the array",cardname[1]);
		goldcontrol.UnlockedTarotCards.Push(int(name(cardname[1])));*/
		int cost = e.args[0];
		goldcontrol.pk_gold = Clamp(goldcontrol.pk_gold - cost,0,99990);
	}
}