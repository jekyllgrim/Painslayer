// Similar to the vanilla ListMenuTextItem, but 
// centered like ListMenuItemStaticPatchCentered,
// and also draws P_mnublk behind itself:
class ListMenuItemPKTextItemCentered : ListMenuItemTextItem {
	TextureID menuBlockTex;
	vector2 menuBlockTexSize;

	override void Draw(bool selected, ListMenuDescriptor desc)	{	
		let font = menuDelegate.PickFont(mFont);
		let fy = font.GetHeight();
		
		// Draw the selector texture:
		if (!menuBlockTex)
			menuBlockTex = TexMan.CheckForTexture("graphics/hud/P_mnublk.png");
		if (menuBlockTexSize == (0,0))
			menuBlockTexSize = TexMan.GetScaledSize(menuBlockTex);
		
		DrawTexture(desc, menuBlockTex, mXpos - (menuBlockTexSize.x / 2), abs(mYpos) - (menuBlockTexSize.y / 2) + (fy / 2), mYpos < 0);
		
		// Draw the actual text:
		String text = Stringtable.Localize(mText);
		double x = mXpos - font.StringWidth(text) / 2;
		DrawText(desc, font, selected ? mColorSelected : mColor, x, abs(mYpos), text, mYpos < 0);
	}
	
	void PK_DrawMenuText(ListMenuDescriptor desc, Font fnt, int color, double x, double y, String text, bool ontop = false) {
		int w = desc ? desc.DisplayWidth() : ListMenuDescriptor.CleanScale;
		int h = desc ? desc.DisplayHeight() : -1;
		
		if (w == ListMenuDescriptor.CleanScale) {
			screen.DrawText(
				fnt, 
				color, 
				x, y, 
				text, 
				ontop ? DTA_CleanTop : DTA_Clean, true);
		}
		
		else {
			screen.DrawText(
				fnt, 
				color, 
				x, y, 
				text, 
				DTA_VirtualWidth, w, 
				DTA_VirtualHeight, h, 
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);
		}
	}
}

// An override for the Skill and Episode menus
// that draws P_mnublk behind the text

class PKSkillMenu : ListMenu {
	TextureID backgroundTex;
	vector2 backgroundTexSize;
	TextureID menuBlockTex;
	vector2 menuBlockTexSize;
	TextureID arrowTex;
	vector2 arrowTexSize;
	const MAXVISIBLE = 7;
	int skillCycleOfs;
	// The skill text has to fit within this width of the
	// background texture. Not using 100% because it has
	// some flowerly bits on the sides that the text
	// must not overlap:
	const TEXFITFACTOR = 0.65;
	const SWIDTH = 1920;
	const SHEIGHT = 1080;
	// Fixed title position:
	const TITLE_POSY = SHEIGHT / 9;
	// Screen center (everything is center-aligned):
	const POSX = SWIDTH / 2;
	// Top and bottom edges of the skill area:
	const SKILL_TOPY = SHEIGHT / 4;
	const SKILL_BOTY = SHEIGHT - (SHEIGHT / 8);
	const SKILL_AREA_HEIGHT = SKILL_BOTY - SKILL_TOPY;
	const SKILLSCROLLSPEED = 12;
	array<ListMenuItemTextItem> skillList;
	int visibleSkills;
	int firstVisible, lastVisible, lastSelectable;
	// This tracks the index of the first skill in the
	// descriptor's mItems array. Needed because while
	// skills go in order, they don't necessarily
	// start at index 0 (that one may be the title).
	int firstSkillIndex;
	
	override void Init(Menu parent, ListMenuDescriptor desc) {
		menuBlockTex = TexMan.CheckForTexture("graphics/hud/P_mnublk.png");
		menuBlockTexSize = TexMan.GetScaledSize(menuBlockTex);
		backgroundTex = TexMan.CheckForTexture("graphics/hud/P_menubkg.jpg");
		backgroundTexSize = TexMan.GetScaledSize(backgroundTex);
		arrowTex = TexMan.CheckForTexture("graphics/hud/P_mnuarr.png");
		arrowTexSize = TexMan.GetScaledSize(arrowtex);

		// Cache all selectable skill elements
		// into a separate array:
		firstSkillIndex = -1;
		for (int i = 0; i < desc.mItems.Size(); ++i) {
			let item = ListMenuItemTextItem(desc.mItems[i]);
			if (item) {
				skillList.Push(item);
				if (firstSkillIndex < 0) {
					firstSkillIndex = i;
				}
			}
		}
		visibleSkills = min(skillList.Size(), MAXVISIBLE) - 1;
		lastSelectable = skillList.Size() - 1;
		firstVisible = 0;
		lastVisible = min(firstVisible + visibleSkills, lastSelectable);

		super.Init(parent, desc);
	}

