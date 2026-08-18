Output pkgs/artisanal/assets/widget_catalog_search.gif

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

Type "dart run build/vhs/artisanal/widget_catalog.dill --preset ocean --ansi"
Enter
Wait+Screen /Search All widgets/
Sleep 2s
Type "progress"
Sleep 700ms
Enter
Wait+Screen /ProgressModel/
Sleep 1s
Wait+Screen /Filter by category/
Type "j"
Type "j"
Type "j"
Type "j"
Type "j"
Type "j"
Type "j"
Type "j"
Enter
Wait+Screen /Search Display widgets/
Type "PanelComponent"
Sleep 700ms
Enter
Wait+Screen /PanelComponent/
Sleep 1s
Wait+Screen /Filter by category/
Escape
Sleep 1s
