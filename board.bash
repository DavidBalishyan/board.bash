#!/usr/bin/env bash
# board.bash -- pretty up your terminal scripts
#
# A pure-bash library for colors, formatting, user prompts, progress bars,
# logging, and other stuff that makes command-line scripts not look like
# they were written in 1985.
#
# Drop this in your script:
#     source /path/to/board.bash
#
# Everything works out of the box. If your terminal doesn't do colors
# (piped output, CI, etc.), board strips them automatically.
#
# Quick peek at what's in here:
#
#  paint, info, ok, warn, error, die, debug   -- print stuff nicely
#  hr, title, header, bullet, box, center     -- make things look organized
#  cursor_up, cursor_save, clear_line, ...     -- terminal gymnastics
#  confirm, prompt, password, choose           -- talk to the user
#  spinner, progress, countdown                -- show you're busy
#  log::set_level, log::info, log::error, ...  -- structured logging
#  require, assert, is_macos, is_linux, ...    -- sanity checks
#  run, try, die_on_error                      -- run commands safely

BOARD_VERSION="1.0.0"

# COLORS & STYLES
#
# These are just variables holding ANSI escape codes. Use them directly if
# you want total control:
#
#     echo "${RED}Uh oh${RESET} -- something broke"
#     printf "${BOLD}${GREEN}%s${RESET}\n" "it worked!"
#
# Foreground:    BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE
# Bright fg:     BRIGHT_BLACK BRIGHT_RED ... BRIGHT_WHITE
# Background:    BG_BLACK BG_RED ... BG_WHITE
# Bright bg:     BG_BRIGHT_BLACK ... BG_BRIGHT_WHITE
# Styles:        BOLD DIM ITALIC UNDERLINE BLINK REVERSE HIDDEN STRIKETHROUGH
# Reset:         RESET

RESET=$'\e[0m'

BLACK=$'\e[30m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
MAGENTA=$'\e[35m'
CYAN=$'\e[36m'
WHITE=$'\e[37m'

BRIGHT_BLACK=$'\e[90m'
BRIGHT_RED=$'\e[91m'
BRIGHT_GREEN=$'\e[92m'
BRIGHT_YELLOW=$'\e[93m'
BRIGHT_BLUE=$'\e[94m'
BRIGHT_MAGENTA=$'\e[95m'
BRIGHT_CYAN=$'\e[96m'
BRIGHT_WHITE=$'\e[97m'

BG_BLACK=$'\e[40m'
BG_RED=$'\e[41m'
BG_GREEN=$'\e[42m'
BG_YELLOW=$'\e[43m'
BG_BLUE=$'\e[44m'
BG_MAGENTA=$'\e[45m'
BG_CYAN=$'\e[46m'
BG_WHITE=$'\e[47m'

BG_BRIGHT_BLACK=$'\e[100m'
BG_BRIGHT_RED=$'\e[101m'
BG_BRIGHT_GREEN=$'\e[102m'
BG_BRIGHT_YELLOW=$'\e[103m'
BG_BRIGHT_BLUE=$'\e[104m'
BG_BRIGHT_MAGENTA=$'\e[105m'
BG_BRIGHT_CYAN=$'\e[106m'
BG_BRIGHT_WHITE=$'\e[107m'

BOLD=$'\e[1m'
DIM=$'\e[2m'
ITALIC=$'\e[3m'
UNDERLINE=$'\e[4m'
BLINK=$'\e[5m'
REVERSE=$'\e[7m'
HIDDEN=$'\e[8m'
STRIKETHROUGH=$'\e[9m'