	override void Ticker() {
		Super.Ticker();
		if (skillCycleOfs > 0) {
			skillCycleOfs = max(0, skillCycleOfs - SKILLSCROLLSPEED);
		}
		else if (skillCycleOfs < 0) {
			skillCycleOfs = min(0, skillCycleOfs + SKILLSCROLLSPEED);
		}
	}

	// Update visible item list:
	override bool MenuEvent (int mkey, bool fromcontroller) {
		bool ret = Super.MenuEvent(mkey, fromcontroller);
		if (ret == true && (mkey == MKEY_Up || mkey == MKEY_Down)) {
			int selected = clamp(mDesc.mSelectedItem - firstSkillIndex, 0, lastSelectable);
			// went above the first visible item:
			if (selected < firstVisible) {
				// move first visible item up:
				firstVisible = max(0, selected);
				// update last visible accordingly:
				lastVisible = min(firstVisible + visibleSkills, lastSelectable);
				skillCycleOfs = -mDesc.mLineSpacing;
			}
			// went below the last visible item:
			else if (selected > lastVisible) {
				// move last visible down:
				lastVisible = min(lastSelectable, selected);
				// update first visible:
				firstVisible = max(lastVisible - visibleSkills, 0);
				skillCycleOfs = mDesc.mLineSpacing;
			}
		}
		return ret;
	}
	
