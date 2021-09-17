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
	
	PKZFBoxTextures lightFrame;
	PKZFBoxTextures darkFrame;
	
	bool showWMText;
	
	static const string mainTabnames[] = {
		"$PKC_WEAPONS",
		"$PKC_POWERUPS",
		"$PKC_GOLD",
		"$PKC_TAROT"
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
	
	override void Drawer() {
		//PK_StatusBarScreen.Fill("46382c",0,0,backgroundsize.x,backgroundsize.y,1);	
		super.Drawer();
		//console.printf("Show WM: %d",showWMText);
	}
	
	override void Init (Menu parent) {
		super.Init(parent);
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//first create the background (always 4:3, never stretched)
		backgroundsize = (PK_BOARD_WIDTH,PK_BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);	
		
		tabhandler = new("PKCodexTabhandler");
		tabhandler.menu = self;
		
		//dark frame for inactive/non-interactive board elements:
		lightFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut1.png",
			(10,9),
			(74,75),
			false, false
		);
		//light frame for active board elements:
		darkFrame = PKZFBoxTextures.createTexturePixels(
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
				StringTable.Localize(mainTabnames[i]),
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
	
	static const name PK_ModeCVars[] = {
		'pk_switch_Painkiller',
		'pk_switch_ShotgunFreezer',
		'pk_switch_StakeGrenade',
		'pk_switch_MinigunRocket',
		'pk_switch_ElectroDriver',
		'pk_switch_RifleFlamethrower',
		'pk_switch_BoltgunHeater'
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
				textscale:0.9
			);			
			btnPos.y += (btnSize.y + btnYgap);
			tab.Pack(mainTabs[0]);
			tabframe.Pack(mainTabs[0]);
			tab.setAlignment(PKZFElement.AlignType_CenterLeft);
			weaponTabElements[i] = tabframe;		
			
			//these will hold attack icons and descriptions
			string imgpath1;
			string imgpath2;
			string imgpath3;
			string text1; string alttext1;
			string text2; string alttext2;
			string text3;
			
			//cache the names "Primary" and "Secondary":
			string fire_name = StringTable.Localize("$PKC_Primary");
			string altfire_name = StringTable.Localize("$PKC_Secondary");
			
			//check if this weapon has its fire/altfire modes switched:
			bool modeswitch = CVar.GetCVar(PK_ModeCVars[i],Players[Consoleplayer]).GetBool();
			//if so, switch the words "Primary" and "Secondary":
			if (modeswitch) {
				string fire_name_sw = altfire_name;
				string altfire_name_sw = fire_name;
				fire_name = fire_name_sw;
				altfire_name = altfire_name_sw;
			}
			
			if (i == PKCX_PainKiller) {
				imgpath1 = "Graphics/HUD/Codex/CODX_PK_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_PK_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_PK_3.PNG";
				text1 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					fire_name,
					StringTable.Localize("$PKC_Pain"),
					StringTable.Localize("$PKC_PainDesc")
				);
				alttext1 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					fire_name,
					StringTable.Localize("$PKC_Pain"),
					StringTable.Localize("$PKC_PainDescWM")
				);
				text2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Tap"),
					altfire_name,
					StringTable.Localize("$PKC_Killer"),
					StringTable.Localize("$PKC_KillerDesc")
				);
				alttext2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Tap"),
					altfire_name,
					StringTable.Localize("$PKC_Killer"),
					StringTable.Localize("$PKC_KillerDescWM")
				);
				text3 = String.Format(
					"%s %s, %s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					fire_name,
					StringTable.Localize("$PKC_Tap").MakeLower(),
					altfire_name,
					StringTable.Localize("$PKC_Painkiller"),
					StringTable.Localize("$PKC_PainkillerDesc")
				);
			}
			if (i == PKCX_Shotgun) {
				imgpath1 = "Graphics/HUD/Codex/CODX_SH_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_SH_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_SH_3.PNG";
				text1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Shotgun"),
					StringTable.Localize("$PKC_ShotgunDesc")
				);
				alttext1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Shotgun"),
					StringTable.Localize("$PKC_ShotgunDescWM")
				);
				text2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Freezer"),
					StringTable.Localize("$PKC_FreezerDesc")
				);
				alttext2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Freezer"),
					StringTable.Localize("$PKC_FreezerDescWM")
				);
				text3 = String.Format(
					"%s, %s %s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_then"),
					fire_name,
					StringTable.Localize("$PKC_ShotgunFreezer"),
					StringTable.Localize("$PKC_ShotgunFreezerDesc")
				);
			}
			if (i == PKCX_Stakegun) {
				imgpath1 = "Graphics/HUD/Codex/CODX_ST_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_ST_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_ST_3.PNG";
				text1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Stakegun"),
					StringTable.Localize("$PKC_StakegunDesc")
				);
				alttext1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Stakegun"),
					StringTable.Localize("$PKC_StakegunDescWM")
				);
				text2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Grenade"),
					StringTable.Localize("$PKC_GrenadeDesc")
				);
				alttext2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Grenade"),
					StringTable.Localize("$PKC_GrenadeDescWM")
				);
				text3 = String.Format(
					"%s, %s %s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_then"),
					fire_name,
					StringTable.Localize("$PKC_StakeGrenade"),
					StringTable.Localize("$PKC_StakeGrenadeDesc")
				);
			}
			if (i == PKCX_Chaingun) {
				imgpath1 = "Graphics/HUD/Codex/CODX_CH_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_CH_2.PNG";
				imgpath3 = "";
				text1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_RLauncher"),
					StringTable.Localize("$PKC_RLauncherDesc")
				);
				alttext1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_RLauncher"),
					StringTable.Localize("$PKC_RLauncherDescWM")
				);
				text2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Chaingun"),
					StringTable.Localize("$PKC_ChaingunDesc")
				);
				alttext2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Chaingun"),
					StringTable.Localize("$PKC_ChaingunDescWM")
				);
				text3 = "";
			}
			if (i == PKCX_ELD) {
				imgpath1 = "Graphics/HUD/Codex/CODX_ED_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_ED_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_ED_3.PNG";
				text1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Driver"),
					StringTable.Localize("$PKC_DriverDesc")
				);
				alttext1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Driver"),
					StringTable.Localize("$PKC_DriverDescWM")
				);
				text2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Electro"),
					StringTable.Localize("$PKC_ElectroDesc")
				);
				alttext2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Electro"),
					StringTable.Localize("$PKC_ElectroDescWM")
				);
				text3 = String.Format(
					"%s %s, %s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Tap"),
					fire_name,
					StringTable.Localize("$PKC_ElectroDisc"),
					StringTable.Localize("$PKC_ElectroDiscDesc")
				);
			}
			if (i == PKCX_Rifle) {
				imgpath1 = "Graphics/HUD/Codex/CODX_RF_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_RF_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_RF_3.PNG";
				
				text1 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					fire_name,
					StringTable.Localize("$PKC_Rifle"),
					StringTable.Localize("$PKC_RifleDesc")
				);
				alttext1 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					fire_name,
					StringTable.Localize("$PKC_Rifle"),
					StringTable.Localize("$PKC_RifleDescWM")
				);
				text2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Flamer"),
					StringTable.Localize("$PKC_FlamerDesc")
				);
				alttext2 = String.Format(
					"%s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Flamer"),
					StringTable.Localize("$PKC_FlamerDescWM")
				);
				text3 = String.Format(
					"%s %s, %s %s: %s\n\n%s",
					StringTable.Localize("$PKC_Hold"),
					altfire_name,
					StringTable.Localize("$PKC_Tap").MakeLower(),
					fire_name,
					StringTable.Localize("$PKC_FlameTank"),
					StringTable.Localize("$PKC_FlameTankDesc")
				);
			}
			if (i == PKCX_Boltgun) {
				imgpath1 = "Graphics/HUD/Codex/CODX_BG_1.PNG";
				imgpath2 = "Graphics/HUD/Codex/CODX_BG_2.PNG";
				imgpath3 = "Graphics/HUD/Codex/CODX_BG_3.PNG";
				text1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Boltgun"),
					StringTable.Localize("$PKC_BoltgunDesc")
				);
				alttext1 = String.Format(
					"%s: %s\n\n%s",
					fire_name,
					StringTable.Localize("$PKC_Boltgun"),
					StringTable.Localize("$PKC_BoltgunDescWM")
				);
				text2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Heater"),
					StringTable.Localize("$PKC_HeaterDesc")
				);
				alttext2 = String.Format(
					"%s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_Heater"),
					StringTable.Localize("$PKC_HeaterDescWM")
				);
				text3 = String.Format(
					"%s, %s %s: %s\n\n%s",
					altfire_name,
					StringTable.Localize("$PKC_then"),
					fire_name,
					StringTable.Localize("$PKC_HeaterBolts"),
					StringTable.Localize("$PKC_HeaterBoltsDesc")
				);
			}
			
			//create attack description sections:
			double wpnInfoYGap = 32; //gap between attack descriptions
			vector2 wpnInfoBorderPos = (0,16);
			vector2 wpnInfoBorderSize = (644,175);
			vector2 nextwpnInfoBorderPos = wpnInfoBorderPos;
			
			//create 3 sections (2 for Chaingun):
			int goal = text3 ? 3 : 2;
			for (int i = 0; i < goal; i++) {
				let wpnInfoBorder =  PKZFBoxImage.Create(nextwpnInfoBorderPos, wpnInfoBorderSize,darkFrame);
				nextwpnInfoBorderPos.y += wpnInfoBorderSize.y + (wpnInfoYGap / 2);
				wpnInfoBorder.Pack(tabframe);
			}
			
			//create attack icons:
			vector2 wpnImgPos = wpnInfoBorderPos + (8,8);
			vector2 wpnImgSize = (200,wpnInfoBorderSize.y - 16);
			vector2 wpnDescPos = (wpnImgPos.x + wpnImgSize.x + 8,wpnImgPos.y);
			vector2 wpnDescSize = (416,wpnImgSize.y);
						
			//fire modes are switched, switch around image1 and image2:
			if (modeswitch) {
				string imgpath1sw = imgpath2;
				string imgpath2sw = imgpath1;
				imgpath1 = imgpath1sw;
				imgpath2 = imgpath2sw;
			}
			//Create images for Primary, Secondary and Combo
			let img1 = PKZFImage.Create(wpnImgPos,wpnImgSize,imgpath1);
			img1.pack(tabframe);
			wpnImgPos.y += wpnImgSize.y + wpnInfoYGap;
			let img2 = PKZFImage.Create(wpnImgPos,wpnImgSize,imgpath2);
			img2.pack(tabframe);
			wpnImgPos.y += wpnImgSize.y + wpnInfoYGap;
			//chaingun doesn't have a combo attack, so make it optional:
			if (imgpath3) {
				let img3 = PKZFImage.Create(wpnImgPos,wpnImgSize,imgpath3);
				img3.pack(tabframe);
			}
			
			//create text for Primary (switch to Secondary if modes are switched)
			let wtext1 = modeswitch ? PKZFWeaponDescLabel.Create(wpnDescPos,wpnDescSize, self, text2, alttext2) : PKZFWeaponDescLabel.Create(wpnDescPos,wpnDescSize, self,  text1, alttext1);
			wtext1.pack(tabframe);
			wpnDescPos.y += wpnDescSize.y + wpnInfoYGap;
			//create text for Secondary (switch to Primary if modes are switched)
			let wtext2 = modeswitch ? PKZFWeaponDescLabel.Create(wpnDescPos,wpnDescSize, self, text1, alttext1) : PKZFWeaponDescLabel.Create(wpnDescPos,wpnDescSize, self,  text2, alttext2);
			wtext2.pack(tabframe);
			wpnDescPos.y += wpnDescSize.y + wpnInfoYGap;
			//create text for Combo attack (Chaingun doesn't have it)
			if (text3) {
				let wtext3 = PKZFWeaponDescLabel.Create(	wpnDescPos,wpnDescSize,self,text3);
				wtext3.pack(tabframe);
			}
		}
		//Define Weapon Modifier button:
		let WMtexOff = PKZFBoxTextures.CreateSingleTexture("Graphics/HUD/Codex/CODX_WM0.png",true);
		let WMtexHover = PKZFBoxTextures.CreateSingleTexture("Graphics/HUD/Codex/CODX_WM1.png",true);
		let WMtexOn = PKZFBoxTextures.CreateSingleTexture("Graphics/HUD/Codex/CODX_WM2.png",true);
		vector2 WMbtnSize = (96,96);
		vector2 WMbtnPos = btnPos + (0, 18);
		let WMhandler = New("PKWMHandler");
		WMhandler.menu = self;
		//WMhandler.OffHover = WMtexOffHover;
		//WMhandler.OnHover = WMtexOnHover;
		let WMbtn = PKZFToggleButton.Create(
			WMbtnPos, WMbtnSize,
			inactive:WMtexOff, hover:WMtexHover, click:WMtexOn,
			cmdHandler: WMhandler
		);
		let WMbtnDesc = PKZFWeaponDescLabel.Create(WMbtnPos + (WMbtnSize.x,16), (180,64), self, StringTable.Localize("$PKC_WM_Off"), StringTable.Localize("$PKC_WM_On"), textcolor: Font.FindFontColor('PKBaseText'));
		//WMbtnDesc.SetAlignment(PKZFElement.AlignType_Left);
		WMbtn.Pack(mainTabs[0]);
		WMbtnDesc.Pack(mainTabs[0]);
	}		
}

