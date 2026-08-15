Output pkgs/ultraviolet/assets/raycast_maze.gif

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

Type "dart run build/vhs/uv/raycast_maze.dill"
Enter
Wait+Screen /RAYCAST MAZE/
Sleep 2s
Type "d"
Sleep 1s
Type "w"
Sleep 1s
Type "q"
Sleep 1s
