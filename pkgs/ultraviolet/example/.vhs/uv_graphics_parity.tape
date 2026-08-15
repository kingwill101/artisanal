Output pkgs/ultraviolet/assets/uv_graphics_parity.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1100
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/uv/uv_graphics_parity.dill"
Enter
Wait+Screen /Kitty Graphics Protocol/
Sleep 2s
Type "x"
Sleep 1s
