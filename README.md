# KI-Anonymisierer Server

Erkennt personenbezogene Daten in Texten — vollständig auf Ihrer eigenen
Hardware. Keine Cloud, kein Drittanbieter, kein Datenabfluss.

Gehört zum [KI-Anonymisierer](https://ki-anonymisierer.de). Die
Chrome-Erweiterung und der Windows-Client nutzen ihn als Erkennungsschicht.

## Einrichten

```bash
curl -fsSL https://raw.githubusercontent.com/rmdroid/anonymisierer-server/main/install.sh | bash
```

Das Skript prüft die Voraussetzungen, fragt nach der Erkennungsstufe, lädt das
Abbild und startet den Server. Danach liegt die Oberfläche unter
**http://localhost:9090**.

Wer das Skript vorher lesen will — empfehlenswert bei allem, was per `curl`
ausgeführt wird:

```bash
git clone https://github.com/rmdroid/anonymisierer-server
cd anonymisierer-server
less install.sh
./install.sh
```

Voraussetzung ist Docker. Unter Windows und macOS genügt
[Docker Desktop](https://docs.docker.com/get-docker/).

## Zwei Erkennungsstufen

| | Abbild | Erster Start | Trefferquote |
|---|---|---|---|
| **Regeln** | ~190 MB | sofort | 39 % |
| **Regeln + Modell** | ~800 MB | lädt 1,1 GB | **100 %** |

Die Zahlen stammen aus einem Prüfsatz von 18 Fällen, der gezielt auf das zielt,
woran Wortlisten scheitern: Namen außerhalb des deutschen Standardrepertoires,
Organisationen, kleine Orte. In beiden Stufen ohne Fehlalarme.

Ein Beispiel für den Unterschied:

```
Guten Tag, ich bin Zeynep Yildirim aus Friedberg.

Regeln:          nicht erkannt
Regeln + Modell: [Person 1] aus [PLZ Ort 1]
```

Wortlisten sind endlich — der nächste unbekannte Name kommt bestimmt. Das lässt
sich nicht durch Nachpflegen lösen, sondern nur durch ein Modell, das aus dem
Satzbau schließt. Umgekehrt bleiben die Regeln unverzichtbar: Bei IBAN,
Aktenzeichen und Telefonnummern treffen sie sicherer als jedes Modell.

## Oberfläche

Unter `http://localhost:9090`:

- **Erkennungsmodule** einzeln an- und abschalten
- **Eigene Begriffe** ergänzen oder von der Anonymisierung ausnehmen — serverweit
  für alle verbundenen Arbeitsplätze
- **Ausprobieren** — Text einfügen und sehen, was erkannt wird
- **Lizenzschlüssel** eintragen

## Chrome-Erweiterung verbinden

In der Erweiterung unter **Anonymisierungsserver**:

1. „Server verwenden" einschalten
2. Adresse `http://localhost:9090`
3. Auf das Häkchen klicken, um die Verbindung zu prüfen

Fällt der Server aus, arbeitet die Erweiterung mit ihren eigenen Regeln weiter.

## Wie die Daten laufen

```
Chrome / Windows-Client
        │
        │  nur im eigenen Netz
        ▼
  Anonymisierungsserver
   Regeln → Modell
        │
        ▼
  Fundstellen zurück
```

Der Server gibt **Fundstellen** zurück, keinen fertigen Text. Die Ersetzung und
die Zuordnung zu den echten Namen passieren im Client und verlassen ihn nie.
Der Server sieht den Klartext während der Verarbeitung, speichert aber weder
ihn noch die Zuordnung.

Protokolliert werden ausschließlich Kennzahlen:

```
16:42:03  entities=7  chars=1823  engine=regex+gliner  took=142ms
```

Niemals der Text selbst.

## Lizenz

**Einzelplatz auf dem eigenen Rechner: kostenfrei.** Ohne Registrierung, ohne
Zeitbegrenzung, voller Funktionsumfang.

**Mehrere Arbeitsplätze: lizenzpflichtig.** Sobald mehrere Geräte auf denselben
Server zugreifen oder der Windows-Client im Mehrbenutzerbetrieb läuft.

**30 Tage kostenlos testen:** als Testschlüssel für den eigenen Server oder
über unseren Testserver, siehe [BESTELLUNG.md](BESTELLUNG.md). Der
Windows-Client ist kostenlos.

Einzelheiten in [EULA.md](EULA.md) ([English](EULA_en.md)), Bestellung über
[BESTELLUNG.md](BESTELLUNG.md).

Der Schlüssel wird lokal geprüft. Keine Onlineaktivierung, keine Übertragung.

### Mehrbenutzerbetrieb einschalten

Der Schlüssel allein gibt den Netzwerkzugang noch nicht frei — er berechtigt
dazu. Freigeschaltet wird mit:

```bash
cd ~/ki-anonymisierer
curl -fsSL https://raw.githubusercontent.com/rmdroid/anonymisierer-server/main/enable-network.sh | bash
```

Das Skript prüft den Schlüssel, erzeugt einen Zugriffsschlüssel, gibt den Port
im Netzwerk frei und startet neu. Am Ende nennt es die Adresse und den
Zugriffsschlüssel für die Arbeitsplätze.

Rückgängig mit den Sicherungskopien, die das Skript anlegt:

```bash
cp .env.bak .env && cp docker-compose.yml.bak docker-compose.yml && docker compose up -d
```

## Betrieb

```bash
cd ~/ki-anonymisierer

docker compose logs -f          # Protokoll
docker compose down             # beenden
docker compose up -d            # starten
docker compose pull && docker compose up -d   # aktualisieren
```

Einstellungen und Modell liegen in Docker-Volumes und überleben
Aktualisierungen.

### Speicherbedarf

| Stufe | Arbeitsspeicher |
|---|---|
| Regeln | ~150 MB |
| Regeln + Modell | ~1,5 GB |

### Häufige Fehler

**Port belegt** — mit `PORT=9091 ./install.sh` einen anderen wählen.

**Server antwortet nach dem ersten Start nicht** — bei der Modellvariante dauert
das Laden einige Minuten. Fortschritt mit `docker logs -f ki-anonymisierer`.

**Erweiterung erreicht den Server nicht** — prüfen, ob die Adresse in der
Erweiterung zum gewählten Port passt.

## Unterstützung

Für Sicherheitsfragebögen, Auftragsverarbeitungsverträge oder eine Teststellung:
**rm@kostenmanager.net**
