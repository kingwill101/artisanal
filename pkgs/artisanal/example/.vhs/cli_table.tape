Output pkgs/artisanal/assets/cli_table.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1000
Set Height 480
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/artisanal/main.dill ui:table --ansi"
Enter
Wait+Screen /create_users_table/
Sleep 2s
