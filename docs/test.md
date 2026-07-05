# BeyondDimmer test.md

Developer test record for the BeyondDimmer Version 1.0 pre-release review.

---

## TEST-001

Test: Application startup

Steps

1. Start BeyondDimmer.

Expected result

- No Windows warning appears.
- The application does not exit with an error.
- The application stays resident in the task tray.

Result

- OK

---

## TEST-002

Test: Brightness changes

Steps

1. Start BeyondDimmer.
2. Press F16 or F17.
3. Check the Brightness value in the ToolTip and the actual screen brightness.

Expected result

- The Brightness value changes.
- The screen brightness actually changes.
- The Windows standard OSD does not take over the control.

Result

- OK

---

## TEST-003

Test: Contrast changes

Steps

1. Decrease Brightness to 0.
2. Press F17 again.
3. Check the Contrast value in the ToolTip and the actual screen darkness.

Expected result

- After Brightness reaches 0, the Contrast value decreases.
- The screen becomes darker.
- LIMIT is displayed at the lower Contrast limit.

Result

- OK

---

## TEST-004

Test: Reset works

Steps

1. Change Brightness or Contrast.
2. Press F18.

Expected result

- Brightness returns to the default value.
- Contrast returns to the default value.
- The Reset indication is displayed.

Result

- OK

---

## TEST-005

Test: Monitor reconnect

Steps

1. Start BeyondDimmer.
2. Turn off the monitor, or unplug the monitor power cable.
3. Turn on the monitor, or plug the power cable back in.
4. After the screen returns, press F16 or F17.

Expected result

- BeyondDimmer does not exit with an error.
- Brightness can be changed after the monitor returns.
- The ToolTip value does not change without the actual screen changing.

Result

- OK

---

## TEST-006

Test: Multi-monitor operation

Steps

1. Start BeyondDimmer in a multi-monitor environment.
2. Press F16, F17, and F18.
3. Check the target monitor brightness and the ToolTip display.

Expected result

- BeyondDimmer starts in a multi-monitor environment.
- F16, F17, and F18 work correctly.
- The ToolTip is displayed.

Result

- OK

---

## TEST-007

Test: ToolTip position

Steps

1. Start BeyondDimmer.
2. Press F16 or F17 over several applications, such as the desktop, File Explorer, an editor, and Paint.
3. Check the ToolTip position.

Expected result

- The ToolTip appears near the mouse cursor.
- The ToolTip does not jump to the right edge or bottom-right corner of the screen.
- The ToolTip does not fail to appear depending on the active application.

Result

- OK

---

## TEST-008

Test: ToolTip width stability

Steps

1. Start BeyondDimmer.
2. Press F16 or F17 repeatedly.
3. Check the ToolTip width.

Expected result

- The ToolTip width does not expand or shrink when the Brightness or Contrast value changes.
- The width does not change unnaturally when MAX or LIMIT is displayed.

Result

- OK

---

## TEST-009

Test: ToolTip bar display

Steps

1. Start BeyondDimmer.
2. Press F16 or F17 to change Brightness and Contrast.
3. Check the bar display inside the ToolTip.

Expected result

- The Brightness bar changes according to the current value.
- The Contrast bar changes according to the actual usable range.
- The bar characters are displayed naturally.

Result

- OK

---

## TEST-010

Test: Invalid Config value handling

Steps

1. Open BeyondDim.ini.
2. Change the Brightness or Contrast Step value to an invalid value.
   Example: Step=abc
3. Start BeyondDimmer.
4. Check BeyondDim.ini again.

Expected result

- Startup does not fail.
- The invalid value is corrected to the default value.
- F16, F17, and F18 work normally.

Result

- OK

---

## TEST-011

Test: Startup failure MsgBox

Steps

1. Temporarily modify the startup code in BeyondDim.ahk.
2. Throw an Error from TestStartupFailure().
3. Start BeyondDimmer.

Expected result

- A MsgBox saying "BeyondDimmer failed to start." is displayed.
- #Warn does not occur.
- The application does not stay resident unintentionally.

Result

- OK

Notes

This test requires a temporary code change for developer testing.
After the test is complete, always restore the original code.

Temporary code change

Replace the code after try in BeyondDim.ahk with the following:

```ahk
try
{
    TestStartupFailure()
    global App := Application()
}
catch as Err
{
    MsgBox "BeyondDimmer failed to start.`n`n" Err.Message
    ExitApp
}

TestStartupFailure()
{
    throw Error("Test startup failure.")
}
```

