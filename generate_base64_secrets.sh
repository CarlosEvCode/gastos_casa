#!/bin/bash

echo "Generando secretos base64..."

base64 -w 0 android/app/google-services.json > firebase_base64.txt
base64 -w 0 android/key.properties > keyproperties_base64.txt

JKS_FILE=$(find android/app -name "*.jks" -o -name "*.keystore" | head -n 1)

if [ -n "$JKS_FILE" ]; then
  base64 -w 0 "$JKS_FILE" > keystore_base64.txt
else
  echo "No se encontró archivo keystore"
fi

echo ""
echo "Archivos generados:"
echo "firebase_base64.txt"
echo "keyproperties_base64.txt"
echo "keystore_base64.txt"