Output pkgs/artisanal/assets/uv_tui_demo.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/artisanal/uv_tui_demo.dill"
Enter
Wait+Screen /ARTISANAL NEXUS/
Sleep 3s
Type "q"
Sleep 1s
