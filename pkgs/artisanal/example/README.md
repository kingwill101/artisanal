# `artisanal` Example

A comprehensive demo CLI showcasing all artisanal features.

## Running the Example

From the workspace root:

```bash
dart run packages/artisanal/example/main.dart --help
```

Or from the example directory:

```bash
cd packages/artisanal/example
dart run main.dart --help
```

## Quick Start

Run all demos at once:

```bash
dart run main.dart ui:all --ansi
```

## Available Commands

### Basic Output

```bash
# Full demo of basic output helpers
dart run main.dart demo --ansi

# Table rendering
dart run main.dart ui:table --ansi

# Horizontal table (row-as-headers)
dart run main.dart ui:htable --ansi
```

### Tasks & Progress

```bash
# Task with success/fail/skip status
dart run main.dart ui:task --ansi
dart run main.dart ui:task --fail --ansi
dart run main.dart ui:task --skip --ansi

# Progress bar
dart run main.dart ui:progress --count 40 --ansi

# Animated spinner
dart run main.dart ui:spinner --ansi
dart run main.dart ui:spinner -f line --ansi
dart run main.dart ui:spinner -f circle --ansi

# Spin component (processing indicator)
dart run main.dart ui:spin --ansi
```

### Prompts & Input

```bash
# Basic prompts (confirm/ask/choice)
dart run main.dart ui:prompts --ansi

# Secret/password input (no echo)
dart run main.dart ui:secret --ansi

# Password with confirmation
dart run main.dart ui:password --ansi
dart run main.dart ui:password --confirm --ansi

# Interactive single-select
dart run main.dart ui:select --ansi

# Interactive multi-select
dart run main.dart ui:multiselect --ansi

# Searchable selection
dart run main.dart ui:search --ansi

# Pause and countdown
dart run main.dart ui:pause --ansi
dart run main.dart ui:pause --countdown --ansi

# Non-interactive mode with defaults
dart run main.dart ui:prompts --defaults --no-interaction
```

### Autocomplete & Wizard

```bash
# Autocomplete input with suggestions
dart run main.dart ui:anticipate --ansi

# Multi-line text input (opens $EDITOR)
dart run main.dart ui:textarea --ansi

# Multi-step wizard flow
dart run main.dart ui:wizard --ansi

# Wizard in non-interactive mode
dart run main.dart ui:wizard -n --ansi

# Clickable terminal hyperlinks
dart run main.dart ui:link --ansi
```

### Validation

```bash
# Input validators (powered by Acanthis)
dart run main.dart ui:validators --ansi

# Non-interactive mode
dart run main.dart ui:validators --ansi -n
```

### UI Components

```bash
# Laravel-style components facade
dart run main.dart ui:components --ansi

# Boxed panels
dart run main.dart ui:panel --ansi
dart run main.dart ui:panel --style double --ansi
dart run main.dart ui:panel --style heavy --ansi
dart run main.dart ui:panel --style ascii --ansi

# Tree structure
dart run main.dart ui:tree --ansi

# Multi-column layout
dart run main.dart ui:columns --ansi
dart run main.dart ui:columns --cols 2 --ansi

# Styled blocks (Symfony-style)
dart run main.dart ui:block --ansi
dart run main.dart ui:block --large --ansi

# Exception rendering
dart run main.dart ui:exception --ansi
```

### Styling

```bash
# Advanced chalk colors
dart run main.dart ui:chalk --ansi
```

### Utilities

```bash
# Terminal information and utilities
dart run main.dart ui:terminal --ansi
```

## Global Options

All commands support these global options:

| Option | Description |
|--------|-------------|
| `--ansi` | Force ANSI color output |
| `--no-ansi` | Disable ANSI colors |
| `-q, --quiet` | Suppress all output |
| `-n, --no-interaction` | Disable interactive prompts |
| `-v, --verbose` | Increase verbosity |

## Features Demonstrated

### Output
- ✅ Title, section, text, newLine
- ✅ Info, success, warning, error, note, caution messages
- ✅ Listing / bullet lists
- ✅ Tables (standard and horizontal)
- ✅ Definition lists
- ✅ Two-column detail
- ✅ Panels with box drawing
- ✅ Tree structures
- ✅ Multi-column layouts
- ✅ Styled blocks
- ✅ Comments
- ✅ Rules and separators
- ✅ Exception rendering

### Progress & Async
- ✅ Progress bars
- ✅ Animated spinners (6 styles)
- ✅ Task status indicators
- ✅ Spin component with timing

### Interactive
- ✅ Confirm prompts
- ✅ Ask prompts with validation
- ✅ Choice selection (numbered)
- ✅ Arrow-key selection (single)
- ✅ Arrow-key selection (multi)
- ✅ Search/filter selection
- ✅ Autocomplete/anticipate input
- ✅ Secret input (no echo)
- ✅ Password with confirmation
- ✅ Pause (press any key)
- ✅ Countdown timer
- ✅ Multi-line editor input (textarea)
- ✅ Multi-step wizard flow
- ✅ Conditional wizard steps

### Validation (Acanthis)
- ✅ Required, email, URL, URI
- ✅ UUID, JWT, base64, hex color
- ✅ Numeric, integer, range
- ✅ Pattern/regex matching
- ✅ String length constraints
- ✅ Character type validation
- ✅ Network validation (IP, port)
- ✅ Custom validators via Acanthis schemas

### Styling
- ✅ Basic ANSI colors
- ✅ Bright colors
- ✅ Text styles (bold, italic, underline, etc.)
- ✅ True color (RGB)
- ✅ Hex colors
- ✅ Semantic colors

### Terminal Utilities
- ✅ Terminal size detection
- ✅ Cursor control
- ✅ Screen control
- ✅ Raw mode input
- ✅ Key code handling
- ✅ Clickable hyperlinks (OSC 8)
- ✅ Link groups for footnotes

