#!/bin/bash

# Lista de players ativos, ignorando o Firefox
player=$(playerctl -l 2>/dev/null | grep -v firefox | head -n 1)

# Sai se não houver player ou se for vazio
if [[ -z "$player" ]]; then
    exit 0
fi

status=$(playerctl -p "$player" status 2>/dev/null)

# Sai se não estiver tocando ou pausado
if [[ "$status" != "Playing" && "$status" != "Paused" ]]; then
    exit 0
fi

# Ícones MDI
case "$status" in
    "Playing")
        icon="󰐊"
        ;;
    "Paused")
        icon="󰏦"
        ;;
esac

# Metadados
title="$(playerctl -p "$player" metadata title 2>/dev/null)"
artist="$(playerctl -p "$player" metadata artist 2>/dev/null)"
album="$(playerctl -p "$player" metadata album 2>/dev/null)"

# Truncamento com reticências
max_length=30
short_title="$title"
if [[ ${#title} -gt $max_length ]]; then
    short_title="${title:0:$((max_length - 1))}…"
fi

# Função para escapar JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Monta texto e tooltip
text="$icon $short_title $artist"
tooltip="$(escape_json "$title - $artist - $album")"
text_escaped="$(escape_json "$text")"

# Saída JSON
echo "{\"text\": \"$text_escaped\", \"tooltip\": \"$tooltip\"}"

