Output pkgs/artisanal/example/tui/examples/components-host/components-host.gif

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

Type "dart run build/vhs/tui/components-host.dill"
Enter
Wait+Screen /ViewComponent Host Demo/
Sleep 3s
Type "q"
Sleep 1s
