#!/bin/bash

# Crea el secreto con las credenciales de la base de datos H2.
# Termina en el primer comando que falle y muestra el error de ese comando.
set -e

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"

if [ ! -f "$PROJECT_ROOT/params.txt" ]; then
    echo "Error: falta params.txt. Ejecuta antes: bash params.sh <tu id>" >&2
    exit 1
fi

# TODO: Copia aquí, a mano, desde params.txt, el nombre del secreto y la contraseña de la base de datos.
SECRET_NAME=prod/anuncios/010503
DB_PASS=44f496e414bf85a68ba105e3

DB_USER="admin"
DB_NAME="anuncios"

# El JSON del secreto. Spring Boot lo importa y expone cada campo como propiedad (username, password y dbname),
# que son las que usa back/src/main/resources/application.properties para el datasource.
SECRET_JSON=$(printf '{"username":"%s","password":"%s","dbname":"%s"}' "$DB_USER" "$DB_PASS" "$DB_NAME")

echo -n "Creando el secreto '$SECRET_NAME'... "

# TODO Crea el secreto en Secrets Manager con el nombre $SECRET_NAME y el contenido de $SECRET_JSON.
# Pista: aws secretsmanager create-secret. No imprimas el valor del secreto.
aws secretsmanager create-secret --name prod/anuncios/010503 --secret-string $SECRET_JSON --output text >/dev/null
unset SECRET_JSON
echo "listo."
