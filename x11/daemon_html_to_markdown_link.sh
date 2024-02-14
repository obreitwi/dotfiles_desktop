#!/usr/bin/env bash

PID_FILE=/tmp/pid_html_to_markdown_link

echo $$ > "${PID_FILE}"

ensure_exists() {
    if ! which "$1" >/dev/null; then
        echo "ERROR: $1 missing!" >&2
    fi
}

ensure_exists xclip
ensure_exists pandoc

xclip-html-to-markdown () {
    xclip -o -selection clipboard -t text/html | pandoc -f html -t markdown | tr '\n' ' ' | tr -d '\\' | xclip -i -selection clipboard
}

while true; do
    kill -STOP $$
    xclip-html-to-markdown
done

