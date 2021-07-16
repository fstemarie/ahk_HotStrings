﻿; ----------------------------------------------------------------------------
;region Script level settings
#SingleInstance, force
#NoEnv ; Recommended for performance and compatibility
SendMode Input ; Recommended for new scripts
; SetKeyDelay 20
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
;endregion
; ----------------------------------------------------------------------------

; LVM_SETHOVERTIME   := 0x1047 ; (LVM_FIRST + 71)
; LVN_HOTTRACK       := -121 ; (LVN_FIRST - 21)
; LVS_EX_TRACKSELECT := 0x00000008
; WM_NOTIFY          := 0x004E
; WM_ACTIVATEAPP     := 0x001C
#include *i <ObjCSV>
#include *i <Picker>

global version = 1
global category
global csvFile := Get_CsvFile()
global objCSV

; ----------------------------------------------------------------------------
;region Auto-Execute Section
Check_Updated() ; Checks to see if it's been updated to notify the user
Notify_Updates() ; Checks to see if a new version is out
Check_Dependencies() ; Checks for and download the dependencies
Load_CSV() ; Loads the data from the CSV file
Create_HotStrings() ; From the loaded data, create the hotstrings
Func("Picker_Build").call() ; Build the Gui
Func("Picker_Show").call() ; Show the Gui that we just built
return
;endregion
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
;region Code unrelated to Gui
Check_Updated() {
    if (FileExist(A_ScriptDir . "\updated.txt")) {
        FileDelete, %A_ScriptDir%\updated.txt
        TrayTip, Updates, The script has been updated
    }
}

Notify_Updates() {
    OutputDebug, % "-- Notify_Updates()"
    if (Check_Updates()) {
        Update_Script()
    }
}

Check_Updates() {
    OutputDebug, % "-- Check_Updates()"
    global version
    static updatesAvailable = "New"

    if (updatesAvailable = "New") {
        url := "https://raw.githubusercontent.com/"
        . "fstemarie/ahk_HotStrings/master/version.txt"
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, true)
        whr.Send()
        whr.WaitForResponse()
        gh_version := Format("{:i}", whr.ResponseText)
        updatesAvailable := (gh_version > version)
    }
    return updatesAvailable
}

Update_Script() {
    OutputDebug, % "-- Update_Script()"
    url := "https://raw.githubusercontent.com/fstemarie/"
    . "ahk_HotStrings/master/HotStrings/HotStrings.ahk"
    UrlDownloadToFile, %url%, %A_ScriptFullPath%
    FileAppend, "", %A_ScriptDir% . "\updated.txt"
    Reload
}

Check_Dependencies() {
    OutputDebug, % "-- Check_Dependencies()"
    hasToReload := false
    libDir := A_ScriptDir . "\Lib"
    if (!FileExist(libDir))
        FileCreateDir, %libDir%

    ; ObjCSV.ahk
    file := libDir . "\ObjCSV.ahk"
    if (!FileExist(file)) {
        url := "https://raw.githubusercontent.com/"
        . "JnLlnd/ObjCSV/master/Lib/ObjCSV.ahk"
        UrlDownloadToFile, %url%, %file%
        hasToReload := true
    }
    ; Picker.ahk
    file := libDir . "\Picker.ahk"
    if (!FileExist(file)) {
        url := "https://raw.githubusercontent.com/"
        . "fstemarie/ahk_HotStrings/master/HotStrings/Lib/Picker.ahk"
        UrlDownloadToFile, %url%, %file%
        hasToReload := true
    }
    if (hasToReload)
        Reload
}

Get_CsvFile() {
    OutputDebug, % "-- Get_csvFile()"
    configFile := (SubStr(A_ScriptFullPath, 1, -4) . ".ini")
    IniRead, csvFile, %configFile%, Configuration, CsvFile
    if (csvFile == "ERROR") {
        FileSelectFile, fsfValue, 3,, Choose your HotStrings CSV file
        , CSV File (*.csv)
        if (fsfValue) {
            IniWrite, %fsfValue%, %configFile%, Configuration, CsvFile
            csvFile := fsfValue
        } else {
            ExitApp, 1
        }
    }
    return csvFile
}

Load_CSV() {
    objCSV := Func("ObjCSV_CSV2Collection").call(csvFile
        , "HotString,Text,Category,Treated", False)
}

Create_HotStrings() {
    OutputDebug, % "-- Load_HotStrings()"
    ; Setup HotStrings
    Loop, % objCSV.MaxIndex() {
        row := objCSV[A_Index]
        try {
            if (!row.Treated) {
                Hotstring("`:R`:" row.HotString, row.Text)
            } else {
                HotString("`:`:" row.HotString, row.Text)
            }
            OutputDebug, % "Added HotString: " row.HotString
        }
        catch {
            MsgBox "The hotstring does not exist or it has no variant for "
            . "the current IfWin criteria."
        }
    }
}

Fetch_Password() {
    OutputDebug, % "-- Get_Password()"
    static password
    if (password = "") {
        cmd := "KeePassCommand getfield Citrix Password"
        out := ComObjCreate("WScript.Shell")
        .Exec(A_ComSpec . " /q /c " . cmd).StdOut.ReadAll()
        out := StrSplit(out, "`r`n")[4]
        out := RegExReplace(out, "\s+", " ")
        password := StrSplit(out, " ")[3]
    }
    return password
}
return
;endregion
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
;region HotKeys and HotStrings definitions

; #IfWinNotActive, ahk_exe Code.exe
F1::
    OutputDebug, % "HotKey F1 Pressed"
    Loop 2 {
        Func("Picker_Show").call()
    }
return
#IfWinActive

#IfWinActive, PickerGui
#F1::
    OutputDebug, % "HotKey WIN-F1 Pressed"
    Run, GeekSquad.ods, D:\francois\Documents
return
#IfWinActive

#IfWinActive, Virtual Desktop - Desktop Viewer
:*:###::
    SendRaw % Fetch_Password()
return
#IfWinActive

:?:ino::ion
::PArfait::Parfait
::PArfais::Parfait
::connexino::connexion
:C:JE::Je
;endregion
; ----------------------------------------------------------------------------
