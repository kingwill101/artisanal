Output pkgs/ultraviolet/assets/path_tracer.gif

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

Type "dart run build/vhs/uv/path_tracer.dill"
Enter
Wait+Screen /UV Path Tracer/
Sleep 4s
Type "q"
Sleep 1s
