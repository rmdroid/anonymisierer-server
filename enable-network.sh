#!/usr/bin/env bash
#
# Schaltet den Mehrbenutzerbetrieb ein: mehrere Arbeitsplaetze oder der
# Windows-Client greifen auf diesen Server zu.
#
# Setzt voraus, dass ein gueltiger Lizenzschluessel vorliegt. Der
# Einzelplatzbetrieb auf dem eigenen Rechner ist kostenfrei und braucht
# dieses Skript nicht.
#
#   ./enable-network.sh
#
set -euo pipefail

DIR="${ANONYMIZER_DIR:-$HOME/ki-anonymisierer}"
PORT="${PORT:-9090}"

say()  { printf '%s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

cd "$DIR" 2>/dev/null || die "Keine Installation unter $DIR gefunden."
[ -f docker-compose.yml ] || die "docker-compose.yml fehlt in $DIR."
[ -f .env ] || die ".env fehlt in $DIR."

step "Mehrbenutzerbetrieb einschalten"

# ---------------------------------------------------------------- Lizenz
LICENSE="${LICENSE_KEY:-}"

if [ -z "$LICENSE" ]; then
  LICENSE=$(grep -E '^LICENSE_KEY=' .env 2>/dev/null | cut -d= -f2- || true)
fi

if [ -z "$LICENSE" ]; then
  CURRENT=$(curl -fsS "http://127.0.0.1:${PORT}/api/state" 2>/dev/null \
    | python3 -c "import sys,json;print(json.load(sys.stdin)['license'].get('valid'))" 2>/dev/null || echo "")
  if [ "$CURRENT" = "True" ]; then
    say "  Ein gueltiger Schluessel ist bereits in der Oberflaeche hinterlegt."
  else
    say "  Lizenzschluessel eingeben (beginnt mit KIA1.):"
    read -rp "  > " LICENSE
    [ -n "$LICENSE" ] || die "Kein Schluessel eingegeben."
  fi
fi

if [ -n "$LICENSE" ]; then
  RESULT=$(curl -fsS -X POST "http://127.0.0.1:${PORT}/api/license" \
    -H "Content-Type: application/json" \
    -d "{\"key\":\"${LICENSE}\"}" 2>/dev/null || echo "")
  VALID=$(printf '%s' "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin).get('valid'))" 2>/dev/null || echo "")
  if [ "$VALID" != "True" ]; then
    REASON=$(printf '%s' "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin).get('detail','unbekannt'))" 2>/dev/null || echo "Server nicht erreichbar")
    die "Lizenz abgelehnt: $REASON"
  fi
  printf '%s' "$RESULT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"  Lizenz gueltig: {d['customer']}, {d['seats']} Arbeitsplaetze, bis {d['expires'] or 'unbefristet'}\")
"
fi

# ---------------------------------------------------------------- API-Key
APIKEY=$(grep -E '^API_KEY=' .env 2>/dev/null | cut -d= -f2- || true)
if [ -z "$APIKEY" ]; then
  # Nicht ueber "tr ... | head -c": head schliesst die Pipe, tr bekommt
  # SIGPIPE, und pipefail bricht das Skript ab.
  if command -v openssl >/dev/null 2>&1; then
    APIKEY=$(openssl rand -hex 20)
  else
    APIKEY=$(python3 -c "import secrets; print(secrets.token_hex(20))")
  fi
  say "  Zugriffsschluessel erzeugt"
fi

# ---------------------------------------------------------------- .env
cp .env .env.bak
grep -vE '^(NETWORK|LICENSE_KEY|API_KEY)=' .env.bak > .env || true
{
  echo "NETWORK=1"
  [ -n "$LICENSE" ] && echo "LICENSE_KEY=${LICENSE}"
  echo "API_KEY=${APIKEY}"
} >> .env

# ---------------------------------------------------------------- Port
if grep -q '"127.0.0.1:' docker-compose.yml; then
  cp docker-compose.yml docker-compose.yml.bak
  sed -i.tmp 's/"127\.0\.0\.1:\([0-9]*\):9090"/"\1:9090"/' docker-compose.yml
  rm -f docker-compose.yml.tmp
  say "  Port im Netzwerk freigegeben"
else
  say "  Port war bereits freigegeben"
fi

step "Neu starten"
docker compose up -d

printf '  Warte '
for _ in $(seq 1 60); do
  curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && break
  printf '.'; sleep 1
done
printf '\n'

MODE=$(curl -fsS "http://127.0.0.1:${PORT}/health" 2>/dev/null \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['mode'])" 2>/dev/null || echo "?")

if [ "$MODE" != "network" ]; then
  warn "  Der Server laeuft noch im Einzelplatzbetrieb."
  warn "  Protokoll pruefen:  docker logs ki-anonymisierer"
  exit 1
fi

IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "<server-ip>")

step "Fertig"
say "  Adresse fuer die Arbeitsplaetze:"
say "      http://${IP}:${PORT}"
say ""
say "  Zugriffsschluessel:"
say "      ${APIKEY}"
say ""
say "  Beides in der Chrome-Erweiterung unter 'Anonymisierungsserver'"
say "  eintragen, ebenso im Windows-Client."
say ""
warn "  Der Server ist jetzt im Netzwerk erreichbar. Ohne den"
warn "  Zugriffsschluessel kommt niemand an die Einstellungen, aber"
warn "  beschraenken Sie den Zugang zusaetzlich ueber Ihre Firewall."
say ""
say "  Rueckgaengig:  cp .env.bak .env && cp docker-compose.yml.bak docker-compose.yml && docker compose up -d"
