Class PKCardsMenu : PKCGenericMenu {
	const BOARD_WIDTH = 1024;
	const BOARD_HEIGHT = 768;
	double backgroundRatio;
	vector2 boardTopLeft;
	
	PKCMenuHandler handler;
	PKCCardButton SelectedCard;
	PKCCardButton HoveredCard;
	
	PKCFrame cardinfo;	
	
	void ShowCardToolTip(PKCCardButton card) {				
		vector2 tippos = (62,430);
		vector2 tipsize = (378,173);
		
		cardinfo = new("PKCFrame").Init(tippos,tipsize);
		cardinfo.pack(mainframe);	
		
		let outline = new("PKCImage").Init(
			(0,0),
			tipsize,
			"graphics/Tarot/tooltip_bg_outline.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		outline.Pack(cardinfo);
		
		vector2 intofs = (4,4);
		let bkg = new("PKCImage").Init(
			intofs,
			tipsize-(intofs*2),
			"graphics/Tarot/tooltip_bg.png",
			imagescale:(1.6,1.6),
			tiled:true
		);
		bkg.Pack(cardinfo);
		
		vector2 tiptextofs = intofs+(8,5);		
		string title = Stringtable.Localize(card.cardname);
		string desc = Stringtable.Localize(card.carddesc);
		let cardname = new("PKCLabel").Init(
			tiptextofs,
			tipsize-tiptextofs,
			String.Format("%s",title),
			font_times,
			textscale:1.2,
			textcolor: Font.FindFontColor('PKRedText')
		);
		cardname.Pack(cardinfo);		
		
		let tiptext = new("PKCLabel").Init(
			tiptextofs+(0,32),
			tipsize-tiptextofs,
			String.Format("%s",desc), 
			font_times,
			textscale:1,
			textcolor: Font.FindFontColor('PKBaseText'),
			linespacing: 0.1
		);
		tiptext.Pack(cardinfo);	
	}
	
	override void Init (Menu parent) {
		super.Init(parent);
		
		/*vector2 screensize = (Screen.GetWidth(),screen.GetHeight());		
		SetBaseResolution(screensize);
		backgroundRatio = screensize.y / BOARD_HEIGHT;
		vector2 backgroundsize = (BOARD_WIDTH*backgroundRatio,BOARD_HEIGHT*backgroundRatio);
		boardTopLeft = */
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

		handler = new("PKCMenuHandler");
		handler.menu = self;
		
		let exitbutton = PKCExitButton(new("PKCExitButton")).Init(
			(511,196),
			(173,132),
			cmdhandler:handler,
			command:"BoardButton"
		);
		exitbutton.SetTexture(
			"Graphics/Tarot/board_button_highlighted.png",
			"Graphics/Tarot/board_button_highlighted.png",
			"",""
		);
		exitbutton.Pack(mainFrame);
		
		SlotsInit();
		CardsInit();
	}
	
	static const int PKCSilverSlots[] = {	58, 230 };
	static const int PKCGoldSlots[] 	= { 488, 658, 828 };
	private void SlotsInit() {
		vector2 slotsize = (138,227);	
		for (int i = 0; i < PKCSilverSlots.Size(); i++) {			
			vector2 slotpos = (PKCSilverSlots[i],179);
			let cardslot = PKCCardSlot(new("PKCCardSlot"));
			cardslot.Init(
				slotpos,
				slotsize,
				cmdhandler:handler,
				command:"CardSlot"
			);
			cardslot.SetTexture(
				"","","",""
			);
			cardslot.slotpos = slotpos;
			cardslot.slotsize = slotsize;
			cardslot.slottype = false;
			cardslot.Pack(mainFrame);
		}

		for (int i = 0; i < PKCGoldSlots.Size(); i++) {
			vector2 slotpos = (PKCGoldSlots[i],364);
			let cardslot = PKCCardSlot(new("PKCCardSlot"));
			cardslot.Init(
				slotpos,
				slotsize,
				cmdhandler:handler,
				command:"CardSlot"
			);
			cardslot.SetTexture(
				"","","",""
			);
			cardslot.slotpos = slotpos;
			cardslot.slotsize = slotsize;
			cardslot.slottype = true;
			cardslot.Pack(mainFrame);
		}
	}
	static const string PKCSilverCardNames[] = {
		"$SOULKEEPER_NAME",
		"$BLESSING_NAME",
		"$REPLENISH_NAME",
		"$DARKSOUL_NAME",
		"$SOULCATCHER_NAME",
		"$FORGIVENESS_NAME",
		"$GREED_NAME",
		"$SOULREDEEMER_NAME",
		"$REGENERATION_NAME",
		"$HEALTHSTEALER_NAME",
		"$HELLISHARMOR_NAME",
		"$666AMMO_NAME"
	};
	static const string PKCSilverCardDescs[] = {
		"$SOULKEEPER_DESC",
		"$BLESSING_DESC",
		"$REPLENISH_DESC",
		"$DARKSOUL_DESC",
		"$SOULCATCHER_DESC",
		"$FORGIVENESS_DESC",
		"$GREED_DESC",
		"$SOULREDEEMER_DESC",
		"$REGENERATION_DESC",
		"$HEALTHSTEALER_DESC",
		"$HELLISHARMOR_DESC",
		"$666AMMO_DESC"
	};
	static const name PKCSilverCards[] = {
		"SoulKeeper",
		"Blessing",
		"Replenish",
		"DarkSoul",
		"SoulCatcher",
		"Forgiveness",
		"Greed",
		"SoulRedeemer",
		"HealthRegeneration",
		"HealthStealer",
		"HellishArmor",
		"666Ammo"
	};
	static const string PKCGoldCardNames[] = {
		"$ENDURANCE_NAME",
		"$TIMEBONUS_NAME",
		"$SPEED_NAME",
		"$REBIRTH_NAME",
		"$CONFUSION_NAME",
		"$DEXTERITY_NAME",
		"$WMODIFIER_NAME",
		"$SOT_NAME",
		"$RAGE_NAME",
		"$MAGICGUN_NAME",
		"$IRONWILL_NAME",
		"$HASTE_NAME"
	};
	static const string PKCGoldCardDescs[] = {
		"$ENDURANCE_DESC",
		"$TIMEBONUS_DESC",
		"$SPEED_DESC",
		"$REBIRTH_DESC",
		"$CONFUSION_DESC",
		"$DEXTERITY_DESC",
		"$WMODIFIER_DESC",
		"$SOT_DESC",
		"$RAGE_DESC",
		"$MAGICGUN_DESC",
		"$IRONWILL_DESC",
		"$HASTE_DESC"
	};
	static const name PKCGoldCards[] = {
		"Endurance",
		"TimeBonus",
		"Speed",
		"Rebirth",
		"Confusion",
		"Dexterity",
		"WeaponModifier",
		"StepsOfThunder",
		"Rage",
		"MagicGun",
		"IronWill",
		"Haste"
	};
	static const int PKCCardXPos[] = { 56, 135, 214, 291, 369, 447, 525, 604, 682, 759, 835, 913 };
	
	private void CardsInit() {				
		vector2 cardsize = (55,92);
		vector2 cardscale = (0.4,0.407);
		
		for (int i = 0; i < PKCSilverCards.Size(); i++) {
			vector2 cardpos = (PKCCardXPos[i],56);
			let card = PKCCardButton(new("PKCCardButton"));
			card.Init(
				cardpos,
				cardsize,
				cmdhandler:handler,
				command:"HandleCard"
			);
			string texpath = String.Format("graphics/Tarot/cards/%s.png",PKCSilverCards[i]);
			card.SetTexture(texpath, texpath, texpath, "");
			card.buttonScale = cardscale;
			card.defaultscale = cardscale;
			card.defaultpos = cardpos;
			card.defaultsize = cardsize;
			card.slottype = false;
			card.cardname = PKCSilverCardNames[i];
			card.carddesc = PKCSilverCardDescs[i];
			card.Pack(mainFrame);
		}
		
		for (int i = 0; i < PKCGoldCards.Size(); i++) {
			vector2 cardpos = (PKCCardXPos[i],618);
			let card = PKCCardButton(new("PKCCardButton"));
			card.Init(
				cardpos,
				cardsize,
				cmdhandler:handler,
				command:"HandleCard"
			);
			string texpath = String.Format("graphics/Tarot/cards/%s.png",PKCGoldCards[i]);
			card.SetTexture(texpath, texpath, texpath, "");
			card.buttonScale = cardscale;
			card.defaultscale = cardscale;
			card.defaultpos = cardpos;
			card.defaultsize = cardsize;
			card.slottype = true;
			card.cardname = PKCGoldCardNames[i];
			card.carddesc = PKCGoldCardDescs[i];
			card.Pack(mainFrame);
		}
	}
	
	override void Ticker() {
		super.Ticker();
		if (SelectedCard) {			
			SelectedCard.box.pos = mainframe.screenToRel((mouseX,mouseY)) - SelectedCard.box.size / 2;
		}
		if (!cardinfo && HoveredCard && !SelectedCard)
			ShowCardToolTip(HoveredCard);
		if (cardinfo && (!HoveredCard || SelectedCard)) {
			cardinfo.unpack();
			cardinfo.destroy();
		}
	}
}

Class PKCExitButton : PKCButton {
	double aalpha;
	int alphadir;
	double hovered;
	override void drawer() {
		string texture = btnTextures[curButtonState];
		if (aalpha <= 0.25)
			alphadir = 1;
		else if (aalpha >= 1)
			alphadir = -1;
		aalpha = Clamp(aalpha+0.05*alphadir,0.25,1.0);
		drawTiledImage((0, 0), box.size, texture, true, alpha: hovered ? 1.0 : aalpha);
	}
}

Class PKCCardSlot : PKCButton {
	vector2 slotpos;
	vector2 slotsize;
	PKCButton placedcard;
	bool slottype;
}

//same as original Button but also takes an buttonScale argument
Class PKCCardButton : PKCButton {
	vector2 buttonScale;
	vector2 defaultpos;
	vector2 defaultsize;
	vector2 defaultscale;
	bool slottype;
	string cardname;
	string carddesc;
	override void drawer() {
		if (singleTex) {
			string texture = btnTextures[curButtonState];
			TextureID tex = TexMan.checkForTexture(texture, TexMan.Type_Any);
			Vector2 imageSize = TexMan.getScaledSize(tex);			
			imageSize.x *= buttonScale.x;
			imageSize.y *= buttonScale.y;
			drawTiledImage((0, 0), box.size, texture, true, buttonScale);
		}
		else {
			PKCBoxTextures textures = textures[curButtonState];
			drawBox((0, 0), box.size, textures, true);
		}

		// draw the text in the middle of the button
		Vector2 textSize = (fnt.stringWidth(text), fnt.getHeight()) * textScale;
		Vector2 textPos = (box.size - textSize) / 2;
		drawText(textPos, fnt, text, textColor, textScale);
	}
}

Class PKCMenuHandler : PKCHandler {
	PKCardsMenu menu;
	PKCCardSlot hoveredslot;
	
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		//exit button - works if you don't have a picked card:
		if (command == "BoardButton" && !menu.SelectedCard) {			
			S_StartSound("ui/board/click",CHAN_AUTO,CHANF_UI);
			menu.Close();			
		}
		//card slot: if you have a card picked and click the slot, the card will be placed in it and scaled up to its size:
		if (command == "CardSlot") {			
			let cardslot = PKCCardSlot(Caller);
			//check if there's a selected card AND if the card's type matches the slot's:
			if (menu.SelectedCard && menu.SelectedCard.slottype == cardslot.slottype) {
				let card = PKCCardButton(menu.SelectedCard);
				menu.SelectedCard = null;
				card.box.pos = cardslot.slotpos;
				card.box.size = cardslot.slotsize;
				card.buttonscale = (1,1);
				//if there's a card place in the slot, move that card back to its default pos first, then place this one
				if (cardslot.placedcard) {
					let placedcard = PKCCardButton(cardslot.placedcard);
					placedcard.box.size = placedcard.defaultsize;
					placedcard.box.pos = placedcard.defaultpos;
					placedcard.buttonscale = placedcard.defaultscale;
				}
				cardslot.placedcard = card;
				sound snd = (cardslot.slottype) ? "ui/board/placegold" : "ui/board/placesilver";
				S_StartSound(snd,CHAN_AUTO,CHANF_UI);
			}
			//otherwise check if there's a card in the slot; if there is, pick it up and attach to mouse pointer
			else if (cardslot.placedcard) {
				let card = PKCCardButton(cardslot.placedcard);
				card.box.size = card.defaultsize;
				card.buttonscale = card.defaultscale;
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI);
				cardslot.placedcard = null;
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.mainframe.elements.delete(menu.mainframe.elements.find(card));
				menu.mainframe.elements.push(card);
			}
		}
		//clicking the card: attaches card to mouse pointer, or, if you already have one and you click *anywhere* where there's no card slot, the card will jump back to its original slot:
		if (command == "HandleCard") {
			let card = PKCCardButton(Caller);
			//don't do anything if you're hovering over a valid slot: we don't want placing into slot and clicking the card to happen at the same time
			if (hoveredslot) {
				//if clicking over incorrect slot color, don't jump back but instead play "wrong slot" sound
				if(hoveredslot.slottype != card.slottype)
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI);
				return;
			}
			//if not hovering over slot, take card and attach it to the menu
			if (!menu.SelectedCard) {
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI);
				menu.SelectedCard = card;
				//move it to the top of the elements array so that it's rendered on the top layer:
				menu.mainframe.elements.delete(menu.mainframe.elements.find(card));
				menu.mainframe.elements.push(card);
			}
			//if we already have a card, put it back
			else {
				S_StartSound("ui/board/returncard",CHAN_AUTO,CHANF_UI);
				card.box.pos = card.defaultpos;
				menu.SelectedCard = null;
			}
		}
	}
	
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		//play sound of hovering over the exit button:
		if (command == "BoardButton" && !menu.SelectedCard) {
			let button = PKCExitButton(caller);
			if (!unhovered) {
				button.hovered = true;
				S_StartSound("ui/board/hover",CHAN_AUTO,CHANF_UI);
			}
			else
				button.hovered = false;
		}
		//keep track of slots we're hovering over:
		if (command == "CardSlot") {
			if (!unhovered)
				hoveredslot = PKCCardSlot(Caller);
			else
				hoveredslot = null;
		}
		if (command == "HandleCard") {
			let card = PKCCardButton(Caller);
			if (!unhovered)
				menu.HoveredCard = card;
			else
				menu.HoveredCard = null;
		}
	}
}

Class PKCardsMenuHandler : EventHandler {
	override void WorldThingSpawned(Worldevent e) {
		if (e.thing && e.thing == players[consoleplayer].mo)
			Menu.SetMenu("PKCardsMenu");
	}
}