#!/bin/bash

TOTAL_BLOCKS=10

VOLUME_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$VOLUME_RAW" | awk '{printf "%d", $2 * 100}')
MUTED=$(echo "$VOLUME_RAW" | grep -q MUTED && echo true || echo false)

if [ "$MUTED" = "true" ]; then
    ICON="  "
    BAR=$(printf '░%.0s' $(seq 1 $TOTAL_BLOCKS))
    TEXT="Mutado"
else
    if [ "$VOLUME" -lt 30 ]; then
        ICON=" "
    elif [ "$VOLUME" -lt 70 ]; then
        ICON=" "
    else
        ICON=" "
    fi

    # Número de blocos completos
    FILLED=$(( VOLUME / 10 ))
    # Resto para blocos meio cheios
    REMAINDER=$(( VOLUME % 10 ))

    BAR=""

    # Blocos completos
    for ((i=0; i<FILLED; i++)); do
        BAR+="▓"
    done

    # Bloco meio cheio se o resto for >=5
    if [ "$REMAINDER" -ge 5 ]; then
        BAR+="▒"
        FILLED=$(( FILLED + 1 ))
    fi

    # Blocos vazios restantes
    for ((i=FILLED; i<TOTAL_BLOCKS; i++)); do
        BAR+="░"
    done

    TEXT="$BAR $VOLUME%"
fi

notify-send -u low -h string:x-canonical-private-synchronous:volume "$ICON $TEXT"

