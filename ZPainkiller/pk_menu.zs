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

class ListMenuItemPKDrawMenuBackground : ListMenuItemStaticPatch {
	bool shouldDraw;

	override void Draw(bool selected, ListMenuDescriptor desc) {
		if (gamestate == GS_LEVEL)
			return;
		if (!mTexture.Exists())
			return;
		PK_StatusBarScreen.Fill("000000",0,0,statscr_base_width,statscr_base_height,1);
		PK_StatusBarScreen.DrawTexture(mTexture, (960,540));
	}
}