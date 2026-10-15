#!/bin/bash

# Crea el User Pool de Cognito, su App Client, el grupo y el usuario de prueba.
# Termina en el primer comando que falle y muestra el error de ese comando.
set -e

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"

if [ ! -f "$PROJECT_ROOT/params.txt" ]; then
    echo "Error: falta params.txt. Ejecuta antes: bash params.sh <tu id>" >&2
    exit 1
fi

# TODO: Copia aquí, a mano, desde params.txt, el usuario del examen y su contraseña.
EXAM_USER_PASS=Corr-cf50d2c0-A1
EXAM_USER=corrector

# TODO: El User Pool se llama `anuncios-pool` y su App Client `anuncios-front`.
# Escribe esos nombres en los comandos `create-user-pool` y `create-user-pool-client`.

FRONT_CONFIG="$PROJECT_ROOT/front/config.js"
SPRING_CONFIG="$PROJECT_ROOT/back/src/main/resources/cognito.properties"

AWS_REGION="$(aws configure get region)"

echo -n "Creando User Pool... "
USER_POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name anuncios-pool \
    --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
    --query "UserPool.Id" \
    --output text)
echo "listo."

# El cliente inicia sesión con usuario y contraseña directamente contra Cognito (USER_PASSWORD_AUTH)
# y puede renovar el token (refresh).
AUTH_FLOWS="ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH"

echo -n "Creando App Client... "
# --no-generate-secret: cliente público, el secreto quedaría visible en el navegador
# shellcheck disable=SC2086
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$USER_POOL_ID" \
    --client-name anuncios-front \
    --no-generate-secret \
    --explicit-auth-flows $AUTH_FLOWS \
    --query "UserPoolClient.ClientId" \
    --output text)
echo "listo."

echo -n "Creando el usuario '$EXAM_USER'... "
aws cognito-idp admin-create-user \
    --user-pool-id "$USER_POOL_ID" \
    --username "$EXAM_USER" \
    --message-action SUPPRESS \
    --output text >/dev/null
aws cognito-idp admin-set-user-password \
    --user-pool-id "$USER_POOL_ID" \
    --username "$EXAM_USER" \
    --password "$EXAM_USER_PASS" \
    --permanent
echo "listo."

cat > "$SPRING_CONFIG" <<CONF
# Generado por aws-scripts/cognito.sh. No editar a mano.
spring.security.oauth2.resourceserver.jwt.issuer-uri=https://cognito-idp.$AWS_REGION.amazonaws.com/$USER_POOL_ID
CONF

cat > "$FRONT_CONFIG" <<CONF
// Generado por aws-scripts/cognito.sh. No editar a mano.
window.COGNITO_CONFIG = { region: "$AWS_REGION", clientId: "$CLIENT_ID" };
CONF

echo "Configuración de Cognito finalizada."
