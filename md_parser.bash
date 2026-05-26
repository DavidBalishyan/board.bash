#!/bin/bash
# md_parser.bash -- render Markdown in the terminal using board.bash
#
# Source board.bash first, then pipe or pass markdown files to render:
#
#   source /path/to/board.bash
#   source /path/to/md_parser.bash
#   md::render_file README.md
#   echo "# Hello" | md::render
#

_MD_IN_CODE_BLOCK=false

# Inline parsing
_md::inline() {
    local text="$1" result="" i=0
    local len=${#text}

    while (( i < len )); do
        local c="${text:i:1}"

        if [[ "$c" == '`' ]]; then
            local inner=""
            local j=$((i + 1))
            while (( j < len )) && [[ "${text:j:1}" != '`' ]]; do
                inner+="${text:j:1}"
                ((j++))
            done
            if (( j < len )); then
                result+="$(paint -n --dim " ${inner} ")"
                i=$((j + 1))
            else
                result+='`'
                ((i++))
            fi

        elif [[ "$c" == '*' ]]; then
            if (( i + 1 < len )) && [[ "${text:i+1:1}" == '*' ]]; then
                local inner="" j=$((i + 2)) found=false
                while (( j + 1 < len )); do
                    if [[ "${text:j:2}" == '**' ]]; then found=true; break; fi
                    inner+="${text:j:1}"
                    ((j++))
                done
                if $found; then
                    result+="$(paint -n --bold "$(_md::inline "$inner")")"
                    i=$((j + 2))
                else
                    result+='**'; i=$((i + 2))
                fi
            else
                local inner="" j=$((i + 1)) found=false
                while (( j < len )); do
                    if [[ "${text:j:1}" == '*' ]]; then
                        if (( j + 1 < len )) && [[ "${text:j+1:1}" == '*' ]]; then
                            inner+='*'; ((j++)); continue
                        fi
                        found=true; break
                    fi
                    inner+="${text:j:1}"
                    ((j++))
                done
                if $found; then
                    result+="$(paint -n --italic "$(_md::inline "$inner")")"
                    i=$((j + 1))
                else
                    result+='*'; ((i++))
                fi
            fi

        elif [[ "$c" == '~' && $((i + 1)) -lt len && "${text:i+1:1}" == '~' ]]; then
            local inner="" j=$((i + 2)) found=false
            while (( j + 1 < len )); do
                if [[ "${text:j:2}" == '~~' ]]; then found=true; break; fi
                inner+="${text:j:1}"
                ((j++))
            done
            if $found; then
                result+="$(paint -n --strikethrough "$(_md::inline "$inner")")"
                i=$((j + 2))
            else
                result+='~~'; i=$((i + 2))
            fi

        elif [[ "$c" == '[' ]]; then
            local link_text="" j=$((i + 1))
            while (( j < len )) && [[ "${text:j:1}" != ']' ]]; do
                link_text+="${text:j:1}"; ((j++))
            done
            if (( j < len )); then
                local k=$((j + 1))
                if (( k < len )) && [[ "${text:k:1}" == '(' ]]; then
                    local url=""; ((k++))
                    while (( k < len )) && [[ "${text:k:1}" != ')' ]]; do
                        url+="${text:k:1}"; ((k++))
                    done
                    if (( k < len )); then
                        result+="$(paint -n --blue --underline "$(_md::inline "$link_text")")"
                        result+="$(paint -n --dim " (${url})")"
                        i=$((k + 1))
                    else
                        result+="[$link_text"; i=$j
                    fi
                else
                    result+="[$link_text"; i=$j
                fi
            else
                result+='['; ((i++))
            fi

        elif [[ "$c" == '!' && $((i + 1)) -lt len && "${text:i+1:1}" == '[' ]]; then
            local alt="" j=$((i + 2))
            while (( j < len )) && [[ "${text:j:1}" != ']' ]]; do
                alt+="${text:j:1}"; ((j++))
            done
            if (( j < len )); then
                local k=$((j + 1))
                if (( k < len )) && [[ "${text:k:1}" == '(' ]]; then
                    local url=""; ((k++))
                    while (( k < len )) && [[ "${text:k:1}" != ')' ]]; do
                        url+="${text:k:1}"; ((k++))
                    done
                    if (( k < len )); then
                        result+="$(paint -n --dim --italic "$alt")"
                        result+="$(paint -n --dim " (${url})")"
                        i=$((k + 1))
                    else
                        result+="![$alt"; i=$j
                    fi
                else
                    result+="![$alt"; i=$j
                fi
            else
                result+='!'; ((i++))
            fi

        else
            result+="$c"; ((i++))
        fi
    done

    printf "%s" "$result"
}

# Block-level rendering
_md::render_paragraph() {
    local rendered="$(_md::inline "$*")"
    echo "$rendered"
}

_md::render_blockquote() {
    local content="$1"
    local rendered="$(_md::inline "$content")"
    indent 4 "$(paint -n --dim --italic "$rendered")"
}

_md::render_unordered_list() {
    bullet "$(_md::inline "$1")"
}

_md::render_ordered_list() {
    local num="$1" content="$2"
    printf "  %s. %s\n" "$num" "$(_md::inline "$content")"
}

_md::render_task_list() {
    local checked="$1" content="$2"
    local rendered="$(_md::inline "$content")"
    if [[ "$checked" == "x" ]]; then
        printf "  %s %s\n" "$(paint -n --green "☑")" "$rendered"
    else
        printf "  %s %s\n" "$(paint -n --dim "☐")" "$rendered"
    fi
}

_md::render_code_block() {
    paint --dim "  $1"
}

# Line dispatch
_md::render_line() {
    local line="$1"

    if [[ "$line" =~ ^\`\`\` ]] || [[ "$line" =~ ^\~\~\~ ]]; then
        if $_MD_IN_CODE_BLOCK; then
            _MD_IN_CODE_BLOCK=false
            echo
        else
            _MD_IN_CODE_BLOCK=true
        fi
        return
    fi

    if $_MD_IN_CODE_BLOCK; then
        _md::render_code_block "$line"
        return
    fi

    if [[ -z "$line" ]]; then
        echo
        return
    fi

    if [[ "$line" =~ ^(#{1,6})\ (.+)$ ]]; then
        local level="${#BASH_REMATCH[1]}"
        local content="${BASH_REMATCH[2]}"
        local rendered="$(_md::inline "$content")"
        case $level in
            1) header "$rendered" ;;
            2) title "$rendered" ;;
            3) paint --bold --cyan "$rendered" ;;
            4) paint --bold --green "$rendered" ;;
            5) paint --bold --yellow "$rendered" ;;
            6) paint --bold --dim "$rendered" ;;
        esac
        return
    fi

    if [[ "$line" =~ ^[-*_]{3,}$ ]]; then
        hr
        echo
        return
    fi

    if [[ "$line" =~ ^[-*+]\ \[( |x)\]\ (.*) ]]; then
        _md::render_task_list "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return
    fi

    if [[ "$line" =~ ^[-*+]\ (.*) ]]; then
        _md::render_unordered_list "${BASH_REMATCH[1]}"
        return
    fi

    if [[ "$line" =~ ^([0-9]+)\.\ (.*) ]]; then
        _md::render_ordered_list "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return
    fi

    if [[ "$line" =~ ^\>\ ?(.*) ]]; then
        _md::render_blockquote "${BASH_REMATCH[1]}"
        return
    fi

    _md::render_paragraph "$line"
}

# Public api
md::render() {
    local line
    _MD_IN_CODE_BLOCK=false
    while IFS= read -r line || [[ -n "$line" ]]; do
        _md::render_line "$line"
    done
}

md::render_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        die "File not found: $file"
    fi
    md::render < "$file"
}
