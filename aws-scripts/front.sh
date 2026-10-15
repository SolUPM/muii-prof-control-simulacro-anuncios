#!/bin/bash

# Publica el front estático en /var/www/html de la instancia (Ubuntu).
# Termina en el primer comando que falle y muestra el error de ese comando.
set -e

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"

if [ ! -f "$PROJECT_ROOT/params.txt" ]; then
    echo "Error: falta params.txt. Ejecuta antes: bash params.sh <tu id>" >&2
    exit 1
fi

KEY_PATH="$PROJECT_ROOT/ssh-key/labsuser.pem"
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: No se encontró la clave SSH en: $KEY_PATH" >&2
    exit 1
fi

# TODO: Copia aquí, a mano, la IP pública de la instancia.
PUBLIC_IP=100.51.132.57

FRONT_PATH="$PROJECT_ROOT/front"

echo -n "Subiendo el front a $PUBLIC_IP... "
ssh -T -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@"$PUBLIC_IP" "rm -rf /tmp/front && mkdir /tmp/front"
scp -q -o StrictHostKeyChecking=no -i "$KEY_PATH" "$FRONT_PATH"/* ubuntu@"$PUBLIC_IP":/tmp/front/

ssh -T -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@"$PUBLIC_IP" << 'ENDSSH'
set -e
sudo rm -rf /var/www/html/*
sudo mv /tmp/front/* /var/www/html/
sudo rm -rf /tmp/front
sudo chown -R www-data:www-data /var/www/html
ENDSSH
echo "listo."

echo "Despliegue del front finalizado:"
echo "  http://$PUBLIC_IP/"
