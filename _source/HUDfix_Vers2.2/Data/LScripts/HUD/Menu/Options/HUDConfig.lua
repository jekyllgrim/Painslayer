HUDConfig =
{
	bgStartFrame = { 120, 243, 268 },
	bgEndFrame   = { 180, 267, 291 },

	fontBigSize = 36,

	backAction = "PainMenu:ApplySettings(true); HUD.SetTransparency(Cfg.HUDTransparency); PainMenu:ActivateScreen(OptionsMenu); R3D.SetCameraFOV(Cfg.FOV); PainMenu.cameraFOV = Cfg.FOV",
	applyAction = "",

	items =
	{
		HUDBorder =
		{
			type = MenuItemTypes.Border,
			x = 120,
			y = 70,
			width = 784,
			height = 640,
		},
		
		HeadBob =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.HeadBob,
			desc = TXT.MenuDesc.HeadBob,
			option = "HeadBob",
			minValue = 0,
			maxValue = 100,
			x	 = 160,
			y	 = 100,
			action = "",
		},
		
		HUDTransparency =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.HUDTransparency,
			desc = TXT.MenuDesc.HUDTransparency,
			option = "HUDTransparency",
			minValue = 0,
			maxValue = 100,
			x	 = 160,
			y	 = 150,
			action = "",
		},

		FOV =
		{
			type = MenuItemTypes.Slider,
			text = "FOV",
			desc = "Adjust's your Field of Vision",
			option = "FOV",
			minValue = 50,
			maxValue = 170,
			x	 = 160,
			y	 = 200,
			action = "",
		},

		WeaponFOV =
		{
			type = MenuItemTypes.Slider,
			text = "Weapon Distance",
			desc = "Weapon Draw Distance to Camera",
			option = "WeaponFOV",
			minValue = -25,
			maxValue = 25,
			x	 = 160,
			y	 = 250,
			action = "",
		},

		HUDSize =
		{
			type = MenuItemTypes.TextButtonEx,
			text = TXT.Menu.HUDSize,
			desc = TXT.MenuDesc.HUDSize,
			option = "HUDSize",
			values = { 0.0, 0.25, 0.5, 0.6, 0.75, 1.0 },
			visible = { "Off", "Micro", "Tiny", TXT.Menu.Small, TXT.Menu.Normal, TXT.Menu.Large },
			x	 = -1,
			y	 = 300,
			action = "",
			align = MenuAlign.None,
		},

		Eyefinity =
		{
			type = MenuItemTypes.TextButtonEx,
			text = "Center HUD (Multipanel)",
			desc = "Center Ammo and Health on main screen.",
			option = "Eyefinity",
			values = { 1, 0, },
			visible = { "On", "Off" },
			x	 = -1,
			y	 = 350,
			action = "",
			align = MenuAlign.None,
		},

		EyefinityAdjust =
		{
			type = MenuItemTypes.Slider,
			text = "Hor HUD Center",
			desc = "Adjust towards or away from horizontal center",
			option = "EyefinityAdjust",
			minValue = -500,
			maxValue = 500,
			x	 = 160,
			y	 = 400,
			action = "",
		},

		CrossImage =
		{
			type = MenuItemTypes.SliderImage,
			text = TXT.Menu.Crosshair,
			desc = TXT.MenuDesc.Crosshair,
			option = "Crosshair",
			minValue = 1,
			maxValue = 32,
			x	 = 160,
			y	 = 450,
			action = "",
			images =
			{
				"HUD/crosshair", "HUD/crossy/cross1", "HUD/crossy/cross2", "HUD/crossy/cross3",
				"HUD/crossy/cross4", "HUD/crossy/cross5", "HUD/crossy/cross6", "HUD/crossy/cross7",
				"HUD/crossy/cross8", "HUD/crossy/cross9", "HUD/crossy/cross91", "HUD/crossy/cross92",
				"HUD/crossy/cross93", "HUD/crossy/cross94", "HUD/crossy/cross95", "HUD/crossy/cross96",
				"HUD/crossy/cross97", "HUD/crossy/cross98", "HUD/crossy/cross99", "HUD/crossy/cross991",
				"HUD/crossy/cross992", "HUD/crossy/cross993", "HUD/crossy/cross994", "HUD/crossy/cross995",
				"HUD/crossy/cross996", "HUD/crossy/cross997", "HUD/crossy/cross998", "HUD/crossy/cross999",
				"HUD/crossy/cross9991", "HUD/crossy/cross9992", "HUD/crossy/cross9993", "HUD/crossy/cross9994"
			}
		},
		
		CrosshairTrans =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.CrosshairTrans,
			desc = TXT.MenuDesc.CrosshairTrans,
			option = "CrosshairTrans",
			minValue = 0,
			maxValue = 100,
--			isFloat = true,
			x	 = 160,
			y	 = 500,
			action = "",
		},
		
		CrosshairR =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.CrosshairR,
			desc = TXT.MenuDesc.CrosshairR,
			option = "CrosshairR",
			minValue = 0,
			maxValue = 255,
			x	 = 160,
			y	 = 550,
			action = "",
		},
		
		CrosshairG =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.CrosshairG,
			desc = TXT.MenuDesc.CrosshairG,
			option = "CrosshairG",
			minValue = 0,
			maxValue = 255,
			x	 = 160,
			y	 = 600,
			action = "",
		},
		
		CrosshairB =
		{
			type = MenuItemTypes.Slider,
			text = TXT.Menu.CrosshairB,
			desc = TXT.MenuDesc.CrosshairB,
			option = "CrosshairB",
			minValue = 0,
			maxValue = 255,
			x	 = 160,
			y	 = 650,
			action = "",
		},
	}
}
