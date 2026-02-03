#!/bin/bash

TOTAL_BLOCKS=20 # Reduzido para evitar o corte (reticências)
VOLUME_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOLUME=$(echo "$VOLUME_RAW" | awk '{printf "%d", $2 * 100}')
MUTED=$(echo "$VOLUME_RAW" | grep -q MUTED && echo true || echo false)

if [ "$MUTED" = "true" ]; then
    ICON=" "
    BAR=" [ MUTADO ]"
else
    [ "$VOLUME" -lt 30 ] && ICON=" " || { [ "$VOLUME" -lt 70 ] && ICON=" " || ICON=" "; }
    
    # Cálculo preciso para não estourar a largura
    FILLED=$(( VOLUME * TOTAL_BLOCKS / 100 ))
    EMPTY=$(( TOTAL_BLOCKS - FILLED ))

    # Caractere sólido para preenchimento e sutil para o fundo
    BAR_FILLED=$(printf "%${FILLED}s" | sed "s/ /━/g")
    BAR_EMPTY=$(printf "%${EMPTY}s" | sed "s/ /─/g") # Traço fino no fundo para ver o limite
    
    BAR="$BAR_FILLED$BAR_EMPTY"
fi

notify-send -u low -t 1500 -h string:x-canonical-private-synchronous:volume \
    "$ICON $VOLUME% $BAR"