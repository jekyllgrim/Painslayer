// Similar to the vanilla ListMenuTextItem, but 
// centered like ListMenuItemStaticPatchCentered,
// and also draws P_mnublk behind itself:
class ListMenuItemPKTextItemCentered : ListMenuItemTextItem {
	TextureID mTexture;
	vector2 mTextureOfs;

	override void Draw(bool selected, ListMenuDescriptor desc)	{	
		let font = menuDelegate.PickFont(mFont);
		let fy = font.GetHeight();
		
		// Draw the selector texture:
		if (!mTexture)
			mTexture = TexMan.CheckForTexture("P_mnublk", TexMan.Type_Any);
		if (mTextureOfs == (0,0))
			mTextureOfs = TexMan.GetScaledSize(mTexture);
		
		DrawTexture(desc, mTexture, mXpos - (mTextureOfs.x / 2), abs(mYpos) - (mTextureOfs.y / 2) + (fy / 2), mYpos < 0);
		
		// Draw the actual text:
		String text = Stringtable.Localize(mText);
		double x = mXpos - font.StringWidth(text) / 2;
		DrawText(desc, font, selected ? mColorSelected : mColor, x, abs(mYpos), text, mYpos < 0);
	}
	
	void PK_DrawMenuText(ListMenuDescriptor desc, Font fnt, int color, double x, double y, String text, bool ontop = false) {
		int w = desc ? desc.DisplayWidth() : ListMenuDescriptor.CleanScale;
		int h = desc ? desc.DisplayHeight() : -1;
		
		if (w == ListMenuDescriptor.CleanScale) {
			screen.DrawText(fnt, color, x, y, text, ontop? DTA_CleanTop : DTA_Clean, true);
		}
		
		else {
			screen.DrawText(fnt, color, x, y, text, DTA_VirtualWidth, w, DTA_VirtualHeight, h, DTA_FullscreenScale, FSMode_ScaleToFit43);
		}
	}
}

// A hack to implement a custom skill menu. As long as this class
// is set as the SkillMenu class, we can work around the stupid
// size limitations (that will thankfully be gone in 4.10) and
// avoid the fallback to the text-only version, by setting the 
// positions and sizes explicitly
// (thanks, Boondorl!)
class PKSkillMenu : ListMenu {
	TextureID mTexture;
	TextureID mBackground;
	vector2 mTextureOfs;
	// explicit linespacing and size:
	const LINESPACING = 92;
	const POSX = 960;
	const POSY = 360;
	const SWIDTH = 1920;
	const SHEIGHT = 1080;
	
	override void Init(Menu parent, ListMenuDescriptor desc) {
		// Remove the jank workaround
		if (desc) {
			desc.mYpos = 0;
			desc.mLinespacing = LINESPACING;
		}
		super.Init(parent, desc);
	}
	
	override void Drawer() {
		// draw skill menu background:
		PK_StatusBarScreen.Fill("000000",0,0, SWIDTH, SHEIGHT,1);
		if (!mBackground)
			mBackground = TexMan.CheckForTexture("P_MENU", TexMan.Type_Any);
		PK_StatusBarScreen.DrawTexture(mBackground, (960,540));
		
		int y = POSY;
		let font = mDesc.mFont;
		let fy = font.GetHeight();
		if (!mTexture)
			mTexture = TexMan.CheckForTexture("P_mnublk", TexMan.Type_Any);	
		mTextureOfs = TexMan.GetScaledSize(mTexture);
		
		for (int i = 0; i < mDesc.mItems.Size(); ++i) {
			// check this is actually a skill element:
			let item = ListMenuItemTextItem(mDesc.mItems[i]);
			if (!item)
				continue;
			
			vector2 texpos = ((SWIDTH / 2) - (mTextureOfs.x / 2), y - (mTextureOfs.y / 2) + (fy / 2));
			// draw the background:
			Screen.DrawTexture(
				mTexture, 
				true, 
				texpos.x, texpos.y,
				DTA_VirtualWidth, SWIDTH,
				DTA_VirtualHeight, SHEIGHT
			);
			
			// Set vertical collision for mouse selection:
			let sItem = ListMenuItemSelectable(item);
			if (sItem)
			{
				sItem.SetY(y);
				sItem.mHeight = mDesc.mLinespacing;
			}
			
			// Draw the skill text:
			string text = StringTable.Localize(item.mText);
			vector2 textpos = ( (SWIDTH / 2) - (font.StringWidth(text) / 2), y);
			Screen.DrawText(
				font, 
				mDesc.mSelectedItem == i ? item.mColorSelected : mDesc.mFontColor,
				textpos.x, textpos.y, 
				text, 
				DTA_VirtualWidth, SWIDTH,
				DTA_VirtualHeight, SHEIGHT
			);

			y += mDesc.mLinespacing;
		}
	}
	
	override void onDestroy() {
		if (mDesc) {
			mDesc.mYpos = 0;
			mDesc.mLinespacing = 0;
		}
		super.onDestroy();
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
		PK_StatusBarScreen.Fill("000000",0,0,statscr_base_width,statscr_base_height,1);
		PK_StatusBarScreen.DrawTexture(mTexture, (960,540));
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