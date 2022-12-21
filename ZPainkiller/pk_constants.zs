const font_times = "TimesS2";
const PK_BOARD_WIDTH = 1024;
const PK_BOARD_HEIGHT = 768;
const PK_MENUTEXTSCALE = 1;

enum PK_WeaponLayers {
	PSP_UNDERGUN 	= -1,
	PSP_OVERGUN 	= 2,
	PSP_SCOPE1		= 3,
	PSP_SCOPE2		= 4,
	PSP_SCOPE3		= 5,
	PSP_PFLASH 	= -100,
	PSP_HIGHLIGHTS = 100,
	
	PWR_HANDLER	= -10,
	PWR_PENTA		= -11,
	PWR_PANTIRAD	= -12,
	PWR_EYES		= -13,
	
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
	CH_END		= 12,
	//	Demon Morph looping sound will play on this channel:
	CH_HELL	= 66,
	CH_PKUI 	= 67
}