#!/bin/sh

SRCFLD=$(dirname $(readlink -m "$0"))
TGTFLD="${HOME}/.local/bin"

mkdir -p "${TGTFLD}"

# disabled since not used right now
# ln -s -f -v "$SRCFLD/daemon_html_to_markdown_link.sh" "$TGTFLD/daemon_html_to_markdown_link"
# ln -s -f -v "$SRCFLD/client_html_to_markdown_link.sh" "$TGTFLD/html_to_markdown_link"
ln -s -f -v "$SRCFLD/xinitrc" "$HOME/.xinitrc"
# ln -s -f -v "$SRCFLD/brightness_down.sh"  "$TGTFLD"
# ln -s -f -v "$SRCFLD/brightness_up.sh"  "$TGTFLD"
