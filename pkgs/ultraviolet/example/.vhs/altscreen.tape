Output pkgs/ultraviolet/assets/altscreen.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1000
Set Height 520
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/uv/altscreen.dill"
Enter
Wait+Screen /This is using inline mode./
Sleep 1s
Type " "
Sleep 2s
Type "q"
Sleep 1s
