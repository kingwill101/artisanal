Output pkgs/ultraviolet/assets/pong.gif

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

Type "dart run build/vhs/uv/pong.dill"
Enter
Wait+Screen /PONG/
Sleep 4s
Type "q"
Sleep 1s
