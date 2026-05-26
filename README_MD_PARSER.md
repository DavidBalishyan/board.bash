# md\_parser.bash

Render Markdown in your terminal using [board.bash](README.md) for styling.

No dependencies beyond bash and board.bash. Drop it in, source it, done.

## Quick start

```bash
source /path/to/board.bash
source /path/to/md_parser.bash

md::render_file README.md
```

Or pipe markdown directly:

```bash
echo "# Hello **world**" | md::render
```

## Usage

### `md::render`

Reads markdown from stdin and prints styled output to stdout.

```bash
cat docs/guide.md | md::render
```

### `md::render_file <path>`

Reads a markdown file and renders it.

```bash
md::render_file README.md
md::render_file docs/changelog.md
```

## Supported syntax

| Element | Pattern | Rendering |
|---|---|---|
| Heading 1 | `# text` | Bold bright-white + `=` underline |
| Heading 2 | `## text` | Bold white + `-` underline |
| Heading 3 | `### text` | Bold cyan |
| Heading 4 | `#### text` | Bold green |
| Heading 5 | `##### text` | Bold yellow |
| Heading 6 | `###### text` | Bold dim |
| Bold | `**text**` | Bold style |
| Italic | `*text*` | Italic style |
| Strikethrough | `~~text~~` | Strikethrough style |
| Inline code | `` `code` `` | Dimmed, padded |
| Link | `[text](url)` | Blue underlined text + dimmed URL |
| Image | `![alt](url)` | Dimmed italic alt + dimmed URL |
| Horizontal rule | `---`, `***`, `___` | `hr()` across terminal |
| Unordered list | `- item`, `* item`, `+ item` | Bullet points |
| Ordered list | `1. item` | Numbered list |
| Task list | `- [ ] task`, `- [x] done` | ☐/☑ checkboxes |
| Blockquote | `> text` | Indented, dimmed, italic |
| Table | `\| a \| b \|` | Box-drawn grid with borders |
| Code block | `` ``` `` ... `` ``` `` | Dimmed, indented |
| Paragraph | plain text | Inline-rendered text |

## Examples

Render this README:

```bash
source board.bash
source md_parser.bash
md::render_file README_MD_PARSER.md
```

Inline formatting in action:

```bash
echo 'This is **bold**, *italic*, and \`code\`' | md::render
```

A full document:

```bash
cat <<'MARKDOWN' | md::render
# Project Title

> A blockquote with **style**

## Features

- Fast
- **Reliable**
- *Extensible*

1. Install
2. Configure
3. \`./run.sh\`

More details [here](https://example.com).

### Tables

```
| Name    | Age | City      |
|---------|-----|-----------|
| Alice   | 30  | New York  |
| Bob     | 25  | London    |
| Charlie | 35  | Tokyo     |
```
MARKDOWN
```

## Limitations

- Setext-style headers (`===` underline) are not supported (only ATX `#` headers).
- Reference-style links `[text][ref]` are not supported (only inline `[text](url)`).
- HTML is passed through verbatim (not rendered or stripped).
- Nested blockquotes (`> > nested`) are not supported.
- Inline formatting within table cells is not supported (cells render as plain text).

## License

MIT (same as board.bash)
