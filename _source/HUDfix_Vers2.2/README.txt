		Painkiller: Black Edition - Widescreen HUD Fix - Vers. 2.2


---------------------------------------Installation--------------------------------------


1. Install the folder called \Data\ into your main \Painkiller Black Edition\ directory

	For my Steam version, it's \Steam\steamapps\common\Painkiller Black Edition\, but this should work on any 1.64 Black Edition version of Painkiller.


2. Open the folder that corresponds to your resolution, \16_9\ for example, and move this \Data\ folder into the same \steamapps\common\Painkiller Black Edition\ directory.

	These are resized textures (Boss Health, Startup Screen, Bolt Gun Scope) that have been properly scaled for each resolution.


3. Go to Options > HUD for easily accessible options. Certain things (like zoomed FOV) still require using the console or .ini edits.



IMPORTANT: Using texture files that have not been resized specifically for your aspect ratio will cause the red ring of health around your compass during boss battles (boss_health.tga) to be misaligned. It must be controlled with the engine.dll, because I can't find any scripts that modify it. The Startup Screen and Scope can be stretched without breaking gameplay (pick the ones resized closest to your aspect ratio for less noticeable distortion) but I would strongly suggest manually resizing the boss_health.tga for the best experience.



The newest version of this mod can always be found at steamcommunity.com/sharedfiles/filedetails/?id=193714598


---------------------------------------Usage----------------------------------------------


	New Console Commands

WeaponFOV = -10          Weapon distance to camera, + or -
Eyefinity = 0            Centers important HUD elements. 1=On, 0=Off
EyefinityAdjust = 0      Fine-tunes HUD placement. Negative numbers push HUD out, positive pulls HUD in. Requires Eyefinity = 1
StakeFadeTime = 3600   	 Time in seconds for stakes and shurikens to fade. Default time is one hour.
CrosshairSize = 0.75     Crosshair Size. 1=Full Size, 2=Double Size, 0.5=Half size
PlayStartMovies = false  Disables the three splash videos on startup
PlayStartSound = true    Enables the painkiller-mainlogo.wav on startup


	Existing commands that are handy.

FOV = 110      (Changes the Field of Vision)
HudSize = 0.5  (Changes the size of the HUD while constraining proportions)


	New commands that require a restart to take effect. Useful to avoid .ini edits.

ZoomFov = 60      Zoomed Weapon FOV





	Author: steamcommunity.com/id/Lemmers
		ericlemke@gmail.com