	override void Drawer() {

		// draw skill menu background:
		Screen.Dim(0x000000, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		Screen.DrawTexture(backgroundTex, false,
			0, 0,
			DTA_VirtualWidthF, backgroundTexSize.x,
			DTA_VirtualHeightF, backgroundTexSize.y,
			DTA_FullScreenScale, FSMode_ScaleToFit43);
		
		// Draw the title (parse for StaticText elements):
		Font mFont = mDesc.mFont;
		for (int i = 0; i < mDesc.mItems.Size(); ++i) {
			// Static element? (title):
			let title = ListMenuItemStaticText(mDesc.mItems[i]);

			// draw the title:
			if (title) {
				string text = StringTable.Localize(title.mText);
				vector2 textpos = ( (SWIDTH / 2) - (mFont.StringWidth(text) / 2), TITLE_POSY);
				// draw shadow:
				Screen.DrawText(
					mFont, 
					Font.CR_Untranslated,
					textpos.x + 3, textpos.y + 3, 
					text, 
					DTA_VirtualWidth, SWIDTH,
					DTA_VirtualHeight, SHEIGHT,
					DTA_FullscreenScale, FSMode_ScaleToFit43
				);
				// draw the actual text:
				Screen.DrawText(
					mFont, 
					mFont.FindFontColor('PKWhiteText'),
					textpos.x, textpos.y, 
					text, 
					DTA_VirtualWidth, SWIDTH,
					DTA_VirtualHeight, SHEIGHT,
					DTA_FullscreenScale, FSMode_ScaleToFit43
				);
				break;
			}
		}

		// Draw skills:

		int y = SKILL_TOPY + skillCycleOfs - mDesc.mLineSpacing;
		int fy = int(mFont.GetHeight());
		int textureWidth = int(menuBlockTexSize.x);
		double fitTextureWidth = textureWidth * TEXFITFACTOR;

		let [box_coords, box_size] = Screen.VirtualToRealCoords(
			(0, SKILL_TOPY - (menuBlockTexSize.y / 2) + (fy / 2) + 8), 
			(SWIDTH, mDesc.mLineSpacing * (visibleSkills + 1)),
			(SWIDTH, SHEIGHT)
		);

		// Draw arrows above/below if there are skills there:
		if (lastSelectable > visibleSkills)
		{
			double arrowscale = 0.5;
			// sine pulse alpha:
			double arrowAlpha = 0.5 + 0.5 * (0.5 + 0.5 * sin(360.0 * Menu.MenuTime() / 20));
			if (firstVisible > 0) {
				Screen.DrawTexture(
					arrowTex, false,
					int(SWIDTH / 2 - arrowTexSize.x*0.5*arrowscale), SKILL_TOPY - (menuBlockTexSize.y / 2) + (fy / 2) - arrowTexSize.y*arrowscale,
					DTA_VirtualWidth, SWIDTH,
					DTA_VirtualHeight, SHEIGHT,
					DTA_FullscreenScale, FSMode_ScaleToFit43,
					DTA_FlipY, true,
					DTA_ScaleX, arrowscale,
					DTA_ScaleY, arrowscale,
					DTA_Alpha, arrowAlpha
				);
			}
			if (lastVisible < lastSelectable) {
				Screen.DrawTexture(
					arrowTex, false,
					int(SWIDTH / 2 - arrowTexSize.x*0.5*arrowscale), SKILL_BOTY - mDesc.mLineSpacing*0.5,
					DTA_VirtualWidth, SWIDTH,
					DTA_VirtualHeight, SHEIGHT,
					DTA_FullscreenScale, FSMode_ScaleToFit43,
					DTA_ScaleX, arrowscale,
					DTA_ScaleY, arrowscale,
					DTA_Alpha, arrowAlpha
				);
			}
		}

		Screen.SetClipRect(box_coords.x, box_coords.y, box_size.x, box_size.y);

		// we'll draw one above and one below visible edges
		// so the items don't pop out of nowhere when
		// animating the scroll:
		for (int i = firstVisible - 1; i <= lastVisible + 1; i++) {
			if (i < 0 || i > lastSelectable) {
				y += mDesc.mLinespacing;
				continue;
			}
			let item = skillList[i];

			// We'll need to squish the skill text horizontally if
			// it's too long to fit within the panel texture:
			string text = StringTable.Localize(item.mText);
			double textwidth = mFont.StringWidth(text);
			double targetTextWidth = min(textwidth, fitTextureWidth);
			double textXScaleMul = min(1.0, targetTextWidth / textwidth);
			
			vector2 texpos = (
				(SWIDTH / 2) - (textureWidth / 2), 
				y - (menuBlockTexSize.y / 2) + (fy / 2)
			);
			/*if (i == 0) {
				let [box_coords, box_size] = Screen.VirtualToRealCoords(
					texpos, 
					(SWIDTH, SKILL_AREA_HEIGHT),
					(SWIDTH, SHEIGHT)
				);

				Console.Printf("\cdTexture\c- virtual top %.2f | real top %.2f",
					texpos.y,
					box_coords.y
				);
			}*/

			// draw the background:
			Screen.DrawTexture(
				menuBlockTex, 
				true, 
				texpos.x, texpos.y,
				DTA_VirtualWidth, SWIDTH,
				DTA_VirtualHeight, SHEIGHT,
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);
			
			// Set vertical collision for mouse selection:
			let sItem = ListMenuItemSelectable(item);
			if (sItem) {
				sItem.SetY(y);
				sItem.mHeight = int(mDesc.mLinespacing);
			}
			
			// Draw the skill text:
			vector2 textpos = (
				(SWIDTH / 2) - (targetTextWidth / 2), 
				y
			);
			let textcolor = mDesc.mFontColor;
			if (mDesc.mSelectedItem >= 0 && item == mDesc.mItems[mDesc.mSelectedItem] && i >= 0 && i <= lastSelectable) {
				textcolor = item.mColorSelected;
			}
			Screen.DrawText(
				mFont,
				textcolor,
				textpos.x, textpos.y, 
				text,
				DTA_VirtualWidth, SWIDTH,
				DTA_VirtualHeight, SHEIGHT,
				DTA_FullscreenScale, FSMode_ScaleToFit43,
				// Scale the text horizontally to fit
				// within the graphic:
				DTA_ScaleX, textXScaleMul
			);

			y += mDesc.mLinespacing;
		}

		Screen.ClearClipRect();

		/*Screen.DrawText(
			NewConsoleFont, 
			Font.CR_White,
			0, 0,
			String.Format("Selected \cd%d\c- | First vis \cd%d\c- | Last vis \cd%d\c-",
				mDesc.mSelectedItem - firstSkillIndex,
				firstVisible,
				lastVisible
			),
			DTA_VirtualWidth, SWIDTH,
			DTA_VirtualHeight, SHEIGHT,
			DTA_FullscreenScale, FSMode_ScaleToFit43,
			DTA_ScaleX, 2.0,
			DTA_ScaleY, 2.0
		);*/
	}
}

// A dedicated element that will draw fullscreen 
// background for the main menu but only if we're 
// not in a map (only intro screen and titlemap qualify)
class ListMenuItemPKDrawMenuBackground : ListMenuItemStaticPatch {
	override void Draw(bool selected, ListMenuDescriptor desc) {
		if (gamestate == GS_LEVEL)
			return;
		if (!mTexture.Exists())
			return;
		Screen.Dim(0x000000, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		Vector2 tSize = TexMan.GetScaledSize(mTexture);
		Screen.DrawTexture(mTexture, false,
			0, 0,
			DTA_VirtualWidthF, tSize.x,
			DTA_VirtualHeightF, tSize.y,
			DTA_FullScreenScale, FSMode_ScaleToFit43);
	}
}


class OptionMenuItemPKCrosshairOption : OptionMenuItemOption 
{
	CVar xhair;
	
