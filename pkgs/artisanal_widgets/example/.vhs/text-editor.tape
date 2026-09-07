Output pkgs/artisanal_widgets/assets/text-editor.gif

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

Type "dart run build/vhs/widgets/text-editor.dill"
Enter
Wait+Screen /TextEditor Demo/
Sleep 3s
Escape
Sleep 500ms
Type "ctrl+c"
Sleep 1s
