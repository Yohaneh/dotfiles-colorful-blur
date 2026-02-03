#!/usr/bin/env bash

# --- Configurações PS120EVO ---
export SDL_VIDEO_WAYLAND_WMCLASS="PS120EVO"
HYPR_GAMEMODE_STATE="/tmp/hypr_gamemode_active"

# Caminho absoluto do script de wallpaper (ajuste se necessário)
WALLPAPER_SCRIPT="$HOME/.config/hypr/scripts/wl-random-wallpaper-matugen.sh"

# Função para ATIVAR otimizações
enable_gamemode() {
    # 1. Hyprland: Desativa firulas visuais
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

    # 2. Matar o script de wallpaper aleatório (processo Python)
    pkill -f "wl-random-wallpaper-matugen" 2>/dev/null
    echo "[$(date)] enable_gamemode: pkill wl-random-wallpaper (exit: $?)" >> /tmp/gamemode_debug.log

    # 3. Matar o swww-daemon (libera a GPU de renderizar wallpaper)
    pkill -f "swww-daemon" 2>/dev/null
    echo "[$(date)] enable_gamemode: pkill swww-daemon (exit: $?)" >> /tmp/gamemode_debug.log

    # 4. Criar arquivo temporário de estado
    touch "$HYPR_GAMEMODE_STATE"
    notify-send "PS120EVO" "Gamemode ATIVADO" -i controller
}

# Função para DESATIVAR otimizações
disable_gamemode() {
    # 1. Hyprland: Recarrega as configurações originais
    hyprctl reload > /dev/null

    # 2. Relançar o script de wallpaper (ele lança o swww-daemon sozinho se precisar)
    if [ -f "$WALLPAPER_SCRIPT" ]; then
        echo "[$(date)] disable_gamemode: relançando wallpaper script" >> /tmp/gamemode_debug.log
        python3 "$WALLPAPER_SCRIPT" &
    else
        echo "[$(date)] disable_gamemode: SCRIPT NÃO ENCONTRADO em $WALLPAPER_SCRIPT" >> /tmp/gamemode_debug.log
    fi

    # 3. Remover arquivo de estado
    rm -f "$HYPR_GAMEMODE_STATE"
    notify-send "PS120EVO" "Gamemode DESATIVADO" -i controller
}

# --- Lógica Principal ---

# Se o script for chamado SEM argumentos (pelo seu script de gatilho)
if [ $# -eq 0 ]; then
    if [ ! -f "$HYPR_GAMEMODE_STATE" ]; then
        enable_gamemode
    else
        disable_gamemode
    fi
    exit 0
fi

# Se o script for chamado COM argumentos (ex: pela Steam)
# Ele vai gerenciar o Power Profile E o visual do Hyprland

enable_gamemode

# Verifica PowerProfiles (CachyOS/Performance)
if command -v powerprofilesctl &>/dev/null && powerprofilesctl list | grep -q 'performance:'; then
    # Executa com performance e inibidor de suspensão
    systemd-inhibit --why "PS120EVO Gaming" \
        powerprofilesctl launch -p performance \
        -r "Launched with PS120EVO Performance Utility" -- "$@"
else
    # Executa o jogo normalmente se não tiver powerprofilesctl
    "$@"
fi

# Quando o jogo fechar, ele executa isso:
disable_gamemode