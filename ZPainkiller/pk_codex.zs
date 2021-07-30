Class PKCodexMenu : PKCGenericMenu {
	PKCodexHandler handler;
	int activeTab;	
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
		
	override void Init (Menu parent) {
		super.Init(parent);
		S_StartSound("ui/board/open",CHAN_VOICE,CHANF_UI,volume:snd_menuvolume);
		
		//first create the background (always 4:3, never stretched)
		vector2 backgroundsize = (PK_BOARD_WIDTH,PK_BOARD_HEIGHT);	
		SetBaseResolution(backgroundsize);
		let background = new("PKCImage");
		background.Init(
			(0,0),
			backgroundsize,
			image:"graphics/HUD/codexbg.png"
		);
		background.Pack(mainFrame);
		
		handler = new("PKCodexHandler");
		handler.menu = self;
		
		vector2 buttonpos = (32,32);
		int buttongap = buttonpos.x;
		vector2 buttonsize = ( (PK_BOARD_WIDTH - (buttongap*5)) / 4, 52);
		
		let tab_weapons = new("PKCButton").Init(
			buttonpos,
			buttonsize,
			text:Stringtable.Localize("WEAPONS"),
			cmdhandler:handler,
			command:"OpenTab_Weapons",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		tab_weapons.SetTexture("","","","");
		tab_weapons.pack(mainFrame);
		
		buttonpos.x += buttonsize.x + buttongap;
		let tab_powerups = new("PKCButton").Init(
			buttonpos,
			buttonsize,
			text:Stringtable.Localize("POWERUPS"),
			cmdhandler:handler,
			command:"OpenTab_Powerups",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		tab_powerups.SetTexture("","","","");
		tab_powerups.pack(mainFrame);
		
		buttonpos.x += buttonsize.x + buttongap;
		let tab_Gold = new("PKCButton").Init(
			buttonpos,
			buttonsize,
			text:Stringtable.Localize("GOLD"),
			cmdhandler:handler,
			command:"OpenTab_Gold",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		tab_Gold.SetTexture("","","","");
		tab_Gold.pack(mainFrame);
		
		buttonpos.x += buttonsize.x + buttongap;
		let tab_Cards = new("PKCButton").Init(
			buttonpos,
			buttonsize,
			text:Stringtable.Localize("BLACK TAROT"),
			cmdhandler:handler,
			command:"OpenTab_Cards",
			fnt:font_times,
			textscale:PK_MENUTEXTSCALE*1.5,
			textColor:Font.FindFontColor('PKBaseText')
		);
		tab_Cards.SetTexture("","","","");
		tab_Cards.pack(mainFrame);
	}
}

Class PKCodexHandler : PKCHandler {
	PKCodexMenu menu;
	override void buttonClickCommand(PKCButton caller, string command) {
		if (!menu)
			return;
		if (!caller || !caller.isEnabled())
			return;
		if (command == "OpenTab_Weapons") {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (command == "OpenTab_Powerups") {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (command == "OpenTab_Cards") {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
		if (command == "OpenTab_Gold") {	
			S_StartSound("ui/menu/accept",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
			return;
		}
	}
	override void elementHoverChanged(PKCElement caller, string command, bool unhovered) {
		if (!menu || command == "")
			return;
		if (!caller || !caller.isEnabled())
			return;
		let btn = PKCButton(caller);			
		if (!unhovered) {
			btn.textcolor = Font.FindFontColor('PKRedText');
			S_StartSound("ui/menu/hover",CHAN_AUTO,CHANF_UI,volume:snd_menuvolume);
		}
		else {
			btn.textcolor = Font.FindFontColor('PKBaseText');
		}
	}
}