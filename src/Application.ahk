class Application
{
    PowerBroadcastMessage := 0x218
    SessionChangeMessage := 0x02B1

    PowerSuspend := 0x0004
    PowerResumeSuspend := 0x0007
    PowerResumeAutomatic := 0x0012

    SessionLock := 0x7
    SessionUnlock := 0x8

    ResumeDelay := 1500
    ReconnectDelay := 3000

    HotkeysEnabled := false
    ResumeScheduled := false
    IsShuttingDown := false

    __New()
    {
        this.Config := Config()
        this.Controller := BrightnessController(this.Config)

        this.RegisterHotkeys()
        this.RegisterPowerEvents()
        this.RegisterSessionEvents()

        OnExit ObjBindMethod(this, "Shutdown")

        if !this.IsMonitorReady()
            this.ScheduleResume(this.ReconnectDelay)
    }

    RegisterHotkeys()
    {
        this.RegisterHotkey(this.Config.HotkeyIncrease, "IncreaseBrightness")
        this.RegisterHotkey(this.Config.HotkeyDecrease, "DecreaseBrightness")
        this.RegisterHotkey(this.Config.HotkeyReset, "Reset")

        this.HotkeysEnabled := true
    }

    RegisterHotkey(KeyName, MethodName)
    {
        local NormalizedKeyName := this.NormalizeHotkey(KeyName)

        Hotkey(
            NormalizedKeyName,
            ObjBindMethod(this.Controller, MethodName),
            "On"
        )
    }

    NormalizeHotkey(KeyName)
    {
        ; Capture the hotkey regardless of Shift/Ctrl/Alt state.
        if (SubStr(KeyName, 1, 1) != "*")
            return "*" KeyName

        return KeyName
    }

    EnableHotkeys()
    {
        if this.HotkeysEnabled
            return

        Hotkey(this.NormalizeHotkey(this.Config.HotkeyIncrease), "On")
        Hotkey(this.NormalizeHotkey(this.Config.HotkeyDecrease), "On")
        Hotkey(this.NormalizeHotkey(this.Config.HotkeyReset), "On")

        this.HotkeysEnabled := true
    }

    DisableHotkeys()
    {
        if !this.HotkeysEnabled
            return

        Hotkey(this.NormalizeHotkey(this.Config.HotkeyIncrease), "Off")
        Hotkey(this.NormalizeHotkey(this.Config.HotkeyDecrease), "Off")
        Hotkey(this.NormalizeHotkey(this.Config.HotkeyReset), "Off")

        this.HotkeysEnabled := false
    }

    RegisterPowerEvents()
    {
        OnMessage(
            this.PowerBroadcastMessage,
            ObjBindMethod(this, "OnPowerBroadcast")
        )
    }

    RegisterSessionEvents()
    {
        OnMessage(
            this.SessionChangeMessage,
            ObjBindMethod(this, "OnSessionChange")
        )

        ; NOTIFY_FOR_THIS_SESSION = 0
        DllCall(
            "Wtsapi32.dll\WTSRegisterSessionNotification"
            , "Ptr", A_ScriptHwnd
            , "UInt", 0
        )
    }

    OnSessionChange(wParam, lParam, msg, hwnd)
    {
        if (wParam = this.SessionLock)
            return

        if (wParam = this.SessionUnlock)
        {
            this.ScheduleResume()
            return
        }
    }

    OnPowerBroadcast(wParam, lParam, msg, hwnd)
    {
        if (wParam = this.PowerSuspend)
        {
            this.Controller.Close()
            return true
        }

        if (wParam = this.PowerResumeAutomatic || wParam = this.PowerResumeSuspend)
        {
            this.ScheduleResume()
            return true
        }

        return false
    }

    ScheduleResume(Delay := "")
    {
        if this.IsShuttingDown
            return

        if this.ResumeScheduled
            return

        if (Delay = "")
            Delay := this.ResumeDelay

        this.ResumeScheduled := true

        SetTimer ObjBindMethod(this, "ResumeAfterSleep"), -Delay
    }

    ResumeAfterSleep()
    {
        this.ResumeScheduled := false

        if this.IsShuttingDown
            return

        try
        {
            this.Controller.Reopen()

            if this.IsMonitorReady()
                return

            this.ScheduleResume(this.ReconnectDelay)
        }
        catch as Err
        {
            this.ScheduleResume(this.ReconnectDelay)
        }
    }

    IsMonitorReady()
    {
        try
        {
            return this.Controller.Monitor.IsReady()
        }

        return false
    }

    Shutdown(*)
    {
        this.IsShuttingDown := true

        try
        {
            this.DisableHotkeys()
            this.Controller.Close()
        }

        try
        {
            DllCall(
                "Wtsapi32.dll\WTSUnRegisterSessionNotification"
                , "Ptr", A_ScriptHwnd
            )
        }
    }
}
