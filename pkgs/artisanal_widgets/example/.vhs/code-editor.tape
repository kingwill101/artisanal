Output pkgs/artisanal_widgets/assets/code-editor.gif

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

Type "dart run build/vhs/widgets/code-editor.dill"
Enter
Wait+Screen /Editor/
Sleep 2s
Type "final count = 42;"
Sleep 1s
Type "ctrl+s"
Sleep 800ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "esc"
Sleep 600ms
Type "ctrl+c"
Sleep 1s
