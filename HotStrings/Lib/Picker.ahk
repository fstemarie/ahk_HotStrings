
; ----------------------------------------------------------------------------
; Picker Gui Code
global lvPicker
global txtPicker
global hwndPicker
global lbCategories

if (A_ScriptName = "Picker.ahk")
    ExitApp 1

Picker_Build() {
    OutputDebug, % "-- Picker_Build()"
    Gui, Picker:New, +Owner +Border +HwndhwndPicker, PickerGui
    Gui, +LabelPicker_On -Caption +AlwaysOnTop
    Gui, Font, s16, Cascadia Bold
    Gui, Margin, 10, 10
    Gui, Add, Button, Hidden Default gPicker_btnSubmit_OnClick  ;btnSubmit
    Gui, Add, ListView, xm ym w1140 r15 LV0x8 vlvPicker HwndhwndlvPicker
    GuiControl, +gPicker_lvPicker_OnEvent +Hdr, lvPicker
    GuiControl, +AltSubmit -Multi +Border Report, lvPicker ;lvPicker
    PostMessage, 0x1047, 0, 1,, ahk_id %hwndlvPicker% ;LVM_SETHOVERTIME
    Gui, Add, ListBox, x+m ym w150 hp 0x100 vlbCategories
    GuiControl, +gPicker_lbCategories_OnEvent Sort, lbCategories ;lbCategories
    Gui, Add, Text, vtxtPicker xm w1300 r10 Border
    Gui, Add, Button, xm y+m w100 r1 gPicker_btnQuit_OnClick, Quit ;btnReload
    Gui, Add, Button, x+m wp r1 gPicker_btnReload_OnClick, Reload ;btnQuit
    Gui, Add, Button, x+m wp r1 gPicker_btnEdit_OnClick, Edit CSV ;btnEdit
    Gui, Add, Button, x+m wp r1 gPicker_btnDoc_OnClick, Edit Doc ;btnDoc
    Gui, Add, Button, x+m wp r1 gPicker_btnNote_OnClick, Notepad ;btnNote
    OnMessage(0x001C, "Picker_OnWMACTIVATEAPP") ;WM_ACTIVATEAPP
    Picker_lbCategories_Update()
    Picker_lvPicker_Update()
}

Picker_OnEscape() {
    OutputDebug, % "-- Picker_OnEscape()"
    Gui Picker:Hide
}

Picker_OnWMACTIVATEAPP(activated) {
    OutputDebug, % "-- Picker_OnWMACTIVATEAPP()"
    if (!activated) {
        Gui, Picker:Hide
        return 0
    }
}

Picker_btnSubmit_OnClick() {
    OutputDebug, % "-- Picker_btnSubmit_OnClick()"
    Gui, Picker:Default
    Gui, ListView, lvPicker
    row := LV_GetNext(0)
    if (row > 0) {
        Gui, Picker:Hide
        LV_GetText(cell, row, 2)
        LV_GetText(treated, row, 4)
        if (!treated) {
            SendRaw, %cells%
        } else {
            Send, %cell%
        }
    }
}

Picker_lbCategories_OnEvent() {
    global category
    if (A_GuiEvent = "Normal") {
        GuiControlGet, category,, lbCategories
        Picker_lvPicker_Update()
    }
}

Picker_lbCategories_Update() {
    ; Setup categories
    categories := "*|"
    Loop, % objCSV.MaxIndex() {
        row := objCSV[A_Index]
        categories := categories . "|" . row.Category
    }
    Sort, categories, U D|
    GuiControl, Text, lbCategories, %categories%
}

Picker_lvPicker_OnEvent() {
    OutputDebug, % "-- Picker_lvPicker_OnEvent()"
    Gui, Picker:Default
    Gui, ListView, lvPicker
    LV_GetText(cell, A_EventInfo, 2)
    LV_GetText(treated, A_EventInfo, 4)
    if (A_GuiEvent == "Normal") {
        Gui, Picker:Hide
        if (!treated) {
            SendRaw, %cell%
        } else {
            Send, %cell%
        }
    } else if (A_GuiEvent == "I") {
        Critical, On
        GuiControl, Text, txtPicker, %cell%
    }
}

