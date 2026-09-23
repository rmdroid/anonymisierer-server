#!/usr/bin/env bash
#
# KI-Anonymisierer Server — Einrichtung
#
#   curl -fsSL https://raw.githubusercontent.com/rmdroid/anonymisierer-server/main/install.sh | bash
#
# oder nach dem Klonen:  ./install.sh
#
set -euo pipefail

IMAGE_BASE="${IMAGE_BASE:-ghcr.io/rmdroid/anonymisierer-server}"
DIR="${ANONYMIZER_DIR:-$HOME/ki-anonymisierer}"
PORT="${PORT:-9090}"

say()  { printf '%s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

step "KI-Anonymisierer Server"
say  "Lokale Anonymisierung fuer Chrome-Erweiterung und Windows-Client."

# ---------------------------------------------------------------- Vorbedingungen
step "Voraussetzungen pruefen"

command -v docker >/dev/null 2>&1 \
  || die "Docker wurde nicht gefunden. Docker Desktop installieren: https://docs.docker.com/get-docker/"

docker info >/dev/null 2>&1 \
  || die "Docker laeuft nicht. Bitte Docker Desktop starten und erneut versuchen."

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  die "docker compose fehlt. Es gehoert zu Docker Desktop dazu."
fi

say "  Docker  $(docker --version | cut -d' ' -f3 | tr -d ,)"
say "  Compose vorhanden"

if lsof -Pi ":$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
  die "Port $PORT ist belegt. Mit PORT=9091 ./install.sh einen anderen waehlen."
fi

# ---------------------------------------------------------------- Variante
step "Erkennungsstufe waehlen"
say "  1) Regeln            ~190 MB, startet sofort"
say "     Namen aus Wortlisten, Adressen, IBAN, Aktenzeichen, Telefon"
say ""
say "  2) Regeln + Modell   ~800 MB, laedt beim ersten Start rund 1,1 GB"
say "     Zusaetzlich Namen ausserhalb der Wortlisten, Organisationen, Orte"
say "     Deutlich hoehere Trefferquote. Empfohlen."
say ""

CHOICE="${VARIANT_CHOICE:-}"
if [ -z "$CHOICE" ]; then
  if [ -t 0 ]; then
    read -rp "Auswahl [2]: " CHOICE
  fi
fi
CHOICE="${CHOICE:-2}"

# Das Modell belegt beim Laden gut 2 GB. Ein zu knappes Limit laesst den
# Container beim Start abbrechen (Exit 137), ohne verstaendliche Meldung.
if [ "$CHOICE" = "1" ]; then
  TAG="latest"; ENGINES="regex";        MEM_DEFAULT="512M"
else
  TAG="gliner";  ENGINES="regex,gliner"; MEM_DEFAULT="6G"
fi
MEMORY="${MEMORY:-$MEM_DEFAULT}"

if [ "$CHOICE" != "1" ]; then
  TOTAL=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
  if [ "$TOTAL" -gt 0 ] && [ "$TOTAL" -lt 4000000000 ]; then
    warn ""
    warn "  Docker stehen nur $((TOTAL/1024/1024/1024)) GB zur Verfuegung."
    warn "  Die Modellvariante braucht gut 2 GB allein zum Laden."
    warn "  In Docker Desktop unter Settings > Resources mehr zuteilen,"
    warn "  oder mit Auswahl 1 ohne Modell starten."
    warn ""
  fi
fi

# ---------------------------------------------------------------- Einrichten
step "Einrichten in $DIR"
mkdir -p "$DIR"
cd "$DIR"

cat > docker-compose.yml <<COMPOSE
services:
  anonymizer:
    image: ${IMAGE_BASE}:${TAG}
    container_name: ki-anonymisierer
    restart: unless-stopped

    # Nur von diesem Rechner erreichbar. Ohne das "127.0.0.1:" davor
    # veroeffentlicht Docker den Port im gesamten Netzwerk.
    ports:
      - "127.0.0.1:${PORT}:9090"

    env_file: .env

    volumes:
      - models:/opt/models
      - config:/data

    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL

    deploy:
      resources:
        limits:
          memory: ${MEMORY}

volumes:
  models:
  config:
COMPOSE

if [ ! -f .env ]; then
  cat > .env <<ENVFILE
# Erkennungsstufen: regex und optional gliner
ENGINES=${ENGINES}

# --- Mehrbenutzerbetrieb (lizenzpflichtig) -------------------------
# Mehrere Arbeitsplaetze oder der Windows-Client greifen auf diesen
# Server zu. Dafuer zusaetzlich in docker-compose.yml das "127.0.0.1:"
# vor dem Port entfernen.
#
# Lizenz ueber ki-anonymisierer.de
#
# NETWORK=1
# LICENSE_KEY=KIA1....
# API_KEY=hier-einen-langen-zufallswert-eintragen
ENVFILE
  say "  .env angelegt"
else
  warn "  .env bleibt unveraendert"
fi

# ---------------------------------------------------------------- Starten
step "Abbild laden"
if [ "${SKIP_PULL:-0}" != "1" ]; then
  docker pull "${IMAGE_BASE}:${TAG}"
else
  say "  uebersprungen (SKIP_PULL=1)"
fi

step "Starten"
$COMPOSE up -d

printf '  Warte auf Bereitschaft '
READY=0
for _ in $(seq 1 90); do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then READY=1; break; fi
  printf '.'
  sleep 1
done
printf '\n'

if [ "$READY" != "1" ]; then
  warn "  Der Server antwortet noch nicht."
  warn "  Beim ersten Start mit Modell dauert das Laden einige Minuten."
  warn "  Fortschritt:  docker logs -f ki-anonymisierer"
  exit 0
fi

step "Fertig"
say "  Oberflaeche      http://localhost:${PORT}"
say "  Verzeichnis      $DIR"
say ""
say "  In der Chrome-Erweiterung unter 'Anonymisierungsserver' eintragen:"
say "      http://localhost:${PORT}"
say ""
say "  Beenden   cd $DIR && $COMPOSE down"
say "  Neustart  cd $DIR && $COMPOSE up -d"
say "  Aktualisieren  cd $DIR && $COMPOSE pull && $COMPOSE up -d"
say ""
say "  Einzelplatz auf diesem Rechner ist kostenfrei."
say "  Mehrere Arbeitsplaetze brauchen eine Lizenz, siehe EULA.md."
