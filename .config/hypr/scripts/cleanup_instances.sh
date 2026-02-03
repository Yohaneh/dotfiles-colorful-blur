#!/bin/bash

# Script de limpeza para matar todas as instâncias e resetar o wallpaper manager

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║       🧹 Limpeza de Instâncias - Wallpaper Manager       ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 1. Mata scripts Python de wallpaper
echo "1️⃣  Matando scripts Python de wallpaper..."
pkill -f 'python.*wallpaper' 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✓ Scripts Python terminados"
else
    echo "   • Nenhum script Python de wallpaper rodando"
fi

# 2. Mata swww-daemon (será reiniciado depois)
echo ""
echo "2️⃣  Matando swww-daemon..."
killall swww-daemon 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✓ swww-daemon terminado"
    sleep 1
else
    echo "   • swww-daemon não estava rodando"
fi

# 3. Remove lockfile
echo ""
echo "3️⃣  Removendo lockfile..."
if [ -f /tmp/wallpaper_manager.lock ]; then
    rm /tmp/wallpaper_manager.lock
    echo "   ✓ Lockfile removido"
else
    echo "   • Lockfile não existe"
fi

# 4. Reinicia swww-daemon
echo ""
echo "4️⃣  Reiniciando swww-daemon..."
swww-daemon &
sleep 2

if pidof swww-daemon > /dev/null; then
    echo "   ✓ swww-daemon iniciado (PID: $(pidof swww-daemon))"
else
    echo "   ✗ Erro ao iniciar swww-daemon"
    exit 1
fi

# 5. Verifica estado final
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ LIMPEZA CONCLUÍDA"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Estado atual:"
echo "  • swww-daemon: $(pidof swww-daemon | wc -w) instância(s)"
echo "  • Scripts de wallpaper: $(pgrep -f 'python.*wallpaper' | wc -l) instância(s)"
echo "  • Lockfile: $([ -f /tmp/wallpaper_manager.lock ] && echo 'existe' || echo 'não existe')"
echo ""
echo "💡 Agora você pode iniciar o script novamente:"
echo "   python wallpaper_manager_fixed.py"
echo ""
