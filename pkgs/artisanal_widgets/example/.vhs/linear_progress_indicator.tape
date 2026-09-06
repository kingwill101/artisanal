Output pkgs/artisanal_widgets/assets/linear_progress_indicator.gif

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

Type "dart run build/vhs/widgets/linear_progress_indicator.dill"
Enter
Wait+Screen /LinearProgressIndicator/
Sleep 3s
Type "q"
Sleep 1s
