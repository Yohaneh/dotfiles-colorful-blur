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
WALLPAPER_DIRECTORY = os.path.expanduser("~/.config/hypr/wallpapers")
CACHE_DIRECTORY = os.path.expanduser("~/.cache/hypr_wallpaper_frames")
WAYBAR_CSS_PATH = os.path.expanduser("~/.config/waybar/colors.css")

# Garante que o Python encontre os binários em pastas comuns de usuário
os.environ["PATH"] += os.pathsep + os.path.expanduser("~/.local/bin") + os.pathsep + os.path.expanduser("~/.cargo/bin")

os.makedirs(CACHE_DIRECTORY, exist_ok=True)

def log(msg):
    """Log formatado para a classe PS120EVO."""
    print(f"[PS120EVO] {msg}")
    sys.stdout.flush()

def find_closest_papirus_color(target_hex):
    """Detecta a cor do Papirus baseada na Matiz (Hue)."""
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
    """Lê a cor principal gerada pelo Matugen."""
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
    """Atualiza componentes do sistema após a troca do wallpaper."""
    log("Executando hooks de interface...")
    # Recarrega Kitty (SIGUSR1) e SwayNC
    subprocess.run(["killall", "-10", "kitty"], stderr=subprocess.DEVNULL)
    subprocess.run(["swaync-client", "-rs"], stderr=subprocess.DEVNULL)
    
    # Atualiza ícones Papirus
    color = get_accent_from_css()
    log(f"Aplicando cor '{color}' aos ícones Papirus.")
    subprocess.Popen(["papirus-folders", "-t", "Papirus", "--color", color], stdout=subprocess.DEVNULL)

def generate_matugen(image_path):
    """Gera o tema de cores usando Matugen."""
    log(f"Matugen processando: {os.path.basename(image_path)}")
    res = subprocess.run(["matugen", "image", image_path, "-m", "dark"], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    if res.returncode == 0:
        run_post_hooks()
    else:
        log(f"Erro no Matugen: {res.stderr.decode()}")

def set_wallpaper():
    """Sorteia e aplica o wallpaper nos monitores ativos."""
    if os.path.exists(os.path.expanduser("~/.disable-random-wallpaper")):
        log("Script pausado via flag file (~/.disable-random-wallpaper)")
        return

    valid_exts = ('.png', '.jpg', '.jpeg', '.gif', '.webp')
    wallpapers = [str(f) for f in Path(WALLPAPER_DIRECTORY).glob("*") if f.suffix.lower() in valid_exts]
    
    if not wallpapers:
        log(f"Erro: Nenhum wallpaper encontrado em {WALLPAPER_DIRECTORY}")
        return

    chosen = random.choice(wallpapers)
    log(f"Novo wallpaper: {os.path.basename(chosen)}")

    try:
        # Detecta monitores via hyprctl
        monitors_out = subprocess.check_output(["hyprctl", "monitors"], stderr=subprocess.STDOUT).decode()
        monitors = [line.split()[1] for line in monitors_out.splitlines() if "Monitor" in line]
        
        for m in monitors:
            log(f"Aplicando em monitor {m}")
            subprocess.run(["swww", "img", chosen, "-o", m, "--transition-type", "grow", "--transition-fps", "144"])
        
        # Inicia geração de cores em segundo plano
        threading.Thread(target=generate_matugen, args=(chosen,), daemon=True).start()
        
    except Exception as e:
        log(f"Falha ao aplicar wallpaper: {e}")

def signal_handler(sig, frame):
    log("Encerrando serviço PS120EVO... Limpando processos.")
    subprocess.run(["pkill", "swww-daemon"], stderr=subprocess.DEVNULL)
    sys.exit(0)

# Registra o sinal de interrupção (Ctrl+C)
signal.signal(signal.SIGINT, signal_handler)

if __name__ == "__main__":
    log("Iniciando serviço de Wallpaper PS120EVO...")
    
    # 1. Mata qualquer instância existente (limpeza preventiva)
    log("Limpando processos swww antigos...")
    subprocess.run(["pkill", "-9", "swww-daemon"], stderr=subprocess.DEVNULL)
    
    # 2. Remove arquivos de socket que impedem o novo daemon de subir
    uid = os.getuid()
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{uid}")
    # Remove especificamente o arquivo que causou seu erro anterior
    subprocess.run(f"rm -rf {runtime_dir}/swww*", shell=True)
    subprocess.run(f"rm -rf {runtime_dir}/wayland-1-swww-daemon..sock", shell=True)

    # Pequena pausa para o sistema liberar os arquivos
    time.sleep(0.5)

    # 3. Inicia o Daemon do zero
    log("Iniciando nova instância do swww-daemon...")
    # Usamos shell=True ou passamos as envs para garantir que o Wayland o reconheça
    subprocess.Popen(["swww-daemon"], env=os.environ.copy())

    def wait_for_daemon():
        """Verifica se o novo socket está pronto."""
        for _ in range(20):
            check = subprocess.run(["swww", "query"], capture_output=True)
            if check.returncode == 0:
                log("Daemon sincronizado e pronto.")
                return True
            time.sleep(0.5)
        return False

    if wait_for_daemon():
        while True:
            set_wallpaper()
            time.sleep(TIME)
    else:
        log("ERRO: O daemon não subiu mesmo após o reset total.")
        sys.exit(1)