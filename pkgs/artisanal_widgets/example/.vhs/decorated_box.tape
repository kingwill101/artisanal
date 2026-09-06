Output pkgs/artisanal_widgets/assets/decorated_box.gif

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

Type "dart run build/vhs/widgets/decorated_box.dill"
Enter
Wait+Screen /DecoratedBox Widget/
Sleep 3s
Type "q"
Sleep 1s
