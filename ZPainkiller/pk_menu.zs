//same as vanilla ListMenuTextItem, but centered like ListMenuItemStaticPatchCentered
class ListMenuItemPKTextItemCentered : ListMenuItemTextItem {
	
	override void Draw(bool selected, ListMenuDescriptor desc)	{
		let font = menuDelegate.PickFont(mFont);
		String text = Stringtable.Localize(mText);
		double x = mXpos - font.StringWidth(text) / 2;
		DrawText(desc, font, selected ? mColorSelected : mColor, x, abs(mYpos), text, mYpos < 0);
	}
	
	void PK_DrawMenuText(ListMenuDescriptor desc, Font fnt, int color, double x, double y, String text, bool ontop = false)	{
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

//a dedicated element that will draw fullscreen background for the main menu
//but only if we're not in a map (only intro screen and titlemap qualify)
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
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, isGrayed());

		if (!xhair)
			return indent;
		string texname = String.Format("XHAIRB%d", xhair.GetInt());
		TextureID tex = TexMan.CheckForTexture(texname, TexMan.Type_Any);
		if (!tex)
			return indent;
		vector2 texsize = TexMan.GetScaledSize(tex);
			
		String label = Stringtable.Localize(mLabel);
		int wd = Menu.OptionWidth(label);
		int x = (screen.GetWidth() + wd) / 2;
		int w = screen.GetWidth();
		int h = screen.GetHeight();
		Screen.DrawTexture(
			tex, true, 
			x, y, 
			DTA_VirtualWidth, w, 
			DTA_VirtualHeight, h, 
			DTA_FullscreenScale, FSMode_ScaleToFit43,
			DTA_LegacyRenderStyle, Style_Add
		);
		return indent;
	}
}