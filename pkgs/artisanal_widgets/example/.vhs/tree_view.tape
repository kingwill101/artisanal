Output pkgs/artisanal_widgets/assets/tree_view.gif

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

Type "dart run build/vhs/widgets/tree_view.dill"
Enter
Wait+Screen /TreeView Showcase/
Sleep 2s
Down
Sleep 500ms
Down
Sleep 500ms
Up
Sleep 500ms
Type "q"
Sleep 1s
