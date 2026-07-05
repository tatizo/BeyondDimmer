class Status
{
    ShowSerial := 0

    TooltipId := 1
    BarWidth := 16

    DefaultDuration := 800
    DefaultWarningDuration := 1500

    FilledBarChar := "▋"
    EmptyBarChar := "▏"

    __New(Config)
    {
        this.Config := Config
    }

    Show(
        Brightness,
        Contrast,
        ActiveControl := "",
        Direction := "",
        UseBeyondSymbol := false,
        BrightnessAtMaximum := false,
        ContrastAtMinimum := false,
        Prefix := ""
    ) {
        if !this.ShouldShow()
            return

        this.ShowSerial += 1
        local CurrentSerial := this.ShowSerial

        local Text := this.BuildStatusText(
            Brightness,
            Contrast,
            BrightnessAtMaximum,
            ContrastAtMinimum,
            Prefix
        )

        this.ShowNearMouse(Text)
        this.ScheduleHide(CurrentSerial, this.GetStatusDuration())
    }

    ShowWarning(Message)
    {
        if !this.ShouldShow()
            return

        this.ShowSerial += 1
        local CurrentSerial := this.ShowSerial

        local Text := this.BuildWarningText(Message)

        this.ShowNearMouse(Text)
        this.ScheduleHide(CurrentSerial, this.GetWarningDuration())
    }

    BuildStatusText(
        Brightness,
        Contrast,
        BrightnessAtMaximum,
        ContrastAtMinimum,
        Prefix
    ) {
        local BrightnessStatus := BrightnessAtMaximum ? "MAX" : ""
        local ContrastStatus := ContrastAtMinimum ? "LIMIT" : ""

        local BrightnessLine := " Brightness  " this.PadLeft(Brightness, 3) "  " this.MakeStatusField(BrightnessStatus)
        local ContrastLine := " Contrast    " this.PadLeft(Contrast, 3) "  " this.MakeStatusField(ContrastStatus)

        local BrightnessBar := this.MakeBar(
            Brightness,
            this.GetBrightnessMin(),
            this.GetBrightnessMax(),
            this.BarWidth
        )

        ; The Contrast bar represents only the range that BeyondDimmer
        ; actually uses: monitor/config minimum to the standard contrast.
        ; This prevents showing an unreachable area to users.
        local ContrastBar := this.MakeBar(
            Contrast,
            this.GetContrastMin(),
            this.GetContrastMax(),
            this.BarWidth
        )

        local Text := ""

        if (Prefix != "")
            Text .= this.NormalizePrefix(Prefix) "`n`n"

        Text .= BrightnessLine "`n"
        Text .= BrightnessBar "`n`n"
        Text .= ContrastLine "`n"
        Text .= ContrastBar "`n`n"
        Text .= " " this.GetResetHotkeyLabel() "  Reset"

        return Text
    }

    GetResetHotkeyLabel()
    {
        if this.Config.HasOwnProp("HotkeyReset")
            return this.FormatHotkeyLabel(this.Config.HotkeyReset)

        return "F18"
    }

    FormatHotkeyLabel(Hotkey)
    {
        local Text := Trim(String(Hotkey))

        if (Text = "")
            return ""

        local Label := ""
        local Index := 1

        while (Index <= StrLen(Text))
        {
            local Ch := SubStr(Text, Index, 1)

            if (Ch = "^")
                Label := this.AppendHotkeyLabelPart(Label, "Ctrl")
            else if (Ch = "!")
                Label := this.AppendHotkeyLabelPart(Label, "Alt")
            else if (Ch = "+")
                Label := this.AppendHotkeyLabelPart(Label, "Shift")
            else if (Ch = "#")
                Label := this.AppendHotkeyLabelPart(Label, "Win")
            else if (Ch = "*" || Ch = "~" || Ch = "$" || Ch = "<" || Ch = ">")
            {
                ; AHK hotkey options / left-right modifiers are internal notation.
                ; Keep the tooltip readable by omitting these symbols.
            }
            else
            {
                Label := this.AppendHotkeyLabelPart(Label, SubStr(Text, Index))
                break
            }

            Index += 1
        }

        return (Label = "") ? Text : Label
    }

    AppendHotkeyLabelPart(Label, Part)
    {
        return (Label = "") ? Part : Label " + " Part
    }

    NormalizePrefix(Prefix)
    {
        if (Prefix = "")
            return ""

        return " " Prefix
    }

    BuildWarningText(Message)
    {
        if InStr(StrLower(Message), "reconnecting")
            return " Monitor reconnecting..."

        return " " Message
    }

    MakeBar(Value, MinValue, MaxValue, Width)
    {
        if (Width <= 0)
            return ""

        if (MaxValue <= MinValue)
            return this.RepeatText(this.EmptyBarChar, Width)

        local Ratio := (Value - MinValue) / (MaxValue - MinValue)

        if (Ratio < 0)
            Ratio := 0
        else if (Ratio > 1)
            Ratio := 1

        local Filled := Round(Ratio * Width)
        local Bar := ""

        Loop Width
            Bar .= (A_Index <= Filled) ? this.FilledBarChar : this.EmptyBarChar

        return Bar
    }

    MakeStatusField(StatusText)
    {
        ; Keep the tooltip width stable by always reserving the same field.
        ; Do not use brackets here because the status word should be subtle.
        if (StatusText = "")
            return "     "

        return this.PadRight(StatusText, 5)
    }

    PadLeft(Value, Width)
    {
        local Text := String(Value)

        while (StrLen(Text) < Width)
            Text := " " Text

        return Text
    }

    PadRight(Value, Width)
    {
        local Text := String(Value)

        while (StrLen(Text) < Width)
            Text .= " "

        if (StrLen(Text) > Width)
            Text := SubStr(Text, 1, Width)

        return Text
    }

    RepeatText(Text, Count)
    {
        local Result := ""

        Loop Count
            Result .= Text

        return Result
    }

    Hide()
    {
        ToolTip(,,, this.TooltipId)
    }

    ShowNearMouse(Text)
    {
        ; Let the Windows standard ToolTip choose the position near the mouse cursor.
        ; This is more reliable than custom coordinate correction across apps, DPI,
        ; taskbar positions, and screen edges.
        ;
        ; Do not hide before updating; hiding causes visible redraw flicker during
        ; fast knob rotation. Updating the same ToolTip ID is smoother.
        ToolTip(Text,,, this.TooltipId)
    }


    ScheduleHide(Serial, Duration)
    {
        SetTimer (() => this.HideIfCurrent(Serial)), -Duration
    }

    HideIfCurrent(Serial)
    {
        if (Serial != this.ShowSerial)
            return

        this.Hide()
    }

    ShouldShow()
    {
        if this.Config.HasOwnProp("ShowStatus")
            return !!this.Config.ShowStatus

        if this.Config.HasOwnProp("ShowToolTip")
            return !!this.Config.ShowToolTip

        return true
    }

    GetStatusDuration()
    {
        if this.Config.HasOwnProp("StatusDuration")
            return this.Config.StatusDuration

        return this.DefaultDuration
    }

    GetWarningDuration()
    {
        if this.Config.HasOwnProp("WarningDuration")
            return this.Config.WarningDuration

        return this.DefaultWarningDuration
    }

    GetBrightnessMin()
    {
        if this.Config.HasOwnProp("MinimumBrightness")
            return this.Config.MinimumBrightness

        return 0
    }

    GetBrightnessMax()
    {
        return 100
    }

    GetContrastMin()
    {
        if this.Config.HasOwnProp("MinimumContrast")
            return this.Config.MinimumContrast

        return 0
    }

    GetContrastMax()
    {
        if this.Config.HasOwnProp("DefaultContrast")
            return this.Config.DefaultContrast

        return 50
    }
}