# Unicode symbols for status icons and decorations.
# Falls back to plain ASCII if UTF-8 isn't available.
if [[ "$LC_ALL" == *"UTF-8"* || "$LC_CTYPE" == *"UTF-8"* || "$LANG" == *"UTF-8"* ]]; then
    _BOARD_CHECKMARK=$'\xe2\x9c\x93'
    _BOARD_CROSS=$'\xe2\x9c\x97'
    _BOARD_WARN=$'\xe2\x9a\xa0'
    _BOARD_INFO=$'\xe2\x84\xb9'
    _BOARD_BULLET=$'\xe2\x80\xa2'
    _BOARD_HR_DEFAULT=$'\xe2\x94\x80'
    _BOARD_BOX_H=$'\xe2\x94\x80'
    _BOARD_BOX_V=$'\xe2\x94\x82'
    _BOARD_BOX_TL=$'\xe2\x94\x8c'
    _BOARD_BOX_TR=$'\xe2\x94\x90'
    _BOARD_BOX_BL=$'\xe2\x94\x94'
    _BOARD_BOX_BR=$'\xe2\x94\x98'
    _BOARD_SPINNER=($'\xe2\xa0\x8b' $'\xe2\xa0\x99' $'\xe2\xa0\xb9' $'\xe2\xa0\xb8' $'\xe2\xa0\xbc' $'\xe2\xa0\xb4' $'\xe2\xa0\xa6' $'\xe2\xa0\xa7' $'\xe2\xa0\x8f' $'\xe2\xa0\x8f')
    _BOARD_BLOCK=$'\xe2\x96\x88'
    _BOARD_ARROW=$'\xe2\x86\x92'
