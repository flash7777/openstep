#!/bin/sh
set -eu

STEPPATH="${STEPPATH:-/home/step}"
CA_NAME="${CA_NAME:-nuhost6-ca}"
CA_DNS="${CA_DNS:-step-ca}"
CA_ADDRESS="${CA_ADDRESS:-:9000}"
CA_PASSWORD="${CA_PASSWORD:-}"
ACME_PROVISIONER="${ACME_PROVISIONER:-acme}"

# Passwort-Datei
PW_FILE="$STEPPATH/secrets/password"

# Erstinitialisierung: CA anlegen wenn noch nicht vorhanden
if [ ! -f "$STEPPATH/config/ca.json" ]; then
    echo "=== step-ca: Erstinitialisierung ==="

    # Passwort generieren oder aus ENV
    mkdir -p "$STEPPATH/secrets"
    if [ -n "$CA_PASSWORD" ]; then
        printf '%s' "$CA_PASSWORD" > "$PW_FILE"
    elif [ ! -f "$PW_FILE" ]; then
        head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' > "$PW_FILE"
        echo "  CA-Passwort generiert: $PW_FILE"
    fi

    # CA initialisieren (non-interactive)
    step ca init \
        --name "$CA_NAME" \
        --dns "$CA_DNS" \
        --address "$CA_ADDRESS" \
        --provisioner admin \
        --password-file "$PW_FILE" \
        --provisioner-password-file "$PW_FILE" \
        --deployment-type standalone \
        --acme

    echo "  CA initialisiert: $CA_NAME"
    echo "  ACME-URL: https://${CA_DNS}${CA_ADDRESS}/acme/acme/directory"
    echo ""
    echo "  Root-CA installieren auf Clients:"
    echo "    step ca root --ca-url https://<step-ca-ip>:9000"
    echo ""
fi

# CA starten
exec step-ca "$STEPPATH/config/ca.json" --password-file "$PW_FILE"
