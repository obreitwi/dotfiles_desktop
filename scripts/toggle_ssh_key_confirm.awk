#!/usr/bin/awk -f

BEGIN {
    skip_line = 0;
}

function toggle_confirm()
{
    if ($3 ~ /^confirm$/)
    {
        print $1, $2
    }
    else
    {
        print $1, $2, "confirm"
    }
    skip_line = 1;
}

$1 ~ "97FF0A28D247AEFEA32CB5D6DA58B67283BF1A23" { toggle_confirm() }
$1 ~ "338A8455AC3DF1325E8DBD6FD5B7C94CDDD120B1" { toggle_confirm() }

!skip_line { print }
skip_line  { skip_line = 0; }
