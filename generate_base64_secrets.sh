#!/bin/bash
echo "=== SECRETOS PARA GITHUB ACTIONS ==="
echo ""
echo "1. FIREBASE_JSON_BASE64"
base64 -w 0 android/app/google-services.json
echo ""
echo ""
echo "2. KEY_PROPERTIES_BASE64"
base64 -w 0 android/key.properties
echo ""
echo ""
echo "3. KEYSTORE_BASE64"
# Necesitamos encontrar el archivo .jks o .keystore primero
JKS_FILE=$(find android/app -name "*.jks" -o -name "*.keystore" | head -n 1)
if [ -n "$JKS_FILE" ]; then
  base64 -w 0 $JKS_FILE
else
  echo "NO SE ENCONTRÓ NINGÚN ARCHIVO .jks en android/app/"
fi
echo ""
echo "====================================="
