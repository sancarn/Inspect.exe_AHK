OnMessage(0x14, "WM_ERASEBKGND")
Gui, -Caption +ToolWindow
Gui, +LastFound
WinSet, TransColor, Black
; Create the pen here so we don't need to create/delete it every time.
RedPen := DllCall("CreatePen", "int", PS_SOLID:=0, "int", 5, "uint", 0xff)
return

WM_ERASEBKGND(wParam, lParam)
{
    global x1, y1, x2, y2, RedPen
    Critical 50
    if A_Gui = 1
    {
        ; Retrieve stock brush.
        blackBrush := DllCall("GetStockObject", "int", BLACK_BRUSH:=0x4)
        ; Select pen and brush.
        oldPen := DllCall("SelectObject", "uint", wParam, "uint", RedPen)
        oldBrush := DllCall("SelectObject", "uint", wParam, "uint", blackBrush)
        ; Draw rectangle.
        DllCall("Rectangle", "uint", wParam, "int", 0, "int", 0, "int", x2-x1, "int", y2-y1)
        ; Reselect original pen and brush (recommended by MS).
        DllCall("SelectObject", "uint", wParam, "uint", oldPen)
        DllCall("SelectObject", "uint", wParam, "uint", oldBrush)
        return 1
    }
}

+LButton::
    MouseGetPos, xorigin, yorigin
    SetTimer, rectangle, 10
return

rectangle:
    MouseGetPos, x2, y2
    
    ; Has the mouse moved?
    if (x1 y1) = (x2 y2)
        return
    
    ; Allow dragging to the left of the click point.
    if (x2 < xorigin) {
        x1 := x2
        x2 := xorigin
    } else
        x1 := xorigin
    
    ; Allow dragging above the click point.
    if (y2 < yorigin) {
        y1 := y2
        y2 := yorigin
    } else
        y1 := yorigin
    
    Gui, Show, % "NA X" x1 " Y" y1 " W" x2-x1 " H" y2-y1
    Gui, +LastFound
    DllCall("RedrawWindow", "uint", WinExist(), "uint", 0, "uint", 0, "uint", 5)
return

+LButton Up::
    SetTimer, rectangle, Off
    Gui, Cancel
return