#!/bin/bash

# ============================================================
# Script de Controle de Brilho via ddcutil
# Uso: ./ajusta_brilho.sh [up|down|valor]
# Ex: ./ajusta_brilho.sh up    (Aumenta o brilho)
# Ex: ./ajusta_brilho.sh 50    (Define brilho para 50%)
# ============================================================

# Configuração do passo (quanto aumenta/diminui por vez)
STEP=10

# Função para exibir ajuda
function show_help {
    echo "Uso: $0 {up | down | <número 0-100>}"
    exit 1
}

# Verifica se o ddcutil está instalado
if ! command -v ddcutil &> /dev/null; then
    echo "Erro: ddcutil não está instalado."
    exit 1
fi

# Argumento de entrada
ARG=$1

if [ -z "$ARG" ]; then
    show_help
fi

# Lógica de controle
# O código 10 é o padrão VCP para Brilho (Brightness)
if [ "$ARG" == "up" ]; then
    echo "Aumentando brilho em $STEP%..."
    ddcutil setvcp 10 + $STEP --noverify
elif [ "$ARG" == "down" ]; then
    echo "Diminuindo brilho em $STEP%..."
    ddcutil setvcp 10 - $STEP --noverify
elif [[ "$ARG" =~ ^[0-9]+$ ]] && [ "$ARG" -ge 0 ] && [ "$ARG" -le 100 ]; then
    echo "Definindo brilho para $ARG%..."
    ddcutil setvcp 10 $ARG --noverify
else
    show_help
fi

# Opcional: Mostra o valor atual após a mudança
# Nota: Isso pode deixar o script um pouco mais lento
# current=$(ddcutil getvcp 10 --terse | awk '{print $4}')
# echo "Brilho atual: $current%"