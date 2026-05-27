#!/usr/bin/env bash
# Walk through every feature of the markdown parser with real examples.
# Run this in a terminal to see what each one does.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/board.bash"
source "$SCRIPT_DIR/md_parser.bash"

set_title "md_parser.bash demo"

header "md_parser.bash demo"
center "Rendering all supported markdown elements"
echo

# ------------------------------------------------------------------
title "Source: rendering inline"
echo

info "Render a single string inline:"
echo

rendered="$(_md::inline "This has **bold**, *italic*, \`code\`, and a [link](https://example.com).")"
echo "  $rendered"
echo

rendered="$(_md::inline "~~strikethrough~~ and an image ![icon](icon.png) too.")"
echo "  $rendered"
echo

# ------------------------------------------------------------------
title "Source: rendering a full document"
echo

info "A markdown document with every supported element:"
echo

cat <<'MARKDOWN' | md::render
# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6

This is a paragraph with **bold**, *italic*, ~~strikethrough~~, and `inline code`.

Here is a [link to board.bash](https://github.com) and an image ![logo](logo.png).

---

> Blockquotes make text stand out. They can have **bold** and *italic* too.

---

### Lists

Unordered:

- First item
- Second item
- Third item

Ordered:

1. Step one
2. Step two
3. Step three

Task lists:

- [x] Completed task
- [ ] Pending task
- [ ] Another todo

---

### Code blocks

```
#!/bin/bash
echo "Hello, world!"
```

Inline `code` spans work inside paragraphs and headings too.

---

### All headers together

# H1
## H2
### H3
#### H4
##### H5
###### H6

---

### Inline combinations

**Bold with *italic* inside** and *italic with **bold** inside*.

`code with **bold**` and `code with *italic*`.

A [link containing **bold**](https://example.com) and [link with `code`](https://example.com).

That's everything the parser supports.
MARKDOWN

echo

# ------------------------------------------------------------------
title "Source: rendering a file"
echo

info "You can also render a markdown file:"
echo
code "  md::render_file README.md"
echo

info "The parser reads from stdin, so piping works too:"
echo
code "  cat CHANGELOG.md | md::render"
echo

# ------------------------------------------------------------------
hr
center "See README_MD_PARSER.md for the full reference"
echo

ok "Demo complete"