else
    _BOARD_CHECKMARK="+"
    _BOARD_CROSS="x"
    _BOARD_WARN="!"
    _BOARD_INFO="i"
    _BOARD_BULLET="*"
    _BOARD_HR_DEFAULT="-"
    _BOARD_BOX_H="-"
    _BOARD_BOX_V="|"
    _BOARD_BOX_TL="+"
    _BOARD_BOX_TR="+"
    _BOARD_BOX_BL="+"
    _BOARD_BOX_BR="+"
    _BOARD_SPINNER=('|' '/' '-' '\')
    _BOARD_BLOCK="#"
    _BOARD_ARROW="->"
fi

# INTERNAL HELPERS
#
# Prefixed with __board:: to keep them out of your namespace.
# The fancier functions below depend on these, but you probably
# won't need to call them directly. No judgment if you do though.

# Checks if stdout is connected to an actual terminal. Returns 0 if
# yes, 1 if it's a pipe or redirect. This is how we decide whether
# to show spinners and progress bars.
__board::is_terminal() {
    [[ -t 1 ]]
}

# Same thing for stderr.
__board::is_terminal_err() {
    [[ -t 2 ]]
}

# Figures out how wide the terminal is. Falls back to 80.
__board::width() {
    if __board::is_terminal && command -v tput &>/dev/null; then
        tput cols 2>/dev/null || echo 80
    else
        echo 80
    fi
}

# OUTPUT FUNCTIONS -- make text look good

# Like echo, but with flag names instead of cryptic escape codes.
# Automatically resets at the end so styles don't leak.
#
#   paint --red "error"
#   paint --green --bold "success"
#   paint --bright-yellow --bg-black "warning"
#   paint -n --cyan "spinning..."
#
paint() {
    local _n=false
    local _color=""
    local _style=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n) _n=true; shift ;;

            --black)         _color="$BLACK" ; shift ;;
            --red)           _color="$RED" ; shift ;;
            --green)         _color="$GREEN" ; shift ;;
            --yellow)        _color="$YELLOW" ; shift ;;
            --blue)          _color="$BLUE" ; shift ;;
            --magenta)       _color="$MAGENTA" ; shift ;;
            --cyan)          _color="$CYAN" ; shift ;;
            --white)         _color="$WHITE" ; shift ;;
            --bright-black)  _color="$BRIGHT_BLACK" ; shift ;;
            --bright-red)    _color="$BRIGHT_RED" ; shift ;;
            --bright-green)  _color="$BRIGHT_GREEN" ; shift ;;
            --bright-yellow) _color="$BRIGHT_YELLOW" ; shift ;;
            --bright-blue)   _color="$BRIGHT_BLUE" ; shift ;;
            --bright-magenta) _color="$BRIGHT_MAGENTA" ; shift ;;
            --bright-cyan)   _color="$BRIGHT_CYAN" ; shift ;;
            --bright-white)  _color="$BRIGHT_WHITE" ; shift ;;

            --bg-black)         _color="${_color}${BG_BLACK}" ; shift ;;
            --bg-red)           _color="${_color}${BG_RED}" ; shift ;;
            --bg-green)         _color="${_color}${BG_GREEN}" ; shift ;;
            --bg-yellow)        _color="${_color}${BG_YELLOW}" ; shift ;;
            --bg-blue)          _color="${_color}${BG_BLUE}" ; shift ;;
            --bg-magenta)       _color="${_color}${BG_MAGENTA}" ; shift ;;
            --bg-cyan)          _color="${_color}${BG_CYAN}" ; shift ;;
            --bg-white)         _color="${_color}${BG_WHITE}" ; shift ;;
            --bg-bright-black)  _color="${_color}${BG_BRIGHT_BLACK}" ; shift ;;
            --bg-bright-red)    _color="${_color}${BG_BRIGHT_RED}" ; shift ;;
            --bg-bright-green)  _color="${_color}${BG_BRIGHT_GREEN}" ; shift ;;
            --bg-bright-yellow) _color="${_color}${BG_BRIGHT_YELLOW}" ; shift ;;
            --bg-bright-blue)   _color="${_color}${BG_BRIGHT_BLUE}" ; shift ;;
            --bg-bright-magenta) _color="${_color}${BG_BRIGHT_MAGENTA}" ; shift ;;
            --bg-bright-cyan)   _color="${_color}${BG_BRIGHT_CYAN}" ; shift ;;
            --bg-bright-white)  _color="${_color}${BG_BRIGHT_WHITE}" ; shift ;;

            --bold)           _style="${_style}${BOLD}" ; shift ;;
            --dim)            _style="${_style}${DIM}" ; shift ;;
            --italic)         _style="${_style}${ITALIC}" ; shift ;;
            --underline)      _style="${_style}${UNDERLINE}" ; shift ;;
            --blink)          _style="${_style}${BLINK}" ; shift ;;
            --reverse)        _style="${_style}${REVERSE}" ; shift ;;
            --hidden)         _style="${_style}${HIDDEN}" ; shift ;;
            --strikethrough)  _style="${_style}${STRIKETHROUGH}" ; shift ;;

            --) shift; break ;;
            *) break ;;
        esac
    done

    if $_n; then
        printf "%s%s%s%s" "$_style" "$_color" "$*" "$RESET"
    else
        printf "%s%s%s%s\n" "$_style" "$_color" "$*" "$RESET"
    fi
}

# Shortcuts for common message types. warn and error go to stderr.
# debug only shows when BOARD_DEBUG is set.
info()   { paint --blue "${_BOARD_INFO} $*"; }
ok()     { paint --green "${_BOARD_CHECKMARK} $*"; }
warn()   { paint --yellow "${_BOARD_WARN} $*" >&2; }
error()  { paint --red "${_BOARD_CROSS} $*" >&2; }
debug()  { [[ -n "$BOARD_DEBUG" ]] && paint --dim "${_BOARD_BULLET} DEBUG: $*" >&2; }

# Prints an error and exits. Takes an optional exit code (default 1).
#
#   die "Something went wrong"
#   die "Fatal" 2
#
die() {
    local _code="${2:-1}"
    error "$1"
    exit "$_code"
}

# FORMATTING -- organize your output

# Draws a horizontal line across the terminal.
hr() {
    local _char="${1:-$_BOARD_HR_DEFAULT}"
    local _w=$(__board::width)
    local _line=""
    local _i=0
    while (( _i < _w )); do
        _line="${_line}${_char}"
        (( _i++ ))
    done
    printf "%s%s%s\n" "${DIM}" "$_line" "${RESET}"
}

