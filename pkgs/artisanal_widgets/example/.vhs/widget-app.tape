Output pkgs/artisanal_widgets/assets/widget-app.gif

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

Type "dart run build/vhs/widgets/artisanal_app.dill"
Enter
Wait+Screen /ArtisanalApp Shell/
Sleep 2s
Enter
Wait+Screen /Details/
Sleep 2s
Escape
Sleep 1s
Enter
Wait+Screen /Details/
Sleep 1.5s
Escape
Sleep 1s
Type "q"
Sleep 1s