Picker_lvPicker_Update() {
    if (category and category != "*") {
        objFiltered := []
        Loop, % objCSV.MaxIndex() {
            if (objCSV[A_Index].Category = category)
                objFiltered.Push(objCSV[A_Index])
        }
    } else {
        objFiltered := objCSV
    }

    ; Fill the ListView
    Gui, Picker:Default
    Gui, ListView, lvPicker
    GuiControl, Hide, lvPicker
    LV_Delete()
    Func("ObjCSV_Collection2Listview").call(objFiltered, Picker
        , lvPicker, strFieldOrder := "HotString,Text,Category,Treated")
    LV_ModifyCol(1, AutoHDR)
    LV_ModifyCol(2, 1005)
    LV_ModifyCol(3, 0)
    LV_ModifyCol(4, 0)
    GuiControl, Show, lvPicker
    LV_Modify(20, "+Focus +Select")
}

Picker_btnReload_OnClick() {
    OutputDebug, % "-- Picker_btnReload_OnClick()"
    Reload
}

Picker_btnQuit_OnClick() {
    OutputDebug, % "-- Picker_btnQuit_OnClick()"
    ExitApp, 0
}

Picker_btnEdit_OnClick() {
    OutputDebug, % "-- Picker_btnEdit_OnClick()"
    static editor := false
    if (!editor) {
        configFile := SubStr(A_ScriptFullPath, 1, -4) . ".ini"
        IniRead, editor, %configFile%, Configuration, Editor
        if (editor == "ERROR") {
            Gui Picker:Hide
            FileSelectFile, fsfValue, 3, C:\Windows\notepad.exe
                , Choose your CSV text editor, Text Editor (*.exe)
            if (fsfValue) {
                IniWrite, %fsfValue%, %configFile%, Configuration, Editor
                editor := fsfValue
            } else {
                editor := false
                return
            }
        }
    }
    Run %editor% %csvFile%
}

Picker_btnDoc_OnClick() {
    OutputDebug, % "-- Picker_btnDoc_OnClick()"
    static doc
    if (!doc) {
        configFile := (SubStr(A_ScriptFullPath, 1, -4) . ".ini")
        IniRead, doc, %configFile%, Configuration, Document
        if (doc == "ERROR") {
            Gui Picker:Hide
            FileSelectFile, fsfValue, 3, %A_MyDocuments%
                , Choose your document, Document (*.*)
            if (fsfValue) {
                IniWrite, %fsfValue%, %configFile%, Configuration, Document
                doc := fsfValue
            } else {
                doc := false
                return
            }
        }
    }
    Run, %doc%
}

Picker_btnNote_OnClick() {
    OutputDebug, % "-- Picker_btnNote_OnClick()"
    Run notepad.exe
}

Picker_Show() {
    OutputDebug, % "-- Picker_Show()"
    static centers
    if !IsObject(centers) {
        Gui, Show, AutoSize Center
        centers := Picker_FindCenters()
    }
    mon := Picker_GetMonitor()
    guiLeft := centers[mon].guiLeft
    guiTop := centers[mon].guiTop
    Gui, Picker:Show, % "x"guiLeft " y"guiTop
    GuiControl, Focus, lvPicker
    LV_Modify(1, "+Focus +Select")
}

Picker_GetMonitor() {
    OutputDebug, % "-- Picker_GetMonitor()"
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        if (mouseX >= monLeft && mouseX <= monRight
                && mouseY >= monTop && mouseY <= monBottom) {
            mon := A_Index
            break
        }
    }
    return %mon%
}

Picker_FindCenters() {
    OutputDebug, % "-- Picker_FindCenters()"
    centers := []
    WinGetPos,,, guiWidth, guiHeight, ahk_id %hwndPicker%
    SysGet, monCount, MonitorCount
    Loop % monCount {
        SysGet, mon, Monitor, %A_Index%
        guiLeft := Ceil(monLeft + (monRight - monLeft - guiWidth) / 2)
        guiTop := Ceil(monTop + (monBottom - monTop - guiHeight) / 2)
        centers.Push({"guiLeft": guiLeft, "guiTop": guiTop})
    }
    return centers
}