	OptionMenuItemPKCrosshairOption Init(String label, Name command)
	{
		Super.Init(label, command, "Crosshairs", null, 0);
		xhair = Cvar.FindCvar('Crosshair');
		return self;
	}
	
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		if (mCenter)
		{
			indent = (screen.GetWidth() / 2);
		}
		// Draw the option item label:
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, isGrayed());
		
		// Get the texture of the crosshair
		// from the value of 'crosshair' cvar:
		if (!xhair)
			return indent;
		string texname = String.Format("XHAIRB%d", xhair.GetInt());
		TextureID tex = TexMan.CheckForTexture(texname);
		if (!tex)
			return indent;
			
		// Get the size of the menu item:
		int labelH = int(Menu.Optionheight() * CleanYfac_1);
		int ofsy = Menu.Optionheight() * CleanYfac_1 / 2;
		Vector2 size = TexMan.GetScaledSize(tex);
		double scale = min(labelH / size.x, labelH / size.y);
		
		Screen.DrawTexture(
			tex, true, 
			indent + labelH * 2, y + ofsy/2,
			DTA_ScaleX, scale,
			DTA_ScaleY, scale
		);
		return indent;
	}
}

class PK_ModSettingsMenu : OptionMenu {
	const TOOLTIP_RES_X = 800;
	const TOOLTIP_RES_Y = 600;

	// Tooltips are provided as "LABEL_LANGUAGE_KEY|TOOLTIP_LANGUAGE_KEY"
	// in MENUDEF. In Init(), the item labels are split, with their
	// labels being set to "$LABEL_LANGUAGE_KEY", and tooltip keys
	// are stored in this assoc map to be retrieved in Drawer():
	Map<String, String> pk_modTooltips;
	static const String pk_tooltipKeys[] = {
		"$PKM_UseCards|$PKM_UseCards_Desc",
		"$PKM_OpenTarot|$PKM_OpenTarot_Desc",
		"$PKM_OpenCodex|$PKM_OpenCodex_Desc",
		"$PKM_LastWeapon|$PKM_LastWeapon_Desc",
		"$PKM_PKMovement|$PKM_PKMovement_Desc",
		"$PKM_PKMAutoJump|$PKM_PKMAutoJump_Desc",
		"$PKM_AutoOpenTarot|$PKM_AutoOpenTarot_Desc",
		"$PKM_QOLCATCHER|$PKM_QOLCATCHER_Desc",
		"$PKM_ALLOWDEMON|$PKM_ALLOWDEMON_DESC",
		"$PKM_GIFTCARRDS|$PKM_GIFTCARRDS_DESC",
		"$PKM_KeepBodies|$PKM_KeepBodies_Desc",
		"$PKM_ShowCodexNotifs|$PKM_ShowCodexNotifs_Desc",
		"$PKM_ShowCardsInHUD|$PKM_ShowCardsInHUD_Desc",
		"$PKM_ParticlesAmount|$PKM_ParticlesAmount_Desc",
		"$DSPLYMNU_MAXPARTICLES|$PKM_DebrisNumber_Desc",
		"$PKM_MapStartSound|$PKM_MapStartSound_Desc",
		"$CNTRLMNU_SLOT1|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT2|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT3|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT4|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT5|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT6|$PKM_FIREMODES_DESC",
		"$CNTRLMNU_SLOT7|$PKM_FIREMODES_DESC"
	};

