Output pkgs/artisanal/assets/cli_progress.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1000
Set Height 420
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/artisanal/main.dill ui:progress --count 40 --ansi"
Enter
Wait+Screen /100%/
Sleep 2s
