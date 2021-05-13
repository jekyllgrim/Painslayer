/*======================================

  Black Tarot Board for GZDoom
  by Jekyll Grim Payne aka Agent_Ash
  
  The following menu is coded based on 
  ZForms menu library by Gutawer.

======================================*/



Class PKCardsMenu : PKCGenericMenu {
	const BOARD_WIDTH = 1024;
	const BOARD_HEIGHT = 768;
	const MENUTEXTSCALE = 1;
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
	
	PKCFrame silverSlotsInfo;
	PKCFrame goldSlotsInfo;
	
	PKCFrame boardElements;		//everything in the board except the background and popups
	PKCBoardMessage cardinfo;		//card information popup
	PKCBoardMessage promptPopup;	//an exit or purchase popup that blocks the board
	PKCBoardMessage firstUsePopup;	//first use notification
	PKCBoardMessage needMousePopup;	//need mouse notification
	int firstUsePopupDur;				//first use notification display duration
	int needMousePopupDur;			//need mouse notification display duration
	
	PKCButton exitbutton;			//big round flashing menu close button
	bool ExitHovered;				//whether it's hovered
	int ExitAlphaDir;
	
	bool firstUse;
	
	bool queueForClose;
	
	override void Init (Menu parent) {
		super.Init(parent);
		
		/*vector2 screensize = (Screen.GetWidth(),screen.GetHeight());		
		SetBaseResolution(screensize);
		backgroundRatio = screensize.y / BOARD_HEIGHT;
		vector2 backgroundsize = (BOARD_WIDTH*backgroundRatio,BOARD_HEIGHT*backgroundRatio);
		boardTopLeft = */
		
		
		//checks if the board is opened for the first time on the current map:
		let plr = players[consoleplayer].mo;
		if (!plr || plr.health < 0) {
			queueForClose = true;
			return;
		}
		goldcontrol = PK_CardControl(plr.FindInventory("PK_CardControl"));
		if (!goldcontrol || goldcontrol.goldActive) {
			queueForClose = true;
			return;
		}
		menuEHandler = PK_BoardEventHandler(EventHandler.Find("PK_BoardEventHandler"));
		if (menuEHandler && CVar.GetCVar('m_use_mouse',players[consoleplayer]).GetInt() > 0) {
			if (!menuEHandler.boardOpened) {
				firstUse = true;
				menuEHandler.boardOpened = true;
			}
			else
				firstUse = false;
		}
		
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
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
		
		//clicking anywhere on the board is supposed to close the First Use popup:
		let closeFirstUseBtn = new("PKCButton").Init(
			(0,0),
			backgroundsize,
			cmdhandler:handler,
			command:"CloseFirstUse"
		);
		closeFirstUseBtn.SetTexture( "", "", "", "" );
		closeFirstUseBtn.Pack(boardElements);
		
		if (CVar.GetCVar('m_use_mouse',players[consoleplayer]).GetInt() <= 0) {
			string str = String.Format(Stringtable.Localize("$TAROT_NEEDMOUSE"),Stringtable.Localize("$OPTMNU_TITLE"),Stringtable.Localize("$OPTMNU_MOUSE"),Stringtable.Localize("$MOUSEMNU_MOUSEINMENU"));
			needMousePopup = New("PKCBoardMessage");
			needMousePopup.pack(mainFrame);
			needMousePopup.Init(
				(192,256),
				(700,256),
				str,
				textscale:MENUTEXTSCALE*1.2
			);
			needMousePopupDur = 800;
			return;
		}
		
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
		SlotInfoInit(); //hover text with info about slots
		
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
	PKCCardSlot cardslots[5];
	
	private void SlotsInit() {
		vector2 slotsize = (138,227);	
		for (int i = 0; i < 5; i++) {			
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

			if (goldcontrol) {
				//check if the card is already unlocked:
				if (goldcontrol.UnlockedTarotCards.Find(int(name(card.cardID))) != goldcontrol.UnlockedTarotCards.Size()) {
					//console.printf("%s is bought",card.cardID);
					card.cardbought = true;
				}
				//check if the card is already equipped, and if so, place it in that slot:
				for (int i = 0; i < cardslots.Size(); i++) {
					if (goldcontrol.EquippedSlots[i] == card.cardID) {
						let cardslot = cardslots[i];
						card.box.pos = cardslot.slotpos;
						card.box.size = cardslot.slotsize;
						card.buttonscale = (1,1);
						cardslot.placedcard = card;
						if (!firstUse)
							card.cardlocked = true;
					}
				}
			}
			
		}
		//unlock 2 random silver and 3 random gold cards if you have none unlocked ("pistol start"):	
		if (goldcontrol && goldcontrol.UnlockedTarotCards.Size() == 0) {
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
				textscale:MENUTEXTSCALE* 1.2,
				alignment: PKCElement.AlignType_HCenter
			);
			firstUsePopupDur = 120;	//"first use" message is temporary
			
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
					//elementsEHandler.UnlockedTarotCards.push(int(name(card.cardID)));
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
					//elementsEHandler.UnlockedTarotCards.push(int(name(card.cardID)));
					string eventname = String.Format("PKCBuyCard:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname);
				}
			}
		}
	}
	
	//make sound, call netevent to activate equipped cards, close the board
	void PKCCloseBoard() {
		S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		EventHandler.SendNetworkEvent('PKCCloseBoard');
		Close();
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
			text:Stringtable.Localize("$TAROT_YES"),
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
			text:Stringtable.Localize("$TAROT_NO"),
			cmdhandler:promptHandler,
			command:"CancelPrompt",
			fnt:font_times,
			textscale:MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		noButton.SetTexture("","","","");
		noButton.pack(promptPopup);
	}

	void ShowPurchasePopup(PKCTarotCard card, bool unequip = false) {
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
		
		string purchaseLine;
		if (!unequip)
			purchaseLine = (gold >= card.cardcost) ? Stringtable.Localize("$TAROT_PURCHASE") : Stringtable.Localize("$TAROT_CANTPURCHASE");
		else
			purchaseLine = (gold >= card.cardcost) ? Stringtable.Localize("$TAROT_PAYTOUNEQUIP") : Stringtable.Localize("$TAROT_CANTUNEQUIP");
		vector2 purchaseTextofs = (16,16);	
		let purchaseText = new("PKCLabel").Init(
			purchaseTextofs+(0,40),
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
				text:Stringtable.Localize("$TAROT_YES"),
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
				text:Stringtable.Localize("$TAROT_NO"),
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
				text:Stringtable.Localize("$TAROT_CLOSE"),
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
			
		let cardcost = new("PKCLabel").Init(
			tiptextofs+(185,0),
			(160,64),
			String.Format("%d%s",card.cardcost,Stringtable.Localize("$TAROT_GOLDABR")), 
			font_times,
			alignment:PKCElement.AlignType_TopRight,
			textscale:1,
			textcolor: Font.FindFontColor('PKGreenText'),
			linespacing: 0.1
		);
		cardcost.Pack(cardinfo);	
	}

    override bool MenuEvent (int mkey, bool fromcontroller) {
        if (mkey == MKEY_Back) {
			//show "mouse needed" message if no mouse detected
			if (needMousePopup) {
				S_StartSound("ui/board/exit",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				PKCCloseBoard();
				return true;
			}
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
				PKCCloseBoard();
				return true;
			}
		}
		return false;
    }
	
	void DeselectCard() {
		selectedCard = null;
	}
	
	override void Ticker() {
		if (queueForClose) {
			Close();
			return;
		}
		if ((promptPopup && promptPopup.isEnabled()) || needMousePopup) {
			boardElements.disabled = true;
		}
		else {
			boardElements.disabled = false;
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
					SelectedCard.box.pos = cardslot.slotpos;
					SelectedCard.box.size = cardslot.slotsize;
					SelectedCard.buttonscale = (1,1);
					selectedCard = null;
					break;
				}
			}
			if (selectedCard) {
				SelectedCard.box.pos = boardelements.screenToRel((mouseX,mouseY)) - SelectedCard.box.size / 2;
			}
		}
		//show card info if mouse hovers over a card and there's no card selected:
		if (!cardinfo && HoveredCard && HoveredCard.isEnabled() && !HoveredCard.hidden && !SelectedCard)
			ShowCardToolTip(HoveredCard);
		//as soon as you hover off the card, immediately remove card info:
		if (cardinfo && (!HoveredCard || !HoveredCard.isEnabled() || HoveredCard.hidden || SelectedCard)) {
		//It's actually not a good idea to continuously create and destroy stuff like that, I simply designed it like this initially and it was too bothersome  to redo.
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
	PK_CardControl goldcontrol;	//this item holds the amount of gold
	PKCImage GoldDigits[6]; //there's a total of 6 digits
	vector2 DigitPos[6];
	//digits are not spaced totally evently, so we define their X pos explicitly:
	static const int PKCGoldDigitXPos[] = { -3, 24, 53, 82, 111, 141 };
	int PKCGoldDigitYPos[6];
	
	DynamicValueInterpolator GoldInterpolator[6];
	
	PKCGoldCounter init(Vector2 pos, Vector2 size) {
		self.setBox(pos, size);
		self.alpha = 1;
		
		//the rightmost digit of the counter is always 0 since max gold is 99990, so we just draw it here and don't modify it further:
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
		goldcontrol = PK_CardControl(players[consoleplayer].mo.FindInventory("PK_CardControl"));

		return self;
	}
	
	override void ticker() {
		super.ticker();
		if (!goldcontrol)
			return;		
		int gold = goldcontrol.pk_gold; //check how much gold we have
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
			let img = new("PKCImage");
			img.pack(self);
			img.Init(
				digitpos,
				digitsize,
				"PKCNUMS"
			);
			if (newY != targetYofs && abs((newY+5) % 64) <= 4)
				S_StartSound("ui/board/digitchange",CHAN_VOICE,CHANF_UI|CHANF_NOSTOP,volume:snd_menuvolume);
		
			GoldDigits[i] = img;
			
			gold /= 10; //with this the next targetYofs will check the next digit in the number
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
		//fade the card out if it's locked (equipped in a slot and the board has already been used in this map)
		if (cardlocked)
			drawTiledImage((0, 0), box.size, "graphics/Tarot/tooltip_bg.png", true, buttonScale,alpha: 0.4);
		
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
			menu.PKCCloseBoard();
			return;
		}
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
	//PK_BoardElementsHandler elementsEHandler;
		
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
				menu.PKCCloseBoard();
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
				//get pointer to selected card:
				let card = PKCTarotCard(menu.SelectedCard);
				//get pointer to previously placed card if there is one:
				PKCTarotCard placedcard = (cardslot.placedcard) ? PKCTarotCard(cardslot.placedcard) : null;
				//proceed if slot type matches to card type (silver/gold) and there's no placed card OR there is one but it's not locked:
				if (card.slottype == cardslot.slottype && (!placedcard || !placedcard.cardlocked)) {
					card.box.pos = cardslot.slotpos;
					card.box.size = cardslot.slotsize;
					card.buttonscale = (1,1);
					menu.SelectedCard = null; //detach from cursor
					//if there was a card placed in the slot, move that card back to its default pos before placing this one
					if (placedcard) {
						placedcard.box.size = placedcard.defaultsize;
						placedcard.box.pos = placedcard.defaultpos;
						placedcard.buttonscale = placedcard.defaultscale;
					}
					//attach the card to slot
					cardslot.placedcard = card;
					sound snd = (cardslot.slottype) ? "ui/board/placegold" : "ui/board/placesilver";
					S_StartSound(snd,CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					string eventname = String.Format("PKCCardToSlot:%s",card.cardID);
					EventHandler.SendNetworkEvent(eventname,cardslot.slotID);
				}
				//otherwise do nothing:
				else {
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				}
				return;
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
					card.box.size = card.defaultsize;
					card.buttonscale = card.defaultscale;
					S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
					cardslot.placedcard = null;
					menu.SelectedCard = card;
					//move it to the top of the elements array so that it's rendered on the top layer:
					menu.boardelements.elements.delete(menu.boardelements.elements.find(card));
					menu.boardelements.elements.push(card);
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
				//if clicking over incorrect slot color, don't jump back but instead play "wrong slot" sound
				if(hoveredslot.slottype != card.slottype)
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
				return;
			}
			//if not hovering over slot, take card and attach it to the mouse pointer
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
					if (menu.goldSlotsInfo)
						menu.goldSlotsInfo.hidden = false;
					menu.boardelements.elements.delete(menu.boardelements.elements.find(menu.goldSlotsInfo));
					menu.boardelements.elements.push(menu.goldSlotsInfo);
				}
				else {
					if (menu.silverSlotsInfo)
						menu.silverSlotsInfo.hidden = false;
					menu.boardelements.elements.delete(menu.boardelements.elements.find(menu.silverSlotsInfo));
					menu.boardelements.elements.push(menu.silverSlotsInfo);
				}
			}
			else {
				hoveredslot = null;
				if (menu.goldSlotsInfo)
					menu.goldSlotsInfo.hidden = true;
				if (menu.silverSlotsInfo)
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