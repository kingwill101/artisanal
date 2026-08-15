Output pkgs/artisanal_widgets/assets/command_palette.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1200
Set Height 720
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/widgets/command_palette.dill"
Enter
Wait+Screen /Command Palette/
Sleep 2s
Type "p"
Sleep 1s
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Enter
Sleep 1.5s
Type "p"
Sleep 1s
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Enter
Sleep 1.5s
Type "q"
Sleep 1s
