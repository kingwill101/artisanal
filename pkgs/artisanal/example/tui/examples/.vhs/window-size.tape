Output pkgs/artisanal/example/tui/examples/window-size/window-size.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1000
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/tui/window-size.dill"
Enter
Wait+Screen /Press any key to query window size/
Sleep 1s
Type "a"
Sleep 1s
Type "q"
Sleep 1s
