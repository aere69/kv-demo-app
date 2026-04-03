az login
export KEYVAULT_URL="https://<your-kv-name>.vault.azure.net/"
export DB_PASSWORD_SECRET_NAME="db-password"

docker build -t kv-demo-app .
docker run --rm -p 8000:8000 \
  -e KEYVAULT_URL \
  -e DB_PASSWORD_SECRET_NAME \
  kv-demo-app
