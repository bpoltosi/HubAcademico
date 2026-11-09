#!/usr/bin/env bash
# ==============================================================================
# CTIA · Repositório Acadêmico do CTISM
# Script de automação: Build and Run direto no Simulador do iPhone (macOS)
# HackaTruck MakerSpace · Deploy 26.1
# ==============================================================================

set -e

echo "🚀 Iniciando Build and Run do aplicativo CTIA..."

# 1. Verifica ambiente macOS e ferramentas do Xcode
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "⚠️  Nota: A execução nativa de simuladores iOS requer macOS com Xcode instalado."
  echo "ℹ️  No Linux ou ambiente Web, utilize o Simulador Interativo integrado na porta 3000."
  exit 0
fi

if ! command -v xcodebuild &> /dev/null; then
  echo "❌ Xcode Command Line Tools não encontrados. Execute: xcode-select --install"
  exit 1
fi

# 2. Localiza um simulador de iPhone disponível (prioriza iPhone 16 ou iPhone 15)
echo "📱 Localizando Simulador do iPhone..."
DEVICE_NAME=$(xcrun simctl list devices available | grep -E "iPhone 16|iPhone 15" | head -n 1 | sed -E 's/^[[:space:]]+//' | sed -E 's/ \([A-F0-9-]+\).*//')

if [ -z "$DEVICE_NAME" ]; then
  DEVICE_NAME=$(xcrun simctl list devices available | grep "iPhone" | head -n 1 | sed -E 's/^[[:space:]]+//' | sed -E 's/ \([A-F0-9-]+\).*//')
fi

if [ -z "$DEVICE_NAME" ]; then
  DEVICE_NAME="iPhone 16"
fi

DEVICE_ID=$(xcrun simctl list devices available | grep "$DEVICE_NAME" | head -n 1 | grep -o -E '[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}')

echo "📱 Simulador selecionado: $DEVICE_NAME ($DEVICE_ID)"

# 3. Inicializa o Simulador
echo "⏳ Abrindo o aplicativo Simulator..."
open -a Simulator
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

# 4. Compila o projeto com xcodebuild
echo "🔨 Compilando CTIA (SwiftUI) para iOS Simulator..."
DERIVED_DATA_PATH="./build/DerivedData"

if [ -d "CTIA.xcodeproj" ]; then
  xcodebuild -project CTIA.xcodeproj \
    -scheme CTIA \
    -destination "id=$DEVICE_ID" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -configuration Debug \
    build
else
  echo "Compilando via Swift Package Manager..."
  swift build -c debug
fi

# 5. Localiza e instala o binário CTIA.app
APP_PATH=$(find "$DERIVED_DATA_PATH" -name "CTIA.app" -type d 2>/dev/null | head -n 1)

if [ -n "$APP_PATH" ]; then
  echo "📦 Instalando CTIA.app no simulador..."
  xcrun simctl install "$DEVICE_ID" "$APP_PATH"
  
  echo "🎉 Abrindo CTIA no simulador do iPhone..."
  xcrun simctl launch "$DEVICE_ID" br.ufsm.ctism.ctia
  
  echo "✅ Sucesso! CTIA está aberto e instalado no simulador ($DEVICE_NAME)."
else
  echo "ℹ️  Build concluído com sucesso. Para rodar, abra CTIA.xcodeproj no Xcode e pressione Cmd + R."
fi
