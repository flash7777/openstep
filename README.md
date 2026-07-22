# openstep -- Interne CA fuer nuhost6

step-ca mit ACME-Provisioner. Traefik und andere Services koennen
Zertifikate automatisch von dieser CA beziehen -- genau wie von
Let's Encrypt, aber ohne Internet-Erreichbarkeit.

## Build

```bash
# Lokal
podman build -t openstep .

# Via Build-Worker
../kosmos-cloud-deploy/job.py build-pod
```

## Deploy auf nuhost6

```bash
# Compose-Dir ins Target
nu compose --init step_ca
cp -a compose/* /nu/container/step_ca/compose/

# Netzwerk anpassen
vim /nu/container/step_ca/compose/compose.nuhost6.conf

# Deployen
nu compose /nu/container/step_ca/compose/
nu container enable step_ca
nu start step_ca
```

## Traefik konfigurieren

In der OpenCloud `.env` (oder compose.nuhost6.conf):

```
TRAEFIK_ACME_CASERVER=https://step-ca:9000/acme/acme/directory
```

step-ca muss im selben Netzwerk wie Traefik erreichbar sein,
oder Traefik bekommt die IP direkt.

## Root-CA auf Clients installieren

```bash
# Root-Zertifikat vom step-ca holen
podman exec step-ca step ca root > /tmp/nuhost6-ca.crt

# Auf jedem Client/Host:
cp /tmp/nuhost6-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

## Volumes

| Pfad | Inhalt | Backup? |
|---|---|---|
| `/home/step` | CA-Keys, DB, Zertifikate, Config | JA (kritisch!) |

Die CA-Keys sind das wertvollste Asset. Ohne sie sind alle
ausgestellten Zertifikate wertlos.

## Environment

| Variable | Default | Beschreibung |
|---|---|---|
| `CA_NAME` | `nuhost6-ca` | Name der CA |
| `CA_DNS` | `step-ca` | DNS-Name(n) der CA (kommagetrennt) |
| `CA_PASSWORD` | (generiert) | CA-Passwort (leer = auto-generiert) |
| `ACME_PROVISIONER` | `acme` | Name des ACME-Provisioners |

## ACME-URL

```
https://<step-ca-ip>:9000/acme/acme/directory
```
