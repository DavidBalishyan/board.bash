#!/bin/bash
# Walk through every function in board.bash with real examples.
# Run this in a terminal to see what each one does.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/board.bash"

set_title "board.bash demo"

header "board.bash v$BOARD_VERSION"
center "A tour of every function in the library"
echo

# ------------------------------------------------------------------
info "Checking we have the basics"
require "bash" "You somehow don't have bash?"
require "sleep" "GNU coreutils"

ok "All dependencies met"
echo

# ------------------------------------------------------------------
title "paint -- color output"

info "paint is like echo with color flags:"
paint --red         "  paint --red 'text'"
paint --green       "  paint --green 'text'"
paint --yellow      "  paint --yellow 'text'"
paint --blue        "  paint --blue 'text'"
paint --magenta     "  paint --magenta 'text'"
paint --cyan        "  paint --cyan 'text'"
paint --white       "  paint --white 'text'"

paint --bright-red  "  paint --bright-red 'text'"
paint --bright-green "  paint --bright-green 'text'"
paint --bright-yellow "  paint --bright-yellow 'text'"

paint --bold        "  paint --bold 'bold'"
paint --dim         "  paint --dim 'dimmed'"
paint --underline   "  paint --underline 'underlined'"

paint --red --bold "  paint --red --bold 'bold red'"
paint --green --italic "  paint --green --italic 'italic green'"
paint -n --cyan "  paint -n --cyan 'no newline... '"
echo "and the line continues (no newline above)"
echo

# You can also use the color variables directly:
echo "${BOLD}${BLUE}direct variable:${RESET} ${GREEN}\${GREEN}green\${RESET}${RESET}"
echo

# ------------------------------------------------------------------
title "Status helpers: info, ok, warn, error, debug"

info "Info message (blue)"
ok   "OK message (green)"
warn "Warning message (yellow, goes to stderr)"
error "Error message (red, goes to stderr)"

export BOARD_DEBUG=1
debug "Debug message (dim, only when BOARD_DEBUG is set)"
unset BOARD_DEBUG
echo

# ------------------------------------------------------------------
title "Formatting: hr, bullet, box, center, indent, code"

bullet "This is a bullet point"
bullet "Great for lists in your output"
code "apt install foo"
code "/var/log/syslog"
indent 4 "indent 4 -- indented block of text"
indent 4 "indent 4 -- useful for nested output"
echo

box "Hello from board.bash!"
echo

center "Centered text is useful for banners"
center "and splash screens"
echo

# ------------------------------------------------------------------
title "Terminal dimensions"

echo "  Terminal width:  $(columns) columns"
echo "  Terminal height: $(lines) lines"
echo

# ------------------------------------------------------------------
title "Progress bar (determinate)"

info "Simulating file processing..."
echo

total=30
for i in $(seq 1 $total); do
    progress "$i" "$total" 30
    sleep 0.03
done
echo
echo

# ------------------------------------------------------------------
title "Progress bar (indeterminate)"

info "Processing with unknown total..."
echo

for i in $(seq 1 60); do
    progress "$i" 0 20
    sleep 0.03
done
echo
echo

# ------------------------------------------------------------------
title "Spinner"

info "Running a fake task with a spinner..."
spinner "Thinking really hard" sleep 1.5
echo

# ------------------------------------------------------------------
title "Countdown"

countdown 3
echo

# ------------------------------------------------------------------
title "Logging"

info "Logging with different levels:"
log::set_level DEBUG
log::debug "Connecting to database..."
sleep 0.2
log::info  "Connected to database on port 5432"
sleep 0.2
log::warn  "Connection pool is at 80% capacity"
sleep 0.2
log::error "Query timeout after 5s"
echo

# ------------------------------------------------------------------
title "Platform checks"

is_macos && info "Running on macOS"
is_linux && info "Running on Linux"
is_wsl   && info "Running on WSL"
has_color && info "Terminal supports color"
echo

# ------------------------------------------------------------------
title "Execution helpers"

info "try ignores errors gracefully:"
try false
ok "Script kept running after try false"

info "run prints the command before executing:"
run echo "  hello from run()"
echo

# ------------------------------------------------------------------
title "Interactive input"

if [[ -t 0 ]]; then
    info "Terminal is interactive, showing input prompts..."
    echo

    prompt name "What's your name?"
    ok "Hello, $name!"
    echo

    if confirm "Did you enjoy this demo?" "y"; then
        ok "Glad you liked it!"
    else
        warn "Fair enough, I'll keep improving."
    fi
    echo

    press_any_key
else
    warn "Not a terminal, skipping interactive prompts"
fi
echo

# ------------------------------------------------------------------
hr
center "${BOLD}That's all for the board.bash tour!${RESET}"
center "See the README.md for the full reference"
echo

ok "Demo complete"
