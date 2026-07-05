class Config
{
    IniPath := ""

    __New()
    {
        this.IniPath := A_ScriptDir "\BeyondDim.ini"

        this.LoadDefaults()
        this.CreateIniIfNeeded()
        this.LoadIni()
        this.ApplyInputMode()
    }

    LoadDefaults()
    {
        ; Brightness
        this.StepBrightness := 5
        this.DefaultBrightness := 20
        this.MinimumBrightness := 0

        ; Contrast
        this.StepContrast := 5
        this.DefaultContrast := 50
        this.MinimumContrast := 0

        ; Input
        this.InputMode := "Left-hand_Device"

        ; Left-hand_Device
        this.HotkeyIncrease := "F16"
        this.HotkeyDecrease := "F17"
        this.HotkeyReset := "F18"

        ; Standard Keyboard
        this.KeyboardIncrease := "^!Up"
        this.KeyboardDecrease := "^!Down"
        this.KeyboardReset := "^!Home"

        ; Status
        this.ShowStatus := true
        this.StatusDuration := 800
        this.WarningDuration := 1500
    }

    CreateIniIfNeeded()
    {
        if FileExist(this.IniPath)
            return

        IniText :=
        (
"; ====================================================
; BeyondDimmer Configuration File
; ====================================================
;
; Input mode:
;
; Mode=Left-hand_Device   Use F16 / F17 / F18
; Mode=Keyboard           Use normal keyboard shortcuts
;
; AutoHotkey modifier keys:
;
; ^ = Ctrl
; ! = Alt
; + = Shift
; # = Windows key
;
; Examples:
;
; ^!Up    = Ctrl + Alt + Up
; ^!Down  = Ctrl + Alt + Down
; ^!Home  = Ctrl + Alt + Home
;
; Status:
;
; ShowStatus=1 enables the ToolTip status display.
; StatusDuration is in milliseconds.
;
; ====================================================

[Brightness]
Step=5
Default=20
Minimum=0

[Contrast]
Step=5
Default=50
Minimum=0

[Input]
Mode=Left-hand_Device

[Hotkey]
Increase=F16
Decrease=F17
Reset=F18

KeyboardIncrease=^!Up
KeyboardDecrease=^!Down
KeyboardReset=^!Home

[Status]
ShowStatus=1
StatusDuration=800
WarningDuration=1500
"
        )

        FileAppend IniText, this.IniPath, "UTF-8"
    }

    LoadIni()
    {
        this.StepBrightness := this.ReadInteger("Brightness", "Step", this.StepBrightness, 1, 100)
        this.DefaultBrightness := this.ReadInteger("Brightness", "Default", this.DefaultBrightness, 0, 100)
        this.MinimumBrightness := this.ReadInteger("Brightness", "Minimum", this.MinimumBrightness, 0, 100)

        this.StepContrast := this.ReadInteger("Contrast", "Step", this.StepContrast, 1, 100)
        this.DefaultContrast := this.ReadInteger("Contrast", "Default", this.DefaultContrast, 0, 100)
        this.MinimumContrast := this.ReadInteger("Contrast", "Minimum", this.MinimumContrast, 0, 100)

        this.InputMode := this.ReadString("Input", "Mode", this.InputMode)

        this.HotkeyIncrease := this.ReadString("Hotkey", "Increase", this.HotkeyIncrease)
        this.HotkeyDecrease := this.ReadString("Hotkey", "Decrease", this.HotkeyDecrease)
        this.HotkeyReset := this.ReadString("Hotkey", "Reset", this.HotkeyReset)

        this.KeyboardIncrease := this.ReadString("Hotkey", "KeyboardIncrease", this.KeyboardIncrease)
        this.KeyboardDecrease := this.ReadString("Hotkey", "KeyboardDecrease", this.KeyboardDecrease)
        this.KeyboardReset := this.ReadString("Hotkey", "KeyboardReset", this.KeyboardReset)

        this.ShowStatus := this.ReadBoolean("Status", "ShowStatus", this.ShowStatus)
        this.StatusDuration := this.ReadInteger("Status", "StatusDuration", this.StatusDuration, 100, 5000)
        this.WarningDuration := this.ReadInteger("Status", "WarningDuration", this.WarningDuration, 300, 10000)

        ; Backward compatibility with older INI files.
        if !this.SectionExists("Status")
            this.ShowStatus := this.ReadBoolean("Display", "ShowToolTip", this.ShowStatus)
    }

    ApplyInputMode()
    {
        if (StrLower(this.InputMode) != "keyboard")
            return

        this.HotkeyIncrease := this.KeyboardIncrease
        this.HotkeyDecrease := this.KeyboardDecrease
        this.HotkeyReset := this.KeyboardReset
    }

    SectionExists(Section)
    {
        try
        {
            IniRead(this.IniPath, Section)
            return true
        }
        catch
        {
            return false
        }
    }

    ReadString(Section, Key, DefaultValue)
    {
        local MissingValue := "__BeyondDimmer_Missing__"
        local Value := IniRead(this.IniPath, Section, Key, MissingValue)
        Value := Trim(Value)

        if (Value = MissingValue || Value = "")
        {
            IniWrite DefaultValue, this.IniPath, Section, Key
            return DefaultValue
        }

        return Value
    }

    ReadInteger(Section, Key, DefaultValue, MinValue, MaxValue)
    {
        local MissingValue := "__BeyondDimmer_Missing__"
        local RawValue := IniRead(this.IniPath, Section, Key, MissingValue)
        RawValue := Trim(RawValue)

        local Value := DefaultValue
        local ShouldWriteBack := false

        if (RawValue = MissingValue || RawValue = "")
        {
            ShouldWriteBack := true
        }
        else if !IsInteger(RawValue)
        {
            ShouldWriteBack := true
        }
        else
        {
            Value := Integer(RawValue)

            if (Value < MinValue)
            {
                Value := MinValue
                ShouldWriteBack := true
            }
            else if (Value > MaxValue)
            {
                Value := MaxValue
                ShouldWriteBack := true
            }
        }

        if ShouldWriteBack
            IniWrite Value, this.IniPath, Section, Key

        return Value
    }

    ReadBoolean(Section, Key, DefaultValue)
    {
        local MissingValue := "__BeyondDimmer_Missing__"
        local RawValue := IniRead(this.IniPath, Section, Key, MissingValue)
        RawValue := Trim(RawValue)
        local Value := StrLower(RawValue)

        if (Value = "1" || Value = "true" || Value = "yes" || Value = "on")
            return true

        if (Value = "0" || Value = "false" || Value = "no" || Value = "off")
            return false

        IniWrite DefaultValue ? 1 : 0, this.IniPath, Section, Key
        return DefaultValue
    }
}
