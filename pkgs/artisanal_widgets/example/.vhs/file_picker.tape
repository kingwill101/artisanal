Output pkgs/artisanal_widgets/assets/file_picker.gif

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

Type "dart run build/vhs/widgets/file_picker.dill"
Enter
Wait+Screen /Browse project files/
Sleep 2s
Down
Sleep 600ms
Down
Sleep 600ms
Escape
Sleep 1s
