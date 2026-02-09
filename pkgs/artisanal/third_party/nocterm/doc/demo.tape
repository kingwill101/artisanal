# VHS tape for nocterm demo
# Run: vhs doc/demo.tape

Output doc/assets/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"
Set Padding 20
Set Framerate 30

# Enable true color support
Env COLORTERM "truecolor"
Env TERM "xterm-256color"

# Hide the typing - just show the demo
Hide
Type "dart run example/readme_bento_full.dart"
Enter
Sleep 3s
Show

# Let the animations play - ~7s for one full sin cycle (2π / 0.04 * 0.045s)
Sleep 7.07s

# Quit
Hide
Type "q"
Sleep 500ms
