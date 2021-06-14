class ListMenuItemPKTextItemCentered : ListMenuItemTextItem {
	
	override void Draw(bool selected, ListMenuDescriptor desc)	{
		let font = menuDelegate.PickFont(mFont);
		String text = Stringtable.Localize(mText);
		double wmul = 0.8;
		double x = mXpos - font.StringWidth(text) * wmul / 2;
		//DrawText(desc, font, selected ? mColorSelected : mColor, x, abs(mYpos), text, mYpos < 0);
		PK_StatusBarScreen.DrawString(font, text, (x, abs(mYpos)), 0, selected ? mColorSelected : mColor, scale: (0.5 * wmul, 0.5));
	}
	
	void PK_DrawMenuText(ListMenuDescriptor desc, Font fnt, int color, double x, double y, String text, bool ontop = false)
	{
		int w = desc ? desc.DisplayWidth() : ListMenuDescriptor.CleanScale;
		int h = desc ? desc.DisplayHeight() : -1;
		if (w == ListMenuDescriptor.CleanScale)
		{
			screen.DrawText(fnt, color, x, y, text, ontop? DTA_CleanTop : DTA_Clean, true);
		}
		else
		{
			screen.DrawText(fnt, color, x, y, text, DTA_VirtualWidth, w, DTA_VirtualHeight, h, DTA_FullscreenScale, FSMode_ScaleToFit43);
		}
	}

}