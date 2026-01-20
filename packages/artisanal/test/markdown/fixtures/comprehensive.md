# Artisanal Markdown Renderer Test Document

This document tests **all** markdown features supported by the ANSI renderer.

## Inline Formatting

### Basic Text Styles

This paragraph contains **bold text**, *italic text*, and ***bold italic text***.

You can also use __underscores for bold__ and _underscores for italic_.

Here's some `inline code` in a sentence, and here's more `complex::code_with_symbols()`.

This text has ~~strikethrough~~ applied to it.

### Combining Styles

- **Bold with `code` inside**
- *Italic with `code` inside*
- ~~Strikethrough with **bold** inside~~
- ***Bold italic with `code` inside***

## Links and References

### Basic Links

Visit [Dart's official website](https://dart.dev) for more information.

Here's a link to [GitHub](https://github.com) and another to [Google](https://google.com).

### Links with Special Characters

Check out [this project's issues](https://github.com/user/repo/issues?q=is%3Aissue+is%3Aopen).

## Images

### Basic Images

![Dart Logo](https://dart.dev/assets/shared/dart-logo-for-shares.png)

![Alternative text for accessibility](https://example.com/image.jpg)

### Images in Context

Here's an inline image reference: ![icon](icon.svg) in the middle of text.

## Lists

### Unordered Lists

- First item
- Second item
- Third item with **bold** and *italic*
- Fourth item with `code`

### Nested Unordered Lists

- Level 1 item A
  - Level 2 item A.1
  - Level 2 item A.2
    - Level 3 item A.2.1
    - Level 3 item A.2.2
      - Level 4 item A.2.2.1
  - Level 2 item A.3
- Level 1 item B
  - Level 2 item B.1

### Ordered Lists

1. First ordered item
2. Second ordered item
3. Third ordered item
4. Fourth ordered item
5. Fifth ordered item

### Nested Ordered Lists

1. First item
   1. Sub-item 1.1
   2. Sub-item 1.2
      1. Sub-sub-item 1.2.1
      2. Sub-sub-item 1.2.2
2. Second item
   1. Sub-item 2.1

### Mixed Lists

1. Ordered item one
   - Unordered sub-item
   - Another unordered sub-item
2. Ordered item two
   1. Ordered sub-item
   2. Another ordered sub-item
      - Deep unordered item
      - Another deep unordered item

### Task Lists

- [x] Completed task
- [x] Another completed task
- [ ] Incomplete task
- [ ] Another incomplete task
- [x] Task with **bold** text
- [ ] Task with `code` in it

## Blockquotes

### Simple Blockquote

> This is a simple blockquote.
> It can span multiple lines.

### Blockquote with Formatting

> This blockquote contains **bold**, *italic*, and `code`.
>
> It also has multiple paragraphs.

### Nested Blockquotes

> Level 1 quote
>
> > Level 2 quote
> >
> > > Level 3 quote
> > >
> > > This is deeply nested.
> >
> > Back to level 2.
>
> Back to level 1.

### Blockquote with List

> Here's a list inside a blockquote:
>
> - Item one
> - Item two
> - Item three

## Code

### Inline Code

Use `print()` to output text. Call `myFunction(arg1, arg2)` with arguments.

Special characters in code: `<div class="container">`, `SELECT * FROM users`, `$variable`.

### Code Blocks

```
Plain code block without language specification.
It preserves    spacing    and
line breaks.
```

### Code Blocks with Language

```dart
void main() {
  final greeting = 'Hello, World!';
  print(greeting);
  
  for (var i = 0; i < 5; i++) {
    print('Count: $i');
  }
}
```

```javascript
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

console.log(fibonacci(10));
```

```python
def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)

print(quicksort([3, 6, 8, 10, 1, 2, 1]))
```

```sql
SELECT 
    users.name,
    orders.total,
    orders.created_at
FROM users
JOIN orders ON users.id = orders.user_id
WHERE orders.total > 100
ORDER BY orders.created_at DESC;
```

```bash
#!/bin/bash
echo "Installing dependencies..."
npm install
echo "Running tests..."
npm test
echo "Building project..."
npm run build
```

```json
{
  "name": "artisanal",
  "version": "1.0.0",
  "dependencies": {
    "markdown": "^7.0.0"
  },
  "scripts": {
    "test": "dart test",
    "analyze": "dart analyze"
  }
}
```

```yaml
name: CI Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test
```

## Headings

# Heading Level 1

## Heading Level 2

### Heading Level 3

#### Heading Level 4

##### Heading Level 5

###### Heading Level 6

### Headings with Formatting

## Heading with **Bold** Text

### Heading with *Italic* Text

#### Heading with `Code` in It

## Horizontal Rules

Above the rule.

---

Between rules.

***

Below the rules.

___

After all rules.

## Tables

### Simple Table

| Name | Age | City |
|------|-----|------|
| Alice | 30 | New York |
| Bob | 25 | Los Angeles |
| Charlie | 35 | Chicago |

### Table with Alignment

| Left Aligned | Center Aligned | Right Aligned |
|:-------------|:--------------:|--------------:|
| Left | Center | Right |
| Data | Data | Data |
| More | More | More |

### Table with Formatting

| Feature | Status | Notes |
|---------|--------|-------|
| **Bold** support | ✓ | Works great |
| *Italic* support | ✓ | Also works |
| `Code` support | ✓ | In tables too |
| ~~Strike~~ | ✓ | Even this |

### Complex Table

| Language | Typing | Paradigm | First Appeared | Notable Feature |
|----------|--------|----------|----------------|-----------------|
| Dart | Static | OOP, Functional | 2011 | Sound null safety |
| Rust | Static | Systems, Functional | 2010 | Memory safety without GC |
| Go | Static | Procedural, Concurrent | 2009 | Goroutines |
| Python | Dynamic | Multi-paradigm | 1991 | Readability |
| JavaScript | Dynamic | Multi-paradigm | 1995 | Ubiquity |

### Table with Long Content

| Category | Description |
|----------|-------------|
| Performance | The system delivers excellent performance across all benchmarks, consistently outperforming competitors in both synthetic and real-world tests. |
| Reliability | With 99.99% uptime guaranteed, our infrastructure ensures your applications are always available to your users. |
| Scalability | Easily scale from handling hundreds to millions of requests per second with our auto-scaling capabilities. |

## Special Characters and Escaping

### HTML Entities

- Less than: &lt;
- Greater than: &gt;
- Ampersand: &amp;
- Quote: &quot;

### Escaped Characters

\*This is not italic\*

\*\*This is not bold\*\*

\`This is not code\`

\[This is not a link\](https://example.com)

## Complex Nested Structures

### Blockquote with Code Block

> Here's some code in a blockquote:
>
> ```dart
> void main() {
>   print('Hello from blockquote!');
> }
> ```
>
> Pretty neat, right?

### List with Code Blocks

1. First, define your function:
   ```dart
   int add(int a, int b) => a + b;
   ```
2. Then call it:
   ```dart
   final result = add(2, 3);
   print(result); // 5
   ```
3. That's it!

### Nested Lists with Formatting

- **Bold parent item**
  - *Italic child item*
    - `Code grandchild item`
    - Normal grandchild item
  - Another child with [a link](https://example.com)
- Another parent item
  1. Ordered in unordered
  2. Another ordered
     - Back to unordered
       - Deeply nested

## Edge Cases

### Empty Elements

Empty bold: ****

Empty italic: **

Empty code: ``

### Adjacent Formatting

**Bold***Italic***BoldItalic***

### Line Breaks

First line  
Second line (with two trailing spaces)

Third line after blank line.

### Very Long Lines

This is an extremely long line that goes on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on and on without any breaks to test how the renderer handles very long content that exceeds typical terminal widths.

### Unicode Characters

- Emoji: 🚀 🎉 ✨ 🔥 💯
- Math: ∑ ∏ ∫ √ ∞ ≠ ≤ ≥
- Arrows: → ← ↑ ↓ ↔ ⇒ ⇐
- Boxes: ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
- Greek: α β γ δ ε ζ η θ
- Currency: $ € £ ¥ ₹ ₿

### Consecutive Headings

# H1

## H2

### H3

#### H4

##### H5

###### H6

---

## Conclusion

This document covers **all** the major markdown features:

1. ✅ Inline formatting (bold, italic, code, strikethrough)
2. ✅ Links and images
3. ✅ Lists (ordered, unordered, nested, task lists)
4. ✅ Blockquotes (including nested)
5. ✅ Code blocks (with language hints)
6. ✅ Headings (all 6 levels)
7. ✅ Horizontal rules
8. ✅ Tables (with alignment)
9. ✅ Special characters and escaping
10. ✅ Complex nested structures

*Thank you for testing the Artisanal Markdown Renderer!*
