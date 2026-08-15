Output pkgs/artisanal_widgets/assets/opencode.gif

Require dart

Set Shell "bash"
Set FontFamily "DejaVu Sans Mono"
Set FontSize 16
Set LetterSpacing 0
Set Width 1600
Set Height 990
Set Theme "Catppuccin Mocha"
Set TypingSpeed 35ms
Set PlaybackSpeed 1.25
Set CursorBlink false

Type "dart run build/vhs/widgets/opencode.dill --replay-scenario baseline_scroll --replay-block-input --replay-speed 0.4 --replay-keep-open"
Enter
Wait+Screen /opencode/
Sleep 12s
Type "ctrl+c"
Sleep 1s
