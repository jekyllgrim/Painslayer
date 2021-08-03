enum PKCodexTabs {
	PKCX_Weapons,
	PKCX_Powerups,
	PKCX_Gold,
	PKCX_Cards,
	
	PKCX_PainKiller,
	PKCX_Shotgun,
	PKCX_Stakegun,
	PKCX_Chaingun,
	PKCX_ELD,
	PKCX_Rifle,
	PKCX_Boltgun
}

Class PKCodexMenu : PKZFGenericMenu {
	PKCodexTabhandler handler;
	vector2 backgroundsize;
	int activeTab;

	PKZFRadioButton CreateTabButton(vector2 pos, vector2 size, String text, PKZFRadioController controller, int value,PKZFBoxTextures inactiveTex, PKZFBoxTextures activeTex = null) {
		let ret = PKZFRadioButton.Create(
			pos,
			size,
			controller,
			value,
			inactive:inactiveTex,
			hover:(activeTex ? activeTex : inactiveTex),
			click:(activeTex ? activeTex : inactiveTex),
			text:text,
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.25,
			textColor:Font.FindFontColor('PKBaseText'),
			cmdhandler:handler
		);
		return ret;
	}
	
	static const string TabNames[] = {
		"WEAPONS",
		"POWERUPS",
		"GOLD",
		"TAROT"
	};
	
	override void Drawer() {
		//PK_StatusBarScreen.Fill("46382c",0,0,backgroundsize.x,backgroundsize.y,1);	
		super.Drawer();
	}
	
	override void Init (Menu parent) {
		super.Init(parent);
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//first create the background (always 4:3, never stretched)
		backgroundsize = (PK_BOARD_WIDTH,PK_BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);	
		
		handler = new("PKCodexTabhandler");
		handler.menu = self;
		
		let lightFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut1.png",
			(10,9),
			(74,75),
			false, false
		);
		let darkFrame = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbut2.png",
			(10,9),
			(74,75),
			false, false
		);
		
		let backgroundBorder = PKZFBoxImage.Create((0,0), backgroundsize, darkFrame);
		backgroundBorder.pack(mainFrame);
		
		let bord = PKZFBoxTextures.createTexturePixels(
			"graphics/HUD/Codex/codxbbutn.png",
			(10,9),
			(74,75),
			false, false
		);
		
		let tabController = new("PKZFRadioController");
		
		vector2 buttonpos = (32,32);
		double buttongap = buttonpos.x * 0.5;
		vector2 buttonsize = ( (PK_BOARD_WIDTH - (buttonpos.x*2 + buttongap * 3)) / 4, 64);
		
		vector2 nextBtnPos = buttonpos;
		for (int i = 0; i < 4; i++) {
			let tab = CreateTabButton(nextBtnPos, buttonsize, TabNames[i], tabController, i,  darkFrame, lightFrame);
			nextBtnPos.x += buttonsize.x + buttongap;
			tab.Pack(mainFrame);
		}
		
		/*let tab_weapons = CreateTabButton(buttonpos, buttonsize, Stringtable.Localize("WEAPONS"), tabController, PKCX_Weapons,  darkFrame, lightFrame);
		tab_weapons.pack(mainFrame);
		nextBtnPos.x += buttonsize.x + buttongap;
		let tab_powerups = CreateTabButton(nextBtnPos, buttonsize, Stringtable.Localize("POWERUPS"), tabController, PKCX_Powerups, darkFrame, lightFrame);
		tab_powerups.pack(mainFrame);		
		nextBtnPos.x += buttonsize.x + buttongap;
		let tab_Gold = CreateTabButton(nextBtnPos, buttonsize, Stringtable.Localize("GOLD"), tabController, PKCX_Gold,  darkFrame, lightFrame);
		tab_Gold.pack(mainFrame);		
		nextBtnPos.x += buttonsize.x + buttongap;
		let tab_Cards = CreateTabButton(nextBtnPos, buttonsize, Stringtable.Localize("TAROT"), tabController, PKCX_Cards,darkFrame, lightFrame);
		tab_Cards.pack(mainFrame);*/
		
		vector2 sectionPos = (buttonpos.x * 0.5, buttonpos.y + buttonsize.y * 1.5);
		vector2 sectionSize = (PK_BOARD_WIDTH - sectionPos.x * 2, PK_BOARD_HEIGHT - sectionPos.y * 1.25);
		
		let sectionBorder = PKZFBoxImage.Create(sectionPos, sectionSize, lightFrame);
		sectionBorder.pack(mainFrame);
	}
}

Class PKCodexTabhandler : PKZFHandler {
	PKCodexMenu menu;
	override void radioButtonChanged(PKZFRadioButton caller, string command, PKZFRadioController variable) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		if (caller.getValue() == PKCX_Weapons) {
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (caller.getValue() == PKCX_Powerups) {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (caller.getValue() == PKCX_Cards) {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (caller.getValue() == PKCX_Gold) {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
	}
	override void elementHoverChanged(PKZFElement caller, string command, bool unhovered) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		let btn = PKZFRadioButton(caller);
		if (!btn)
			return;
		if (!unhovered) {
			btn.SetTextColor(Font.FindFontColor('PKRedText'));
			S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		}
		else {
			btn.SetTextColor(Font.FindFontColor('PKBaseText'));
		}
	}
}

