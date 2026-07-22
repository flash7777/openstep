# openstep -- Interne CA fuer nuhost6

step-ca mit ACME-Provisioner. Traefik und andere Services koennen
Zertifikate automatisch von dieser CA beziehen -- genau wie von
Let's Encrypt, aber ohne Internet-Erreichbarkeit.

Nutzt das offizielle `smallstep/step-ca` Image direkt.

## Image

```
docker.io/smallstep/step-ca:latest
```

Kein eigenes Dockerfile noetig -- das offizielle Image hat
`DOCKER_STEPCA_INIT_*` Env-Variablen fuer automatische Initialisierung.

## Deploy auf nuhost6

```bash
# 1. Target initialisieren
nu compose --init step_ca

# 2. Compose-Dir befuellen
cp docker-compose.yml .env compose.nuhost6.conf /nu/container/step_ca/compose/

# 3. Netzwerk anpassen
vim /nu/container/step_ca/compose/compose.nuhost6.conf

# 4. Quadlet generieren
nu compose --auto-apply /nu/container/step_ca/compose/

# 5. Verdrahten + starten
nu container enable step_ca
nu start step_ca
```

## Erster Start

Beim ersten Start initialisiert step-ca automatisch:
- Root-CA + Intermediate-CA generiert
- ACME-Provisioner angelegt
- Admin-Passwort angezeigt (einmalig in den Logs)

```bash
# Admin-Passwort aus Logs holen (nur beim ersten Start sichtbar!)
nu logs step_ca | grep password
```

## Bekannte Punkte

### EnvironmentFile

nu-compose generiert `<member>.env` Dateien mit den aufgeloesten
Environment-Variablen. nu-container bindet diese aktuell NICHT automatisch
als `EnvironmentFile=` ein. Workaround bis Stephans Convention implementiert ist:

```bash
# Manuell EnvironmentFile in nu.container ergaenzen:
sed -i '/^Image=/a EnvironmentFile=/nu/container/step_ca/step_ca.env' \
    /nu/container/step_ca/nu.container
systemctl daemon-reload
```

### Network-Check

step-ca braucht keine statische IP auf einer unmanaged Bridge.
Das Podman-Default-Netz reicht. nu-container meldet eine Warnung:

```
Network=podman: missing mandatory ':ip=' options
```

Workaround: `--ignore-check-network-config` beim Enable.

### Volume-Permissions

step-ca laeuft als UID 1000. Das Volume-Verzeichnis muss entsprechend
geowned sein:

```bash
chown -R 1000:1000 /nu/container/step_ca/volumes/step_ca/step-ca-data
```

### target_env_rewrite

`nu-container enable` ergaenzt `NU_TARGET_VOLUME_*` erst beim zweiten
Enable, wenn die Datei bereits `NU_TARGET` und `NU_TARGET_MEMBER` enthaelt.
Workaround: disable + enable nochmal ausfuehren.

## Traefik konfigurieren

In der OpenCloud `.env`:

```
TRAEFIK_ACME_CASERVER=https://<step-ca-ip>:9000/acme/acme/directory
```

## Root-CA auf Clients installieren

```bash
# Aus dem laufenden Container
podman exec systemd-step_ca step ca root > /tmp/nuhost6-ca.crt

# Auf jedem Client/Host
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
| `STEP_CA_TAG` | `latest` | Image-Tag |

## Volume

`/home/step` -- CA-Keys, DB, Config.

**Kritisch: muss gesichert werden. Ohne CA-Keys sind alle Zertifikate wertlos.**

## Deployed auf

| Host | IP | Status |
|---|---|---|
| hell | 192.168.1.10 | running (step_ca.service) |
