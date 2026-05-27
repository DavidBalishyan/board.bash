# board.bash

Make your bash scripts look like they belong in this century.

Colors, spinners, progress bars, user prompts, logging -- all in one
pure-bash file with zero dependencies. Drop it in, source it, done.

## Usage

```bash
source /path/to/board.bash
```

That's it. Everything below is ready to use. Colors auto-disable when
piping to a file or running in CI. UTF-8 symbols fall back to ASCII
if your terminal doesn't support them. No config, no fuss.

## Cheat sheet

### Print stuff

```bash
info  "Processing..."      # blue ℹ
ok    "All good"           # green ✓
warn  "Low disk space"     # yellow ⚠
error "File not found"     # red ✗
die   "Fatal" 2            # error + exit with code (default 1)
debug "x = 42"             # dim, only if BOARD_DEBUG is set

paint --red "red text"
paint --green --bold "bold green"
paint --bright-yellow --bg-black --underline "fancy"
paint -n --cyan "no newline"
```

### Make it pretty

```bash
hr                        # ─────────── across the whole terminal
title "Section"           # bold title + === underline
header "Major"            # === overline + title + === underline
bullet "item"             # • dimmed bullet point
box "Hello"               # box around your text
center "Welcome"          # horizontally centered
indent 4 "hi"             # indented by 4 spaces
code "apt install foo"    # dim, code-style text
```

### Move the cursor around

```bash
cursor_up          # up one line
cursor_down 3      # down 3 lines
cursor_save        # remember this position
cursor_restore     # go back to saved position
cursor_hide        # make cursor invisible
cursor_show        # make cursor visible again
clear_line         # erase to end of line
clear_screen       # clear everything, go home
columns            # print terminal width
lines              # print terminal height
beep               # *beep*
set_title "Hey"    # set window/tab title
```

### Talk to the user

```bash
if confirm "Delete?"; then             # yes/no, default: n
    rm file.txt
fi

if confirm "Overwrite?" "y"; then      # default: y
    cp src dst
fi

prompt name "Enter your name"          # read into $name
password pass "Password"               # silent input into $pass

choose color "Pick one" red green blue # numbered menu into $color

press_any_key                          # wait for keypress
```

### Show you're working

```bash
spinner "Installing" npm install       # animated spinner, shows ✓/✗

# progress bar in a loop:
total=${#files[@]}
for i in "${!files[@]}"; do
    progress $((i + 1)) $total
    process "${files[i]}"
done
echo                                   # newline after the bar

countdown 5                            # 5... 4... 3... 2... 1... ✓
status "Server started"                # [14:32:01] Server started
```

### Log stuff

```bash
log::set_level DEBUG             # show everything (default: INFO)
log::set_file /tmp/app.log       # also write to file

log::debug "connecting..."       # dim, filtered below DEBUG
log::info  "listening on 8080"   # blue
log::warn  "disk 90% full"       # yellow
log::error "connection refused"  # red
```

### Check your assumptions

```bash
require git "apt install git"    # die if git not found
require_root                     # die if not running as root

assert [[ -f "$config" ]]        # die if condition is false
assert grep -q "KEY" .env        # same, but runs a command

if is_macos; then echo "mac"; fi
if is_linux;  then echo "linux"; fi
if is_wsl;    then echo "wsl";   fi
if has_color; then echo "color!"; fi
```

### Run commands

```bash
run cp file.txt backup/          # prints the command, then runs it
try rm tempdir                   # runs it, ignores errors

cp file.txt backup/
die_on_error "Backup failed"     # die if previous command failed
```

## Scripts that use board

```bash
#!/bin/bash
source /path/to/board.bash

require git "Install git first"
require gcc

header "Building project"
run gcc -o app main.c

if confirm "Install?"; then
    spinner "Installing" cp app /usr/local/bin
    ok "Done!"
fi
```

## Environment variables

| Variable | What it does |
|---|---|
| `BOARD_DEBUG` | Set to anything to enable `debug()` output |
| `NO_COLOR` | Set to anything to disable all colors ([no-color.org](https://no-color.org)) |

## Design, philosophy, etc.

- **Zero dependencies.** Pure bash + standard POSIX utilities. Nothing to
  install, nothing to break.
- **Graceful degradation.** Colors go away when piped. Spinners don't spin
  when there's no terminal. UTF-8 symbols turn into ASCII when they need to.
- **Simple functions, not DSLs.** No config files, no init calls, no
  object-oriented nonsense. Just functions that do one thing.

## License

[LGPL-2.1](LICENSE)
