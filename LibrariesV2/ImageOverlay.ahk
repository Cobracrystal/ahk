
class ImageOverlay {
	static __New() {

	}

	makeOverlay() {
		MouseGetPos(&x, &y)
		this.drawRect(x,y)
	}

	drawRect(x1,y1) {
		
	}

	createImage() {
	}

	showGui(x,y,w,h,image) {
		tgui := Gui("+AlwaysOnTop +ToolWindow -Caption", "ImageOverlay")
		tgui.BackColor := "FFFFFF"
		WinSetTransColor("FFFFFF", tgui.hwnd)
		tgui.AddPicture(Format("w{1} h{2}", w, h), image)
		tgui.Show(Format("x{1} y{2} NoActivate", x, y))
	}

	bitmapFromScreen(x,y,w,h,raster) {
		chdc := CreateCompatibleDC()
		hbm := CreateDIBSection2(w, h, chdc)
		obm := SelectObject(chdc, hbm)
		hhdc := hhdc ? hhdc : GetDC()
		BitBlt(chdc, 0, 0, w, h, hhdc, x, y, Raster)
		ReleaseDC(hhdc)
		pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
		SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
		return pBitmap
	}
}

