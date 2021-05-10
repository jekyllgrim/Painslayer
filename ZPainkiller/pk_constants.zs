const font_times = "TimesS2";

enum PK_WeaponLayers {
	PSP_UNDERGUN 	= -1,
	PSP_OVERGUN 	= 2,
	PSP_SCOPE1		= 3,
	PSP_SCOPE2		= 4,
	PSP_SCOPE3		= 5,
	PSP_PFLASH 	= -100,
	PSP_HIGHLIGHTS = 100,
	
	RIFLE_PILOT	= -6,
	RIFLE_STRAP 	= -3,
	RIFLE_BARREL 	= -2,
	RLIGHT_BARREL	= -1,
	RLIGHT_WEAPON	= 2,
	RIFLE_BOLT		= 3,
	RLIGHT_BOLT	= 4,
	RIFLE_STOCK	= 5,
	RLIGHT_STOCK	= 6,
	
	PSP_DEMON = 66
}	

enum PK_SoundChannels {
	CH_LOOP	= 12,
	CH_WMOD 	= 13,
	CH_PWR		= 14,
	/*	highest number in the list of channels 
		that should be affected by A_SoundPitch 
		call in Haste and simialr effects:
	*/
	CH_END		= 14,
	//	Demon Morph looping sound will play on this channel:
	CH_HELL	= 66
}