# PhotoBoothQt

Qt 6 rewrite of the existing macOS-only PhotoBooth app.

## Build

```bash
cmake -S . -B build -G Ninja
cmake --build build
```

## Notes

- Requires a Qt 6 toolchain with `Core`, `Gui`, `Qml`, `Quick`, `QuickControls2`, `QuickDialogs2`, `Multimedia`, and `Test`.
- The original Swift/Xcode app remains untouched in the repo root.
