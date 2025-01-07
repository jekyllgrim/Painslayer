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
			menuBlockTex = TexMan.CheckForTexture("P_mnublk", TexMan.Type_Any);
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
	// The skill text has to fit within this width of the
	// background texture. Not using 100% because it has
	// some flowerly bits on the sides that the text
	// must not overlap:
	const TEXFITFACTOR = 0.65;
	// explicit linespacing and size:
	const LINESPACING = 92;
	const POSX = 960;
	const POSY = 360;
	const SWIDTH = 1920;
	const SHEIGHT = 1080;
	
	/*override void Init(Menu parent, ListMenuDescriptor desc) {
		// Remove the jank workaround
		if (desc) {
			desc.mYpos = 0;
			desc.mLinespacing = LINESPACING;
		}
		super.Init(parent, desc);
	}*/
	
	override void Drawer() {
		// draw skill menu background:
		Screen.Dim(0x000000, 1.0, 0, 0, Screen.GetWidth(), Screen.GetHeight());
		if (!backgroundTex.IsValid()) {
			backgroundTex = TexMan.CheckForTexture("P_MENU", TexMan.Type_Any);
			backgroundTexSize = TexMan.GetScaledSize(backgroundTex);
		}
		Screen.DrawTexture(backgroundTex, false,
			0, 0,
			DTA_VirtualWidthF, backgroundTexSize.x,
			DTA_VirtualHeightF, backgroundTexSize.y,
			DTA_FullScreenScale, FSMode_ScaleToFit43);
		
		int y = POSY;
		let mFont = mDesc.mFont;
		let fy = mFont.GetHeight();
		if (!menuBlockTex.IsValid()) {
			menuBlockTex = TexMan.CheckForTexture("P_mnublk", TexMan.Type_Any);
			menuBlockTexSize = TexMan.GetScaledSize(menuBlockTex);
		}
		
		// Draw the title at the top:
		for (int i = 0; i < mDesc.mItems.Size(); ++i) {
			let title = ListMenuItemStaticText(mDesc.mItems[i]);
			if (title) {
				string text = StringTable.Localize(title.mText);
				vector2 textpos = ( (SWIDTH / 2) - (mFont.StringWidth(text) / 2), y / 2);
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
			}
		}
		
		int textureWidth = int(menuBlockTexSize.x);
		double fitTextureWidth = textureWidth * TEXFITFACTOR;
		for (int i = 0; i < mDesc.mItems.Size(); ++i) {
			// check it's a clikcable element (skill or episode):
			let item = ListMenuItemTextItem(mDesc.mItems[i]);
			if (!item)
				continue;
			
			// We'll need to squish the skill text horizontally if
			// it's too long to fit within the panel texture:
			string text = StringTable.Localize(item.mText);
			double textwidth = mFont.StringWidth(text);
			double targetTextWidth = min(textwidth, fitTextureWidth);
			double textXScaleMul = Clamp(targetTextWidth / textwidth, 0., 1.);
			
			vector2 texpos = (
				(SWIDTH / 2) - (textureWidth / 2), 
				y - (menuBlockTexSize.y / 2) + (fy / 2)
			);
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
				sItem.mHeight = mDesc.mLinespacing;
			}
			
			// Draw the skill text:
			vector2 textpos = (
				(SWIDTH / 2) - (targetTextWidth / 2), 
				y
			);
			Screen.DrawText(
				mFont, 
				mDesc.mSelectedItem == i ? item.mColorSelected : mDesc.mFontColor,
				textpos.x, textpos.y, 
				text,
				// Scale the text horizontally to fit
				// within the graphic:
				DTA_ScaleX, textXScaleMul,
				DTA_VirtualWidth, SWIDTH,
				DTA_VirtualHeight, SHEIGHT,
				DTA_FullscreenScale, FSMode_ScaleToFit43
			);

			y += mDesc.mLinespacing;
		}
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
		TextureID tex = TexMan.CheckForTexture(texname, TexMan.Type_Any);
		if (!tex)
			return indent;
			
		// Get the size of the menu item:
		String label = Stringtable.Localize(mLabel);
		int labelW = Menu.OptionWidth(label) * 1.2;
		int labelH = Menu.Optionheight();		
		// Define graphic's offsets based
		// on the size of the label:
		int x = (screen.GetWidth() + labelW) / 2;
		y += labelH; // this centers the graphic next to the label
		
		// Get the graphic size and scale it down
		// by the font's height:
		vector2 texsize = TexMan.GetScaledSize(tex);
		double texScale = texsize.y / labelH / 2;
		
		int w = screen.GetWidth();
		int h = screen.GetHeight();
		Screen.DrawTexture(
			tex, true, 
			x, y, 
			DTA_VirtualWidth, w, 
			DTA_VirtualHeight, h, 
			DTA_FullscreenScale, FSMode_ScaleToFit43,
			DTA_LegacyRenderStyle, Style_Add/*,
			DTA_ScaleX, texScale,
			DTA_ScaleY, texScale*/
		);
		return indent;
	}
}