Class PKWMHandler : PKZFHandler {
	PKCodexMenu menu;
	PKZFBoxTextures OffHover;
	PKZFBoxTextures OnHover;
	override void toggleButtonChanged(PKZFToggleButton caller, string command, bool on) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return; 
		let btn = PKZFToggleButton(caller);
		if (!btn)
			return;
		//btn.SetTextures(btn.getInactiveTexture(), on ? OnHover : OffHover, btn.getClickTexture(), btn.getDisabledTexture());
		menu.showWMText = !menu.showWMText;
		S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
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

Class PKZFWeaponDescLabel : PKZFLabel {
	PKCodexMenu menu;
	string maintext;
	string WMText;
	int baseTextColor;
	
	static PKZFWeaponDescLabel create(
		Vector2 pos, Vector2 size, PKCodexMenu menu, string text = "", string alttext = "", Font fnt = font_times, AlignType alignment = AlignType_TopLeft,
		bool wrap = true, bool autoSize = false, double textScale = PK_MENUTEXTSCALE*0.85, int textColor = Font.CR_WHITE,
		double lineSpacing = 0, PKZFElement forElement = NULL
	) {
		let ret = new('PKZFWeaponDescLabel');
		
		ret.menu = menu;
		ret.baseTextColor = textColor;
		ret.maintext = text;
		ret.WMText = alttext;
		ret.setBox(pos, size);
		ret.config(text, fnt, alignment, wrap, autoSize, textScale, textColor, lineSpacing, forElement);

		return ret;
	}
	
	override void Ticker() {
		super.Ticker();
		if (WMText && menu && menu.showWMText) {
			SetText(WMText);
			SetTextColor(Font.FindFontColor('PKRedText'));
		}
		else {
			SetText(maintext);
			SetTextColor(baseTextColor);
		}
	}
}