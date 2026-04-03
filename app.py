from fastapi import FastAPI
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import os

app = FastAPI()

KV_URL_ENV = "KEYVAULT_URL"
SECRET_NAME_ENV = "DB_PASSWORD_SECRET_NAME"

kv_url = os.getenv(KV_URL_ENV)
secret_name = os.getenv(SECRET_NAME_ENV, "db-password")

if not kv_url:
    raise RuntimeError(f"{KV_URL_ENV} environment variable must be set")

credential = DefaultAzureCredential()
client = SecretClient(vault_url=kv_url, credential=credential)


def get_db_password() -> str:
    secret = client.get_secret(secret_name)
    return secret.value


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/secret")
def read_secret():
    value = get_db_password()
    # This endpoint is only for demo pruposes.
    # In real systems, you never return secrets.
    # Used to prove the managed identity successfully accessed Key Vault.
    # ----- In real life, you would NOT return secrets in responses. -----
    return {"secret_name": secret_name, "secret_value": value}