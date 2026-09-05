Output pkgs/artisanal_widgets/assets/text-area.gif

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

Type "dart run build/vhs/widgets/text-area.dill"
Enter
Wait+Screen /TextArea Demo/
Sleep 2s
Type "Hello"
Sleep 1s
Escape
Sleep 500ms
Type "q"
Sleep 1s
