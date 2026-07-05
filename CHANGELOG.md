# Changelog

All notable changes to BeyondDimmer are documented in this file.

## [1.0.0] - 2026-07-05

### Added

- Initial release of BeyondDimmer.
- Brightness control for external monitors via DDC/CI.
- Beyond range control: after Brightness reaches the lower limit, Contrast is lowered to make the display darker than the monitor's minimum Brightness setting.
- Left-hand device mode.
- Keyboard mode.
- Configurable hotkeys through `BeyondDim.ini`.
- Real-time ToolTip status display.
- MAX and LIMIT indicators in the ToolTip.
- Reset operation to restore the configured default Brightness and Contrast values.
- Multi-monitor support.
- Sleep resume and reconnect handling.
- README assets, demo GIFs, and application icon assets.

### Verified

- ToolTip display can be disabled with `[Status] ShowStatus=0`.
- MAX is displayed when Brightness reaches the maximum value.
- LIMIT is displayed when Contrast reaches the lower control limit.
- Known limitation for built-in display environments is documented in `docs/test.md`.

### Notes

- BeyondDimmer is intended for external monitors that support DDC/CI Brightness and Contrast control.
- Built-in display environments, such as notebook PCs or iMac Boot Camp environments, may not support DDC/CI control correctly.
