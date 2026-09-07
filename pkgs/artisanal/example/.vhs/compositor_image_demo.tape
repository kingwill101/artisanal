Output pkgs/artisanal/assets/compositor_image_demo.gif

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

Type "dart run build/vhs/artisanal/compositor_image_demo.dill"
Enter
Wait+Screen /Detected capabilities/
Sleep 3s
