--============================================================================
-- PainMenu
--============================================================================

-- Common buttons

BackButton =
{
	text		= TXT.Menu.Back,
	desc		= TXT.MenuDesc.Back,
	x			= 72,
	y			= 660,
	fontBigSize = 36,
	align		= MenuAlign.Left,
	useItemBG	= false,
	textColor	= R3D.RGBA( 255, 255, 255, 255 ),
	descColor	= R3D.RGB( 255, 255, 255 ),
	sndAccept   = "menu/menu/back-accept",
	sndLightOn  = "menu/menu/back-light-on",
	fontBigTex  = "HUD/font_texturka_alpha",
	fontSmallTex= "HUD/font_texturka_alpha",
}

ApplyButton =
{
	text		= TXT.Menu.Apply,
	desc		= TXT.MenuDesc.Apply,
	x			= 952,
	y			= 660,
	fontBigSize = 36,
	align		= MenuAlign.Right,
	useItemBG	= false,
	textColor	= R3D.RGBA( 255, 255, 255, 255 ),
	descColor	= R3D.RGB( 255, 255, 255 ),
	sndAccept   = "menu/menu/apply-accept",
	sndLightOn  = "menu/menu/back-light-on",
	fontBigTex  = "HUD/font_texturka_alpha",
	fontSmallTex= "HUD/font_texturka_alpha",
}

-- Menu screens

DoFile(path.."HUD/Menu/Dialogs.lua")
if not IsBlackEdition() then
	DoFile(path.."HUD/Menu/MainMenu.lua")
	DoFile(path.."HUD/Menu/Options/OptionsMenu.lua")
else
	DoFile(path.."HUD/Menu/MainMenuBlack.lua")
	DoFile(path.."HUD/Menu/Options/OptionsMenuBlack.lua")
end
DoFile(path.."HUD/Menu/NewGameMenu.lua")
DoFile(path.."HUD/Menu/GameMenu.lua")
DoFile(path.."HUD/Menu/DemoEnd.lua")
DoFile(path.."HUD/Menu/CreditsMenu.lua")
DoFile(path.."HUD/Menu/VideosMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/MultiplayerMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/InternetGameMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/LANGameMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/FavoritesGameMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/StartGameMenu.lua")
DoFile(path.."HUD/Menu/Multiplayer/CreateServerMenu.lua")
DoFile(path.."HUD/Menu/Options/VideoOptions.lua")
DoFile(path.."HUD/Menu/Options/AdvancedVideoOptions.lua")
DoFile(path.."HUD/Menu/Options/SoundOptions.lua")
DoFile(path.."HUD/Menu/Options/HUDConfig.lua")
DoFile(path.."HUD/Menu/Options/ControlsConfig.lua")
DoFile(path.."HUD/Menu/Options/WeaponsConfig.lua")
DoFile(path.."HUD/Menu/Options/MessagesConfig.lua")
DoFile(path.."HUD/Menu/Multiplayer/PlayerOptions.lua")
DoFile(path.."HUD/Menu/SaveGame/LoadSaveMenu.lua")

--============================================================================

PainMenu =
{
	mainScreen	= MainMenu,
	currScreen  = nil,
	lastScreen	= "",

	menuWidth   = 720,
	topPos		= 140,
	sliderWidth = 370,
	sliderCtrlWidth = 700,
	listMaxHeight = 380,

--	fontBig		= "gothicum",
--	fontSmall	= "gothicum",
--	fontBig		= "arialbd",
--	fontSmall	= "arialbd",
--	fontBig		= "tahomabd",
--	fontSmall	= "tahomabd",
	fontBig		= "timesbd",
	fontSmall	= "timesbd",
	fontBigSize	= 54,
	fontSmallSize = 26,
	fontBigTex  = "",
	fontSmallTex = "",

	-- Colors
--	textColor	= R3D.RGBA( 66, 3, 3, 200 ),
	textColor	= R3D.RGBA( 255, 186, 122, 255 ),
	disabledColor = R3D.RGBA( 155, 86, 22, 255 ),
	underMouseColor = R3D.RGBA( 166, 3, 3, 255 ),
	descColor	= R3D.RGB( 255, 186, 122 ),

	itemsFadeLength = 15,
	itemsDrawShadow = true,

--	background	= "../Data/Movies/menu.avi",
--	bgType		= MenuBackgroundTypes.Movie,
	background	= "HUD/Menu",
	bgType		= MenuBackgroundTypes.Image,

	sndAccept   = "menu/menu/option-accept",
	sndLightOn  = "menu/menu/option-light-on",

	favServers	= {},
	mapsOnServer = {},
	mapsOnServerFFA = {},
	mapsOnServerTDM = {},
	mapsOnServerTLB = {},
	mapsOnServerPCF = {},
	mapsOnServerVSH = {},
	mapsOnServerCTF = {},
	mapsOnServerDUE = {},
	mapsOnServerLMS = {},
	lastMPMode = "",

	playerModel = nil,
	playerLight = nil,
	cameraPos = { 0.0, 0.0, 0.0 },
	cameraRot = { 0.0, 0.0, 0.0 },
	ambient = { 0, 0, 0, 0 },
	
	showStartMovies = Cfg.PlayStartMovies,
	
	weapons = { _11 = TXT.Weapons.Pain, _12 = TXT.Weapons.Killer, _21 = TXT.Weapons.Shotgun, _22 = TXT.Weapons.Freezer, _31 = TXT.Weapons.Stakegun,
				_32 = TXT.Weapons.GranadeLauncher, _41 = TXT.Weapons.RocketLauncher, _42 = TXT.Weapons.Minigun, _51 = TXT.Weapons.Shurikens, _52 = TXT.Weapons.Electro,
				_61 = TXT.Weapons.Rifle, _62 = TXT.Weapons.FlameThrower, _71 = TXT.Weapons.BoltGun, _72 = TXT.Weapons.Heater },

	lastSaveSort = "date",
	
	movSndTracks = { "english", "french", "german", "italian", "russian", "spanish" },
	movSndTrack = 0,

	playerName = Cfg["PlayerName"],
	passwd = "",
	speed = 1,
	host = "",
	port = 3455,
	public = true,
	spectator = false,

	GfxQualityPresets =
	{
		{
			-- Fastest
			Resolution = "640X480",			-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 3,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 3,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 3,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 3,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 0,					-- 1/0
			WeatherEffects = false,			-- true/false
			RenderSky = 0,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = false,		-- true/false
			WeaponSpecular = false,			-- true/false
			WeaponNormalMap = false,		-- true/false
			TextureFiltering = "Bilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 0,				-- 0,1,2
			ParticlesDetail = 1,			-- 1 = low, 2 = high
			DecalsStayTime = 1000,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = false,				-- true/false
			DetailTextures = false,			-- true/false
		},
		
		{
			-- Fast
			Resolution = "640X480",			-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 2,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 2,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 2,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 2,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 0,					-- 1/0
			WeatherEffects = false,			-- true/false
			RenderSky = 1,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = true,			-- true/false
			WeaponSpecular = false,			-- true/false
			WeaponNormalMap = false,		-- true/false
			TextureFiltering = "Bilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 1,				-- 0,1,2
			ParticlesDetail = 1,			-- 1 = low, 2 = high
			DecalsStayTime = 1000,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = false,				-- true/false
			DetailTextures = false,			-- true/false
		},
		
		{
			-- Standard
			Resolution = "800X600",			-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 1,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 1,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 1,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 1,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 0,					-- 1/0
			WeatherEffects = true,			-- true/false
			RenderSky = 2,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = true,			-- true/false
			WeaponSpecular = false,			-- true/false
			WeaponNormalMap = false,		-- true/false
			TextureFiltering = "Bilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 1,				-- 0,1,2
			ParticlesDetail = 1,			-- 1 = low, 2 = high
			DecalsStayTime = 0.4,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = true,					-- true/false
			DetailTextures = true,			-- true/false
		},
		
		{
			-- High
			Resolution = "1024X768",		-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 0,					-- 1/0
			WeatherEffects = true,			-- true/false
			RenderSky = 2,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = true,			-- true/false
			WeaponSpecular = true,			-- true/false
			WeaponNormalMap = true,			-- true/false
			TextureFiltering = "Bilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 2,				-- 0,1,2
			ParticlesDetail = 2,			-- 1 = low, 2 = high
			DecalsStayTime = 0.4,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = true,					-- true/false
			DetailTextures = true,			-- true/false
		},
		
		{
			-- Very High
			Resolution = "1024X768",		-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 1,					-- 1/0
			WeatherEffects = true,			-- true/false
			RenderSky = 2,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = true,			-- true/false
			WeaponSpecular = true,			-- true/false
			WeaponNormalMap = true,			-- true/false
			TextureFiltering = "Trilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 2,				-- 0,1,2
			ParticlesDetail = 2,			-- 1 = low, 2 = high
			DecalsStayTime = 0.4,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = true,					-- true/false
			DetailTextures = true,			-- true/false
		},
		
		{
			-- Insane
			Resolution = "1280X960",		-- "640X480", "800X600", "1024X768", "1280X1024", "1600X1200"
			TextureQualityWeapons = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityArchitecture = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualityCharacters = 0,	-- 3 = very low, 2 = low, 1 = medium, 0 = high
			TextureQualitySkies = 0,		-- 3 = very low, 2 = low, 1 = medium, 0 = high
			Shadows = 1,					-- 1/0
			WeatherEffects = true,			-- true/false
			RenderSky = 2,					-- 0 = off, 1 = low, 2 = high
			ViewWeaponModel = true,			-- true/false
			WeaponSpecular = true,			-- true/false
			WeaponNormalMap = true,			-- true/false
			TextureFiltering = "Trilinear",	-- "Bilinear"/"Trilinear"
			Multisample = "x0",				-- "x0" = none, "x2", "x4", "x6"
			DynamicLights = 2,				-- 0,1,2
			ParticlesDetail = 2,			-- 1 = low, 2 = high
			DecalsStayTime = 0.2,			-- 1000 = off, 2.0 = x1, 1.0 = x2, 0.6 = x3, 0.4 = x4, 0.2 = x5
			Coronas = true,					-- true/false
			DetailTextures = true,			-- true/false
		},
	},

	ConnectionSpeedPresets =
	{
		{
			-- modem
            NetcodeClientMaxBytesPerSecond = -1,
            NetcodeEnemyPredictionInterpolation = true,
            NetcodeLocalPlayerSynchroEveryNFrames = 1,
            NetcodeMaxPlayerActionsPassed = 1,
            NetcodeMinUpstreamFrameSize = 0,
            NetcodeServerFramerate = 10,
            NetcodeStatsNumberToAverageFrom = 1,
            NetcodeStatsUpdateDelay = 1000,
            MaxFpsMP = 60,
		},
		
		{
			-- ISDN/ADSL
            NetcodeClientMaxBytesPerSecond = -1,
            NetcodeEnemyPredictionInterpolation = true,
            NetcodeLocalPlayerSynchroEveryNFrames = 1,
            NetcodeMaxPlayerActionsPassed = 1,
            NetcodeMinUpstreamFrameSize = 0,
            NetcodeServerFramerate = 20,
            NetcodeStatsNumberToAverageFrom = 1,
            NetcodeStatsUpdateDelay = 1000,
            MaxFpsMP = 60,
		},
		
		{
			-- ADSL/Cable
            NetcodeClientMaxBytesPerSecond = -1,
            NetcodeEnemyPredictionInterpolation = true,
            NetcodeLocalPlayerSynchroEveryNFrames = 1,
            NetcodeMaxPlayerActionsPassed = 1,
            NetcodeMinUpstreamFrameSize = 0,
            NetcodeServerFramerate = 30,
            NetcodeStatsNumberToAverageFrom = 1,
            NetcodeStatsUpdateDelay = 1000,
            MaxFpsMP = 100,
		},
		
		{
			-- LAN/T1/E1
            NetcodeClientMaxBytesPerSecond = -1,
            NetcodeEnemyPredictionInterpolation = true,
            NetcodeLocalPlayerSynchroEveryNFrames = 1,
            NetcodeMaxPlayerActionsPassed = 1,
            NetcodeMinUpstreamFrameSize = 0,
            NetcodeServerFramerate = 30,
            NetcodeStatsNumberToAverageFrom = 1,
            NetcodeStatsUpdateDelay = 1000,
            MaxFpsMP = 125,
		},
	},
}

--============================================================================

firstTimeRun = 1

--============================================================================

function PainMenu:Init()
--	PainMenu:ActivateScreen( self.mainScreen )
--	MagicBoard_LoadStatus()
end

function PainMenu:Close()
	PMENU.Clear()
end

--============================================================================

function PainMenu:Draw()
	if self.showStartMovies then
		if IsFinalBuild() then
			PMENU.PlayMovie('../Data/Movies/logo-dreamcatcher.bik');
			PMENU.PlayMovie('../Data/Movies/logo-pcf.bik');
			PMENU.PlayMovie('../Data/Movies/logo-nvidia.bik');
		end
		self.showStartMovies = false
	end
	if Cfg.PlayStartSound == true then PlaySound2D("menu/painkiller-mainlogo", 25) end
end

function PainMenu:ActivateScreen( screen )
--	local ret = PMENU.PlayMovie( "../Data/Movies/menu.bik" )
--	if not ret then
--		Game:Print( "Cannot play movie" )
--	end

	SOUND.SetRoomType(0,0,0)

	PMENU.ClearScreen()
	PainMenu:SetupScreen( screen )
	
	if Cfg.BlackEdition then
		screen.background = "HUD/Menu_black"
	end
	
	PMENU.SetBackground( screen.background, screen.bgType )
	PMENU.SetMenuWidth( screen.menuWidth )
	PMENU.SetTopPosition( screen.topPos )
	if( screen.firstTimeShowItems and firstTimeRun > 0 ) then
		PMENU.SetItemsFadeLength( screen.itemsFadeLength )
		PMENU.SetShowItemsFrame( screen.firstTimeShowItems )
		firstTimeRun = 0
	else
		PMENU.SetShowItemsFrame( 0 )
	end

	if( screen.bgStartFrame and screen.bgEndFrame ) then
