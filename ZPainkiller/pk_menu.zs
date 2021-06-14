class ListMenuItemPKTextItemCentered : ListMenuItemTextItem {
	
	override void Draw(bool selected, ListMenuDescriptor desc)	{
		let font = menuDelegate.PickFont(mFont);
		String text = Stringtable.Localize(mText);
		double x = mXpos - font.StringWidth(text) / 2;
		//DrawText(desc, font, selected ? mColorSelected : mColor, x, abs(mYpos), text, mYpos < 0);
		PK_StatusBarScreen.DrawString(font, text, (x, abs(mYpos)), 0, selected ? mColorSelected : mColor, scale: (0.5,
 0.5));
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
	override void Draw(bool selected, ListMenuDescriptor desc) {
		if (!mTexture.Exists())
			return;
		PK_StatusBarScreen.DrawTexture(mTexture, (960,540));
	}
}