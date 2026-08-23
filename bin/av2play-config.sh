#!/bin/sh
# av2play-config.sh - configure av2play boot defaults. No Python needed.
#
# No arguments: finds AVFPLAY and AV2PLAY.XEX next to this script and offers
# an interactive menu for each (current values shown).
#
# Arguments:  av2play-config.sh <file> [UI] [SOUND] [PLAYBACK] [STORAGE]
#   UI:       auto | ui40 | ui80m3 | ui80m4
#   SOUND:    pokey | d280 | d300 | d500 | d580 | d600 | d700
#   PLAYBACK: playapac | play80m3 | play80m4
#   STORAGE:  auto | off
#   '.' (or '-') leaves a slot unchanged. Old value names (ui80, std, m3,
#   m4) are still accepted.

find_off() {
    grep -abo 'A2CF' "$1" 2>/dev/null | head -n1 | cut -d: -f1
}
peek() {
    dd if="$1" bs=1 skip=$(($2 + $3)) count=1 2>/dev/null | od -An -tu1 | tr -d ' \n'
}
poke() {
    printf "$(printf '\\%03o' "$4")" | dd of="$1" bs=1 seek=$(($2 + $3)) conv=notrunc 2>/dev/null
}

ui_name() {
    case "$1" in
        255) echo auto ;; 0) echo ui40 ;; 1) echo ui80m3 ;; 2) echo ui80m4 ;;
        *) echo invalid ;;
    esac
}
snd_name() {
    case "$1" in
        0) echo pokey ;; 1) echo d280 ;; 2) echo d300 ;; 3) echo d500 ;;
        4) echo d580 ;; 5) echo d600 ;; 6) echo d700 ;; *) echo invalid ;;
    esac
}
pb_name() {
    case "$1" in
        0) echo playapac ;; 1) echo play80m3 ;; 2) echo play80m4 ;;
        *) echo invalid ;;
    esac
}
st_name() {
    case "$1" in 0) echo auto ;; 1) echo off ;; *) echo invalid ;; esac
}

show_config() {
    echo ""
    echo "$(basename "$1"):"
    echo "  1) UI mode      : $(ui_name  "$(peek "$1" "$2" 5)")"
    echo "  2) Sound device : $(snd_name "$(peek "$1" "$2" 6)")"
    echo "  3) Playback     : $(pb_name  "$(peek "$1" "$2" 7)")"
    echo "  4) Storage      : $(st_name  "$(peek "$1" "$2" 8)")"
}

interactive() {
    f="$1"
    off=$(find_off "$f")
    if [ -z "$off" ]; then
        echo "$f: no A2CF config block - skipping"
        return
    fi
    while :; do
        show_config "$f" "$off"
        printf "Change which setting? (1-4, ENTER = done): "
        read c
        case "$c" in
            '') break ;;
            1)  echo "  1) auto  2) ui40  3) ui80m3  4) ui80m4"
                printf "UI mode (ENTER = keep): "; read v
                case "$v" in
                    1) poke "$f" "$off" 5 255 ;;
                    2) poke "$f" "$off" 5 0 ;;
                    3) poke "$f" "$off" 5 1 ;;
                    4) poke "$f" "$off" 5 2 ;;
                esac ;;
            2)  echo "  1) pokey  2) d280  3) d300  4) d500  5) d580  6) d600  7) d700"
                printf "Sound device (ENTER = keep): "; read v
                case "$v" in
                    [1-7]) poke "$f" "$off" 6 $(($v - 1)) ;;
                esac ;;
            3)  echo "  1) playapac  2) play80m3  3) play80m4"
                printf "Playback (ENTER = keep): "; read v
                case "$v" in
                    [1-3]) poke "$f" "$off" 7 $(($v - 1)) ;;
                esac ;;
            4)  echo "  1) auto  2) off"
                printf "Storage (ENTER = keep): "; read v
                case "$v" in
                    1) poke "$f" "$off" 8 0 ;;
                    2) poke "$f" "$off" 8 1 ;;
                esac ;;
        esac
    done
}

if [ -z "$1" ]; then
    dir=$(dirname "$0")
    found=0
    for name in AVFPLAY AV2PLAY.XEX bin/AVFPLAY bin/av2play.xex; do
        if [ -f "$dir/$name" ]; then
            interactive "$dir/$name"
            found=1
        fi
    done
    if [ "$found" = 0 ]; then
        echo "No AVFPLAY or AV2PLAY.XEX found next to this script."
        echo "Usage: $0 <file> [auto|ui40|ui80m3|ui80m4|.] [pokey|d280..d700|.] [playapac|play80m3|play80m4|.] [auto|off|.]"
    fi
    exit 0
fi

f="$1"
if [ ! -f "$f" ]; then
    echo "ERROR: file not found: $f"
    exit 1
fi
echo "WARNING: patching bytes inside '$f'. Only use this on av2play binaries"
echo "         (AVFPLAY / AV2PLAY.XEX); anything else will be damaged."
off=$(find_off "$f")
if [ -z "$off" ]; then
    echo "ERROR: no A2CF config block found - not an av2play binary?"
    exit 1
fi

if [ -z "$2" ]; then
    interactive "$f"
    exit 0
fi

case "$2" in
    auto)        poke "$f" "$off" 5 255 ;;
    ui40)        poke "$f" "$off" 5 0 ;;
    ui80|ui80m3) poke "$f" "$off" 5 1 ;;
    ui80m4)      poke "$f" "$off" 5 2 ;;
    -|.)         ;;
    *)  echo "ERROR: UI must be auto, ui40, ui80m3 or ui80m4"; exit 1 ;;
esac
case "$3" in
    pokey) poke "$f" "$off" 6 0 ;;
    d280)  poke "$f" "$off" 6 1 ;;
    d300)  poke "$f" "$off" 6 2 ;;
    d500)  poke "$f" "$off" 6 3 ;;
    d580)  poke "$f" "$off" 6 4 ;;
    d600)  poke "$f" "$off" 6 5 ;;
    d700)  poke "$f" "$off" 6 6 ;;
    ''|-|.)  ;;
    *)  echo "ERROR: SOUND must be pokey or d280/d300/d500/d580/d600/d700"; exit 1 ;;
esac
case "$4" in
    playapac|std) poke "$f" "$off" 7 0 ;;
    play80m3|m3)  poke "$f" "$off" 7 1 ;;
    play80m4|m4)  poke "$f" "$off" 7 2 ;;
    ''|-|.)       ;;
    *)  echo "ERROR: PLAYBACK must be playapac, play80m3 or play80m4"; exit 1 ;;
esac
case "$5" in
    auto) poke "$f" "$off" 8 0 ;;
    off)  poke "$f" "$off" 8 1 ;;
    ''|-|.) ;;
    *)  echo "ERROR: STORAGE must be auto or off"; exit 1 ;;
esac
show_config "$f" "$off"
