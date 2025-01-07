/*======================================

  Black Tarot Board for GZDoom
  by Jekyll Grim Payne aka Agent_Ash
  
  The following menu is coded based on 
  ZForms menu library by Gutawer.

======================================*/



Class PKCardsMenu : PKZFGenericMenu {
	double backgroundRatio;
	vector2 boardTopLeft;
	
	PlayerPawn plr;
	PK_CardControl goldcontrol;
	
	PK_BoardEventHandler menuEHandler;
	
	array <PKCTarotCard> silvercards;	//all silver cards
	array <PKCTarotCard> goldcards;		//all gold cards
	
	PKCMenuHandler handler;
	PKCTarotCard SelectedCard;	//card attached to the pointer
	PKCTarotCard HoveredCard;	//card the pointer is hovering over
	
	PKZFFrame silverSlotsInfo;
	PKZFFrame goldSlotsInfo;
	
	PKZFFrame boardElements;		//everything in the board except the background and popups
	PKCBoardMessage cardinfo;		//card information popup
	PKZFLabel cardinfoTip;
	PKZFLabel cardinfoCost;
	PKCBoardMessage promptPopup;	//an exit or purchase popup that blocks the board
	PKCBoardMessage firstUsePopup;	//first use notification
	PKCBoardMessage needMousePopup;	//need mouse notification
	int firstUsePopupDur;				//first use notification display duration
	int needMousePopupDur;			//need mouse notification display duration
	PKZFLabel goldUsesCounter; //shows the number of remaining gold cards activations
	int goldUses;
	int refreshcost;
	
	PKZFButton exitbutton;			//big round flashing menu close button
	bool ExitHovered;				//whether it's hovered
	int ExitAlphaDir;
	
	bool firstUse;
	
	bool queueForClose;
	
	override void Drawer() {
		if (!multiplayer)
			Screen.Dim(0x000000, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
			super.Drawer();
	}

	override void Init (Menu parent) {
		super.Init(parent);
		
		vector2 backgroundsize = (PK_BOARD_WIDTH,PK_BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);		
		
		//check the player isn't dead
		let plr = players[consoleplayer].mo;
		if (!plr || plr.health < 0) {
			queueForClose = true;
			return;
		}
		//check the player has the control item
		goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!goldcontrol || goldcontrol.goldActive) {
			queueForClose = true;
			return;
		}
		
		//check that mouse is enabled and "use mouse in menus" is enabled (there's no keyboard controls for the board)
		bool mouseEnabled = CVar.GetCVar('m_use_mouse',players[consoleplayer]).GetInt() > 0 && CVar.GetCVar('use_mouse',players[consoleplayer]).GetInt() > 0;
		
		//checks if the board is opened for the first time on the current map:
		menuEHandler = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (mouseEnabled && menuEHandler) {
			firstUse = !menuEHandler.boardOpenedTracker[consoleplayer];
		}

		/*if (menuEHandler && mouseEnabled) {
			if (!menuEHandler.boardOpened) {
				firstUse = true;
				menuEHandler.boardOpened = true;
			}
			else
				firstUse = false;
			console.printf("Board first use: %d", firstuse);
		}*/
		
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//first create the background (always 4:3, never stretched)
		let background = PKZFImage.Create(
			(0,0),
			backgroundsize,
			image:"graphics/HUD/Tarot/cardsboard.png"/*,
			imagescale:(1*backgroundRatio,1*backgroundRatio)*/
		);
		background.Pack(mainFrame);
		
		
		//define the frame that will keep everything except text popups:
		boardelements = PKZFFrame.Create((0,0),backgroundsize);
		boardelements.pack(mainFrame);

		handler = new("PKCMenuHandler");
		handler.menu = self;		
		
		GoldActivationsInit(); //gold uses counter and refresh button
		
		//clicking anywhere on the board is supposed to close the First Use popup:
		let closeFirstUseBtn = PKZFButton.Create(
			(0,0),
			backgroundsize,
			cmdhandler:handler,
			command:"CloseFirstUse"
		);
		closeFirstUseBtn.Pack(boardElements);
		
		if (!mouseEnabled) {
			string str = String.Format(Stringtable.Localize("$TAROT_NEEDMOUSE"),Stringtable.Localize("$OPTMNU_TITLE"),Stringtable.Localize("$OPTMNU_MOUSE"),Stringtable.Localize("$MOUSEMNU_MOUSEINMENU"));
			needMousePopup = PKCBoardMessage.Create(
				(192,256),
				(700,256),
				str,
				textscale:PK_MENUTEXTSCALE*1.2
			);
			let pressEsc = PKZFLabel.Create((0,180),(700,32),Stringtable.Localize("$TAROT_PRESSESC"),font_times,alignment:PKZFElement.AlignType_BottomCenter,textscale:PK_MENUTEXTSCALE*1.2,textcolor:Font.FindFontColor('PKWhiteText'));
			pressEsc.Pack(needMousePopup);
			needMousePopup.pack(mainFrame);
			needMousePopupDur = 800;
			return;
		}
		
		//create big round exit button:
		let exittex = PKZFBoxTextures.CreateSingleTexture("graphics/HUD/Tarot/board_button_highlighted.png",false);
		exitbutton = PKZFButton.Create(
			(511,196),
			(173,132),
			cmdhandler:handler,
			command:"BoardButton",
			inactive:exittex,
			hover:exittex,
			click:exittex,
			disabled:exittex
		);
		exitbutton.Pack(boardelements);

		SlotsInit();	//initialize card slots
		CardsInit();	//initialize cards
		SlotInfoInit(); //hover text with info about slots
		
		let goldcounter = PKCGoldCounter.Create(
			(728,237),
			(170,50)
		);		
		goldcounter.Pack(boardElements);
		
	}
	
	protected void GoldActivationsInit() {
		vector2 counterPos = (435, 365);
		vector2 counterSize = (47,47);
		let counter = PKZFImage.Create(
			counterpos,
			counterSize,
			"graphics/HUD/Tarot/board_numberbox.png"
		);
		
		goldUsesCounter = PKZFLabel.Create(
			counterpos,
			counterSize,
			"0",
			"PKHNUMS",
			alignment: PKZFElement.AlignType_Center,
			textscale:PK_MENUTEXTSCALE * 2
		);
		
		vector2 buttonPos = (431, 410);
		let refreshButtonTex = PKZFBoxTextures.CreateSingleTexture("graphics/HUD/Tarot/board_refresh.png",false);
		let refreshButtonTexHL = PKZFBoxTextures.CreateSingleTexture("graphics/HUD/Tarot/board_refresh_hover.png",false);
		let refreshButton = PKZFButton.Create(
			buttonPos,
			(53, 53),
			cmdhandler: handler,
			command: "ShowRefreshPopup",
			inactive:refreshButtonTex,
			hover:refreshButtonTexHL,
			click:refreshButtonTexHL,
			disabled:refreshButtonTex
		);
		
		counter.Pack(mainFrame);
		goldUsesCounter.Pack(mainFrame);
		refreshButton.Pack(mainFrame);
	}
		
	
	//card slots aren't evenly spaced, so I define their positions explicitly:
	static const int PKCSlotXPos[] = {  58, 231, 489, 660, 829 };
	static const int PKCSlotYPos[] = { 179, 179, 364, 364, 364 };
	//array of slots; filled on slots' initialization
	PKCCardSlot cardslots[5];
	
	const equipSlotSizeX = 138;
	const equipSlotSizeY = 227;
	
	//Initialize slot-related pop-up tips:
	private void SlotInfoInit() {
		double bkgalpha = 0.7;
		
		//silver slots tip:
		vector2 silverTipSize = (280,80);
		silverSlotsInfo = PKZFFrame.Create((75,255),silverTipSize);
		silverSlotsInfo.Pack(boardElements);
		silverSlotsInfo.setDontBlockMouse(true);
		let silverSlotBkg = PKZFImage.Create(
			(0,0),
			silverTipSize,
			"graphics/HUD/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		silverSlotBkg.SetAlpha(bkgalpha);
		silverSlotBkg.setDontBlockMouse(true);
		silverSlotBkg.Pack(silverSlotsInfo);
		let silverSlotText = PKZFLabel.Create(
			(5,5),
			(270,70),
			Stringtable.Localize("$TAROT_SILVERINFO"),
			font_times,
			alignment: PKZFElement.AlignType_HCenter,
			textscale:PK_MENUTEXTSCALE*0.9,
			textcolor: Font.FindFontColor('PKWhiteText'),
			linespacing: 0.1
		);
		silverSlotText.Pack(silverSlotsInfo);
		silverSlotText.setDontBlockMouse(true);
		silverSlotsInfo.Hide();

		//gold slots tip:
		vector2 goldTipSize = (360,80);
		goldSlotsInfo = PKZFFrame.Create((560,440),goldTipSize);
		goldSlotsInfo.Pack(boardElements);
		goldSlotsInfo.setDontBlockMouse(true);
		let goldSlotBkg = PKZFImage.Create(
			(0,0),
			goldTipSize,
			"graphics/HUD/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		goldSlotBkg.SetAlpha(bkgalpha);
		goldSlotBkg.Pack(goldSlotsInfo);
		goldSlotBkg.setDontBlockMouse(true);
		let goldSlotText = PKZFLabel.Create(
			(5,5),
			(350,70),
			Stringtable.Localize("$TAROT_GOLDINFO"),
			font_times,
			alignment: PKZFElement.AlignType_HCenter,
			textscale:PK_MENUTEXTSCALE*0.9,
			textcolor: Font.FindFontColor('PKWhiteText'),
			linespacing: 0.1
		);
		goldSlotText.Pack(goldSlotsInfo);
		goldSlotText.setDontBlockMouse(true);
		goldSlotsInfo.Hide();
		
		//sizes and positions of the ares that you need to hover in order to see the tips:
		/*vector2 silverTipAreaPos = (PKCSlotXPos[0], PKCSlotYPos[0]);
		vector2 silverTipAreaSize = (PKCSlotXPos[1] + equipSlotSizeX, PKCSlotYPos[0] + equipSlotSizeY);
		let silverTipArea = PKZFTipFrame.Create(silverTipAreaPos, silverTipAreaSize, handler, "SilverTip");
		silverTipArea.setDontBlockMouse(true);
		vector2 goldTipAreaPos = (PKCSlotXPos[2], PKCSlotYPos[2]);
		vector2 goldTipAreaSize = (PKCSlotXPos[4] + equipSlotSizeX, PKCSlotYPos[2] + equipSlotSizeY);
		let goldTipArea = PKZFTipFrame.Create(silverTipAreaPos, silverTipAreaSize, handler, "GoldTip");
		goldTipArea.setDontBlockMouse(true);
		*/
	}
	
	//Initialize slots the cards can be equipped to:
	private void SlotsInit() {
		vector2 slotsize = (equipSlotSizeX,equipSlotSizeY);	
		for (int i = 0; i < 5; i++) {
			vector2 slotpos = (PKCSlotXPos[i],PKCSlotYPos[i]);
			let cardslot = PKCCardSlot.Create(
				slotpos,
				slotsize,
				cmdhandler:handler,
				command:"CardSlot"
			);
			cardslot.slotpos = slotpos;
			cardslot.slotsize = slotsize;
			cardslot.slottype = (i < 2) ? false : true;
			cardslot.slotID = i;
			cardslot.setDontBlockMouse(false);
			cardslots[i] = cardslot;
			cardslot.Pack(boardelements);
		}
	}
	//LANGUAGE references containing card names:
	static const string PKCCardNames[] = {
		//silver
		"$PK_SOULKEEPER_NAME"		,	"$PK_BLESSING_NAME"		,	"$PK_REPLENISH_NAME",
		"$PK_DARKSOUL_NAME"		,	"$PK_SOULCATCHER_NAME"	,	"$PK_FORGIVENESS_NAME",
		"$PK_GREED_NAME"			,	"$PK_SOULREDEEMER_NAME"	,	"$PK_REGENERATION_NAME",
		"$PK_HEALTHSTEALER_NAME"	,	"$PK_HELLISHARMOR_NAME"	,	"$PK_666AMMO_NAME",
		//gold
		"$PK_ENDURANCE_NAME"		,	"$PK_TIMEBONUS_NAME"		,	"$PK_SPEED_NAME",
		"$PK_REBIRTH_NAME"		,	"$PK_CONFUSION_NAME"		,	"$PK_DEXTERITY_NAME",
		"$PK_WMODIFIER_NAME"		,	"$PK_SOT_NAME"				,	"$PK_RAGE_NAME",
		"$PK_MAGICGUN_NAME"		,	"$PK_IRONWILL_NAME"		,	"$PK_HASTE_NAME"
	};
	//LANGUAGE references containing card descriptions:
	static const string PKCCardDescs[] = {
		//silver
		"$PK_SOULKEEPER_DESC"		,	"$PK_BLESSING_DESC"		,	"$PK_REPLENISH_DESC",
		"$PK_DARKSOUL_DESC"		,	"$PK_SOULCATCHER_DESC"	,	"$PK_FORGIVENESS_DESC",
		"$PK_GREED_DESC"			,	"$PK_SOULREDEEMER_DESC"	,	"$PK_REGENERATION_DESC",
		"$PK_HEALTHSTEALER_DESC"	,	"$PK_HELLISHARMOR_DESC"	,	"$PK_666AMMO_DESC",
		//gold
		"$PK_ENDURANCE_DESC"		,	"$PK_TIMEBONUS_DESC"		,	"$PK_SPEED_DESC",
		"$PK_REBIRTH_DESC"		,	"$PK_CONFUSION_DESC"		,	"$PK_DEXTERITY_DESC",
		"$PK_WMODIFIER_DESC"		,	"$PK_SOT_DESC"				,	"$PK_RAGE_DESC",
		"$PK_MAGICGUN_DESC"		,	"$PK_IRONWILL_DESC"		,	"$PK_HASTE_DESC"
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
			string texpath = String.Format("graphics/HUD/Tarot/cards/%s.png",PKCCardIDs[i]);
			let cardTex = PKZFBoxTextures.CreateSingleTexture(texpath,false);
			let card = PKCTarotCard.Create(
				cardpos,
				cardsize,
				cmdhandler:handler,
				command:"HandleCard",
				inactive:cardTex,
				hover:cardTex,
				click:cardTex,
				disabled:cardTex
			);
			card.setDontBlockMouse(true);
			card.cardtexture = TexMan.checkForTexture(texpath, TexMan.Type_Any);
			card.cardtextureName = texpath;
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

			if (goldcontrol) {
				//check if the card is already unlocked:
				if (goldcontrol.UnlockedTarotCards.Find(card.cardID) != goldcontrol.UnlockedTarotCards.Size()) {
					//console.printf("%s is bought",card.cardID);
					card.cardbought = true;
				}
				//check if the card is already equipped, and if so, place it in that slot:
				for (int i = 0; i < cardslots.Size(); i++) {
					if (goldcontrol.EquippedSlots[i] == card.cardID) {
						let cardslot = cardslots[i];
						card.SetBox(cardslot.slotpos, cardslot.slotsize);
						card.buttonscale = (1,1);
						cardslot.placedcard = card;
						card.cardlocked = !firstUse;
					}
				}
			}
			
		}
		//unlock 2 random silver and 3 random gold cards if you have none unlocked ("pistol start") and a CVAR allows that:	
		if (pk_allowFreeCards && goldcontrol && goldcontrol.UnlockedTarotCards.Size() == 0) {
			//S_StartSound("ui/board/cardunlocked",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			S_StartSound("ui/board/cardburn",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			//console.printf("fist unlock");			
			ShowFirstUsePopup();
			
			//these arrays are used to make sure we don't unlock the same card more than once:
			array <PKCTarotCard> UnlockedGoldCards;
			array <PKCTarotCard> UnlockedSilverCards;
			
			//unlock the cards and push them into an array on the item token via a netevent:
			while (UnlockedSilverCards.Size() < 2) {
				let card = PKCTarotCard(silvercards[random[tarot](0,silvercards.Size()-4)]);
				if (UnlockedSilverCards.Find(card) == UnlockedSilverCards.Size()) {
					card.cardbought = true;
					card.purchaseAnim = true;
					UnlockedSilverCards.push(card);					
					string eventname = String.Format("PKCBuyCard:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname);
				}
			}
			while (UnlockedGoldCards.Size() < 3) {
				let card = PKCTarotCard(goldcards[random[tarot](0,goldcards.Size()-4)]);
				if (UnlockedGoldCards.Find(card) == UnlockedGoldCards.Size()) {
					card.cardbought = true;
					card.purchaseAnim = true;
					UnlockedGoldCards.push(card);
					string eventname = String.Format("PKCBuyCard:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname);
				}
			}
		}
	}
	
	//make sound, call netevent to activate equipped cards, close the board
	void CloseBoard() {
		S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		EventHandler.SendNetworkEvent('PKCCloseBoard', firstUse);
		Close();
	}

	//shows exit popup message
	void ShowExitPopup() {
		if (!boardElements)
			return;
				
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);


		promptPopup = PKCBoardMessage.Create(
			popuppos,
			popupsize,
			Stringtable.Localize("$TAROT_EXIT"),
			textscale:PK_MENUTEXTSCALE* 1,
			alignment: PKZFElement.AlignType_HCenter
		);
		promptPopup.pack(mainFrame);
		
		let promptHandler = PKCPromptHandler(new("PKCPromptHandler"));
		promptHandler.menu = self;		
		
		//create Yes button:
		vector2 buttonsize = (100,60);
		let yesButton = PKZFButton.Create(
			(100,160),
			buttonsize,
			text:Stringtable.Localize("$TAROT_YES"),
			cmdhandler:promptHandler,
			command:"DoExit",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		yesButton.pack(promptPopup);
		
		//create No button:
		let noButton = PKZFButton.Create(
			(440,160),
			buttonsize,
			text:Stringtable.Localize("$TAROT_NO"),
			cmdhandler:promptHandler,
			command:"CancelPrompt",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		noButton.pack(promptPopup);
	}
	
	void ShowFirstUsePopup() {
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);
			
		string firstUseLine = Stringtable.Localize("$TAROT_FIRSTUSE");
		//show "first use" text popup (doesn't block the board):
		promptPopup = PKCBoardMessage.Create(
			popuppos,
			popupsize,
			firstUseLine,
			textscale:PK_MENUTEXTSCALE* 1.2,
			alignment: PKZFElement.AlignType_HCenter
		);
		promptPopup.pack(mainFrame);
		
		let promptHandler = PKCPromptHandler(new("PKCPromptHandler"));
		promptHandler.menu = self;
		
		vector2 buttonsize = (100,60);
		let okButton = PKZFButton.Create(
			(265,160),
			buttonsize,
			text:Stringtable.Localize("$TAROT_CLOSE"),
			cmdhandler:promptHandler,
			command:"CancelPrompt",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		okButton.pack(promptPopup);
	}

	void ShowPurchasePopup(PKCTarotCard card, bool unequip = false) {
		if (!boardElements || !card)
			return;
				
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);
		
		promptPopup = PKCBoardMessage.Create(
			popuppos,
			popupsize,
			card.cardname,
			textscale:PK_MENUTEXTSCALE* 1.4,
			alignment: PKZFElement.AlignType_HCenter
		);
		promptPopup.pack(mainFrame);
		
		int gold;
		if (goldcontrol)
			gold = goldcontrol.GetGoldAmount();
		
		string purchaseLine;
		if (!unequip)
			purchaseLine = (gold >= card.cardcost) ? Stringtable.Localize("$TAROT_PURCHASE") : Stringtable.Localize("$TAROT_CANTPURCHASE");
		else
			purchaseLine = (gold >= card.cardcost) ? Stringtable.Localize("$TAROT_PAYTOUNEQUIP") : Stringtable.Localize("$TAROT_CANTUNEQUIP");
		vector2 purchaseTextofs = (16,16);	
		let purchaseText = PKZFLabel.Create(
			purchaseTextofs+(0,40),
			popupsize-(purchaseTextofs*1.2),
			String.Format(purchaseLine,card.cardCost), 
			font_times,
			alignment: PKZFElement.AlignType_HCenter,
			textscale:PK_MENUTEXTSCALE*1,
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
			let yesButton = PKZFButton.Create(
				(100,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_YES"),
				cmdhandler:promptHandler,
				command:"BuyCard",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			yesButton.pack(promptPopup);
			
		
			//create No button:
			let noButton = PKZFButton.Create(
				(440,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_NO"),
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			noButton.pack(promptPopup);
		}
		
		else {		
			//create Close button:
			let okButton = PKZFButton.Create(
				(265,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_CLOSE"),
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			okButton.pack(promptPopup);
		}			
	}
	
	void ShowRefreshPopup() {
		if (!boardElements || !goldcontrol)
			return;
			
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		vector2 popuppos = (192,160);
		vector2 popupsize = (640,260);
		
		refreshCost = 0;
		for (int i = 2; i < 5; i++) {
			let slot = cardslots[i];
			if (slot && slot.placedcard) {
				PKCTarotCard card = cardslots[i].placedcard;
				refreshCost += card.cardcost;
			}
		}				
		
		int maxUses = 1;
		if (goldcontrol.EquippedSlots[0] == "Forgiveness" || goldcontrol.EquippedSlots[1] == "Forgiveness")
			maxUses = 2;
		string refresh_spend = String.Format(Stringtable.Localize("$TAROT_REFRESH_REMAINING"), goldUses, refreshCost, maxUses);
		string refresh_needgold = String.Format(Stringtable.Localize("$TAROT_REFRESH_NEEDGOLD"), goldUses, refreshCost);
		string refresh_atmax = String.Format(Stringtable.Localize("$TAROT_REFRESH_MAX"), goldUses);
		
		string refreshMsg;
		if (goldUses >= maxUses) 
			refreshMsg = refresh_atmax;
		else if (goldcontrol.GetGoldAmount() >= refreshCost)
			refreshMsg = refresh_spend;
		else
			refreshMsg = refresh_needgold;
		
		promptPopup = PKCBoardMessage.Create(
			popuppos,
			popupsize,
			refreshMsg,
			textscale:PK_MENUTEXTSCALE* 1,
			alignment: PKZFElement.AlignType_HCenter
		);
		promptPopup.pack(mainFrame);		
		
		let promptHandler = PKCPromptHandler(new("PKCPromptHandler"));
		promptHandler.menu = self;	
		
		vector2 buttonsize = (100,60);
		
		if (refreshMsg == refresh_spend) {		
			//create Yes button:
			let yesButton = PKZFButton.Create(
				(100,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_YES"),
				cmdhandler:promptHandler,
				command:"RefreshUses",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			yesButton.pack(promptPopup);			
		
			//create No button:
			let noButton = PKZFButton.Create(
				(440,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_NO"),
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			noButton.pack(promptPopup);
		}
		
		else {		
			//create Close button:
			let okButton = PKZFButton.Create(
				(265,160),
				buttonsize,
				text:Stringtable.Localize("$TAROT_CLOSE"),
				cmdhandler:promptHandler,
				command:"CancelPrompt",
				fnt:font_times,
				textscale:PK_MENUTEXTSCALE*1.5,
				textColor:Font.FindFontColor('PKBaseText')
			);
			okButton.pack(promptPopup);
		}			
	}
	
	void ShowCardToolTip(PKCTarotCard card) {
		if (!card)
			return;
		vector2 tippos = (62,430);
		vector2 tipsize = (378,173);
		vector2 tiptextofs = (16,16);	

		string title = String.Format("%s",Stringtable.Localize(card.cardname));	//card name
		string desc = String.Format("%s",Stringtable.Localize(card.carddesc));	//description
		string cost = String.Format("%d%s",card.cardcost,Stringtable.Localize("$TAROT_GOLDABR")); //cost and the abbreviation for "gold"
		
		if (!cardinfo) {
			cardinfo = PKCBoardMessage.Create(
				tippos,
				tipsize,
				title,
				textscale:PK_MENUTEXTSCALE*1.2,
				textcolor: Font.FindFontColor('PKRedText')
			);
			cardinfo.pack(mainFrame);
		}
		else {
			cardinfo.Show();
			cardinfo.text = title;
		}
		if (!cardinfoTip) {
			cardinfoTip = PKZFLabel.Create(
				tiptextofs+(0,48),
				tipsize-(tiptextofs*1.2),
				desc, 
				font_times,
				textscale:PK_MENUTEXTSCALE*1,
				textcolor: Font.FindFontColor('PKBaseText'),
				linespacing: 0.1
			);
			cardinfoTip.Pack(cardinfo);	
		}
		else
			cardinfoTip.SetText(desc);
		if (!cardinfoCost) {
			cardinfoCost = PKZFLabel.Create(
				tiptextofs+(185,0),
				(160,64),
				cost, 
				font_times,
				alignment:PKZFElement.AlignType_TopRight,
				textscale:1,
				textcolor: Font.FindFontColor('PKGreenText'),
				linespacing: 0.1
			);
			cardinfoCost.Pack(cardinfo);	
		}
		else {
			cardinfoCost.SetText(cost);
			if (!card.cardbought)
				cardinfoCost.Show();
			else
				cardinfoCost.Hide();
		}
	}

    override void HandleBack () {
		//show "mouse needed" message if no mouse detected
		if (needMousePopup) {
			S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			CloseBoard();
			super.HandleBack();
			return;
		}
		//if exit prompt is active, hitting Esc will close the popup, not the menu:
		if (promptPopup && promptPopup.isEnabled()) {
			S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			promptPopup.Hide();
			promptPopup.Disable();
		}
		//otherwise draw a Yes/No exit prompt:
		else if (firstUse) {
			ShowExitPopup();
		}
		//if not first use, just close the board with the right sound
		else {
			CloseBoard();
			super.HandleBack();
			return;
		}
    }
	
	void DeselectCard() {
		selectedCard = null;
	}
	
	override void Ticker() {
		//vector2 mpos = boardelements.screenToRel(GetMousePos());
		//Screen.DrawText(font_times, Font.CR_WHITE, 8, 8, String.Format("x: %f | y: %f", mpos.x, mpos. y));
		if (queueForClose) {
			Close();
			return;
		}
		if ((promptPopup && promptPopup.isEnabled()) || needMousePopup || firstUsePopup) {
			boardElements.Disable();
		}
		else {
			boardElements.Enable();
		}
		
		if (needMousePopup) {
			needMousePopupDur--;			
			if (needMousePopupDur <= 0) {
				Close();
			}
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
		
		//if the player picked a card from a slot, move it with the mouse pointer:
		if (SelectedCard) {
			//this is another safeguard to make sure placed cards don't accidentally get attached to the pointer (kept randomly happening for a couple of cards for no obvious reason)
			for (int i = 0; i < cardslots.Size(); i++) {
				let cardslot = cardslots[i];
				if (cardslot && cardslot.placedcard == SelectedCard) {					
					SelectedCard.SetBox(cardslot.slotpos, cardslot.slotsize);
					SelectedCard.buttonscale = (1,1);
					selectedCard = null;
					break;
				}
			}
			if (selectedCard) {
				SelectedCard.SetBox(boardelements.screenToRel(GetMousePos()) - SelectedCard.GetSize() / 2, SelectedCard.GetSize());
			}
		}
		
		//show card info if mouse hovers over a card and there's no card selected:
		if ((!cardinfo || cardinfo.isHidden()) && HoveredCard && HoveredCard.isEnabled() && !HoveredCard.isHidden() && !SelectedCard)
			ShowCardToolTip(HoveredCard);
		//as soon as you hover off the card, immediately remove card info:
		if (cardinfo && !cardinfo.isHidden() && (!HoveredCard || !HoveredCard.isEnabled() || HoveredCard.isHidden() || SelectedCard)) {
			cardinfo.Hide();
		}
		//exit button continuously flashes, like in original:
		if (exitbutton) {
			if (exitbutton.GetAlpha() <= 0.25)
				ExitAlphaDir = 1;
			else if (exitbutton.GetAlpha() >= 1)
				ExitAlphaDir = -1;
			exitbutton.SetAlpha( (exitbutton.isHovered() && !SelectedCard) ? 1.0 : Clamp(exitbutton.GetAlpha()+0.05*ExitAlphaDir,0.25,1.0) );
		}
		
		// Track the number of remaining Golden Card activations:
		if (goldcontrol) {
			goldUses = goldcontrol.GetGoldUses();
			// Update the value of the visual counter:
			if (goldUsesCounter)
				goldUsesCounter.setText(String.Format("%d", goldUses));
		}
		
		super.Ticker();
	}
}

Class PKZFTipFrame : PKZFFrame {
	void config(PKZFHandler cmdHandler = NULL, string command = "") {
		cmdHandler = cmdHandler;
		command = command;
	}
	static PKZFTipFrame create(Vector2 pos, Vector2 size, PKZFHandler cmdHandler = null, string command = "") {
		let ret = new('PKZFTipFrame');

		ret.setBox(pos, size);
		ret.alpha = 1;
		ret.config(cmdHandler, command);

		return ret;
	}
}

/* 
	A generalized Board message frame that includes a lighter outline,
	a darker inner image, and a slot for text. Use by popups.
*/
Class PKCBoardMessage : PKZFFrame {
	private int dur;
	string text;
	PKZFLabel msgPrompt;
	static PKCBoardMessage Create (vector2 msgpos, vector2 msgsize, string msgtext = "", double TextScale = 1.0, int TextColor = 0,  AlignType alignment = AlignType_TopLeft) {
		let ret = new('PKCBoardMessage');

		ret.setBox(msgpos, msgsize);
		ret.alpha = 1;
	
		let outline = PKZFImage.Create(
			(0,0),
			msgsize,
			"graphics/HUD/Tarot/tooltip_bg_outline.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		outline.Pack(ret);
				
		vector2 intofs = (4,4);
		let bkg = PKZFImage.Create(
			intofs,
			msgsize-(intofs*2),
			"graphics/HUD/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		bkg.Pack(ret);
		
		if (msgtext == "")
			return ret;
		ret.text = msgtext;
		
		if (textColor == 0)
			TextColor = Font.FindFontColor('PKWhiteText');
		
		vector2 msgTextOfs = intofs+(12,12);
		ret.msgPrompt = PKZFLabel.Create(
			msgTextOfs,
			msgsize-(msgTextOfs*2),
			ret.text,
			font_times,
			alignment: alignment,
			textscale: TextScale,
			textcolor: TextColor
		);		
		ret.msgPrompt.Pack(ret);
		return ret;
	}
	override void drawer() {
		super.drawer();
		if (msgPrompt && text)
			msgPrompt.SetText(text);
	}
}

Class PKCGoldCounter : PKZFFrame {
	PK_CardControl goldcontrol;	//this item holds the amount of gold
	PKZFImage GoldDigits[6]; //there's a total of 6 digits
	vector2 DigitPos[6];
	//digits are not spaced totally evently, so we define their X pos explicitly:
	static const int PKCGoldDigitXPos[] = { -3, 24, 53, 82, 111, 141 };
	int PKCGoldDigitYPos[6];
	
	DynamicValueInterpolator GoldInterpolator[6];
	
	static PKCGoldCounter Create(Vector2 pos, Vector2 size) {
		let ret = new('PKCGoldCounter');
		ret.setBox(pos, size);
		ret.alpha = 1;
		
		//the rightmost digit of the counter is always 0 since max gold is 99990, so we just draw it here and don't modify it further:
		vector2 digitsize = (27,50);
		let img = PKZFImage.Create(
			(-3,-5),
			digitsize,
			"PKCNUMS"
		);
		img.pack(ret);
		ret.DigitPos[0] = img.GetPos();
		ret.GoldDigits[0] = img;
		
		for (int i = ret.GoldInterpolator.Size() - 1; i > 0; i--) {
			ret.GoldInterpolator[i] = DynamicValueInterpolator.Create(0,0.1,4,64);
		}
		
		//cast the gold item
		ret.goldcontrol = PK_CardControl(players[consoleplayer].mo.FindInventory("PK_CardControl"));

		return ret;
	}
	
	override void ticker() {
		super.ticker();
		if (!goldcontrol)
			return;		
		int gold = goldcontrol.GetGoldAmount(); //check how much gold we have
		vector2 digitsize = (32,640);	//digit size is fixed
		//iterate through digits, right to left:
		//we don't modify the rightmost one, so it's > 0, not >= 0:
		for (int i = 5; i > 0; i--) {
			//get target Y offset based on the rightmost digit in the gold amount number:
			int targetYofs = ((gold % 10) * -64) - 5;
			//check if target Y offset is not equal to the previously recorded value
			if (PKCGoldDigitYPos[i] != targetYofs) {
				//if so, reset interpolator
				GoldInterpolator[i].Reset(PKCGoldDigitYPos[i]);
				//and record the value
				PKCGoldDigitYPos[i] = targetYofs;
			}
			else //if the target value is already recorded, just do the interpolation
				GoldInterpolator[i].Update(targetYofs);
			int newY = GoldInterpolator[i].GetValue();			
			vector2 digitpos = (PKCGoldDigitXPos[i],newY);
			/*	If there's already a digit graphic in this position, destroy it first,
				because the image is cropped to the frame size, so we can't just move it
				and show more of it.
			*/
			if (GoldDigits[i]) {
				GoldDigits[i].unpack();
				GoldDigits[i].destroy();
			}			
			//draw a new digit graphic with the required offset
			let img = PKZFImage.Create(
				digitpos,
				digitsize,
				"PKCNUMS"
			);
			img.pack(self);
			if (newY != targetYofs && abs((newY+5) % 64) <= 4)
				S_StartSound("ui/board/digitchange",CHAN_VOICE,CHANF_UI|CHANF_NOSTOP,volume:snd_menuvolume);
		
			GoldDigits[i] = img;
			
			gold /= 10; //with this the next targetYofs will check the next digit in the number
		}
	}
}
		
// Slots are also buttons, but they can hold cards in them
Class PKCCardSlot : PKZFButton {
	vector2 slotpos;
	vector2 slotsize;
	PKCTarotCard placedcard;
	bool slottype;
	int slotID;

	static PKCCardSlot Create(Vector2 pos, Vector2 size, PKZFHandler cmdHandler = NULL, string command = "") {
		let ret = new('PKCCardSlot');
		ret.config("", cmdHandler, command, null, null, null, null, null, 1, 0, -1);
		ret.setBox(pos, size);
		return ret;
	}
}

//cards are buttons that hold various data and also become translucent if not purchased
Class PKCTarotCard : PKZFButton {
	PKCardsMenu menu;
	bool cardbought;	
	bool cardlocked;	//is set to true for cards placed in slots once the board has been closed
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
	TextureID cardtexture;
	string cardtextureName;
	override void drawer() {
		/*string texture = btnTextures[curButtonState];
		if (!cardtexture)
			cardtexture = TexMan.checkForTexture(texture, TexMan.Type_Any);*/
		Vector2 imageSize = TexMan.getScaledSize(cardtexture);			
		imageSize.x *= buttonScale.x;
		imageSize.y *= buttonScale.y;
		drawImage((0,0), cardtextureName, true, buttonScale);
		
		//fade the card out if it's not purchased (and thus is inaccessible)
		if (!cardbought)
			drawTiledImage((0, 0), GetSize(), "graphics/HUD/Tarot/tooltip_bg.png", true, buttonScale,alpha: 0.75);
		//fade the card out if it's locked (equipped in a slot and the board has already been used in this map)
		if (cardlocked)
			drawTiledImage((0, 0), GetSize(), "graphics/HUD/Tarot/tooltip_bg.png", true, buttonScale,alpha: 0.4);
		
		//otherwise play the burn frame animation
		else if (purchaseAnim) {
			if (purchaseFrame <= 16) {
				purchaseFrame++;
				string tex = String.Format("graphics/HUD/Tarot/cardburn/pkcburn%d.png",purchaseFrame);
				drawImage((0,0),tex,true,buttonScale);
			}
			else {
				purchaseFrame = 0;
				purchaseAnim = false;
			}
		}
	}

	override void Ticker() {
		super.Ticker();
		/*	The purpose if this block is to make *absolutely sure*
			that every card *never* ends up stuck somewhere on the board
			outside of any slots.
			The chances of this happening are very small, but I had
			some elusive glitches where the card would sometimes not
			equip to a slot properly, and I haven't found a way to
			solve it for 100% of cases, so I made this.
		*/
		if (!menu)
			return;
		//do nothing if this card is being dragged, that's the only case when we allow all positions
		if (menu.selectedCard == self)
			return;
		//get pos and size:
		vector2 pos = GetPos();
		vector2 size = GetSize();
		//do nothing if the card is in its default position:
		if (pos == defaultpos && size == defaultsize)
			return;
		//iterate through slots and check if the card is in any of them:
		for (int i = 0; i < menu.cardslots.Size(); i++) {
			if (menu.cardslots[i]) {
				let placedcard = menu.cardslots[i].placedcard;
				//if it's placed, make sure the size and pos are correct:
				if (placedcard && placedcard == self) {
					SetBox(menu.cardslots[i].slotpos, menu.cardslots[i].slotsize);
					buttonscale = (1,1);					
					return;
				}
			}
		}
		//if all of the above fail, return the card to its default position:
		SetBox(defaultpos, defaultsize);
		buttonscale = defaultscale;
	}
	
	static PKCTarotCard create(Vector2 pos, Vector2 size, string text = "", PKZFHandler cmdHandler = NULL, string command = "",
	               PKZFBoxTextures inactive = NULL, PKZFBoxTextures hover = NULL, PKZFBoxTextures click = NULL,
	               PKZFBoxTextures disabled = NULL, Font fnt = NULL, double textScale = 1, int textColor = Font.CR_WHITE,
	               int holdInterval = -1) {
		let ret = new('PKCTarotCard');

		ret.config(text, cmdHandler, command, inactive, hover, click, disabled, fnt, textScale, textColor, holdInterval);
		ret.setBox(pos, size);

		return ret;
	}
}

//a separate handler for the exit and purchase prompts
Class PKCPromptHandler : PKZFHandler {
	PKCardsMenu menu;
	PKCTarotCard card;
	
	//this handles Yes and No buttons in the popup:
	override void buttonClickCommand(PKZFButton caller, string command) {
		//Console.printf("buttonClickCommand, %p, %s", caller, command);
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		//exit popup Yes: close the board
		if (command == "DoExit") {	
			menu.CloseBoard();
			return;
		}
		// Card purchase popup: yes, buy the card
		if (command == "BuyCard" && card) {
			if (card.cardlocked) {
				S_StartSound("ui/menu/open",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				card.cardlocked = false;
				EventHandler.SendNetworkEvent("PKCTakeGold",card.cardcost);
			}
			else {
				S_StartSound("ui/board/cardburn",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				card.cardbought = true;
				card.purchaseAnim = true;
				string eventname = String.Format("PKCBuyCard:%s",card.cardID);
				EventHandler.SendNetworkEvent(eventname,card.cardcost);
				//console.printf("buying card %s at %d",card.cardID,card.cardcost);
			}
			CloseMenuPopup();
		}
		// Refresh Uses popup: yes, refresh them
		if (command == "RefreshUses") {
			EventHandler.SendNetworkEvent("PKCRefreshUses", menu.refreshCost);
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			CloseMenuPopup();
		}		
		//No: close the popup
		if (command == "CancelPrompt") {
			S_StartSound("ui/menu/back",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			CloseMenuPopup();
		}
	}
	
	void CloseMenuPopup() {
		if (!menu)
			return;
		let popup = menu.promptPopup;
		if (popup) {
			popup.Hide();
			popup.Disable();
		}
	}
	
	//this makes Yes and No buttons slightly grow and become red when hovered:
	override void elementHoverChanged(PKZFElement caller, string command, bool unhovered) {
		if (!menu || command == "")
			return;
		if (!caller || !caller.isEnabled())
			return;
		let btn = PKZFButton(caller);			
		if (!unhovered) {
			btn.SetTextScale(1.8);
			btn.SetTextColor(Font.FindFontColor('PKRedText'));
			S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		}
		else {
			btn.SetTextScale(1.5);
			btn.SetTextColor(Font.FindFontColor('PKBaseText'));
		}
	}
}

//the main handler for the board menu
Class PKCMenuHandler : PKZFHandler {
	PKCardsMenu menu;
	PKCCardSlot hoveredslot;
	//PK_BoardElementsHandler elementsEHandler;
		
	override void buttonClickCommand(PKZFButton caller, string command) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		//exit button - works if you don't have a picked card:
		if (command == "BoardButton") {
			if (menu.SelectedCard) {
				if (pk_debugmessages)
					Console.Printf("Pressing Close button but a selected card blocks it");
				return;
			}
			if (pk_debugmessages)
				Console.Printf("Pressing Close button");
			//if board opened for the first time in the map, show a yes/no prompt:
			if (menu.firstUse)
				menu.ShowExitPopup();	
			//otherwise just close the board  immediately
			else {
				menu.CloseBoard();
			}
			return;
		}
		if (menu.promptPopup && menu.promptPopup.isEnabled()) {
			if (pk_debugmessages)
				Console.Printf("Prompt active: do nothing");
			return;
		}
		if (command == "CloseFirstUse" && menu.firstUsePopup) {
			S_StartSound("ui/menu/open",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			menu.firstUsePopup.Unpack();
			menu.firstUsePopup.Destroy();
		}
		
		if (command == "ShowRefreshPopup") {
			menu.ShowRefreshPopup();
		}
		
		//card slot: if you have a card picked and click the slot, the card will be placed in it and scaled up to its size:		
		if (command == "CardSlot") {
			if (pk_debugmessages)
				Console.Printf("Clicking card equip slot");
			let cardslot = PKCCardSlot(Caller);
			//check if there's a selected card
			if (menu.SelectedCard) {
				//get pointer to selected card:
				let card = PKCTarotCard(menu.SelectedCard);
				//get pointer to previously placed card if there is one:
				PKCTarotCard placedcard = (cardslot.placedcard) ? PKCTarotCard(cardslot.placedcard) : null;
				//proceed if slot type matches card type (silver/gold) and there's no placed card OR there is one but it's not locked:
				if (card.slottype == cardslot.slottype && (!placedcard || !placedcard.cardlocked)) {
					ReturnCard(placedcard);
					EquipCard(card, cardslot);
					sound snd = (cardslot.slottype) ? "ui/board/placegold" : "ui/board/placesilver";
					S_StartSound(snd,CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				}
				//otherwise do nothing:
				else {
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				}
			}
			//otherwise check if there's a card in the slot; if there is, pick it up and attach to mouse pointer
			else if (cardslot.placedcard) {
				let card = PKCTarotCard(cardslot.placedcard);
				//do nothing if the card is locked in the slot
				if (card.cardlocked) {
					menu.ShowPurchasePopup(card,true);
					return;
				}
				else {
					card.SetBox(card.GetPos(),  card.defaultsize);
					card.buttonscale = card.defaultscale;
					S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					cardslot.placedcard = null;
					menu.SelectedCard = card;
					//move it to the top of the elements array so that it's rendered on the top layer:
					menu.boardelements.moveElement(menu.boardelements.indexOfElement(card), menu.boardelements.elementCount() - 1);
					EventHandler.SendNetworkEvent("PKCClearSlot",cardslot.slotID);
				}
			}
			return;
		}
		//clicking the card: attaches card to mouse pointer, or, if you already have one and you click *anywhere* where there's no card slot, the card will jump back to its original slot:
		if (command == "HandleCard") {
			let card = PKCTarotCard(Caller);
			if (!menu.SelectedCard && !card.cardbought) {
				menu.ShowPurchasePopup(card);
				return;
			}
			//don't do anything if you're hovering over a valid slot: we don't want placing into slot and clicking the card to happen at the same time
			if (hoveredslot) {
				return;
			}
			//if not hovering over slot, take card and attach it to the mouse pointer
			if (!menu.SelectedCard) {
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.boardelements.moveElement(menu.boardelements.indexOfElement(card), menu.boardelements.elementCount() - 1);
				//card.setDontBlockMouse(true);
			}
			//if we already have a card, put it back
			else {
				S_StartSound("ui/board/returncard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				card.SetBox(card.defaultpos, card.GetSize());
				menu.SelectedCard = null;
			}
		}
	}
	
	override void elementHoverChanged(PKZFElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		if (menu.promptPopup)
			return;
		if (!caller || !caller.isEnabled())
			return;
		//play sound of hovering over the exit button:
		if (command == "BoardButton" && !menu.SelectedCard) {
			if (!unhovered) {
				S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			}
		}
		
		//hovered over equip slots:
		if (command == "CardSlot") {
			if (!unhovered) {
				if (pk_debugmessages > 1)
					Console.Printf("Hovering over equip slot");
				hoveredslot = PKCCardSlot(Caller); //record covered slot
				//show gold info:
				if (hoveredslot.slottype == 1) {
					if (menu.goldSlotsInfo && menu.goldSlotsInfo.isHidden())
						menu.goldSlotsInfo.Show();
					menu.boardelements.moveElement(menu.boardelements.indexOfElement(menu.goldSlotsInfo), menu.boardelements.elementCount() - 1);
				}
				//show silver info:
				else {
					if (menu.silverSlotsInfo && menu.silverSlotsInfo.isHidden())
						menu.silverSlotsInfo.Show();
					menu.boardelements.moveElement(menu.boardelements.indexOfElement(menu.silverSlotsInfo), menu.boardelements.elementCount() - 1);
				}
			}
			//hide info tips:
			else {
				if (pk_debugmessages > 1)
					Console.Printf("No longer hovering over equip slot");
				hoveredslot = null; //no hovered slot
				if (menu.goldSlotsInfo)
					menu.goldSlotsInfo.Hide();
				if (menu.silverSlotsInfo)
					menu.silverSlotsInfo.Hide();
			}
		}
		
		//keep track of the cards we're hovering:
		if (command == "HandleCard") {
			let card = PKCTarotCard(Caller);
			if (!unhovered) {
				if (pk_debugmessages > 1)
					Console.Printf("Hovering over %s",card.cardname);
				menu.HoveredCard = card;
			}
			else {
				if (pk_debugmessages > 1)
					Console.Printf("No longer hovering over %s",card.cardname);
				menu.HoveredCard = null;
			}
		}
	}
	
	void ReturnCard(PKCTarotCard card) {
		if (!card)
			return;
		if (pk_debugmessages)
			Console.Printf("Returning %s to its default slot", card.cardID);
		card.SetBox(card.defaultpos, card.defaultsize);
		card.buttonscale = card.defaultscale;
		//card.setDontBlockMouse(false);
	}
	
	void EquipCard(PKCTarotCard card, PKCCardSlot cardslot) {		
		if (!card || !cardslot)
			return;
		if (pk_debugmessages)
			Console.Printf("Equipping %s into a slot", card.cardID);
		card.SetBox(cardslot.slotpos, cardslot.slotsize);
		card.buttonscale = (1,1);
		//card.setDontBlockMouse(false);
		cardslot.placedcard = card;
		string eventname = String.Format("PKCCardToSlot:%s",card.cardID);
		EventHandler.SendNetworkEvent(eventname,cardslot.slotID);
		if (menu) {
			menu.DeselectCard(); //detach from cursor
		}
	}
	
	// If for some reason the card ends up not in its default slot and not in any of the equip slots, reset it:
	void ResetCardPos(PKCTarotCard card) {
		if (!menu)
			return;
		//get pos and size:
		vector2 pos = card.GetPos();
		vector2 size = card.GetSize();
		//do nothing if the card is in its default position:
		if (pos == card.defaultpos && size == card.defaultsize)
			return;
		//iterate through slots and check if the card is in any of them:
		for (int i = 0; i < menu.cardslots.Size(); i++) {
			if (menu.cardslots[i]) {
				let placedcard = menu.cardslots[i].placedcard;
				if (placedcard && placedcard == card) {
					card.SetBox(menu.cardslots[i].slotpos, menu.cardslots[i].slotsize);
					card.buttonscale = (1,1);					
					return;
				}
			}
		}
		card.SetBox(card.defaultpos, card.defaultsize);
		card.buttonscale = card.defaultscale;
	}
}