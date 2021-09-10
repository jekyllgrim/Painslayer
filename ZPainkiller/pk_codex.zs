enum PKCodexTabs {
	PKCX_Weapons,
	PKCX_Powerups,
	PKCX_Gold,
	PKCX_Cards,
}

enum PKWeaponTabs {
	PKCX_PainKiller,
	PKCX_Shotgun,
	PKCX_Stakegun,
	PKCX_Chaingun,
	PKCX_ELD,
	PKCX_Rifle,
	PKCX_Boltgun
}

Class PKCodexMenu : PKZFGenericMenu {
	
	vector2 backgroundsize;
	PKCodexTabhandler tabhandler;
	PKZFFrame mainTabs[4];
	PKZFFrame weaponTabElements[7];
	
	vector2 infoSectionPos;
	vector2 infoSectionSize;
	
	static const string mainTabnames[] = {
		"WEAPONS",
		"POWERUPS",
		"GOLD",
		"TAROT"
	};

	PKZFTabButton, PKZFFrame CreateTab(vector2 pos, vector2 size, String text, PKZFRadioController controller, PKZFHandler handler, int value, vector2 framePos, vector2 frameSize, PKZFBoxTextures inactiveTex = null, PKZFBoxTextures activeTex = null, PKZFBoxTextures hoverTex = null, PKZFBoxTextures clickTex = null, double textScale = 1, int textColor = Font.CR_WHITE/*, PKZFElement.AlignType alignment = PKZFElementAlignType_Center*/) {
		let tabButton = PKZFTabButton.Create(
			pos,
			size,
			controller,
			value,
			inactive:inactiveTex,
			hover:(hoverTex ? hoverTex : inactiveTex),
			click:(clickTex ? clickTex : activeTex),
			text:text,
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*textscale,
			textColor: textColor,
			//alignment:alignment,
			cmdhandler:handler
		);
		let tabContents = PKZFFrame.Create(framePos,frameSize);
		tabButton.tabframe = tabContents;
		return tabButton, tabContents;
	}
	
	/*override void Drawer() {
		PK_StatusBarScreen.Fill("46382c",0,0,backgroundsize.x,backgroundsize.y,1);	
		super.Drawer();
	}*/
	
	override void Init (Menu parent) {
		super.Init(parent);
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//first create the background (always 4:3, never stretched)
		backgroundsize = (PK_BOARD_WIDTH,PK_BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);	
		
		tabhandler = new("PKCodexTabhandler");
		tabhandler.menu = self;
		
		//dark frame for inactive/non-interactive board elements:
		let lightFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut1.png",
			(10,9),
			(74,75),
			false, false
		);
		//light frame for active board elements:
		let darkFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut2.png",
			(10,9),
			(74,75),
			false, false
		);
		
		//background with a border:
		let backgroundBorder = PKZFBoxImage.Create((0,0), backgroundsize, darkFrame);
		backgroundBorder.pack(mainFrame);
		
		let bord = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbutn.png",
			(10,9),
			(74,75),
			false, false
		);
		
		//create tab buttons:
		let tabController = new("PKZFRadioController");	
		//hover, inactive and active button frames:
		let btnInactiveFrame = darkFrame;
		let btnHoverFrame = lightFrame;	
		let btnActiveFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut1.png",
			(10,0),
			(74,84),
			false, false
		);
		//define/calculate button positions, gaps between them and sizes:
		vector2 buttonpos = (32,32);
		double buttongap = buttonpos.x * 0.5;
		vector2 buttonsize = ( (backgroundsize.x - (buttonpos.x*2 + buttongap * 3)) / 4, 72);		
		//define Info section size and position:
		infoSectionPos = (buttonpos.x * 0.5, buttonpos.y + buttonsize.y - 9);
		infoSectionSize = (backgroundsize.x - infoSectionPos.x * 2, PK_BOARD_HEIGHT - infoSectionPos.y * 1.25);
		
		//create main tabs:
		vector2 nextBtnPos = buttonpos;
		for (int i = 0; i < mainTabs.Size(); i++) {
			PKZFTabButton tab; PKZFFrame tabframe;
			[tab, tabframe] = CreateTab(
				nextBtnPos, 
				buttonsize, 
				mainTabnames[i], 
				tabController, 
				tabhandler, 
				i,
				infoSectionPos, infoSectionSize,
				btnInactiveFrame, btnActiveFrame, btnHoverFrame,
				textScale: 1.25,
				textColor: Font.FindFontColor('PKBaseText')
			);
			nextBtnPos.x += buttonsize.x + buttongap;
			tab.Pack(mainFrame);
			tabframe.Pack(mainFrame);
			mainTabs[i] = tabframe;
			//tabhandler.tabframes.Push(tabframe);
		}
		
		//Draw border & background for the Info section:
		let sectionBorder = PKZFBoxImage.Create(infoSectionPos, infoSectionSize, lightFrame);
		sectionBorder.pack(mainFrame);		
		//move the Info section in front of the background but behind 
		//the buttons (so that the button bottoms can overlap its top edge)
		mainFrame.moveElement(mainFrame.indexOfElement(sectionBorder), mainFrame.indexOfElement(backgroundBorder)+1);
		
		//Create WEAPONS tab elements:
		WeaponsTabInit();
		
		
	}
		
	static const Class<Weapon> PK_Weapons[] = {
		"PK_Painkiller",
		"PK_Shotgun",
		"PK_Stakegun",
		"PK_Chaingun",
		"PK_ElectroDriver",
		"PK_Rifle",
		"PK_Boltgun"
	};
	
	//Create weapons tabs and a frame:
	void WeaponsTabInit() {		
		let wpnTabCont = new("PKZFRadioController"); //define a new controller
		let wpnTabHandler = tabhandler; //the handler can be reused
		vector2 btnPos = (24,24); //button positon
		double btnYgap = 24;						//vertical gap between buttons
		vector2 btnSize = (300,45);
		//Define weapon info section: has to be smaller than the info section so that it doesn't
		//cover the buttons themselves!
		vector2 wpnSectionPos = (btnPos.x + btnSize.x + 8, btnPos.y);
		vector2 wpnSectionSize = (infoSectionSize.x - wpnSectionPos.x, infoSectionSize.y);		
		//Define buttons with weapon names:
		for (int i = 0; i < weaponTabElements.Size(); i++) {
			PKZFTabButton tab; PKZFFrame tabframe;
			[tab, tabframe] = CreateTab(
				btnPos, 
				btnSize,
				GetDefaultByType(PK_Weapons[i]).GetTag(), //use weapon's tag as the button's name
				wpnTabCont,
				wpnTabHandler,				
				i,
				wpnSectionPos, wpnSectionSize,
				textscale:0.85
			);
			tab.Pack(mainTabs[0]);
			tabframe.Pack(mainTabs[0]);
			tab.setAlignment(PKZFElement.AlignType_CenterLeft);
			weaponTabElements[i] = tabframe;
			if (i == 0) {
				//let img = PKZFImage.Create((0,0),(283,189),"PCDXPAIN");
				//let img2 = PKZFImage.Create((0,169),(283,189),"PCDXKILL");
				let img = PKZFImage.Create((0,0),(200,159),"Graphics/HUD/Codex/CODX_PK_1.PNG");
				let img2 = PKZFImage.Create((0,170),(200,159),"Graphics/HUD/Codex/CODX_PK_2.PNG");
				let img3 = PKZFImage.Create((0,340),(200,159),"Graphics/HUD/Codex/CODX_PK_3.PNG");
				let text = PKZFLabel.Create((204,0),(420,170),
					"Hold Primary: Pain\n\nDeal continuous damage with the spinning blades.",
					fnt:font_times,
					textscale:PK_MENUTEXTSCALE*0.9,
					textColor:Font.FindFontColor('PKBaseText')
				);
				let text2 = PKZFLabel.Create((204,170),(420,170),
					"Tap Secondary: Killer\n\nFire the folded blade unit. The unit can stick into walls and creates a laser beam that burns enemies when you aim at it.\nNOTE: This attack can juggle corpses.",
					fnt:font_times,
					textscale:PK_MENUTEXTSCALE*0.9,
					textColor:Font.FindFontColor('PKBaseText')
				);
				let text3 = PKZFLabel.Create((204,340),(420,170),
					"Hold Primary, tap Secondary: Painkiller\n\nLaunch the spinning blades forward. This projectile is slow but deals a lot of damage on impact.",
					fnt:font_times,
					textscale:PK_MENUTEXTSCALE*0.9,
					textColor:Font.FindFontColor('PKBaseText')
				);
				img.pack(tabframe);
				img2.pack(tabframe);
				img3.pack(tabframe);
				text.pack(tabframe);
				text2.pack(tabframe);
				text3.pack(tabframe);
			}
			btnPos.y += (btnSize.y + btnYgap);
		}
	}
}

