#!/usr/bin/env bash
# ==============================================================================
# CTIA · Repositório Acadêmico do CTISM / UFSM
# Script de automação: Build & Run direto no Simulador iOS (Xcode)
# ==============================================================================

set -e

# Cores para terminal
CYAN='\033[0;36m'
GOLD='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}================================================================${NC}"
echo -e "${GOLD}   CTIA · Repositório Acadêmico do CTISM (UFSM)${NC}"
echo -e "${CYAN}   HackaTruck MakerSpace · Deploy Automático no Simulador iOS${NC}"
echo -e "${CYAN}================================================================${NC}"

# 1. Verifica se está rodando no macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}[ERRO] Este script requer o macOS com Xcode instalado.${NC}"
    echo "Para rodar em sua máquina:"
    echo "1. Clone este repositório no seu Mac;"
    echo "2. Abra a pasta e execute: ./run_simulator.sh ou dê duplo clique em RunInSimulator.command;"
    echo "3. Ou simplesmente abra 'CTIA.xcodeproj' no Xcode e pressione Cmd + R."
    exit 1
fi

# 2. Verifica se o Xcode está selecionado
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}[ERRO] xcodebuild não encontrado.${NC}"
    echo "Execute: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "\n${GOLD}[1/5] Procurando ou iniciando o Simulador iPhone...${NC}"

# Abre o aplicativo do Simulador
open -a Simulator

# Procura um simulador já aberto/booted
BOOTED_DEVICE=$(xcrun simctl list devices | grep "(Booted)" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\) \(Booted\)/\1/' || true)

if [ -z "$BOOTED_DEVICE" ]; then
    echo "Nenhum simulador ligado. Procurando iPhone 16 ou mais recente..."
    TARGET_DEVICE=$(xcrun simctl list devices available | grep -E "iPhone 16|iPhone 15|iPhone 14" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\) .*/\1/' || true)
    
    if [ -z "$TARGET_DEVICE" ]; then
        TARGET_DEVICE=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed -E 's/.* \(([A-F0-9-]+)\) .*/\1/' || true)
    fi
    
    if [ -z "$TARGET_DEVICE" ]; then
        echo -e "${RED}[ERRO] Nenhum simulador de iPhone disponível encontrado no Xcode.${NC}"
        exit 1
    fi
    
    echo "Iniciando simulador ID: $TARGET_DEVICE..."
    xcrun simctl boot "$TARGET_DEVICE" || true
    BOOTED_DEVICE="$TARGET_DEVICE"
else
    echo "Simulador ativo detectado: $BOOTED_DEVICE"
fi

echo -e "\n${GOLD}[2/5] Compilando o projeto CTIA no Xcode (xcodebuild)...${NC}"
BUILD_DIR="$PROJECT_DIR/build/DerivedData"

xcodebuild build \
    -project "$PROJECT_DIR/CTIA.xcodeproj" \
    -scheme "CTIA" \
    -destination "platform=iOS Simulator,id=$BOOTED_DEVICE" \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    -quiet

echo -e "${GREEN}✓ Compilação concluída com sucesso!${NC}"

echo -e "\n${GOLD}[3/5] Localizando o binário CTIA.app...${NC}"
APP_PATH=$(find "$BUILD_DIR" -name "CTIA.app" -type d | head -n 1)

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}[ERRO] Não foi possível localizar o binário compilado CTIA.app.${NC}"
    exit 1
fi
echo "App encontrado em: $APP_PATH"

echo -e "\n${GOLD}[4/5] Instalando CTIA no Simulador iPhone...${NC}"
xcrun simctl install "$BOOTED_DEVICE" "$APP_PATH"
echo -e "${GREEN}✓ CTIA instalado com sucesso no iPhone!${NC}"

echo -e "\n${GOLD}[5/5] Abrindo o app CTIA...${NC}"
xcrun simctl launch "$BOOTED_DEVICE" "br.ufsm.ctism.ctia"

# Traz a janela do Simulador para o primeiro plano
osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}✓ SUCESSO! O CTIA está aberto e rodando no seu Simulador iPhone.${NC}"
echo -e "${CYAN}Você também pode abrir o 'CTIA.xcodeproj' no Xcode e pressionar Cmd + R.${NC}"
echo -e "${GREEN}================================================================${NC}"
