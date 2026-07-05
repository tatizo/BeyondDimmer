#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
#UseHook True
#MaxThreadsPerHotkey 1

#Include Version.ahk
#Include Config.ahk
#Include Monitor.ahk
#Include Status.ahk
#Include BrightnessController.ahk
#Include Application.ahk

global App := 0

Persistent()

InitializeApplicationIconAndTrayMenu()

; ============================================================
; BeyondDimmer application icon / tray menu patch
; AutoHotkey v2
; ============================================================
;
; Place the call below near the top of BeyondDim.ahk,
; after #Requires / #SingleInstance / Persistent and before normal startup.
;
;     InitializeApplicationIconAndTrayMenu()
;
; This version supports both layouts:
;
;   BeyondDimmer\BeyondDim.ahk
;   BeyondDimmer\src\BeyondDim.ahk
;
; It also removes the default "Pause Script" tray item because it is
; confusing for this application. Use "Suspend Hotkeys" when you want
; to disable the hotkeys.
; ============================================================

InitializeApplicationIconAndTrayMenu() {
    SetApplicationIcon()
    RemovePauseScriptTrayItem()
}

RemovePauseScriptTrayItem() {
    ; The visible item is shown as "Pause Script", but the internal
    ; AutoHotkey tray-menu item name may include an access-key marker.
    ; Try both forms so the item is removed in both .ahk and compiled .exe runs.
    for itemName in ["&Pause Script", "Pause Script"] {
        try A_TrayMenu.Delete(itemName)
    }
}

SetApplicationIcon() {
    iconPath := GetApplicationIconPath()

    if A_IsCompiled {
        ; Use the icon embedded in BeyondDim.exe.
        ; The final true freezes the icon so Pause/Suspend does not replace it.
        try {
            TraySetIcon(A_ScriptFullPath, 1, true)
            return
        }

        ; Fallback for unusual build environments.
        if FileExist(iconPath) {
            TraySetIcon(iconPath, , true)
        }
        return
    }

    ; Running as BeyondDim.ahk.
    ; Use the external icon file from assets.
    if FileExist(iconPath) {
        TraySetIcon(iconPath, , true)
    }
}

GetApplicationIconPath() {
    candidates := [
        A_ScriptDir "\assets\icons\candidates\icon_01_gradient_square.ico",
        A_ScriptDir "\..\assets\icons\candidates\icon_01_gradient_square.ico"
    ]

    for path in candidates {
        if FileExist(path) {
            return path
        }
    }

    return ""
}

StartBeyondDimmer()

StartBeyondDimmer(*)
{
    global App

    try
    {
        App := Application()
    }
    catch as Err
    {
        MsgBox(
            "BeyondDimmer の起動に失敗しました。`n`n" . Err.Message,
            "BeyondDimmer",
            "Iconx"
        )
        ExitApp
    }
}
