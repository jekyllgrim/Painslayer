Class PKCardsMenu : PKCGenericMenu {
	const BOARD_WIDTH = 1024;
	const BOARD_HEIGHT = 768;
	double backgroundRatio;
	vector2 boardTopLeft;
	
	PKCMenuHandler handler;
	PKCCardButton SelectedCard;
	
	static const string PKCardTextures[] = {
		"graphics/Tarot/cards/Endurance.png",
		"graphics/Tarot/cards/Time_Bonus.png",
		"graphics/Tarot/cards/Speed.png",
		"graphics/Tarot/cards/Haste.png",
		"graphics/Tarot/cards/Dexterity.png",
		"graphics/Tarot/cards/Iron_Will.png",
		"graphics/Tarot/cards/Rage.png",
		"graphics/Tarot/cards/Weapon_Modifier.png",
		"graphics/Tarot/cards/Rebirth.png",
		"graphics/Tarot/cards/Confusion.png",
		"graphics/Tarot/cards/Magic_Gun.png"
	};
	
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
			image:"graphics/Tarot/cardsboard.tga"/*,
			imagescale:(1*backgroundRatio,1*backgroundRatio)*/
		);
		background.Pack(mainFrame);		

		handler = new("PKCMenuHandler");
		handler.menu = self;
		
		let exitbutton = new("PKCButton");
		exitbutton.Init(
			(511,196),
			(173,132),
			cmdhandler:handler,
			command:"BoardButton"
		);
		exitbutton.SetTexture(
			"graphics/Tarot/board_button.png",
			"graphics/Tarot/board_button_highlighted.png",
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
	static const int PKCCardXPos[] = { 
		56, 
		135, 
		214, 
		291, 
		369, 
		447, 
		525, 
		604, 
		682, 
		759, 
		835, 
		913 
	};
	
	private void CardsInit() {				
		vector2 cardsize = (55,92);
		vector2 cardscale = (0.4,0.4);
		
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
			card.cardname = PKCSilverCards[i];
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
			card.Pack(mainFrame);
		}
	}
	
	override void Ticker() {
		super.Ticker();
		if (SelectedCard) {			
			SelectedCard.box.pos = mainframe.screenToRel((mouseX,mouseY)) - SelectedCard.box.size / 2;
		}		
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
	name cardname;
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
			}
		}
		//clicking the card: attaches card to mouse pointer, or, if you already have one and you click *anywhere* where there's no valid card slot, the card will jump back to its original slot:
		if (command == "HandleCard") {
			let card = PKCCardButton(Caller);
			//don't do anything if you're hovering over a valid slot: we don't want placing into slot and clicking the card to happen at the same time
			if (hoveredslot) {
				if(hoveredslot.slottype != card.slottype)
					S_StartSound("ui/board/wrongplace",CHAN_AUTO,CHANF_UI);
				return;
			}
			if (!menu.SelectedCard) {
				S_StartSound("ui/board/takecard",CHAN_AUTO,CHANF_UI);
				menu.SelectedCard = card;
			}
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
		if (command == "BoardButton" && !unhovered && !menu.SelectedCard) {
			S_StartSound("ui/board/hover",CHAN_AUTO,CHANF_UI);
		}
		if (command == "CardSlot") {
			if (!unhovered)
				hoveredslot = PKCCardSlot(Caller);
			else
				hoveredslot = null;
		}
	}
}

Class PKCardsMenuHandler : EventHandler {
	override void WorldThingSpawned(Worldevent e) {
		if (e.thing && e.thing == players[consoleplayer].mo)
			Menu.SetMenu("PKCardsMenu");
	}
}