	// Build tooltips on initialization:
	override void Init(Menu parent, OptionMenuDescriptor desc) {
		Super.Init(parent, desc);

		array<String> label;
		String current;
		for (int i = pk_tooltipKeys.Size() - 1; i >= 0; i--) {
			label.Clear();
			pk_tooltipKeys[i].Split(label, "|");
			pk_modTooltips.Insert(label[0], label[1]);
		}
	}

	override void Drawer() {
		Super.Drawer();
		if (mDesc.mSelectedItem < 0) return;
		OptionMenuItem item = mDesc.mItems[mDesc.mSelectedItem];
		String tooltip = pk_modTooltips.Get(item.mLabel);
		if (!tooltip) return;
		tooltip = StringTable.Localize(tooltip);
		String curlabel = StringTable.Localize(item.mLabel);
		
		int screenCenter = TOOLTIP_RES_X / 2;
		int width = int(ceil(TOOLTIP_RES_X * 0.8));
		int height = int(ceil(TOOLTIP_RES_Y * 0.2));
		int posx = screenCenter - (width / 2);

		int posy;
		// set posy to the top or bottom based on where the cursor is:
		int firstVisible = mDesc.mScrollTop + mDesc.mScrollPos;
		int visHeight = visBottom - firstVisible;
		if (mDesc.mSelectedItem < firstVisible + visHeight*0.6) {
			posy = TOOLTIP_RES_Y - height - 8;
		}
		else {
			posy = 8;
		}

		TextureID tex = TexMan.CheckForTexture("graphics/hud/tarot/tooltip_bg.png");
		Screen.DrawTexture(tex, false,
			posx, posy,
			DTA_VirtualWidth, TOOLTIP_RES_X,
			DTA_VirtualHeight, TOOLTIP_RES_Y,
			DTA_DestWidth, width,
			DTA_DestHeight, height,
			DTA_ColorOverlay, 0xbbffffbb
		);
		Screen.DrawTexture(tex, false,
			posx+4, posy+4,
			DTA_VirtualWidth, TOOLTIP_RES_X,
			DTA_VirtualHeight, TOOLTIP_RES_Y,
			DTA_DestWidth, width - 8,
			DTA_DestHeight, height - 8,
			DTA_Alpha, 0.9,
			DTA_ColorOverlay, 0xbb000000
		);

		int indentX = 20;
		int indentY = 12;
		int lineheight = newconsolefont.GetHeight();
		if (curlabel) {
			int linewidth = newconsolefont.StringWidth(curlabel);
			Screen.DrawText(newconsolefont, Font.CR_Gold,
				screenCenter - (linewidth / 2),
				(posy + indentY), 
				curlabel,
				DTA_VirtualWidth, TOOLTIP_RES_X,
				DTA_VirtualHeight, TOOLTIP_RES_Y,
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);
			posy += lineheight*2;
		}

		BrokenLines lines = newconsolefont.BreakLines(tooltip, width - indentX*2);
		String curline;
		for (int i = 0; i < lines.Count(); i++) {
			curline = lines.StringAt(i);
			curline.Replace("\n", " ");
			Screen.DrawText(newconsolefont, Font.CR_White,
				(posx + indentX),
				(posy + indentY), 
				curline,
				DTA_VirtualWidth, TOOLTIP_RES_X,
				DTA_VirtualHeight, TOOLTIP_RES_Y,
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);
			posy += lineheight;
		}
	}
}

class ListMenuItemPKBuildInfo : ListMenuItem {
	transient String buildinfo;
	
	void Init (ListMenuDescriptor desc) {
		Super.Init(0, 0);
		let lump = Wads.FindLump("painbuild.txt");
		if (lump >= 0) {
			buildinfo = String.Format("Painslayer build %s", Wads.ReadLump(lump));
		}
	}

	override void Draw(bool selected, ListMenuDescriptor desc) {
		if (buildinfo) {
			Screen.DrawText(newConsoleFont, Font.CR_White,
				Screen.GetWidth() - newConsoleFont.StringWidth(buildinfo), Screen.GetHeight() - newConsoleFont.GetHeight() - 2,
				buildinfo,
				DTA_Alpha, 0.6
			);
		}
	}
}