--		if( currScreen == nil ) then
			PMENU.SetMovieLoop( screen.bgStartFrame[1], screen.bgEndFrame[1] )
--		else
--			PainMenu:OnMovieLoopEnd()
--		end
	end

	self.currScreen = screen

	local i, o = next( screen.items, nil )
	while i do
		PainMenu:AddItem( i, o )
		i,o = next( screen.items, i )
	end

	if screen.backAction then
--		Game:Print( "Adding back button - "..screen.backAction )
		PainMenu:AddCommonButton( BackButton, screen, "BackButton", screen.backAction, "" )
	end

--	if screen.applyAction then
--		PainMenu:AddCommonButton( ApplyButton, screen, "ApplyButton", screen.applyAction, "" )
--	end

	PMENU.SetItemsDrawShadow( screen.itemsDrawShadow )

	if screen == InternetGameMenu then
		if self.lastScreen == "joinlan" then
			PainMenu:StopServerList()
			PainMenu:ActivateScreen(LANGameMenu)
		elseif self.lastScreen == "favorites" then
			PainMenu:StopServerList()
			PainMenu:ActivateScreen(FavoritesGameMenu)
		end
		self.lastScreen = ""
	end
	
	if screen == WeaponsConfig then
		PainMenu:FixFireSwitchTable()
	end

	PMENU.ShowMouse()

	if screen == DemoEnd then
		CONSOLE.Activate(false)
--		PMENU.ShowMouse(false)
	end

	PainMenu:CheckWeaponSpecular()

--	PainMenu:OnMovieLoopEnd()

	local wait = 0
	if screen.wait then wait = screen.wait end
	PMENU.SetWaitTime( wait )

	if self.currScreen == ControlsConfig then
		PainMenu:HideTabGroup(PainMenu.currScreen.items.AdvancedTab, 'AdvancedTab')
		PainMenu:ShowTabGroup(PainMenu.currScreen.items.GeneralTab, 'GeneralTab')
	elseif self.currScreen == NewGameMenu then
		local cardCount = 0
		for i,o in Game.CardsAvailable do
			if (i > 24 and Game.AddOn) or not Game.AddOn then
				if Game.CardsAvailable[i] then
					cardCount = cardCount + 1
				end
			end
		end
		if (not Game.AddOn and IsBooHInstalled()) or (Game.AddOn and cardCount > 8) or (not Game.AddOn and cardCount > 22) then
			PMENU.EnableItem("Trauma")
			PMENU.SetItemDesc("Trauma", TXT.MenuDesc.Trauma)
		elseif Game.AddOn then
			PMENU.SetItemDesc("Trauma", Languages.Texts[835])
		else
			PMENU.SetItemDesc("Trauma", Languages.Texts[689])
		end
	elseif self.currScreen == CreateServerMenu then
		local item = self.currScreen.items.GeneralTab.items.GameMode
		if item.values[item.currValue] == "Capture The Flag" then
			PMENU.SetItemVisibility( "CaptureLimit", true )
			PMENU.SetItemVisibility( "LMSLives", false )
		elseif item.values[item.currValue] == "Last Man Standing" then
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", true )
		else
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", false )
		end
		
		item = self.currScreen.items.GeneralTab.items.PublicServer
		if not IsPKInstalled() then PMENU.DisableItem( "PublicServer" ) end
	end
end

function PainMenu:AddItem( i, o )
	local itemName = i
	local skip = false

	if o.inGameOnly then
		if Game.LevelStarted == false or (self.GMode ~= GModes.SingleGame and itemName == "BackToMap") then
			skip = true
		end

		if Game.GameInProgress == true and itemName == "BackToMap" then
			skip = false
		end

		if (Game.GMode == GModes.SingleGame or Game:IsServer()) and itemName == "Disconnect" then
			skip = true
		end
	end
	
--	if not Cfg.Credits and itemName == "Credits" then
--		skip = true
--	end
	
	if IsMPDemo() then
		if itemName == "SignAPact" or itemName == "LoadGame" or itemName == "CDKey" then
			o.disabled = true
		elseif itemName == "Quit" then
			o.action = "PainMenu:AskYesNo( Languages.Texts[469], 'PainMenu:ActivateScreen(DemoEnd)', 'PainMenu:ActivateScreen(MainMenu)' )"
		elseif itemName == "GameMode" then
			o.values = { "Free For All", "The Light Bearer" }
			o.visible = { TXT.Menu.FreeForAll, TXT.Menu.TheLightBearer }
		elseif itemName == "ModelSelect" then
			o.values = { 1, 2, 3, 4 }
			o.visible = { TXT.Menu.Model1, TXT.Menu.Model2, TXT.Menu.Model3, TXT.Menu.Model4 }
		end
	end
	
	if not IsPKInstalled() then
		if itemName == "CDKey" then
			o.disabled = true
		end
	end

	if itemName == "ModelSelect" and not IsMPDemo() then
		o.currValue = Cfg.PlayerModel
		if not Game.BonusMPModel and not Game.BonusMPModel2 then
			o.values = { 1, 2, 3, 4, 5 }
			o.visible = { TXT.Menu.Model1, TXT.Menu.Model2, TXT.Menu.Model3, TXT.Menu.Model4, TXT.Menu.Model7 }
		elseif Game.BonusMPModel and not Game.BonusMPModel2 then
			o.values = { 1, 2, 3, 4, 5, 6 }
			o.visible = { TXT.Menu.Model1, TXT.Menu.Model2, TXT.Menu.Model3, TXT.Menu.Model4, TXT.Menu.Model7, TXT.Menu.Model5 }
		elseif not Game.BonusMPModel and Game.BonusMPModel2 then
			o.values = { 1, 2, 3, 4, 5, 7 }
			o.visible = { TXT.Menu.Model1, TXT.Menu.Model2, TXT.Menu.Model3, TXT.Menu.Model4, TXT.Menu.Model7, TXT.Menu.Model6 }
		else
			o.values = { 1, 2, 3, 4, 5, 6, 7 }
			o.visible = { TXT.Menu.Model1, TXT.Menu.Model2, TXT.Menu.Model3, TXT.Menu.Model4, TXT.Menu.Model7, TXT.Menu.Model5, TXT.Menu.Model6 }
		end
	end

	if skip == false then
		if o.type == MenuItemTypes.ImageButtonEx then
			PMENU.AddImageButtonEx( itemName, o.text, o.desc, Cfg.Crosshair - 1 )
			for i, v in o.images do
				PMENU.AddImageToButtonEx( itemName, o.images[i] )
			end
		elseif o.type == MenuItemTypes.StaticText then
			PMENU.AddStaticText( itemName, HUD.PrepareString( o.text ) )
		elseif o.type == MenuItemTypes.SimpleKeyConf then
			PainMenu:AddSimpleKeyConf( itemName, o )
		elseif o.type == MenuItemTypes.ColorPicker then
			PMENU.AddColorPicker( itemName, o.text, o.desc )
		elseif o.type == MenuItemTypes.CharPicker then
			PMENU.AddCharPicker( itemName, o.text, o.desc )
		elseif o.type == MenuItemTypes.PlayerModel then
			PainMenu:AddPlayerModelItem( itemName, o )
		elseif o.type == MenuItemTypes.ControlCfg then
			PainMenu:AddControlConfig( o )
		elseif o.type == MenuItemTypes.ServerList then
			PainMenu:AddServerList( itemName, o )
		elseif o.type == MenuItemTypes.List then
			PainMenu:AddList( itemName, o )
		elseif o.type == MenuItemTypes.WeaponList then
			PainMenu:AddWeaponList( itemName, o )
		elseif o.type == MenuItemTypes.LoadSave then
--				Game:Print( "Adding loadsave" )
			PainMenu:AddLoadSave( itemName, o )
		elseif o.type == MenuItemTypes.MapTable then
			PainMenu:AddMapTable( itemName, o )
		elseif o.type == MenuItemTypes.TextButton then
			PMENU.AddTextButton( itemName, o.text, o.desc )
		elseif o.type == MenuItemTypes.Border then
			PMENU.AddBorder( itemName, o.dark )
			PMENU.SetItemPosition( itemName, o.x, o.y )
			PMENU.SetBorderSize( itemName, o.width, o.height )
			if o.header then PMENU.SetBorderHeader( itemName, o.header ) end
			if itemName == "FireBorder" then
				PMENU.SetBorderColCount( itemName, 4 )
				PMENU.SetBorderColumn( itemName, 0, 248 )
				PMENU.SetBorderColumn( itemName, 1, 248 )
				PMENU.SetBorderColumn( itemName, 2, 248 )
				PMENU.SetBorderColumn( itemName, 3, 120 )
			elseif itemName == "MessagesBorder" then
				PMENU.SetBorderColCount( itemName, 3 )
				PMENU.SetBorderColumn( itemName, 0, 140 )
				PMENU.SetBorderColumn( itemName, 1, 50 )
				PMENU.SetBorderColumn( itemName, 2, 734 )
			end
		elseif o.type == MenuItemTypes.TabGroup then
			PMENU.AddTabGroup( itemName, o.dark )
			PMENU.SetItemPosition( itemName, o.x, o.y )
			PMENU.SetBorderSize( itemName, o.width, o.height )
			local j, m = next( o.items, nil )
			while j do
				PainMenu:AddItem( j, m )
				j,m = next( o.items, j )
			end
			if o.visible == true then
				PainMenu:ShowTabGroup( o, itemName )
			else
				PainMenu:HideTabGroup( o, itemName )
			end
		elseif o.type == MenuItemTypes.ImageButton then
			PMENU.AddImageButton( itemName, o.text, o.desc, o.image, o.imageUnder, o.imagePressed )
		elseif o.type == MenuItemTypes.Checkbox then
			local val = false
			if not string.find( itemName, "AutoGenerated_" ) then
				if Cfg[o.option] == o.valueOn then
					val = true
				end
			else
				if Cfg[o.option][o.index] == o.valueOn then
					val = true
					o.desc = o.descOn
				else
					o.desc = o.descOff
				end
			end
			PMENU.AddCheckbox( itemName, o.text, o.desc, val )
		elseif o.type == MenuItemTypes.TextButtonEx then
			o.currValue = 1
			for i, v in o.values do
				if itemName ~= "ModelSelect" or i <= table.getn(o.values) or Game.BonusMPModel or Game.BonusMPModel2 or IsMPDemo() then
					if v == Cfg[o.option] then
						o.currValue = i
						if itemName == "ModelSelect" then
							PainMenu:ChangePlayerModel(MPModels[v])
						end
					end
				end
			end
			if itemName == "SoundProvider" then
				PainMenu:FillSoundProviders( o )
			end
			if itemName == "Resolution" then
				o.visible = R3D.GetAvailableResolutions()
				o.values = {}
				for i=1,table.getn(o.visible) do
					o.values[i] = string.upper(o.visible[i])
					if o.values[i] == Cfg.Resolution then
						o.currValue = i
					end
				end
			end
			PMENU.AddTextButtonEx( itemName, o.text, o.desc, o.visible[o.currValue] )
		elseif o.type == MenuItemTypes.NumRange then
			if Cfg[o.option] == nil then
				o.currValue = o.minVal
			else
				o.currValue = Cfg[o.option]
				if o.currValue < o.minVal then o.currValue = o.minVal end
				if o.currValue > o.maxVal and o.maxVal ~= -1 then o.currValue = o.maxVal end
			end
			PMENU.AddNumRange( itemName, o.text, o.desc, o.minVal, o.maxVal, o.currValue )
		elseif o.type == MenuItemTypes.Slider then
			if Cfg[o.option] == nil then
				o.currValue = 100
			else
				o.currValue = Cfg[o.option]
			end

			if not o.isFloat then
				o.isFloat = false
			end

			local value = o.currValue
			local minValue = o.minValue
			local maxValue = o.maxValue
			if o.isFloat == true then
				value = value * 100.0
				minValue = minValue * 100.0
				maxValue = maxValue * 100.0
			end
			PMENU.AddSlider( itemName, o.text, o.desc, minValue, maxValue, o.isFloat, value, o.sliderWidth, o.sliderCtrlWidth )
			if o.fullWidth then
				PMENU.SetSliderFullWidth( itemName, o.fullWidth )
			end
		elseif o.type == MenuItemTypes.TextEdit then
			local len = 0
			if o.maxLength then
				len = o.maxLength
			end
			local value = ""
			if itemName == "CDKey" then
				value = "****" -- PMENU.GetCDKey()
			elseif string.find( itemName, "AutoGenerated_" ) then
				value = Cfg[o.option][o.index]
			else
				if Cfg[o.option] then
					value = Cfg[o.option]
				end
			end
			PMENU.AddTextEdit( itemName, o.text, o.desc, len, value )
		elseif o.type == MenuItemTypes.Password then
			local len = 0
			if o.maxLength then
				len = o.maxLength
			end
			local value = ""
			if Cfg[o.option] then
				value = Cfg[o.option]
			end
			PMENU.AddPassword( itemName, o.text, o.desc, len, value )
		elseif o.type == MenuItemTypes.NumEdit then
			local len = 0
			if o.maxLength then
				len = o.maxLength
			end
			local value = ""
			if Cfg[o.option] then
				value = Cfg[o.option]
			end
			PMENU.AddNumEdit( itemName, o.text, o.desc, len, value )
		elseif o.type == MenuItemTypes.SliderImage then
			if Cfg[o.option] == nil then
				o.currValue = 100
			else
				o.currValue = Cfg[o.option]
			end

			if not o.isFloat then
				o.isFloat = false
			end

			local value = o.currValue
			local minValue = o.minValue
			local maxValue = o.maxValue
			if o.isFloat == true then
				value = value * 100.0
				minValue = minValue * 100.0
				maxValue = maxValue * 100.0
			end
			PMENU.AddSliderImage( itemName, o.text, o.desc, minValue, maxValue, o.isFloat, value, o.sliderWidth, o.sliderCtrlWidth )
			if o.fullWidth then
				PMENU.SetSliderFullWidth( itemName, o.fullWidth )
			end
			for i, v in o.images do
				PMENU.AddImageToSlider( itemName, v )
