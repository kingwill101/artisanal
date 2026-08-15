Output pkgs/ultraviolet/assets/draw.gif

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

Type "dart run build/vhs/uv/draw.dill"
Enter
Wait+Screen /Welcome to Draw Example!/
Sleep 1s
Type "x"
Sleep 2s
Type "q"
Sleep 1s
