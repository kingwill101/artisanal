Output pkgs/artisanal_widgets/assets/markdown-editor.gif

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

Type "dart run build/vhs/widgets/markdown-editor.dill"
Enter
Wait+Screen /Markdown/
Sleep 2s
Type "# Demo"
Sleep 600ms
Type "Some **bold** text"
Sleep 600ms
Type "ctrl+s"
Sleep 800ms
Type "esc"
Sleep 600ms
Type "ctrl+c"
Sleep 1s
