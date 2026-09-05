Output pkgs/artisanal/example/tui/examples/prevent-quit/prevent-quit.gif

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

Type "dart run build/vhs/tui/prevent-quit.dill"
Enter
Wait+Screen /Only the best words/
Sleep 3s
Type "q"
Sleep 1s
