#!/bin/sh

SRCFLD=$(dirname "$(readlink -m "$0")")
TGTFLD="${HOME}/.local/share/applications"

[ ! -d "${TGTFLD}" ] && mkdir -vp "${TGTFLD}"

ln -s -f -v "${SRCFLD}/nvim-urxvt.desktop" "${TGTFLD}"
ln -s -f -v "${SRCFLD}/zathura.desktop" "${TGTFLD}"

export XDG_UTILS_DEBUG_LEVEL=10

for ft in $(grep MimeType "${SRCFLD}/nvim-urxvt.desktop" | cut -d= -f2 | tr ';' ' '); do
    xdg-mime default nvim-urxvt.desktop "$ft";
done

if which zathura>/dev/null; then
    xdg-mime default zathura.desktop application/pdf
    xdg-mime default zathura.desktop application/djvu
fi