--					Game:Print( "Adding image "..v )
			end
		end

		if not ( o.type == MenuItemTypes.ControlCfg ) then
			PMENU.SetItemPosition( itemName, o.x, o.y )
			PMENU.SetItemAlign( itemName, o.align )
			PMENU.SetItemAction( itemName, o.action )
			PMENU.SetItemApplyRequired( itemName, o.applyRequired )
			PMENU.SetItemFonts( itemName, o.fontBig, o.fontBigSize, o.fontSmall, o.fontSmallSize )
			PMENU.SetItemFontsTex( itemName, o.fontBigTex, o.fontSmallTex )
			if o.warning then PMENU.SetItemWarning( itemName, true ) end
			if( o.exitStart and o.exitEnd ) then
				PMENU.SetItemExitMovie( itemName, o.exitStart, o.exitEnd )
			end
			PMENU.SetItemColors( itemName, o.textColor, o.disabledColor, o.underMouseColor, o.descColor )
			if o.disabled then
				PMENU.DisableItem( itemName )
			end
			if o.useItemBG == true then
				PMENU.EnableItemBG( itemName, "blaszka" )
			end
			PMENU.SetItemSounds( itemName, o.sndAccept, o.sndLightOn )
			PMENU.SetItemVisibility( itemName, o.visible )
		end
	end
end

function PainMenu:SetupScreen( screen )
	if not screen.name then
		screen.name = ""
	end

	if screen.items.MessagesKeys ~= nil then
		local o = screen.items.MessagesKeys
		for i=1,o.count do
			screen.items["AutoGenerated_Message"..i.."Key"] =
			{
				type = MenuItemTypes.SimpleKeyConf,
				text = "Print Screen",
				desc = "",
				option = "MessagesKeys",
				index = i,
				x	 = 122,
				y	 = 158 + i * 24,
				fontBigSize = 22,
				align = MenuAlign.Center,
				disabledColor = R3D.RGB( 200, 200, 200 ),
			}

			screen.items["AutoGenerated_Message"..i.."SayAll"] =
			{
				type = MenuItemTypes.Checkbox,
				text = "",
				desc = "",
				option = "MessagesSayAll",
				index = i,
				valueOn = 1,
				valueOff = 0,
				x	 = 204,
				y	 = 154 + i * 24,
				action = "",
				align = MenuAlign.Left,
				fontBigSize = 10,
				descOn = TXT.MenuDesc.SAOn,
				descOff = TXT.MenuDesc.SAOff,
			}

			screen.items["AutoGenerated_Message"..i.."Msg"] =
			{
				type = MenuItemTypes.TextEdit,
				text = "",
				desc = "",
				option = "MessagesTexts",
				index = i,
				x	 = 242,
				y	 = 158 + i * 24,
				width = 700,
				action = "",
				maxLength = 48,
				fontBig = "courbd",
				fontBigSize = 22,
				align = MenuAlign.Left,
			}
		end
	end

	-- Width
	if not screen.menuWidth and self.menuWidth then
		screen.menuWidth = self.menuWidth
	end

	if not screen.topPos and self.topPos then
		screen.topPos = self.topPos
	end

	if not screen.sliderWidth and self.sliderWidth then
		screen.sliderWidth = self.sliderWidth
	end
	
	if not screen.sliderCtrlWidth and self.sliderCtrlWidth then
		screen.sliderCtrlWidth = self.sliderCtrlWidth
	end
	
	if not screen.listMaxHeight and self.listMaxHeight then
		screen.listMaxHeight = self.listMaxHeight
	end

	-- Fonts
	if not screen.fontBig and self.fontBig then
		screen.fontBig = self.fontBig
	end
	if not screen.fontSmall and self.fontSmall then
		screen.fontSmall = self.fontSmall
	end
	if not screen.fontBigSize and self.fontBigSize then
		screen.fontBigSize = self.fontBigSize
	end
	if not screen.fontSmallSize and self.fontSmallSize then
		screen.fontSmallSize = self.fontSmallSize
	end
	if not screen.fontBigTex and self.fontBigTex then
		screen.fontBigTex = self.fontBigTex
	end
	if not screen.fontSmallTex and self.fontSmallTex then
		screen.fontSmallTex = self.fontSmallTex
	end
	
	-- Colors
	if not screen.textColor and self.textColor then
		screen.textColor = self.textColor
	end
	if not screen.disabledColor and self.disabledColor then
		screen.disabledColor = self.disabledColor
	end
	if not screen.underMouseColor and self.underMouseColor then
		screen.underMouseColor = self.underMouseColor
	end
	if not screen.descColor and self.descColor then
		screen.descColor = self.descColor
	end
	
	-- Background
	if not screen.background and self.background then
		screen.background = self.background
	end
	if not screen.bgType and self.bgType then
		screen.bgType = self.bgType
	end

	if not screen.itemsFadeLength then
		screen.itemsFadeLength = self.itemsFadeLength
	end
	
	if not screen.itemsDrawShadow then
		screen.itemsDrawShadow = self.itemsDrawShadow
	end

	-- Sounds
	if not screen.sndAccept then
		screen.sndAccept = self.sndAccept
	end

	if not screen.sndLightOn then
		screen.sndLightOn = self.sndLightOn
	end

	-- Items
	local i, o = next( screen.items, nil )
	while i do
		PainMenu:SetupItem( screen, i, o )
		i,o = next( screen.items, i )
	end
end

function PainMenu:SetupItem( screen, i, o )
	if not o.sliderWidth then
		o.sliderWidth = screen.sliderWidth
	end
	
	if not o.sliderCtrlWidth then
		o.sliderCtrlWidth = screen.sliderCtrlWidth
	end
	
	if not o.listMaxHeight then
		o.listMaxHeight = screen.listMaxHeight
	end

	if not o.align then
		o.align = MenuAlign.None
	end

	-- Fonts
	if not o.fontBig then
		o.fontBig = screen.fontBig
	end
	if not o.fontSmall then
		o.fontSmall = screen.fontSmall
	end
	if not o.fontBigSize then
		o.fontBigSize = screen.fontBigSize
	end
	if not o.fontSmallSize then
		o.fontSmallSize = screen.fontSmallSize
	end
	if not o.fontBigTex then
		o.fontBigTex = screen.fontBigTex
	end
	if not o.fontSmallTex then
		o.fontSmallTex = screen.fontSmallTex
	end

	-- Colors
	if not o.textColor then
		o.textColor = screen.textColor
	end
	if not o.disabledColor then
		o.disabledColor = screen.disabledColor
	end
	if not o.underMouseColor then
		o.underMouseColor = screen.underMouseColor
	end
	if not o.descColor then
		o.descColor = screen.descColor
	end

	if not o.type then
		o.type = MenuItemTypes.TextButton
	end

	if not o.x then
		o.x = -1
	end
	
	if not o.y then
		o.y = -1
	end

	if screen.useItemBG then
		if o.useItemBG == nil then
			o.useItemBG = screen.useItemBG
		end
	end

	if not o.useItemBG then
		o.useItemBG = false
	end
	
	if not o.applyRequired then
		o.applyRequired = false
	end

	if o.visible == nil then
		o.visible = true
	end

	-- Sounds
	if not o.sndAccept then
		o.sndAccept = screen.sndAccept
	end

	if not o.sndLightOn then
		o.sndLightOn = screen.sndLightOn
	end
	
	if not o.dark then
		o.dark = false
	end
	
	if not o.descOn then o.descOn = "" end
	if not o.descOff then o.descOff = "" end

	if o.type == MenuItemTypes.TabGroup then
		local j, m = next( o.items, nil )
		while j do
			PainMenu:SetupItem( screen, j, m )
			j,m = next( o.items, j )
		end
	end

	if screen == VideoOptions and R3D.GetHWClass() == R3DHWClass.GenericTnL then
		if Cfg.DynamicLights == 2 then Cfg.DynamicLights = 1 end
		Cfg.WeaponNormalMap = false
		Cfg.WeaponSpecular = false
		Cfg.Bloom = false
		Cfg.WarpEffects = false
		Cfg.WaterFX = 0
		screen.items.AdvancedTab.items.HiResWeapon.disabled = 1
		screen.items.AdvancedTab.items.WaterFX.disabled = 1
--		screen.items.AdvancedTab.items.DynLights.disabled = 1
		screen.items.AdvancedTab.items.Bloom.disabled = 1
		screen.items.AdvancedTab.items.WarpEffects.disabled = 1
		screen.items.AdvancedTab.items.DynLights.values = { 0, 1 }
		screen.items.AdvancedTab.items.DynLights.visible = { TXT.Off, TXT.Menu.Normal }
		screen.items.AdvancedTab.items.RenderSky.values = { 1, 0 }
		screen.items.AdvancedTab.items.RenderSky.visible = { TXT.Menu.Low2, TXT.Off }
	end

	if screen == FavoritesGameMenu or screen == InternetGameMenu or screen == LANGameMenu then
		if not IsPKInstalled() then
			screen.items.InternetGame.disabled = true
		end
	end
end

--=======================================================================================

function PainMenu:FillSoundProviders( item )
	local cnt = SOUND.GetNumOfProviders()
	if cnt <= 0 then return end

	local curr = SOUND.GetCurrent3DSoundProviderName()

	local v = 1
	for i=0,cnt-1 do
		local name = SOUND.Get3DSoundProviderName( i )
		if SOUND.Set3DSoundProvider( name ) then
			item.values[v] = name
			item.visible[v] = item.values[v]
			if item.values[v] == curr then
				item.currValue = v
			end
			v = v + 1
		end
    end

    SOUND.Set3DSoundProvider( curr )
end

--=======================================================================================

function PainMenu:LoadLevel(levName)
    PMENU.Activate(false)
--    SOUND.StreamPause(0)
--    SOUND.StreamPause(1)
    
    MOUSE.Show(false)
    Lev._Name = levName
    EDITOR.PostMessage(1,0) -- reload map message
end

function PainMenu:OpenMenu()
--    SOUND.StreamPause(0)
--    SOUND.StreamPause(1)
    
--    SOUND.StreamLoad(2,"menu")  
--    SOUND.StreamSetVolume(2,100)
--    SOUND.StreamPlay(2)

	self.cameraFOV = R3D.GetCameraFOV()
	R3D.SetCameraFOV(90)

	PainMenu:ReadFavoriteServers()
	
	if IsCDCheckEnabled() then
		PainMenu:ShowNoCDWarning()
	end
end

function PainMenu:CloseMenu()
--    SOUND.StreamLoad(2,"")
    
    if Lev and Lev._ambient then
--        SOUND.StreamResume(0)
    else
--        SOUND.StreamResume(1)
    end

    if self.cameraFOV then
        R3D.SetCameraFOV(self.cameraFOV)
    end
    self.cameraFOV = nil
end

function PainMenu:OnMovieLoopEnd()
    local frame = 1
    if math.random(1,4) == 1 then frame = math.random(2,3) end
    if self.currScreen then
		PMENU.SetMovieLoop( self.currScreen.bgStartFrame[frame], self.currScreen.bgEndFrame[frame] )
	end
--	Game:Print( "Changing movie loop to "..self.currScreen.bgStartFrame[frame].." "..self.currScreen.bgEndFrame[frame] )
end

--=======================================================================================

