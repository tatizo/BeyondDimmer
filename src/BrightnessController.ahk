class BrightnessController
{
    LastRefreshTick := 0
    RefreshInterval := 1500
    ContrastAtMinimum := false

    __New(Config)
    {
        this.Config := Config
        this.Monitor := Monitor()
        this.Status := Status(Config)

        if this.Monitor.IsReady()
            this.LastRefreshTick := A_TickCount
    }

    Close()
    {
        this.Monitor.Close()
        this.Status.Hide()
    }

    IncreaseBrightness(*)
    {
        if !this.PrepareMonitorForControl()
        {
            this.Status.ShowWarning("Monitor is reconnecting.")
            return
        }

        local Contrast := this.Monitor.Contrast

        ; Beyond area:
        ; Return Contrast to the normal boundary first.
        if (Contrast < this.Config.DefaultContrast)
        {
            local ContrastTarget := Contrast + this.Config.StepContrast

            if (ContrastTarget > this.Config.DefaultContrast)
                ContrastTarget := this.Config.DefaultContrast

            this.SetContrastWithRecovery(ContrastTarget)
            this.ContrastAtMinimum := false
            this.ShowStatus("", "Contrast", "Up", true)
            return
        }

        ; Normal area:
        ; Contrast is already at the normal boundary.
        local BrightnessTarget := this.Monitor.Brightness + this.Config.StepBrightness

        this.SetBrightnessWithRecovery(BrightnessTarget)
        this.ShowStatus("", "Brightness", "Up", false)
    }

    DecreaseBrightness(*)
    {
        if !this.PrepareMonitorForControl()
        {
            this.Status.ShowWarning("Monitor is reconnecting.")
            return
        }

        local Brightness := this.Monitor.Brightness
        local Contrast := this.Monitor.Contrast

        ; Lower Brightness first.
        if (Brightness > this.Config.MinimumBrightness)
        {
            local BrightnessTarget := Brightness - this.Config.StepBrightness

            if (BrightnessTarget < this.Config.MinimumBrightness)
                BrightnessTarget := this.Config.MinimumBrightness

            this.SetBrightnessWithRecovery(BrightnessTarget)
            this.ShowStatus("", "Brightness", "Down", false)
            return
        }

        ; Brightness is at minimum.
        ; Now start decreasing Contrast: this is the Beyond area.
        if (Contrast > this.Config.MinimumContrast)
        {
            local ContrastBefore := this.Monitor.Contrast
            local ContrastTarget := Contrast - this.Config.StepContrast

            if (ContrastTarget < this.Config.MinimumContrast)
                ContrastTarget := this.Config.MinimumContrast

            this.SetContrastWithRecovery(ContrastTarget)
            this.UpdateContrastMinimumState(ContrastBefore, ContrastTarget)
            this.ShowStatus("", "Contrast", "Down", true)
            return
        }

        this.ContrastAtMinimum := true
        this.ShowStatus("", "Contrast", "Down", true)
    }

    ResetBrightness(*)
    {
        if !this.PrepareMonitorForControl(true)
        {
            this.Status.ShowWarning("Monitor is reconnecting.")
            return
        }

        this.SetBrightnessWithRecovery(this.Config.DefaultBrightness)
        this.SetContrastWithRecovery(this.Config.DefaultContrast)
        this.ContrastAtMinimum := false

        this.ShowStatus("Reset")
    }

    Refresh()
    {
        if this.RefreshMonitorState()
            this.ShowStatus("Refresh")
        else
            this.Status.ShowWarning("Monitor is reconnecting.")
    }

    Reopen()
    {
        this.Monitor.Close()
        Sleep 300
        this.Monitor.Open()
        this.RefreshMonitorState()
    }

    Reset(*)
    {
        this.ResetBrightness()
    }

    PrepareMonitorForControl(ForceRefresh := false)
    {
        ; Fast path:
        ; During continuous knob rotation, use cached values for responsiveness.
        ; Refresh only when needed, such as after idle time, resume, or recovery.
        if !this.Monitor.EnsureReady()
            return this.ReconnectMonitor()

        if (ForceRefresh || this.ShouldRefreshBeforeControl())
            return this.RefreshMonitorState() || this.ReconnectMonitor()

        return true
    }

    ShouldRefreshBeforeControl()
    {
        if (this.LastRefreshTick = 0)
            return true

        return (A_TickCount - this.LastRefreshTick) >= this.RefreshInterval
    }

    RefreshMonitorState()
    {
        if this.Monitor.Refresh()
        {
            this.LastRefreshTick := A_TickCount
            return true
        }

        return false
    }

    ReconnectMonitor()
    {
        this.Monitor.Close()
        Sleep 300

        if !this.Monitor.Open()
            return false

        if !this.Monitor.Refresh()
            return false

        this.LastRefreshTick := A_TickCount
        return true
    }

    SetBrightnessWithRecovery(Value)
    {
        ; Brightness is usually exact and fast, so avoid a readback refresh here.
        ; If the call fails, recover the monitor handle and retry once.
        if this.Monitor.SetBrightness(Value)
            return true

        if !this.ReconnectMonitor()
            return false

        return this.Monitor.SetBrightness(Value)
    }

    SetContrastWithRecovery(Value)
    {
        ; Some monitors clamp Contrast internally. Refresh only Contrast after a
        ; successful write so cached values match the real monitor state.
        if this.Monitor.SetContrast(Value)
        {
            this.Monitor.RefreshContrast()
            this.LastRefreshTick := A_TickCount
            return true
        }

        if !this.ReconnectMonitor()
            return false

        if this.Monitor.SetContrast(Value)
        {
            this.Monitor.RefreshContrast()
            this.LastRefreshTick := A_TickCount
            return true
        }

        return false
    }

    UpdateContrastMinimumState(ContrastBefore, ContrastTarget)
    {
        this.ContrastAtMinimum := false

        if (this.Monitor.Contrast <= this.Config.MinimumContrast)
        {
            this.ContrastAtMinimum := true
            return
        }

        if (ContrastTarget < ContrastBefore && this.Monitor.Contrast >= ContrastBefore)
            this.ContrastAtMinimum := true
    }

    IsBeyond()
    {
        return this.Monitor.Brightness <= this.Config.MinimumBrightness
            && this.Monitor.Contrast < this.Config.DefaultContrast
    }

    IsBrightnessAtMaximum()
    {
        return this.Monitor.Brightness >= this.Monitor.BrightnessMax
    }

    IsContrastAtMinimum()
    {
        return this.ContrastAtMinimum
            || this.Monitor.Contrast <= this.Config.MinimumContrast
    }

    ShowStatus(
        Prefix := "",
        ActiveControl := "",
        Direction := "",
        UseBeyondSymbol := false
    ) {
        this.Status.Show(
            this.Monitor.Brightness,
            this.Monitor.Contrast,
            ActiveControl,
            Direction,
            UseBeyondSymbol,
            this.IsBrightnessAtMaximum(),
            this.IsContrastAtMinimum(),
            Prefix
        )
    }
}
