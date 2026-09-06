Output pkgs/artisanal_widgets/assets/text-field.gif

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

Type "dart run build/vhs/widgets/text-field.dill"
Enter
Wait+Screen /TextField Demo/
Sleep 2s
Type "Ada"
Sleep 1s
Tab
Sleep 800ms
Type "q"
Sleep 1s