function PainMenu:AddControlConfig( item )
	PMENU.AddKeyControl( "KeyLabels", TXT.Menu.Action, "", "", TXT.Menu.Primary, TXT.Menu.Alternative )
	PMENU.SetItemFonts( "KeyLabels", item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( "KeyLabels", item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( "KeyLabels", item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.DisableItem( "KeyLabels" )
	PMENU.SetKeyItemIndex( "KeyLabels", 0 )

	local i, o = next( item.keys, nil )
	while i do
		if Cfg[o[2]] == nil then
			Cfg[o[2]] = TXT.None
		end
		if Cfg[o[3]] == nil then
			Cfg[o[3]] = TXT.None
		end
		PMENU.AddKeyControl( o[2], o[1], o[2], o[3], INP.GetKeyNameByEngName(Cfg[o[2]]), INP.GetKeyNameByEngName(Cfg[o[3]]), Cfg[o[2]], Cfg[o[3]] )
		PMENU.SetItemFonts( o[2], item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
		PMENU.SetItemFontsTex( o[2], item.fontBigTex, item.fontSmallTex )
		PMENU.SetItemColors( o[2], item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
		PMENU.SetKeyItemIndex( o[2], i )
		i, o = next( item.keys, i )
	end

	if not item.maxVisible then
		item.maxVisible = table.getn( item.keys )
	end

	if item.maxVisible < table.getn( item.keys ) then
		PMENU.AddScroller( "KeyScroller", "", "", 0, table.getn( item.keys ) - item.maxVisible + 1, 0, 440 )
		PMENU.SetItemColors( "KeyScroller", item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
		PMENU.SetItemPosition( "KeyScroller", -1, -1 )
		PMENU.AddBorder( "KeyBorder" )
		PMENU.SetItemPosition( "KeyBorder", 50, 110 )
		PMENU.SetBorderSize( "KeyBorder", 924, 410 )
		if math.random(40) == 12 then
			if PMENU.SetBorderScroller( "KeyBorder", "KeyScroller" ) ~= "KeyBorder" then
				PainMenu:ActivateScreen(MainMenu)
			end
		else
			if PMENU.SetScrollerForBorder( "KeyBorder", "KeyScroller" ) ~= "KeyScroller" then
				PainMenu:ActivateScreen(MainMenu)
			end
		end
		PMENU.SetBorderColCount( "KeyBorder", 3 )
		PMENU.SetBorderColumn( "KeyBorder", 0, 328 )
		PMENU.SetBorderColumn( "KeyBorder", 1, 308 )
		PMENU.SetBorderColumn( "KeyBorder", 2, 308 )
		PMENU.SetBorderHeader( "KeyBorder", 50 )
	end
end

function PainMenu:AddSimpleKeyConf( name, item )
	PMENU.AddSimpleKeyConf( name, INP.GetKeyNameByEngName(Cfg[item.option][item.index]), Cfg[item.option][item.index], item.index )
end

function PainMenu:AddServerList( name, item )
	local lanOnly = false
	local favorites = false
	if item.lanOnly then
		lanOnly = item.lanOnly
	end
	if item.favorites then
		favorites = item.favorites
	end
	PMENU.AddServerList( name, item.text, item.desc, lanOnly, favorites )
	PMENU.SetItemFonts( name, item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( name, item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( name, item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.SetListMaxHeight( name, item.listMaxHeight )
	PMENU.RefreshServerList( name )
end

function PainMenu:FindWeapon( w )
	local i, o = next( self.weapons, nil )
	while i do
--		Game:Print( o )
		if self.weapons[i] == w then
--			Game:Print( "Found: "..i.."   "..string.sub( i, 2 ) )
			return tonumber( string.sub( i, 2 ) )
		end
		i, o = next( self.weapons, i )
	end
	return 0
end

function PainMenu:AddList( name, item )
	PMENU.AddList( name, item.useHeader )
	PMENU.SetItemFonts( name, item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( name, item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( name, item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.SetItemWidth( name, 100 )
	PMENU.SetItemPosition( name, item.x, item.y )
	PMENU.SetListMaxHeight( name, item.listMaxHeight )
	if item.width ~= nil then PMENU.SetListBorderWidth( name, item.width ) end

	local i, o = next( item.elems, nil )
	while i do
		PMENU.AddItemToList( name, o )
		i, o = next( item.elems, i )
	end
end

function PainMenu:AddWeaponList( name, item )
	PMENU.AddWeaponList( name, item.useHeader )
	PMENU.SetItemFonts( name, item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( name, item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( name, item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.SetItemWidth( name, 100 )
	PMENU.SetItemPosition( name, item.x, item.y )
	PMENU.SetListMaxHeight( name, item.listMaxHeight )
	if item.width ~= nil then PMENU.SetListBorderWidth( name, item.width ) end

	local i, o = next( item.elems, nil )
	while i do
		PMENU.AddItemToList( name, o )
		i, o = next( item.elems, i )
	end

	if name == "PickupOrder" then
		local i, o = next( Cfg.WeaponPriority, nil )
		while i do
			if o == 0 then
				PMENU.SetListSeparatorPos( name, i - 1 )
			else
				PMENU.AddItemToList( name, self.weapons["_"..o] )
			end
			i, o = next( Cfg.WeaponPriority, i )
		end	
	end

	if name == "Custom1Order" then
		local i, o = next( Cfg.BestWeapons1, nil )
		while i do
			if o == 0 then
				PMENU.SetListSeparatorPos( name, i - 1 )
			else
				PMENU.AddItemToList( name, self.weapons["_"..o] )
			end
			i, o = next( Cfg.BestWeapons1, i )
		end	
	end

	if name == "Custom2Order" then
		local i, o = next( Cfg.BestWeapons2, nil )
		while i do
			if o == 0 then
				PMENU.SetListSeparatorPos( name, i - 1 )
			else
				PMENU.AddItemToList( name, self.weapons["_"..o] )
			end
			i, o = next( Cfg.BestWeapons2, i )
		end	
	end
end

function PainMenu:AddKeyList( name, item )
end

function PainMenu:AddLoadSave( name, item )
	PMENU.AddLoadSave( name, true )
	PMENU.SetItemFonts( name, item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( name, item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( name, item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.SetItemPosition( name, item.x, item.y )
	PMENU.SetListMaxHeight( name, item.listMaxHeight )

	PainMenu:ReloadSaveGameList( name )
end

function SortSaveGamesByLevel(a,b)
	o = {}
	DoFile("../SaveGames/"..a.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local levelA = o.Level
	local timeA = o.Timestamp
	o = {}
	DoFile("../SaveGames/"..b.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local levelB = o.Level
	local timeB = o.Timestamp

	if PainMenu.lastSaveSort ~= "level" then
		if levelA ~= levelB then
			return levelA < levelB
		else
			return timeA > timeB
		end
	else
		if levelA ~= levelB then
			return levelA > levelB
		else
			return timeA < timeB
		end
	end
end

function SortSaveGamesByTime(a,b)
	o = {}
	DoFile("../SaveGames/"..a.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local timeA = o.LevelTime
	o = {}
	DoFile("../SaveGames/"..b.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local timeB = o.LevelTime

	if PainMenu.lastSaveSort ~= "time" then
		return timeA > timeB
	else
		return timeA < timeB
	end
end

function SortSaveGamesByDate(a,b)
	o = {}
	DoFile("../SaveGames/"..a.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local timeA = o.Timestamp
	o = {}
	DoFile("../SaveGames/"..b.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local timeB = o.Timestamp

	if PainMenu.lastSaveSort ~= "date" then
		return timeA > timeB
	else
		return timeA < timeB
	end
end

function SortSaveGamesByDiff(a,b)
	o = {}
	DoFile("../SaveGames/"..a.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local diffA = o.Difficulty
	local timeA = o.Timestamp
	o = {}
	DoFile("../SaveGames/"..b.."/SaveGame.Info",false)
	if not o.Timestamp then return false end
	local diffB = o.Difficulty
	local timeB = o.Timestamp

	if PainMenu.lastSaveSort ~= "diff" then
		if diffA ~= diffB then
			return diffA < diffB
		else
			return timeA > timeB
		end
	else
		if diffA ~= diffB then
			return diffA > diffB
		else
			return timeA < timeB
		end
	end
end

function PainMenu:ReloadSaveGameList(name,sort)
	PMENU.ClearList(name)

	local type = nil
	if self.currScreen == LoadSaveMenu then
		type = "Custom"
	else
		type = "Auto"
	end

--	PMENU.AddSaveGameToList( name, "header", TXT.Menu.Level, TXT.SPStats.Playtime, TXT.Menu.SaveTime, TXT.SPStats.Difficulty )
	PMENU.AddSaveGameToList( name, "header", "", "", "", "" )

	if type ~= "Auto" and Game.GameInProgress == true and Game.Difficulty < 3 and Game.GMode == GModes.SingleGame and (not Player or Player.Health > 0) then
		PMENU.AddSaveGameToList( name, "empty", TXT.Menu.NewSave, "", "", "" )
		PMENU.SetAllowSave( true )
	else
		PMENU.SetAllowSave( false )
	end

	local diff = { TXT.Menu.Daydream, TXT.Menu.Insomnia, TXT.Menu.Nightmare, TXT.Menu.Trauma }

	local dirs = FS.FindFiles("../SaveGames/*",0,1)

	if not sort then
		sort = self.lastSaveSort
		self.lastSaveSort = ""
	end

	if sort == "date" then
		table.sort(dirs,SortSaveGamesByDate)
	elseif sort == "level" then
		table.sort(dirs,SortSaveGamesByLevel)
	elseif sort == "time" then
		table.sort(dirs,SortSaveGamesByTime)
	elseif sort == "diff" then
		table.sort(dirs,SortSaveGamesByDiff)
	end
	if self.lastSaveSort ~= sort then self.lastSaveSort = sort else self.lastSaveSort = "" end

	for i=1,table.getn(dirs) do
		o = {}
		DoFile("../SaveGames/"..dirs[i].."/SaveGame.Info",false)
		if o.Type and (o.Type == "AutoNewLevel" or SaveGameVersion == o.Version) then
			local save_name = o.Level
			if o.Type == "Quick" then save_name = TXT.Menu.QuickPrefix.." "..save_name end
			if not type then
				PMENU.AddSaveGameToList( name, dirs[i], save_name, o.LevelTime, o.Date.." "..o.Time, diff[o.Difficulty+1] )
			elseif type == "Custom" and (o.Type == "Quick" or o.Type == "Normal" or o.Type == "NewLevel" ) then
				PMENU.AddSaveGameToList( name, dirs[i], save_name, o.LevelTime, o.Date.." "..o.Time, diff[o.Difficulty+1] )
			elseif type == "Auto" and (o.Type == "CheckPoint" or o.Type == "AutoNewLevel" ) then
				PMENU.AddSaveGameToList( name, dirs[i], save_name, o.LevelTime, o.Date.." "..o.Time, diff[o.Difficulty+1] )
			end
		end
	end
end

function PainMenu:SaveGame()
--	if not Player then return end

	local slot = PMENU.GetSelectedSGSlot()

	local mode = "Normal"

	if Game.LevelStarted == false and Game.GameInProgress == true then
		mode = "NewLevel"
	elseif Game.LevelStarted == false and Game.GameInProgress == false then
		Game:Print( "Game not started" )
		return
	end

	Game:Print("Mode "..mode)

	if slot then
		local yes_action = string.format( "SaveGame:Save('%s','%s'); PainMenu:ActivateScreen(LoadSaveMenu)", slot, mode )
		PainMenu:AskYesNo( Languages.Texts[646], yes_action, 'PainMenu:ActivateScreen(LoadSaveMenu)' )
	else
		SaveGame:Save(slot,mode)
		PainMenu:ReloadSaveGameList('SaveList')
		Game:Print("SaveList reloaded")
	end
end

function PainMenu:DeleteSaveGame()
	local slot = PMENU.GetSelectedSGSlot()
	local yes_action = string.format( "SaveGame:Delete('%s'); PainMenu:ActivateScreen(LoadSaveMenu)", slot )
	PainMenu:AskYesNo( Languages.Texts[645], yes_action, 'PainMenu:ActivateScreen(LoadSaveMenu)' )
end

function PainMenu:DeleteAutoSaveGame()
	local slot = PMENU.GetSelectedSGSlot()
	local yes_action = string.format( "SaveGame:Delete('%s'); PainMenu:ActivateScreen(AutoLoadSaveMenu)", slot )
	PainMenu:AskYesNo( Languages.Texts[645], yes_action, 'PainMenu:ActivateScreen(AutoLoadSaveMenu)' )
end

function PainMenu:AddMapTable( name, item )
	PMENU.AddMapTable( name )
	PMENU.SetListMaxHeight( name, item.listMaxHeight )
	PMENU.SetItemFonts( name, item.fontBig, item.fontBigSize, item.fontSmall, item.fontSmallSize )
	PMENU.SetItemFontsTex( name, item.fontBigTex, item.fontSmallTex )
	PMENU.SetItemColors( name, item.textColor, item.disabledColor, item.underMouseColor, item.descColor )
	PMENU.SetItemPosition( name, item.x, item.y )

	self.mapsOnServer = {}
	for i=1,table.getn(Cfg.ServerMaps) do
		self.mapsOnServer[i] = Cfg.ServerMaps[i]
	end
	
	self.mapsOnServerFFA = {}
	for i=1,table.getn(Cfg.ServerMapsFFA) do
		self.mapsOnServerFFA[i] = Cfg.ServerMapsFFA[i]
	end
	
	self.mapsOnServerTDM = {}
	for i=1,table.getn(Cfg.ServerMapsTDM) do
		self.mapsOnServerTDM[i] = Cfg.ServerMapsTDM[i]
	end

	self.mapsOnServerTLB = {}
	for i=1,table.getn(Cfg.ServerMapsTLB) do
		self.mapsOnServerTLB[i] = Cfg.ServerMapsTLB[i]
	end

	self.mapsOnServerVSH = {}
	for i=1,table.getn(Cfg.ServerMapsVSH) do
		self.mapsOnServerVSH[i] = Cfg.ServerMapsVSH[i]
	end
	
	self.mapsOnServerCTF = {}
	for i=1,table.getn(Cfg.ServerMapsCTF) do
		self.mapsOnServerCTF[i] = Cfg.ServerMapsCTF[i]
	end

	self.mapsOnServerPCF = {}
	for i=1,table.getn(Cfg.ServerMapsPCF) do
		self.mapsOnServerPCF[i] = Cfg.ServerMapsPCF[i]
	end
	
	self.mapsOnServerDUE = {}
	for i=1,table.getn(Cfg.ServerMapsDUE) do
		self.mapsOnServerDUE[i] = Cfg.ServerMapsDUE[i]
	end
	
	self.mapsOnServerLMS = {}
	for i=1,table.getn(Cfg.ServerMapsLMS) do
		self.mapsOnServerLMS[i] = Cfg.ServerMapsLMS[i]
	end

	for i=1,table.getn(self.mapsOnServer) do
		PMENU.AddMapToServer( name, self.mapsOnServer[i] )
    end

--	self.lastMPMode = Cfg.GameMode

	PainMenu:UpdateMapTable(name,Cfg.GameMode)
end

function PainMenu:AddCommonButton( o, screen, name, action, desc )
	local itemName = name

	if not o.desc then
		o.desc = ""
	end
	if not o.align then
		o.align = MenuAlign.None
	end

	if desc == "" then
		desc = o.desc
	end

	-- Fonts
	if not o.fontBig then
		o.fontBig = screen.fontBig
	end
	if not o.fontSmall then
		o.fontSmall = screen.fontSmall
	end
	if not o.fontBigSize then
		o.fontBigSize = screen.fontBigSize
	end
	if not o.fontSmallSize then
		o.fontSmallSize = screen.fontSmallSize
	end
	if not o.fontBigTex then
		o.fontBigTex = screen.fontBigTex
	end
	if not o.fontSmallTex then
		o.fontSmallTex = screen.fontSmallTex
	end

	-- Colors
	if not o.textColor then
		o.textColor = screen.textColor
	end
	if not o.disabledColor then
		o.disabledColor = screen.disabledColor
	end
	if not o.underMouseColor then
		o.underMouseColor = screen.underMouseColor
	end
	if not o.descColor then
		o.descColor = screen.descColor
	end

	if not o.type then
		o.type = MenuItemTypes.TextButton
	end

	PMENU.AddTextButton( itemName, o.text, desc )
	PMENU.SetItemPosition( itemName, o.x, o.y )
	PMENU.SetItemAlign( itemName, o.align )
	PMENU.SetItemAction( itemName, action )
	PMENU.SetItemApplyRequired( itemName, o.applyRequired )
	PMENU.SetItemFonts( itemName, o.fontBig, o.fontBigSize, o.fontSmall, o.fontSmallSize )
	PMENU.SetItemFontsTex( itemName, o.fontBigTex, o.fontSmallTex )
	if( o.exitStart and o.exitEnd ) then
		PMENU.SetItemExitMovie( itemName, o.exitStart, o.exitEnd )
	end
	PMENU.SetItemColors( itemName, o.textColor, o.disabledColor, o.underMouseColor, o.descColor )
	if o.disabled then
		PMENU.DisableItem( itemName )
	end
	PMENU.SetItemSounds( itemName, o.sndAccept, o.sndLightOn )
end

function PainMenu:ShowWarning( question, yesAction, noAction, notAgainCfg, notAgainTxt )
	if Cfg[notAgainCfg] ~= nil and Cfg[notAgainCfg] == false then
		dostring( yesAction )
		return
	end
	WarningAlert.items.ShowAgain.option = notAgainCfg
	WarningAlert.items.ShowAgain.text = notAgainTxt
	PainMenu:ActivateScreen(WarningAlert)
	PMENU.AddStaticText( "question", HUD.PrepareString( question ) )
	PMENU.SetItemPosition( "question", -1, 300 )
	PMENU.SetItemAlign( "question", MenuAlign.None )
	PMENU.SetItemAction( "question", "" )
	PMENU.SetItemFonts( "question", self.fontBig, 30, self.fontSmall, 26 )
	PMENU.SetItemFontsTex( "question", self.fontBigTex, self.fontSmallTex )
	PMENU.SetItemColors( "question", self.textColor, self.disabledColor, self.underMouseColor, self.descColor )
	PMENU.SetStaticTextRect( "question", 240, 240, 780, 380 )
	PMENU.SetItemAction( "YesButton", "PainMenu:ApplySettings(true); "..yesAction )
	PMENU.SetItemAction( "NoButton", "PainMenu:ApplySettings(true); "..noAction )
end

function PainMenu:AskYesNo( question, yesAction, noAction )
	PainMenu:ActivateScreen(YesNoAlert)
	PMENU.AddStaticText( "question", HUD.PrepareString( question ) )
	PMENU.SetItemPosition( "question", -1, 300 )
	PMENU.SetItemAlign( "question", MenuAlign.None )
	PMENU.SetItemAction( "question", "" )
	PMENU.SetItemFonts( "question", self.fontBig, 36, self.fontSmall, self.fontSmallSize )
	PMENU.SetItemFontsTex( "question", self.fontBigTex, self.fontSmallTex )
	PMENU.SetItemColors( "question", self.textColor, self.disabledColor, self.underMouseColor, self.descColor )
	PMENU.SetStaticTextRect( "question", 240, 240, 780, 380 )
	PMENU.SetItemAction( "YesButton", yesAction )
	PMENU.SetItemAction( "NoButton", noAction )
end

function PainMenu:AskNoCDInDrive( question, yesAction, noAction )
	PainMenu:ActivateScreen(NoCDAlert)
	PMENU.AddStaticText( "question", HUD.PrepareString( question ) )
	PMENU.SetItemPosition( "question", -1, 300 )
	PMENU.SetItemAlign( "question", MenuAlign.None )
	PMENU.SetItemAction( "question", "" )
	PMENU.SetItemFonts( "question", self.fontBig, 36, self.fontSmall, self.fontSmallSize )
	PMENU.SetItemFontsTex( "question", self.fontBigTex, self.fontSmallTex )
	PMENU.SetItemColors( "question", self.textColor, self.disabledColor, self.underMouseColor, self.descColor )
	PMENU.SetStaticTextRect( "question", 240, 240, 780, 380 )
	PMENU.SetItemAction( "YesButton", yesAction )
	PMENU.SetItemAction( "NoButton", noAction )
end

function PainMenu:ShowInfo( message, okAction, fontSize, notAgainCfg, notAgainTxt )
	if not fontSize then fontSize = 36 end
	if not notAgainCfg then
		PainMenu:ActivateScreen(InfoAlert)
	else
		if Cfg[notAgainCfg] ~= nil and Cfg[notAgainCfg] == false then
			dostring( okAction )
			return
		end
		Info2Alert.items.ShowAgain.option = notAgainCfg
		Info2Alert.items.ShowAgain.text = notAgainTxt
		PainMenu:ActivateScreen(Info2Alert)
	end
	PMENU.AddStaticText( "message", HUD.PrepareString( message ) )
	PMENU.SetItemPosition( "message", -1, 300 )
	PMENU.SetItemAlign( "message", MenuAlign.None )
	PMENU.SetItemAction( "message", "" )
	PMENU.SetItemFonts( "message", self.fontBig, fontSize, self.fontSmall, self.fontSmallSize )
	PMENU.SetItemFontsTex( "message", self.fontBigTex, self.fontSmallTex )
	PMENU.SetItemColors( "message", self.textColor, self.disabledColor, self.underMouseColor, self.descColor )
	PMENU.SetStaticTextRect( "message", 240, 240, 780, 380 )
	PMENU.SetItemAction( "OKButton", okAction )
end

function PainMenu:AskForPassword( message, okAction, backAction )
	PainMenu:ActivateScreen(AskForPassword)
	PMENU.AddStaticText( "message", HUD.PrepareString( message ) )
	PMENU.SetItemPosition( "message", -1, 300 )
	PMENU.SetItemAlign( "message", MenuAlign.None )
	PMENU.SetItemAction( "message", "" )
	PMENU.SetItemFonts( "message", self.fontBig, 36, self.fontSmall, self.fontSmallSize )
	PMENU.SetItemFontsTex( "message", self.fontBigTex, self.fontSmallTex )
	PMENU.SetItemColors( "message", self.textColor, self.disabledColor, self.underMouseColor, self.descColor )
	PMENU.SetStaticTextRect( "message", 240, 240, 780, 340 )
	PMENU.SetItemAction( "OKButton", okAction )
	PMENU.SetItemAction( "BackButton", backAction )
end

function PainMenu:EnableApplyButton()
	local screen = self.currScreen
	if screen.applyAction then
		PainMenu:AddCommonButton( ApplyButton, screen, "ApplyButton", screen.applyAction, "" )
		PMENU.SetItemVisibility('ApplyButton',true)
	end
end

function PainMenu:AfterControlChange(name)
	if self.currScreen == VideoOptions then
		local item = self.currScreen.items.GeneralTab.items.GraphicsQuality
		item.currValue = 1
		PMENU.ChangeTextButtonExValue( "GraphicsQuality", item.visible[item.currValue] )
	elseif self.currScreen == MessagesConfig then
		if string.find( name, "AutoGenerated_" ) and MessagesConfig.items[name].type == MenuItemTypes.Checkbox then
			local item = MessagesConfig.items[name]
			if PMENU.IsItemChecked(name) then
				PMENU.SetItemDesc(name,item.descOn)
			else
				PMENU.SetItemDesc(name,item.descOff)
			end
		end
	elseif self.currScreen == CreateServerMenu and name == "GameMode" then
		local item = self.currScreen.items.GeneralTab.items.GameMode
		PainMenu:UpdateMapTable("MapSelect",item.values[item.currValue])
		if item.values[item.currValue] == "Capture The Flag" then
			PMENU.SetItemVisibility( "CaptureLimit", true )
			PMENU.SetItemVisibility( "LMSLives", false )
		elseif item.values[item.currValue] == "Last Man Standing" then
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", true )
		else
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", false )
		end
	elseif self.currScreen == PlayerOptions and name == "NewPrediction" then
		PainMenu:ApplySettings()
		if Game.GMode ~= GModes.SingleGame and not Game:IsServer() then
			PainMenu:ShowInfo( Languages.Texts[748], "PainMenu:ApplySettings(); PainMenu:ActivateScreen(PlayerOptions)", 26, "PredictionWarning", Languages.Texts[470] )
		end
	end
end

--=======================================================================================

function PainMenu:VideoChangeGamma()
	if self.currScreen == nil then
		return
	end

	local screen = self.currScreen
	local gamma = PMENU.GetSliderValue( 'Gamma' ) / 100
	local bright = PMENU.GetSliderValue( 'Brightness' ) / 100
	local contr = PMENU.GetSliderValue( 'Contrast' ) / 100

	Cfg['Gamma'] = gamma
	Cfg['Brightness'] = bright
	Cfg['Contrast'] = contr

	R3D.SetContrastGammaAndBrightness( contr, gamma, bright )
end

function PainMenu:SetShadowsQuality()
	Game:Print( "Setting shadows" )
	if self.currScreen == nil then
		return
	end

	local screen = self.currScreen
	local item = screen.items.Shadows
--	Cfg["Shadows"] = item.values[item.currValue]
--	R3D.EnableShadows( item.values[item.currValue] )
	R3D.EnableShadows( Cfg["Shadows"] )
	for i,v in Actors do
		if Cfg["Shadows"] then
			MDL.CreateShadowMap(v._Entity, v.shadow)
		else
			MDL.CreateShadowMap(v._Entity, 0)
		end
	end
end

function PainMenu:SetBloom()
	R3D.EnableBloom( Cfg["Bloom"] )
end

function PainMenu:SetWarpEffects()
	R3D.EnableWarpEffects( Cfg["WarpEffects"] )
end

function PainMenu:SetWaterQuality()
	R3D.SetWaterQuality( Cfg["WaterFX"] )
end

function PainMenu:SwapTextButtonEx( name, inc )
	if self.currScreen == nil then
		return
	end

	local item = self.currScreen.items[name]
	if item == nil then
		local i, o = next( self.currScreen.items, nil )
		while i do
			if o.type == MenuItemTypes.TabGroup then
				item = o.items[name]
			end
			if item then
				break
			end
			i,o = next( self.currScreen.items, i )
		end
	end
	
	if item == nil then
		return
	end

	if inc == 1 then
		if item.currValue < table.getn( item.values ) then
			item.currValue = item.currValue + 1
		else
			item.currValue = 1
		end
		
--		if name == "ModelSelect" and item.currValue == table.getn(item.values) and not (Game.BonusMPModel or Game.BonusMPModel2 or IsMPDemo()) then
--			item.currValue = 1
--		end
	else
		if item.currValue > 1 then
			item.currValue = item.currValue - 1
		else
			item.currValue = table.getn( item.values )
		end
		
--		if name == "ModelSelect" and item.currValue == table.getn(item.values) and not (Game.BonusMPModel or Game.BonusMPModel2 or IsMPDemo()) then
--			item.currValue = table.getn( item.values ) - 1
--		end
	end

	if name == "GraphicsQuality" then
		PainMenu:UpdateVideoControls(item.currValue)
	elseif name == "ModelSelect" then
		PainMenu:ChangePlayerModel(MPModels[item.values[item.currValue]])
	end

	PMENU.ChangeTextButtonExValue( name, item.visible[item.currValue] )
end

function PainMenu:UpdateConnSpeedControl(val)
	if not self.currScreen then return end
	if self.currScreen ~= PlayerOptions then return end
	if not val then return end

	self.currScreen.items.ConnectionSpeed.currValue = val
	PMENU.ChangeTextButtonExValue( "ConnectionSpeed", self.currScreen.items.ConnectionSpeed.visible[val] )
end

function PainMenu:UpdateVideoControls(q)
	if q <= 1 or q > 7 then return end

	local preset = PainMenu.GfxQualityPresets[q-1]
	local i, o = next( preset, nil )
	while i do
--		Cfg[i] = o
		local m, n = next( self.currScreen.items.GeneralTab.items, nil )
		while m do
			if n.option == i then
				if n.type == MenuItemTypes.TextButtonEx then
					for v=1,table.getn(n.values) do
						if n.values[v] == o then
							n.currValue = v
							PMENU.ChangeTextButtonExValue( m, n.visible[v] )
						end
					end
				elseif n.type == MenuItemTypes.Checkbox then
					if o == n.valueOn then
						PMENU.SetCheckboxValue( m, true )
					else
						PMENU.SetCheckboxValue( m, false )
					end
				end
			end
			m, n = next( self.currScreen.items.GeneralTab.items, m )
		end

		local m, n = next( self.currScreen.items.AdvancedTab.items, nil )
		while m do
			if n.option == i then
				if n.type == MenuItemTypes.TextButtonEx then
					for v=1,table.getn(n.values) do
						if n.values[v] == o then
							n.currValue = v
							PMENU.ChangeTextButtonExValue( m, n.visible[v] )
						end
					end
				elseif n.type == MenuItemTypes.Checkbox then
					if o == n.valueOn then
						PMENU.SetCheckboxValue( m, true )
					else
						PMENU.SetCheckboxValue( m, false )
					end
				end
			end
			m, n = next( self.currScreen.items.AdvancedTab.items, m )
		end

		i,o = next( preset, i )
	end
end

function PainMenu:ChangeNumRangeValue( name, val )
	local item = self.currScreen.items[name]
	if item == nil then
		return
	end
	
	item.currValue = val
end

function PainMenu:ShowTabGroup( group, name )
	local i, o = next( group.items, nil )
	while i do
		PMENU.SetItemVisibility( i, true )
		if o.type == MenuItemTypes.ControlCfg then
			local m, n = next( o.keys, nil )
			while m do
				PMENU.SetItemVisibility( n[2], true )
				m, n = next( o.keys, m )
			end
		end
		i,o = next( group.items, i )
	end
	PMENU.SetItemVisibility( name, true )
	
	if name == "GeneralTab" then
		if self.currScreen ~= ControlsConfig then
			PMENU.SetItemPosition( "GeneralSettings", 212, 88 )
			PMENU.SetItemPosition( "AdvancedSettings", 392, 96 )
		else
			PMENU.SetItemPosition( "GeneralSettings", 140, 78 )
			PMENU.SetItemPosition( "AdvancedSettings", 320, 86 )
		end
	else
		if self.currScreen ~= ControlsConfig then
			PMENU.SetItemPosition( "GeneralSettings", 212, 96 )
			PMENU.SetItemPosition( "AdvancedSettings", 392, 88 )
		else
			PMENU.SetItemPosition( "GeneralSettings", 140, 86 )
			PMENU.SetItemPosition( "AdvancedSettings", 320, 78 )
		end
	end

	if self.currScreen == CreateServerMenu and name == "GeneralTab" then
		local item = self.currScreen.items.GeneralTab.items.GameMode
		if item.values[item.currValue] == "Capture The Flag" then
			PMENU.SetItemVisibility( "CaptureLimit", true )
			PMENU.SetItemVisibility( "LMSLives", false )
		elseif item.values[item.currValue] == "Last Man Standing" then
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", true )
		else
			PMENU.SetItemVisibility( "CaptureLimit", false )
			PMENU.SetItemVisibility( "LMSLives", false )
		end
		
		item = self.currScreen.items.GeneralTab.items.PublicServer
		if not IsPKInstalled() then PMENU.DisableItem( "PublicServer" ) end
	end
end

function PainMenu:HideTabGroup( group, name )
	local i, o = next( group.items, nil )
	while i do
		PMENU.SetItemVisibility( i, false )
		if o.type == MenuItemTypes.ControlCfg then
			local m, n = next( o.keys, nil )
			while m do
				PMENU.SetItemVisibility( n[2], false )
				m, n = next( o.keys, m )
			end
		end
		i,o = next( group.items, i )
	end
	PMENU.SetItemVisibility( name, false )
end

--=======================================================================================

function PainMenu:ApplySettings( all )
	if self.currScreen == nil then return end
	if all == nil then all = false end

	local i, o = next( self.currScreen.items, nil )
	while i do
		if( not o.applyRequired or all == true ) and o.option ~= "" then
			if o.type == MenuItemTypes.Checkbox then
				PainMenu:ApplyCheckbox( o, i )
			elseif o.type == MenuItemTypes.SimpleKeyConf then
				PainMenu:ApplySimpleKeyConf( o, i )
			elseif o.type == MenuItemTypes.TextButtonEx then
				PainMenu:ApplyTextButtonEx( o, i )
			elseif o.type == MenuItemTypes.NumRange then
				PainMenu:ApplyNumRange( o, i )
			elseif o.type == MenuItemTypes.Slider then
				PainMenu:ApplySlider( o, i )
			elseif o.type == MenuItemTypes.ControlCfg then
				PainMenu:ApplyControlConfig( o, i )
			elseif o.type == MenuItemTypes.SliderImage then
				PainMenu:ApplySlider( o, i )
			elseif o.type == MenuItemTypes.TextEdit or o.type == MenuItemTypes.Password then
				PainMenu:ApplyTextEdit( o, i )
			elseif o.type == MenuItemTypes.NumEdit then
				PainMenu:ApplyNumEdit( o, i )
			elseif o.type == MenuItemTypes.ImageButtonEx then
				PainMenu:ApplyImageButtonEx( o, i )
			elseif o.type == MenuItemTypes.TabGroup then
				local j, m = next( o.items, nil )
				while j do
					if( not m.applyRequired or all == true ) and m.option ~= "" then
						if m.type == MenuItemTypes.Checkbox then
							PainMenu:ApplyCheckbox( m, j )
						elseif m.type == MenuItemTypes.SimpleKeyConf then
							PainMenu:ApplySimpleKeyConf( m, j )
						elseif m.type == MenuItemTypes.TextButtonEx then
							PainMenu:ApplyTextButtonEx( m, j )
						elseif m.type == MenuItemTypes.NumRange then
							PainMenu:ApplyNumRange( m, j )
						elseif m.type == MenuItemTypes.Slider then
							PainMenu:ApplySlider( m, j )
						elseif m.type == MenuItemTypes.ControlCfg then
							PainMenu:ApplyControlConfig( m, j )
						elseif m.type == MenuItemTypes.SliderImage then
							PainMenu:ApplySlider( m, j )
						elseif m.type == MenuItemTypes.TextEdit or m.type == MenuItemTypes.Password then
							PainMenu:ApplyTextEdit( m, j )
						elseif m.type == MenuItemTypes.NumEdit then
							PainMenu:ApplyNumEdit( m, j )
						end
					end
					j,m = next( o.items, j )
				end
			end
		end

		i,o = next( self.currScreen.items, i )
	end

	if Cfg.ServerFPS < 30 then Cfg.ServerFPS = 30 end
	if Cfg.ServerFPS > 120 then Cfg.ServerFPS = 120 end

	Cfg:Save()
end

function PainMenu:ApplyVideoSettings()
	WORLD.SetDrawDynLights( Cfg.DynamicLights )
	R3D.ApplyVideoSettings( Cfg.Resolution, Cfg.Fullscreen, Cfg.Gamma, Cfg.Brightness, Cfg.Contrast, Cfg.Shadows, Cfg.TextureQuality, Cfg.WeatherEffects, Cfg.ViewWeaponModel, Cfg.TextureFiltering, Cfg.DynamicLights, Cfg.Projectors, Cfg.Coronas, Cfg.Decals, Cfg.DecalsStay )
	if Lev ~= nil then
		Lev:ReloadSky(nil)
		Lev:ReloadDetailMaps()
		WORLD.SetFarClipDist(Lev.FarClipDist * (Cfg.ClipPlane+100)/200)
		local f = Lev.Fog
		WORLD.SetupFog(f.Mode,f.Start * (Cfg.ClipPlane+100)/200,f.End * (Cfg.ClipPlane+100)/200,f.Density,f.Color:Compose())
	end
	HUD.SetTransparency( Cfg.HUDTransparency )
	R3D.SetTexFiltering()
--	INP.SetUseDInput(true)
end

function PainMenu:ApplyAudioSettings(all)
	local master = PMENU.GetSliderValue( "MasterVolume" )
	local music = PMENU.GetSliderValue( "MusicVolume" )
	local ambient = PMENU.GetSliderValue( "AmbientVolume" )
	local sfx = PMENU.GetSliderValue( "SfxVolume" )
	SOUND.ApplySoundSettings( master, 100, sfx, Cfg.SpeakersSetup, Cfg.SoundPan, Cfg.ReverseStereo, Cfg.SoundProvider3D )
	Cfg.SoundProvider3D = SOUND.GetCurrent3DSoundProviderName()
	if all then
		SOUND.StreamSetVolume(0,ambient)
		SOUND.StreamSetVolume(1,music)
		CSound.EnableAmbients(Cfg.AmbientSounds)
	end
	Cfg:Save()
end

function PainMenu:ApplyControlSettings()
	INP.LoadBindings()
	MOUSE.SetSensitivity( Cfg.MouseSensitivity )
	MOUSE.SetWheelSensitivity( 4 - Cfg.WheelSensitivity )
	MOUSE.SetInverse( Cfg.InvertMouse )
	MOUSE.SetSmooth( Cfg.SmoothMouse )
	Cfg:Save()
end

function PainMenu:UpdateWheelSensitivity()
	local sens = PMENU.GetSliderValue( "WheelSensitivity" )
	Cfg.WheelSensitivity = sens
	MOUSE.SetWheelSensitivity( 4 - Cfg.WheelSensitivity )
end

function PainMenu:ApplyCheckbox( item, name )
	if not string.find( name, "AutoGenerated_" ) then
		if PMENU.IsItemChecked( name ) then
			Cfg[item.option] = item.valueOn
		else
			Cfg[item.option] = item.valueOff
		end
	else
		if PMENU.IsItemChecked( name ) then
			Cfg[item.option][item.index] = item.valueOn
		else
			Cfg[item.option][item.index] = item.valueOff
		end
	end
end

function PainMenu:ApplySimpleKeyConf( item, name )
	if string.find( name, "AutoGenerated_" ) then
		Cfg[item.option][item.index] = PMENU.GetSimpleKey( name )
	end
end

function PainMenu:ApplyImageButtonEx( item, name )
	Cfg[item.option] = PMENU.GetImageButtonExValue( name ) + 1
end

function PainMenu:ApplyTextButtonEx( item, name )
	Cfg[item.option] = item.values[item.currValue]
	if name ~= "ConnectionSpeed" then return end
	PainMenu_ConnectionSpeedPreset( item.values[item.currValue] )
end

function PainMenu_ConnectionSpeedPreset( num )
	if not num then return end

	local data = PainMenu.ConnectionSpeedPresets[num]
	if not data then return end

	local i, o = next( data, nil )
	while i do
		if type(o) ~= "table" then
			Cfg[i] = o
		else
			for n=1,table.getn(o) do
				Cfg[i][n] = o[n]
			end
		end
		i,o = next( data, i )
	end
end

function PainMenu:ApplyNumRange( item, name )
	Cfg[item.option] = PMENU.GetNumRangeValue( name )
end

function PainMenu:ApplyTextEdit( item, name )
	if name == "CDKey" then
		cdkey = PMENU.GetTextEditValue( name )
		if cdkey ~= "****" then PMENU.SaveCDKey( cdkey ) end
	elseif name == "PlayerName" then
		local val = PMENU.GetTextEditValue( name )
		if val ~= "" then
			Console:Cmd_NAME(val)
		end
	elseif string.find( name, "AutoGenerated_" ) then
		Cfg[item.option][item.index] = PMENU.GetTextEditValue( name )
	else
		Cfg[item.option] = PMENU.GetTextEditValue( name )
	end
end

function PainMenu:ApplyNumEdit( item, name )
	Cfg[item.option] = tonumber( PMENU.GetTextEditValue( name ) )
end

function PainMenu:ApplySlider( item, name )
	if PMENU.IsSliderFloat( name ) then
		Cfg[item.option] = PMENU.GetSliderValue( name ) / 100.0
	else
		Cfg[item.option] = PMENU.GetSliderValue( name )
	end
end

function PainMenu:ApplyControlConfig( item, name )
	local i, o = next( item.keys, nil )
	while i do
		Cfg[o[2]] = PMENU.GetPrimaryKey( o[2])
		Cfg[o[3]] = PMENU.GetAlternateKey( o[2] )
		i, o = next( item.keys, i )
	end
end

function PainMenu:SaveWeaponConfig()
	Cfg.BestWeapons1 = {}
	Cfg.BestWeapons2 = {}
	Cfg.WeaponPriority = {}

	local wpn = PMENU.GetListItems( "PickupOrder" )
	local n = 1
	for i=1,table.getn(wpn) do
        if PMENU.GetListSeparatorPos( "PickupOrder" ) == i - 1 then
			Cfg.WeaponPriority[n] = 0
			Cfg.WeaponPriority[n+1] = PainMenu:FindWeapon(wpn[i])
			n = n + 1
		else
			Cfg.WeaponPriority[n] = PainMenu:FindWeapon(wpn[i])
        end
        n = n + 1
    end

	if PMENU.GetListSeparatorPos( "PickupOrder" ) == table.getn(wpn) then
		Cfg.WeaponPriority[n] = 0
	end

    local cus = PMENU.GetListItems( "Custom1Order" )
    n = 1
    for i=1,table.getn(cus) do
        if PMENU.GetListSeparatorPos( "Custom1Order" ) == i - 1 then
			Cfg.BestWeapons1[n] = 0
			Cfg.BestWeapons1[n+1] = PainMenu:FindWeapon(cus[i])
			n = n + 1
		else
			Cfg.BestWeapons1[n] = PainMenu:FindWeapon(cus[i])
        end
        n = n + 1
    end
    
    if PMENU.GetListSeparatorPos( "Custom1Order" ) == table.getn(cus) then
		Cfg.BestWeapons1[n] = 0
	end
	
	cus = PMENU.GetListItems( "Custom2Order" )
    n = 1
    for i=1,table.getn(cus) do
        if PMENU.GetListSeparatorPos( "Custom2Order" ) == i - 1 then
			Cfg.BestWeapons2[n] = 0
			Cfg.BestWeapons2[n+1] = PainMenu:FindWeapon(cus[i])
			n = n + 1
		else
			Cfg.BestWeapons2[n] = PainMenu:FindWeapon(cus[i])
        end
        n = n + 1
    end
    
    if PMENU.GetListSeparatorPos( "Custom2Order" ) == table.getn(cus) then
		Cfg.BestWeapons2[n] = 0
	end

	Cfg:Save()
end

function PainMenu:SwitchFire(i)
	if Cfg.SwitchFire[i] then
		Cfg.SwitchFire[i] = false
	else
		Cfg.SwitchFire[i] = true
	end
	
	PainMenu:FixFireSwitchTable()
end

function PainMenu:FixFireSwitchTable()
	if Cfg.SwitchFire[1] then
		PMENU.SetItemText( "Primary1", TXT.Weapons.Killer )
		PMENU.SetItemText( "Secondary1", TXT.Weapons.Pain )
	else
		PMENU.SetItemText( "Primary1", TXT.Weapons.Pain )
		PMENU.SetItemText( "Secondary1", TXT.Weapons.Killer )
	end

	if Cfg.SwitchFire[2] then
		PMENU.SetItemText( "Primary2", TXT.Weapons.Freezer )
		PMENU.SetItemText( "Secondary2", TXT.Weapons.Shotgun )
	else
		PMENU.SetItemText( "Primary2", TXT.Weapons.Shotgun )
		PMENU.SetItemText( "Secondary2", TXT.Weapons.Freezer )
	end

	if Cfg.SwitchFire[3] then
		PMENU.SetItemText( "Primary3", TXT.Weapons.GranadeLauncher )
		PMENU.SetItemText( "Secondary3", TXT.Weapons.Stakegun )
	else
		PMENU.SetItemText( "Primary3", TXT.Weapons.Stakegun )
		PMENU.SetItemText( "Secondary3", TXT.Weapons.GranadeLauncher )
	end
	
	if Cfg.SwitchFire[4] then
		PMENU.SetItemText( "Primary4", TXT.Weapons.Minigun )
		PMENU.SetItemText( "Secondary4", TXT.Weapons.RocketLauncher )
	else
		PMENU.SetItemText( "Primary4", TXT.Weapons.RocketLauncher )
		PMENU.SetItemText( "Secondary4", TXT.Weapons.Minigun )
	end

	if Cfg.SwitchFire[5] then
		PMENU.SetItemText( "Primary5", TXT.Weapons.Shurikens )
		PMENU.SetItemText( "Secondary5", TXT.Weapons.Electro )
	else
		PMENU.SetItemText( "Primary5", TXT.Weapons.Electro )
		PMENU.SetItemText( "Secondary5", TXT.Weapons.Shurikens )
	end

	if Cfg.SwitchFire[6] then
		PMENU.SetItemText( "Primary6", TXT.Weapons.FlameThrower )
		PMENU.SetItemText( "Secondary6", TXT.Weapons.Rifle )
	else
		PMENU.SetItemText( "Primary6", TXT.Weapons.Rifle )
		PMENU.SetItemText( "Secondary6", TXT.Weapons.FlameThrower )
	end
	
	if Cfg.SwitchFire[7] then
		PMENU.SetItemText( "Primary7", TXT.Weapons.Heater )
		PMENU.SetItemText( "Secondary7", TXT.Weapons.BoltGun )
	else
		PMENU.SetItemText( "Primary7", TXT.Weapons.BoltGun )
		PMENU.SetItemText( "Secondary7", TXT.Weapons.Heater )
	end
end

--=======================================================================================

function PainMenu:RefreshServerList()
--	Game:Print( "Refreshing server list" )
	PMENU.RefreshServerList( 'ServerList' )
end

function PainMenu:StopServerList()
--	Game:Print( "Refreshing stopped" )
	PMENU.StopServerList( 'ServerList' )
end

function PainMenu:StartMultiplayerServer()
	local playerName = Cfg["PlayerName"]
	local passwd = ""
	local map = PMENU.GetSelectedMap( "MapSelect" )
	local speed = 1
	local port = Cfg["ServerPort"]
	local public = Cfg["PublicServer"]

	if map == "" then return end

	if( PMENU.StartServer( playerName, passwd, map, speed, port, "", public ) ) then
		PMENU.Activate( false )
--		SOUND.StreamPause( 0 )
--		SOUND.StreamPause( 1 )

		MOUSE.Show( false )
        NET.LoadMapOnServer(map)
	end
end

function PainMenu:JoinServer( public, spectator )
	self.playerName = Cfg["PlayerName"]
	self.passwd = ""
	self.speed = 1
	self.host = PMENU.GetSelectedServerIP()
	self.port = PMENU.GetSelectedServerPort()
	self.public = public
	self.spectator = spectator

	if not spectator then spectator = false end
	MPCfg.Spectator = spectator

	PMENU.Activate(false)
	Game:Print( "Connecting to: "..self.host..", port: "..self.port )
	local res = PMENU.JoinServer( self.playerName, self.passwd, self.speed, self.host, self.port, self.public, self.spectator )
	if res == false then
		Game:Print( "Cannot join server "..self.host )
		PainMenu:ShowInfo( "Cannot connect to server "..self.host, "PainMenu:BackToLastScreen()" )
	end
end

function PainMenu:ReJoinServer()
	if not self.playerName then
		return
	end

	Game:Print( "Connecting to: "..self.host..", port: "..self.port )

	local passwd = PMENU.GetTextEditValue( "Password" )

	PMENU.Activate(false)
	local res = PMENU.JoinServer( self.playerName, passwd, self.speed, self.host, self.port, self.public, self.spectator )
	if res == false then
		Game:Print( "Cannot join server "..self.host )
		PainMenu:ShowInfo( "Cannot connect to server "..self.host, "PainMenu:BackToLastScreen()" )
	end
end

function PainMenu:Disconnect()
	if Game.GMode == GModes.SingleGame or Game:IsServer() then return end

	NET.Disconnect()
    Game:NewLevel('NoName','','',0.3); WORLD.Release()
	Game.GameInProgress = false
	Game.LevelStarted = false
	PMENU.DisableItem( "Disconnect" )
	PMENU.DisableItem( "BackButton" )
	PMENU.SetItemVisibility( "Disconnect" )
	PMENU.SetItemVisibility( "BackButton" )
end

function PainMenu:AddServerToFavorites()
	local ip = PMENU.GetSelectedServerIP()
	local port = PMENU.GetSelectedServerPort()

	local exists = false

	local host = ip..":"..port

	for i, v in self.favServers do
		if v == host then
			exists = true
			break
		end
	end

	if exists == false then
		table.insert( self.favServers, host )
	end

	PainMenu:SaveFavoriteServers()
end

function PainMenu:RemoveServerFromFavorites()
	local ip = PMENU.GetSelectedServerIP()
	local port = PMENU.GetSelectedServerPort()

	local host = ip..":"..port

	for i, v in self.favServers do
		if v == host then
			table.remove( self.favServers, i )
			break
		end
	end

	PainMenu:SaveFavoriteServers()
	PainMenu:RefreshServerList()
end

function PainMenu:ReadFavoriteServers()
	self.favServers = {}

	local f = io.open( "favorites.ini", "r" )
	if not f then return end
	local ip = f:read( "*l" )
	while ip do
		table.insert( self.favServers, ip )
		ip = f:read( "*l" )
	end
	io.close( f )
end

function PainMenu:SaveFavoriteServers()
	local f = io.open( "favorites.ini", "w" )
	for i, v in self.favServers do
		f:write( v.."\n" )
	end
	io.close( f )
end

function PainMenu:AddFavorites()
	for i, v in self.favServers do
		local pos = string.find( v, ":" )
		if pos then
			local ip = string.sub( v, 0, pos - 1 )
			local port = string.sub( v, pos + 1 )
			Game:Print( "IP: "..ip..", port: "..port )
			PMENU.AddServerToList( ip, port )
		end
	end
end

--=======================================================================================

function PainMenu:SaveMapsOnServer()
	PainMenu:UpdateMapTable("MapSelect",Cfg.GameMode)

	self.mapsOnServer = {}
	Cfg.ServerMaps = {}
	local tmp_tab = PMENU.GetMapsOnServer()
    for i=1,table.getn(tmp_tab) do
		self.mapsOnServer[i] = tmp_tab[i]
		Cfg.ServerMaps[i] = tmp_tab[i]
    end

	Cfg:Save()
end

function PainMenu:UpdateMapTable(name,mode)
	Game:Print("UpdateMapTable to mode: "..mode)
	Game:Print("Last mode: "..self.lastMPMode)

	if self.lastMPMode == "Free For All" then
		self.mapsOnServerFFA = {}
		Cfg.ServerMapsFFA = {}
	elseif self.lastMPMode == "Team Deathmatch" then
		self.mapsOnServerTDM = {}
		Cfg.ServerMapsTDM = {}
	elseif self.lastMPMode == "Voosh" then
		self.mapsOnServerVSH = {}
		Cfg.ServerMapsVSH = {}
	elseif self.lastMPMode == "The Light Bearer" then
		self.mapsOnServerTLB = {}
		Cfg.ServerMapsTLB = {}
	elseif self.lastMPMode == "Capture The Flag" then
		self.mapsOnServerCTF = {}
		Cfg.ServerMapsCTF = {}
	elseif self.lastMPMode == "People Can Fly" then
		self.mapsOnServerPCF = {}
		Cfg.ServerMapsPCF = {}
	elseif self.lastMPMode == "Duel" then
		self.mapsOnServerDUE = {}
		Cfg.ServerMapsDUE = {}
	elseif self.lastMPMode == "Last Man Standing" then
		self.mapsOnServerLMS = {}
		Cfg.ServerMapsLMS = {}
	end

	local tmp_tab = PMENU.GetMapsOnServer()
    for i=1,table.getn(tmp_tab) do
		local val = tmp_tab[i]
		if self.lastMPMode == "Free For All" then
			self.mapsOnServerFFA[i] = val
			Cfg.ServerMapsFFA[i] = val
		elseif self.lastMPMode == "Team Deathmatch" then
			self.mapsOnServerTDM[i] = val
			Cfg.ServerMapsTDM[i] = val
		elseif self.lastMPMode == "Voosh" then
			self.mapsOnServerVSH[i] = val
			Cfg.ServerMapsVSH[i] = val
		elseif self.lastMPMode == "The Light Bearer" then
			self.mapsOnServerTLB[i] = val
			Cfg.ServerMapsTLB[i] = val
		elseif self.lastMPMode == "Capture The Flag" then
			self.mapsOnServerCTF[i] = val
			Cfg.ServerMapsCTF[i] = val
		elseif self.lastMPMode == "People Can Fly" then
			self.mapsOnServerPCF[i] = val
			Cfg.ServerMapsPCF[i] = val
		elseif self.lastMPMode == "Duel" then
			self.mapsOnServerDUE[i] = val
			Cfg.ServerMapsDUE[i] = val
		elseif self.lastMPMode == "Last Man Standing" then
			self.mapsOnServerLMS[i] = val
			Cfg.ServerMapsLMS[i] = val
		end
    end

	PMENU.UpdateMapTable(name,mode)

--	for i=1,table.getn(Cfg.ServerMaps) do
--		self.mapsOnServer[i] = Cfg.ServerMaps[i]
--	end

	tmp_tab = {}
	if mode == "Free For All" then
		tmp_tab = self.mapsOnServerFFA
	elseif mode == "Team Deathmatch" then
		tmp_tab = self.mapsOnServerTDM
	elseif mode == "Voosh" then
		tmp_tab = self.mapsOnServerVSH
	elseif mode == "The Light Bearer" then
		tmp_tab = self.mapsOnServerTLB
	elseif mode == "Capture The Flag" then
		tmp_tab = self.mapsOnServerCTF
	elseif mode == "People Can Fly" then
		tmp_tab = self.mapsOnServerPCF
	elseif mode == "Duel" then
		tmp_tab = self.mapsOnServerDUE
	elseif mode == "Last Man Standing" then
		tmp_tab = self.mapsOnServerLMS
	end

	self.mapsOnServer = {}
	Cfg.ServerMaps = {}

	PMENU.RemoveAllMapsFromServer( name )
	for i=1,table.getn(tmp_tab) do
		PMENU.AddMapToServer( name, tmp_tab[i] )
		self.mapsOnServer[i] = tmp_tab[i]
		Cfg.ServerMaps[i] = tmp_tab[i]
    end

	self.lastMPMode = mode
	Cfg.GameMode = mode

	Cfg:Save()
end

--=======================================================================================

function PainMenu:BackToLastScreen()
	if self.lastScreen == "server" then
		PainMenu:ActivateScreen(CreateServerMenu)
	else
		PainMenu:ActivateScreen(InternetGameMenu)
	end
end

function PainMenu_MultiplayerErrorCallback( mtype, desc )
    if IsDedicatedServer() then 
        if mtype ~= MultiplayerErrorTypes.Information then MsgBox(desc) end
        Game.LevelStarted = false
        return
    end
	if mtype == MultiplayerErrorTypes.Information then
		CONSOLE.Print( desc )
	elseif mtype == MultiplayerErrorTypes.Disconnected then
		Game:NewLevel('NoName','','',0.3); WORLD.Release()
		Game.LevelStarted = false
		PMENU.ShowMenu()
		PainMenu:ShowInfo( desc, "PainMenu:BackToLastScreen()" )
	elseif mtype == MultiplayerErrorTypes.BadCDKey then
		Game:NewLevel('NoName','','',0.3); WORLD.Release()
		Game.LevelStarted = false
		PMENU.ShowMenu()
		PainMenu:ShowInfo( desc, "PainMenu:ActivateScreen(PlayerOptions)" )
	elseif mtype == MultiplayerErrorTypes.BadPassword then
		Game.LevelStarted = false
		PMENU.ShowMenu()
		PainMenu:AskForPassword( desc, "PainMenu:ReJoinServer()", "PainMenu:BackToLastScreen()" )
	end
end


function PainMenu:PrintMapsOnServer()
	local tmp_tab = PMENU.GetMapsOnServer()
    for i=1,table.getn(tmp_tab) do
        Game:Print( tmp_tab[i] )
    end
end

--=======================================================================================

function PainMenu:AddPlayerModelItem( name, item )
	PMENU.AddPlayerModel( name )

	PainMenu:ChangePlayerModel( MPModels[Cfg.PlayerModel] )
end

function PainMenu:RenderPlayerModel( name )

	if not self.playerModel then return end
--	if not self.playerModel or not self.playerLight then return end
	local x, y, z = CAM.GetPos()
	local rx, ry, rz = CAM.GetRotation()
	self.cameraPos = { x, y, z }
	self.cameraRot = { rx, ry, rz }

	CAM.SetPos( 0, 5, 19 )
	CAM.LookAt( -9.5, 1, 0 )
	CAM.UpdateViewport()

	ENTITY.SetPosition( self.playerModel, 0, 0, 0 )
	ENTITY.SetOrientation( self.playerModel, 0.7 )
	ENTITY.SetPosition( self.playerLight, -2, 6, 2 )

	if not Game:IsServer() and Game.GMode == GModes.SingleGame then
		WORLD.AdvanceFrameCounter()
		ENTITY.Tick( self.playerModel, INP.GetTimeDelta() )
--		ENTITY.Tick( self.playerLight, INP.GetTimeDelta() )
	end

	R3D.SetCameraFOV(90)
	ENTITY.ResetLights( self.playerModel )
	ENTITY.AddLight( self.playerModel, self.playerLight )
	ENTITY.Draw( self.playerModel )

	CAM.SetTransform( self.cameraPos[1], self.cameraPos[2], self.cameraPos[3], self.cameraRot[1], self.cameraRot[2], self.cameraRot[3] )
	CAM.UpdateViewport()

end

function PainMenu:ReleasePlayerModel( name )
	Game:BrightSkin( self.playerModel, true, Cfg.Team )

	WORLD.AmbientColor( self.ambient[1], self.ambient[2], self.ambient[3], self.ambient[4] )
	if self.playerModel then
		WORLD.RemoveEntity( self.playerModel )
		ENTITY.Release( self.playerModel )
	end
	self.playerModel = nil

	if self.playerLight then
		WORLD.RemoveEntity( self.playerLight )
		ENTITY.Release( self.playerLight )
	end
	self.playerLight = nil

	WORLD.DeleteDelayedEntities()

end

function PainMenu:ReloadBrightskins()
	if Game.GMode == GModes.SingleGame then return end
	for i,o in Game.PlayerStats do
		Game:BrightSkin( o._Entity, true, o.Team )
	end
end

function PainMenu:ChangePlayerModel( model )

	if self.playerModel or self.playerLight then PainMenu:ReleasePlayerModel( "PlayerModel" ) end

	if not model then model = "player" end

	Game:Print( "Model change "..model )
	
	self.playerModel = ENTITY.Create( ETypes.Model, model, "player_menu", 0.6 )
	WORLD.AddEntity( self.playerModel, true )
	MDL.SetAnim( self.playerModel, "run", true )
	Game:BrightSkin( self.playerModel, false, Cfg.Team )

	if not self.playerModel then
		PainMenu:ReleasePlayerModel( "PlayerModel" )
		return
	end

	self.playerLight = ENTITY.Create( ETypes.Light, "Script", "player_menu_light" );
	
	if not self.playerLight then
		PainMenu:ReleasePlayerModel( "PlayerModel" )
		return
	end
	
	LIGHT.Setup( self.playerLight, 2, Color:New(255,255,255,0):Compose(), 0, 1, 0, 1 )
	LIGHT.SetFalloff( self.playerLight, 2, 10, 90 )
	LIGHT.SetDynamicFlag( self.playerLight, false )
--	LIGHT.SetLitParentFlag( self.playerLight, false )
--	LIGHT.SetProjector( self.playerLight, "" )
	WORLD.AddEntity( self.playerLight, true )
--	MDL.SetMeshLighting( self.playerModel, "*", true )

	local e = self.playerModel

    
    
	-- stakegun
    MDL.SetMeshVisibility(e,"stake",false)
    -- minigun
    MDL.SetMeshVisibility(e,"rl",false)
    -- shotgun
    MDL.SetMeshVisibility(e,"ASG_bodyShape",false)
    
    -- painkiller
    --MDL.SetMeshVisibility(e,"PKW_korpusShape",false)
	--MDL.SetMeshVisibility(e,"PKW_HeadShape",false)

	-- spawara
	MDL.SetMeshVisibility(e,"pCylinderShape1",false)
    MDL.SetMeshVisibility(e,"pCylinderShape2",false)
    MDL.SetMeshVisibility(e,"polySurfaceShape450",false)
    MDL.SetMeshVisibility(e,"polySurfaceShape455",false)
	-- boltstickheater
	MDL.SetMeshVisibility(e,"polySurfaceShape431",false)
	-- flameth
    MDL.SetMeshVisibility(e,"polySurfaceShape1391",false)
    
    

	local r, g, b, l = WORLD.GetAmbientColor()
	self.ambient = { r, g, b, l }

	WORLD.AmbientColor( 200, 200, 200, 0 )
	ENTITY.SetAmbient(e, true, 200,200,200)
--	WORLD.AmbientColor( 255, 255, 255, 0 )
--	ENTITY.SetAmbient(e, true, 255,255,255)

end

--=======================================================================================

function PainMenu:ReloadWeaponsTextures()
	if not Player then return end

	for i=1,7 do
        if Player.Weapons[i] then
			if Player.Weapons[i]["ReloadTextures"] then
				Player.Weapons[i]:ReloadTextures()
			end
        end
    end
end

function PainMenu:CheckWeaponSpecular()
	if not self.currScreen then return end
	if self.currScreen ~= VideoOptions then return end

	if PMENU.IsItemChecked( "WeaponNormalMap" ) then
		Cfg.WeaponSpecular = true
--		PMENU.EnableItem( "WeaponSpecular" )
	else
--		PMENU.DisableItem( "WeaponSpecular" )
		Cfg.WeaponSpecular = false
	end
end

--=======================================================================================

function PainMenu_PrintGameVersion()
	if PainMenu.currScreen == DemoEnd then return end
	local w,h = R3D.ScreenSize()
    HUD.SetFont("timesbd",16)
    local ver = "Version: "..PK_VERSION
    if IsMPDemo() then
		ver = "Version: "..PK_VERSION.." MP Demo"
    end
    local tw = HUD.GetTextWidth(ver)
    HUD.PrintXY(w-tw-54*w/1024,54*h/768,ver,"timesbd",0,0,0,16)
    HUD.PrintXY(w-tw-53*w/1024,53*h/768,ver,"timesbd",255,186,122,16)
end

function PainMenu:SignAPact(mode,addon)
	if not IsPKInstalled() then
		Game:Print( "PK not installed" )
		return PainMenu:SignAPactBooHOnly(mode,addon)
	end
	
	if not IsBooHInstalled() then
		Game:Print( "BooH not installed" )
		return PainMenu:SignAPactPKOnly(mode,addon)
	else
		Game:Print( "BooH installed" )
	end

	WORLD.SwitchToState(2)
--	WORLD.Release(true)

	if not Game then
		PainMenu:ActivateScreen(NewGameMenu)
	end

	local ask = false

	local add = "false"
	if addon then add = "true" end

	if not mode or mode == 1 then
		if Game.GameInProgress then
			PainMenu:AskYesNo( Languages.Texts[686], 'Game.GameInProgress = false; Game.LevelStarted = false; Game:ClearLevelsStats(false); PainMenu:SignAPact(2,'..add..')', 'PainMenu:ActivateScreen(GameMenu)' )
		else
			PainMenu:SignAPact(2,addon)
		end
	else
		for i=1,table.getn(Game.CardsAvailable) do
			if Game.CardsAvailable[i] == true then
				if i > 24 and (addon or Game.AddOn) then
					ask = true
				end
			end
		end

		if not ask and Levels[1][1] and Game.LevelsStats[Levels[1][1][1]] then
			if Game.LevelsStats[Levels[1][1][1]].Finished == true then
				ask = true
			end
		end

		if not ask and Game.PlayerMoney > 0 then ask = true end

		if ask then
			PainMenu:AskYesNo( Languages.Texts[636], "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; if Game then Game.AddOn = "..add.."; Game:ClearLevelsStats(true) end; PainMenu:ActivateScreen(NewGameMenu)", "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; PainMenu:ActivateScreen(NewGameMenu)" )
		else
			Game.GameInProgress = false
			Game.LevelStarted = false
			Game.AddOn = addon
			PainMenu:ActivateScreen(NewGameMenu)
		end
	end
end

function PainMenu:SignAPactBooHOnly(mode,addon)
	WORLD.SwitchToState(2)
--	WORLD.Release(true)

	if not Game then
		PainMenu:ActivateScreen(NewGameMenu)
	end

	local ask = false

	local add = "true"

	if not mode or mode == 1 then
		if Game.GameInProgress then
			PainMenu:AskYesNo( Languages.Texts[686], 'Game.GameInProgress = false; Game.LevelStarted = false; Game:ClearLevelsStats(false); PainMenu:SignAPactBooHOnly(2,'..add..')', 'PainMenu:ActivateScreen(MainMenu)' )
		else
			PainMenu:SignAPactBooHOnly(2,addon)
		end
	else
		for i=1,table.getn(Game.CardsAvailable) do
			if Game.CardsAvailable[i] == true then
				if i > 24 and (addon or Game.AddOn) then
					ask = true
				end
			end
		end

		if not ask and Levels[1][1] and Game.LevelsStats[Levels[1][1][1]] then
			if Game.LevelsStats[Levels[1][1][1]].Finished == true then
				ask = true
			end
		end

		if not ask and Game.PlayerMoney > 0 then ask = true end

		if ask then
			PainMenu:AskYesNo( Languages.Texts[636], "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; if Game then Game.AddOn = "..add.."; Game:ClearLevelsStats(true) end; PainMenu:ActivateScreen(NewGameMenu)", "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; PainMenu:ActivateScreen(NewGameMenu)" )
		else
			Game.GameInProgress = false
			Game.LevelStarted = false
			Game.AddOn = addon
			PainMenu:ActivateScreen(NewGameMenu)
		end
	end
end

function PainMenu:SignAPactPKOnly(mode,addon)
	WORLD.SwitchToState(2)
--	WORLD.Release(true)

	if not Game then
		PainMenu:ActivateScreen(NewGameMenu)
	end

	local ask = false

	local add = "false"

	if not mode or mode == 1 then
		if Game.GameInProgress then
			PainMenu:AskYesNo( Languages.Texts[686], 'Game.GameInProgress = false; Game.LevelStarted = false; Game:ClearLevelsStats(false); PainMenu:SignAPactPKOnly(2,'..add..')', 'PainMenu:ActivateScreen(MainMenu)' )
		else
			PainMenu:SignAPactPKOnly(2,addon)
		end
	else
		for i=1,table.getn(Game.CardsAvailable) do
			if Game.CardsAvailable[i] == true then
				if i > 24 and (addon or Game.AddOn) then
					ask = true
				end
			end
		end

		if not ask and Levels[1][1] and Game.LevelsStats[Levels[1][1][1]] then
			if Game.LevelsStats[Levels[1][1][1]].Finished == true then
				ask = true
			end
		end

		if not ask and Game.PlayerMoney > 0 then ask = true end

		if ask then
			PainMenu:AskYesNo( Languages.Texts[636], "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; if Game then Game.AddOn = "..add.."; Game:ClearLevelsStats(true) end; PainMenu:ActivateScreen(NewGameMenu)", "Game.AddOn = "..add.."; Game.GameInProgress = false; Game.LevelStarted = false; PainMenu:ActivateScreen(NewGameMenu)" )
		else
			Game.GameInProgress = false
			Game.LevelStarted = false
			Game.AddOn = addon
			PainMenu:ActivateScreen(NewGameMenu)
		end
	end
end

function PainMenu:AskReturnToMap()
	if not Game.LevelStarted then
		PMENU.SwitchToMap()
	else
		PainMenu:AskYesNo( Languages.Texts[687], 'Game.LevelStarted = false; PMENU.SwitchToMap()', 'PainMenu:ActivateScreen(MainMenu)' )
	end
end

function PainMenu:ResetCheats()
	GOD = false
	if not Game then return end
	Game.Cheat_AlwaysGib = false
	Game.Cheat_WeakEnemies = false
	Game.GoldenCardsUseUnlimited = false
	Game.Cheat_KeepBodies = false
	Game.Cheat_KeepDecals = false
	if Player then
		Player.HasWeaponModifier = false
		Player._WeaponModifierCounter = 0
	end
end

function PainMenu:SelectDifficulty(mode)
	Game:Print( "SoundTrack: "..self.movSndTrack )
	if not Game.AddOn then
		PMENU.PlayMovie("../Data/Movies/intro.bik",self.movSndTrack)
	else
		PMENU.PlayMovie("../Data/Movies/booh_intro.bik",self.movSndTrack)
	end
	Game:ClearLevelsStats(false)
	PainMenu:ResetCheats()
	Game.GameInProgress = true
	Game.LevelStarted = false
	Game.Difficulty = mode
	PMENU.MapReset()
	PMENU.SwitchToMap()
end

function PainMenu:CheckCDInDrive()
	local path = nil
	local f = 3 -- math.random(1,3)
	if f == 1 then
		path = GetDriveLetter()
	elseif f == 2 then
		path = LabelOk()
	else
		path = GetCDLetter()
	end

	if path then
		local file = FS.FindFiles(path.."painkiller.ico",1,0)
		if not file[1] then file = FS.FindFiles(path.."autorun.inf",1,0) end
		if not file[1] then file = FS.FindFiles(path.."painkiller.003",1,0) end
		if not file[1] then file = FS.FindFiles(path.."PainkillerSetup.003",1,0) end
		if file[1] then
			Game:Print( "CD found in: "..path )
			return true
		else
			return false
		end
	else
		return false
	end
end

function PainMenu:ShowNoCDWarning()
	if not PainMenu:CheckCDInDrive() then
		PainMenu:AskNoCDInDrive( TXT.Menu.InsertCD, "PainMenu:ShowNoCDWarning()", "Exit()" )
	else
		PainMenu:ActivateScreen(MainMenu)
	end
end
