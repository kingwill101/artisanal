Output pkgs/artisanal/assets/widget_catalog_showcase.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1200
Set Height 900
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/artisanal/widget_catalog.dill --showcase --preset ocean --ansi"
Enter
Wait+Screen /Artisanal ComponentTheme — ocean/
Sleep 3s
