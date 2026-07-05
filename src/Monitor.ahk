class Monitor
{
    ; PHYSICAL_MONITOR:
    ; HANDLE hPhysicalMonitor + WCHAR szPhysicalMonitorDescription[128]
    ; WCHAR is UTF-16, so 128 characters = 256 bytes.
    static PhysicalMonitorStructSize := A_PtrSize + 256

    MonitorHandle := 0
    PhysicalHandle := 0
    PhysicalMonitorBuffer := 0

    IsAvailable := false
    LastErrorMessage := ""

    Brightness := 0
    BrightnessMin := 0
    BrightnessMax := 100

    Contrast := 0
    ContrastMin := 0
    ContrastMax := 100

    __New()
    {
        this.Open()
    }

    Open()
    {
        ; Re-open safely if Open() is called after resume, power loss, or input changes.
        this.Close()

        this.IsAvailable := false

        this.LastErrorMessage := ""

        this.MonitorHandle := DllCall(
            "MonitorFromPoint"
            , "Int64", 0
            , "UInt", 2
            , "Ptr"
        )

        if !this.MonitorHandle
            return this.FailOpen("MonitorFromPoint failed.")

        local MonitorCount := 0

        if !DllCall(
            "Dxva2.dll\GetNumberOfPhysicalMonitorsFromHMONITOR"
            , "Ptr", this.MonitorHandle
            , "UInt*", &MonitorCount
        )
        {
            return this.FailOpen("GetNumberOfPhysicalMonitorsFromHMONITOR failed.")
        }

        if (MonitorCount < 1)
            return this.FailOpen("No physical monitor found.")

        this.PhysicalMonitorBuffer := Buffer(Monitor.PhysicalMonitorStructSize, 0)

        if !this.TryGetPhysicalMonitor()
            return this.FailOpen("Physical monitor handle is not ready.")

        this.IsAvailable := true
        this.Refresh()

        return true
    }

    FailOpen(Message)
    {
        this.LastErrorMessage := Message
        this.Close()

        return false
    }

    IsReady()
    {
        return this.IsAvailable && !!this.PhysicalHandle
    }

    EnsureReady()
    {
        if this.IsReady()
            return true

        return this.Open()
    }

    TryGetPhysicalMonitor()
    {
        Loop 10
        {
            if DllCall(
                "Dxva2.dll\GetPhysicalMonitorsFromHMONITOR"
                , "Ptr", this.MonitorHandle
                , "UInt", 1
                , "Ptr", this.PhysicalMonitorBuffer
            )
            {
                this.PhysicalHandle := NumGet(this.PhysicalMonitorBuffer, 0, "Ptr")

                if this.PhysicalHandle
                    return true
            }

            Sleep 500
        }

        return false
    }

    Refresh()
    {
        if !this.IsReady()
            return false

        local BrightnessOk := this.RefreshBrightness()
        local ContrastOk := this.RefreshContrast()

        return BrightnessOk && ContrastOk
    }

    RefreshBrightness()
    {
        if !this.IsReady()
            return false

        local BrightnessMin := 0
        local BrightnessCurrent := 0
        local BrightnessMax := 0

        local Success := this.TryExecute(
            (*) => DllCall(
                "Dxva2.dll\GetMonitorBrightness"
                , "Ptr", this.PhysicalHandle
                , "UInt*", &BrightnessMin
                , "UInt*", &BrightnessCurrent
                , "UInt*", &BrightnessMax
            )
        )

        if !Success
        {
            this.NotifyWarning("GetMonitorBrightness failed.")
            return false
        }

        this.BrightnessMin := BrightnessMin
        this.Brightness := BrightnessCurrent
        this.BrightnessMax := BrightnessMax

        return true
    }

    RefreshContrast()
    {
        if !this.IsReady()
            return false

        local ContrastMin := 0
        local ContrastCurrent := 0
        local ContrastMax := 0

        local Success := this.TryExecute(
            (*) => DllCall(
                "Dxva2.dll\GetMonitorContrast"
                , "Ptr", this.PhysicalHandle
                , "UInt*", &ContrastMin
                , "UInt*", &ContrastCurrent
                , "UInt*", &ContrastMax
            )
        )

        if !Success
        {
            this.NotifyWarning("GetMonitorContrast failed.")
            return false
        }

        this.ContrastMin := ContrastMin
        this.Contrast := ContrastCurrent
        this.ContrastMax := ContrastMax

        return true
    }

    Close()
    {
        if this.PhysicalHandle
        {
            DllCall(
                "Dxva2.dll\DestroyPhysicalMonitor"
                , "Ptr", this.PhysicalHandle
            )
        }

        this.IsAvailable := false
        this.PhysicalHandle := 0
        this.MonitorHandle := 0
        this.PhysicalMonitorBuffer := 0
    }

    GetBrightness()
    {
        return this.Brightness
    }

    SetBrightness(Value)
    {
        if !this.EnsureReady()
        {
            this.NotifyWarning("Monitor is not ready.")
            return false
        }

        Value := this.Clamp(Value, this.BrightnessMin, this.BrightnessMax)

        if (Value = this.Brightness)
            return true

        local Success := this.TrySetBrightness(Value)

        if !Success
        {
            this.NotifyWarning("Brightness change failed.")
            return false
        }

        this.Brightness := Value
        return true
    }

    TrySetBrightness(Value)
    {
        return this.TryExecute(
            (*) => DllCall(
                "Dxva2.dll\SetMonitorBrightness"
                , "Ptr", this.PhysicalHandle
                , "UInt", Value
            )
        )
    }

    GetContrast()
    {
        return this.Contrast
    }

    SetContrast(Value)
    {
        if !this.EnsureReady()
        {
            this.NotifyWarning("Monitor is not ready.")
            return false
        }

        Value := this.Clamp(Value, this.ContrastMin, this.ContrastMax)

        if (Value = this.Contrast)
            return true

        local Success := this.TrySetContrast(Value)

        if !Success
        {
            this.NotifyWarning("Contrast change failed.`nOSD may be open.")
            return false
        }

        this.Contrast := Value
        return true
    }

    TrySetContrast(Value)
    {
        return this.TryExecute(
            (*) => DllCall(
                "Dxva2.dll\SetMonitorContrast"
                , "Ptr", this.PhysicalHandle
                , "UInt", Value
            )
        )
    }

    TryExecute(Callback, RetryCount := 3, RetryDelay := 80)
    {
        Loop RetryCount
        {
            if Callback.Call()
                return true

            Sleep RetryDelay
        }

        return false
    }

    NotifyWarning(Message, Duration := 1200)
    {
        ToolTip "BeyondDimmer`n" Message
        SetTimer () => ToolTip(), -Duration
    }

    Clamp(Value, MinValue, MaxValue)
    {
        if (Value < MinValue)
            return MinValue

        if (Value > MaxValue)
            return MaxValue

        return Value
    }
}
