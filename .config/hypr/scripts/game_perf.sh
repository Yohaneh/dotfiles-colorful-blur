#!/usr/bin/env bash

# --- Configurações PS120EVO ---
export SDL_VIDEO_WAYLAND_WMCLASS="PS120EVO"
HYPR_GAMEMODE_STATE="/tmp/hypr_gamemode_active"
WALLPAPER_FLAG="$HOME/.disable-random-wallpaper"

# Função para ATIVAR otimizações
enable_gamemode() {
    # 1. Hyprland: Desativa firulas visuais para maximizar FPS
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword animation borderangle,0; \
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:fullscreen_opacity 1;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0" > /dev/null

    # 2. Matar a Waybar (Libera processamento e espaço em tela)
    pkill waybar 2>/dev/null
    echo "[$(date)] enable_gamemode: pkill waybar (exit: $?)" >> /tmp/gamemode_debug.log

    # 3. Ordem de hibernação para o script de Wallpaper (Mata o swww via Python)
    touch "$WALLPAPER_FLAG"
    echo "[$(date)] enable_gamemode: flag de wallpaper ativada" >> /tmp/gamemode_debug.log

    # 4. Criar arquivo temporário de estado
    touch "$HYPR_GAMEMODE_STATE"
    notify-send "PS120EVO" "Gamemode ATIVADO (Waybar OFF, SWWW OFF)" -i controller
}

# Função para DESATIVAR otimizações
disable_gamemode() {
    # 1. Hyprland: Recarrega as configurações originais
    hyprctl reload > /dev/null

    # 2. Relançar a Waybar
    waybar &
    echo "[$(date)] disable_gamemode: relançando waybar" >> /tmp/gamemode_debug.log

    # 3. Ordem de despertar para o script de Wallpaper (Revive o swww)
    rm -f "$WALLPAPER_FLAG"
    echo "[$(date)] disable_gamemode: flag de wallpaper removida" >> /tmp/gamemode_debug.log

    # 4. Remover arquivo de estado
    rm -f "$HYPR_GAMEMODE_STATE"
    notify-send "PS120EVO" "Gamemode DESATIVADO (Sistema Restaurado)" -i controller
}

# --- Lógica Principal ---

if [ $# -eq 0 ]; then
    if [ ! -f "$HYPR_GAMEMODE_STATE" ]; then
        enable_gamemode
    else
        disable_gamemode
    fi
    exit 0
fi

# Se chamado com argumentos (ex: Steam)
enable_gamemode
"$@"
disable_gamemode