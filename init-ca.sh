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
        echo "$CA_PASSWORD" > "$PW_FILE"
    elif [ ! -f "$PW_FILE" ]; then
        openssl rand -hex 32 > "$PW_FILE"
        echo "  CA-Passwort generiert: $PW_FILE"
    fi

    # CA initialisieren
    step ca init \
        --name "$CA_NAME" \
        --dns "$CA_DNS" \
        --address "$CA_ADDRESS" \
        --provisioner admin \
        --password-file "$PW_FILE" \
        --deployment-type standalone

    # ACME-Provisioner hinzufuegen (Let's Encrypt kompatibel)
    step ca provisioner add "$ACME_PROVISIONER" \
        --type ACME \
        --password-file "$PW_FILE"

    echo "  CA initialisiert: $CA_NAME"
    echo "  ACME-Provisioner: $ACME_PROVISIONER"
    echo "  ACME-URL: https://$CA_DNS${CA_ADDRESS}/acme/$ACME_PROVISIONER/directory"
    echo ""
    echo "  Root-CA installieren auf Clients:"
    echo "    step ca root > /usr/local/share/ca-certificates/nuhost6-ca.crt"
    echo "    update-ca-certificates"
    echo ""
fi

# CA starten
exec step-ca "$STEPPATH/config/ca.json" --password-file "$PW_FILE"
