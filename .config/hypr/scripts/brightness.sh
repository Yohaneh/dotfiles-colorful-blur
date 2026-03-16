#!/bin/bash

# ============================================================
# PS120EVO - v7: Debounce Longo (Estabilidade Máxima)
# ============================================================

STATE_FILE="/tmp/brightness_level"
BUS_ID="7"
TOTAL_BLOCKS=20
STEP=5
DELAY="0.8" # Delay aumentado para estabilizar a roleta

# 1. Gestão de Estado (Arquivo Temporário)
if [ ! -f "$STATE_FILE" ]; then
    CURRENT=$(ddcutil getvcp 10 --bus "$BUS_ID" --terse 2>/dev/null | awk '{print $4}' | grep -oE '^[0-9]+$')
    [ -z "$CURRENT" ] && CURRENT=50
    echo "$CURRENT" > "$STATE_FILE"
else
    CURRENT=$(grep -oE '^[0-9]+$' "$STATE_FILE" || echo 50)
fi

# 2. Cálculo do Novo Valor
case "$1" in
    up)   NEW=$(( CURRENT + STEP )) ;;
    down) NEW=$(( CURRENT - STEP )) ;;
    *)    NEW=$1 ;;
esac

(( NEW > 100 )) && NEW=100
(( NEW < 0 )) && NEW=0
echo "$NEW" > "$STATE_FILE"

# 3. Interface Visual Instantânea (Estilo vol_change.sh)
[ "$NEW" -lt 30 ] && ICON="󰃞 " || { [ "$NEW" -lt 70 ] && ICON="󰃟 " || ICON="󰃠 "; }
FILLED=$(( NEW * TOTAL_BLOCKS / 100 ))
EMPTY=$(( TOTAL_BLOCKS - FILLED ))
BAR="$(printf "%${FILLED}s" | sed "s/ /━/g")$(printf "%${EMPTY}s" | sed "s/ /─/g")"

notify-send -u low -t 1000 \
    -h string:x-canonical-private-synchronous:brightness \
    -h boolean:transient:true \
    "$ICON $NEW% $BAR"

# 4. O Processo de "Confirmação" (Hardware)
# Mata qualquer agendamento de brilho anterior que ainda esteja esperando o 'sleep'
pkill -f "sleep $DELAY && ddcutil" 2>/dev/null

(
    # Aguarda o silêncio da roleta
    sleep "$DELAY"
    
    # Limpa qualquer ddcutil que possa ter travado por erro de I2C/Lock
    pkill -9 ddcutil 2>/dev/null
    
    # Aplica o valor final de uma vez só
    ddcutil setvcp 10 "$NEW" --bus "$BUS_ID" --noverify --sleep-multiplier .5 > /dev/null 2>&1
) &