# Bold text with an = underline across the terminal.
title() {
    local _text="$*"
    local _w=$(__board::width)
    printf "\n${BOLD}%s${RESET}\n" "$_text"
    local _i=0
    while (( _i < _w )); do
        printf "="
        (( _i++ ))
    done
    printf "\n"
}

# = lines above AND below the text. Use for major sections.
header() {
    local _text="$*"
    local _w=$(__board::width)
    local _i=0
    while (( _i < _w )); do
        printf "="
        (( _i++ ))
    done
    printf "\n${BOLD}%s${RESET}\n" "$_text"
    _i=0
    while (( _i < _w )); do
        printf "="
        (( _i++ ))
    done
    printf "\n\n"
}

# Dimmed bullet point for lists.
bullet() { paint --dim "${_BOARD_BULLET} $*"; }

# Puts text in a bordered box.
#
#  box "Hello"
#  # +-------+
#  # | Hello |
#  # +-------+
#
box() {
    local _text="$*"
    local _len=${#_text}
    local _top="${_BOARD_BOX_TL}${_BOARD_BOX_H}"
    local _bot="${_BOARD_BOX_BL}${_BOARD_BOX_H}"
    local _i=0
    while (( _i < _len + 2 )); do
        _top="${_top}${_BOARD_BOX_H}"
        _bot="${_bot}${_BOARD_BOX_H}"
        (( _i++ ))
    done
    _top="${_top}${_BOARD_BOX_TR}"
    _bot="${_bot}${_BOARD_BOX_BR}"
    printf "%s\n" "$_top"
    printf "%s %s %s\n" "${_BOARD_BOX_V}" "$_text" "${_BOARD_BOX_V}"
    printf "%s\n" "$_bot"
}

# Centers text horizontally in the terminal.
center() {
    local _text="$*"
    local _w=$(__board::width)
    local _len=${#_text}
    local _pad=$(( (_w - _len) / 2 ))
    if (( _pad > 0 )); then
        local _i=0
        while (( _i < _pad )); do
            printf " "
            (( _i++ ))
        done
    fi
    printf "%s\n" "$_text"
}

# Indents text by n spaces.
indent() {
    local _n="$1"
    shift
    local _text="$*"
    local _pad=""
    local _i=0
    while (( _i < _n )); do
        _pad="${_pad} "
        (( _i++ ))
    done
    printf "%s%s\n" "$_pad" "$_text"
}

# Prints dim text, good for showing commands or file paths.
code() { paint --dim "${_BOARD_BULLET} $*"; }

# TERMINAL CONTROL -- cursor and screen manipulation

cursor_up()    { printf "\e[${1:-1}A"; }
cursor_down()  { printf "\e[${1:-1}B"; }
cursor_save()      { printf "\e[s"; }
cursor_restore()   { printf "\e[u"; }
cursor_hide()      { printf "\e[?25l"; }
cursor_show()      { printf "\e[?25h"; }
clear_line()       { printf "\e[K"; }
clear_screen()     { printf "\e[2J\e[H"; }

# Print terminal width in characters (or 80).
columns() { __board::width; }

# Print terminal height in lines (or 24).
lines() {
    if __board::is_terminal && command -v tput &>/dev/null; then
        tput lines 2>/dev/null || echo 24
    else
        echo 24
    fi
}

beep()     { printf "\a"; }

# Set the terminal window or tab title.
set_title() { printf "\e]0;%s\a" "$*"; }

# USER INPUT -- ask the person on the other end

# Yes/no question. Returns 0 for yes, 1 for no.
# Second argument sets the default (y or n, default is n).
#
#   if confirm "Delete the file?"; then
#       rm file.txt
#   fi
#
confirm() {
    local _prompt="${1:-Continue?}"
    local _default="${2:-n}"
    local _yn

    if [[ "$_default" == "y" ]]; then
        _prompt="$_prompt [Y/n] "
    else
        _prompt="$_prompt [y/N] "
    fi

    while true; do
        read -r -p "$(paint -n --cyan "$_prompt")" _yn
        _yn="${_yn:-$_default}"
        case "${_yn,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     paint --yellow "Please answer y or n." >&2 ;;
        esac
    done
}

# Reads text input into a variable.
#
#   prompt name "What's your name?"
#   echo "Hello, $name!"
#
prompt() {
    local _var="$1"
    shift
    local _prompt="$*"
    local _val

    read -r -p "$(paint -n --cyan "${_prompt}: ")" _val
    printf -v "$_var" "%s" "$_val"
}

# Like prompt but doesn't echo what the user types.
#
#   password pass "Enter password"
#
password() {
    local _var="$1"
    shift
    local _prompt="$*"
    local _val

    paint -n --cyan "${_prompt}: " >&2
    read -r -s _val
    echo >&2
    printf -v "$_var" "%s" "$_val"
}

# Shows a numbered menu and stores the selected option in a variable.
#
#   choose color "Pick one" red green blue
#   echo "You picked $color"
#
choose() {
    local _var="$1"
    shift
    local _prompt="$1"
    shift
    local _opts=("$@")
    local _i _choice _sel

    if [[ ${#_opts[@]} -eq 0 ]]; then
        printf -v "$_var" ""
        return 1
    fi

    echo "$_prompt" >&2
    for _i in "${!_opts[@]}"; do
        printf "  %d) %s\n" $((_i + 1)) "${_opts[_i]}" >&2
    done

    while true; do
        read -r -p "$(paint -n --cyan "Choose [1-${#_opts[@]}]: ")" _choice
        if [[ "$_choice" =~ ^[0-9]+$ ]] && (( _choice >= 1 && _choice <= ${#_opts[@]} )); then
            _sel="${_opts[$((_choice - 1))]}"
            printf -v "$_var" "%s" "$_sel"
            return 0
        fi
        paint --yellow "Invalid selection. Enter a number between 1 and ${#_opts[@]}." >&2
    done
}

# Waits for the user to press any key.
press_any_key() {
    local _prompt="${1:-Press any key to continue...}"
    paint --dim "$_prompt" >&2
    read -r -n 1 -s
    echo >&2
}

# PROGRESS AND STATUS -- show you're not frozen

# Runs a command in the background with an animated spinner.
# Shows a checkmark or cross when done. Returns the command's exit code.
#
#   spinner "Installing" npm install || die "npm failed"
#
spinner() {
    local _msg="$1"
    shift
    local _cmd=("$@")
    local _pid _exit_code=0
    local _i=0
    local _spin_chars=("${_BOARD_SPINNER[@]}")

    if ! __board::is_terminal; then
        paint --dim "${_msg}..."
        "${_cmd[@]}"
        return $?
    fi

    ("${_cmd[@]}") &>/tmp/board_spinner_out.$$ &
    _pid=$!

    cursor_hide

    while kill -0 "$_pid" 2>/dev/null; do
        local _c="${_spin_chars[_i]}"
        printf "\r%s %s..." "$_c" "$_msg" >&2
        _i=$(( (_i + 1) % ${#_spin_chars[@]} ))
        sleep 0.1
    done

    wait "$_pid"
    _exit_code=$?

    if [[ $_exit_code -eq 0 ]]; then
        printf "\r${GREEN}${_BOARD_CHECKMARK}${RESET} %s...${GREEN}done${RESET}  \n" "$_msg" >&2
    else
        printf "\r${RED}${_BOARD_CROSS}${RESET} %s...${RED}failed${RESET}  \n" "$_msg" >&2
    fi

    cursor_show
    rm -f /tmp/board_spinner_out.$$

    return $_exit_code
}

# Draws a progress bar with percentage. Call in a loop to animate.
# Pass total=0 for an indeterminate bar.
#
#   total=${#files[@]}
#   for i in "${!files[@]}"; do
#       progress $((i + 1)) $total
#       process "${files[i]}"
#   done
#   echo
#
progress() {
    local _current="$1"
    local _total="$2"
    local _width="${3:-40}"
    local _pct _filled _empty _bar _label

    if ! __board::is_terminal; then
        return
    fi

    if [[ "$_total" -le 0 ]]; then
        local _pos=$(( _current % _width ))
        local _i=0
        _bar=""
        while (( _i < _width )); do
            if (( _i == _pos )); then
                _bar="${_bar}${_BOARD_BLOCK}"
            else
                _bar="${_bar}${DIM}${_BOARD_BLOCK}${RESET}"
            fi
            (( _i++ ))
        done
        printf "\r  %s" "$_bar" >&2
        return
    fi

    (( _current > _total )) && _current=$_total
    (( _current < 0 )) && _current=0

    _pct=$(( _current * 100 / _total ))
    _filled=$(( _current * _width / _total ))
    _empty=$(( _width - _filled ))
    _bar=""
    local _i=0
    while (( _i < _filled )); do
        _bar="${_bar}${_BOARD_BLOCK}"
        (( _i++ ))
    done
    _i=0
    while (( _i < _empty )); do
        _bar="${_bar}${DIM}${_BOARD_BLOCK}${RESET}"
        (( _i++ ))
    done

    printf "\r%3d%% ${_bar}" "$_pct" >&2
}

# Prints a line with a timestamp.
status() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*" >&2; }

# Counts down from N seconds.
countdown() {
    local _secs="$1"
    local _i

    for (( _i = _secs; _i > 0; _i-- )); do
        printf "\r${BOLD}%2d${RESET}" "$_i" >&2
        sleep 1
    done
    printf "\r${GREEN}${_BOARD_CHECKMARK}${RESET}  \n" >&2
}

# LOGGING -- keep a record
#
# Levels are DEBUG < INFO < WARN < ERROR < SILENT.
# Set the level with log::set_level. Optionally log to a file with
# log::set_file.

_BOARD_LOG_LEVEL_DEBUG=0
_BOARD_LOG_LEVEL_INFO=1
_BOARD_LOG_LEVEL_WARN=2
_BOARD_LOG_LEVEL_ERROR=3
_BOARD_LOG_LEVEL_SILENT=4

_BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_INFO"
_BOARD_LOG_FILE=""

# Set the minimum log level. Everything below is silently dropped.
log::set_level() {
    case "${1^^}" in
        DEBUG)  _BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_DEBUG" ;;
        INFO)   _BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_INFO" ;;
        WARN)   _BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_WARN" ;;
        ERROR)  _BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_ERROR" ;;
        SILENT) _BOARD_LOG_LEVEL="$_BOARD_LOG_LEVEL_SILENT" ;;
        *)      warn "Unknown log level: $1 (use DEBUG, INFO, WARN, ERROR, SILENT)" ;;
    esac
}

# Also write log output to a file.
log::set_file() { _BOARD_LOG_FILE="$1"; }

# The internal logger: timestamps, colors, filters, and writes to file.
__board::log() {
    local _level="$1"
    local _level_name="$2"
    local _color="$3"
    local _msg="$4"
    local _timestamp
    _timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if (( _level < _BOARD_LOG_LEVEL )); then
        return
    fi

    printf "%s [%s] %s%s%s\n" "$_timestamp" "$_level_name" "$_color" "$_msg" "$RESET" >&2

    if [[ -n "$_BOARD_LOG_FILE" ]]; then
        printf "%s [%s] %s\n" "$_timestamp" "$_level_name" "$_msg" >> "$_BOARD_LOG_FILE"
    fi
}

log::debug() { __board::log "$_BOARD_LOG_LEVEL_DEBUG" "DEBUG" "${DIM}" "$*"; }
log::info()  { __board::log "$_BOARD_LOG_LEVEL_INFO"  "INFO"  "${BLUE}" "$*"; }
log::warn()  { __board::log "$_BOARD_LOG_LEVEL_WARN"  "WARN"  "${YELLOW}" "$*"; }
log::error() { __board::log "$_BOARD_LOG_LEVEL_ERROR" "ERROR" "${RED}" "$*"; }

# ASSERTIONS AND CHECKS -- sanity first

# Dies if a command isn't found on this system.
# Optionally takes a hint about how to install it.
#
#   require git
#   require jq "Install jq with: apt install jq"
#
require() {
    local _cmd="$1"
    local _hint="${2:-}"
    if ! command -v "$_cmd" &>/dev/null; then
        error "Required command not found: ${BOLD}$_cmd${RESET}"
        if [[ -n "$_hint" ]]; then
            error "  ${_hint}"
        fi
        die "Please install '$_cmd' and try again."
    fi
}

# Dies if the script isn't running as root.
require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        die "This command must be run as root (use sudo)."
    fi
}

# Run a command or test. Dies if it returns non-zero.
#
#   assert [[ -f "$config" ]]
#   assert grep -q "KEY" .env
#
assert() {
    local _condition="$*"
    if ! eval "$_condition"; then
        die "Assertion failed: $_condition"
    fi
}

# Platform checks 
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
is_wsl()   { [[ -f /proc/version ]] && grep -qi microsoft /proc/version; }

# Returns 0 if the terminal supports color, 1 otherwise.
# Respects the NO_COLOR convention (https://no-color.org).
# Called automatically on load. If colors aren't supported, all
# the color variables are blanked out.
has_color() {
    if [[ -n "$NO_COLOR" ]]; then
        return 1
    fi
    if [[ "$TERM" == dumb ]]; then
        return 1
    fi
    if __board::is_terminal || __board::is_terminal_err; then
        return 0
    fi
    return 1
}

# EXECUTION HELPERS

# Prints the command, then runs it. Shows the exit code if it fails.
#
#   run cp file.txt backup/
#
run() {
    local _cmd=("$@")
    local _ec

    paint --dim "${_BOARD_ARROW} ${_cmd[*]}" >&2
    "${_cmd[@]}"
    _ec=$?

    if [[ $_ec -ne 0 ]]; then
        paint --red "${_BOARD_CROSS} Command exited with code $_ec" >&2
    fi

    return $_ec
}

# Runs a command and ignores errors (swallows non-zero exit codes).
try() { "$@" || true; }

# Put this after a command and it'll die with a message if the
# previous command failed.
#
#   cp file.txt backup/
#   die_on_error "Backup failed"
#
die_on_error() {
    local _ec=$?
    if [[ $_ec -ne 0 ]]; then
        die "$* (exit code: $_ec)"
    fi
}

# BOOTSTRAP
#
# When the library loads, check if the terminal supports colors.
# If not, blank out all the color variables so you don't get
# garbage escape codes in log files or CI output.

if ! has_color; then
    RESET=""
    BLACK="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE=""
    BRIGHT_BLACK="" BRIGHT_RED="" BRIGHT_GREEN="" BRIGHT_YELLOW=""
    BRIGHT_BLUE="" BRIGHT_MAGENTA="" BRIGHT_CYAN="" BRIGHT_WHITE=""
    BG_BLACK="" BG_RED="" BG_GREEN="" BG_YELLOW="" BG_BLUE=""
    BG_MAGENTA="" BG_CYAN="" BG_WHITE=""
    BG_BRIGHT_BLACK="" BG_BRIGHT_RED="" BG_BRIGHT_GREEN="" BG_BRIGHT_YELLOW=""
    BG_BRIGHT_BLUE="" BG_BRIGHT_MAGENTA="" BG_BRIGHT_CYAN="" BG_BRIGHT_WHITE=""
    BOLD="" DIM="" ITALIC="" UNDERLINE="" BLINK="" REVERSE="" HIDDEN="" STRIKETHROUGH=""
fi
