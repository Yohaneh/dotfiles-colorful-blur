#!/usr/bin/env python3

import os
import random
import subprocess
import time
import threading
import re
import colorsys
import sys
from pathlib import Path
import signal

# --- CONFIGURAÇÕES PS120EVO ---
TIME = 120
CHECK_INTERVAL = 2 # Tempo (em seg) que o script checa se o Gamemode foi ativado
WALLPAPER_DIRECTORY = os.path.expanduser("~/.config/hypr/wallpapers")
CACHE_DIRECTORY = os.path.expanduser("~/.cache/hypr_wallpaper_frames")
WAYBAR_CSS_PATH = os.path.expanduser("~/.config/waybar/colors.css")
GAMEMODE_FLAG = os.path.expanduser("~/.disable-random-wallpaper")

# Garante que o Python encontre os binários
os.environ["PATH"] += os.pathsep + os.path.expanduser("~/.local/bin") + os.pathsep + os.path.expanduser("~/.cargo/bin")

os.makedirs(CACHE_DIRECTORY, exist_ok=True)

def log(msg):
    """Log formatado para a classe PS120EVO."""
    print(f"[PS120EVO] {msg}")
    sys.stdout.flush()

def find_closest_papirus_color(target_hex):
    # [Mantido igual ao seu original]
    try:
        hex_str = target_hex.lstrip('#')
        r, g, b = tuple(int(hex_str[i:i+2], 16)/255 for i in (0, 2, 4))
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        hue = h * 360
        if s < 0.15: return "grey"
        if v < 0.15: return "black"
        if hue < 15 or hue >= 330: return "red"
        if hue < 45: return "orange"
        if hue < 70: return "yellow"
        if hue < 160: return "green" if s > 0.4 else "nordic"
        if hue < 190: return "cyan"
        if hue < 260: return "blue" if s > 0.5 else "indigo"
        if hue < 290: return "violet"
        return "magenta"
    except:
        return "blue"

def get_accent_from_css():
    # [Mantido igual ao seu original]
    try:
        if os.path.exists(WAYBAR_CSS_PATH):
            with open(WAYBAR_CSS_PATH, 'r') as f:
                content = f.read()
                match = re.search(r'@define-color\s+accent_color\s+(#[0-9a-fA-F]{6});', content)
                if match:
                    return find_closest_papirus_color(match.group(1))
    except Exception as e:
        log(f"Erro ao ler CSS: {e}")
    return "blue"

def run_post_hooks():
    log("Executando hooks de interface...")
    subprocess.run(["killall", "-10", "kitty"], stderr=subprocess.DEVNULL)
    subprocess.run(["swaync-client", "-rs"], stderr=subprocess.DEVNULL)
    color = get_accent_from_css()
    log(f"Aplicando cor '{color}' aos ícones Papirus.")
    subprocess.Popen(["papirus-folders", "-t", "Papirus", "--color", color], stdout=subprocess.DEVNULL)

def generate_matugen(image_path):
    log(f"Matugen processando: {os.path.basename(image_path)}")
    res = subprocess.run(["matugen", "image", image_path, "-m", "dark"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if res.returncode == 0:
        run_post_hooks()
    else:
        log(f"Erro no Matugen: {res.stderr.decode()}")

def set_wallpaper():
    """Aplica o wallpaper com máxima eficiência e sem picos de GPU."""
    # Focado apenas em imagens estáticas
    #valid_exts = ('.png', '.jpg', '.jpeg')
    valid_exts = ('.png', '.jpg', '.jpeg', '.gif', '.webp')
    wallpapers = [str(f) for f in Path(WALLPAPER_DIRECTORY).glob("*") if f.suffix.lower() in valid_exts]
    
    if not wallpapers:
        log(f"Erro: Nenhum wallpaper encontrado em {WALLPAPER_DIRECTORY}")
        return

    chosen = random.choice(wallpapers)
    log(f"Novo wallpaper: {os.path.basename(chosen)}")

    try:
        # Transição fade simples a 60fps para evitar picos na GPU
        subprocess.run(["swww", "img", chosen, "--transition-type", "fade", "--transition-fps", "60", "--transition-duration", "1"])
        threading.Thread(target=generate_matugen, args=(chosen,), daemon=True).start()
    except Exception as e:
        log(f"Falha ao aplicar wallpaper: {e}")

def kill_daemon_aggressively():
    """Mata o daemon e limpa o terreno para liberar VRAM."""
    subprocess.run(["pkill", "-9", "swww-daemon"], stderr=subprocess.DEVNULL)
    uid = os.getuid()
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{uid}")
    subprocess.run(f"rm -rf {runtime_dir}/swww*", shell=True)
    subprocess.run(f"rm -rf {runtime_dir}/wayland-1-swww-daemon..sock", shell=True)

def wait_for_daemon():
    for _ in range(20):
        check = subprocess.run(["swww", "query"], capture_output=True)
        if check.returncode == 0:
            return True
        time.sleep(0.5)
    return False

def signal_handler(sig, frame):
    log("Encerrando serviço PS120EVO...")
    kill_daemon_aggressively()
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

if __name__ == "__main__":
    log("Iniciando serviço de Wallpaper PS120EVO...")
    kill_daemon_aggressively()
    time.sleep(0.5)
    
    subprocess.Popen(["swww-daemon"], env=os.environ.copy())
    if not wait_for_daemon():
        log("ERRO: O daemon não subiu.")
        sys.exit(1)

    log("Daemon sincronizado e pronto.")
    
    # Máquina de estados para controle instantâneo
    swww_is_alive = True
    wallpaper_timer = TIME # Força a primeira execução imediata

    while True:
        # 1. Verifica se o Gamemode está ativo
        if os.path.exists(GAMEMODE_FLAG):
            if swww_is_alive:
                log("GAMEMODE DETECTADO: Aniquilando swww-daemon para liberar recursos da GPU...")
                kill_daemon_aggressively()
                swww_is_alive = False
            
            # Trava o timer para que troque o wallpaper assim que o jogo fechar
            wallpaper_timer = TIME 
        
        # 2. Operação Normal
        else:
            if not swww_is_alive:
                log("GAMEMODE ENCERRADO: Revivendo swww-daemon...")
                subprocess.Popen(["swww-daemon"], env=os.environ.copy())
                if wait_for_daemon():
                    swww_is_alive = True
                else:
                    log("ERRO ao reviver daemon.")
            
            # Só troca se o daemon estiver rodando e o tempo tiver passado
            if swww_is_alive and wallpaper_timer >= TIME:
                set_wallpaper()
                wallpaper_timer = 0
            
            # Incrementa o timer do wallpaper
            wallpaper_timer += CHECK_INTERVAL
            
        # Dorme curto para manter a responsividade aos jogos
        time.sleep(CHECK_INTERVAL)