---

## TEST-012

Test: Response during fast operation

Steps

1. Start BeyondDimmer.
2. Rotate the left-hand device knob quickly.
3. Check the ToolTip display and the actual brightness change.

Expected result

- The application responds well enough to fast knob operation.
- One knob step matches one Brightness or Contrast step.
- The Windows standard OSD does not take over the control.

Result

- OK

---

## TEST-013

Test: Operation after waking from sleep

Steps

1. Put Windows to sleep while BeyondDimmer is running.
2. Wake Windows from sleep.
3. Press F16, F17, and F18.

Expected result

- BeyondDimmer remains in the task tray.
- F16, F17, and F18 work correctly.
- No stuck-key behavior occurs.

Result

- OK

---

## TEST-014

Test: Left-hand_Device / Keyboard setting

Steps

1. Check Input Mode in BeyondDim.ini.
2. In Left-hand_Device mode, check F16, F17, and F18.
3. Switch to Keyboard mode and check the standard keyboard shortcuts.

Expected result

- Left-hand_Device mode works.
- Keyboard mode works.
- Hotkeys switch according to the INI setting.

Result

- OK

---

## TEST-015

Test: ToolTip display after Hotkey setting changes

The Hotkey Reset setting in BeyondDim.ini is reflected in the ToolTip display.

Steps

1. Change [Hotkey] Reset in BeyondDim.ini to a key other than F18.
   Example: Reset=Home
2. Restart BeyondDimmer.
3. Press the Reset key.
4. Check the Reset display in the ToolTip.
5. Change [Input] Mode to Keyboard.
6. Change [Hotkey] Reset to a hotkey with modifier keys.
   Example: Reset=^!Home
7. Restart BeyondDimmer.
8. Press the Reset key.
9. Check the Reset display in the ToolTip.

Expected result

- Reset is executed.
- The ToolTip displays the changed key name.
- Example: when Reset=Home, the ToolTip displays "Home  Reset".
- Example: when Reset=^!Home, the ToolTip displays "Ctrl + Alt + Home  Reset".
- The fixed display "F18  Reset" does not remain.
- AutoHotkey shorthand such as ^!Home is not displayed as-is.

Result

- OK

---

## TEST-016

Test: ToolTip can be disabled

The ToolTip display can be disabled by setting `ShowStatus=0` in `BeyondDim.ini`.

Steps

1. Open `BeyondDim.ini`.
2. Set `[Status] ShowStatus=0`.
3. Start BeyondDimmer.
4. Press the Increase, Decrease, and Reset hotkeys.
5. Check the screen brightness and ToolTip display.
6. Restore `[Status] ShowStatus=1` after the test.

Expected result

- Brightness and Contrast still change normally.
- Reset still works normally.
- The ToolTip is not displayed while `ShowStatus=0`.
- After restoring `ShowStatus=1`, the ToolTip is displayed again.

Result

- OK

---

## TEST-017

Test: MAX and LIMIT indicators

The ToolTip displays `MAX` and `LIMIT` at the upper and lower control limits.

Steps

1. Start BeyondDimmer.
2. Press the Increase hotkey until Brightness reaches the maximum value.
3. Check the ToolTip display.
4. Press the Decrease hotkey until Brightness reaches 0.
5. Continue pressing the Decrease hotkey until Contrast reaches the lower control limit.
6. Check the ToolTip display.

Expected result

- `MAX` is displayed when Brightness reaches the maximum value.
- After Brightness reaches 0, Contrast decreases.
- `LIMIT` is displayed when Contrast reaches the lower control limit.
- The ToolTip bar display remains stable and readable.

Result

- OK

---

## Known limitation: built-in display environments

Built-in display environments, such as notebook PCs or iMac Boot Camp environments, may not support DDC/CI control correctly.

Observed behavior

- On an iMac Retina 5K 27-inch Late 2014 running Windows 11 through Boot Camp, BeyondDimmer did not control the built-in display correctly in Keyboard mode.
- Contrast appeared to start from 0.
- Increasing Contrast did not visibly change the actual display.
- After entering the Brightness range and reaching around 30 to 40, a reconnect message appeared and BeyondDimmer became unable to control the display.

Notes

- This is treated as a known limitation of built-in display environments.
- BeyondDimmer is intended for external monitors that support DDC/CI Brightness and Contrast control.
