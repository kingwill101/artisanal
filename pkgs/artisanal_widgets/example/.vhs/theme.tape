Output pkgs/artisanal_widgets/assets/theme.gif

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

Type "dart run build/vhs/widgets/theme.dill"
Enter
Wait+Screen /Theme & MediaQuery Showcase/
Sleep 3s
Type "q"
Sleep 1s