Class PKCodexTabhandler : PKZFHandler {
	PKCodexMenu menu;
	
	override void radioButtonChanged(PKZFRadioButton caller, string command, PKZFRadioController variable) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;  
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
	}
	override void elementHoverChanged(PKZFElement caller, string command, bool unhovered) {
		if (!menu || !caller || !caller.isEnabled())
			return;
		let btn = PKZFTabButton(caller);
		if (!btn) {
			/*let but = PKZFRadioButton(caller);			
			if (!unhovered) {
				but.SetTextColor(Font.FindFontColor('PKRedText'));
				S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			}
			else {
				but.SetTextColor(Font.CR_WHITE);
			}*/
			return;
		}
		if (!unhovered) {
			btn.SetTextColor(Font.FindFontColor('PKRedText'));
			S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		}
		else {
			btn.SetTextColor(btn.baseTextColor);
		}
	}
}

Class PKZFTabButton : PKZFRadioButton {
	PKZFFrame tabframe;
	int baseTextColor;
	
	static PKZFTabButton create(
		Vector2 pos, Vector2 size,
		PKZFRadioController variable, int value,
		PKZFBoxTextures inactive = NULL, PKZFBoxTextures hover = NULL,
		PKZFBoxTextures click = NULL, PKZFBoxTextures disabled = NULL,
		string text = "", Font fnt = font_times, double textScale = 1, int textColor = Font.CR_WHITE,
		AlignType alignment = AlignType_Center, PKZFHandler cmdHandler = NULL, string command = ""
	) {
		let ret = new('PKZFTabButton');
		ret.baseTextColor = textColor;
		ret.config(variable, value, inactive, hover, click, disabled, text, fnt, textScale, textColor, alignment, cmdHandler, command);
		ret.setBox(pos, size);

		return ret;
	}
	
	override void Drawer() {
		Super.Drawer();
		if (tabframe) {
			if (curButtonState == ButtonState_Click) {
				tabframe.Show();
				//tabframe.Enable();
			}
			else {
				tabframe.Hide();
				//tabframe.Disable();
			}
		}
	}	
}