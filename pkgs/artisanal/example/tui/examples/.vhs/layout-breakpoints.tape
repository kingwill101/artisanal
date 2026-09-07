Output pkgs/artisanal/example/tui/examples/layout-breakpoints/layout-breakpoints.gif

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

Type "dart run build/vhs/tui/layout-breakpoints.dill"
Enter
Wait+Screen /Active Breakpoints/
Sleep 3s
Type "q"
Sleep 1s
