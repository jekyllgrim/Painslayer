**PAINSLAYER © 2020-2021 Agent_Ash aka Jekyll Grim Payne**

*Painslayer* is a gameplay mod for GZDoom engine by Agent_Ash aka Jekyll Grim Payne, inspired by *Painkiller* (2004) by People Can Fly. 

*Painslayer* requires [GZDoom 4.7.0](https://zdoom.org/downloads).

☕ Support me on Boosty: https://boosty.to/agent_ash

# Contents

- [How to play](#how-to-play)
  * [How to play the latest stable release](#how-to-play-the-latest-stable-release)
  * [How to play the freshest dev build](#how-to-play-the-freshest-dev-build)
  * [How to play Painslayer with Beautiful Doom](#how-to-play-painslayer-with-beautiful-doom)
- [Copyright information and permissions](#copyright-information-and-permissions)
  + [Short summary of the permissions (not equivalent to the full text):](#short-summary-of-the-permissions--not-equivalent-to-the-full-text--)
    * [The Artwork](#the-artwork)
    * [The Code](#the-code)
    * [The Audio](#the-audio)
- [Credits](#credits)

# How to play

## How to play the latest stable release

Releases aren't always super-stable or bug-free, but they should be playable. Some releases are development versions which don't have all the planned features implemented yet.

1. Navigate to the "Releases" tab at the top or following this URL: https://github.com/jekyllgrim/Painslayer/releases
2. Download the attached PK3 file. Run it as you'd run any .wad or .pk3. For example, in the command line it shoud look as follows:

```
gzdoom.exe -file Painslayer###.pk3
```

(`###` in the example above stand for the version number, e.g. 085.)

## How to play the freshest dev build

It's possible to play the version that is currently in the repository but hasn't been made into a separate release yet:

1. Click [here](https://github.com/jekyllgrim/Painslayer/archive/refs/heads/master.zip) (or click the green "**Code**" button at the top right of this page and choose "**Download ZIP**"). This will download a file called `Painslayer-master.zip`.

2. Do not unpack the downloaded archive!

3. (Optional) Rename the downloaded **.zip** to **.pk3** to remember that you don't need to unpack it.

4. Run the archive as you would run any mod; from command line or a bat file in the GZDoom directory:
   
   ```
   gzdoom.exe -file Painslayer-master.zip 
   ```
   
    Or, if you renamed it: 
   
   ```
   gzdoom.exe -file Painslayer-master.pk3
   ```

5. If you're getting errors, try running it with the latest [development build of GZDoom](https://devbuilds.drdteam.org/gzdoom/). Github builds may contain features that haven't made it into a stable GZDoom release yet.

6. Enjoy!

## How to play Painslayer with Beautiful Doom

1. Download a fresh release of Beautiful Doom: https://github.com/jekyllgrim/Beautiful-Doom/releases

2. Run the game so that Painslayer is placed *after* Beautiful Doom in the load order. For example:
   
   ```
   gzdoom.exe -file Beautiful_Doom_715.pk3 Painslayer102.pk3
   ```

3. In the Main Menu, before starting the game, navigate to **Options** > **Beautiful Doom Settings** > scroll down, find **Beautiful Doom Weapons** > set to **Disabled**.

4. Play the game, and you'll have Beautiful Doom visuals with Painslayer weapons and mechanics!

# Copyright information and permissions

Painslayer gameplay modification for GZDoom engine ("Painslayer") by Agent_Ash also known as Jekyll Grim Payne ("the Author") is based on the Painkiller game series by People Can Fly and consists of several components that are subject to different licenses and permissions.

### Short summary of the permissions (not equivalent to the full text):

* Most of the graphics in Painslayer (specifically, weapon and pickup sprites) are owned by the Author and may NOT be used, copied or edited by anyone for any purpose without first obtaining an explicit permission from the Author.
* The code used in Painslayer was produced by several authors and can be freely used by anyone for any purpose, provided the authors are credited, the required licenses are applied to the derivative works, and the relevant license and copyright information is kept intact (i.e. all files containing license information shall be copied to derivate works).
* The sounds used in Painslayer are owned by People Can Fly and are used under Fair Use doctrine. They may be removed from Painslayer, should People Can Fly request it.

## The Artwork

The visual assets used in Painslayer, such as sprites, UI icons and other images, as well as 3D models and their textures ("the Artwork") are split into several categories. The Artwork categories, as well as the corresponding permissions and artwork locations are listed below:

i.   Original artwork created by the Author (usually inspired by works of People Can Fly)  
     **Permissions**: these assets may NOT be used, copied or edited by anyone for any purpose without first obtaining an explicit permission from the Author (with the exception of modifications made for personal use that will not be released publicly).  
     **Locations**: 

```
graphics/Boltgun/
graphics/Chaingun/
graphics/ElectroDriver/
graphics/hud/HUDelements/
graphics/Items/
graphics/Painkiller/
graphics/Rifle/
graphics/ShotgunFreezer/
graphics/StakeGun/
sprites/debris/
sprites/DemonEyes/
sprites/electro/
sprites/gold/
sprites/Painkiller/
sprites/pickups/
sprites/WeaponIcons/
```

ii.  Graphics, originally created by People Can Fly, modified in various ways, including but not limited to rescaling, color correction and partial redrawing  
     **Permissions**: these assets is used under the Fair Use doctrine. The Author does not own this artwork or any licenses to it. This artwork may be removed from Painslayer, should People Can Fly request it. You may use this artwork, as long as your use still falls under the Fair Use doctrine.  
     **Locations**:

```
graphics/HUD/ammo/
graphics/HUD/icons/
graphics/HUD/numbers/
graphics/HUD/Tarot/
graphics/HUD/DCRHA.png
graphics/crosshairs/
models/boltgun/
models/chaingun/
models/electrodriver/
models/painkiller/
models/rifle/
models/Shotgun/
models/Stakegun/
sprites/souls/
sprites/Flamethrower/
```

iii. Open-source assets  
     **Permissions**: can be used by anyone for any purpose.  
     **Locations**:

```
graphics/FLARA.png
graphics/FLARB.png
graphics/PKIMARK1.png
graphics/PKIMARK2.png
graphics/PKIMARK3.png
graphics/PKIMARK4.png
graphics/XHAIRB99.IMGZ
graphics/XHAIRS99.IMGZ
models/penta/
models/CrossSectionPrimitive.obj
models/flatbeam.obj
models/pickup_ring.obj
models/pickup_ring.png
models/pickup_ringwall.png
models/shaftB.png
models/spark.png
models/tracer.md3
models/tracer.png
sprites/SFX/
```

## The Code

The codebase of Painslayer includes original code produced by the Author, as well as several libraries, each under their own license.

**Summary of the permissions (not equivalent to the full license text):** 

* Painslayer codebase can be used freely by anyone for any purpose, provided the attached licene information is kept intact and the original authors are credited in all derivative works. 

* Some of the code in Painslayer is licensed under GPLv3. All code that is borrowed or based on that code also has to be licensed under GPLv3.

The code libraries, their license types and their locations are as follows:

1. Original code by the Author (with the occasional help of the members of the ZDoom community)  
    **License**: GPLv3  
    **Location**: `ZPainkiller/` (not including any subfolders)
2. *ZForms* library by Jessica Russell and Chronos "phantombeta" Ouroboros  
    **License**: free license  
    **Location**: `ZPainkiller/Zforms/`
3. *ToolTips* library by Nero  
    **License**: GPLv3  
    **Location**: `ZPainkiller/Tooltips/`
4. *StatusBarScreen* library by Lewisk3  
    **License**: MIT License  
    **Location**: `ZPainkiller/StatusBarScreen/`
5. *MK_Matrix* library by Marisa Kirisame  
    **License**: GNU GPL  
    **Location**: `ZPainkiller/mk_matrix/`
6. *Gutamatics* library by Gutawer
    **License**: MIT License
    **Location**: `ZPainkiller/PK_Gutamatics/`



Refer to the aforementioned code locations for license information on each code component.

## The Audio

All sounds used in Painslayer are owned by People Can Fly and are used under Fair Use doctrine. The Author does not own any of the sounds or any licenses to them. They may be removed from Painslayer, should People Can Fly request it.

# Credits

**People Can Fly**: Painkiller, Painkiller sounds, HUD graphics

**Agent_Ash aka Jekyll Grim Payne**: Idea, code, weapon and item sprites

**kodi**: Beam library

**Cherno**: Demon Morph shaders

**Lewisk3**: [StatusBarScreen](https://github.com/Lewisk3/StatusBarScreen), scripting help

Boondolr: Boss healthbar code, scripting help

phantombeta, Gutawer: [ZForms](https://gitlab.com/Gutawer/gzdoom-zforms)

Gutawer: [Gutamatics](https://gitlab.com/Gutawer/gzdoom-gutamatics/)

Nero: [Tooltips](https://github.com/Saican/Tooltips/tree/master)

Marisa Kirisame: MK_Matrix
