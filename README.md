# openstep -- Interne CA fuer nuhost6

step-ca mit ACME-Provisioner. Traefik und andere Services koennen
Zertifikate automatisch von dieser CA beziehen -- genau wie von
Let's Encrypt, aber ohne Internet-Erreichbarkeit.

Nutzt das offizielle `smallstep/step-ca` Image direkt.
Kein eigenes Dockerfile noetig.

## Deploy auf nuhost6

```bash
# 1. Compose-Dir ins Target kopieren
nu compose --init step_ca
cp docker-compose.yml .env compose.nuhost6.conf /nu/container/step_ca/compose/

# 2. Netzwerk + DNS anpassen
vim /nu/container/step_ca/compose/compose.nuhost6.conf

# 3. Quadlet generieren + starten
nu compose /nu/container/step_ca/compose/
nu container enable step_ca
nu start step_ca
```

Beim ersten Start initialisiert step-ca automatisch:
- Root-CA + Intermediate-CA generieren
- ACME-Provisioner anlegen
- Admin-Passwort anzeigen (einmalig in den Logs)

```bash
# Admin-Passwort aus Logs holen (nur beim ersten Start sichtbar)
nu logs step_ca | grep password
```

## Traefik konfigurieren

In der OpenCloud `.env`:

```
TRAEFIK_ACME_CASERVER=https://<step-ca-ip>:9000/acme/acme/directory
```

## Root-CA auf Clients installieren

```bash
# Aus dem Volume holen
podman exec systemd-step_ca step ca root > /tmp/nuhost6-ca.crt

# Auf jedem Client
cp /tmp/nuhost6-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

## Environment

| Variable | Default | Beschreibung |
|---|---|---|
| `CA_NAME` | `nuhost6-ca` | Name der CA |
| `CA_DNS` | `step-ca` | DNS-Name(n) der CA |
| `CA_ACME` | `true` | ACME-Provisioner anlegen |
| `CA_PASSWORD` | (auto) | CA-Passwort (leer = generiert) |

## Volume

`/home/step` -- CA-Keys, DB, Config. **Kritisch, muss gesichert werden.**
