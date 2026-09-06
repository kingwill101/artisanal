Output pkgs/artisanal_widgets/assets/buttons.gif

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

Type "dart run build/vhs/widgets/buttons.dill"
Enter
Wait+Screen /Buttons/
Sleep 2s
Tab
Sleep 800ms
Tab
Sleep 800ms
Tab
Sleep 800ms
Type "q"
Sleep 1s
